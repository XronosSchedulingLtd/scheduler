# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'csv'

class GroupsController < ApplicationController
  before_action :set_group, only: [:show,
                                   :edit,
                                   :update,
                                   :destroy,
                                   :members,
                                   :do_clone,
                                   :flatten]

  # GET /groups
  # GET /groups.json
  def index
    if current_user.admin && !params[:mine]
      @groups = Group.current.page(params[:page]).order('name')
      @paginate = true
      @separate = false
    else
      @groups = Group.current.belonging_to(current_user).order('name')
      @public_groups, @private_groups = @groups.partition {|g| g.make_public}
      @separate = !(@public_groups.empty? || @private_groups.empty?)
      @paginate = false
    end
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @atomic_membership = @group.atomic_membership
  end

  # GET /groups/new
  def new
    @group = Vanillagroup.new
    @group.era = Setting.current_era
    @group.current = true
  end

  # GET /groups/1/edit
  def edit
    if current_user.can_edit?(@group)
      @membership = Membership.new
      @membership.group = @group
      @exclusion = Membership.new
      @exclusion.group = @group
      @exclusion.inverse = true
      @atomic_membership = @group.atomic_membership
    else
      #
      #  If somebody has got here then they're playing at silly buggers.
      #  Let's not be helpful.
      #
      redirect_to :root
    end
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = Vanillagroup.new(group_params)
#    Rails.logger.debug("Just newed")
#    Rails.logger.debug("new_record? #{@group.new_record?}, persisted? #{@group.persisted?}")
    @group.starts_on ||= Date.today
    @group.owner = current_user

    respond_to do |format|
      if @group.save
#        Rails.logger.debug("Created group")
#        Rails.logger.debug("new_record? #{@group.new_record?}, persisted? #{@group.persisted?}")
        format.html { redirect_to edit_group_path(@group), notice: 'Group was successfully created.' }
        format.json { render :show, status: :created, location: @group }
      else
#        Rails.logger.debug("Failed to create group. id = #{@group.id}")
#        Rails.logger.debug("new_record? #{@group.new_record?}, persisted? #{@group.persisted?}")
        @membership = @group.memberships.new
#        Rails.logger.debug("And failed membership.") unless @membership
        format.html { render :new }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /groups/1/do_clone
  def do_clone
    @new_group = @group.do_clone
    @new_group.owner = current_user
    #
    #  And round to edit it.
    #
    redirect_to edit_group_path(@new_group)
  end

  # POST /groups/1/flatten
  def flatten
    @new_group = @group.do_clone
    @new_group.flatten
    redirect_to edit_group_path(@new_group)
  end

  # PATCH/PUT /groups/1
  # PATCH/PUT /groups/1.json
  def update
    if current_user.can_edit?(@group)
      respond_to do |format|
        if @group.update(group_params)
          format.html { redirect_to groups_path, notice: 'Group was successfully updated.' }
          format.json { render :show, status: :ok, location: @group }
        else
          format.html { render :edit }
          format.json { render json: @group.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to :root
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    if current_user.can_edit?(@group)
      @group.ceases_existence
      respond_to do |format|
        format.html { redirect_to groups_url }
        format.json { head :no_content }
      end
    else
      redirect_to :root
    end
  end

  # GET /groups/1/members
  def members
    #
    #  What we actually do is to produce a listing of all the immediate
    #  members of this group, and explicit exclusions, and then further
    #  listings of all subsidiary groups.
    #
    #  Here we generate an array of groups, starting with this one
    #  and followed by all the ones on which it depends.
    #
    @groups_to_list = @group.influencing_groups
    respond_to do |format|
      format.csv
    end
  end

  private
    def authorized?(action = action_name, resource = nil)
      logged_in? && (current_user.create_groups? || action == 'index')
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def group_params
      params.require(:group).permit(:name,
                                    :era_id,
                                    :current,
                                    :source_id,
                                    :make_public)
    end
end
