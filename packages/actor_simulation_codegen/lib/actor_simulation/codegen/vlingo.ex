defmodule ActorSimulation.Codegen.Vlingo do
  alias ActorSimulation.TemplateVersions

  @moduledoc """
  Generates VLINGO XOOM Actors code from ActorSimulation DSL.

  VLINGO XOOM is a Java actor framework that provides:
  - Type-safe actor implementations
  - Protocol-based (interface) messaging
  - Scheduler-based message dispatch
  - Reactive foundation for distributed systems

  This generator creates production-ready Java projects with:
  - Actor implementations with protocol interfaces
  - JUnit 5 test suites
  - Maven build configuration
  - CI/CD pipeline
  - Complete documentation

  ## Example

      simulation = ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
            send_pattern: {:periodic, 100, :msg},
            targets: [:receiver])
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} = Vlingo.generate(simulation,
        project_name: "my-actors",
        group_id: "com.example")

      Vlingo.write_to_directory(files, "vlingo_output/")
  """

  alias ActorSimulation.GeneratorUtils

  @doc """
  Generates complete VLINGO XOOM project files from an ActorSimulation.

  ## Options

  - `:project_name` (required) - Name of the Java project (kebab-case)
  - `:group_id` (default: "com.example") - Maven group ID
  - `:vlingo_version` - VLINGO XOOM version, defaulting to
    `ActorSimulation.TemplateVersions.get(:vlingo)`
  - `:enable_callbacks` (default: true) - Generate callback interfaces

  ## Returns

  `{:ok, files}` where files is a list of `{filename, content}` tuples
  """
  def generate(simulation, opts \\ []) do
    project_name = Keyword.fetch!(opts, :project_name)
    group_id = Keyword.get(opts, :group_id, "com.example")
    vlingo_version = Keyword.get(opts, :vlingo_version, TemplateVersions.get(:vlingo))
    enable_callbacks = Keyword.get(opts, :enable_callbacks, true)

    actors = simulation.actors
    package_path = String.replace(group_id, ".", "/")

    files =
      []
      |> add_actor_files(actors, group_id, package_path, enable_callbacks)
      |> add_main_file(actors, project_name, group_id, package_path, enable_callbacks)
      |> add_test_files(actors, group_id, package_path, enable_callbacks)
      |> add_pom_file(project_name, group_id, vlingo_version)
      |> add_ci_pipeline(project_name)
      |> add_readme(actors, project_name)

    {:ok, files}
  end

  @doc """
  Writes generated files to a directory.
  """
  def write_to_directory(files, output_dir) do
    GeneratorUtils.write_to_directory(files, output_dir)
  end

  # Private functions

  defp add_actor_files(files, actors, group_id, package_path, enable_callbacks) do
    Enum.reduce(actors, files, fn {name, actor_info}, acc ->
      case actor_info.type do
        :simulated ->
          definition = actor_info.definition
          class_name = GeneratorUtils.to_pascal_case(name)

          # Protocol interface
          protocol = generate_protocol_interface(name, definition, group_id)
          protocol_file = "src/main/java/#{package_path}/#{class_name}Protocol.java"

          # Actor implementation
          actor_impl = generate_actor_implementation(name, definition, group_id, enable_callbacks)
          actor_file = "src/main/java/#{package_path}/#{class_name}Actor.java"

          new_files = [
            {protocol_file, protocol},
            {actor_file, actor_impl}
          ]

          new_files =
            if enable_callbacks do
              callback_interface = generate_callback_interface(name, definition, group_id)
              callback_impl = generate_callback_implementation(name, definition, group_id)

              callback_interface_file =
                "src/main/java/#{package_path}/#{class_name}Callbacks.java"

              callback_impl_file =
                "src/main/java/#{package_path}/#{class_name}CallbacksImpl.java"

              new_files ++
                [
                  {callback_interface_file, callback_interface},
                  {callback_impl_file, callback_impl}
                ]
            else
              new_files
            end

          new_files ++ acc

        :real_process ->
          acc
      end
    end)
  end

  defp add_main_file(files, actors, project_name, group_id, package_path, enable_callbacks) do
    content = generate_main(actors, project_name, group_id, enable_callbacks)
    main_file = "src/main/java/#{package_path}/Main.java"
    [{main_file, content} | files]
  end

  defp add_test_files(files, actors, group_id, package_path, enable_callbacks) do
    simulated = GeneratorUtils.simulated_actors(actors)

    test_files =
      Enum.flat_map(simulated, fn {name, definition} ->
        class_name = GeneratorUtils.to_pascal_case(name)
        test_content = generate_test_class(name, definition, group_id, enable_callbacks)
        test_file = "src/test/java/#{package_path}/#{class_name}ActorTest.java"
        [{test_file, test_content}]
      end)

    # The clock the tests own, for the projects whose actors wait for time.
    clock_files =
      if Enum.any?(simulated, fn {_name, definition} -> interval_of(definition) != :none end) do
        clock = generate_manual_scheduler(group_id)
        [{"src/test/java/#{package_path}/ManualScheduler.java", clock}]
      else
        []
      end

    clock_files ++ test_files ++ files
  end

  # interval_of answers how far apart the sends of an actor are, in milliseconds, or
  # :none when the actor does not send on a clock.
  defp interval_of(%{send_pattern: {:periodic, interval_ms, _message}}), do: interval_ms
  defp interval_of(%{send_pattern: {:rate, per_second, _message}}), do: div(1000, per_second)
  defp interval_of(%{send_pattern: {:burst, _count, interval_ms, _message}}), do: interval_ms
  defp interval_of(%{send_pattern: {:self_message, delay_ms, _message}}), do: delay_ms
  defp interval_of(_definition), do: :none

  # The clock a test owns: a Scheduler that fires nothing until the test says how
  # much time has passed, and then fires what is due on the test's thread.
  defp generate_manual_scheduler(group_id) do
    """
    // Generated from ActorSimulation DSL
    // A scheduler whose time is the test's.

    package #{group_id};

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
    """
  end

  defp add_pom_file(files, project_name, group_id, vlingo_version) do
    content = generate_pom(project_name, group_id, vlingo_version)
    [{"pom.xml", content} | files]
  end

  defp add_ci_pipeline(files, project_name) do
    content = generate_ci_pipeline(project_name)
    [{".github/workflows/ci.yml", content} | files]
  end

  defp add_readme(files, actors, project_name) do
    content = generate_readme(project_name, actors)
    [{"README.md", content} | files]
  end

  defp generate_protocol_interface(name, definition, group_id) do
    class_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    methods =
      if messages != [] do
        Enum.map_join(messages, "\n", fn msg ->
          msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_camel_case()
          "  void #{msg_name}();"
        end)
      else
        "  void process();"
      end

    # Protocol interfaces should NOT extend Scheduled - that causes issues with VLINGO's proxy generator
    # The Actor implementation will implement Scheduled directly

    """
    // Generated from ActorSimulation DSL
    // Protocol interface for: #{name}

    package #{group_id};

    /**
     * Protocol interface for #{class_name} actor.
     * This interface defines the messages that can be sent to this actor.
     */
    public interface #{class_name}Protocol {
    #{methods}
    }
    """
  end

  defp generate_callback_code(enable_callbacks, class_name) do
    if enable_callbacks do
      field = """
        private final #{class_name}Callbacks callbacks;
      """

      param = ", #{class_name}Callbacks callbacks"

      init = """
          this.callbacks = (callbacks != null) ? callbacks : new #{class_name}CallbacksImpl();
      """

      {field, param, init}
    else
      {"", "", ""}
    end
  end

  defp generate_target_code(targets, class_name) do
    if targets != [] do
      field = """
        private final List<#{class_name}Protocol> targets;
      """

      param = ", List<#{class_name}Protocol> targets"

      init = """
          this.targets = (targets != null) ? targets : new ArrayList<>();
      """

      {field, param, init}
    else
      {"", "", ""}
    end
  end

  defp generate_method_implementations(messages, definition, enable_callbacks) do
    if messages != [] do
      Enum.map_join(messages, "\n\n", fn msg ->
        generate_message_method(msg, definition, enable_callbacks)
      end)
    else
      processing =
        if enable_callbacks do
          """
            callbacks.onProcess();
          """
        else
          """
            logger().info(getClass().getSimpleName() + " processing...");
          """
        end

      """
        @Override
        public void process() {
      #{processing}      // Send to targets
          sendToTargets();
        }

        private void sendToTargets() {
          // No targets defined
        }
      """
    end
  end

  defp generate_imports_and_implements(definition) do
    has_targets = definition.targets != []

    list_import =
      if has_targets, do: "import java.util.List;\nimport java.util.ArrayList;", else: ""

    {scheduled_import, scheduled_implements} =
      case definition.send_pattern do
        {:periodic, _, _} ->
          {"import io.vlingo.xoom.common.Scheduled;", ", Scheduled<Object>"}

        {:rate, _, _} ->
          {"import io.vlingo.xoom.common.Scheduled;", ", Scheduled<Object>"}

        {:burst, _, _, _} ->
          {"import io.vlingo.xoom.common.Scheduled;", ", Scheduled<Object>"}

        {:self_message, _, _} ->
          {"import io.vlingo.xoom.common.Scheduled;", ", Scheduled<Object>"}

        _ ->
          {"", ""}
      end

    {list_import, scheduled_import, scheduled_implements}
  end

  defp generate_actor_implementation(name, definition, group_id, enable_callbacks) do
    class_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    {callback_field, callback_param, callback_init} =
      generate_callback_code(enable_callbacks, class_name)

    {target_field, target_param, target_init} =
      generate_target_code(definition.targets, class_name)

    self_message_init = generate_self_message_init(definition, class_name)
    method_impls = generate_method_implementations(messages, definition, enable_callbacks)
    interval_signal_method = generate_interval_signal_method(definition, messages)

    {list_import, scheduled_import, scheduled_implements} =
      generate_imports_and_implements(definition)

    timed? = scheduled_implements != ""

    # A test that owns the time passes its own scheduler; production passes nothing
    # and gets the stage's, so the actor waits on the wall clock as before.
    scheduler_param = if timed?, do: ", io.vlingo.xoom.common.Scheduler timers", else: ""

    scheduler_init =
      if timed? do
        """

            final io.vlingo.xoom.common.Scheduler clock = (timers != null) ? timers : scheduler();
        """
      else
        ""
      end

    """
    // Generated from ActorSimulation DSL
    // Actor implementation for: #{name}

    package #{group_id};

    import io.vlingo.xoom.actors.Actor;
    #{scheduled_import}
    #{list_import}

    /**
     * Actor implementation for #{class_name}.
     * This actor implements the #{class_name}Protocol interface.
     */
    public class #{class_name}Actor extends Actor implements #{class_name}Protocol#{scheduled_implements} {
    #{callback_field}#{target_field}
      /**
       * Constructor for #{class_name}Actor.
       */
      @SuppressWarnings("unchecked")
      public #{class_name}Actor(#{format_constructor_params(callback_param, target_param)}#{scheduler_param}) {
    #{callback_init}#{target_init}#{scheduler_init}#{self_message_init}  }

    #{method_impls}
    #{interval_signal_method}

      @Override
      public void stop() {
        super.stop();
      }
    }
    """
  end

  defp generate_self_message_init(definition, _class_name) do
    case definition.send_pattern do
      {:self_message, delay_ms, _message} ->
        """

            // Schedule one-shot self-message
            clock.scheduleOnce(
              selfAs(Scheduled.class),
              null,
              0L,
              #{delay_ms}L
            );
        """

      {:periodic, interval_ms, _message} ->
        """

            // Schedule periodic message sending
            clock.schedule(
              selfAs(Scheduled.class),
              null,
              #{interval_ms}L,
              #{interval_ms}L
            );
        """

      {:rate, per_second, _message} ->
        interval_ms = div(1000, per_second)

        """

            // Schedule rate-based message sending
            clock.schedule(
              selfAs(Scheduled.class),
              null,
              #{interval_ms}L,
              #{interval_ms}L
            );
        """

      {:burst, _count, interval_ms, _message} ->
        """

            // Schedule burst message sending
            clock.schedule(
              selfAs(Scheduled.class),
              null,
              #{interval_ms}L,
              #{interval_ms}L
            );
        """

      _ ->
        ""
    end
  end

  defp generate_interval_signal_method(definition, messages) do
    case definition.send_pattern do
      {:periodic, _, _} when messages != [] ->
        [first_msg | _] = messages
        msg_name = GeneratorUtils.message_name(first_msg) |> GeneratorUtils.to_camel_case()

        """

          @Override
          public void intervalSignal(io.vlingo.xoom.common.Scheduled<Object> scheduled, Object data) {
            #{msg_name}();
          }
        """

      {:rate, _, _} when messages != [] ->
        [first_msg | _] = messages
        msg_name = GeneratorUtils.message_name(first_msg) |> GeneratorUtils.to_camel_case()

        """

          @Override
          public void intervalSignal(io.vlingo.xoom.common.Scheduled<Object> scheduled, Object data) {
            #{msg_name}();
          }
        """

      {:burst, _, _, _} when messages != [] ->
        [first_msg | _] = messages
        msg_name = GeneratorUtils.message_name(first_msg) |> GeneratorUtils.to_camel_case()

        """

          @Override
          public void intervalSignal(io.vlingo.xoom.common.Scheduled<Object> scheduled, Object data) {
            #{msg_name}();
          }
        """

      {:self_message, _, _} when messages != [] ->
        [first_msg | _] = messages
        msg_name = GeneratorUtils.message_name(first_msg) |> GeneratorUtils.to_camel_case()

        """

          @Override
          public void intervalSignal(io.vlingo.xoom.common.Scheduled<Object> scheduled, Object data) {
            #{msg_name}();
          }
        """

      _ ->
        ""
    end
  end

  defp generate_message_method(msg, definition, enable_callbacks) do
    msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_camel_case()
    msg_name_pascal = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_pascal_case()

    callback_call =
      if enable_callbacks do
        """
          callbacks.on#{msg_name_pascal}();
        """
      else
        """
          logger().info(getClass().getSimpleName() + " received #{msg}");
        """
      end

    send_to_targets =
      if definition.targets != [] do
        """
            // Send to all targets
            for (var target : targets) {
              target.#{msg_name}();
            }
        """
      else
        ""
      end

    """
      @Override
      public void #{msg_name}() {
        #{callback_call}#{send_to_targets}
      }
    """
  end

  defp generate_callback_interface(name, definition, group_id) do
    class_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    methods =
      if messages != [] do
        Enum.map_join(messages, "\n", fn msg ->
          msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_pascal_case()
          "  void on#{msg_name}();"
        end)
      else
        "  void onProcess();"
      end

    """
    // Generated from ActorSimulation DSL
    // Callback interface for: #{name}
    // DO NOT EDIT - This file is auto-generated
    //
    // This interface defines the contract for #{class_name} callbacks.
    // Customize behavior by editing #{class_name}CallbacksImpl.java

    package #{group_id};

    /**
     * Callback interface for #{class_name} actor.
     * This is the contract - do not modify this interface.
     * Customize behavior in #{class_name}CallbacksImpl instead.
     */
    public interface #{class_name}Callbacks {
    #{methods}
    }
    """
  end

  defp generate_callback_implementation(name, definition, group_id) do
    class_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    methods =
      if messages != [] do
        Enum.map_join(messages, "\n\n", fn msg ->
          msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_pascal_case()
          # If actor has send_pattern, it's the sender (publisher)
          action = if definition.send_pattern, do: "Sending", else: "Received"

          """
            @Override
            public void on#{msg_name}() {
              // TODO: Implement custom behavior for #{msg}
              System.out.println("#{class_name}: #{action} #{msg} message");
            }
          """
        end)
      else
        """
          @Override
          public void onProcess() {
            // TODO: Implement custom behavior
            System.out.println("#{class_name}: Processing message");
          }
        """
      end

    """
    // Generated from ActorSimulation DSL
    // Default callback implementation for: #{name}
    //
    // CUSTOMIZE THIS CLASS to add your own behavior!

    package #{group_id};

    /**
     * Default implementation of #{class_name}Callbacks.
     * Modify this class to add custom behavior.
     */
    public class #{class_name}CallbacksImpl implements #{class_name}Callbacks {
    #{methods}
    }
    """
  end

  defp generate_main(actors, project_name, group_id, enable_callbacks) do
    simulated = GeneratorUtils.simulated_actors(actors)

    spawn_code =
      Enum.map_join(simulated, "\n", fn {name, definition} ->
        snake_name = GeneratorUtils.to_camel_case(name)
        class_name = GeneratorUtils.to_pascal_case(name)

        # Determine parameters based on constructor needs
        params =
          cond do
            enable_callbacks && definition.targets != [] ->
              "(#{class_name}Callbacks) null, new java.util.ArrayList<>()"

            enable_callbacks ->
              "(#{class_name}Callbacks) null"

            definition.targets != [] ->
              "new java.util.ArrayList<>()"

            true ->
              ""
          end

        # A timed actor also takes its scheduler, and production lets it have the
        # stage's, which is the wall clock.
        params =
          if interval_of(definition) != :none and params != "" do
            params <> ", (io.vlingo.xoom.common.Scheduler) null"
          else
            params
          end

        """
        #{class_name}Protocol #{snake_name} = world.actorFor(
              #{class_name}Protocol.class,
              Definition.has(#{class_name}Actor.class,
                Definition.parameters(#{params}))
            );
        """
      end)

    """
    // Generated from ActorSimulation DSL
    // Main entry point for #{project_name}

    package #{group_id};

    import io.vlingo.xoom.actors.Definition;
    import io.vlingo.xoom.actors.World;

    /**
     * Main class to start the VLINGO XOOM actor system on the wall clock.
     */
    public class Main {
      /** How long the actors run: long enough to see them work, short enough for a demo. */
      private static final long RUN_MILLIS = 300L;

      /** No scheduler is given, so the actors wait on the wall clock. */
      public static void main(String[] args) throws InterruptedException {
        System.out.println("Starting VLINGO XOOM actor system...");

        final World world = World.startWithDefaults("#{project_name}");

        // The world's scheduler has threads of its own, and terminating the world
        // does not stop them, so a program that is done closes the scheduler too.
        final io.vlingo.xoom.common.Scheduler timers = world.stage().scheduler();

        try {
          // Spawn all actors
    #{spawn_code}

          System.out.println("Running for " + RUN_MILLIS + "ms...");
          Thread.sleep(RUN_MILLIS);
        } finally {
          world.terminate();
          timers.close();
        }

        System.out.println("Stopped.");

        // The actor world leaves threads of its own behind even after it is
        // terminated and its scheduler closed, so a demo that is over says so to the
        // JVM instead of waiting for them.
        System.exit(0);
      }
    }
    """
  end

  defp generate_test_class(name, definition, group_id, enable_callbacks) do
    class_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)
    interval = interval_of(definition)

    if interval != :none and enable_callbacks do
      generate_timed_test_class(class_name, messages, definition, group_id, interval)
    else
      generate_plain_test_class(class_name, messages, definition, group_id, enable_callbacks)
    end
  end

  # The test of an actor that waits: the actor is handed a clock the test owns, and
  # the test says how much time has passed instead of waiting for it.
  defp generate_timed_test_class(class_name, messages, definition, group_id, interval_ms) do
    target_param = if definition.targets != [], do: ", new ArrayList<>()", else: ""
    one_shot? = match?({:self_message, _, _}, definition.send_pattern)

    repeats_constant =
      if one_shot?, do: "", else: "\n      private static final int REPEATS = 3;"

    count_test_name =
      if one_shot?,
        do: "testTheActorSendsOnceWhenTheTestSaysItsDelayHasPassed",
        else: "testTheActorSendsOncePerIntervalTheTestSaysHasPassed"

    """
    // Generated from ActorSimulation DSL
    // JUnit 5 tests for #{class_name}Actor

    package #{group_id};

    import static org.junit.jupiter.api.Assertions.assertEquals;
    import static org.junit.jupiter.api.Assertions.assertNotNull;
    import static org.junit.jupiter.api.Assertions.assertTrue;

    import io.vlingo.xoom.actors.Definition;
    import io.vlingo.xoom.actors.World;
    import io.vlingo.xoom.actors.testkit.TestUntil;
    import java.util.ArrayList;
    import java.util.concurrent.atomic.AtomicInteger;
    import org.junit.jupiter.api.AfterEach;
    import org.junit.jupiter.api.BeforeEach;
    import org.junit.jupiter.api.Test;

    /**
     * Test class for #{class_name}Actor. The time the actor waits in is this test's:
     * the scheduler it is handed is a ManualScheduler, so nothing is due until the
     * test says how much time has passed.
     */
    public class #{class_name}ActorTest {
      private static final long INTERVAL_MILLIS = #{interval_ms}L;
      private static final long BOUND_MILLIS = 1000L;#{repeats_constant}

      private World world;
      private ManualScheduler clock;
      private #{class_name}Protocol actor;
      private final AtomicInteger sent = new AtomicInteger();
      private final TestUntil handled = TestUntil.happenings(1);

      private void count() {
        sent.incrementAndGet();
        handled.happened();
      }

      @BeforeEach
      public void setUp() {
        clock = new ManualScheduler();
        world = World.startWithDefaults("test-world");

        final #{class_name}Callbacks counting = new #{class_name}Callbacks() {
    #{counting_callbacks(messages)}
        };

        actor =
            world.actorFor(
                #{class_name}Protocol.class,
                Definition.has(
                    #{class_name}Actor.class,
                    Definition.parameters(counting#{target_param}, clock)));
      }

      @AfterEach
      public void tearDown() {
        if (world != null) {
          world.terminate();
        }
      }

      @Test
      public void testActorCreation() {
        assertNotNull(actor, "Actor should be created");
      }

      @Test
      public void #{count_test_name}() {
        // The actor arms its timer in its constructor, which runs when its first
        // message is handled: the test waits for that delivery, and for no time.
        handled.resetHappeningsTo(1);
        actor.#{first_message(messages)}();
        assertTrue(
            handled.completesWithin(BOUND_MILLIS), "the actor did not handle its first message");

        final int before = sent.get();

        clock.advanceBy(INTERVAL_MILLIS - 1);
        assertEquals(before, sent.get(), "the actor sent before its interval was up");
    #{timed_count_test(one_shot?)}    }
    }
    """
  end

  # timed_count_test answers the part of a timed test that holds the actor to the
  # number of sends its clock made due: one per interval, or one in all for a
  # one-shot.
  defp timed_count_test(true) do
    """

        handled.resetHappeningsTo(1);
        clock.advanceBy(1);
        assertTrue(
            handled.completesWithin(BOUND_MILLIS), "the send the clock made due was not handled");
        assertEquals(before + 1, sent.get(), "the actor did not send when its delay was up");

        clock.advanceBy(INTERVAL_MILLIS); // a one-shot has nothing left to send
        assertEquals(before + 1, sent.get(), "the actor sent again, and was asked for one send");
    """
  end

  defp timed_count_test(false) do
    """

        handled.resetHappeningsTo(REPEATS);
        clock.advanceBy(REPEATS * INTERVAL_MILLIS);
        assertTrue(
            handled.completesWithin(BOUND_MILLIS), "the sends the clock made due were not handled");
        assertEquals(
            before + REPEATS,
            sent.get(),
            "one interval, one send: " + REPEATS + " intervals, " + REPEATS + " sends");
    """
  end

  defp generate_plain_test_class(class_name, messages, definition, group_id, enable_callbacks) do
    if enable_callbacks do
      target_param = if definition.targets != [], do: ", new ArrayList<>()", else: ""

      """
      // Generated from ActorSimulation DSL
      // JUnit 5 tests for #{class_name}Actor

      package #{group_id};

      import static org.junit.jupiter.api.Assertions.assertEquals;
      import static org.junit.jupiter.api.Assertions.assertNotNull;
      import static org.junit.jupiter.api.Assertions.assertTrue;

      import io.vlingo.xoom.actors.Definition;
      import io.vlingo.xoom.actors.World;
      import io.vlingo.xoom.actors.testkit.TestUntil;
      import java.util.ArrayList;
      import java.util.concurrent.atomic.AtomicInteger;
      import org.junit.jupiter.api.AfterEach;
      import org.junit.jupiter.api.BeforeEach;
      import org.junit.jupiter.api.Test;

      /**
       * Test class for #{class_name}Actor.
       */
      public class #{class_name}ActorTest {
        private static final long BOUND_MILLIS = 1000L;

        private World world;
        private #{class_name}Protocol actor;
        private final AtomicInteger sent = new AtomicInteger();
        private final TestUntil handled = TestUntil.happenings(1);

        private void count() {
          sent.incrementAndGet();
          handled.happened();
        }

        @BeforeEach
        public void setUp() {
          world = World.startWithDefaults("test-world");

          final #{class_name}Callbacks counting = new #{class_name}Callbacks() {
      #{counting_callbacks(messages)}
          };

          actor =
              world.actorFor(
                  #{class_name}Protocol.class,
                  Definition.has(
                      #{class_name}Actor.class, Definition.parameters(counting#{target_param})));
        }

        @AfterEach
        public void tearDown() {
          if (world != null) {
            world.terminate();
          }
        }

        @Test
        public void testActorCreation() {
          assertNotNull(actor, "Actor should be created");
        }

        @Test
        public void testTheActorHandlesItsMessage() {
          handled.resetHappeningsTo(1);
          actor.#{first_message(messages)}();
          assertTrue(handled.completesWithin(BOUND_MILLIS), "the actor did not handle the message");
          assertEquals(1, sent.get(), "the actor handled the message once");
        }
      }
      """
    else
      """
      // Generated from ActorSimulation DSL
      // JUnit 5 tests for #{class_name}Actor

      package #{group_id};

      import static org.junit.jupiter.api.Assertions.assertNotNull;

      import io.vlingo.xoom.actors.Definition;
      import io.vlingo.xoom.actors.World;
      import org.junit.jupiter.api.AfterEach;
      import org.junit.jupiter.api.BeforeEach;
      import org.junit.jupiter.api.Test;

      /**
       * Test class for #{class_name}Actor. Without callbacks there is nothing to
       * observe from outside, so the test holds the actor to being created.
       */
      public class #{class_name}ActorTest {
        private World world;
        private #{class_name}Protocol actor;

        @BeforeEach
        public void setUp() {
          world = World.startWithDefaults("test-world");
          actor =
              world.actorFor(
                  #{class_name}Protocol.class,
                  Definition.has(#{class_name}Actor.class, Definition.parameters()));
        }

        @AfterEach
        public void tearDown() {
          if (world != null) {
            world.terminate();
          }
        }

        @Test
        public void testActorCreation() {
          assertNotNull(actor, "Actor should be created");
        }
      }
      """
    end
  end

  # counting_callbacks counts what the actor does and tells the test when it did it:
  # the mailbox is still asynchronous, so the test needs to hear about a delivery,
  # and TestUntil bounds that wait without waiting for time.
  defp counting_callbacks([]) do
    """
          @Override
          public void onProcess() {
            count();
          }
    """
  end

  defp counting_callbacks(messages) do
    Enum.map_join(messages, "\n", fn msg ->
      msg_pascal = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_pascal_case()

      """
            @Override
            public void on#{msg_pascal}() {
              count();
            }
      """
    end)
  end

  defp first_message([]), do: "process"

  defp first_message(messages) do
    messages |> hd() |> GeneratorUtils.message_name() |> GeneratorUtils.to_camel_case()
  end

  defp generate_pom(project_name, group_id, vlingo_version) do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <project xmlns="http://maven.apache.org/POM/4.0.0"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                                 http://maven.apache.org/xsd/maven-4.0.0.xsd">
      <modelVersion>4.0.0</modelVersion>

      <groupId>#{group_id}</groupId>
      <artifactId>#{project_name}</artifactId>
      <version>1.0-SNAPSHOT</version>
      <packaging>jar</packaging>

      <name>#{project_name}</name>
      <description>Generated from ActorSimulation DSL using VLINGO XOOM Actors</description>

      <properties>
        <maven.compiler.source>#{TemplateVersions.get(:java_release)}</maven.compiler.source>
        <maven.compiler.target>#{TemplateVersions.get(:java_release)}</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <vlingo.version>#{vlingo_version}</vlingo.version>
        <junit.version>#{TemplateVersions.get(:junit)}</junit.version>
      </properties>

      <dependencies>
        <!-- VLINGO XOOM Actors -->
        <dependency>
          <groupId>io.vlingo.xoom</groupId>
          <artifactId>xoom-actors</artifactId>
          <version>${vlingo.version}</version>
        </dependency>

        <!-- JUnit 5 for testing -->
        <dependency>
          <groupId>org.junit.jupiter</groupId>
          <artifactId>junit-jupiter-api</artifactId>
          <version>${junit.version}</version>
          <scope>test</scope>
        </dependency>
        <dependency>
          <groupId>org.junit.jupiter</groupId>
          <artifactId>junit-jupiter-engine</artifactId>
          <version>${junit.version}</version>
          <scope>test</scope>
        </dependency>
      </dependencies>

      <build>
        <plugins>
          <!-- Compiler plugin -->
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <version>#{TemplateVersions.get(:maven_compiler_plugin)}</version>
            <configuration>
              <release>#{TemplateVersions.get(:java_release)}</release>
              <compilerArgs>
                <arg>-Xlint:unchecked</arg>
              </compilerArgs>
            </configuration>
          </plugin>

          <!-- Surefire plugin for running tests -->
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>#{TemplateVersions.get(:maven_surefire_plugin)}</version>
            <configuration>
              <includes>
                <include>**/*Test.java</include>
              </includes>
              <reportFormat>xml</reportFormat>
              <reportNameSuffix>junit5</reportNameSuffix>
            </configuration>
          </plugin>

          <!-- Exec plugin to run main class -->
          <plugin>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>exec-maven-plugin</artifactId>
            <version>#{TemplateVersions.get(:maven_exec_plugin)}</version>
            <configuration>
              <!-- A forked JVM, not exec:java: VLINGO compiles an actor's proxy at
                   runtime, and that compiler needs the project's classpath. -->
              <executable>java</executable>
              <arguments>
                <argument>-classpath</argument>
                <classpath />
                <argument>#{group_id}.Main</argument>
              </arguments>
            </configuration>
          </plugin>

          <!-- Assembly plugin for creating executable JAR -->
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-assembly-plugin</artifactId>
            <version>#{TemplateVersions.get(:maven_assembly_plugin)}</version>
            <configuration>
              <archive>
                <manifest>
                  <mainClass>#{group_id}.Main</mainClass>
                </manifest>
              </archive>
              <descriptorRefs>
                <descriptorRef>jar-with-dependencies</descriptorRef>
              </descriptorRefs>
            </configuration>
            <executions>
              <execution>
                <id>make-assembly</id>
                <phase>package</phase>
                <goals>
                  <goal>single</goal>
                </goals>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>

      <repositories>
        <repository>
          <id>central</id>
          <url>https://repo.maven.apache.org/maven2</url>
        </repository>
      </repositories>
    </project>
    """
  end

  defp format_constructor_params(callback_param, target_param) do
    # Remove leading commas and trim
    params =
      (callback_param <> target_param)
      |> String.replace(~r/^,\s*/, "")
      |> String.trim()

    params
  end

  defp generate_ci_pipeline(_project_name) do
    """
    name: CI

    on:
      push:
        branches: [ main, develop ]
      pull_request:
        branches: [ main ]

    # The test-result action publishes a check run, which needs checks: write.
    permissions:
      contents: read
      checks: write
      pull-requests: write

    jobs:
      build:
        runs-on: ${{ matrix.os }}
        strategy:
          fail-fast: false
          matrix:
            os: [ubuntu-latest, macos-latest, windows-latest]
            java: ['#{TemplateVersions.get(:java_release)}', '21']

        steps:
        - uses: actions/checkout@#{TemplateVersions.get(:checkout_action)}

        - name: Set up JDK ${{ matrix.java }}
          uses: actions/setup-java@#{TemplateVersions.get(:setup_java_action)}
          with:
            java-version: ${{ matrix.java }}
            distribution: 'temurin'
            cache: 'maven'

        - name: Build with Maven
          run: mvn clean compile

        - name: Run tests
          run: mvn test

        - name: Package application
          run: mvn package

        - name: Publish Test Results
          # The action is a container, so it runs on Linux only.
          if: always() && runner.os == 'Linux'
          uses: EnricoMi/publish-unit-test-result-action@#{TemplateVersions.get(:publish_test_results_action)}
          with:
            files: |
              target/surefire-reports/*.xml
            check_name: "Test Results (Java ${{ matrix.java }}, ${{ matrix.os }})"

        - name: Run the application
          run: mvn -B -q compile exec:exec
    """
  end

  defp generate_readme(project_name, actors) do
    clock_section =
      actors
      |> GeneratorUtils.simulated_actors()
      |> Enum.find(fn {_name, definition} -> interval_of(definition) != :none end)
      |> case do
        nil -> ""
        timed -> generate_readme_clock_section(timed)
      end

    """
    # #{project_name}

    Generated from the [ActorSimulation DSL](https://github.com/d-led/gen_server_virtual_time) with
    [VLINGO XOOM Actors](https://docs.vlingo.io/xoom-actors).

    ## Run it

    ```bash
    mvn test                     # the tests, which own time: none of them waits for a timer
    mvn compile exec:exec        # the same actors on the wall clock, briefly, then it stops
    ```

    Requires Java #{TemplateVersions.get(:java_release)}+ and Maven 3.6+.

    ## What is where

    | file | what |
    |------|------|
    | `src/main/java/**/Main.java` | the actors on the wall clock, for a moment |
    | `src/main/java/**/*Actor.java` | the generated actors, each taking its `Scheduler` |
    | `src/main/java/**/*Protocol.java` | the messages an actor takes |
    | `src/main/java/**/*CallbacksImpl.java` | **your behaviour goes here** |
    | `src/test/java/**/ManualScheduler.java` | the clock the tests own |
    | `src/test/java/**/*ActorTest.java` | the tests |

    #{clock_section}## Learn more

    - [VLINGO XOOM documentation](https://docs.vlingo.io/xoom-actors)
    - [The ActorSimulation DSL](https://github.com/d-led/gen_server_virtual_time)
    """
  end

  defp generate_readme_clock_section({name, definition}) do
    class_name = GeneratorUtils.to_pascal_case(name)
    interval_ms = interval_of(definition)

    """
    ## The time the actors wait in belongs to the tests

    An actor that sends every #{interval_ms}ms would make a test of it take as long as the test runs.
    The generated actors take their `Scheduler` as a constructor argument: production passes none and
    gets the stage's, which is the wall clock, and a test hands the actor a `ManualScheduler` — the
    clock the test owns, in `src/test/java` — which fires nothing until the test calls `advanceBy`.
    The tests assert the counts that clock produces, down to the millisecond before an interval;
    what is left here is what the same actors print on the wall clock:

    ```shell
    $ mvn compile exec:exec
    Starting VLINGO XOOM actor system...
    #{class_name}: Sending #{first_message(messages_of(definition))} message
    #{class_name}: Sending #{first_message(messages_of(definition))} message
    Running for 300ms...
    Stopped.
    ```

    """
  end

  defp messages_of(definition), do: GeneratorUtils.extract_messages(definition.send_pattern)
end
