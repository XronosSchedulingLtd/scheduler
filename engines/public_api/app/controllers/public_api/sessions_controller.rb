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

    def update
      user_id = session_params[:user_id]
      if user_can_su?
        if user_id && (user = User.find_by(id: user_id))
          #
          #  Don't allow acquisition of admin privilege.
          #
          if current_user.as_privileged_as?(user)
            su_to(user)
            status = :ok
          else
            status = :forbidden
          end
        else
          status = :not_found
        end
      elsif original_user &&
            user_id &&
            original_user.id == user_id.to_i
        revert_su
        status = :ok
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

    def version
      #
      #  The SOFTWARE VERSION variable contains something like:
      #
      #  "Version 1.15.13".
      #
      #  We want only the last bit.
      #
      version = SOFTWARE_VERSION.split(' ')[-1]
      render json: { status: 'OK', version: version }
    end

    private

    def authorized?(action = action_name, resource = nil)
      #
      #  We only tolerate json requests, and we can log you in
      #  or out.  If you are not logged in, you can still logout.
      #
      #  You are also allowed to query the version regardless.
      #
      request.format == 'json' &&
      (
        action == 'login' ||
        action == 'logout' ||
        action == 'version' ||
        (
          known_user? &&
          we_can_api? &&
          (
            action == 'update' ||
            action == 'revert' ||
            action == 'whoami'
          )
        )
      )
    end

    def session_params
      params.require(:session).permit(:user_id)
    end

  end

end

