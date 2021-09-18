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
  #  Wed 22nd, 29th Sep, 6th, 13th Oct, 3rd, 17th, 24th Nov...
  #
  #  with intelligent line wrapping.
  #
  #  or perhaps like this?:
  #
  #  Sep: Wed 22nd, 29th
  #  Oct: Wed 6th, 13th
  #  Nov: Wed 3rd, 17th, 24th
  #
  #

  def self.build_html(result, prefix, name, dates)
    result << "<div class='#{prefix}month'>"
    result << "<div class='#{prefix}month-name'>#{name}</div>"
    current_wday = -1
    date_texts = []
    dates.each do |date|
      if date.wday == current_wday
        date_texts << "#{date.day.ordinalize}"
      else
        date_texts << date.strftime("%a #{date.day.ordinalize}")
        current_wday = date.wday
      end
    end
    result << "<div class='#{prefix}month-dates'>#{date_texts.join(", ")}</div>"
    result << "</div>"
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
    current_month = 0
    current_wday = -1

    if html
      #
      #  HTML, suitable for displaying using flex-box CSS - or indeed
      #  any other kind of display at the choice of the caller.  One
      #  div per month, each containing two divs - one with the month name
      #  and the other with the contents.  Formatting them is up to the caller.
      #
      result = []
      month_name = ""
      month_dates = []
      date_array.sort.each do |date|
        if date.month != current_month
          if current_month != 0
            #
            #  Flush what we have and move on.
            #
            build_html(result, html_element_prefix, month_name, month_dates)
          end
          current_month = date.month
          month_name = date.strftime("%b")
          month_dates = []
        end
        month_dates << date
      end
      if current_month != 0
        build_html(result, html_element_prefix, month_name, month_dates)
      end

      return result.join("\n")
    else
      #
      #  Pure text.
      #
      lines = []
      current_lines = []
      current_line = ""
      date_array.sort.each do |date|
        if date.month != current_month
          #
          #  Moving into a fresh (or the first) month.
          #
          unless current_line.blank?
            current_lines << current_line
          end
          unless current_lines.empty?
            lines << current_lines
            current_lines = []
          end
          current_month = date.month
          current_line = ""
          current_wday = -1
        end
        if date.wday == current_wday
          wday_text = ""
        else
          wday_text = date.strftime("%a ")
          current_wday = date.wday
        end
        chunk = "#{wday_text}#{date.day.ordinalize}"
        #
        if current_line.blank?
          #
          #  The only time the current line is blank is when we
          #  are starting a new month.
          #
          current_line = date.strftime("%b: ") + chunk
        else
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
      unless current_lines.empty?
        lines << current_lines
      end

      return prefix + lines.join("\n#{prefix}")
    end
  end
end
