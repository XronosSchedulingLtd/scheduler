# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi

  class UsersController < PublicApi::ApplicationController

    def index
      if current_user.can_su?
        #
        #  Although this is an index function, we expect to be given
        #  some more parameters.  Returning an index of all the users
        #  would mean sending quite a lot and could be some kind of
        #  security risk.
        #
        #  We take the view that if they don't send any parameters,
        #  we don't return any users.  You didn't ask for any
        #  so you don't get any.
        #
        if params[:email]
          @users = User.where(email: params[:email])
          if @users.empty?
            status = :not_found
          else
            status = :ok
          end
        else
          @users = []
          status = :ok
        end
      else
        @users = []
        status = :forbidden
      end
      data = ModelHasher.new.summary_from(@users)
      render json: {
        status: status_text(status),
        users: data
      }, status: status
    end

    def show
      #
      #  We use find_by rather than find because we want to handle
      #  the non-existence case explicitly and tidily rather than
      #  throwing the caller into a generic error handler.
      #
      @element = Element.includes(:entity).find_by(id: params[:id])
      if @element
        render json: {
          status: "OK",
          element: ModelHasher.new.detail_from(@element)
        }
      else
        render json: {status: status_text(:not_found)}, status: :not_found
      end
    end

  end

end
