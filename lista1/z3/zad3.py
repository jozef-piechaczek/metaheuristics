import sys

from agent import *

tabu_size = int(1e4)
neighbourhood_size = int(1e3)


def read_values(file):
    with open(file) as f:
        matrix = []
        t, n, m = list(map(int, f.readline().split(' ')))
        for i in range(n):
            matrix.append(list(map(int, [c for c in f.readline().strip()])))
    return t, n, m, matrix


def find_path(t, n, m, g):
    grid = Grid(tabu_size, neighbourhood_size, n, m, g)
    solution, cost = grid.run_tabu(t)
    return solution, cost


def main():
    if len(sys.argv) != 4:
        raise Exception('Incorrect number of parameters')
    file_in, file_out, file_err = sys.argv[1], sys.argv[2], sys.argv[3]
    t, n, m, g = read_values(file_in)
    solution, cost = find_path(t, n, m, g)
    with open(file_out, 'w') as f:
        f.write(str(cost))
    with open(file_err, 'w') as f:
        f.write(''.join(solution))


if __name__ == '__main__':
    main()
