#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  An engine to find properties as needed, cacheing the work which
#  it's done so far.
#
#  This one is slightly different, in that we will create any missing
#  ones which we need.
#
#  As with the others, what we return is always an Element.
#
class PropertyEngine

  def initialize(suffix = " fixture")
    @suffix = suffix
    @known_properties = Hash.new
  end

  def find(sport)
    if sport.blank?
      return nil
    else
      property_name = "#{sport}#{@suffix}"
      existing = @known_properties[property_name]
      if existing
        return existing
      else
        #
        #  Let's see if we can find it.
        #
        property = Property.find_by(name: property_name)
        unless property && property.element
          #
          #  Create it.
          #
          property = Property.create({name: property_name})
        end
        element = property.element
        @known_properties[property_name] = element
        return element
      end
    end
  end

end

