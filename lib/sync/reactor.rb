module Sync
  class Reactor

    def start
      run unless running? || using_reactor_based_server?
    end

    def run
      Thread.new{ EM.run }
    end

    def stop
      EM.stop if running?
    end

    def running?
      EM.reactor_running?
    end

    def using_reactor_based_server?
      using_thin?
    end

    def using_thin?
      defined? Thin
    end
  end
end