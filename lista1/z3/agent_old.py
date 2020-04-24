import copy
import time

MAX = 2147483647


# noinspection PyMethodMayBeStatic
class Grid:

    def __init__(self, t_size, n_size, n, m, grid):
        self.t_size = t_size
        self.n_size = n_size
        self.n = n
        self.m = m
        self.grid = grid
        for y in range(n):
            for x in range(m):
                if grid[y][x] == 5:
                    self.x_pos = x
                    self.y_pos = y

    def tile(self, x, y):
        return self.grid[y][x]

    def find_first_solution(self):
        """Returns naive solution"""
        x = self.x_pos
        y = self.y_pos
        solution = []
        tile = self.tile
        while tile(x, y - 1) != 1 and tile(x, y - 1) != 8:
            solution += 'U'
            y -= 1
        if tile(x, y - 1) == 8:
            solution += 'U'
            return solution
        while tile(x + 1, y) != 1 and tile(x + 1, y) != 8:
            solution += 'R'
            x += 1
            if tile(x, y - 1) == 8:
                solution += 'U'
                return solution
        if tile(x + 1, y) == 8:
            solution += 'R'
            return solution
        while tile(x, y + 1) != 1 and tile(x, y + 1) != 8:
            solution += 'D'
            y += 1
            if tile(x + 1, y) == 8:
                solution += 'R'
                return solution
        if tile(x, y + 1) == 8:
            solution += 'D'
            return solution
        while tile(x - 1, y) != 1 and tile(x - 1, y) != 8:
            solution += 'L'
            x -= 1
            if tile(x, y + 1) == 8:
                solution += 'D'
                return solution
        if tile(x - 1, y) == 8:
            solution += 'L'
            return solution
        while tile(x, y - 1) != 1 and tile(x, y - 1) != 8:
            solution += 'U'
            y -= 1
            if tile(x - 1, y) == 8:
                solution += 'L'
                return solution
        if tile(x, y - 1) == 8:
            solution += 'U'
            return solution
        while tile(x + 1, y) != 1 and tile(x + 1, y) != 8:
            solution += 'R'
            x += 1
            if tile(x, y - 1) == 8:
                solution += 'U'
                return solution
        raise SolutionNotExistsError()

    def remove_unnecessary_tiles(self, solution):
        idx = 0
        while idx < len(solution) - 1:
            if (solution[idx] == 'U' and solution[idx + 1] == 'D'
                    or solution[idx] == 'D' and solution[idx + 1] == 'U'
                    or solution[idx] == 'L' and solution[idx + 1] == 'R'
                    or solution[idx] == 'R' and solution[idx + 1] == 'L'):
                solution.pop(idx)
                solution.pop(idx)
                idx -= 1
            idx += 1
        return solution

    def find_neighbours(self, solution):
        neighbourhood = []
        for x in range(len(solution)):
            sx = solution[x]
            for y in range(len(solution)):
                sy = solution[y]
                if sx == sy:
                    continue
                new = copy.deepcopy(solution)
                new[x], new[y] = sy, sx
                if new not in neighbourhood:
                    neighbourhood.append(new)
                    yield new

    def find_neighbours2(self, solution):
        neighbourhood = []
        for x in range(2, len(solution)):
            for i in range(len(solution) - x):
                new = solution[:i] + solution[i:(i + x)][::-1] + solution[(i + x):]
                if new not in neighbourhood:
                    neighbourhood.append(new)
                    yield new

    def find_cost(self, solution):
        """Finds cost of given solution
        :raise NotExistingMoveError if solution contains not existing move
        :raise ForbiddenTileError if Agent walked on forbidden tile
        :return cost if solution is correct, 2147483647 otherwise
        """
        x_curr = self.x_pos
        y_curr = self.y_pos
        cost = 0
        for s in solution:
            cost += 1
            if s == 'U':
                y_curr -= 1
            elif s == 'D':
                y_curr += 1
            elif s == 'L':
                x_curr -= 1
            elif s == 'R':
                x_curr += 1
            else:
                raise NotExistingMoveError()
            if self.grid[y_curr][x_curr] == 1:
                return MAX
            if self.grid[y_curr][x_curr] == 8:
                return cost
        return MAX

    def run_tabu2(self, t):
        best_solution = self.find_first_solution()
        best_cost = self.find_cost(best_solution)
        solution = copy.deepcopy(best_solution)
        cost = best_cost
        end_time = time.time() + t
        tabu = [solution]
        print(solution)
        while time.time() < end_time:
            counter = 1
            neighbourhood = self.find_neighbours(solution)
            best_neighbour = next(neighbourhood)
            best_neighbour_cost = self.find_cost(best_neighbour)
            temp_list = list(neighbourhood)
            for neighbour in temp_list:
                if neighbour in tabu:
                    continue
                if counter > self.n_size:
                    break
                counter += 1
                tabu.append(neighbour)
                if len(tabu) >= self.t_size:
                    tabu.pop(0)
                tmp_neighbour_cost = self.find_cost(neighbour)
                if tmp_neighbour_cost < best_neighbour_cost:
                    print("WWWW")
                    best_neighbour = neighbour
                    best_neighbour_cost = tmp_neighbour_cost
            if best_neighbour_cost < cost:
                solution = best_neighbour[:best_neighbour_cost]
                cost = best_neighbour_cost
                tabu.append(solution)
                print(solution)
        return solution, cost

    def run_tabu3(self, t):
        solution = self.find_first_solution()
        cost = self.find_cost(solution)
        tabu = [solution]
        print(solution)
        end_time = time.time() + t
        while time.time() < end_time:
            neighbourhood = self.find_neighbours(solution)
            ctr = 0
            for neighbour in neighbourhood:
                ctr += 1
                if neighbour in tabu:
                    continue
                tabu.append(neighbour)
                if len(tabu) >= self.t_size:
                    tabu.pop(0)
                tmp_neighbour_cost = self.find_cost(neighbour)
                if tmp_neighbour_cost < cost:
                    solution = neighbour[:tmp_neighbour_cost]
                    cost = tmp_neighbour_cost
                    tabu.append(solution)
                    print(solution)
                    break
            print(ctr)
        return solution, cost

    def run_tabu(self, t):
        solution = self.find_first_solution()
        cost = self.find_cost(solution)
        tabu = [solution]
        print(solution)
        end_time = time.time() + t
        while time.time() < end_time:
            neighbourhood = self.find_neighbours2(solution)
            best_neighbour = next(neighbourhood)
            best_neighbour_cost = self.find_cost(best_neighbour)
            for neighbour in neighbourhood:
                if neighbour in tabu:
                    continue
                if neighbourhood not in tabu:
                    tabu.append(neighbour)
                if len(tabu) >= self.t_size:
                    tabu.pop(0)
                tmp_neighbour_cost = self.find_cost(neighbour)
                if tmp_neighbour_cost <= best_neighbour_cost:
                    best_neighbour = neighbour[:tmp_neighbour_cost]
                    best_neighbour_cost = tmp_neighbour_cost
            print(solution)
            solution = best_neighbour
            cost = best_neighbour_cost
            tabu.append(solution)
        return solution, cost


class NotExistingMoveError(Exception):
    """Exception for not existing move"""
    pass


class ForbiddenTileError(Exception):
    """Exception for walking on forbidden tile"""
    pass


class SolutionNotExistsError(Exception):
    """Exception for walking on forbidden tile"""
    pass
