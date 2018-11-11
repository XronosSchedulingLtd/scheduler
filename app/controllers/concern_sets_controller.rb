class ConcernSetsController < ApplicationController
  before_action :find_user

  # GET /users/1/concern_sets
  def index
    dummy_concern_set = ConcernSet.new({
      name: ConcernSet::DefaultViewName,
      owner: @user
    })
    dummy_concern_set.id = 0
    @concern_sets = [dummy_concern_set] + @user.concern_sets
    @concern_set = ConcernSet.new
    render layout: false
  end

  # POST /users/1/concern_sets
  def create
    @refresh = false
    @concern_set = @user.concern_sets.new(concern_set_params)
    if @concern_set.save
      if @concern_set.copy_concerns
        #
        #  Need to create copies of all the currently visible concerns
        #  in what was the user's current view.
        #
        #  They do not get any permission bits or special attributes.
        #  Those only ever apply in the default set, and we can't
        #  create the default set.
        #
        if @user.current_concern_set
          selector = @user.current_concern_set.concerns.visible
        else
          selector = @user.concerns.default_view.visible
        end
        selector.each do |concern|
          @concern_set.concerns.create({
            user:    @user,
            element: concern.element,
            visible: true,
            colour:  concern.colour
          })
          if @concern_set.and_hide
            #
            #  We have also been asked to remove the concern from its
            #  existing set.  If it's a dynamic concern (one which the
            #  user can delete) then we delete it, but if it's one which
            #  confers privilege, then we merely make it invisible.
            #
            #
            if @user.can_delete?(concern)
              concern.destroy
            else
              concern.visible = false
              concern.save
            end
          end
        end
      end
      @user.current_concern_set = @concern_set
      @user.save
      @refresh = true
    end
    respond_to do |format|
      format.js { render 'select' }
    end
  end

  # PUT /users/1/concern_sets/1/select
  #
  #  Switch to the indicated concern set, provided it belongs to the
  #  user.  If it doesn't then do nothing.  It means that someone is
  #  playing at silly buggers.
  #
  def select
    @refresh = false
    id = params[:id]
    if id == "0"
      #
      #  User wants to switch to his default concern set (i.e. none).
      #  This is always permitted.
      #
      @user.current_concern_set = nil
      @user.save
      @refresh = true
    else
      concern_set = @user.concern_sets.find_by(id: id)
      if concern_set
        @user.current_concern_set = concern_set
        @user.save
        @refresh = true
      end
    end
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @refresh = false
    concern_set = @user.concern_sets.find_by(id: params[:id])
    if concern_set
      if concern_set == @user.current_concern_set
        @refresh = true
      end
      concern_set.destroy
    end
    respond_to do |format|
      format.js { render 'select' }
    end
  end

  private
  #
  #
  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.known? &&
      params[:user_id].to_i == current_user.id
  end

  # Use callbacks to share common setup or constraints between actions.
  def find_user
    @user = User.find(params[:user_id])
  end

  def concern_set_params
    params.require(:concern_set).permit(:name, :copy_concerns, :and_hide)
  end
end
