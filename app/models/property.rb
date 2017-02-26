# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2015 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Property < ActiveRecord::Base

  scope :public_ones, -> { where(make_public: true) }
  validates :name, presence: true
  validates :name, uniqueness: true

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

  def owners_initials
    self.element.owners.collect {|o| o.initials}.join(", ")
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

  #
  #  Deleting a property with dependent stuff could be disastrous.
  #  Major loss of information.  Allow deletion only if we have no
  #  commitments.
  #
  def can_destroy?
    self.element.commitments.count == 0
  end

end
