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
      uuid = params[:uuid] || params[:uid]
      if uuid && (user = User.find_by(uuid: uuid)) && user.can_api?
        set_logged_in_as(user)
        render json: { status: 'OK' }
      else
        access_denied
      end
    end

    def logout
      set_logged_out
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

