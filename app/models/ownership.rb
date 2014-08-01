class Ownership < ActiveRecord::Base
  belongs_to :user
  belongs_to :element

  scope :me, -> {where(equality: true)}
  scope :notme, -> {where(equality: false)}

  def self.set_equality
    Ownership.all.each do |o|
      unless o.equality
        o.equality = true
        o.save!
      end
    end
  end
end
