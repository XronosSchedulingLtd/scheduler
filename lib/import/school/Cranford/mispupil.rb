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
      prefix = set_code[/^\d+/]
      if prefix
        result = prefix.to_i
      elsif set_code == "NA1"
        result = -1
      else
        #
        #  We have no idea.
        #
#        puts "Set code \"#{set_code}\" gives no year."
        result = nil
      end
    end
#    puts "Guessed #{result}"
    result
  end
end
