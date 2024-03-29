import cv2
import numpy as np
import math


def convolution2d(image, kernel, bias):
    m, n = kernel.shape
    if (m == n):
        y, x = image.shape
        y = y - m + 1
        x = x - m + 1
        new_image = np.zeros((y,x))
        for i in range(y):
            for j in range(x):
                new_image[i][j] = np.sum(image[i:i+m, j:j+m]*kernel) + bias
    return new_image

path='./image.jpg'
image = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
image = cv2.resize(image,(64,64))
pixels = np.array(image).flatten()

# img.dat
with open('./img.dat', 'w') as file:
    i=0
    for pixel in pixels:
        decimalpixel=pixel
        pixel = int(pixel * (2 ** 4))
        binary_representation = bin(pixel)[2:].zfill(13)
        file.write(str(binary_representation)+" //data "+str(i)+" : " +str(format(decimalpixel,'.1f')) +'\n')
        i=i+1

# cv2.imwrite('./resizeImg.png', image)

########### Layer0 ##########
# padding
image = cv2.copyMakeBorder(image, 2, 2, 2, 2, cv2.BORDER_REPLICATE)

# conv
bias=-0.75
kernel = np.array([[-0.0625, 0 , -0.125, 0, -0.0625],
                   [0, 0, 0, 0, 0],
                   [-0.25, 0, 1, 0, -0.25],
                   [0, 0, 0, 0, 0],
                   [-0.0625, 0, -0.125, 0, -0.0625]])
image = convolution2d(image,kernel,bias)

#relu
image = np.maximum(image, 0)

pixels = np.array(image).flatten()
with open('./layer0_golden.dat', 'w') as file:
    i=0
    for pixel in pixels:
        decimalpixel=pixel
        pixel = int(pixel * (2 ** 4))
        binary_representation = bin(pixel)[2:].zfill(13)
        file.write(str(binary_representation)+" //data "+str(i)+" : " +str(decimalpixel) +'\n')
        i=i+1
# cv2.imwrite('./layer0_outputImg.png', image)

########### Layer1 ##########
#Maxpooling
pool_size = (2, 2)
stride = (2, 2)
blocks = image.reshape((image.shape[0] // pool_size[0], pool_size[0],
                              image.shape[1] // pool_size[1], pool_size[1]))
pooled_blocks = np.max(blocks, axis=(1, 3))
image = pooled_blocks.reshape((pooled_blocks.shape[0], pooled_blocks.shape[1]))
pixels = np.array(image).flatten()

with open('./layer1_golden.dat', 'w') as file:
    i=0
    for pixel in pixels:
        pixel = math.ceil(pixel)
        decimalpixel=pixel
        pixel = int(pixel * (2 ** 4))
        binary_representation = bin(pixel)[2:].zfill(13)
        file.write(str(binary_representation)+" //data "+str(i)+" : " +str(format(decimalpixel,'.1f')) +'\n')
        i=i+1
# cv2.imwrite('./layer1_outputImg.png', image)
