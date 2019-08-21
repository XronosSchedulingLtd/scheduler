# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

#
#  This class takes care of the propagation of repeating events.
#
#  It needs an EventCollection (which defines how the repetition will
#  occur) and a sample Event (which gives the timings and resources to
#  use).  Note that in the course of doing the repetition, it might even
#  delete the original sample Event - if for instance you set up an
#  event on a Thursday, then ask the system to repeat it on every
#  Wednesday.
#
#  DateTime fields in the EventCollection are used to ensure that there
#  can't be two attempts going on at once.
#
#  We work on the principle that any repeating event can occur at most
#  once per calendar day.  If we find an existing one of our events on
#  a given day, then we adjust that one to suit our current settings.
#
class EventRepeater

  #
  #  If a block is given, then call it each time a commitment is
  #  added or removed, with two parameters:
  #
  #    :added or :removed
  #    the commitment
  #
  def self.effect_repetition(by_user, ec, event, asynchronous = false)
    result = false
    todays_date = Date.today
    if asynchronous
      Rails.logger.error("Asynchronous event repetition not implemented yet.")
    else
      if ec.valid? && event.valid?
        if ec.note_update_requested(by_user, true)
          candidates = ec.events.sort
          possibly_to_go = []
          week_identifier =
            WeekIdentifier.new(ec.repetition_start_date,
                               ec.repetition_end_date)
          eventsource = Eventsource.find_by(name: "Manual")
          ec.repetition_start_date.upto(ec.repetition_end_date) do |date|
            while (candidate = candidates[0]) && candidate.starts_at < date
              possibly_to_go << candidates.shift
            end
            if ec.happens_on?(date, week_identifier.week_letter(date), todays_date)
              if candidates[0] &&
                 candidates[0].starts_at.to_date == date
                #
                #  It seems we already have an event on this date.
                #  Take it and make sure it is right.
                #
                candidate = candidates.shift
                #
                #  It might not be appropriate for us to modify this
                #  event, even though it otherwise matches.  Currently
                #  this happens only because it is in the past.
                #
                if ec.can_modify_event?(candidate)
                  candidate.make_to_match(by_user, event) do |action, item|
                    if block_given?
                      yield action, item
                    end
                  end
                end
              else
                #
                #  Need to create a new event on this date.
                #
                modifiers = {
                  owner: by_user,
                  eventsource: eventsource,
                  starts_at: Time.zone.parse(event.start_time_text, date),
                  ends_at: Time.zone.parse(event.end_time_text, date)
                }
                event.clone_and_save(by_user,
                                     modifiers,
                                     nil,
                                     :repeated,
                                     true) do |item|
                  if block_given?
                    yield :added, item
                  end
                end
              end
            end
          end
          #
          #  Any left which we haven't dealt with should be destroyed.
          #
          (possibly_to_go + candidates).each do |event|
            if ec.event_should_go?(event, todays_date)
              event.journal_event_destroyed(by_user, true)
              if block_given?
                event.commitments.each do |c|
                  yield :removed, c
                end
                event.requests.each do |r|
                  yield :removed, r
                end
              end
              event.destroy
            end
          end
          event.journal_repeated_from(by_user)
          ec.note_finished_update
          result = true
        else
          Rails.logger.error("Failed to start repetition process.")
        end
      else
        Rails.logger.error("Event and collection must be valid to effect repetition.")
      end
    end
    result
  end


  #
  #  A much cut down version of the previous method, which simply works
  #  out whether or not the specified EventCollection and Event would,
  #  if passed to the previous method, result in any events at all.
  #
  #  Intended as a pre-check to make sure we don't delete everything.
  #
  def self.would_have_events?(ec)
    todays_date = Date.today
    unless ec.days_of_week.empty? ||
           ec.weeks.empty? ||
           ec.repetition_end_date < ec.repetition_start_date
      week_identifier =
        WeekIdentifier.new(ec.repetition_start_date,
                           ec.repetition_end_date)
      ec.repetition_start_date.upto(ec.repetition_end_date) do |date|
        if ec.happens_on?(date, week_identifier.week_letter(date), todays_date)
          return true
        end
      end
    end
    return false
  end

end

