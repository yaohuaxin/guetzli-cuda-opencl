import argparse
import numpy
import math
import skimage.io as skimage_io
from os import listdir
from os.path import isfile, isdir, join, basename

parser = argparse.ArgumentParser()
parser.add_argument('--source', type=str, default=None, help='source image file')
parser.add_argument('--target', type=str, default=None, help='target image file')
args = parser.parse_args()

if args.source is None or args.target is None:
    print("Should provide source and target image file.")
    exit(1)

sourceImageFile = args.source
targetImageFile = args.target

def psnr(img1, img2):
    mse = numpy.mean( (img1 - img2) ** 2 )
    if mse == 0:
        return 100
    PIXEL_MAX = 255.0
    return 20 * math.log10(PIXEL_MAX / math.sqrt(mse))

sourceImage = skimage_io.imread(sourceImageFile)
targetImage = skimage_io.imread(targetImageFile)

if sourceImage.ndim != targetImage.ndim:
    print("Dimension mismatch: ndim is not equal, will not calculated:", sourceImage.shape, targetImage.shape)
else:
    d = psnr(sourceImage, targetImage)
    
    print("PSNR is:", d)
