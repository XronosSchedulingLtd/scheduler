class ExamCycle < ActiveRecord::Base

  include Generator

  belongs_to :default_rota_template, :class_name => "RotaTemplate"

  validates :name, :presence => true
  validates :starts_on, :presence => true

  def starts_on_text
    starts_on ? starts_on.strftime("%d/%m/%Y") : ""
  end

  def starts_on_text=(value)
    self.starts_on = value
  end

  def ends_on_text
    ends_on ? ends_on.strftime("%d/%m/%Y") : ""
  end

  def ends_on_text=(value)
    self.ends_on = value
  end

  def vague_start_date
    if starts_on
      starts_on.strftime("%b %Y")
    else
      ""
    end
  end

  def <=>(other)
    self.starts_on <=> other.starts_on
  end
end
