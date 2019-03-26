# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :null_session

    before_action :login_required

    private

    def current_user
      @current_user ||=
        User.find_by(id: session[:user_id]) if session[:user_id]
    end

    def logged_in?
      !!current_user
    end

    def login_required
      authorized? || access_denied
    end

    def access_denied
      respond_to do |format|
        format.html do
          #
          #  Shouldn't be getting HTML requests at all.
          #  Send them back to the application proper
          #
          redirect_to '/'
        end
        format.json do
          render json: { message: 'Access denied' }, status: 401
        end
      end
    end

    def authorized?(action = action_name, resource = nil)
      Rails.logger.debug("session[:user_id] = #{session[:user_id]}")
      logged_in? && current_user.can_api? && request.format == 'json'
    end

  end
end
