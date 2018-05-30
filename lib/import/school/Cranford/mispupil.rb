class MIS_Pupil

  def translate_year_group(pass_year)
    if pass_year.blank?
      puts "Pupil #{@name} has no year group in Pass."
    end
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
