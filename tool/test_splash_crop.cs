using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public class TestSplashCrop
{
    public static void Main()
    {
        using (Bitmap src = new Bitmap(@"tool\temp_splash.png"))
        {
            // Artwork is X=[19, 918], Y=[529, 1236]
            // Center is X=468, Y=882
            // Let's crop a square centered on the artwork:
            int size = Math.Max(900, 708) + 60; // ~960
            int cropX = (19 + 918) / 2 - size / 2;
            int cropY = (529 + 1236) / 2 - size / 2;

            using (Bitmap square = new Bitmap(size, size, PixelFormat.Format32bppArgb))
            {
                using (Graphics g = Graphics.FromImage(square))
                {
                    g.Clear(Color.Transparent);
                    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    g.SmoothingMode = SmoothingMode.HighQuality;
                    g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                    g.CompositingQuality = CompositingQuality.HighQuality;

                    // Draw image with offset
                    g.DrawImage(src, new Rectangle(-cropX, -cropY, src.Width, src.Height));
                }

                // Remove outer white pixels with flood fill
                RemoveOuterWhite(square);

                // Resize to 512x512
                using (Bitmap dest = new Bitmap(512, 512, PixelFormat.Format32bppArgb))
                {
                    using (Graphics g = Graphics.FromImage(dest))
                    {
                        g.Clear(Color.Transparent);
                        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        g.SmoothingMode = SmoothingMode.HighQuality;
                        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                        g.CompositingQuality = CompositingQuality.HighQuality;

                        g.DrawImage(square, new Rectangle(0, 0, 512, 512));
                    }
                    dest.Save(@"tool\test_splash_icon.png", ImageFormat.Png);
                    Console.WriteLine("Saved tool\\test_splash_icon.png");
                }
            }
        }
    }

    private static void RemoveOuterWhite(Bitmap img)
    {
        int w = img.Width;
        int h = img.Height;
        bool[,] isBg = new bool[w, h];
        Queue<Point> q = new Queue<Point>();

        for (int x = 0; x < w; x++)
        {
            CheckAndPush(img, isBg, q, x, 0);
            CheckAndPush(img, isBg, q, x, h - 1);
        }
        for (int y = 0; y < h; y++)
        {
            CheckAndPush(img, isBg, q, 0, y);
            CheckAndPush(img, isBg, q, w - 1, y);
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
                    CheckAndPush(img, isBg, q, nx, ny);
                }
            }
        }

        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                if (isBg[x, y])
                {
                    img.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
                }
            }
        }
    }

    private static void CheckAndPush(Bitmap img, bool[,] isBg, Queue<Point> q, int x, int y)
    {
        if (isBg[x, y]) return;
        Color c = img.GetPixel(x, y);
        if (c.R >= 246 && c.G >= 246 && c.B >= 242)
        {
            isBg[x, y] = true;
            q.Enqueue(new Point(x, y));
        }
    }
}
