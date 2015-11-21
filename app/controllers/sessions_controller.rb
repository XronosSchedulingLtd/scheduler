class SessionsController < ApplicationController
  def new
    redirect_to '/auth/google_oauth2'
  end

  def create
    auth = request.env["omniauth.auth"]
#    raise auth.inspect
    user = User.find_by_provider_and_uid(auth["provider"], auth["uid"]) ||
           User.create_from_omniauth(auth)
    reset_session
    session[:user_id] = user.id
    Rails.logger.info("User #{user.email} signed in.")
    redirect_to root_url, :notice => "Signed in"
  end

  def destroy
    session[:user_id] = nil
    @current_user = nil
    redirect_to root_url, :notice => "Signed out"
  end

  #
  #  A request to chage the user id for this session.  A testing tool.
  #  Should perhaps restrict it to the development environment only.
  #
  def become
    if current_user.can_su
      user_id = params[:user_id]
      if user_id
        new_user = User.find_by(id: user_id)
        if new_user
          reset_session
          session[:user_id] = new_user.id
        end
      end
    end
    redirect_to :root
  end

  private

  def authorized?(action = action_name, resource = nil)
    logged_in? || action == 'new' || action == 'create'
  end

end
