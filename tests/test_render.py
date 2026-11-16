import tempfile
import unittest
from pathlib import Path
from PIL import Image
from scripts.render import render

class RenderTests(unittest.TestCase):
    def test_dimensions_and_black_background(self):
        with tempfile.TemporaryDirectory() as folder:
            src = Path(folder) / 'source.jpg'
            dest = Path(folder) / 'wallpaper.jpg'
            Image.new('RGB', (500, 500), (255, 0, 0)).save(src)
            render(src, dest, 1280, 720, padding=16)
            with Image.open(dest) as img:
                self.assertEqual(img.size, (1280, 720))
                self.assertLess(max(img.getpixel((0, 0))), 15)
                self.assertGreater(img.getpixel((640, 360))[0], 230)

    def test_invalid_padding(self):
        with self.assertRaises(ValueError):
            render('none', 'none', 300, 300, padding=160)

if __name__ == '__main__':
    unittest.main()
