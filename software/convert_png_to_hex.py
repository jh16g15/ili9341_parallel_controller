# Based on Ben Eater's Image conversion code seen here
# https://www.youtube.com/watch?v=uqY3FMuMuRo

from PIL import Image

IMAGE_LOC = "D:/Documents/vivado/ili9341_parallel_controller/resources/edited/"
IMAGE_NAME = "bike"
IMAGE_EXT = ".png"
IMAGE_WIDTH = 240
IMAGE_HEIGHT = 320
PADDED_WIDTH = 256  # pad out to 256 wide for easier addressing

PAD_WIDTH_ENABLE = False

BITS_PER_PIXEL = 8

if PAD_WIDTH_ENABLE:
    IMAGE_WIDTH = PADDED_WIDTH     
    
TOTAL_MEM_BITS = BITS_PER_PIXEL * IMAGE_WIDTH * IMAGE_HEIGHT 

FGPA_MEM_ARRAY_LEN =  IMAGE_WIDTH * IMAGE_HEIGHT
print("Total Bits: " + str(TOTAL_MEM_BITS))
print("FPGA Memory Array Length: " + str(FGPA_MEM_ARRAY_LEN))

image = Image.open(IMAGE_LOC + IMAGE_NAME + IMAGE_EXT)

pixels = image.load()

## Output File Format
# This outputs 1 pixel (byte) per line
# GGGRRRBB
out_file = open(IMAGE_LOC + "../hex/" +  IMAGE_NAME + ".hex", "w")
for y in range(IMAGE_HEIGHT):
    for x in range(IMAGE_WIDTH):
        try:
            out_file.write(f'{pixels[x,y]:02x}')    # 0-padded, 2 digit hex
        except IndexError:  # if we have enabled padding
            out_file.write(f'{0:02x}')
        out_file.write("\n")

out_file.close()