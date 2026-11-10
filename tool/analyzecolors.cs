using System;
using System.Drawing;

class AnalyzeColors
{
    static void Main(string[] args)
    {
        string path = args.Length > 0 ? args[0] : "assets/icons/money-manager-icon.jpg";
        using (Bitmap bmp = new Bitmap(path))
        {
            Console.WriteLine("Image dimensions: " + bmp.Width + "x" + bmp.Height);
            
            PrintPixel(bmp, 220, 360, "Face ring teal");
            PrintPixel(bmp, 200, 320, "Face ring teal 2");
            PrintPixel(bmp, 150, 550, "Dark body / wings");
            PrintPixel(bmp, 512, 120, "Dark head top");
            PrintPixel(bmp, 512, 720, "Belly center");
            PrintPixel(bmp, 480, 720, "Belly mid");
            PrintPixel(bmp, 512, 480, "Beak gold");
            PrintPixel(bmp, 530, 480, "Beak shadow/side");
            PrintPixel(bmp, 20, 20, "Background corner");
        }
    }

    static void PrintPixel(Bitmap bmp, int x, int y, string label)
    {
        Color c = bmp.GetPixel(x, y);
        Console.WriteLine(string.Format("{0,-20} at ({1},{2}): #{3:X2}{4:X2}{5:X2} (R:{3}, G:{4}, B:{5})",
            label, x, y, c.R, c.G, c.B));
    }
}
