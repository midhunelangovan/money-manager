using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public class TestSplashCircle
{
    public static void Main()
    {
        using (Bitmap src = new Bitmap(@"tool\test_splash_icon.png"))
        {
            int size = 512;
            using (Bitmap dest = new Bitmap(size, size, PixelFormat.Format32bppArgb))
            {
                using (Graphics g = Graphics.FromImage(dest))
                {
                    g.Clear(Color.Transparent);
                    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    g.SmoothingMode = SmoothingMode.HighQuality;
                    g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                    g.CompositingQuality = CompositingQuality.HighQuality;

                    // Circle mask of diameter 512
                    using (GraphicsPath path = new GraphicsPath())
                    {
                        path.AddEllipse(0, 0, size, size);
                        g.SetClip(path);
                        g.Clear(Color.White);

                        // Draw source
                        g.DrawImage(src, new Rectangle(0, 0, size, size));
                    }
                }
                dest.Save(@"tool\preview_splash_circle.png", ImageFormat.Png);
                Console.WriteLine("Saved: tool\\preview_splash_circle.png");
            }
        }
    }
}
