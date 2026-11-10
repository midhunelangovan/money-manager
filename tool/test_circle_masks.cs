using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public class TestCircleMasks
{
    public static void Main()
    {
        using (Bitmap cutout = new Bitmap(@"tool\test_app_icon_cutout.png"))
        {
            RenderMasked(cutout, @"tool\preview_fill.png", 432, 1.0f);
            RenderMasked(cutout, @"tool\preview_medium.png", 432, 0.82f);
            RenderMasked(cutout, @"tool\preview_badge.png", 432, 0.68f);
        }
    }

    private static void RenderMasked(Bitmap src, string outputPath, int size, float ratio)
    {
        using (Bitmap dest = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.Clear(Color.Transparent);
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.CompositingQuality = CompositingQuality.HighQuality;

                // Simulate Android Circular Launcher Mask (radius = size * 0.33f to 0.36f -> diameter = size * 0.72f)
                int maskDiameter = (int)(size * 0.72f);
                int maskOffset = (size - maskDiameter) / 2;

                using (GraphicsPath path = new GraphicsPath())
                {
                    path.AddEllipse(maskOffset, maskOffset, maskDiameter, maskDiameter);
                    g.SetClip(path);
                    g.Clear(Color.White);

                    int targetSize = (int)(size * ratio);
                    int offset = (size - targetSize) / 2;
                    g.DrawImage(src, new Rectangle(offset, offset, targetSize, targetSize));
                }
            }
            dest.Save(outputPath, ImageFormat.Png);
            Console.WriteLine("Saved: " + outputPath);
        }
    }
}
