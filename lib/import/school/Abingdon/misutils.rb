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

  def local_effective_start_year(era, nc_year, ahead = 0)
    era.starts_on.year + 7 - (nc_year + ahead)
  end

  def local_wanted(nc_year)
    nc_year < 20
  end

  def local_week_wanted(week)
    week.name != "Prep Week"
  end

end
