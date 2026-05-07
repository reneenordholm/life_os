ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Stub embeddings once per worker
Rails.application.config.after_initialize do
  EmbeddingService.define_singleton_method(:embed) do |_text|
    Array.new(1536, 0.0)
  end
end
module ActiveSupport
  class TestCase
    include ActiveSupport::Testing::TimeHelpers

    # Run tests in parallel
    parallelize(workers: :number_of_processors)

    # no fixtures
    # fixtures :all

    teardown do
      travel_back
    end
  end
end
