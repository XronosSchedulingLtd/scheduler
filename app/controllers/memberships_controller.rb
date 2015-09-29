class MembershipsController < ApplicationController
  before_action :set_membership, only: [:destroy]

  # POST /memberships
  # POST /memberships.json
  def create
    #
    #  Although this action portrays itself as creating a membership
    #  record, adding a member to a group is actually more complicated
    #  than that, and may or may not involve the creation of a new
    #  membership record.  Uses the method add_member in the Group model
    #  to do the actual work.
    #
    #  An existing group and element need to be specified in order for
    #  this method to achieve anything, but if we don't like the parameters
    #  then we quietly do nothing.  We may do nothing anyway, if for
    #  instance the element is already a member of the group.
    #
    @group = Group.find_by(id: membership_params[:group_id])
    @element = Element.find_by(id: membership_params[:element_id])
    inverse = membership_params[:inverse]
    #
    #  Don't let a group be added to itself.
    #
    if @group && @element && @group.element != @element
      if inverse && inverse == "true"
        @group.add_outcast(@element)
      else
        @group.add_member(@element)
      end
    end
    #
    #  We respond regardless of whether or not we've done anything.
    #  If @group isn't set then we send back an empty snippet of javascript,
    #  otherwise we re-display the group's membership.
    #
    if @group
      @atomic_membership = @group.atomic_membership
    end
    respond_to do |format|
      format.js
    end
  end

  def destroy
    #
    #  This one likewise doesn't work quite the way you might expect.
    #  On the whole, we never actually destroy a membership record, we
    #  just mark it as over.  The only time one goes away is when the
    #  date of destruction is the same as the date of creation.
    #
    if @membership.inverse
      @membership.group.remove_outcast(@membership.element)
    else
      @membership.group.remove_member(@membership.element)
    end
    #
    #  @group needs to be set so that the view can re-render things.
    #
    @group = @membership.group
    @atomic_membership = @group.atomic_membership
    respond_to do |format|
      format.js
    end
  end

  private
    def authorized?(action = action_name, resource = nil)
      logged_in? && current_user.create_groups?
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_membership
      @membership = Membership.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def membership_params
      params.require(:membership).permit(:group_id,
                                         :element_id,
                                         :element_name,
                                         :inverse)
    end
end
