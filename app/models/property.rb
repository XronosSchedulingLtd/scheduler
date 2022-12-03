#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Property < ApplicationRecord

  has_many :ad_hoc_domains,
           foreign_key: :connected_property_id,
           dependent: :nullify

  scope :public_ones, -> { where(make_public: true) }
  scope :for_staff, -> { where(auto_staff: true) }
  scope :for_pupils, -> { where(auto_pupils: true) }
  validates :name, presence: true
  validates :name, uniqueness: true

  include Elemental

  def active
    true
  end

  def element_name
    name
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

  #
  #  This has a slightly different name from the database field because
  #  it's provided by the elemental concern.  We override it because
  #  we do actually have a locking field, whilst most entities don't.
  #
  def can_lock?
    self.locking?
  end

end
