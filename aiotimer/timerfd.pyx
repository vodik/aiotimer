# cython: linetrace=True
import asyncio

from libc cimport errno
from libc.stdint cimport uint64_t
from posix cimport unistd
from posix.time cimport clock_gettime, CLOCK_MONOTONIC, timespec


cdef extern from "time.h" nogil:
    cdef struct itimerspec:
        timespec it_interval
        timespec it_value


cdef extern from "sys/timerfd.h":
    int timerfd_create(int, int) except? -1
    int timerfd_settime(int, int, itimerspec *, itimerspec *) except? -1
    int timerfd_gettime(int, itimerspec *) except? -1

    enum: TFD_CLOEXEC
    enum: TFD_NONBLOCK
    enum: TFD_TIMER_ABSTIME


cdef class Timer:
    cdef int _fd
    cdef itimerspec _timerspec
    cdef uint64_t _interval
    cdef object _protocol, _loop

    cdef _arm_timer(self, reset=False):
        if reset:
            clock_gettime(CLOCK_MONOTONIC, &self._timerspec.it_value)

        self._timerspec.it_value.tv_nsec += self._interval
        if self._timerspec.it_value.tv_nsec >= 1_000_000_000:
            self._timerspec.it_value.tv_nsec -= 1_000_000_000
            self._timerspec.it_value.tv_sec += 1

        timerfd_settime(self._fd, TFD_TIMER_ABSTIME, &self._timerspec, NULL)

    def __cinit__(self, protocol, interval, *, loop=None):
        self._fd = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK)
        self._arm_timer(reset=True)

        self._interval = interval * 1_000_000_000
        self._protocol = protocol
        self._loop = loop or asyncio.get_event_loop()
        self._loop.add_reader(self._fd, self._callback)
        self._protocol.timer_started(self)

    cdef fileno(self):
        return self._fd

    cpdef _callback(self):
        cdef int result
        cdef uint64_t expirations

        result = unistd.read(self._fd, &expirations, sizeof(expirations))
        assert result == sizeof(expirations)

        self._arm_timer()
        self._protocol.timer_ticked()

        result = unistd.read(self._fd, &expirations, sizeof(expirations))
        if result == -1:
            assert errno.errno == errno.EAGAIN
            return

        assert result == sizeof(expirations)
        if self._protocol.timer_overrun(expirations):
            self._arm_timer(reset=True)
        else:
            self.close()

    cpdef close(self):
        unistd.close(self._fd)
        self._fd = -1
