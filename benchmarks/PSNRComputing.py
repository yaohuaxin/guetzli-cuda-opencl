import numpy 
import math
import skimage.io as skimage_io
from os import listdir
from os.path import isfile, isdir, join, basename

#sourceImageDirectory = "../../dataset/images/eligible_files"
#sourceImageDirectory = "../../dataset/images/tencentResults/guetzli_result"
#sourceImageDirectory = "../../dataset/images/X86Results.byIBM/output.HDD"
sourceImageDirectory = "../../dataset/images/IBMResults/4G_8P_MPS.forSource"

#processedImageDirectory = "./output.HDD"
processedImageDirectory = "../../dataset/images/IBMResults/4G_8P_MPS.forTarget"
#processedImageDirectory = "../../dataset/images/X86Results.byIBM"

def psnr(img1, img2):
    mse = numpy.mean( (img1 - img2) ** 2 )
    if mse == 0:
        return 100
    PIXEL_MAX = 255.0
    return 20 * math.log10(PIXEL_MAX / math.sqrt(mse))

sourceImageFiles = {}
for f in listdir(sourceImageDirectory):
    if f.endswith(".jpg"):
        key = f.replace("out_test_","").replace(".jpg","")
        #print(key)
        #print(f)
        fileName = join(sourceImageDirectory, f)
        sourceImageFiles[key] = fileName
'''
for key in sourceImageFiles:
    print(key, sourceImageFiles[key])
'''

processedImageFiles = {}
for f in listdir(processedImageDirectory):
    if isdir(join(processedImageDirectory, f)):
        subDir = join(processedImageDirectory, f)
        for ff in listdir(subDir):
            if ff.endswith(".jpg"):
                key = ff.replace(".jpg","")
                fileName = join(subDir, ff)
                processedImageFiles[key] = fileName
'''
for key in processedImageFiles:
    print(key, processedImageFiles[key])
'''

maxPSNR = 0
minPSNR = 100
PSNRsOfAllImages = {}
imagesGivenByTencentButNotInIBMResult = {}

for orignalFileKey in sourceImageFiles:
    if orignalFileKey in processedImageFiles:
        sourceFile = sourceImageFiles[orignalFileKey]
        processedFile = processedImageFiles[orignalFileKey]
        
        print("Debug: Found file, ID: {}, source file: {}, processed file: {}.".format(
                orignalFileKey, sourceFile, processedFile))

        original = skimage_io.imread(sourceFile)
        processed = skimage_io.imread(processedFile)
        
        if original.ndim != processed.ndim:
            print("Dimension mismatch:", basename(sourceFile), "ndim is not equal, will not calculated:", original.shape, processed.shape)
        else:
            d=psnr(original, processed)
            if d > maxPSNR: maxPSNR = d
            if d < minPSNR: minPSNR = d
            
            PSNRsOfAllImages[orignalFileKey] = d
            
            if d == 100:
                print("Image identify:", basename(sourceFile), "PSNR is 100.")
            else:
                print("Image not identify:", basename(sourceFile), "PSNR:", d)

    else:
        print("Debug: Not found file, ID: {}, source file: {}.".format(orignalFileKey, sourceImageFiles[orignalFileKey]))
        imagesGivenByTencentButNotInIBMResult[orignalFileKey] = sourceImageFiles[orignalFileKey]
        pass

print("==== ==== ==== ==== summary ==== ==== ==== ====")
print("Images given by Tencent, but not in IBM result:")
for item in imagesGivenByTencentButNotInIBMResult.items():
    print("    ", item)

PSNRsOfAllImagesSortedByValue = sorted(PSNRsOfAllImages.items(), key=lambda x: x[1])
print("Total number of images compared", len(PSNRsOfAllImages.items()))
#print("Total picture compared", len(PSNRsOfAllImagesSortedByValue))

print("PSNR range: [", maxPSNR, minPSNR, "]")

for index in range(0, len(PSNRsOfAllImagesSortedByValue)):
    print(PSNRsOfAllImagesSortedByValue[index])

