class ExamCycle < ActiveRecord::Base

  belongs_to :default_rota_template, :class_name => "RotaTemplate"
end
