========
aiotimer
========

AsyncIO compatible periodic timer. Linux only and very alpha API.

-------
Example
-------

The timer is implemented as a straightforward protocol similar to how
the asyncio's network protocols are handled:

.. code-block:: python

    class MyTimer(aiotimer.Protocol):
        def __init__(self):
            self.counter = 0

        def timer_started(self, timer):
            self.timer = timer

        def timer_ticked(self):
            # Callback triggered when the timer interval elapses
            ...

        def timer_overrun(self):
            # Callback triggered if the timer_ticked callback runtime
            # should exceed the timer interval. Return True to
            # reschedule, otherwise the timer is aborted.
            return True

        def error_received():
            ...

The protocol can then be used to create a new timer:

.. code-block:: python

    # Schedule once every 10th of a second
    aiotimer.create_timer(MyTimer, 0.1, loop=loop)
