class Staff < ActiveRecord::Base

  validates :name, presence: true

  include Elemental

  has_one :tutorgroup, dependent: :destroy

  self.per_page = 15

  scope :active, -> { where(active: true) }
  scope :current, -> { where(current: true) }

  def element_name
    #
    #  A constructed name to pass to our element record.
    #
    "#{self.name} (Staff)"
  end

  def self.set_currency
    Staff.active.each do |s|
      s.current = true
      s.save
    end
  end
end
