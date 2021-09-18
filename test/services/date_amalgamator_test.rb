require 'test_helper'

class DateAmalgamatorTest < ActiveSupport::TestCase

  setup do
    @dates = [
      Time.zone.parse("2021-01-03 12:23"),
      Time.zone.parse("2021-01-04 12:23"),
      Time.zone.parse("2021-01-05 12:23"),
      Time.zone.parse("2021-01-06 12:23"),
      Time.zone.parse("2021-01-07 12:23"),
      Time.zone.parse("2021-01-08 12:23"),
      Time.zone.parse("2021-01-09 12:23"),
      Time.zone.parse("2021-01-11 12:23"),
      Time.zone.parse("2021-01-12 12:23"),
      Time.zone.parse("2021-01-13 12:23"),
      Time.zone.parse("2021-02-03 12:23"),
      Time.zone.parse("2021-02-04 12:23"),
      Time.zone.parse("2021-02-05 12:23"),
      Time.zone.parse("2021-03-03 12:23"),
      Time.zone.parse("2021-03-04 12:23"),
      Time.zone.parse("2021-03-05 12:23"),
      Time.zone.parse("2021-03-12 12:23"),
      Time.zone.parse("2021-03-19 12:23"),
      Time.zone.parse("2021-03-26 12:23"),
      Time.zone.parse("2021-03-27 12:23"),
      Time.zone.parse("2021-03-28 12:23"),
      Time.zone.parse("2021-03-29 12:23")
    ]
    @da = DateAmalgamator.new(@dates)
  end

  test "can format as text" do
#    puts DateAmalgamator.format(@dates, wrap_width: 40, prefix: "XX XX ")
    expected = 
      "XX XX Jan: Sun 3rd, Mon 4th, Tue 5th, Wed 6th\n" +
      "XX XX      Thu 7th, Fri 8th, Sat 9th, Mon 11th\n" +
      "XX XX      Tue 12th, Wed 13th\n" +
      "XX XX Feb: Wed 3rd, Thu 4th, Fri 5th\n" +
      "XX XX Mar: Wed 3rd, Thu 4th, Fri 5th, 12th\n" +
      "XX XX      Fri 19th, 26th, Sat 27th, Sun 28th\n" +
      "XX XX      Mon 29th"
    assert_equal expected,
      DateAmalgamator.format(@dates, wrap_width: 40, prefix: "XX XX ")
    assert_equal expected,
      @da.as_text(wrap_width: 40, prefix: "XX XX ")
#    puts DateAmalgamator.format(@dates, wrap_width: 72)
    expected =
      "Jan: Sun 3rd, Mon 4th, Tue 5th, Wed 6th, Thu 7th, Fri 8th, Sat 9th\n" +
      "     Mon 11th, Tue 12th, Wed 13th\n" +
      "Feb: Wed 3rd, Thu 4th, Fri 5th\n" +
      "Mar: Wed 3rd, Thu 4th, Fri 5th, 12th, 19th, 26th, Sat 27th, Sun 28th\n" +
      "     Mon 29th"
    assert_equal expected, DateAmalgamator.format(@dates, wrap_width: 72)
    assert_equal expected, @da.as_text(wrap_width: 72)
  end

  test "can format as html" do
    #puts DateAmalgamator.format(@dates, html: true)
    expected =
      "<div class='da-month'>\n" +
      "<div class='da-month-name'>Jan</div>\n" +
      "<div class='da-month-dates'>Sun 3rd, Mon 4th, Tue 5th, Wed 6th, Thu 7th, Fri 8th, Sat 9th, Mon 11th, Tue 12th, Wed 13th</div>\n" +
      "</div>\n" +
      "<div class='da-month'>\n" +
      "<div class='da-month-name'>Feb</div>\n" +
      "<div class='da-month-dates'>Wed 3rd, Thu 4th, Fri 5th</div>\n" +
      "</div>\n" +
      "<div class='da-month'>\n" +
      "<div class='da-month-name'>Mar</div>\n" +
      "<div class='da-month-dates'>Wed 3rd, Thu 4th, Fri 5th, 12th, 19th, 26th, Sat 27th, Sun 28th, Mon 29th</div>\n" +
      "</div>"
    assert_equal expected, DateAmalgamator.format(@dates, html: true)
    assert_equal expected, @da.as_html

  end

end
