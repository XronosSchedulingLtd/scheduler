# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Locationalias < ActiveRecord::Base

  validates :name, presence: true
  belongs_to :location
  belongs_to :datasource

  after_create :create_corresponding_location

  self.per_page = 15

  #
  #  Sorting location aliases is interesting.  I really want aliases
  #  for the same location to appear together, and I want those without
  #  locations in a lump.  Within aliases for the same location, I want
  #  the friendly one(s) last, and otherwise in alphabetical order.
  #
  #  Note comparison of ids where possible to avoid unnecessary d/b
  #  hits.
  #
  def <=>(other)
    if self.location_id == other.location_id
      #
      #  Two aliases for the same location. (Or two orphaned aliases.)
      #
      if self.friendly == other.friendly
        #
        #  Both of the same friendliness.
        #
        self.name <=> other.name
      else
        #
        #  Friendly one goes last.
        #
        if self.friendly
          1
        else
          -1
        end
      end
    else
      if self.location_id && other.location_id
        self.location <=> other.location
      elsif self.location_id
        -1
      else
        1
      end
    end
  end

  def create_corresponding_location
    #
    #  If we are a brand new location alias then we'd quite like
    #  a corresponding location.  We may have been linked to an existing
    #  location as part of the creation process.
    #
    if self.location
      self.location.update_element
    else
      location = Location.new
      location.name       = self.name
      location.active     = true
      location.current    = true
      begin
        #
        #  Slight repetitiveness here.  We have to save the location
        #  record before we can link to it, but then we need to save it
        #  again to make sure its element name is correctly updated.
        #
        location.save!
        self.location = location
        self.save
        location.reload
        location.update_element
      rescue
        location.errors.full_messages.each do |msg|
          errors[:base] << "Location: #{msg}"
        end
        raise $!
      end
    end
  end

end
