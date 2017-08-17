class UserFormResponsesController < ApplicationController
  before_action :find_user_form, only: [:index, :new, :create]
  before_action :set_user_form_response, only: [:show, :edit, :update, :destroy]

  # GET /user_form_responses
  # GET /user_form_responses.json
  def index
    @user_form_responses = @user_form.user_form_responses.order('updated_at DESC')
  end

  # GET /user_form_responses/1
  # GET /user_form_responses/1.json
  def show
  end

  # GET /user_form_responses/new
  def new
    @user_form_response = @user_form.user_form_responses.new
  end

  # GET /user_form_responses/1/edit
  def edit
#    @user_form = @user_form_response.user_form
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
        format.html { redirect_to user_form_user_form_responses_path(@user_form), notice: 'User form response was successfully created.' }
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
    respond_to do |format|
      if @user_form_response.update(user_form_response_params)
        format.html { redirect_to user_form_user_form_responses_path(@user_form_response.user_form), notice: 'User form response was successfully updated.' }
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
    # Use callbacks to share common setup or constraints between actions.
    def set_user_form_response
      @user_form_response = UserFormResponse.find(params[:id])
    end

    def find_user_form
      @user_form = UserForm.find(params[:user_form_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_form_response_params
      params.require(:user_form_response).permit(:user_form_id, :parent_id, :parent_type, :user_id, :form_data)
    end
end
