using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.IO;

public class GenerateNewAssets
{
    // Brand Colors from Design Tokens & app_colors.dart
    private static readonly Color BrandPrimary = Color.FromArgb(255, 3, 50, 58);     // #03323A
    private static readonly Color BrandTeal = Color.FromArgb(255, 35, 129, 141);    // #23818D
    private static readonly Color WarmOffWhite = Color.FromArgb(255, 246, 245, 242); // #F6F5F2
    private static readonly Color NightPrimary = Color.FromArgb(255, 248, 250, 252); // #F8FAFC
    private static readonly Color NightTeal = Color.FromArgb(255, 166, 180, 201);    // #A6B4C9

    public static void Main(string[] args)
    {
        string inputPath = @"assets/icons/animal.png";
        if (!File.Exists(inputPath))
        {
            inputPath = @"assets/icons/money-manager-icon.jpg";
            if (!File.Exists(inputPath))
            {
                Console.WriteLine("Error: Source image not found at assets/icons/animal.png or assets/icons/money-manager-icon.jpg");
                return;
            }
        }

        Console.WriteLine("Loading character icon from: " + inputPath);
        using (Bitmap raw = new Bitmap(inputPath))
        using (Bitmap character = (inputPath.EndsWith(".jpg", StringComparison.OrdinalIgnoreCase)) ? CreateCutout(raw) : new Bitmap(raw))
        {
            Console.WriteLine("Source character ready (" + character.Width + "x" + character.Height + ")");

            // 1. Android 12+ Splash Icons (safe circle window is ~66% of canvas, 330px on 512 canvas)
            Console.WriteLine("Generating Splash Icons...");
            GenerateSplashIcon(character, @"android/app/src/main/res/drawable/splash_icon.png", 512, 330);
            GenerateSplashIcon(character, @"android/app/src/main/res/drawable-mdpi/splash_icon.png", 128, 82);
            GenerateSplashIcon(character, @"android/app/src/main/res/drawable-hdpi/splash_icon.png", 192, 124);
            GenerateSplashIcon(character, @"android/app/src/main/res/drawable-xhdpi/splash_icon.png", 256, 165);
            GenerateSplashIcon(character, @"android/app/src/main/res/drawable-xxhdpi/splash_icon.png", 384, 248);
            GenerateSplashIcon(character, @"android/app/src/main/res/drawable-xxxhdpi/splash_icon.png", 512, 330);
            GenerateSplashIcon(character, @"assets/icons/splash_icon.png", 512, 330);

            // 2. Splash Branding (Light Theme: #03323A / #23818D)
            Console.WriteLine("Generating Splash Branding (Light)...");
            GenerateSplashBranding(@"android/app/src/main/res/drawable/splash_branding.png", 400, 160, 26, 14, BrandPrimary, BrandTeal);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-mdpi/splash_branding.png", 200, 80, 13, 7, BrandPrimary, BrandTeal);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-hdpi/splash_branding.png", 300, 120, 19, 10, BrandPrimary, BrandTeal);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-xhdpi/splash_branding.png", 400, 160, 26, 14, BrandPrimary, BrandTeal);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-xxhdpi/splash_branding.png", 600, 240, 39, 21, BrandPrimary, BrandTeal);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-xxxhdpi/splash_branding.png", 800, 320, 52, 28, BrandPrimary, BrandTeal);

            // 3. Splash Branding (Night Theme: #F8FAFC / #A6B4C9)
            Console.WriteLine("Generating Splash Branding (Night)...");
            GenerateSplashBranding(@"android/app/src/main/res/drawable-night/splash_branding.png", 400, 160, 26, 14, NightPrimary, NightTeal);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-night-mdpi/splash_branding.png", 200, 80, 13, 7, NightPrimary, NightTeal);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-night-hdpi/splash_branding.png", 300, 120, 19, 10, NightPrimary, NightTeal);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-night-xhdpi/splash_branding.png", 400, 160, 26, 14, NightPrimary, NightTeal);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-night-xxhdpi/splash_branding.png", 600, 240, 39, 21, NightPrimary, NightTeal);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-night-xxxhdpi/splash_branding.png", 800, 320, 52, 28, NightPrimary, NightTeal);

            // 4. Composite Splash Art (1024x1024)
            Console.WriteLine("Generating Composite Splash Art...");
            GenerateCompositeSplash(character, @"assets/icons/splash.png");

            // 5. Adaptive Icon Foregrounds (Android 108dp canvas safe zone is 66dp circle, 0.52f provides safe margins)
            Console.WriteLine("Generating Adaptive Foregrounds...");
            GenerateAdaptiveForeground(character, @"android/app/src/main/res/drawable/ic_launcher_foreground.png", 432, 0.52f);
            GenerateAdaptiveForeground(character, @"android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png", 108, 0.52f);
            GenerateAdaptiveForeground(character, @"android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png", 162, 0.52f);
            GenerateAdaptiveForeground(character, @"android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png", 216, 0.52f);
            GenerateAdaptiveForeground(character, @"android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png", 324, 0.52f);
            GenerateAdaptiveForeground(character, @"android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png", 432, 0.52f);

            // 6. Square Mipmaps (Warm off-white #F6F5F2 background with comfortable 0.68f padding)
            Console.WriteLine("Generating Square Mipmaps...");
            GenerateMipmapIcon(character, @"android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48, 0.68f);
            GenerateMipmapIcon(character, @"android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72, 0.68f);
            GenerateMipmapIcon(character, @"android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96, 0.68f);
            GenerateMipmapIcon(character, @"android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144, 0.68f);
            GenerateMipmapIcon(character, @"android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192, 0.68f);

            // 7. Round Mipmaps (circle-masked #F6F5F2 background with comfortable 0.62f padding)
            Console.WriteLine("Generating Round Mipmaps...");
            GenerateMipmapRoundIcon(character, @"android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png", 48, 0.62f);
            GenerateMipmapRoundIcon(character, @"android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png", 72, 0.62f);
            GenerateMipmapRoundIcon(character, @"android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png", 96, 0.62f);
            GenerateMipmapRoundIcon(character, @"android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png", 144, 0.62f);
            GenerateMipmapRoundIcon(character, @"android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png", 192, 0.62f);

            // 8. Flutter App Icon Assets (#F6F5F2 background, 0.70f scaling)
            Console.WriteLine("Generating Flutter Assets app_icon.png & wizard.png...");
            GenerateSquareIconWithBg(character, @"assets/icons/app_icon.png", 512, 0.70f);
            GenerateSquareIconWithBg(character, @"assets/icons/wizard.png", 512, 0.70f);

            // 9. Android Notification Small Icons (Monochrome white silhouette with transparent cutouts)
            Console.WriteLine("Generating Notification Small Icons (ic_notification.png)...");
            using (Bitmap monochromeOwl = CreateMonochromeNotificationSilhouette(character))
            {
                GenerateNotificationIcon(monochromeOwl, @"android/app/src/main/res/drawable-mdpi/ic_notification.png", 24);
                GenerateNotificationIcon(monochromeOwl, @"android/app/src/main/res/drawable-hdpi/ic_notification.png", 36);
                GenerateNotificationIcon(monochromeOwl, @"android/app/src/main/res/drawable-xhdpi/ic_notification.png", 48);
                GenerateNotificationIcon(monochromeOwl, @"android/app/src/main/res/drawable-xxhdpi/ic_notification.png", 72);
                GenerateNotificationIcon(monochromeOwl, @"android/app/src/main/res/drawable-xxxhdpi/ic_notification.png", 96);
                GenerateNotificationIcon(monochromeOwl, @"android/app/src/main/res/drawable/ic_notification.png", 48);
            }
        }

        Console.WriteLine("All modern V1 launcher, splash, branding, and notification assets generated successfully!");
    }

    private static Bitmap CreateCutout(Bitmap src)
    {
        int w = src.Width;
        int h = src.Height;
        Bitmap res = new Bitmap(w, h, PixelFormat.Format32bppArgb);

        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                res.SetPixel(x, y, src.GetPixel(x, y));
            }
        }

        bool[,] visited = new bool[w, h];
        Queue<Point> queue = new Queue<Point>();

        for (int x = 0; x < w; x++)
        {
            CheckAndEnqueue(src, visited, queue, x, 0, w, h);
            CheckAndEnqueue(src, visited, queue, x, h - 1, w, h);
        }
        for (int y = 0; y < h; y++)
        {
            CheckAndEnqueue(src, visited, queue, 0, y, w, h);
            CheckAndEnqueue(src, visited, queue, w - 1, y, w, h);
        }

        while (queue.Count > 0)
        {
            Point p = queue.Dequeue();
            res.SetPixel(p.X, p.Y, Color.FromArgb(0, 0, 0, 0));

            CheckAndEnqueue(src, visited, queue, p.X + 1, p.Y, w, h);
            CheckAndEnqueue(src, visited, queue, p.X - 1, p.Y, w, h);
            CheckAndEnqueue(src, visited, queue, p.X, p.Y + 1, w, h);
            CheckAndEnqueue(src, visited, queue, p.X, p.Y - 1, w, h);
        }

        return res;
    }

    private static void CheckAndEnqueue(Bitmap src, bool[,] visited, Queue<Point> queue, int px, int py, int w, int h)
    {
        if (px >= 0 && px < w && py >= 0 && py < h && !visited[px, py])
        {
            Color c = src.GetPixel(px, py);
            if (c.R >= 238 && c.G >= 238 && c.B >= 238)
            {
                visited[px, py] = true;
                queue.Enqueue(new Point(px, py));
            }
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

    private static void GenerateSplashIcon(Bitmap owl, string path, int canvasSize, int targetOwlSize)
    {
        EnsureDirectory(path);
        using (Bitmap bmp = new Bitmap(canvasSize, canvasSize, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            ConfigureGraphics(g);
            g.Clear(Color.Transparent);

            float scale = (float)targetOwlSize / Math.Max(owl.Width, owl.Height);
            int drawW = (int)(owl.Width * scale);
            int drawH = (int)(owl.Height * scale);
            int drawX = (canvasSize - drawW) / 2;
            int drawY = (canvasSize - drawH) / 2;

            g.DrawImage(owl, new Rectangle(drawX, drawY, drawW, drawH));
            bmp.Save(path, ImageFormat.Png);
        }
    }

    private static void GenerateSplashBranding(string path, int w, int h, float titleSize, float subSize, Color titleColor, Color subColor)
    {
        EnsureDirectory(path);
        using (Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            ConfigureGraphics(g);
            g.Clear(Color.Transparent);

            using (Font titleFont = new Font("Segoe UI", titleSize, FontStyle.Bold, GraphicsUnit.Pixel))
            using (Font subFont = new Font("Segoe UI", subSize, FontStyle.Regular, GraphicsUnit.Pixel))
            using (Brush titleBrush = new SolidBrush(titleColor))
            using (Brush subBrush = new SolidBrush(subColor))
            using (StringFormat sf = new StringFormat())
            {
                sf.Alignment = StringAlignment.Center;
                sf.LineAlignment = StringAlignment.Center;

                float titleY = h * 0.36f;
                float subY = h * 0.72f;

                g.DrawString("KALS MONEY MANAGER", titleFont, titleBrush, new PointF(w / 2f, titleY), sf);
                g.DrawString("Personal Financial Manager", subFont, subBrush, new PointF(w / 2f, subY), sf);
            }
            bmp.Save(path, ImageFormat.Png);
        }
    }

    private static void GenerateCompositeSplash(Bitmap owl, string path)
    {
        EnsureDirectory(path);
        int size = 1024;
        using (Bitmap bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            ConfigureGraphics(g);
            g.Clear(WarmOffWhite);

            int owlTarget = 520;
            float scale = (float)owlTarget / Math.Max(owl.Width, owl.Height);
            int drawW = (int)(owl.Width * scale);
            int drawH = (int)(owl.Height * scale);
            int drawX = (size - drawW) / 2;
            int drawY = (int)(size * 0.18f);

            g.DrawImage(owl, new Rectangle(drawX, drawY, drawW, drawH));

            using (Font titleFont = new Font("Segoe UI", 48, FontStyle.Bold, GraphicsUnit.Pixel))
            using (Font subFont = new Font("Segoe UI", 24, FontStyle.Regular, GraphicsUnit.Pixel))
            using (Brush titleBrush = new SolidBrush(BrandPrimary))
            using (Brush subBrush = new SolidBrush(BrandTeal))
            using (StringFormat sf = new StringFormat())
            {
                sf.Alignment = StringAlignment.Center;
                sf.LineAlignment = StringAlignment.Center;

                g.DrawString("Kals Money Manager", titleFont, titleBrush, new PointF(size / 2f, size * 0.78f), sf);
                g.DrawString("Dependable Offline Financial Management", subFont, subBrush, new PointF(size / 2f, size * 0.85f), sf);
            }

            bmp.Save(path, ImageFormat.Png);
        }
    }

    private static void GenerateAdaptiveForeground(Bitmap owl, string path, int canvasSize, float safeRatio)
    {
        EnsureDirectory(path);
        using (Bitmap bmp = new Bitmap(canvasSize, canvasSize, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            ConfigureGraphics(g);
            g.Clear(Color.Transparent);

            int targetSize = (int)(canvasSize * safeRatio);
            float scale = (float)targetSize / Math.Max(owl.Width, owl.Height);
            int drawW = (int)(owl.Width * scale);
            int drawH = (int)(owl.Height * scale);
            int drawX = (canvasSize - drawW) / 2;
            int drawY = (canvasSize - drawH) / 2;

            g.DrawImage(owl, new Rectangle(drawX, drawY, drawW, drawH));
            bmp.Save(path, ImageFormat.Png);
        }
    }

    private static void GenerateMipmapIcon(Bitmap owl, string path, int size, float scaleRatio)
    {
        EnsureDirectory(path);
        using (Bitmap bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            ConfigureGraphics(g);
            g.Clear(WarmOffWhite);

            int targetSize = (int)(size * scaleRatio);
            float scale = (float)targetSize / Math.Max(owl.Width, owl.Height);
            int drawW = (int)(owl.Width * scale);
            int drawH = (int)(owl.Height * scale);
            int drawX = (size - drawW) / 2;
            int drawY = (size - drawH) / 2;

            g.DrawImage(owl, new Rectangle(drawX, drawY, drawW, drawH));
            bmp.Save(path, ImageFormat.Png);
        }
    }

    private static void GenerateMipmapRoundIcon(Bitmap owl, string path, int size, float scaleRatio)
    {
        EnsureDirectory(path);
        using (Bitmap bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            ConfigureGraphics(g);
            g.Clear(Color.Transparent);

            using (GraphicsPath clipPath = new GraphicsPath())
            {
                clipPath.AddEllipse(0, 0, size, size);
                using (Brush bgBrush = new SolidBrush(WarmOffWhite))
                {
                    g.FillPath(bgBrush, clipPath);
                }
                g.SetClip(clipPath);

                int targetSize = (int)(size * scaleRatio);
                float scale = (float)targetSize / Math.Max(owl.Width, owl.Height);
                int drawW = (int)(owl.Width * scale);
                int drawH = (int)(owl.Height * scale);
                int drawX = (size - drawW) / 2;
                int drawY = (size - drawH) / 2;

                g.DrawImage(owl, new Rectangle(drawX, drawY, drawW, drawH));
            }
            bmp.Save(path, ImageFormat.Png);
        }
    }

    private static void GenerateSquareIconWithBg(Bitmap owl, string path, int size, float scaleRatio)
    {
        EnsureDirectory(path);
        using (Bitmap bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            ConfigureGraphics(g);
            g.Clear(WarmOffWhite);

            int targetSize = (int)(size * scaleRatio);
            float scale = (float)targetSize / Math.Max(owl.Width, owl.Height);
            int drawW = (int)(owl.Width * scale);
            int drawH = (int)(owl.Height * scale);
            int drawX = (size - drawW) / 2;
            int drawY = (size - drawH) / 2;

            g.DrawImage(owl, new Rectangle(drawX, drawY, drawW, drawH));
            bmp.Save(path, ImageFormat.Png);
        }
    }

    private static Bitmap CreateMonochromeNotificationSilhouette(Bitmap src)
    {
        int w = src.Width;
        int h = src.Height;
        Bitmap res = new Bitmap(w, h, PixelFormat.Format32bppArgb);

        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                Color p = src.GetPixel(x, y);
                if (p.A < 30)
                {
                    res.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
                }
                else
                {
                    // Eye cutouts (white eye area in original character above mid-height) or beak cutout
                    bool isEyeWhite = (p.R > 240 && p.G > 240 && p.B > 240 && y < h / 2);
                    bool isBeak = (p.R > 200 && p.G > 140 && p.B < 60);

                    if (isEyeWhite || isBeak)
                    {
                        res.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
                    }
                    else
                    {
                        // Android requires solid white foreground pixels with alpha transparency
                        res.SetPixel(x, y, Color.FromArgb(p.A, 255, 255, 255));
                    }
                }
            }
        }
        return res;
    }

    private static void GenerateNotificationIcon(Bitmap monochrome, string path, int size)
    {
        EnsureDirectory(path);
        using (Bitmap bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            ConfigureGraphics(g);
            g.Clear(Color.Transparent);

            // 5% padding keeps icon well within Android safe limits (24->22, 48->44, 72->66, 96->88)
            int pad = Math.Max(1, (int)(size * 0.05f));
            int drawSize = size - (2 * pad);
            float scale = (float)drawSize / Math.Max(monochrome.Width, monochrome.Height);
            int drawW = (int)(monochrome.Width * scale);
            int drawH = (int)(monochrome.Height * scale);
            int drawX = (size - drawW) / 2;
            int drawY = (size - drawH) / 2;

            g.DrawImage(monochrome, new Rectangle(drawX, drawY, drawW, drawH));

            // Strictly enforce pure white RGB (255,255,255) with alpha transparency on all pixels
            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    Color p = bmp.GetPixel(x, y);
                    if (p.A > 0)
                    {
                        bmp.SetPixel(x, y, Color.FromArgb(p.A, 255, 255, 255));
                    }
                }
            }

            bmp.Save(path, ImageFormat.Png);
        }
    }

    private static void ConfigureGraphics(Graphics g)
    {
        g.SmoothingMode = SmoothingMode.HighQuality;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
    }
}
