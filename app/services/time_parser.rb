class TimeParser
  def self.parse(question)
    lowered = question.downcase
    today = Date.today

    # explicit written date parsing:
    # "April 23", "April 23rd", "Apr 23", "Apr 23rd"
    if lowered.match(/\b(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|sept|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s+\d{1,2}(?:st|nd|rd|th)?\b/)
      date_text = Regexp.last_match(0).gsub(/(st|nd|rd|th)\b/, "")

      parsed_date = begin
        Date.parse(date_text)
      rescue Date::Error
        nil
      end

      if parsed_date
        parsed_date = parsed_date.change(year: today.year)
        parsed_date = parsed_date.prev_year if parsed_date > today
        return { type: :date, value: parsed_date }
      end
    end

    # explicit numeric date parsing:
    # "4/23", "04/23", "4/23/2026", "4/23/26"
    if lowered.match(/\b\d{1,2}\/\d{1,2}(?:\/\d{2,4})?\b/)
      date_text = Regexp.last_match(0)

      parsed_date = begin
        parts = date_text.split("/")

        if parts.length == 2
          Date.strptime("#{date_text}/#{today.year}", "%m/%d/%Y")
        elsif parts.last.length == 2
          Date.strptime(date_text, "%m/%d/%y")
        else
          Date.strptime(date_text, "%m/%d/%Y")
        end
      rescue Date::Error
        nil
      end
    end

    if parsed_date
      parsed_date = parsed_date.prev_year if parsed_date > today
      return { type: :date, value: parsed_date }
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
