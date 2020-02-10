#!/usr/bin/python2.7

# Initialize the program and modules

try:
    import sys
    from PIL import Image
    import math

except ImportError, err:
    print "Could not load %s module." % (err)
    raise SystemExit

print "\nVCS Sprite Image Converter\nCopyright (c) 2019 D Cooper Dalrymple\n"

# Constants
SPRITE_WIDTH = 8
OUTPUT_TAB_LENGTH = 4

def load_image(filename):
    image = Image.open(filename)
    print("Image successfully loaded.")
    print("Width: " + str(image.width) + "px")
    print("Height: " + str(image.height) + "px")
    print("Frames: " + str(int(math.floor(image.width / float(SPRITE_WIDTH)))) + "\n")
    return image

def read_image(image):
    frames = int(math.floor(image.width / float(SPRITE_WIDTH)))
    data = [[[0 for x in range(0, SPRITE_WIDTH)] for y in range(0, image.height)] for i in range(0, frames)]

    for i in range(0, frames):
        for y in range(0, image.height):
            for x in range(0, SPRITE_WIDTH):
                pixel = image.getpixel((x + SPRITE_WIDTH * i, y))
                avg = sum(pixel) / float(len(pixel))
                if (avg >= 255 / 2.0):
                    data[i][y][x] = 1

    return data

def set_bit(v, index, x): # Index is LSB
    mask = 1 << index
    v &= ~mask
    if x:
        v |= mask
    return v

def set_bit_bit(v, v_index, x, x_index):
    mask = 1 << v_index
    v &= ~mask
    if x & (1 << x_index):
        v |= mask
    return v

def get_bin(n):
    b = ""
    i = 0
    while i < 8:
        b += str(int(n % 2))
        n /= 2
        i += 1
    return b[::-1]

def convert_bin(image_data):
    sprite_data = [[0b00000000 for y in range(0, len(image_data[0]))] for i in range(0, len(image_data))]

    for i in range(0, len(image_data)):
        for y in range(0, len(image_data[i])):
            for x in range(0, SPRITE_WIDTH):
                sprite_data[i][y] = set_bit(sprite_data[i][y], (SPRITE_WIDTH - 1) - x, image_data[i][y][x])

    return sprite_data

def reverse_data(sprite_data):
    rev_data = [[0b00000000 for y in range(0, len(sprite_data[0]))] for i in range(0, len(sprite_data))]

    for i in range(0, len(sprite_data)):
        for y in range(0, len(sprite_data[0])):
            rev_data[i][len(sprite_data[0]) - 1 - y] = sprite_data[i][y]

    return rev_data

def flip_data(sprite_data):
    flip_data = [[0b00000000 for y in range(0, len(sprite_data[0]))] for i in range(0, len(sprite_data))]

    for i in range(0, len(sprite_data)):
        for y in range(0, len(sprite_data[0])):
            for x in range(0, 8): # Reversed 8 bits
                flip_data[i][y] = set_bit_bit(flip_data[i][y], 7 - x, sprite_data[i][y], x)

    return flip_data

def compose_output(sprite_data, address_name):
    output = address_name + ":\n"

    for i in range(0, len(sprite_data)):
        output += "\n"
        for y in range(len(sprite_data[0])):
            output += " " * OUTPUT_TAB_LENGTH + ".BYTE %" + get_bin(sprite_data[i][y]) + "\n"

    return output

# Parse command line arguments

# No input, prompt user
if len(sys.argv) < 2:
    print "No arguments given. Run with -h for a list of options."
    raise SystemExit

# Help message
elif sys.argv[1] == "-h" or sys.argv[1] == "-help" or sys.argv[1] == "--help":
    print "Convert " + str(SPRITE_WIDTH) + " pixel wide sprite frames to GRP bytes:"
    print "  sprite_image.py -name [ADDRESSNAME] -in [FILENAME] -out [FILENAME] -reverse [0/1] -flip [0/1]"
    print "\nAccepts png/jpg input and .asm output is preferred."
    raise SystemExit

if len(sys.argv) == 11 and sys.argv[1] == '-name' and sys.argv[3] == '-in' and sys.argv[5] == '-out' and sys.argv[7] == '-reverse' and sys.argv[9] == '-flip':
    address_name = sys.argv[2]
    in_file = sys.argv[4]
    out_file = sys.argv[6]
    reverse = sys.argv[8]
    flip = sys.argv[10]

    image = load_image(in_file)
    image_data = read_image(image)

    sprite_data = convert_bin(image_data)
    if reverse == '1':
        sprite_data = reverse_data(sprite_data)
    if flip == '1':
        sprite_data = flip_data(sprite_data)
    sprite_output = compose_output(sprite_data, address_name)

    output = open(out_file, "w")
    output.write(sprite_output)
    output.close()

    print "Successfully converted image to sprite frames.\n"
    raise SystemExit

print "Invalid arguments. Run with -h for a list of options."
