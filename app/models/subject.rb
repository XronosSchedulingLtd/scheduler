class Subject < ActiveRecord::Base

  include Elemental

  has_many :teachinggrouppersonae, :dependent => :nullify

  has_and_belongs_to_many :staffs
  before_destroy { staffs.clear }

  scope :current, -> { where(current: true) }

  def teachinggroups
    self.teachinggrouppersonae.preload(:group).collect { |tgp| tgp.group }
  end

  def active
    true
  end

  def element_name
    self.name
  end

end
