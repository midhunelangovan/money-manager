using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public class TestCutout
{
    public static void Main()
    {
        string inputPath = @"C:\Users\Midhun Sasikala\OneDrive\Desktop\Cheerful Beaver with Golden Dollar Coin.png";
        using (Bitmap original = new Bitmap(inputPath))
        {
            int w = original.Width;
            int h = original.Height;
            Bitmap transparent = new Bitmap(w, h, PixelFormat.Format32bppArgb);

            bool[,] isBg = new bool[w, h];
            Queue<Point> q = new Queue<Point>();

            // Seeds along edges
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

            int bgCount = 0;
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    if (isBg[x, y])
                    {
                        bgCount++;
                        transparent.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
                    }
                    else
                    {
                        transparent.SetPixel(x, y, original.GetPixel(x, y));
                    }
                }
            }

            Console.WriteLine(string.Format("Total pixels: {0}, Background pixels: {1} ({2:F1}%)",
                w * h, bgCount, (100.0 * bgCount) / (w * h)));

            transparent.Save(@"tool\test_transparent.png", ImageFormat.Png);
            Console.WriteLine("Saved tool\\test_transparent.png");
        }
    }

    private static void CheckAndPush(Bitmap img, bool[,] isBg, Queue<Point> q, int x, int y)
    {
        if (isBg[x, y]) return;
        Color c = img.GetPixel(x, y);
        // If near white
        if (c.R >= 246 && c.G >= 246 && c.B >= 246)
        {
            isBg[x, y] = true;
            q.Enqueue(new Point(x, y));
        }
    }
}
