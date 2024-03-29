# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi

  class CommitmentsController < PublicApi::ApplicationController

    before_action :find_commitment, only: [:destroy]

    # GET /elements/1/commitments.json
    #
    def index
      status         = :ok
      requests       = nil
      message        = nil
      want_staff     = false
      want_locations = false
      @element = Element.find_by(id: params[:element_id])
      if @element
        status, message, start_date, end_date =
          process_date_params(params)
        if status == :ok
          #
          #  Still no error identified.  Any additional parameters?
          #
          modifiers = params[:include]
          if modifiers
            includes = modifiers.split(",")
            if includes.include?("staff")
              want_staff = true
            end
            if includes.include?("locations")
              want_locations = true
            end
          end
          if want_staff || want_locations
            query =
              @element.commitments_on(startdate: start_date,
                                      enddate: end_date).
                       includes(:element, event: [commitments: [element: :entity]])
          else
            query =
              @element.commitments_on(startdate: start_date,
                                      enddate: end_date).
                       includes(:element, :event)
          end
          #
          #  This next line forces the query to be executed and saves
          #  the result.
          #
          commitments = query.to_a
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
      if commitments
        json_result[:commitments] =
          ModelHasher.new(
            {
              staff: want_staff,
              locations: want_locations
            }).summary_from(commitments.sort, @element)
      end
      if message
        json_result[:message] = message
      end
      render json: json_result, status: status
    end

    # DELETE /api/commitments/1
    def destroy
      @event = @commitment.event
      if current_user.can_delete?(@commitment)
        @event.journal_commitment_removed(@commitment, current_user)
        @commitment.destroy
        status = :ok
      else
        status = :forbidden
      end
      render json: { status: status_text(status) }, status: status
    end

    private

    def find_commitment
      @commitment = Commitment.find(params[:id])
    end

  end

end
