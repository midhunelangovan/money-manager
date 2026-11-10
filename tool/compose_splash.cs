using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;

public class ComposeSplash
{
    public static void Main()
    {
        string mascotPath = @"C:\Users\Midhun Sasikala\OneDrive\Desktop\Cheerful Beaver with Golden Dollar Coin.png";
        using (Bitmap raw = new Bitmap(mascotPath))
        {
            using (Bitmap mascot = CreateCutout(raw))
            {
                // Create a 1024x1024 splash icon composition
                using (Bitmap splash = new Bitmap(1024, 1024, PixelFormat.Format32bppArgb))
                {
                    using (Graphics g = Graphics.FromImage(splash))
                    {
                        g.Clear(Color.Transparent);
                        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        g.SmoothingMode = SmoothingMode.HighQuality;
                        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                        g.CompositingQuality = CompositingQuality.HighQuality;
                        g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;

                        // Mascot in upper portion: 580x580 centered
                        int mascotSize = 580;
                        int mascotX = (1024 - mascotSize) / 2;
                        int mascotY = 120; // Top padding

                        g.DrawImage(mascot, new Rectangle(mascotX, mascotY, mascotSize, mascotSize));

                        // App Name below mascot: "Kals Money Manager"
                        // Line 1: "Kals" (Bold, large)
                        // Line 2: "Money Manager" (Sophisticated tracking, semi-bold)
                        using (Font fontKals = new Font("Segoe UI", 68, FontStyle.Bold, GraphicsUnit.Pixel))
                        using (Font fontSub = new Font("Segoe UI", 40, FontStyle.Bold, GraphicsUnit.Pixel))
                        using (SolidBrush textBrush = new SolidBrush(Color.FromArgb(255, 30, 41, 59))) // #1E293B Slate 800
                        using (SolidBrush subBrush = new SolidBrush(Color.FromArgb(255, 71, 85, 105)))  // #475569 Slate 600
                        {
                            StringFormat sf = new StringFormat
                            {
                                Alignment = StringAlignment.Center,
                                LineAlignment = StringAlignment.Center
                            };

                            // "Kals"
                            g.DrawString("Kals", fontKals, textBrush, new RectangleF(0, mascotY + mascotSize + 25, 1024, 80), sf);

                            // "Money Manager"
                            g.DrawString("MONEY MANAGER", fontSub, subBrush, new RectangleF(0, mascotY + mascotSize + 115, 1024, 55), sf);
                        }
                    }

                    splash.Save(@"tool\composed_splash_preview.png", ImageFormat.Png);
                    Console.WriteLine("Saved tool\\composed_splash_preview.png");
                }
            }
        }
    }

    private static Bitmap CreateCutout(Bitmap original)
    {
        int w = original.Width;
        int h = original.Height;
        Bitmap transparent = new Bitmap(w, h, PixelFormat.Format32bppArgb);

        bool[,] isBg = new bool[w, h];
        Queue<Point> q = new Queue<Point>();

        for (int x = 0; x < w; x++)
        {
            CheckAndPush(original, isBg, q, x, 0);
            CheckAndPush(original, isBg, q, x, h - 1);
        }
        for (int y = 0; y < h; y++)
        {
            CheckAndPush(original, isBg, q, 0, y);
            CheckAndPush(original, isBg, q, w - 1, y);
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
                    CheckAndPush(original, isBg, q, nx, ny);
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

    private static void CheckAndPush(Bitmap img, bool[,] isBg, Queue<Point> q, int x, int y)
    {
        if (isBg[x, y]) return;
        Color c = img.GetPixel(x, y);
        if (c.R >= 246 && c.G >= 246 && c.B >= 246)
        {
            isBg[x, y] = true;
            q.Enqueue(new Point(x, y));
        }
    }
}
