# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi

  class EventsController < PublicApi::ApplicationController
    def create
      status   = :ok
      event    = nil
      failures = nil
      message  = nil
      if current_user.create_events?
        eventsource = Eventsource.find_by(name: "API")
        if eventsource
          event =
            eventsource.events.create(
              event_params.merge(owner: current_user))
          if event.valid?
            event.reload
            event.journal_event_created(current_user)
            status = :created
            #
            #  Now I should add the requested elements, if any.
            #
            failures = Array.new
            if (element_ids = params[:elements])
              if element_ids.respond_to?(:each)
                #
                #  An array to process
                #
                element_ids.each do |element_id|
                  linker = add_element(event, element_id)
                  unless linker.respond_to?(:valid?) && linker.valid?
                    failures << linker
                  end
                end
              else
                #
                #  Just the one
                #
                linker = add_element(event, element_ids)
                unless linker.respond_to?(:valid?) && linker.valid?
                  failures << linker
                end
              end
            end
            #
            #  We may now have some invalid commitment or request records
            #  attached to our event, which makes it appear invalid too.
            #
            #  There is also a bug in Rails 4.2.11.1 whereby newly created
            #  commitments appear twice in the in-memory copy of the
            #  event record.  See tests for details.  It's fixed in
            #  Rails 5.0, but for now this next step will address both.
            #
            event.reload
          else
            status = :unprocessable_entity
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
      mh = ModelHasher.new
      json_result = {
        status: status_text(status)
      }
      if event
        json_result[:event] = mh.summary_from(event)
      end
      if failures
        json_result[:failures] = mh.summary_from(failures, event)
      end
      if message
        json_result[:message] = message
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

    #
    #  This method does all the work of adding a requested element
    #  to an event.  It decides whether a Request or a Commitment
    #  would be appropriate and then creates it.  It returns
    #  the created item, whether or not it is valid.
    #
    #  If the element doesn't make sense, it returns an error hash.
    #
    def add_element(event, element_id)
      #
      #  Note that find_by can cope with either an integer or a string.
      #
      element = Element.includes(:entity).find_by(id: element_id)
      if element
        if element.can_have_requests?
          #
          #  Go for a request
          #
          request = event.requests.create(element: element, quantity: 1)
          if request.valid?
            event.journal_resource_request_created(request, current_user)
          end
          request
        else
          #
          #  Go for a commitment
          #
          commitment = event.commitments.create(element: element) do |c|
            set_appropriate_approval_status(c)
          end
          if commitment.valid?
            event.journal_commitment_added(commitment, current_user)
          end
          commitment
        end
      else
        {
          status: "Not found",
          element_id: element_id
        }
      end
    end

  end

end
