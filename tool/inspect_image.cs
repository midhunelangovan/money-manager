using System;
using System.Drawing;

class Program {
    static void Main(string[] args) {
        string path = args[0];
        using (var bmp = new Bitmap(path)) {
            Console.WriteLine(string.Format("Path: {0}, Size: {1}x{2}", path, bmp.Width, bmp.Height));
            int nonBlack = 0;
            for (int y = 0; y < bmp.Height; y += 10) {
                for (int x = 0; x < bmp.Width; x += 10) {
                    var p = bmp.GetPixel(x, y);
                    if (p.R > 10 || p.G > 10 || p.B > 10) {
                        nonBlack++;
                        if (nonBlack < 10) {
                            Console.WriteLine(string.Format("Sample at ({0},{1}): R={2}, G={3}, B={4}, A={5}", x, y, p.R, p.G, p.B, p.A));
                        }
                    }
                }
            }
            Console.WriteLine(string.Format("Total sampled non-black pixels: {0}", nonBlack));
        }
    }
}
