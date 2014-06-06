class Locationalias < ActiveRecord::Base

  validates :name, presence: true
  belongs_to :location

  attr_accessor :short_name

  after_create :create_corresponding_location

  def after_initialize
    @short_name = nil
  end

  def create_corresponding_location
    #
    #  If we are a brand new location alias then we'd quite like
    #  a corresponding location.
    #
    location = Location.new
    location.short_name = self.short_name
    location.name       = self.name
    location.active     = true
    begin
      location.save!
      self.location = location
      self.save
    rescue
      location.errors.full_messages.each do |msg|
        errors[:base] << "Location: #{msg}"
      end
      raise $!
    end
  end

end
