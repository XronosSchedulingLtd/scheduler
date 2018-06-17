#
#  School-specific utility methods.
#
module MIS_Utils
  def local_yeargroup(nc_year)
    nc_year
  end

  def local_yeargroup_text(yeargroup)
    case yeargroup
    when -2
      "Nursery 1"
    when -1
      "Nursery 2"
    when 0
      "Reception"
    else
      "Year #{yeargroup}"
    end
  end

  def local_yeargroup_text_pupils(yeargroup)
    "#{local_yeargroup_text(yeargroup)} pupils"
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

  def local_format_house_name(house)
    "#{house.name} House"
  end

  def local_stratify_house?(house)
    house.name != "Nursery 1" &&
      house.name != "Nursery 2" &&
      house.name != "Reception"
  end
  #
  #  Given the form code and form description from Pass, try to produce
  #  something reasonable.
  #
  def local_form_name(sample_pupil)
    splut = sample_pupil.form_description.split(' ')
    if splut[0] == "Form"
      "#{splut[1]}/#{sample_pupil.tutor_code}"
    else
      "#{splut[0,2].join(' ')}"
     end
  end

  def translate_year_group(pass_year)
    case pass_year
    when "00N1"
      @nc_year = -2
    when "00N2"
      @nc_year = -1
    when "00R"
      @nc_year = 0
    else
      @nc_year = pass_year.to_i
    end
  end

end
