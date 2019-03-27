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
      if uid && (user = User.find_by(uuid: uid)) && user.can_api?
        reset_session
        session[:user_id] = user.id
        render json: { status: 'OK' }
      else
        access_denied
      end
    end

    def logout
      reset_session
      session[:user_id] = nil
      render json: { status: 'OK' }
    end

    private

    def authorized?(action = action_name, resource = nil)
      #
      #  We only tolerate json requests, and we can log you in
      #  or out.  If you are not logged in, you can still logout.
      #
      request.format == 'json' &&
      (action == 'login' || action == 'logout')
    end

  end

end

