class ISAMS_ScheduleEntry

  SUBJECT_CODES = {
    "Bi" => "Biology",
    "En" => "English",
    "Fr" => "French",
    "Gg" => "Geography",
    "Hi" => "History",
    "La" => "Latin",
    "Ma" => "Mathematics",
    "Mu" => "Music",
    "RS" => "Religious Studies",
    "Sc" => "Science"
  }

  def find_subject(loader)
    splut = self.code.split
    if splut.size == 2
      if /^[12]/ =~ splut[0]
        subject_name = SUBJECT_CODES[splut[1]]
        if subject_name
          @subject = loader.subjects_by_name_hash[subject_name]
          unless @subject
            puts "Failed to find subject #{subject_name}."
          end
#        else
#          puts "Failed to find subject name from #{splut[1]}."
        end
      end
    end
  end

  def subject
    @subject
  end
end
