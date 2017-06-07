class SettingsController < ApplicationController
  before_action :set_setting, only: [:show, :edit, :update]

  # GET /settings/1
  # GET /settings/1.json
  def show
  end

  # GET /settings/1/edit
  def edit
  end

  # PATCH/PUT /settings/1
  # PATCH/PUT /settings/1.json
  def update
    respond_to do |format|
      if @setting.update(setting_params)
        format.html { redirect_to @setting, notice: 'Setting was successfully updated.' }
        format.json { render :show, status: :ok, location: @setting }
      else
        format.html { render :edit }
        format.json { render json: @setting.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_setting
      @setting = Setting.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def setting_params
      params.require(:setting).
             permit(:current_era_id,
                    :next_era_id,
                    :previous_era_id,
                    :perpetual_era_id,
                    :enforce_permissions,
                    :current_mis,
                    :previous_mis,
                    :auth_type,
                    :dns_domain_name,
                    :from_email_address)
    end
end
