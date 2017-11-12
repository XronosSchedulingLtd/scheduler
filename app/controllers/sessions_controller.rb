class SessionsController < ApplicationController
  def new
#    Rails.logger.debug("Full path is #{request.fullpath}")
    #
    #  Want to guard agains left-over deep linking stuff.  If the user
    #  previously tried to access a page which triggered a login attempt,
    #  but they didn't complete the login, and have now chosen to do
    #  an explicit login, then they will be surprised if we go on to send
    #  them to the page they asked for earlier.  Guard against that
    #  case.
    #
    if /signin$/ =~ request.fullpath
      #
      #  This is an explicit login attempt.  Scrub any previous
      #  redireciton information.
      #
#      Rails.logger.debug("Explicit login")
      session.delete(:url_requested)
    end
    redirect_to '/auth/google_oauth2'
  end

  def create
    auth = request.env["omniauth.auth"]
#    raise auth.inspect
    user = User.find_by(provider: auth["provider"],
                        uid:      auth["uid"])
    if user
      #
      #  We have a user record but it doesn't seem to be connected
      #  to a staff or pupil record.  Do a dummy save, so that
      #  if one has sprung into existence we will get connected
      #  to it.
      #
      unless user.known?
        user.save
      end
    else
      user = User.create_from_omniauth(auth)
    end
#    user = User.find_by_provider_and_uid(auth["provider"], auth["uid"]) ||
#           User.create_from_omniauth(auth)
    url_requested = session[:url_requested]
    reset_session
    session[:user_id] = user.id
    Rails.logger.info("User #{user.email} signed in.")
    redirect_to url_requested || root_url, :notice => "Signed in"
  end

  def destroy
    session[:user_id] = nil
    @current_user = nil
    redirect_to root_url, :notice => "Signed out"
  end

  def failure
    #
    #  Could do with some info.
    #
    Rails.logger.debug("Login failed")
    Rails.logger.debug(request.env["omniauth.auth"].inspect)
    redirect_to root_url, :notice => "Login failed"
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
