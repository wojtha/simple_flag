# frozen_string_literal: true

require 'simple_flag/version'
require 'simple_flag/overrides'

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
  include Overrides
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

  def flag?(name)
    @flags.key?(name)
  end

  def active?(name, *args)
    flag = @flags.fetch(name, proc { |*_args| false })
    validate_flag_arguments(name, flag.arity, args.size)
    flag.call(*args)
  end
  alias enabled? active?
  alias on? active?

  def inactive?(name, *args)
    !active?(name, *args)
  end
  alias disabled? inactive?
  alias off? inactive?

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
