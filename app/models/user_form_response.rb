# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
class UserFormResponse < ActiveRecord::Base

  enum status: [
    #
    #================================================================
    #
    #  DANGER WILL ROBINSON!
    #
    #  The first status value here used to be called :empty, but that
    #  leads via a long chain to surprising results.
    #
    #  ActiveModel helpfully creates some helper methods - empty?,
    #  partial?, and complete? so you can do ufr.partial? rather than
    #  "ufr.status == :partial", but then the new empty? method
    #  is aliased as blank?, which the ActiveModel validation code
    #  calls to see whether a record exists at all.
    #
    #  Took me ages to track this down.
    #
    #  The moral of this story is - never give any enum a value of
    #  :empty (or :blank, but that's more obviously a no-no).
    #
    #================================================================
    #
    :pristine,
    :partial,
    :complete
  ]

  belongs_to :user_form
  belongs_to :parent, polymorphic: true
  belongs_to :user

  has_many :comments, as: :parent, dependent: :destroy

  validates :user_form, :parent, presence: true

  scope :incomplete, -> { where.not("user_form_responses.status = ?",
                                    UserFormResponse.statuses[:complete]) }
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
    if self.parent
      if self.parent.instance_of?(Event)
        self.parent
      elsif self.parent.instance_of?(Commitment)
        self.parent.event
      elsif self.parent.instance_of?(Request)
        self.parent.event
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

  def event_date_text
    event = corresponding_event
    if event
      event.starts_at.strftime("%d/%m/%Y")
    else
      ""
    end
  end

  def user_text
    self.user ? self.user.name : ""
  end

  def pushback_and_save
    if self.complete?
      self.status = :partial
      self.save
    end
  end

  #
  #  Note that this method expects a symbol.  The underlying Rails
  #  method expects an integer.
  #
  #  Note to self - I think this method is completely redundant.  It's
  #  here because I copied what was done in the Commitment model, but
  #  there the method is doing an extra bit of work.  Here it isn't.
  #
  #  The reality is that if you do:
  #
  #  object.status = 
  #
  #  then you can pass the symbol as you would expect.
  #
  #  object.status = :complete
  #
  #  It's only if you use
  #
  #  object[:status] =
  #
  #  that you have to make it an integer.
  #
  #  If you write your own custom "def status=(value)" method on
  #  the object (as is done in the Commitment model in order to
  #  implement some side effects) then you need to do the conversion
  #  from symbol to integer before finally saving it.  If OTOH you
  #  don't write this method at all, then symbols work fine.
  #
  #  In other words, if this method were deleted from here, I think
  #  it would all work just as before.
  #
  #  In fact, it's better without this method as defined here.  The default
  #  one copes with number, or symbol, or string, whilst this one copes
  #  only with symbol and string.
  #
#  def status=(new_status)
#    self[:status] = UserFormResponse.statuses[new_status]
#  end

  def self.populate_statuses
    raise "Last version containing working UserFormResponse::populate_statuses is 1.3.1"
  end
end
