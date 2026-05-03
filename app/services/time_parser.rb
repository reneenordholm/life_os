class TimeParser
  MONTHS = {
    "jan" => 1, "january" => 1,
    "feb" => 2, "february" => 2,
    "mar" => 3, "march" => 3,
    "apr" => 4, "april" => 4,
    "may" => 5,
    "jun" => 6, "june" => 6,
    "jul" => 7, "july" => 7,
    "aug" => 8, "august" => 8,
    "sep" => 9, "sept" => 9, "september" => 9,
    "oct" => 10, "october" => 10,
    "nov" => 11, "november" => 11,
    "dec" => 12, "december" => 12
  }.freeze

  WRITTEN_DATE_REGEX = /
    \b
    (jan(?:uary)?|
    feb(?:ruary)?|
    mar(?:ch)?|
    apr(?:il)?|
    may|
    jun(?:e)?|
    jul(?:y)?|
    aug(?:ust)?|
    sep(?:tember)?|
    sept|
    oct(?:ober)?|
    nov(?:ember)?|
    dec(?:ember)?)
    \s+
    (\d{1,2})
    (?:st|nd|rd|th)?
    \b
  /ix

  def self.parse(question)
    lowered = question.downcase
    today = Date.today

    # explicit written date parsing:
    # "April 23", "April 23rd", "Apr 23", "Apr 23rd"
    if lowered.match(WRITTEN_DATE_REGEX)
      month = MONTHS[Regexp.last_match(1).downcase]
      day = Regexp.last_match(2).to_i

      parsed_date = begin
        Date.new(today.year, month, day)
      rescue Date::Error
        nil
      end

      if parsed_date
        parsed_date = parsed_date.prev_year if parsed_date > today
        return { type: :date, value: parsed_date }
      end
    end

    # explicit numeric date parsing:
    # "4/23", "04/23", "4/23/2026", "4/23/26"
    if lowered.match(/\b\d{1,2}\/\d{1,2}(?:\/\d{2,4})?\b/)
      date_text = Regexp.last_match(0)

      date_parts = date_text.split("/")
      implicit_year = date_parts.length == 2

      parsed_date = begin
        if implicit_year
          Date.strptime("#{date_text}/#{today.year}", "%m/%d/%Y")
        elsif date_parts.last.length == 2
          Date.strptime(date_text, "%m/%d/%y")
        else
          Date.strptime(date_text, "%m/%d/%Y")
        end
      rescue Date::Error
        nil
      end

      if parsed_date
        parsed_date = parsed_date.prev_year if implicit_year && parsed_date > today
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
