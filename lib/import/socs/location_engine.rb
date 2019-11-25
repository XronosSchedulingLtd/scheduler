#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  An engine to find locations as needed, cacheing the work which
#  it's done so far.
#
#  Note that what we return is always an Element - for ease of unique
#  identification and attaching to events.
#
class LocationEngine

  def initialize
    @known_locations = Hash.new
  end

  def find(name)
    #
    #  Data item in array may be nil.
    #
    if @known_locations.key?(name)
      return @known_locations[name]
    else
      #
      #  Let's see if we can find it.
      #
      location = Location.find_by(name: name)
      unless location
        location_alias = Locationalias.find_by(name: name)
        if location_alias
          location = location_alias.location
        end
      end
      if location
        element = location.element
      else
        element = nil
      end
      @known_locations[name] = element
      return element
    end
  end

  #
  #  List all the locations which we were asked to find and couldn't.
  #
  def list_missing
    any_missing = false
    @known_locations.each do |key, element|
      unless element
        puts "Missing locations:" unless any_missing
        puts "  #{key}"
        any_missing = true
      end
    end
    puts "No locations missing" unless any_missing
  end
end

