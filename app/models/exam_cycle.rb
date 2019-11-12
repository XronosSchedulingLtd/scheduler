class ExamCycle < ActiveRecord::Base

  include Generator

  belongs_to :default_rota_template, class_name: "RotaTemplate"
  belongs_to :default_group_element, class_name: "Element"
  belongs_to :selector_element,      class_name: "Element"

  validates :name, :presence => true
  validates :starts_on, :presence => true
  validates :ends_on, :presence => true
  #
  #  Note that, although we have a validation here to ensure we
  #  have a default rota template, it's possible that said template
  #  might subsequently have been deleted.  The action in the rota_template
  #  model is to nullify our reference, so we end up with a nil item
  #  here.  Always check before using it.
  #
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

  def selector_element_name
    if selector_element
      selector_element.name
    else
      ""
    end
  end

  def selector_element_name=(value)
    # Don't want this one either
  end

  def <=>(other)
    self.starts_on <=> other.starts_on
  end

  #
  #  This is intended to work very much like the method:
  #
  #    exam_cycle.proto_events
  #
  #  provided as part of active record, but it returns a constructed
  #  array of InvigilationProtoEvents instead of ProtoEvents.
  #
  #  Note that it does actually return an array, unlike the original
  #  which returns a potential database query.  This is inevitable,
  #  because the InvigilationProtoEvents aren't actually in the d/b.
  #
  def invigilation_proto_events
    InvigilationProtoEvent.wrap(self.proto_events)
  end
end
