require "test_helper"

class TimeParserTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  test "parses written dates with full month names" do
    travel_to Date.new(2026, 5, 1) do
      result = TimeParser.parse("What did I do April 23?")

      assert_equal :date, result[:type]
      assert_equal Date.new(2026, 4, 23), result[:value]
    end
  end

  test "parses written dates with ordinal suffixes" do
    travel_to Date.new(2026, 5, 1) do
      result = TimeParser.parse("What did I do April 23rd?")

      assert_equal :date, result[:type]
      assert_equal Date.new(2026, 4, 23), result[:value]
    end
  end

  test "parses abbreviated written dates" do
    travel_to Date.new(2026, 5, 1) do
      result = TimeParser.parse("What did I do Apr 23?")

      assert_equal :date, result[:type]
      assert_equal Date.new(2026, 4, 23), result[:value]
    end
  end

  test "parses numeric month day without year" do
    travel_to Date.new(2026, 5, 1) do
      result = TimeParser.parse("What did I do 4/23?")

      assert_equal :date, result[:type]
      assert_equal Date.new(2026, 4, 23), result[:value]
    end
  end

  test "parses numeric month day with four digit year" do
    travel_to Date.new(2026, 5, 1) do
      result = TimeParser.parse("What did I do 4/23/2026?")

      assert_equal :date, result[:type]
      assert_equal Date.new(2026, 4, 23), result[:value]
    end
  end

  test "parses numeric month day with two digit year" do
    travel_to Date.new(2026, 5, 1) do
      result = TimeParser.parse("What did I do 4/23/26?")

      assert_equal :date, result[:type]
      assert_equal Date.new(2026, 4, 23), result[:value]
    end
  end

  test "snaps written future date to previous year" do
    travel_to Date.new(2026, 3, 1) do
      result = TimeParser.parse("What did I do December 31?")

      assert_equal :date, result[:type]
      assert_equal Date.new(2025, 12, 31), result[:value]
    end
  end

  test "returns nil for invalid numeric date" do
    result = TimeParser.parse("What did I do 2/30?")

    assert_nil result
  end

  test "returns nil for impossible written dates" do
    travel_to Date.new(2026, 5, 1) do
      assert_nil TimeParser.parse("What did I do February 30?")
      assert_nil TimeParser.parse("What did I do June 31?")
    end
  end

  test "returns nil for non-date written inputs" do
    travel_to Date.new(2026, 5, 1) do
      assert_nil TimeParser.parse("What did I do April foo?")
    end
  end

  test "handles leap year correctly for written dates" do
    travel_to Date.new(2024, 3, 1) do
      result = TimeParser.parse("What did I do February 29?")

      assert_equal :date, result[:type]
      assert_equal Date.new(2024, 2, 29), result[:value]
    end
  end

  test "rejects February 29 on non-leap year" do
    travel_to Date.new(2025, 3, 1) do
      assert_nil TimeParser.parse("What did I do February 29?")
    end
  end
end
