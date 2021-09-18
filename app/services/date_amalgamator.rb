#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class DateAmalgamator
  #
  #  Code to take an array of dates and produce a concise listing of
  #  them all, in order.
  #
  #  Something like this:
  #
  #  Sep: Wed 22nd, 29th
  #  Oct: Wed 6th, 13th
  #  Nov: Wed 3rd, 17th, 24th
  #
  #

  class Month

    def initialize(date)
      #
      #  Create a new month record from a specific date.
      #
      @month = date.month
      @year  = date.year
      @name = date.strftime("%b")
      @dates = []
      @dates << date
    end

    def contains?(date)
      date.year == @year && date.month == @month
    end

    def <<(date)
      @dates << date
    end

    def as_html(prefix)
      result = []
      result << "<div class='#{prefix}month'>"
      result << "<div class='#{prefix}month-name'>#{@name}</div>"
      current_wday = -1
      date_texts = []
      @dates.each do |date|
        if date.wday == current_wday
          date_texts << "#{date.day.ordinalize}"
        else
          date_texts << date.strftime("%a #{date.day.ordinalize}")
          current_wday = date.wday
        end
      end
      result << "<div class='#{prefix}month-dates'>#{date_texts.join(", ")}</div>"
      result << "</div>"
      return result.join("\n")
    end

    def as_text(wrap_width, prefix)
      current_lines = []
      current_line = ""
      current_wday = -1
      @dates.each do |date|
        if date.wday == current_wday
          wday_text = ""
        else
          wday_text = date.strftime("%a ")
          current_wday = date.wday
        end
        chunk = "#{wday_text}#{date.day.ordinalize}"
        #
        #  Add 2 for the ", " which we would insert.
        #
        if current_line.length + chunk.length + 2 > wrap_width
          current_lines << current_line
          #
          #  One extra wrinkle.  If we're starting a new line then
          #  we may need to re-evaluate our chunk to include the
          #  day name.  Simpler just to do it than to check whether
          #  we need to do it.
          #
          chunk = date.strftime("%a #{date.day.ordinalize}")
          current_line = "     #{chunk}"
        else
          if current_line.blank?
            current_line = "#{@name}: #{chunk}"
          else
            current_line += ", #{chunk}"
          end
        end
      end
      #
      #  Anything left?
      #
      unless current_line.blank?
        current_lines << current_line
      end
      return prefix + current_lines.join("\n#{prefix}")
    end

  end

  def initialize(dates)
    @org_dates = dates
    #
    #  Let's organize them now.  Formatting will happen later.
    #
    current_month = -1
    @months = []
    dates.sort.each do |date|
      if @months.last&.contains?(date)
        @months.last << date
      else
        @months << Month.new(date)
      end
    end
  end

  def as_html(prefix: "da-")
    result = []
    @months.each do |month|
      result << month.as_html(prefix)
    end
    return result.join("\n")
  end

  def as_text(wrap_width: 78, prefix: "")
    result = []
    @months.each do |month|
      result << month.as_text(wrap_width, prefix)
    end
    return result.join("\n")
  end

  def self.format(
    date_array,                  #  Array of date/time compatible things
    wrap_width:          78,     #  In text mode, how long a line to allow
    prefix:              "",     #  In text mode, a preamble for each line
    html:                false,  #  Flag to switch to html mode
    html_element_prefix: "da-")
    #
    #  Parameter is an array of dates, or anything which will respond
    #  to date-like queries - e.g. TimeWithZone.  (And all of them in
    #  the array must be compatible for sorting.)
    #
    #  The length of the supplied prefix is not included in our
    #  length calculations.  If you're providing a long prefix,
    #  reduce the wrap_width to suit.
    #
    if html
      self.new(date_array).as_html(prefix: html_element_prefix)
    else
      self.new(date_array).as_text(wrap_width: wrap_width, prefix: prefix)
    end
  end

end
