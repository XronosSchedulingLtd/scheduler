class UserFormsController < ApplicationController
  before_action :set_user_form, only: [:show, :edit, :update, :destroy]

  autocomplete :user_form, :name, :full => true
  
  # GET /user_forms
  # GET /user_forms.json
  def index
    @user_forms = UserForm.order(:name).page(params[:page])
  end

  # GET /user_forms/1
  # GET /user_forms/1.json
  def show
  end

  # GET /user_forms/new
  def new
    @user_form = UserForm.new
    @include_formbuilder = true
  end

  # GET /user_forms/1/edit
  def edit
    @include_formbuilder = true
  end

  # POST /user_forms
  # POST /user_forms.json
  def create
    local_params = user_form_params
    local_params[:created_by_user] = current_user
    @user_form = UserForm.new(local_params)

    respond_to do |format|
      if @user_form.save
        format.html { redirect_to user_forms_url, notice: 'User form was successfully created.' }
        format.json { render :show, status: :created, location: @user_form }
      else
        format.html { render :new }
        format.json { render json: @user_form.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /user_forms/1
  # PATCH/PUT /user_forms/1.json
  def update
    respond_to do |format|
      local_params = user_form_params
      local_params[:edited_by_user] = current_user
      if @user_form.update(local_params)
        format.html { redirect_to user_forms_url, notice: 'User form was successfully updated.' }
        format.json { render :show, status: :ok, location: @user_form }
      else
        format.html { render :edit }
        format.json { render json: @user_form.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_forms/1
  # DELETE /user_forms/1.json
  def destroy
    @user_form.destroy
    respond_to do |format|
      format.html { redirect_to user_forms_url }
      format.json { head :no_content }
    end
  end

  private
    def authorized?(action = action_name, resource = nil)
      logged_in? &&
      (current_user.admin ||
       current_user.can_has_forms ||
       action == 'autocomplete_user_form_name')
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_user_form
      @user_form = UserForm.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_form_params
      params.require(:user_form).permit(:name, :definition)
    end
end
