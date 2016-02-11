module RenderSync
  class Reactor
    include MonitorMixin

    # Execute EventMachine bound code block, waiting for reactor to start if
    # not yet started or reactor thread has gone away
    def perform
      return EM.next_tick{ yield } if running?
      cleanly_shutdown_reactor
      condition = new_cond
      Thread.new do
        EM.run do
          EM.next_tick do
            synchronize do
              condition.signal
            end
          end
        end
      end
      synchronize do
        condition.wait_until { EM.reactor_running? }
        EM.next_tick { yield }
      end
    end

    def stop
      EM.stop if running?
    end

    def running?
      EM.reactor_running? && EM.reactor_thread.alive?
    end

    # If the reactor's thread died, EM still thinks it's running but it isn't.
    # This will happen if we forked from a process that had the reator running.
    # Tell EM it's dead. Stolen from the EM internals
    #
    # https://groups.google.com/forum/#!msg/ruby-amqp/zchM4QzbZRE/I43wIjbgIv4J
    #
    def cleanly_shutdown_reactor
      if EM.reactor_running?
        EM.stop_event_loop
        EM.release_machine
        EM.instance_variable_set '@reactor_running', false
      end
    end
  end
end
