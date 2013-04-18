#  Copyright (c) 2011 Pete Higgins
#  https://github.com/phiggins/em-minitest-spec
#
require 'eventmachine'

module EM # :nodoc:
  module MiniTest # :nodoc:
    module Spec # :nodoc
      VERSION = '1.1.0' # :nodoc:

      ##
      # +wait+ indicates that the spec is not expected to be completed when
      # the block is finished running. A call to +done+ is required when using
      # +wait+.
      #
      #   # setup my spec to use EM::MiniTest::Spec
      #   describe MyClass do
      #     include EM::MiniTest::Spec
      #
      #     # The call to defer will return immediately, so the spec code
      #     # needs to keep running until callback is called.
      #     it "does some async things" do
      #       defer_me = lambda do
      #         # some async stuff
      #       end
      #
      #       callback = lambda do
      #         done!
      #       end
      #
      #       EM.defer defer_me, callback
      #
      #       wait!
      #     end
      def wait
        @wait = true
      end
      alias wait! wait

      ##
      # Indicates that an async spec is finished. See +wait+ for example usage.
      def done
        EM.cancel_timer(@timeout)
        EM.stop
      end
      alias done! done

      ##
      # A helper method for the use case of waiting for some operation to
      # complete that is not necessarily under the control of the spec code.
      #
      #   # These are exactly equivalent
      #   it "waits with the helper" do
      #     wait_for do
      #       assert true
      #     end
      #   end
      #
      #   it "waits manually" do
      #     EM.next_tick do
      #       assert true
      #       done!
      #     end
      #
      #     wait!
      #   end
      def wait_for
        EM.next_tick do
          yield
          done!
        end

        wait!
      end

      def self.included base # :nodoc:
        base.extend(ClassMethods)
      end

      module ClassMethods # :nodoc:
        def it *args, &block # :nodoc:
          return super unless block_given?

          super do
            @wait = false

            EM.run do
              @timeout = EM.add_timer(0.1) do
                flunk "test timed out!"
              end

              instance_eval(&block)
              done! unless @wait
            end
          end
        end
      end
    end
  end
end