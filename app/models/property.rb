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

  #
  #  Ensure a property of the given name exists in the database.
  #  Return it.
  #
  def self.ensure(property_name)
    p = Property.find_by(name: property_name)
    unless p
      p = Property.new(name: property_name)
      p.save!
      p.reload
    end
    p
  end

end
