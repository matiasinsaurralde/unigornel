integration_test = True

timeout = 2

SLEEP_INTERVAL = int(100e6)
MIN_TIME = 1451606400000000000 # 2016-1-1 0:0:0.0 UTC

def check_state(state):
    import re
    from functools import partial
    from operator import is_not

    r = re.compile('^(\d+) \[.*\] Hello World!')
    lines = map(r.match, state.console.split('\n'))
    lines = filter(partial(is_not, None), lines)
    times = map(lambda m: int(m.group(1)), lines)
    times = list(times)

    min_times = (timeout - 1) * int(1e9) // SLEEP_INTERVAL
    assert len(times) >= min_times, "Expected at least {0} hello worlds".format(min_times)

    prev = 0
    for t in times:
        diff = t - prev
        assert diff >= SLEEP_INTERVAL, "Sleep interval must be >= {0}".format(SLEEP_INTERVAL)
        assert t >= MIN_TIME, "Time must be after {0}".format(MIN_TIME)
        prev = diff