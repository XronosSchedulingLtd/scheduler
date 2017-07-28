class CoversController < ApplicationController
  before_action :set_commitment

  class PseudoCommitmentSet < Array
    def show_clashes
      true
    end
  end

  #
  # /commitments/1/coverwith/1.json
  #
  #  Sets a covering commitment for the indicated commitment.  The id
  #  which we are passed indicates the element to do the covering.
  #
  #  If we are passed an id of 0, then that means we are to remove
  #  any existing cover from the commitment.
  #
  #  If an existing cover exists on the commitment then we replace
  #  the covering element (if it differs) rather than creating a new
  #  cover.
  #
  def coverwith
    id = params[:id]
    if id == "0"
      if @commitment.covered
        @commitment.covered.destroy
        @commitment.reload
      end
      to_list = @commitment
    else
      @element = Element.find(id)
      if @commitment.covered
        if @commitment.covered.element != @element
          @commitment.covered.element = @element
          @commitment.covered.save!
        end
        to_list = @commitment.covered
      else
        c = Commitment.create!({
          element:  @element,
          event:    @commitment.event,
          covering: @commitment
        })
        to_list = c
      end
    end
    #
    #  Now need to prepare some replacement HTML to go in the dialogue's
    #  description of locations.
    #
    @pcs = PseudoCommitmentSet.new
    @pcs << to_list
    respond_to do |format|
      format.json
    end
  end

  private

  def set_commitment
    @commitment = Commitment.find(params[:commitment_id])
  end
end
