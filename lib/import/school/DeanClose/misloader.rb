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
    tges_by_year = {}
    @houses.each do |house|
      tutors = []
      pupils = []
      house_tges_by_year = {}
      house.tugs.each do |tug|
        tutors << tug.staff.dbrecord
        all_tutors << tug.staff.dbrecord
        tutors_by_year[tug.yeargroup] ||= []
        tutors_by_year[tug.yeargroup] << tug.staff.dbrecord
        #
        #  And now, each of the pupils.
        #
        tug.pupils.each do |pupil|
          tges_by_year[tug.yeargroup] ||= []
          tges_by_year[tug.yeargroup] << pupil.dbrecord
          house_tges_by_year[tug.yeargroup] ||= []
          house_tges_by_year[tug.yeargroup] << pupil.dbrecord
          pupils << pupil.dbrecord
        end
      end
      ensure_membership("#{house.name} House pupils",
                        pupils,
                        Pupil)
      house_tges_by_year.each do |year_group, pupils|
        ensure_membership("#{house.name} House #{local_yeargroup_text(year_group)}",
                          pupils,
                          Pupil)
      end
    end
    tges_by_year.each do |year_group, pupils|
      ensure_membership("#{local_yeargroup_text(year_group)}",
                        pupils,
                        Pupil)
    end
  end

end
