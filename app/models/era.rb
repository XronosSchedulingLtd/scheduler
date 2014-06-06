class Era < ActiveRecord::Base

  has_many :teachinggroups, dependent: :destroy
  has_many :tutorgroups, dependent: :destroy

end
