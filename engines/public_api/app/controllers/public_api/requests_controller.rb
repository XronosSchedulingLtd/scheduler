# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi

  class RequestsController < PublicApi::ApplicationController

    before_action :find_request, only: [:destroy]

    # GET /elements/1/requests.json
    #
    def index
      status = :ok
      requests = nil
      message  = nil
      @element = Element.find_by(id: params[:element_id])
      if @element
        if @element.can_have_requests?
          status, message, start_date, end_date =
            process_date_params(params)
          if status == :ok
            #
            #  Still no error identified.
            #
            requests = @element.requests.
                                during(start_date, end_date + 1.day).
                                includes(:event)
          end
        else
          status = :method_not_allowed
        end
      else
        status = :not_found
      end
      #
      #  And send our response.
      #
      json_result = {
        status: status_text(status)
      }
      if requests
        json_result[:requests] = ModelHasher.new.summary_from(requests.sort, @element)
      end
      if message
        json_result[:message] = message
      end
      render json: json_result, status: status
    end

    # DELETE /api/requests/1
    def destroy
      @event = @request.event
      if current_user.can_delete?(@request)
        @event.journal_resource_request_destroyed(@request, current_user)
        @request.destroy
        status = :ok
      else
        status = :forbidden
      end
      render json: { status: status_text(status) }, status: status
    end

    private

    def find_request
      @request = Request.find(params[:id])
    end

  end

end
