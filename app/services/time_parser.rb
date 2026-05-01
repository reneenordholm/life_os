class TimeParser
  def self.parse(question)
    lowered = question.downcase
    today = Date.today

    # explicit date parsing (e.g. "April 23")
    if lowered.match(/\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}\b/)
      parsed_date = Date.parse(Regexp.last_match(0)) rescue nil

      if parsed_date
        # assume current year if not specified
        parsed_date = parsed_date.change(year: Date.today.year)

        return { type: :date, value: parsed_date }
      end
    end

    # last Sunday, last Monday, etc.
    if lowered.match(/\blast\s+(sunday|monday|tuesday|wednesday|thursday|friday|saturday)\b(?:[[:punct:]]|$)/)
      weekday = Regexp.last_match(1).capitalize
      target = previous_weekday(today, weekday)
      return { type: :date, value: target }
    end

    # this week
    if lowered.include?("this week")
      start_of_week = today.beginning_of_week(:sunday)
      end_of_week = today.end_of_week(:sunday)
      return { type: :range, value: start_of_week..end_of_week }
    end

    # last week
    if lowered.include?("last week")
      last_week = today - 7
      start_of_week = last_week.beginning_of_week(:sunday)
      end_of_week = last_week.end_of_week(:sunday)
      return { type: :range, value: start_of_week..end_of_week }
    end

    nil
  end

  def self.previous_weekday(date, weekday_name)
    target_wday = Date::DAYNAMES.index(weekday_name)
    raise ArgumentError, "Unknown weekday name: #{weekday_name.inspect}" if target_wday.nil?

    days_ago = (date.wday - target_wday) % 7
    days_ago = 7 if days_ago.zero?
    date - days_ago
  end

  private_class_method :previous_weekday
end
