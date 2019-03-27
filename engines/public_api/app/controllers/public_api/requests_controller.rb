# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi

  class RequestsController < PublicApi::ApplicationController

    class RequestToSend
      def initialize(request)
        @my_hash = Hash.new
        @my_hash[:id] = request.id
        event_hash = Hash.new
        event_hash[:id] = request.event.id
        event_hash[:body] = request.event.body
        event_hash[:starts_at] = request.event.starts_at
        event_hash[:ends_at] = request.event.ends_at
        event_hash[:all_day] = request.event.all_day
        elements = Array.new
        request.event.elements.each do |element|
          elements << element.hash_of([:id, :name, :entity_type])
        end
        event_hash[:elements] = elements
        @my_hash[:event] = event_hash
      end

      def as_json(options={})
        @my_hash
      end
    end

    # GET /elements/1/requests.json
    #
    def index
      @element = Element.find_by(id: params[:element_id])
      if @element
        if @element.can_have_requests?
          #
          #  The caller may specify a date range, but for now we're going
          #  to go just for today.
          #
          start_date = Date.today
          end_date = Date.today + 1.day
          requests = @element.requests.
                              during(start_date, end_date).
                              includes(:event).collect {|r| RequestToSend.new(r)}
          render json: {
            status: 'OK',
            requests: requests
          }, status: :ok

        else
          render json: {status: "Method not allowed"},
                 status: :method_not_allowed
        end
      else
        render json: {status: "Not found"}, status: :not_found
      end
    end

    private

  end

end
