class MIS_Subject
  attr_reader :name, :teachers, :year_teachers, :groups, :year_groups

  @@subjects = Array.new
  @@teachers_by_year = Hash.new
  @@all_teachers = Array.new

  #
  #  It's up to the MIS-specific bit to provide the necessary
  #  initialize() method.  We don't know even what parameters it
  #  will need.  However, the MIS-specific code should then make
  #  provision for calling this method too, if it is defined.
  #
  def initialize_generic_bit
    @teachers = Array.new
    @year_teachers = Hash.new
    @groups = Array.new
    @year_groups = Hash.new
    @@subjects << self
  end

  def note_lesson(staff, group)
    if staff.instance_of?(Array)
      staffa = staff
    else
      staffa = [staff]
    end
    staffa.each do |s|
      unless @teachers.include?(s)
#        puts "Adding #{s.name} to #{self.name} teachers."
        @teachers << s
      end
      unless @@all_teachers.include?(s)
        @@all_teachers << s
      end
    end
    unless @groups.include?(group)
#     puts "Adding group #{group.name} to those studying #{self.name}."
      @groups << group
    end
    yeargroup = group.yeargroup
    if yeargroup != 0
      year_record = @year_teachers[yeargroup] ||= Array.new
      staffa.each do |s|
        unless year_record.include?(s)
#         puts "Adding #{s.name} to #{yeargroup.ordinalize} year #{self.name} teachers."
          year_record << s
        end
      end
      year_record = @@teachers_by_year[yeargroup] ||= Array.new
      staffa.each do |s|
        unless year_record.include?(s)
#         puts "Adding #{s.name} to #{yeargroup.ordinalize} year teachers."
          year_record << s
        end
      end
      year_group_record = @year_groups[yeargroup] ||= Array.new
      unless year_group_record.include?(group)
#       puts "Adding group #{group.name} to #{yeargroup.ordinalize} year #{self.name} groups."
        year_group_record << group
      end
    end
  end

  def self.teachers_by_year
    @@teachers_by_year.each do |yeargroup, teachers|
      yield yeargroup, teachers
    end
  end

  def self.all_teachers
    @@all_teachers
  end
end
