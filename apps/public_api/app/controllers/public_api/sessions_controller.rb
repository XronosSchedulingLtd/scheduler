# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi
  class SessionsController < PublicApi::ApplicationController
    #
    #  Login for the API works rather differently.  All you need to
    #  provide is the secret UUID of an API-enabled user.
    #
    def login
      uid = params[:uid]
      if uid
        user = User.find_by(uuid: uid)
        if user && user.can_api?
          reset_session
          session[:user_id] = user.id
          respond_to do |format|
            format.json do
              render json: 'OK'
            end
          end
        else
          access_denied
        end
      else
        access_denied
      end
    end

    private

    def authorized?(action = action_name, resource = nil)
      action == 'login' && request.format == 'json'
    end

  end

end

