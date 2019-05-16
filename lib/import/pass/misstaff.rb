require 'yaml'

class MIS_Staff

  attr_reader :source_id,
              :datasource_id,
              :name,
              :forename,
              :surname,
              :title,
              :initials,
              :email,
              :formal_name

  def initialize(record)
    @source_id     = record.staff_id
    @datasource_id = @@primary_datasource_id
    @formal_name   = record.formal_name
    @surname       = record.surname
    @forename      = record.preferred_name
    @name          = "#{@forename} #{@surname}"
    @title         = record.title
    @initials      = record.initials
    @email         = record.email
    if record.leave_date.blank?
      @current = true
    else
      @current = record.leave_date > Date.today
    end
  end

  def active
    true
  end

  def current
    @current
  end

  def self.construct(loader, mis_data)
    all_staff = Array.new
    mis_data[:staff_by_id].values.each do |record|
      all_staff << MIS_Staff.new(record)
    end
    @staff_by_name = Hash.new
    all_staff.each do |individual|
      @staff_by_name[individual.formal_name] = individual
    end
    all_staff
  end

  def self.by_name(name)
    @staff_by_name[name]
  end

end
