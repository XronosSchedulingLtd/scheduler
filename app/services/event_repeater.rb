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

  def self.effect_repetition(by_user, ec, event, asynchronous = false)
    result = false
    if asynchronous
      Rails.logger.error("Asynchronous event repetition not implemented yet.")
    else
      if ec.valid? && event.valid?
        if ec.note_update_requested(by_user, true)
          candidates = ec.events.sort
          to_go = []
          week_identifier =
            WeekIdentifier.new(ec.repetition_start_date,
                               ec.repetition_end_date)
          eventsource = Eventsource.find_by(name: "Manual")
          ec.repetition_start_date.upto(ec.repetition_end_date) do |date|
            Rails.logger.debug("Processing #{date}")
            #
            #  Any existing events before this date should be got rid of.
            #
            while (candidate = candidates[0]) && candidate.starts_at < date
              to_go << candidates.shift
            end
            if ec.happens_on?(date, week_identifier.week_letter(date))
              if candidates[0] &&
                 candidates[0].starts_at.to_date == date
                #
                #  It seems we already have an event on this date.
                #  Take it and make sure it is right.
                #
                candidate = candidates.shift
                candidate.make_to_match(by_user, event) do |item|
                  if block_given?
                    yield item
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
                    yield item
                  end
                end
              end
            end
          end
          #
          #  Any left which we haven't dealt with should be destroyed.
          #
          (to_go + candidates).each do |event|
            event.journal_event_destroyed(by_user, true)
            event.destroy
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

end

