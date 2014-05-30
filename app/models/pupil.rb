class Pupil < ActiveRecord::Base

  validates :name, presence: true

  include Elemental

  self.per_page = 15

  def active
    true
  end

  def element_name
    #
    #  A constructed name to pass to our element record.
    #
    "#{self.name} (Pupil)"
  end

end
