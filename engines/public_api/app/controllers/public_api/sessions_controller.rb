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

    def become
      if user_can_su?
        user_id = params[:user_id]
        if user_id && (user = User.find_by(id: user_id))
          su_to(user)
          status = :ok
        else
          status = :not_found
        end
      else
        status = :forbidden
      end
      render json: { status: status_text(status) }, status: status
    end

    #
    #  Like logout, this always works.
    #
    def revert
      if user_can_revert?
        revert_su
      end
      status = :ok
      render json: { status: status_text(status) }, status: status
    end

    #
    #  For users who can su, the means to check their current user
    #  id.
    #
    def whoami
      #
      #  Another case where we may inherit the necessary permission
      #  from our original user.
      #
      #  Note also that here we specifically want to check the user's
      #  permission bit - not whether an su is feasible.
      #
      check_as = original_user || current_user
      if check_as.can_su?
        render json: { status: status_text(:ok), user_id: current_user.id }, status: :ok
      else
        render json: { status: status_text(:forbidden) }, status: :forbidden
      end
    end

    private

    def authorized?(action = action_name, resource = nil)
      #
      #  We only tolerate json requests, and we can log you in
      #  or out.  If you are not logged in, you can still logout.
      #
      request.format == 'json' &&
      (
        action == 'login' ||
        action == 'logout' ||
        (
          known_user? &&
          we_can_api? &&
          (
            action == 'become' ||
            action == 'revert' ||
            action == 'whoami'
          )
        )
      )
    end

  end

end

