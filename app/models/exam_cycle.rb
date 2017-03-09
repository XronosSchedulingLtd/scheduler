class ExamCycle < ActiveRecord::Base

  include Generator

  belongs_to :default_rota_template, :class_name => "RotaTemplate"
  belongs_to :default_group_element, :class_name => "Element"

  validates :name, :presence => true
  validates :starts_on, :presence => true
  validates :default_rota_template, :presence => true
  validates :default_group_element, :presence => true

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

  def default_rota_template_name
    if default_rota_template
      default_rota_template.name
    else
      ""
    end
  end

  def default_group_element_name
    if default_group_element
      default_group_element.name
    else
      ""
    end
  end

  def default_group_element_name=(value)
    # We don't want it.
  end

  def <=>(other)
    self.starts_on <=> other.starts_on
  end
end
