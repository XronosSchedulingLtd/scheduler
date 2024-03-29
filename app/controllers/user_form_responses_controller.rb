class UserFormResponsesController < ApplicationController
  before_action :find_user_form, only: [:new, :create]
  before_action :maybe_find_user_form, only: [:index]
  before_action :set_user_form_response, only: [:show, :edit, :update, :destroy]

  # GET /user_form_responses
  # GET /user_form_responses.json
  def index
    if @user_form && current_user.can_has_forms?
      @user_form_responses =
        @user_form.user_form_responses.order('updated_at DESC')
    else
      @user_form_responses =
        current_user.user_form_responses
    end
  end

  # GET /user_form_responses/1
  # GET /user_form_responses/1.json
  def show
#    Rails.logger.debug("request.referer = #{request.referer}")
#    raise params.inspect
    parent = @user_form_response.parent
    if parent
      if parent.instance_of?(Commitment)
        @event = parent.event
        @resource = parent.element
        @status = parent.status
      elsif parent.instance_of?(Request)
        @event = parent.event
        @resource = parent.element
        @status = parent.pending? ? "Pending" : "Complete"
      else
        @event = nil
      end
    else
      @event = nil
    end
    @read_only = true
    @save_button = false
    @cancel_button = true
    @form_status = @user_form_response.status.to_s.capitalize
    #
    #  You get to see the comments if either:
    #
    #  a) There are existing comments
    #  b) You are entitled to add comments
    #
    @comments = @user_form_response.comments.to_a
    can_add = current_user.can_add_comments_to?(@user_form_response)
    if !@comments.empty? || can_add
      @show_comments = true
      #
      #  You get rather odd behaviour if you pass an ActiveRecord::Relation
      #  to "render" in a view.  It gets rendered one more time than there
      #  are records.  Force it to an array here to prevent this.
      #
      if can_add
        @allow_add_comment = true
        @comment = @user_form_response.comments.new
      else
        @allow_add_comment = false
      end
    else
      @show_comments = false
    end
    if params[:close_after]
      @cancel_url = "#"
      @close_after = true
    else
      @cancel_url = request.referer || root_path
    end
    @cancel_text = "Back"
  end

  # GET /user_form_responses/new
  def new
    session[:return_to] = request.referer
    @user_form_response = @user_form.user_form_responses.new
    @read_only = false
    @save_button = true
    @cancel_button = true
    @cancel_url = request.referer || root_path
    @cancel_text = "Cancel"
  end

  # GET /user_form_responses/1/edit
  def edit
    session[:return_to] = request.referer
    @read_only = false
    @save_button = true
    @cancel_button = true
    @cancel_url = request.referer || root_path
    @cancel_text = "Cancel"
    parent = @user_form_response.parent
    if parent
      if parent.instance_of?(Commitment)
        @event = parent.event
        @resource = parent.element
        if parent.rejected?
          @extra_text = "Previously rejected#{ parent.by_whom ? " by: #{parent.by_whom.name}" : ""}"
          if parent.reason
            @extra_text << "\nReason: #{parent.reason}"
          end
        end
      elsif parent.instance_of?(Request)
        @event = parent.event
        @resource = parent.element
      else
        @event = nil
      end
    else
      @event = nil
    end
    #
    #  We don't allow the addition of comments when editing the form,
    #  but you can see any that are there.
    #
    @comments = @user_form_response.comments.to_a
    if @comments.empty?
      @show_comments = false
    else
      @show_comments = true
      @allow_add_comment = false
    end
    @form_status = @user_form_response.status.to_s.capitalize

  end

  # POST /user_form_responses
  # POST /user_form_responses.json
  def create
    local_params = user_form_response_params
    local_params[:user] = current_user
    @user_form_response =
      @user_form.user_form_responses.new(local_params)

    respond_to do |format|
      if @user_form_response.save
        format.html { redirect_to session[:return_to] || root_path }
        format.json { render :show, status: :created, location: @user_form_response }
      else
        format.html { render :new }
        format.json { render json: @user_form_response.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /user_form_responses/1
  # PATCH/PUT /user_form_responses/1.json
  def update
    #
    #  We rely on the front end to check that all required fields
    #  have been filled in.
    #
    #  TODO: Should check here that the current user does actually have
    #  permission to fill in this form.
    #
    my_params = user_form_response_params
    respond_to do |format|
      if @user_form_response.update(my_params)
        if parent = @user_form_response.parent
          if parent.instance_of?(Commitment)
            if parent.rejected? || parent.noted?
              parent.status = :requested
              parent.save
            end
            parent.event.journal_form_completed(@user_form_response,
                                                parent,
                                                current_user)
          end
        end
        format.html { redirect_to session[:return_to] || root_path }
        format.json { render :show, status: :ok, location: @user_form_response }
      else
        format.html { render :edit }
        format.json { render json: @user_form_response.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_form_responses/1
  # DELETE /user_form_responses/1.json
  def destroy
    @user_form = @user_form_response.user_form
    @user_form_response.destroy
    respond_to do |format|
      format.html { redirect_to user_form_user_form_responses_path(@user_form) }
      format.json { head :no_content }
    end
  end

  private

    def authorized?(action = action_name, resource = nil)
      logged_in? && (current_user.admin ||
                     action == "index" ||
                     action == "edit" ||
                     action == "show" ||
                     action == "update")
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_user_form_response
      @user_form_response = UserFormResponse.find(params[:id])
    end

    def find_user_form
      @user_form = UserForm.find(params[:user_form_id])
    end

    def maybe_find_user_form
      #
      #  If this fails, I don't want an error.  It just means we're
      #  not working in the context of a user form.
      #
      @user_form = UserForm.find_by(id: params[:user_form_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_form_response_params
      params.require(:user_form_response).permit(:user_form_id, :parent_id, :parent_type, :user_id, :form_data, :status)
    end
end
