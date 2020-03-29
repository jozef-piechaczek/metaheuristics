"""
Finding minimum of functions Happycat and Griewank using Gradient Search
"""


import sys
import numpy as np
import time
from math import sin, cos, sqrt

start_x = 0.9
a = 0.0001


def happycat(x):
    x1, x2, x3, x4 = x
    return ((((x1 * x1 + x2 * x2 + x3 * x3 + x4 * x4 - 4) ** 2) ** (1 / 8))
            + (1 / 4) * (((1 / 2) * (x1 * x1 + x2 * x2 + x3 * x3 + x4 * x4)) + x1 + x2 + x3 + x4)
            + 1 / 2)


def der_happycat(xk, x):
    x1, x2, x3, x4 = x
    return (((xk * (x1 * x1 + x2 * x2 + x3 * x3 + x4 * x4 - 4))
             / (2 * (((x1 * x1 + x2 * x2 + x3 * x3 + x4 * x4 - 4) ** 2) ** (7 / 8))))
            + ((xk + 1) / 4))


def grad_happycat(x):
    return tuple(map(lambda t: der_happycat(t, x), x))


def griewank(x):
    x1, x2, x3, x4 = x
    return (1 + ((x1 * x1 / 4000) + (x2 * x2 / 4000) + (x3 * x3 / 4000) + (x4 * x4 / 4000))
            - (cos(x1) * cos(x2 / sqrt(2)) * cos(x3 / sqrt(3)) * cos(x4 / 2)))


def grad_griewank(x):
    x1, x2, x3, x4 = x
    return ((x1 / 2000) + sin(x1) * cos(x2 / sqrt(2)) * cos(x3 / sqrt(3)) * cos(x4 / 2),
            (x2 / 2000) + ((1 / sqrt(2)) * (cos(x1) * sin(x2 / sqrt(2)) * cos(x3 / sqrt(3)) * cos(x4 / 2))),
            (x3 / 2000) + ((1 / sqrt(3)) * (cos(x1) * cos(x2 / sqrt(2)) * sin(x3 / sqrt(3)) * cos(x4 / 2))),
            (x4 / 2000) + ((1 / 2) * (cos(x1) * cos(x2 / sqrt(2)) * cos(x3 / sqrt(3)) * sin(x4 / 2))),
            )


def read_values(file):
    with open(file) as f:
        line = f.readline().split(' ')
        t, b = line
    return int(t), int(b)


def find_minimum(t, b):
    x = (start_x, start_x, start_x, start_x)
    grad = grad_happycat if b == 0 else grad_griewank
    func = happycat if b == 0 else griewank
    end_time = time.time() + t
    while time.time() < end_time:
        old_x = x
        x = tuple(np.subtract(old_x, tuple(np.multiply(a, grad(old_x)))))
    return x, func(x)


def run():
    if len(sys.argv) != 3:
        raise Exception('incorrect number of parameters')
    file_in = sys.argv[1]
    file_out = sys.argv[2]
    t, b = read_values(file_in)
    x, fx = find_minimum(t, b)
    with open(file_out, 'w') as f:
        f.write(f'{x[0]} {x[1]} {x[2]} {x[3]} {fx}')
    print(x, fx)


run()
