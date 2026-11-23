using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.IO;

public class DevBadgeAdder
{
    public static void Main(string[] args)
    {
        string[] adaptiveForegrounds = new string[]
        {
            @"android/app/src/main/res/drawable/ic_launcher_foreground.png",
            @"android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png",
            @"android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png",
            @"android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png",
            @"android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png",
            @"android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png",
        };

        foreach (var path in adaptiveForegrounds)
        {
            if (File.Exists(path))
            {
                ApplyDevBadgeToAdaptive(path);
            }
        }

        string[] legacySquareIcons = new string[]
        {
            @"android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
            @"android/app/src/main/res/mipmap-hdpi/ic_launcher.png",
            @"android/app/src/main/res/mipmap-xhdpi/ic_launcher.png",
            @"android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png",
            @"android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
        };

        foreach (var path in legacySquareIcons)
        {
            if (File.Exists(path))
            {
                ApplyDevBadgeToLegacy(path, isRound: false);
            }
        }

        string[] legacyRoundIcons = new string[]
        {
            @"android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png",
            @"android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png",
            @"android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png",
            @"android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png",
            @"android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png",
        };

        foreach (var path in legacyRoundIcons)
        {
            if (File.Exists(path))
            {
                ApplyDevBadgeToLegacy(path, isRound: true);
            }
        }

        Console.WriteLine("All launcher icons updated with DEV badge successfully!");
    }

    private static void ApplyDevBadgeToAdaptive(string path)
    {
        using (Bitmap original = new Bitmap(path))
        {
            int size = original.Width;
            using (Bitmap result = new Bitmap(size, size, PixelFormat.Format32bppArgb))
            {
                using (Graphics g = Graphics.FromImage(result))
                {
                    g.Clear(Color.Transparent);
                    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    g.SmoothingMode = SmoothingMode.HighQuality;
                    g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                    g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;

                    g.DrawImage(original, 0, 0, size, size);

                    // Adaptive icon: safe zone is the central 66% (diameter ~ 0.66 * size)
                    // Center is (size/2, size/2). Safe radius is 0.33 * size.
                    // For size = 432: center = 216, safe radius = 142.
                    // Let's place a badge at the bottom center or bottom right of the safe zone.
                    // Pill dimensions:
                    float badgeWidth = size * 0.22f;
                    float badgeHeight = size * 0.085f;
                    // Place at bottom center of the safe zone:
                    // Y center around size/2 + safe radius * 0.70 = 216 + 99 = 315
                    float badgeX = (size - badgeWidth) / 2.0f;
                    float badgeY = (size * 0.5f) + (size * 0.33f * 0.65f) - (badgeHeight / 2.0f);

                    DrawPillBadge(g, badgeX, badgeY, badgeWidth, badgeHeight, size);
                }
                original.Dispose();
                result.Save(path, ImageFormat.Png);
            }
        }
    }

    private static void ApplyDevBadgeToLegacy(string path, bool isRound)
    {
        using (Bitmap original = new Bitmap(path))
        {
            int size = original.Width;
            using (Bitmap result = new Bitmap(size, size, PixelFormat.Format32bppArgb))
            {
                using (Graphics g = Graphics.FromImage(result))
                {
                    g.Clear(Color.Transparent);
                    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    g.SmoothingMode = SmoothingMode.HighQuality;
                    g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                    g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;

                    g.DrawImage(original, 0, 0, size, size);

                    float badgeWidth = size * 0.38f;
                    float badgeHeight = size * 0.16f;
                    float badgeX = (size - badgeWidth) / 2.0f;
                    float badgeY = size * (isRound ? 0.74f : 0.78f) - (badgeHeight / 2.0f);

                    DrawPillBadge(g, badgeX, badgeY, badgeWidth, badgeHeight, size);
                }
                original.Dispose();
                result.Save(path, ImageFormat.Png);
            }
        }
    }

    private static void DrawPillBadge(Graphics g, float x, float y, float w, float h, int totalSize)
    {
        float radius = h / 2.0f;
        using (GraphicsPath path = GetRoundedRectPath(new RectangleF(x, y, w, h), radius))
        {
            // Drop shadow
            using (GraphicsPath shadowPath = GetRoundedRectPath(new RectangleF(x, y + totalSize * 0.005f, w, h), radius))
            {
                using (SolidBrush shadowBrush = new SolidBrush(Color.FromArgb(80, 0, 0, 0)))
                {
                    g.FillPath(shadowBrush, shadowPath);
                }
            }

            // Amber badge (#D97706 or vibrant amber #F59E0B)
            using (SolidBrush brush = new SolidBrush(Color.FromArgb(245, 158, 11))) // Amber 500
            {
                g.FillPath(brush, path);
            }

            // White border
            float penWidth = Math.Max(1.0f, totalSize * 0.006f);
            using (Pen pen = new Pen(Color.White, penWidth))
            {
                g.DrawPath(pen, path);
            }

            // Text "DEV"
            float fontSize = h * 0.58f;
            using (Font font = new Font("Arial", fontSize, FontStyle.Bold, GraphicsUnit.Pixel))
            {
                using (SolidBrush textBrush = new SolidBrush(Color.FromArgb(24, 24, 27))) // Dark slate/zinc #18181B
                {
                    StringFormat sf = new StringFormat
                    {
                        Alignment = StringAlignment.Center,
                        LineAlignment = StringAlignment.Center
                    };
                    g.DrawString("DEV", font, textBrush, new RectangleF(x, y, w, h), sf);
                }
            }
        }
    }

    private static GraphicsPath GetRoundedRectPath(RectangleF rect, float radius)
    {
        GraphicsPath path = new GraphicsPath();
        float diameter = radius * 2.0f;

        path.AddArc(rect.X, rect.Y, diameter, diameter, 180, 90);
        path.AddArc(rect.Right - diameter, rect.Y, diameter, diameter, 270, 90);
        path.AddArc(rect.Right - diameter, rect.Bottom - diameter, diameter, diameter, 0, 90);
        path.AddArc(rect.X, rect.Bottom - diameter, diameter, diameter, 90, 90);
        path.CloseFigure();

        return path;
    }
}
