class SessionsController < ApplicationController
  def new
    redirect_to '/auth/google_oauth2'
  end

  def create
    auth = request.env["omniauth.auth"]
#    raise auth.inspect
    user = User.find_by_provider_and_uid(auth["provider"], auth["uid"]) ||
           User.create_from_omniauth(auth)
    session[:user_id] = user.id
    Rails.logger.info("User #{user.email} signed in.")
    redirect_to root_url, :notice => "Signed in"
  end

  def destroy
    session[:user_id] = nil
    @current_user = nil
    redirect_to root_url, :notice => "Signed out"
  end

  private

  def authorized?(action = action_name, resource = nil)
    logged_in? || action == 'new' || action == 'create'
  end

end