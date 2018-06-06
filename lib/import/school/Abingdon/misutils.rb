#
#  School-specific utility methods.
#
module MIS_Utils
  def local_yeargroup(nc_year)
    nc_year - 6
  end

  def local_yeargroup_text(yeargroup)
    "#{yeargroup.ordinalize} year"
  end

  alias local_yeargroup_text_pupils local_yeargroup_text

  def local_effective_start_year(era, nc_year, ahead = 0)
    era.starts_on.year + 7 - (nc_year + ahead)
  end

  def local_wanted(nc_year)
    nc_year < 20
  end

  #
  #  We don't want the prep school week, the one which doesn't
  #  appear in the schedule, to break through.
  #
  def local_week_load_regardless(week)
    false
  end

end
