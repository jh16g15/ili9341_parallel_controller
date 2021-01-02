# from Ben Eater
# https://www.youtube.com/watch?v=uqY3FMuMuRo
from PIL import Image

IMAGE_LOC = "D:/Documents/vivado/ili9341_parallel_controller/resources/"
IMAGE_NAME = "KAT_iron_240x320"
IMAGE_EXT = ".png"
IMAGE_WIDTH = 240
IMAGE_HEIGHT = 320
PADDED_WIDTH = 256  # pad out to 256 wide for easier addressing

BITS_PER_PIXEL = 8

TOTAL_MEM_BITS = BITS_PER_PIXEL * PADDED_WIDTH * IMAGE_HEIGHT 
FGPA_MEM_ARRAY_LEN =  PADDED_WIDTH * IMAGE_HEIGHT
print("Total Bits: " + str(TOTAL_MEM_BITS))
print("FPGA Memory Array Length: " + str(FGPA_MEM_ARRAY_LEN))

image = Image.open(IMAGE_LOC + IMAGE_NAME + IMAGE_EXT)

pixels = image.load()

## Output File Format
# This outputs 1 pixel (byte) per line
# GGGRRRBB
out_file = open(IMAGE_LOC + "hex/" +  IMAGE_NAME + ".hex", "w")
for y in range(IMAGE_HEIGHT):
    for x in range(PADDED_WIDTH):
        try:
            out_file.write(f'{pixels[x,y]:02x}')    # 0-padded, 2 digit hex
        except IndexError:
            out_file.write(f'{0:02x}')
        out_file.write("\n")

out_file.close()