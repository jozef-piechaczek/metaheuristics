"""
Solving TSP using Tabu Search
"""
import sys
import time

import numpy as np

tabu_size = int(1e7)


def gen_first_solution(n):
    return [0] + list(np.random.permutation([i for i in range(1, n)])) + [0]


def find_distance(s, dist):
    return sum([dist[s[i]][s[i + 1]] for i in range(len(s) - 1)])


def gen_neighbourhood(solution):
    neighbourhood = []
    for x in solution[1:-1]:
        idx_x = solution.index(x)
        for y in solution[1:-1]:
            idx_y = solution.index(y)
            if x == y:
                continue
            new = [e for e in solution]
            new[idx_x], new[idx_y] = y, x
            if new not in neighbourhood:
                neighbourhood.append(new)
    return neighbourhood


def read_data(file):
    dist = []
    with open(file) as f:
        t, n = list(map(int, f.readline().split(' ')))
        for i in range(n):
            dist.append(list(map(int, f.readline().split(' '))))
    return t, n, dist


def get_diff(perm1, perm2):
    for i in range(len(perm1)):
        if perm1[i] != perm2[i]:
            return perm1[i], perm2[i]
    raise Exception('No diff found')


def solve_tsp(t, n, dist):
    tabu = []
    solution = gen_first_solution(n)
    best_solution = solution
    distance = find_distance(solution, dist)
    best_distance = distance
    end_time = time.time() + t
    while time.time() < end_time:
        neighbourhood = gen_neighbourhood(solution)
        for neighbour in neighbourhood:
            first, second = get_diff(neighbour, solution)
            if (first, second) not in tabu and (second, first) not in tabu:
                tabu.append((first, second))
                solution = neighbour
                distance = find_distance(neighbour, dist)
                if distance < best_distance:
                    best_solution = solution
                    best_distance = distance
                break
        if len(tabu) >= tabu_size:
            tabu.pop(0)
    return best_solution, best_distance


def run():
    if len(sys.argv) != 3:
        raise Exception('Incorrect number of parameters')
    file_in, file_out = sys.argv[1], sys.argv[2]
    t, n, dist_matrix = read_data(file_in)
    solution, distance = solve_tsp(t, n, dist_matrix)
    with open(file_out, 'w') as f:
        f.write(str(distance))
    print(solution, file=sys.stderr)
    print(distance)
    pass


run()
