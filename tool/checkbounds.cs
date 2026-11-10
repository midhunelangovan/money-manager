using System;
using System.Drawing;

class CheckBounds
{
    static void Main()
    {
        using (Bitmap bmp = new Bitmap("assets/icons/money-manager-icon.jpg"))
        {
            int minX = bmp.Width, maxX = 0, minY = bmp.Height, maxY = 0;
            for (int y = 0; y < bmp.Height; y++)
            {
                for (int x = 0; x < bmp.Width; x++)
                {
                    Color c = bmp.GetPixel(x, y);
                    // if not white / very light background
                    if (c.R < 240 || c.G < 240 || c.B < 240)
                    {
                        if (x < minX) minX = x;
                        if (x > maxX) maxX = x;
                        if (y < minY) minY = y;
                        if (y > maxY) maxY = y;
                    }
                }
            }
            Console.WriteLine(string.Format("Owl bounding box: [{0}, {1}] to [{2}, {3}], Width: {4}, Height: {5}",
                minX, minY, maxX, maxY, maxX - minX + 1, maxY - minY + 1));
        }
    }
}
