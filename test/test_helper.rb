ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    include ActiveSupport::Testing::TimeHelpers

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.

    # ❌ disable fixtures
    # fixtures :all

    setup do
      @original_embed = EmbeddingService.method(:embed)

      EmbeddingService.define_singleton_method(:embed) do |_text|
        Array.new(1536, 0.0)
      end
    end

    teardown do
      # restore original embed method
      EmbeddingService.define_singleton_method(:embed, @original_embed)

      travel_back
    end
  end
end
