# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi

  class EventsController < PublicApi::ApplicationController
    def create
      status  = :ok
      event   = nil
      message = nil
      errors  = nil
      if current_user.create_events?
        eventsource = Eventsource.find_by(name: "API")
        if eventsource
          event =
            eventsource.events.create(
              event_params.merge(owner: current_user))
          if event.valid?
            event.reload
            event.journal_event_created(current_user)
            #
            #  Now I should add the requested elements, if any.
            #
          else
            status = :unprocessable_entity
            errors = event.errors
          end
        else
          status = :service_unavailable
          message = "API Eventsource not configured"
        end
      else
        status = :forbidden
      end
      #
      #  And send back a response.
      #
      json_result = {
        status: status_text(status)
      }
      if event
        json_result[:event] = ModelHasher.new.summary_from(event)
      end
      if message
        json_result[:message] = message
      end
      if errors
        json_result[:errors] = errors
      end
      render json: json_result, status: status
    end

    private

    def event_params
      params.require(:event).permit(:body,
                                    :eventcategory_id,
                                    :starts_at_text,
                                    :ends_at_text,
                                    :all_day_field)
    end

  end

end
