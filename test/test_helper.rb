ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module MethodStubHelper
  def with_stubbed_method(object, method_name, replacement)
    singleton = object.singleton_class
    original = :"__scope_drop_original_#{method_name}"
    singleton.alias_method(original, method_name)
    singleton.define_method(method_name) do |*args, **kwargs, &block|
      replacement.is_a?(Proc) ? replacement.call(*args, **kwargs, &block) : replacement
    end
    yield
  ensure
    singleton.alias_method(method_name, original)
    singleton.remove_method(original)
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include MethodStubHelper
  end
end
