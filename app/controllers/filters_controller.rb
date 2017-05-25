class FiltersController < ApplicationController
  before_action :find_user, only: [:edit, :update]

  # GET /users/1/filters/1/edit
  def edit
    fm = FilterManager.new(@user)
    @filter = fm.generate_filter
    render :layout => false
  end

  # PATCH/PUT /users/1/filters/1.js
  def update
    fm = FilterManager.new(@user)
    #
    #  We can't pre-filter the params because they are dynamically
    #  generated.  The service object isn't going to do a bulk assign
    #  anyway.
    #
    @modified, @filter_state = fm.generate_filter.update(params)
    respond_to do |format|
      format.js
    end
  end

  private
    def authorized?(action = action_name, resource = nil)
      logged_in? && current_user.known?
    end

    # Use callbacks to share common setup or constraints between actions.
    def find_user
      @user = User.find(params[:user_id])
    end

end
