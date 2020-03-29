"""
Solving TSP using Tabu Search
"""
import sys
import time
import copy

tabu_size = int(1e9)


def gen_first_solution(n, dist):
    """Greedy algorithm to generate first solution"""
    to_visit = [x for x in range(1, n)]
    solution = [0]
    last = 0
    while len(to_visit) > 0:
        best_city = to_visit[0]
        best_dist = dist[last][best_city]
        for curr_city in to_visit:
            curr_dist = dist[last][curr_city]
            if curr_dist < best_dist:
                best_city = curr_city
                best_dist = curr_dist
        solution.append(best_city)
        to_visit.remove(best_city)
    solution.append(0)
    return solution


# def gen_first_solution(n, dist):
#     q = [0] + list(np.random.permutation([i for i in range(1, n)])) + [0]
#     print(q, find_distance(q, dist))
#     return q


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
            new = copy.deepcopy(solution)
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
    best_solution = gen_first_solution(n, dist)
    best_distance = find_distance(best_solution, dist)
    solution = copy.deepcopy(best_solution)
    end_time = time.time() + t
    while time.time() < end_time:
        neighbourhood = gen_neighbourhood(solution)
        best_neighbour = neighbourhood[0]
        best_neighbour_dist = find_distance(best_neighbour, dist)
        for neighbour in neighbourhood:
            first, second = get_diff(solution, neighbour)
            if (first, second) not in tabu and (second, first) not in tabu:
                tmp_neighbour_dist = find_distance(neighbour, dist)
                if tmp_neighbour_dist < best_neighbour_dist:
                    best_neighbour = neighbour
                    best_neighbour_dist = tmp_neighbour_dist
        tabu.append((get_diff(solution, best_neighbour)))
        solution = best_neighbour
        distance = best_neighbour_dist
        if distance < best_distance:
            best_solution = copy.deepcopy(solution)
            best_distance = distance
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
    print(list(map(lambda x: x + 1, solution)), file=sys.stderr)


run()
