using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public class TestAppIconCutout
{
    public static void Main()
    {
        using (Bitmap src = new Bitmap(@"tool\temp_app_icon.png"))
        {
            int w = src.Width;
            int h = src.Height;
            Bitmap transparent = new Bitmap(w, h, PixelFormat.Format32bppArgb);

            bool[,] isBg = new bool[w, h];
            Queue<Point> q = new Queue<Point>();

            // Seeds along edges
            for (int x = 0; x < w; x++)
            {
                CheckAndPush(src, isBg, q, x, 0);
                CheckAndPush(src, isBg, q, x, h - 1);
            }
            for (int y = 0; y < h; y++)
            {
                CheckAndPush(src, isBg, q, 0, y);
                CheckAndPush(src, isBg, q, w - 1, y);
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
                        CheckAndPush(src, isBg, q, nx, ny);
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
                        transparent.SetPixel(x, y, src.GetPixel(x, y));
                    }
                }
            }

            transparent.Save(@"tool\test_app_icon_cutout.png", ImageFormat.Png);
            Console.WriteLine("Saved tool\\test_app_icon_cutout.png");
        }
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
