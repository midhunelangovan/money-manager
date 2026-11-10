using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.IO;

public class GenerateHdSplash
{
    private static readonly Color WarmOffWhite = Color.FromArgb(255, 246, 245, 242); // #F6F5F2
    private static readonly Color NavyPrimary = Color.FromArgb(255, 30, 58, 95);      // #1E3A5F
    private static readonly Color SlateSecondary = Color.FromArgb(255, 100, 116, 139); // #64748B

    public static void Main(string[] args)
    {
        string animalPath = @"assets/icons/animal.png";
        if (!File.Exists(animalPath))
        {
            Console.WriteLine("Error: animal.png not found at " + animalPath);
            return;
        }

        Console.WriteLine("=== Generating HD Splash Screen & App Icon Assets from animal.png ===");

        using (Bitmap rawOwl = new Bitmap(animalPath))
        {
            // -------------------------------------------------------------
            // 1. Splash Icon (Centered owl with 160dp circular safe zone)
            // -------------------------------------------------------------
            // For a 512x512 canvas, Android 12+ masks to a circle of diameter 341px (160dp / 240dp).
            // Sizing the owl to 330x330 guarantees 100% of the owl is visible and unclipped.
            Console.WriteLine("Generating Android Splash Icons...");
            GenerateSplashIcon(rawOwl, @"android/app/src/main/res/drawable/splash_icon.png", 512, 330);
            GenerateSplashIcon(rawOwl, @"android/app/src/main/res/drawable-mdpi/splash_icon.png", 128, 82);
            GenerateSplashIcon(rawOwl, @"android/app/src/main/res/drawable-hdpi/splash_icon.png", 192, 124);
            GenerateSplashIcon(rawOwl, @"android/app/src/main/res/drawable-xhdpi/splash_icon.png", 256, 165);
            GenerateSplashIcon(rawOwl, @"android/app/src/main/res/drawable-xxhdpi/splash_icon.png", 384, 248);
            GenerateSplashIcon(rawOwl, @"android/app/src/main/res/drawable-xxxhdpi/splash_icon.png", 512, 330);
            GenerateSplashIcon(rawOwl, @"assets/icons/splash_icon.png", 512, 330);

            // -------------------------------------------------------------
            // 2. Splash Branding ("Kals Money Manager")
            // -------------------------------------------------------------
            // Android 12+ supports windowSplashScreenBrandingImage (max 200x80 dp)
            Console.WriteLine("Generating Android Splash Branding Images...");
            GenerateSplashBranding(@"android/app/src/main/res/drawable/splash_branding.png", 400, 160, 48, 22);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-mdpi/splash_branding.png", 200, 80, 24, 11);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-hdpi/splash_branding.png", 300, 120, 36, 16);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-xhdpi/splash_branding.png", 400, 160, 48, 22);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-xxhdpi/splash_branding.png", 600, 240, 72, 33);
            GenerateSplashBranding(@"android/app/src/main/res/drawable-xxxhdpi/splash_branding.png", 800, 320, 96, 44);

            // -------------------------------------------------------------
            // 3. Composite Splash Art (1024x1024 in assets/icons/splash.png)
            // -------------------------------------------------------------
            Console.WriteLine("Generating High-Res Composite Splash (assets/icons/splash.png)...");
            GenerateCompositeSplash(rawOwl, @"assets/icons/splash.png");

            // -------------------------------------------------------------
            // 4. Android Launcher Icons (Warm off-white background #F6F5F2)
            // -------------------------------------------------------------
            Console.WriteLine("Generating Launcher Icon Assets...");
            // Adaptive Foreground (432x432 canvas, owl ~330px centered = ratio 0.76 to stay inside circular safe area)
            GenerateAdaptiveForeground(rawOwl, @"android/app/src/main/res/drawable/ic_launcher_foreground.png", 432, 0.78f);
            GenerateAdaptiveForeground(rawOwl, @"android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png", 108, 0.78f);
            GenerateAdaptiveForeground(rawOwl, @"android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png", 162, 0.78f);
            GenerateAdaptiveForeground(rawOwl, @"android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png", 216, 0.78f);
            GenerateAdaptiveForeground(rawOwl, @"android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png", 324, 0.78f);
            GenerateAdaptiveForeground(rawOwl, @"android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png", 432, 0.78f);

            // Legacy Square Mipmaps (solid #F6F5F2 background)
            GenerateMipmapIcon(rawOwl, @"android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48, 0.84f);
            GenerateMipmapIcon(rawOwl, @"android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72, 0.84f);
            GenerateMipmapIcon(rawOwl, @"android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96, 0.84f);
            GenerateMipmapIcon(rawOwl, @"android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144, 0.84f);
            GenerateMipmapIcon(rawOwl, @"android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192, 0.84f);

            // Round Mipmaps (circle masked #F6F5F2 background)
            GenerateMipmapRoundIcon(rawOwl, @"android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png", 48, 0.80f);
            GenerateMipmapRoundIcon(rawOwl, @"android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png", 72, 0.80f);
            GenerateMipmapRoundIcon(rawOwl, @"android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png", 96, 0.80f);
            GenerateMipmapRoundIcon(rawOwl, @"android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png", 144, 0.80f);
            GenerateMipmapRoundIcon(rawOwl, @"android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png", 192, 0.80f);

            // Flutter assets app icon
            GenerateSquareIconWithBg(rawOwl, @"assets/icons/app_icon.png", 512, 0.84f);
            GenerateSquareIconWithBg(rawOwl, @"assets/icons/wizard.png", 512, 0.84f);
        }

        Console.WriteLine("All HD Splash Screen & Icon assets generated successfully!");
    }

    private static void EnsureDirectory(string path)
    {
        string dir = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
        {
            Directory.CreateDirectory(dir);
        }
    }

    private static void ConfigureGraphics(Graphics g)
    {
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.SmoothingMode = SmoothingMode.HighQuality;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.CompositingQuality = CompositingQuality.HighQuality;
        g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
    }

    private static void GenerateSplashIcon(Bitmap src, string outputPath, int canvasSize, int contentSize)
    {
        EnsureDirectory(outputPath);
        using (Bitmap dest = new Bitmap(canvasSize, canvasSize, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(Color.Transparent);
                ConfigureGraphics(g);

                int offset = (canvasSize - contentSize) / 2;
                g.DrawImage(src, new Rectangle(offset, offset, contentSize, contentSize));
            }
            dest.Save(outputPath, ImageFormat.Png);
        }
        Console.WriteLine("Saved: " + outputPath);
    }

    private static void GenerateSplashBranding(string outputPath, int width, int height, float kalsFontSize, float subFontSize)
    {
        EnsureDirectory(outputPath);
        using (Bitmap dest = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(Color.Transparent);
                ConfigureGraphics(g);

                using (Font fontKals = new Font("Segoe UI", kalsFontSize, FontStyle.Bold, GraphicsUnit.Pixel))
                using (Font fontSub = new Font("Segoe UI", subFontSize, FontStyle.Bold, GraphicsUnit.Pixel))
                using (SolidBrush brushKals = new SolidBrush(NavyPrimary))
                using (SolidBrush brushSub = new SolidBrush(SlateSecondary))
                {
                    StringFormat sf = new StringFormat
                    {
                        Alignment = StringAlignment.Center,
                        LineAlignment = StringAlignment.Center
                    };

                    float kalsHeight = height * 0.52f;
                    float subHeight = height * 0.36f;
                    float topMargin = height * 0.04f;

                    g.DrawString("Kals", fontKals, brushKals, new RectangleF(0, topMargin, width, kalsHeight), sf);
                    g.DrawString("MONEY MANAGER", fontSub, brushSub, new RectangleF(0, topMargin + kalsHeight, width, subHeight), sf);
                }
            }
            dest.Save(outputPath, ImageFormat.Png);
        }
        Console.WriteLine("Saved: " + outputPath);
    }

    private static void GenerateCompositeSplash(Bitmap src, string outputPath)
    {
        EnsureDirectory(outputPath);
        int canvasSize = 1024;
        using (Bitmap dest = new Bitmap(canvasSize, canvasSize, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(Color.Transparent);
                ConfigureGraphics(g);

                int owlSize = 540;
                int owlX = (canvasSize - owlSize) / 2;
                int owlY = 120;
                g.DrawImage(src, new Rectangle(owlX, owlY, owlSize, owlSize));

                using (Font fontKals = new Font("Segoe UI", 72, FontStyle.Bold, GraphicsUnit.Pixel))
                using (Font fontSub = new Font("Segoe UI", 36, FontStyle.Bold, GraphicsUnit.Pixel))
                using (SolidBrush brushKals = new SolidBrush(NavyPrimary))
                using (SolidBrush brushSub = new SolidBrush(SlateSecondary))
                {
                    StringFormat sf = new StringFormat
                    {
                        Alignment = StringAlignment.Center,
                        LineAlignment = StringAlignment.Center
                    };

                    g.DrawString("Kals", fontKals, brushKals, new RectangleF(0, owlY + owlSize + 24, canvasSize, 85), sf);
                    g.DrawString("MONEY MANAGER", fontSub, brushSub, new RectangleF(0, owlY + owlSize + 115, canvasSize, 55), sf);
                }
            }
            dest.Save(outputPath, ImageFormat.Png);
        }
        Console.WriteLine("Saved: " + outputPath);
    }

    private static void GenerateAdaptiveForeground(Bitmap src, string outputPath, int size, float ratio)
    {
        EnsureDirectory(outputPath);
        using (Bitmap dest = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(Color.Transparent);
                ConfigureGraphics(g);

                int targetSize = (int)(size * ratio);
                int offset = (size - targetSize) / 2;
                g.DrawImage(src, new Rectangle(offset, offset, targetSize, targetSize));
            }
            dest.Save(outputPath, ImageFormat.Png);
        }
        Console.WriteLine("Saved: " + outputPath);
    }

    private static void GenerateSquareIconWithBg(Bitmap src, string outputPath, int size, float ratio)
    {
        EnsureDirectory(outputPath);
        using (Bitmap dest = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(WarmOffWhite);
                ConfigureGraphics(g);

                int targetSize = (int)(size * ratio);
                int offset = (size - targetSize) / 2;
                g.DrawImage(src, new Rectangle(offset, offset, targetSize, targetSize));
            }
            dest.Save(outputPath, ImageFormat.Png);
        }
        Console.WriteLine("Saved: " + outputPath);
    }

    private static void GenerateMipmapIcon(Bitmap src, string outputPath, int size, float ratio)
    {
        EnsureDirectory(outputPath);
        using (Bitmap dest = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(WarmOffWhite);
                ConfigureGraphics(g);

                int targetSize = (int)(size * ratio);
                int offset = (size - targetSize) / 2;
                g.DrawImage(src, new Rectangle(offset, offset, targetSize, targetSize));
            }
            dest.Save(outputPath, ImageFormat.Png);
        }
        Console.WriteLine("Saved: " + outputPath);
    }

    private static void GenerateMipmapRoundIcon(Bitmap src, string outputPath, int size, float ratio)
    {
        EnsureDirectory(outputPath);
        using (Bitmap dest = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(Color.Transparent);
                ConfigureGraphics(g);

                using (GraphicsPath path = new GraphicsPath())
                {
                    path.AddEllipse(0, 0, size - 1, size - 1);
                    using (SolidBrush brush = new SolidBrush(WarmOffWhite))
                    {
                        g.FillPath(brush, path);
                    }
                    g.SetClip(path);

                    int targetSize = (int)(size * ratio);
                    int offset = (size - targetSize) / 2;
                    g.DrawImage(src, new Rectangle(offset, offset, targetSize, targetSize));
                }
            }
            dest.Save(outputPath, ImageFormat.Png);
        }
        Console.WriteLine("Saved: " + outputPath);
    }
}
