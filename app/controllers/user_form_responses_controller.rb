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
    Rails.logger.debug("request.referer = #{request.referer}")
    parent = @user_form_response.parent
    if parent
      if parent.instance_of?(Commitment)
        @event = parent.event
        @resource = parent.element
      else
        @event = nil
      end
    else
      @event = nil
    end
    @read_only = true
    @save_button = false
    @cancel_button = true
    @cancel_url = request.referer || root_path
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
  end

  # POST /user_form_responses
  # POST /user_form_responses.json
  def create
    local_params = user_form_response_params
    local_params[:user] = current_user
    local_params[:complete] = true
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
    my_params = user_form_response_params
    my_params[:complete] = true
    respond_to do |format|
      if @user_form_response.update(my_params)
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
      params.require(:user_form_response).permit(:user_form_id, :parent_id, :parent_type, :user_id, :form_data)
    end
end
