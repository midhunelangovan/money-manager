package com.kals.kals_money_manager.kals_storage

import android.app.DownloadManager
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/**
 * Native MediaStore storage plugin for Kals Money Manager.
 * Registered on ALL FlutterEngines (both foreground UI and headless background WorkManager workers),
 * ensuring reliable public Downloads access across Android versions without depending on MainActivity.
 */
class KalsStoragePlugin : FlutterPlugin, MethodCallHandler {

    companion object {
        const val CHANNEL_WIDGET = "com.kals.kals_money_manager/widget_channel"
        const val CHANNEL_STORAGE = "com.kals.kals_money_manager/storage_channel"
        const val LEGACY_CHANNEL_WIDGET = "com.kals.kals_money_manager.dev/widget_channel"
        const val LEGACY_CHANNEL_STORAGE = "com.kals.kals_money_manager.dev/storage_channel"
    }

    private var channelWidget: MethodChannel? = null
    private var channelStorage: MethodChannel? = null
    private var legacyChannelWidget: MethodChannel? = null
    private var legacyChannelStorage: MethodChannel? = null
    private var context: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        channelWidget = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_WIDGET)
        channelWidget?.setMethodCallHandler(this)

        channelStorage = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_STORAGE)
        channelStorage?.setMethodCallHandler(this)

        legacyChannelWidget = MethodChannel(flutterPluginBinding.binaryMessenger, LEGACY_CHANNEL_WIDGET)
        legacyChannelWidget?.setMethodCallHandler(this)

        legacyChannelStorage = MethodChannel(flutterPluginBinding.binaryMessenger, LEGACY_CHANNEL_STORAGE)
        legacyChannelStorage?.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val appContext = context
        if (appContext == null) {
            result.error("NO_CONTEXT", "Application context is not available", null)
            return
        }

        when (call.method) {
            "saveFileToPublicDownloads" -> {
                try {
                    val bytes = call.argument<ByteArray>("bytes")
                        ?: throw IllegalArgumentException("bytes cannot be null")
                    val fileName = call.argument<String>("fileName")
                        ?: throw IllegalArgumentException("fileName cannot be null")
                    val mimeType = call.argument<String>("mimeType")
                        ?: "application/octet-stream"

                    val res = saveFileToPublicDownloads(appContext, bytes, fileName, mimeType)
                    result.success(res)
                } catch (e: Exception) {
                    result.error("SAVE_FAILED", e.message, null)
                }
            }
            "getPublicExportedFiles" -> {
                try {
                    val files = getPublicExportedFiles(appContext)
                    result.success(files)
                } catch (e: Exception) {
                    result.error("QUERY_FAILED", e.message, null)
                }
            }
            "openFolder" -> {
                val path = call.argument<String>("path")
                val opened = openFolderInFileViewer(appContext, path)
                result.success(opened)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channelWidget?.setMethodCallHandler(null)
        channelWidget = null
        channelStorage?.setMethodCallHandler(null)
        channelStorage = null
        legacyChannelWidget?.setMethodCallHandler(null)
        legacyChannelWidget = null
        legacyChannelStorage?.setMethodCallHandler(null)
        legacyChannelStorage = null
        context = null
    }

    private fun saveFileToPublicDownloads(
        ctx: Context,
        bytes: ByteArray,
        fileName: String,
        mimeType: String
    ): Map<String, Any?> {
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val resolvedName = getSafeUniqueFileName(ctx, downloadsDir, fileName)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentResolver = ctx.contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, resolvedName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }

            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                ?: throw IllegalStateException("Failed to create MediaStore entry in Downloads")

            try {
                contentResolver.openOutputStream(uri)?.use { os ->
                    os.write(bytes)
                    os.flush()
                } ?: throw IllegalStateException("Failed to open output stream for MediaStore Uri")

                contentValues.clear()
                contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
                contentResolver.update(uri, contentValues, null, null)

                val canonicalFile = File(downloadsDir, resolvedName)
                val resolvedPath = getAbsolutePathFromUri(ctx, uri) ?: canonicalFile.absolutePath

                // Verification check: ensure file is non-empty and readable
                var verified = false
                val directFile = File(resolvedPath)
                if (directFile.exists() && directFile.length() > 0L) {
                    verified = true
                } else {
                    try {
                        contentResolver.openFileDescriptor(uri, "r")?.use { pfd ->
                            if (pfd.statSize > 0L) {
                                verified = true
                            }
                        }
                    } catch (_: Exception) {}
                }

                if (!verified) {
                    throw IllegalStateException("Exported file failed verification in Downloads collection")
                }

                return mapOf(
                    "success" to true,
                    "filePath" to resolvedPath,
                    "uri" to uri.toString(),
                    "fileName" to resolvedName,
                    "fileSize" to bytes.size
                )
            } catch (e: Exception) {
                try {
                    contentResolver.delete(uri, null, null)
                } catch (_: Exception) {}
                throw e
            }
        } else {
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }
            val targetFile = File(downloadsDir, resolvedName)
            targetFile.outputStream().use { os ->
                os.write(bytes)
                os.flush()
            }

            MediaScannerConnection.scanFile(
                ctx,
                arrayOf(targetFile.absolutePath),
                arrayOf(mimeType),
                null
            )

            if (!targetFile.exists() || targetFile.length() == 0L) {
                throw IllegalStateException("Exported file failed verification in Downloads directory")
            }

            return mapOf(
                "success" to true,
                "filePath" to targetFile.absolutePath,
                "uri" to Uri.fromFile(targetFile).toString(),
                "fileName" to resolvedName,
                "fileSize" to bytes.size
            )
        }
    }

    private fun getSafeUniqueFileName(ctx: Context, dir: File, originalName: String): String {
        val dotIndex = originalName.lastIndexOf('.')
        val baseName = if (dotIndex > 0) originalName.substring(0, dotIndex) else originalName
        val extension = if (dotIndex > 0) originalName.substring(dotIndex) else ""

        var candidateName = originalName
        var counter = 1

        while (isFileExistsInDownloads(ctx, dir, candidateName)) {
            candidateName = "$baseName ($counter)$extension"
            counter++
        }
        return candidateName
    }

    private fun isFileExistsInDownloads(ctx: Context, dir: File, name: String): Boolean {
        val directFile = File(dir, name)
        if (directFile.exists()) return true

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val projection = arrayOf(MediaStore.MediaColumns._ID)
                val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ? AND ${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?"
                val selectionArgs = arrayOf(name, "${Environment.DIRECTORY_DOWNLOADS}%")
                ctx.contentResolver.query(
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                    projection,
                    selection,
                    selectionArgs,
                    null
                )?.use { cursor ->
                    if (cursor.count > 0) return true
                }
            } catch (_: Exception) {}
        }
        return false
    }

    private fun getAbsolutePathFromUri(ctx: Context, uri: Uri): String? {
        try {
            val projection = arrayOf(MediaStore.MediaColumns.DATA)
            ctx.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                val dataIndex = cursor.getColumnIndex(MediaStore.MediaColumns.DATA)
                if (dataIndex != -1 && cursor.moveToFirst()) {
                    val path = cursor.getString(dataIndex)
                    if (!path.isNullOrEmpty()) {
                        return path
                    }
                }
            }
        } catch (_: Exception) {}
        return null
    }

    private fun getPublicExportedFiles(ctx: Context): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()
        val seenPaths = mutableSetOf<String>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val projection = arrayOf(
                    MediaStore.MediaColumns._ID,
                    MediaStore.MediaColumns.DISPLAY_NAME,
                    MediaStore.MediaColumns.DATA,
                    MediaStore.MediaColumns.SIZE,
                    MediaStore.MediaColumns.DATE_MODIFIED
                )
                val selection = "(${MediaStore.MediaColumns.DISPLAY_NAME} LIKE '%.xlsx' OR ${MediaStore.MediaColumns.DISPLAY_NAME} LIKE '%.mmb') AND ${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?"
                val selectionArgs = arrayOf("${Environment.DIRECTORY_DOWNLOADS}%")
                val sortOrder = "${MediaStore.MediaColumns.DATE_MODIFIED} DESC"

                ctx.contentResolver.query(
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                    projection,
                    selection,
                    selectionArgs,
                    sortOrder
                )?.use { cursor ->
                    val nameCol = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME)
                    val dataCol = cursor.getColumnIndex(MediaStore.MediaColumns.DATA)
                    val sizeCol = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE)
                    val dateCol = cursor.getColumnIndex(MediaStore.MediaColumns.DATE_MODIFIED)

                    while (cursor.moveToNext()) {
                        val name = if (nameCol != -1) cursor.getString(nameCol) else ""
                        var path = if (dataCol != -1) cursor.getString(dataCol) else null
                        if (path.isNullOrEmpty()) {
                            path = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), name).absolutePath
                        }
                        val size = if (sizeCol != -1) cursor.getLong(sizeCol) else 0L
                        val modified = if (dateCol != -1) cursor.getLong(dateCol) * 1000L else System.currentTimeMillis()

                        if (!seenPaths.contains(path)) {
                            seenPaths.add(path)
                            results.add(
                                mapOf(
                                    "path" to path,
                                    "name" to name,
                                    "size" to size,
                                    "lastModified" to modified
                                )
                            )
                        }
                    }
                }
            } catch (_: Exception) {}
        }

        try {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (downloadsDir.exists() && downloadsDir.isDirectory) {
                downloadsDir.listFiles()?.forEach { file ->
                    val name = file.name
                    if ((name.endsWith(".xlsx", ignoreCase = true) || name.endsWith(".mmb", ignoreCase = true)) &&
                        !seenPaths.contains(file.absolutePath) &&
                        file.length() > 0L
                    ) {
                        seenPaths.add(file.absolutePath)
                        results.add(
                            mapOf(
                                "path" to file.absolutePath,
                                "name" to name,
                                "size" to file.length(),
                                "lastModified" to file.lastModified()
                            )
                        )
                    }
                }
            }
        } catch (_: Exception) {}

        return results
    }

    private fun openFolderInFileViewer(ctx: Context, folderPath: String?): Boolean {
        try {
            val intent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            ctx.startActivity(intent)
            return true
        } catch (_: Exception) {}

        try {
            val uri = Uri.parse("content://com.android.providers.downloads.documents/root/downloads")
            val intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(uri, "vnd.android.cursor.dir/download")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            ctx.startActivity(intent)
            return true
        } catch (_: Exception) {}

        if (!folderPath.isNullOrEmpty()) {
            try {
                val dir = File(folderPath)
                if (dir.exists()) {
                    val uri = Uri.parse(dir.absolutePath)
                    val intent = Intent(Intent.ACTION_VIEW)
                    intent.setDataAndType(uri, "resource/folder")
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    ctx.startActivity(intent)
                    return true
                }
            } catch (_: Exception) {}

            try {
                val intent = Intent(Intent.ACTION_VIEW)
                val uri = Uri.parse(folderPath)
                intent.setDataAndType(uri, "*/*")
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                ctx.startActivity(intent)
                return true
            } catch (_: Exception) {}
        }

        return false
    }
}
