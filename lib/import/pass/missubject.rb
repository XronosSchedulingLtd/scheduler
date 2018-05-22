# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class MIS_Subject

  attr_reader :datasource_id

  def initialize(id, code, description)
    initialize_generic_bit
    @id   = id
    @code = code
    @description = description
    @datasource_id = @@primary_datasource_id
  end

  def source_id
    @id
  end

  def name
    @description
  end

  def current
    true
  end

  #
  #  Adjust name to avoid name clashes.
  #
  def bump_name
#    puts "Changing #{@description} to add (#{@code})"
    @description = "#{@description} (#{@code})"
  end

  def self.construct(loader, mis_data)
    subjects = Array.new
    subjects_by_code = Hash.new
    mis_data[:subjects].each do |subject|
      record = MIS_Subject.new(subject.id, subject.code, subject.description)
      subjects << record
      subjects_by_code[subject.code] = record
    end
    #
    #  Deal with any name clashes.
    #
    subjects.each do |subject|
      same_name = subjects.select {|s| s.name == subject.name}
      if same_name.size > 1
        same_name.each do |s|
          s.bump_name
        end
      end
    end
    #
    #  The teaching group code will need this later.
    #
    mis_data[:subjects_by_code] = subjects_by_code
    subjects
  end


end
