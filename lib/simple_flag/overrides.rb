class SimpleFlag
  module Overrides

    def override(name, result = true, &block)
      raise FlagNotDefined, "Feature flag `#{name}` is not defined" unless flag?(name)

      # We are using proc, not lambda, because proc does not check for number of arguments
      original_block = overridden?(name) ? @overrides[name] : @flags[name]
      @overrides[name] = original_block
      @flags[name] =
        if block_given?
          validate_flag_arity(name, original_block.arity, block.arity)
          block
        else
          proc { |*_args| result }
        end

      original_block
    end

    def override_with(name, result = true, &block)
      raise FlagNotDefined, "Feature flag `#{name}` is not defined" unless flag?(name)

      original_block = @flags[name]
      @flags[name] = proc { |*_args| result }
      block.call
    ensure
      @flags[name] = original_block
    end

    def reset_override(name)
      raise FlagNotOverridden, "Feature flag `#{name}` was not overridden" unless overridden?(name)

      original_block = @overrides.delete(name)
      @flags[name] = original_block
    end

    def reset_all_overrides
      @overrides.each_key { |name| reset_override(name) }
    end

    def overridden?(name)
      @overrides.key?(name)
    end

  end
end
