# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi

  class RequestsController < PublicApi::ApplicationController

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
                              includes(:event)
          render json: {
            status: 'OK',
            requests: ModelHasher.new.summary_from(requests)
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
