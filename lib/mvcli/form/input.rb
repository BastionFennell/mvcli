require "mvcli/form"

class MVCLI::Form::Input
  def initialize(name, target, options = {}, &block)
    @decoders = []
    @handler = handler(target).new name, target, options, &block
  end

  def decode(&block)
    @handler.decode &block
    return self
  end

  def value(source, context = nil)
    @handler.value source, context
  end

  def handler(target)
    target.is_a?(Array) ? ListTarget : Target
  end

  class Target
    def initialize(name, target, options = {}, &block)
      @name, @options = name, Map(options)
      @decoders = []
      if block_given?
        @decoders << block
      end
    end

    def decode(&block)
      @decoders << block
    end

    def value(source, context = nil)
      if value = [source[@name]].flatten.first
        @decoders.reduce(value) do |value, decoder|
          decoder.call value
        end
      else
        default context
      end
    end

    def default(context)
      value = @options[:default]
      if value.respond_to?(:call)
        if context
          context.instance_exec(&value)
        else
          value.call
        end
      else
        value
      end
    end
  end

  class ListTarget < Target
    def value(source, context = nil)
      list = [source[@name]].compact.flatten.map do |value|
        super({@name => value}, context)
      end.compact
      list.empty? ? [default(context)].compact.flatten : list
    end
  end

end
