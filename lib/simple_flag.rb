# frozen_string_literal: true

require 'simple_flag/version'

# Class FeatureFlag defines and stores feature flags
#
# @example Configuration
#
#    FEATURE = FeatureFlag.new do |feature|
#      feature.define(:new_user_profile) do |user_id:|
#        Admin.where(user_id: user_id).exists?
#      end
#
#      feature.define(:third_party_analytics) do
#        not Rails.env.production?
#      end
#    end
#
# @example Usage
#
#    class ProfilesController < ApplicationController
#      def show
#        FEATURE.with(:new_user_profile, user_id: current_user.id) do
#          return render :new_user_profile, locals: { user: NewUserProfilePresenterV2.new(current_user) }
#        end
#
#        render :show, locals: { user: UserProfilePresenterV1.new(current_user) }
#      end
#    end
#
# @example Testing with before...after
#
#    describe "User profiles" do
#      before { FEATURE.override(:new_user_profile, true) }
#      after  { FEATURE.reset_all_overrides }
#    end
#
# @example Testing with inline block
#
#    it "shows new user profile" do
#      FEATURE.override_with(:new_user_profile, true) do
#        expect( FEATURE.active?(:new_user_profile) ).to be_truthy
#      end
#
#      expect( FEATURE.active?(:new_user_profile) ).to be_falsy
#    end
#
# @see http://blog.arkency.com/2015/11/simple-feature-toggle-for-rails-app/
#
class SimpleFlag
  FlagAlreadyDefined = Class.new(StandardError)
  FlagNotDefined = Class.new(StandardError)
  FlagNotOverridden = Class.new(StandardError)
  FlagArgumentsMismatch = Class.new(StandardError)

  attr_reader :env

  def initialize(env: nil)
    @env       = env
    @flags     = {}
    @overrides = {}
    yield self if block_given?
  end

  def define(name, &block)
    raise FlagAlreadyDefined, "Feature flag `#{name}` is already defined" if flag?(name)

    @flags[name] = block
  end

  def redefine(name, &block)
    @flags[name] = block
  end

  def flags
    @flags.keys
  end

  def with(name, *args, &block)
    block.call if active?(name, *args)
  end

  def override(name, result = true, &block)
    raise FlagNotDefined, "Feature flag `#{name}` is not defined" unless flag?(name)
    raise FlagAlreadyDefined, "Feature flag `#{name}` is already overridden" if overridden?(name)

    # We are using proc, not lambda, because proc does not check for number of arguments
    original_block = @flags[name]
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

  def reset_override(name)
    raise FlagNotOverridden, "Feature flag `#{name}` was not overridden" unless overridden?(name)

    original_block = @overrides.delete(name)
    @flags[name] = original_block
  end

  def reset_all_overrides
    @overrides.each_key { |name| reset_override(name) }
  end

  def override_with(name, result = true, &block)
    raise FlagNotDefined, "Feature flag `#{name}` is not defined" unless flag?(name)

    original_block = @flags[name]
    @flags[name] = proc { |*_args| result }
    block.call
  ensure
    @flags[name] = original_block
  end

  def flag?(name)
    @flags.key?(name)
  end

  def overridden?(name)
    @overrides.key?(name)
  end

  def active?(name, *args)
    flag = @flags.fetch(name, proc { |*_args| false })
    validate_flag_arguments(name, flag.arity, args.size)
    flag.call(*args)
  end
  alias enabled? active?

  def inactive?(name, *args)
    !active?(name, *args)
  end
  alias disabled? inactive?

  def env?(*args)
    [*args].map(&:to_s).include?(env.to_s)
  end

  private

  def validate_flag_arity(flag_name, flag_arity, override_arity)
    original_arity = flag_arity < 0 ? flag_arity.abs - 1 : flag_arity

    if original_arity != override_arity
      raise FlagArgumentsMismatch, "Flag '#{flag_name}' expects #{flag_arity} arguments, " \
            "but #{override_arity} arguments were given"
    end
  end

  def validate_flag_arguments(flag_name, flag_arity, args_size)
    if flag_arity < 0 && (flag_arity.abs - 1) > args_size
      # Contains variable -n-1 arguments
      raise FlagArgumentsMismatch, "Flag '#{flag_name}' expects #{flag_arity.abs - 1} or more arguments, " \
            "but #{args_size} arguments were given"
    elsif flag_arity >= 0 && flag_arity != args_size
      # Contains zero or fixed number of arguments
      raise FlagArgumentsMismatch, "Flag '#{flag_name}' expects #{flag_arity} arguments, " \
            "but #{args_size} arguments were given"
    end
  end
end
