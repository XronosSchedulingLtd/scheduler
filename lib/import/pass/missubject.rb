# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class MIS_Subject

  attr_reader :datasource_id

  def initialize(code, description)
    initialize_generic_bit
    @code = code
    @description = description
    @datasource_id = @@primary_datasource_id
  end

  def source_id
    @code.to_i(36)
  end

  def name
    @description
  end

  def current
    true
  end

  def self.construct(loader, mis_data)
    #
    #  We are going to go through Pass data which has already been
    #  loaded, identifying all our subjects and creating a record for
    #  each one.
    #
    code_hash = Hash.new
    mis_data[:set_records].each do |sr|
#      puts "Subject code #{sr.subject_code}, description #{sr.subject_description}"
      code_hash[sr.subject_code] ||= sr.subject_description
    end
    subjects = Array.new
    code_hash.each do |code, description|
#      puts "Subject code \"#{code}\", description \"#{description}\"."
      subjects << MIS_Subject.new(code, description)
    end
    subjects
  end


end
