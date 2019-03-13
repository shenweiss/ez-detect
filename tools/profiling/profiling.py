import time
import timeit
import cProfile
from memory_profiler import profile as profile_memory

#profile_memory is a decorator

#timeit module usage example 
#>>> timeit.timeit('"-".join(str(n) for n in range(100))', number=10000)
#0.8187260627746582

#function decorator @function_timer
def function_timer(f):
    def f_timer(*args, **kwargs):
        start = time.time()
        result = f(*args, **kwargs)
        end = time.time()
        print('{fname} took {elapsed} time'.format(fname=f.__name__, elapsed=end-start))
        return result
    return f_timer

#Timer class with checkpoints
# Usage example
#timer = timer_for('fancy thing')
#expensive_function()
#timer.checkpoint('done with something')
#Or with timer_for('fancy thing') as timer:
class timer_for():
    def __init__(self, name=''):
        self.name = name
        self.start = time.time()

    @property
    def elapsed(self):
        return time.time() - self.start

    def checkpoint(self, name=''):
        print('{timer} {checkpoint} took {elapsed} seconds'.format(
            timer=self.name,
            checkpoint=name,
            elapsed=self.elapsed,
        )).strip()

    def __enter__(self):
        return self

    def __exit__(self, type, value, traceback):
        self.checkpoint('finished')
        pass

#decorator for recursive profiling
def profile_time(func):
    def profiled_func(*args, **kwargs):
        profile = cProfile.Profile()
        try:
            profile.enable()
            result = func(*args, **kwargs)
            profile.disable()
            return result
        finally:
            profile.print_stats()
    return profiled_func

#line_profiler decorator
try:
    from line_profiler import LineProfiler

    def profile_time_by_line(follow=[]):
        def inner(func):
            def profiled_func(*args, **kwargs):
                try:
                    profiler = LineProfiler()
                    profiler.add_function(func)
                    for f in follow:
                        profiler.add_function(f)
                    profiler.enable_by_count()
                    return func(*args, **kwargs)
                finally:
                    profiler.print_stats()
            return profiled_func
        return inner

except ImportError:
    def profile_time_by_line(follow=[]):
        "Helpful if you accidentally leave in production!"
        def inner(func):
            def nothing(*args, **kwargs):
                return func(*args, **kwargs)
            return nothing
        return inner