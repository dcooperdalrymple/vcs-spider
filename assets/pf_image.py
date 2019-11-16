#!/usr/bin/python2.7

# Initialize the program and modules

try:
    import sys
    from PIL import Image
    import math

except ImportError, err:
    print "Could not load %s module." % (err)
    raise SystemExit

print "\nVCS Playfield Image Converter\nCopyright (c) 2019 D Cooper Dalrymple\n"

# Constants
#PF_HEIGHT = 192 / 8
PF_MIRROR_WIDTH = 4 + 8 + 8
PF_FULL_WIDTH = PF_MIRROR_WIDTH * 2
OUTPUT_TAB_LENGTH = 4
PF_MIRROR_GROUP = 3
PF_FULL_GROUP = 6

def load_image(filename):
    image = Image.open(filename)
    print("Image successfully loaded.")
    print("Width: " + str(image.width) + "px")
    print("Height: " + str(image.height) + "px\n")
    return image

def read_image(image):
    data = [[0 for x in range(0, PF_FULL_WIDTH)] for y in range(0, image.height)]

    for y in range(0, image.height):
        for x in range(0, min(image.width, PF_FULL_WIDTH)):
            pixel = image.getpixel((x, y))
            avg = sum(pixel) / float(len(pixel))
            if (avg >= 255 / 2.0):
                data[y][x] = 1

    return data

def set_bit(v, index, x): # Index is LSB
    mask = 1 << index
    v &= ~mask
    if x:
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

def convert_mirror(image_data):
    pf_data = [0b00000000 for x in range(0, len(image_data) * 3)]

    i = 0 # pf_data index
    for y in range(0, len(image_data)):
        j = 0 # image_data x index

        for x in range(0, 4):
            # First 4 bits reversed (MSB)
            pf_data[i] = set_bit(pf_data[i], x + 4, image_data[y][j])
            j += 1
        i += 1

        for x in range(0, 8):
            # Normal 8 bits
            pf_data[i] = set_bit(pf_data[i], 7 - x, image_data[y][j])
            j += 1
        i += 1

        for x in range(0, 8):
            # Reversed 8 bits
            pf_data[i] = set_bit(pf_data[i], x, image_data[y][j])
            j += 1
        i += 1

        # Leave second half of image untouched

    return pf_data

def convert_full(image_data):
    pf_data = [0b00000000 for x in range(0, len(image_data) * 3 * 2)]

    i = 0 # pf_data index
    for y in range(0, len(image_data)):
        j = 0 # image_data x index

        for x in range(0, 4):
            # First 4 bits reversed (LSB)
            pf_data[i] = set_bit(pf_data[i], x + 4, image_data[y][j])
            j += 1
        i += 1

        for x in range(0, 8):
            # Normal 8 bits
            pf_data[i] = set_bit(pf_data[i], 7 - x, image_data[y][j])
            j += 1
        i += 1

        for x in range(0, 8):
            # Reversed 8 bits
            pf_data[i] = set_bit(pf_data[i], x, image_data[y][j])
            j += 1
        i += 1

        # Just doubles it for second half of image
        for x in range(0, 4):
            # First 4 bits reversed (LSB)
            pf_data[i] = set_bit(pf_data[i], x + 4, image_data[y][j])
            j += 1
        i += 1

        for x in range(0, 8):
            # Normal 8 bits
            pf_data[i] = set_bit(pf_data[i], 7 - x, image_data[y][j])
            j += 1
        i += 1

        for x in range(0, 8):
            # Reversed 8 bits
            pf_data[i] = set_bit(pf_data[i], x, image_data[y][j])
            j += 1
        i += 1

    return pf_data

def reverse_data(data, group_size):
    rev_data = [0 for x in range(0, len(data))]

    groups = int(math.floor(len(data) / float(group_size)))
    for x in range(0, groups):
        for y in range(0, group_size):
            rev_data[(groups - x - 1) * group_size + y] = data[x * group_size + y]

    return rev_data

def compose_output(data, group_size, address_name, group_index):
    output = address_name + ":\n"

    groups = int(math.floor(len(data) / float(group_size)))
    for x in range(0, groups):
        if group_index >= 0:
            output += " " * OUTPUT_TAB_LENGTH + ".BYTE %" + get_bin(data[x * group_size + group_index]) + "\n"
        else:
            output += "\n"
            for y in range(0, group_size):
                output += " " * OUTPUT_TAB_LENGTH + ".BYTE %" + get_bin(data[x * group_size + y]) + "\n"

    return output

def compose_merge(strs):
    output = ""

    for x in range(0, len(strs)):
        if output != "":
            output += "\n"
        output += strs[x]

    return output

# Parse command line arguments

# No input, prompt user
if len(sys.argv) < 2:
    print "No arguments given. Run with -h for a list of options."
    raise SystemExit

# Help message
elif sys.argv[1] == "-h" or sys.argv[1] == "-help" or sys.argv[1] == "--help":
    print "Convert mirrored monochromatic image to playfield bytes:"
    print "  pf_image.py -type mirror -split 0 -reverse 0 -name [ADDRESSNAME] -in [FILENAME] -out [FILENAME]"
    print "Convert fullscreen monochromatic image to playfield bytes:"
    print "  pf_image.py -type full -split 0 -reverse 0 -name [ADDRESSNAME] -in [FILENAME] -out [FILENAME]"
    print "\nSetting split to 1 will separate playfield bytes into different address positions."
    print "Accepts png/jpg input and .asm output is preferred.\n"
    raise SystemExit

if len(sys.argv) == 13 and sys.argv[1] == '-type' and sys.argv[3] == '-split' and sys.argv[5] == '-reverse' and sys.argv[7] == '-name' and sys.argv[9] == '-in' and sys.argv[11] == '-out':
    type = sys.argv[2]
    split = sys.argv[4]
    reverse = sys.argv[6]
    address_name = sys.argv[8]
    in_file = sys.argv[10]
    out_file = sys.argv[12]

    image = load_image(in_file)
    image_data = read_image(image)

    if type == 'mirror':
        pf_data = convert_mirror(image_data)
        group_size = PF_MIRROR_GROUP
    elif type == 'full':
        pf_data = convert_full(image_data)
        group_size = PF_FULL_GROUP
    else:
        print "Invalid conversion type. Must be \"mirror\" or \"full\"."
        raise SystemExit

    if reverse == '1':
        pf_data = reverse_data(pf_data, group_size)

    if split == '1':
        # Force group size to 3. Full image alternates.
        pf0_output = compose_output(pf_data, PF_MIRROR_GROUP, address_name + "PF0", 0)
        pf1_output = compose_output(pf_data, PF_MIRROR_GROUP, address_name + "PF1", 1)
        pf2_output = compose_output(pf_data, PF_MIRROR_GROUP, address_name + "PF2", 2)
        pf_output = compose_merge([pf0_output, pf1_output, pf2_output])
    else:
        pf_output = compose_output(pf_data, group_size, address_name, -1)

    output = open(out_file, "w")
    output.write(pf_output)
    output.close()

    print "Successfully converted image to playfield data.\n"
    raise SystemExit

print "Invalid arguments. Run with -h for a list of options.\n"
