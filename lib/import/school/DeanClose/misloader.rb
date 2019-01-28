class MIS_Loader

  #
  #  This method is called by do_auto_groups if it exists.
  #
  def do_local_auto_groups
    #
    #  Staff by house they are tutors in.
    #
    all_tutors = []
    tutors_by_year = {}
    @houses.each do |house|
      tutors = []
      house.tugs.each do |tug|
        tutors << tug.staff.dbrecord
        all_tutors << tug.staff.dbrecord
        tutors_by_year[tug.yeargroup] ||= []
        tutors_by_year[tug.yeargroup] << tug.staff.dbrecord
      end
    end
  end

end
