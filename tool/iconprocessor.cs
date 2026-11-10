using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.IO;

public class IconProcessor
{
    public static void Main(string[] args)
    {
        string appIconPath = @"C:\Users\Midhun Sasikala\OneDrive\Desktop\Cheerful Beaver Savings Icon.png";
        string mascotPath = @"C:\Users\Midhun Sasikala\OneDrive\Desktop\Cheerful Beaver with Golden Dollar Coin.png";

        if (!File.Exists(appIconPath))
        {
            Console.WriteLine("Error: App icon file not found: " + appIconPath);
            return;
        }
        if (!File.Exists(mascotPath))
        {
            Console.WriteLine("Error: Mascot file not found: " + mascotPath);
            return;
        }

        Console.WriteLine("=== Processing App Icon ===");
        using (Bitmap rawAppIcon = new Bitmap(appIconPath))
        {
            using (Bitmap appIconCutout = CreateCutout(rawAppIcon, 246, 246, 246))
            {
                // 1. Flutter app assets
                GenerateSquareIconWithWhiteBg(appIconCutout, @"assets/icons/app_icon.png", 512, 0.90f);
                GenerateSquareIconWithWhiteBg(appIconCutout, @"assets/icons/wizard.png", 512, 0.90f);

                // 2. Android Adaptive Icon Foregrounds (ratio = 0.84f so circle mask cleanly encloses the art)
                GenerateAdaptiveForeground(appIconCutout, @"android/app/src/main/res/drawable/ic_launcher_foreground.png", 432, 0.84f);
                GenerateAdaptiveForeground(appIconCutout, @"android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png", 108, 0.84f);
                GenerateAdaptiveForeground(appIconCutout, @"android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png", 162, 0.84f);
                GenerateAdaptiveForeground(appIconCutout, @"android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png", 216, 0.84f);
                GenerateAdaptiveForeground(appIconCutout, @"android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png", 324, 0.84f);
                GenerateAdaptiveForeground(appIconCutout, @"android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png", 432, 0.84f);

                // 3. Legacy Mipmap Icons (pure white background)
                GenerateMipmapIcon(appIconCutout, @"android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48, 0.88f);
                GenerateMipmapIcon(appIconCutout, @"android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72, 0.88f);
                GenerateMipmapIcon(appIconCutout, @"android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96, 0.88f);
                GenerateMipmapIcon(appIconCutout, @"android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144, 0.88f);
                GenerateMipmapIcon(appIconCutout, @"android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192, 0.88f);

                // 4. Round Launcher Icons (white circle clip)
                GenerateMipmapRoundIcon(appIconCutout, @"android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png", 48, 0.84f);
                GenerateMipmapRoundIcon(appIconCutout, @"android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png", 72, 0.84f);
                GenerateMipmapRoundIcon(appIconCutout, @"android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png", 96, 0.84f);
                GenerateMipmapRoundIcon(appIconCutout, @"android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png", 144, 0.84f);
                GenerateMipmapRoundIcon(appIconCutout, @"android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png", 192, 0.84f);

                // 5. Widget Mascot Icon
                GenerateTransparentIcon(appIconCutout, @"android/app/src/main/res/drawable/widget_icon.png", 128);
                GenerateTransparentIcon(appIconCutout, @"android/app/src/main/res/drawable-mdpi/widget_icon.png", 32);
                GenerateTransparentIcon(appIconCutout, @"android/app/src/main/res/drawable-hdpi/widget_icon.png", 48);
                GenerateTransparentIcon(appIconCutout, @"android/app/src/main/res/drawable-xhdpi/widget_icon.png", 64);
                GenerateTransparentIcon(appIconCutout, @"android/app/src/main/res/drawable-xxhdpi/widget_icon.png", 96);
                GenerateTransparentIcon(appIconCutout, @"android/app/src/main/res/drawable-xxxhdpi/widget_icon.png", 128);
            }
        }

        Console.WriteLine("=== Processing Splash Screen (Cheerful Beaver + App Name) ===");
        using (Bitmap rawMascot = new Bitmap(mascotPath))
        {
            using (Bitmap mascotCutout = CreateCutout(rawMascot, 246, 246, 246))
            {
                // Create high-res 1024x1024 splash composition
                using (Bitmap splashComposition = new Bitmap(1024, 1024, PixelFormat.Format32bppArgb))
                {
                    using (Graphics g = Graphics.FromImage(splashComposition))
                    {
                        g.Clear(Color.Transparent);
                        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        g.SmoothingMode = SmoothingMode.HighQuality;
                        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                        g.CompositingQuality = CompositingQuality.HighQuality;
                        g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;

                        // Mascot centered in upper portion (580x580)
                        int mascotSize = 580;
                        int mascotX = (1024 - mascotSize) / 2;
                        int mascotY = 120;
                        g.DrawImage(mascotCutout, new Rectangle(mascotX, mascotY, mascotSize, mascotSize));

                        // App Name below mascot: "Kals" & "MONEY MANAGER"
                        using (Font fontKals = new Font("Segoe UI", 68, FontStyle.Bold, GraphicsUnit.Pixel))
                        using (Font fontSub = new Font("Segoe UI", 40, FontStyle.Bold, GraphicsUnit.Pixel))
                        using (SolidBrush textBrush = new SolidBrush(Color.FromArgb(255, 30, 41, 59))) // #1E293B
                        using (SolidBrush subBrush = new SolidBrush(Color.FromArgb(255, 71, 85, 105)))  // #475569
                        {
                            StringFormat sf = new StringFormat
                            {
                                Alignment = StringAlignment.Center,
                                LineAlignment = StringAlignment.Center
                            };

                            g.DrawString("Kals", fontKals, textBrush, new RectangleF(0, mascotY + mascotSize + 25, 1024, 80), sf);
                            g.DrawString("MONEY MANAGER", fontSub, subBrush, new RectangleF(0, mascotY + mascotSize + 115, 1024, 55), sf);
                        }
                    }

                    // Save full high-res splash composition in assets
                    EnsureDirectory(@"assets/icons/splash.png");
                    splashComposition.Save(@"assets/icons/splash.png", ImageFormat.Png);
                    Console.WriteLine("Saved: assets/icons/splash.png");

                    EnsureDirectory(@"assets/icons/splash_icon.png");
                    splashComposition.Save(@"assets/icons/splash_icon.png", ImageFormat.Png);
                    Console.WriteLine("Saved: assets/icons/splash_icon.png");

                    // Android Splash Icon densities
                    GenerateTransparentIcon(splashComposition, @"android/app/src/main/res/drawable/splash_icon.png", 512);
                    GenerateTransparentIcon(splashComposition, @"android/app/src/main/res/drawable-mdpi/splash_icon.png", 128);
                    GenerateTransparentIcon(splashComposition, @"android/app/src/main/res/drawable-hdpi/splash_icon.png", 192);
                    GenerateTransparentIcon(splashComposition, @"android/app/src/main/res/drawable-xhdpi/splash_icon.png", 256);
                    GenerateTransparentIcon(splashComposition, @"android/app/src/main/res/drawable-xxhdpi/splash_icon.png", 384);
                    GenerateTransparentIcon(splashComposition, @"android/app/src/main/res/drawable-xxxhdpi/splash_icon.png", 512);
                }
            }
        }

        Console.WriteLine("All application icons and splash screens generated successfully!");
    }

    private static Bitmap CreateCutout(Bitmap original, int threshR, int threshG, int threshB)
    {
        int w = original.Width;
        int h = original.Height;
        Bitmap transparent = new Bitmap(w, h, PixelFormat.Format32bppArgb);

        bool[,] isBg = new bool[w, h];
        Queue<Point> q = new Queue<Point>();

        for (int x = 0; x < w; x++)
        {
            CheckAndPush(original, isBg, q, x, 0, threshR, threshG, threshB);
            CheckAndPush(original, isBg, q, x, h - 1, threshR, threshG, threshB);
        }
        for (int y = 0; y < h; y++)
        {
            CheckAndPush(original, isBg, q, 0, y, threshR, threshG, threshB);
            CheckAndPush(original, isBg, q, w - 1, y, threshR, threshG, threshB);
        }

        int[] dx = { 1, -1, 0, 0 };
        int[] dy = { 0, 0, 1, -1 };

        while (q.Count > 0)
        {
            Point p = q.Dequeue();
            for (int i = 0; i < 4; i++)
            {
                int nx = p.X + dx[i];
                int ny = p.Y + dy[i];
                if (nx >= 0 && nx < w && ny >= 0 && ny < h && !isBg[nx, ny])
                {
                    CheckAndPush(original, isBg, q, nx, ny, threshR, threshG, threshB);
                }
            }
        }

        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                if (isBg[x, y])
                {
                    transparent.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
                }
                else
                {
                    transparent.SetPixel(x, y, original.GetPixel(x, y));
                }
            }
        }

        return transparent;
    }

    private static void CheckAndPush(Bitmap img, bool[,] isBg, Queue<Point> q, int x, int y, int tR, int tG, int tB)
    {
        if (isBg[x, y]) return;
        Color c = img.GetPixel(x, y);
        if (c.R >= tR && c.G >= tG && c.B >= tB)
        {
            isBg[x, y] = true;
            q.Enqueue(new Point(x, y));
        }
    }

    private static void EnsureDirectory(string path)
    {
        string dir = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
        {
            Directory.CreateDirectory(dir);
        }
    }

    private static void GenerateSquareIconWithWhiteBg(Bitmap src, string outputPath, int size, float ratio)
    {
        EnsureDirectory(outputPath);
        using (Bitmap dest = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(Color.White);
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.CompositingQuality = CompositingQuality.HighQuality;

                int targetSize = (int)(size * ratio);
                int offset = (size - targetSize) / 2;
                g.DrawImage(src, new Rectangle(offset, offset, targetSize, targetSize));
            }
            dest.Save(outputPath, ImageFormat.Png);
            Console.WriteLine("Saved: " + outputPath);
        }
    }

    private static void GenerateAdaptiveForeground(Bitmap src, string outputPath, int size, float safeRatio)
    {
        EnsureDirectory(outputPath);
        using (Bitmap dest = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(Color.Transparent);
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.CompositingQuality = CompositingQuality.HighQuality;

                int targetSize = (int)(size * safeRatio);
                int offset = (size - targetSize) / 2;
                g.DrawImage(src, new Rectangle(offset, offset, targetSize, targetSize));
            }
            dest.Save(outputPath, ImageFormat.Png);
            Console.WriteLine("Saved: " + outputPath);
        }
    }

    private static void GenerateTransparentIcon(Bitmap src, string outputPath, int size)
    {
        EnsureDirectory(outputPath);
        using (Bitmap dest = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(Color.Transparent);
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.CompositingQuality = CompositingQuality.HighQuality;

                g.DrawImage(src, new Rectangle(0, 0, size, size));
            }
            dest.Save(outputPath, ImageFormat.Png);
            Console.WriteLine("Saved: " + outputPath);
        }
    }

    private static void GenerateMipmapIcon(Bitmap src, string outputPath, int size, float ratio)
    {
        EnsureDirectory(outputPath);
        using (Bitmap dest = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(Color.White);
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.CompositingQuality = CompositingQuality.HighQuality;

                int targetSize = (int)(size * ratio);
                int offset = (size - targetSize) / 2;
                g.DrawImage(src, new Rectangle(offset, offset, targetSize, targetSize));
            }
            dest.Save(outputPath, ImageFormat.Png);
            Console.WriteLine("Saved: " + outputPath);
        }
    }

    private static void GenerateMipmapRoundIcon(Bitmap src, string outputPath, int size, float ratio)
    {
        EnsureDirectory(outputPath);
        using (Bitmap dest = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(Color.Transparent);
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.CompositingQuality = CompositingQuality.HighQuality;

                using (GraphicsPath path = new GraphicsPath())
                {
                    path.AddEllipse(0, 0, size, size);
                    g.SetClip(path);
                    g.Clear(Color.White);

                    int targetSize = (int)(size * ratio);
                    int offset = (size - targetSize) / 2;
                    g.DrawImage(src, new Rectangle(offset, offset, targetSize, targetSize));
                }
            }
            dest.Save(outputPath, ImageFormat.Png);
            Console.WriteLine("Saved: " + outputPath);
        }
    }
}
