# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class DayShapeManager < TemplateManager

  KEY = "Day shape"

  def self.template_type
    self.template_type_for(KEY)
  end

  def self.flush_cache
    self.flush_cache_for(KEY)
  end

  def self.setup_users(day_shape = nil)
    day_shape ||= template_type.rota_templates.first
    if day_shape
      User.find_each do |user|
        if user.known?
          unless user.day_shape
            user.day_shape = day_shape
            user.save!
          end
        end
      end
    else
      puts "No day shape to use."
    end
    nil
  end
end
