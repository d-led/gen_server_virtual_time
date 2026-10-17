// Generated from ActorSimulation DSL
// A scheduler whose time is the test's.

package com.example.actors;

import io.vlingo.xoom.common.Cancellable;
import io.vlingo.xoom.common.Scheduled;
import io.vlingo.xoom.common.Scheduler;

import java.util.ArrayList;
import java.util.List;

/**
 * A Scheduler whose time is the test's: no timer is due until the test says how
 * much time has passed, and a timer that falls due fires on the test's thread, in
 * the order the timers are due. That is what makes a test of an actor that waits
 * for time a test of what the actor does, rather than a test of how fast the
 * machine is.
 */
public class ManualScheduler extends Scheduler {

  private final List<Timer> timers = new ArrayList<>();
  private long now;

  @Override
  public <T> Cancellable schedule(
      final Scheduled<T> scheduled, final T data, final long delay, final long interval) {
    return arm(scheduled, data, delay, interval);
  }

  @Override
  public <T> Cancellable scheduleOnce(
      final Scheduled<T> scheduled, final T data, final long delay, final long time) {
    // The scheduler this one stands in for makes the wait the sum of the two, as
    // a one-shot has no interval to repeat on.
    return arm(scheduled, data, delay + time, 0L);
  }

  /** now answers the time this scheduler has been advanced to, in milliseconds. */
  public synchronized long now() {
    return now;
  }

  /**
   * advanceBy lets millis of time pass, firing everything that falls due on the
   * way, timer by timer, in the order the timers are due.
   */
  public void advanceBy(final long millis) {
    final long target = nowMillis() + millis;

    while (true) {
      final Timer due = takeDueBy(target);

      if (due == null) {
        break;
      }

      setNow(due.dueAt);
      due.fire();

      if (due.interval > 0 && !due.cancelled) {
        due.dueAt += due.interval;

        synchronized (this) {
          timers.add(due);
        }
      }
    }

    setNow(target);
  }

  private synchronized long nowMillis() {
    return now;
  }

  private synchronized void setNow(final long millis) {
    now = millis;
  }

  private synchronized <T> Cancellable arm(
      final Scheduled<T> scheduled, final T data, final long delay, final long interval) {
    final Timer timer = new Timer(scheduled, data, now + delay, interval);
    timers.add(timer);

    return () -> cancel(timer);
  }

  private synchronized boolean cancel(final Timer timer) {
    return timers.remove(timer);
  }

  /** takeDueBy answers and removes the timer that is due first, if it is due by then. */
  private synchronized Timer takeDueBy(final long target) {
    Timer first = null;

    for (final Timer candidate : timers) {
      if (candidate.dueAt <= target && (first == null || candidate.dueAt < first.dueAt)) {
        first = candidate;
      }
    }

    if (first != null) {
      timers.remove(first);
    }

    return first;
  }

  /** A timer of the manual scheduler: when it is due, and what to tell when it is. */
  private static final class Timer {
    final Scheduled<Object> scheduled;
    final Object data;
    final long interval;
    long dueAt;
    boolean cancelled;

    @SuppressWarnings("unchecked")
    Timer(final Scheduled<?> scheduled, final Object data, final long dueAt, final long interval) {
      this.scheduled = (Scheduled<Object>) scheduled;
      this.data = data;
      this.dueAt = dueAt;
      this.interval = interval;
    }

    void fire() {
      scheduled.intervalSignal(scheduled, data);
    }
  }
}
