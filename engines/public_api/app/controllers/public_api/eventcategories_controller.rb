# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi

  class EventcategoriesController < PublicApi::ApplicationController

    def index
      if current_user.privileged?
        selector = Eventcategory.available
      else
        selector = Eventcategory.unprivileged.available
      end
      @eventcategories = selector.to_a
      json_result = {
        status: status_text(:ok),
        eventcategories: ModelHasher.new.summary_from(@eventcategories)
      }
      render json: json_result, status: :ok
    end

    def show
      @eventcategory = Eventcategory.find_by(id: params[:id])
      if @eventcategory
        #
        #  It may be that the user is not allowed to access this
        #  one.
        #
        if @eventcategory.privileged? && !current_user.privileged?
          render json: {status: status_text(:forbidden)}, status: :forbidden
        else
          render json: {
            status: "OK",
            eventcategory: ModelHasher.new.detail_from(@eventcategory)
          }
        end
      else
        render json: {status: status_text(:not_found)}, status: :not_found
      end
    end

  end

end
