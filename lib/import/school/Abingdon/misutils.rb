#
#  School-specific utility methods.
#
module MIS_Utils
  def local_yeargroup(nc_year)
    if nc_year == 15
      5
    elsif nc_year == 16
      6
    elsif nc_year == 17
      7
    else
      nc_year - 6
    end
  end

  def local_yeargroup_text(yeargroup)
    "#{yeargroup.ordinalize} year"
  end

  alias local_yeargroup_text_pupils local_yeargroup_text

  def local_effective_start_year(era, nc_year, ahead = 0)
    era.starts_on.year + 1 - (local_yeargroup(nc_year) + ahead)
  end

  def local_wanted(nc_year)
    #
    #  This test really should be just "< 20" in order to exclude the
    #  prep school but various frigs have occurred.
    #
    #  15, 16, and 17 have been used for odd pupils in 5th, L6th and U6th
    #  respectively.  See local_yeargroup() above.
    #
    nc_year < 18
  end

  #
  #  We don't want the prep school week, the one which doesn't
  #  appear in the schedule, to break through.
  #
  def local_week_load_regardless(week)
    false
  end

  def local_format_house_name(house)
    if house.name == "Lower School"
      house.name
    else
      "#{house.name} House"
    end
  end

  def local_stratify_house?(house)
    house.name != "Lower School"
  end
end
