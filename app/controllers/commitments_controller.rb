class CommitmentsController < ApplicationController
  before_action :set_commitment, only: [:destroy]

  # POST /commitments
  # POST /commitments.json
  def create
    Rails.logger.debug("Creating a commitment.")
    @commitment = Commitment.new(commitment_params)
    Rails.logger.debug("@commitment.element.owned = #{@commitment.element.owned}")
    Rails.logger.debug("current_user.owns?(@commitment.element) = #{current_user.owns?(@commitment.element)}")
    if @commitment.element.owned &&
       !current_user.owns?(@commitment.element)
      @commitment.tentative = true
      Rails.logger.debug("Set tentative to true.")
    end
    #
    #  Not currently checking the result of this, because regardless
    #  of whether it succeeds or fails, we just display the list of
    #  committed resources again.
    #
    @commitment.save!
    @commitment.reload
    Rails.logger.debug("Commitment.tentative = #{@commitment.tentative}")
    @event = @commitment.event
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @event = @commitment.event
    @commitment.destroy
    respond_to do |format|
      format.js
    end
  end

  private
    def authorized?(action = action_name, resource = nil)
      logged_in? && current_user.create_events?
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_commitment
      @commitment = Commitment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def commitment_params
      params.require(:commitment).permit(:event_id, :element_id, :element_name)
    end
end
