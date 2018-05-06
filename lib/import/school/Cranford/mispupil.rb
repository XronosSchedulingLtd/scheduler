class MIS_Pupil

  #
  #  Don't currently have a way of getting pupils with their NC years,
  #  so try to guess it.
  #
  def guess_nc_year(set_code)
#    puts "Guessing from #{set_code}"
    if set_code[0] == "R"
      #
      #  Reception
      #
      result = 0
    else
      result = set_code[/^\d+/].to_i
    end
#    puts "Guessed #{result}"
    result
  end
end
