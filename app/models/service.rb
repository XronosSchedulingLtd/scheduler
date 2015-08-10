class Service < ActiveRecord::Base

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

end
