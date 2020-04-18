# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
# This controller functions in two distinct ways for two different clients.
#
#  1.  When a user is editing a group he or she can add and remove members,
#      which may cause the implicit creation or deletion of a membership
#      record.  It seldom actually causes a deletion, because the norm
#      is simply to mark the membership as over.
#
#      This controller contains the logic for deciding what exactly to
#      do.
#
#      These requests come in with a type of JS.  The forms used
#      are flagged as :remote.  They come in only two flavours - create
#      and destroy.  We don't even do the :new to go with the :create,
#      because that's handled by the groups controller.
#
#  2.  Suitably privileged users can create, edit and destroy membership
#      records directly.  For this case the controller applies no
#      additional logic - it just does what it was asked, like a standard
#      Rails controller.
#
#      These requests come in with a type of HTML and result in bog-standard
#      HTML responses.
#
#
class MembershipsController < ApplicationController
  prepend_before_action :set_membership, only: [:edit, :update, :destroy, :terminate]
  prepend_before_action :set_group, only: [:new, :create, :index]

  def new
    @membership = @group.memberships.new({
      starts_on: Date.today,
      ends_on:   @group.ends_on
    })
  end

  # POST /memberships
  # POST /memberships.json
  def create
    if request.format.html?
      @membership = @group.memberships.new(membership_params)
      if @membership.save
        redirect_to group_memberships_path(@group)
      else
        render :new
      end
    else
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
  end

  def destroy
    if request.format.html?
      #
      #  An HTML request, which means just do it.
      #  We have already checked the user's permissions.
      #
      @membership.destroy
      #
      #  Don't put the and_save bit on here.  That way we end up
      #  back at the group's membership listing, but our session
      #  should still contain the *previous* group listing path.
      #
      redirect_to group_memberships_path(@membership.group)
    else
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
  end

  def index
    if params[:and_save]
      session[:listing_memberships_from] = request.env['HTTP_REFERER']
    end
    @memberships = @group.memberships.sort
    @show_action_links = current_user.can_edit?(@group)
    if session[:listing_memberships_from]
      @back_link_target = session[:listing_memberships_from]
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @membership.update(membership_params)
        format.html { redirect_to group_memberships_path(@membership.group), notice: 'Membership was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  def terminate
    #
    #  This is just a short cut for editing the membership record and
    #  setting the end date to today.
    #
    if @membership.terminate
      redirect_back fallback_location: root_path
    else
      redirect_back fallback_location: root_path, notice: 'Not a valid end date'
    end
  end

  private

  def authorized?(action = action_name, resource = nil)
    #
    #  Default to no
    #
    result = false
    if known_user? && current_user.can_has_groups?
      #
      #  Further checking depends on the type of the request.
      #
      if request.format.html?
        if current_user.can_edit_memberships?
          case action
          when 'index', 'new', 'create'
            result = current_user.can_edit?(@group)
          when 'edit', 'update', 'destroy', 'terminate'
            result = current_user.can_edit?(@membership.group)
          end
        end
      elsif request.format.js?
        #
        #  Only two possible actions - create and destroy
        #
        case action
        when 'create'
          result = current_user.can_edit?(@group)
        when 'destroy'
          result = current_user.can_edit?(@membership.group)
        end
      end
    end
    result
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_membership
    @membership = Membership.find(params[:id])
  end

  def set_group
    @group = Group.find(params[:group_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def membership_params
    params.require(:membership).permit(:element_id,
                                       :element_name,
                                       :starts_on_text,
                                       :ends_on_text,
                                       :inverse)
  end

end
