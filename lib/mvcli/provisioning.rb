require "map"
require "active_support/concern"
require "active_support/dependencies"
require "mvcli/loader"

module MVCLI
  module Provisioning
    extend ActiveSupport::Concern
    MissingScope = Class.new StandardError

    module ClassMethods
      def requires(*deps)
        deps.each do |dep|
          self.send(:define_method, dep) {Scope[dep]}
        end
      end
    end

    class Scope
      attr_reader :command, :cortex

      def initialize(command, cortex)
        @command = command
        @cortex = cortex
        @providers = Map command: const(command), cortex: const(cortex)
      end

      def [](name)
        unless provider = @providers[name]
          provider = @providers[name] = @cortex.access :provider, name
        end
        provider.respond_to?(:value) ? provider.value : provider.new.value
      end

      def evaluate
        old = self.class.current
        self.class.current = self
        yield
      ensure
        self.class.current = old
      end

      def const(value)
        Constant.new value
      end

      def self.current
        Thread.current[self.class.name]
      end

      def self.current!
        current or fail MissingScope, "attempting to access scope, but none is active!"
      end

      def self.current=(scope)
        Thread.current[self.class.name] = scope
      end

      def self.[](name)
        current![name]
      end
      class Constant
        attr_reader :value

        def initialize(value)
          @value = value
        end
      end
    end
    ::Object.send :include, self
  end
end
