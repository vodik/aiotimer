from .timerfd import Timer


class Protocol:
    def timer_started(self, timer):
        pass

    def timer_ticked(self):
        pass

    def timer_overrun(self, overruns):
        raise RuntimeError("Loop callback took longer than timer callback.")

    def error_received(self):
        pass


def create_timer(protocol_factory, interval, *, loop=None):
    protocol = protocol_factory()
    timer = Timer(protocol_factory(), interval, loop=loop)
    return timer, protocol
