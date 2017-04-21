#
#  School-specific utility methods.
#
module MIS_Utils
  def local_yeargroup(nc_year)
    #
    #  For some odd reason, pupils in NC year -3 are recorded in the
    #  iSAMS database at Dean Close with an NC year of 14.
    #
    if nc_year == 14
      -3
    else
      nc_year
    end
  end

  def local_yeargroup_text(yeargroup)
    "Year #{yeargroup}"
  end

  def local_effective_start_year(era, nc_year, ahead = 0)
    era.starts_on.year + 1 - (nc_year + ahead)
  end

  def local_wanted(nc_year)
    true
  end

  def local_week_load_regardless(week)
    true
  end

end
