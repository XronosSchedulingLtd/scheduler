#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  Holds common code to be included in the ApplicationController
#  in both the main application and the PublicApi engine.
#
#  Said code thus ends up available to all the subsidiary controllers
#  in both areas.
#
#  This module both defines some instance variables and expects to
#  do all the manipulation of them.
#

#
#  Instance variables used.
#
#  @current_user
#  @original_user
#
#  It also considers itself as owning the session, and particularly
#
#  session[:user_id]
#  session[:original_user_id]
#
#  No other code should reference or manipulate these.
#
#  Other bits of code may put things in the session, but they should
#  be aware that they will disappear at login/logout/su/revert
#  Typically these are URLs to go back to, or notification records
#  which persist through an event editing session.
#
#
#  This module handles the mechanics of logging in and out or changing
#  user id, but it makes no attempt to check validity.  It's up to the calling
#  code to make sure the request is permissible.
#

module ControllerCommon

  #
  #  General method to clean things up at any kind of state change.
  #
  def reset_session_and_purge_cache
    reset_session
    @current_user = nil
    @original_user = nil
  end

  #
  #  Set the indicated user as being logged in.
  #
  def set_logged_in_as(user)
    reset_session_and_purge_cache
    session[:user_id] = user.id
    @current_user = user
  end

  #
  #  Whoever is logged in, log out.  Note that this will work even
  #  if no-one is logged in.
  #
  def set_logged_out
    reset_session_and_purge_cache
  end

  #
  #  Set the indicated user as the current user, and stack the old
  #  one.  Calling code should already have checked that we're not
  #  already in an su state.
  #
  def su_to(new_user)
    saved_user = current_user
    reset_session_and_purge_cache
    session[:user_id] = new_user.id
    @current_user = new_user
    session[:original_user_id] = saved_user.id
    @original_user = saved_user
  end

  #
  #  Revert back to the previous logged in user.  Calling code should
  #  already have checked that this is feasible (although we will
  #  cope if it isn't).
  def revert_su
    original_user_id = session[:original_user_id]
    if original_user_id
      #
      #  The request to revert does at least have some meaning.
      #
      reset_session_and_purge_cache
      session[:user_id] = original_user_id
    end
  end

  #
  #  Give cached access to the user record of the current user.
  #
  def current_user
    #
    #  This next line is dangerously clever, but it seems to be in common
    #  usage.
    #
    #  Clever because it gets the desired result very compactly.
    #  Dangerous because it's not obvious how or if it works unless
    #  you stop to think for a while.
    #
    #  I don't like it.
    #
    #  The crucial point to note is that the trailing if clause is
    #  evaluated first.  If it comes out as false then nothing else
    #  happens and the line yields nil, which is then returned.
    #
    #  Only if session[:user_id] is truthy (i.e. not nil) does the
    #  rest of the line get dealt with.  If @current_user is not
    #  nil then that is returned, otherwise the database fetch is
    #  executed, the result (which may be nil) assigned to @current_user
    #  and the same value is returned.
    #
    #  Note that it is still necessary to set @current_user back to
    #  nil when session[:user_id] is changed, because otherwise the
    #  cached record could just be carried through (although it would
    #  need a new value to be assigned to session[:user_id] within
    #  the duration of the same request - e.g. for an su request.
    #
    @current_user ||=
      User.includes(:concerns).find_by(id: session[:user_id]) if session[:user_id]
  end

  #
  #  Likewise for the original user, if any.
  #
  #  Note - returns nil if we are not in an su session.
  #
  def original_user
    @original_user ||=
      User.find_by(id: session[:original_user_id]) if session[:original_user_id]
  end

  #
  #  Is anyone logged in at all (possibly a guest)?
  #
  def logged_in?
    !!current_user
  end

  #
  #  Is a known user (not a guest) logged in?
  #
  def known_user?
    !!current_user && current_user.known?
  end

  #
  #  Can only su if a) have permission and b) not already su'ed.
  #
  def user_can_su?
    known_user? && current_user.can_su? &&
      !session[:original_user_id]
  end

  def user_can_revert?
    !!session[:original_user_id]
  end

end
