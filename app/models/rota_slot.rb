require 'tod'

class RotaSlot < ActiveRecord::Base
  serialize :starts_at, Tod::TimeOfDay
  serialize :ends_at, Tod::TimeOfDay
  serialize :days, Array

  belongs_to :rota_template
end
