class UserFormResponse < ActiveRecord::Base

  belongs_to :user_form
  belongs_to :owner, polymorphic: true
  belongs_to :user

  validates :user_form, presence: true

  #
  #  The following are helper methods intended to make life easier for
  #  the view.  They could go in a helper, but it seems more logical
  #  to be able to ask the model for this information.
  #
  #
  def definition
    user_form ? user_form.definition : ""
  end

  def updated_at_text
    self.updated_at.strftime(
      "%H:%M:%S #{self.updated_at.day.ordinalize} %b, %Y")
  end

  def corresponding_event
    if self.owner
      if self.owner.instance_of?(Event)
        self.owner
      elsif self.owner.instance_of?(Commitment)
        self.owner.event
      else
        nil
      end
    else
      nil
    end
  end

  def event_text
    event = corresponding_event
    if event
      event.body
    else
      ""
    end
  end

  def event_time_text
    event = corresponding_event
    if event
      event.starts_at.interval_str(event.ends_at)
    else
      ""
    end
  end

  def user_text
    self.user ? self.user.name : ""
  end

end
