using System;
using System.Drawing;

public class Inspect
{
    public static void Main()
    {
        using (Bitmap b = new Bitmap(@"tool\temp_splash.png"))
        {
            Console.WriteLine("Splash Dimensions: " + b.Width + "x" + b.Height);
            Console.WriteLine("Top (0,0): " + b.GetPixel(0, 0));
            Console.WriteLine("Top (w/2, 50): " + b.GetPixel(b.Width / 2, 50));
            Console.WriteLine("Bottom (w/2, h-50): " + b.GetPixel(b.Width / 2, b.Height - 50));
            Console.WriteLine("Left (50, h/2): " + b.GetPixel(50, b.Height / 2));
            Console.WriteLine("Right (w-50, h/2): " + b.GetPixel(b.Width - 50, b.Height / 2));

            // Check non-white bounding box
            int minX = b.Width, maxX = 0, minY = b.Height, maxY = 0;
            for (int y = 0; y < b.Height; y++)
            {
                for (int x = 0; x < b.Width; x++)
                {
                    Color c = b.GetPixel(x, y);
                    if (c.R < 245 || c.G < 245 || c.B < 240)
                    {
                        if (x < minX) minX = x;
                        if (x > maxX) maxX = x;
                        if (y < minY) minY = y;
                        if (y > maxY) maxY = y;
                    }
                }
            }
            Console.WriteLine(string.Format("Artwork Bounding Box: X=[{0}, {1}], Y=[{2}, {3}], W={4}, H={5}",
                minX, maxX, minY, maxY, maxX - minX + 1, maxY - minY + 1));
        }
    }
}
