# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2015 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Property < ActiveRecord::Base

  validates :name, presence: true

  include Elemental

  def active
    true
  end

  def current
    true
  end

  def element_name
    name
  end

  def preferred_colour
    @preferred_colour
  end

  def preferred_colour=(colour)
    @preferred_colour = colour
  end

  def adjust_element_creation_hash(creation_hash)
    if @preferred_colour
      creation_hash[:preferred_colour] = @preferred_colour
    end
  end

  #
  #  Ensure a property of the given name exists in the database.
  #  Return it.
  #
  def self.ensure(property_name, preferred_colour = nil)
    p = Property.find_by(name: property_name)
    unless p
      p = Property.new(name: property_name,
                       preferred_colour: preferred_colour)
      p.save!
      p.reload
    end
    p
  end

end
