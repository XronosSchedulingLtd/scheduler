class Date
  def loony_isams_cweek
    #
    #  I've discovered by experimentation that iSAMS does not use
    #  standard week numbers - instead it uses ones of its own
    #  invention.
    #
    #  It appears they take a week as running from Sunday to Saturday
    #  and week 1 as being the first week or part of week in the year.
    #
    #  It is thus not possible to use standard date manipulation
    #  libraries when handling their week numbers.  This file
    #  attempts to produce an equivalent to the standard cweek()
    #  method that instead provides iSAMS week numbers.
    #
    #  Take today's day number in the year.
    #  Subtract the weekday number, getting back to Sunday.
    #  Add 6 to get to the following Saturday.
    #
    #  If the resulting value is: 1,2,3,4,5,6,7 then we are in week 1.
    #  (Actually, we wouldn't get some of those low values because we'd
    #  be in the previous calendar year, but this is the principle.)
    #
    #  So we add a further 6, 12 in all and then do integer division by
    #  7 to get the week number.
    #
    #  Sun 1st Jan   (1 - 0 + 12) / 7 = 13 / 7 = 1
    #  Mon 2nd Jan   (2 - 1 + 12) / 7 = 13 / 7 = 1
    #  Sat 7th Jan   (7 - 6 + 12) / 7 = 13 / 7 = 1
    #  Sun 8th Jan   (8 - 0 + 12) / 7 = 20 / 7 = 2
    #
    #  Sat 1st Jan   (1 - 6 + 12) / 7 = 7 / 7 = 1
    #  Sun 2nd Jan   (2 - 0 + 12) / 7 = 14 / 7 = 2
    #  Sat 8th Jan   (8 - 6 + 12) / 7 = 14 / 7 = 2
    #  Sun 9th Jan   (9 - 0 + 12) / 7 = 21 / 7 = 3
    #
    #  Sat 5th Jan   (5 - 6 + 12) / 7 = 11 / 7 = 1
    #  Sun 6th Jan   (6 - 0 + 12) / 7 = 18 / 7 = 2
    #  Sat 12th Jan  (12 - 6 + 12) / 7 = 18 / 7 = 2
    #  Sun 13th Jan  (13 - 0 + 12) / 7 = 25 / 7 = 3
    #
    #  Sat 6th Jan   (6 - 6 + 12) / 7 = 12 / 7 = 1
    #  Sun 7th Jan   (7 - 0 + 12) / 7 = 19 / 7 = 2
    #  Sat 13th Jan  (13 - 6 + 12) / 7 = 19 / 7 = 2
    #  Sun 14th Jan  (14 - 0 + 12) / 7 = 26 / 7 = 3
    #
    (self.yday - self.wday + 12) / 7
  end
end
