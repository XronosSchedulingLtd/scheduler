#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class RotaTemplateType < ApplicationRecord

  has_many :rota_templates, :dependent => :destroy

  validates :name, :presence => true

  def <=>(other)
    self.name <=> other.name
  end

  #
  #  A maintenance method for use on existing systems to create
  #  the necessary.  Currently we do not provide any facility for
  #  even the sys admin to change them.
  #
  def self.create_basics
    ["Invigilation", "Day shape", "AdHocAvailability"].each do |name|
      rtt = RotaTemplateType.find_by(name: name)
      unless rtt
        RotaTemplateType.create!({ name: name })
      end
    end
    nil
  end
end
