import numpy 
import math
import skimage.io as skimage_io
from os import listdir
from os.path import isfile, isdir, join, basename

originalImageDirectory = "../../dataset/images/eligible_files"
processedImageDirectory = "./output.HDD"

def psnr(img1, img2):
    mse = numpy.mean( (img1 - img2) ** 2 )
    if mse == 0:
        return 100
    PIXEL_MAX = 255.0
    return 20 * math.log10(PIXEL_MAX / math.sqrt(mse))

originalImageFiles = []
for f in listdir(originalImageDirectory):
    if f.endswith(".jpg"):
        fileName = join(originalImageDirectory, f)
        originalImageFiles.append(fileName)

#for f in originalImageFiles: print(f)

processedImageFiles = []
for f in listdir(processedImageDirectory):
    if isdir(join(processedImageDirectory, f)):
        subDir = join(processedImageDirectory, f)
        for ff in listdir(subDir):
            if ff.endswith(".jpg"):
                fileName = join(subDir, ff)
                #print(fileName)
                processedImageFiles.append(fileName)
                
#for f in processedImageFiles: print(f)

maxPSNR = 0
minPSNR = 100

for orignalFile in originalImageFiles:
    found = False
    baseNameOfOriginalFile = basename(orignalFile)
    for processedFile in processedImageFiles:
        baseFileNameOfProcessed = basename(processedFile)
        if baseNameOfOriginalFile == baseFileNameOfProcessed:
            #print(baseNameOfOriginalFile)
            found = True
            break
        
    if found:
        print("Debug:", orignalFile, processedFile)
        
        original = skimage_io.imread(orignalFile)
        processed = skimage_io.imread(processedFile)
        
        if original.ndim != processed.ndim:
            print("Mismatch:", basename(orignalFile), "ndim is not equal, will not calculated:", original.shape, processed.shape)
        else:
            d=psnr(original, processed)
            if d == 100:
                print("Saturate:", basename(orignalFile), "PSNR is 100.")
            else:
                print("Normal:", basename(orignalFile), "PSNR:", d)
                if d > maxPSNR: maxPSNR = d
                if d < minPSNR: minPSNR = d
        
print(maxPSNR, minPSNR)
