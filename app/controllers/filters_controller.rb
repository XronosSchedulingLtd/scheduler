class FiltersController < ApplicationController
  before_action :find_user, only: [:edit, :update]

  # GET /users/1/filters/1/edit
  def edit
    @filter = FilterManager.new(@user).generate_filter
    @show_extra = current_user.admin
    render :layout => false
  end

  # PATCH/PUT /users/1/filters/1.js
  def update
    filter = FilterManager.new(@user).generate_filter
    #
    #  We can't pre-filter the params because they are dynamically
    #  generated.  The service object isn't going to do a bulk assign
    #  anyway.
    #
    @modified, @filter_state = filter.update(params)
    respond_to do |format|
      format.js
    end
  end

  private
  #
  #  In theory we allow admin to edit anybody's filters, although there
  #  is no provision for it currently in the UI.
  #
  #  Others can edit only their own.
  #
  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.known? &&
      (current_user.admin || params[:user_id].to_i == current_user.id)
  end

  # Use callbacks to share common setup or constraints between actions.
  def find_user
    @user = User.find(params[:user_id])
  end

end
