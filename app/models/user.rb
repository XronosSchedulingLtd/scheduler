# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class User < ApplicationRecord

  include Permissions

  DWI = Struct.new(:id, :name)
  DaysOfWeek = [DWI.new(0, "Sunday"),
                DWI.new(1, "Monday"),
                DWI.new(2, "Tuesday"),
                DWI.new(3, "Wednesday"),
                DWI.new(4, "Thursday"),
                DWI.new(5, "Friday"),
                DWI.new(6, "Saturday")]

  DECENT_COLOURS = [
                    "#483D8B",      # DarkSlateBlue
                    "#CD5C5C",      # IndianRed
                    "#B8860B",      # DarkGoldenRed (brown)
                    "#7B68EE",      # MediumSlateBlue
                    "#808000",      # Olive
                    "#6B8E23",      # OliveDrab
                    "#DB7093",      # PaleVioletRed
                    "#2E8B57",      # SeaGreen
                    "#A0522D",      # Sienna
                    "#008080",      # Teal
                    "#3CB371",      # MediumSeaGreen
                    "#2F4F4F",      # DarkSlateGray
                    "#556B2F",      # DarkOliveGreen
                    "#FF6347",      # Tomato
                    "#BF1A5B",      # Purpley purple
                    "#126787",      # Slatey dark blue
                    "#112146",      # Really dark blue
                    "#013B05",      # Really dark green
                    "#558068",      # Medium grey green
                    "#B34608",      # Dark terracota
                    "#5F1731"       # Dark magenta
  ]

  FIELD_TITLE_TEXTS = {
    admin:  "Does this user have full control of the system?",
    editor: "Can this user create and edit events within the system?",
    can_repeat_events: "Can this user create repeating events within the system?",
    arranges_cover: "Is this user responsible for arranging cover?",
    secretary: "Does this user enter events on behalf of other people?  Causes the Organizer field on new events to be left blank, rather than being pre-filled with the user's name.",
    edit_all_events: "Can this user edit all events within the system?",
    subedit_all_events: "Can this user sub-edit all events within the system?",
    privileged: "Can this user enter events into the privileged event categories?",
    can_has_groups: "Can this user create and edit groups within the system?",
    can_has_forms: "Can this user create and edit forms within the system?",
    public_groups: "Can this user create publicly visible groups?",
    can_find_free: "Can this user do searches for free resources?",
    can_add_concerns: "Can this user dynamically choose which schedules to look at?",
    can_roam: "Can this user follow links from one displayed element to another?",
    can_su: "Can this user become another user?",
    exams: "Does this user administer exams or invigilation?",
    can_relocate_lessons: "Can this user relocate lessons in general - not just his or her own?",
    show_pre_requisites: "Do you want to be prompted for likely requirements when creating new events?",
    can_add_resources: "Can this user add resources to events?",
    can_add_notes: "Can this user add notes to events?",
    can_view_forms: "Can this user view all the forms attached to an event?",
    can_view_unconfirmed: "Can this user see events in the context of resources which have not yet been confirmed for the event?",
    can_edit_memberships: "Can this user edit membership records directly, rather than implicitly by editing the group?",
    can_api: "Can this user make direct use of the API?",
    can_has_files: "Can this user upload files to the server?",
    can_view_journals: "Can this user view the modification journal for events?",
    can_make_shadows: "Can this user set the shadow flag when editing events?"
  }
  FIELD_TITLE_TEXTS.default = ""

  serialize :suppressed_eventcategories, Array
  serialize :extra_eventcategories,      Array
  serialize :permissions,                ShadowPermissionFlags

  has_many :concerns,            dependent: :destroy
  has_many :concern_sets,        dependent: :destroy, foreign_key: :owner_id
  has_many :user_form_responses, dependent: :destroy
  has_many :user_files,          dependent: :destroy, foreign_key: :owner_id

  has_many :events, foreign_key: :owner_id, dependent: :nullify

  has_many :event_collections, foreign_key: :requesting_user_id, dependent: :nullify

  has_many :controlled_commitments,
           class_name: "Commitment",
           foreign_key: "by_whom_id",
           dependent: :nullify

  has_many :messages, class_name: 'Ahoy::Message', as: :user
  has_many :comments, dependent: :destroy
  belongs_to :preferred_event_category, class_name: Eventcategory
  belongs_to :day_shape, class_name: RotaTemplate
  belongs_to :corresponding_staff, class_name: "Staff"
  belongs_to :user_profile
  belongs_to :current_concern_set, class_name: "ConcernSet"

  #
  #  The only elements we can actually own currently are groups.  By creating
  #  a group with us as the owner, its corresponding element will also be
  #  marked as having us as the owner.  Should this user ever be deleted
  #  the owned groups will also be deleted, and thus the elements will go
  #  too.
  #
  has_many :elements, foreign_key: :owner_id
  has_many :groups,   foreign_key: :owner_id, :dependent => :destroy
  has_many :notes,    foreign_key: :owner_id, :dependent => :destroy

  validates :firstday, :presence => true
  validates :firstday, :numericality => true

  validates :user_profile, :presence => true

  validates :uuid, uniqueness: true

  scope :arranges_cover, lambda { where("arranges_cover = true") }
  scope :element_owner, lambda { where(:element_owner => true) }
  scope :editors, lambda { where(editor: true) }
  scope :exams, lambda { where(exams: true) }
  scope :administrators, lambda { where(admin: true) }
  scope :demo_user, lambda { where(demo_user: true) }
  scope :known, -> { where(known: true) }
  scope :guest, -> { where(known: false) }

  before_create :add_uuid
  before_destroy :being_destroyed
  before_save :update_from_profile

  self.per_page = 15

  def staff?
    self.corresponding_staff != nil
  end

  def pupil?
    self.own_element != nil && self.own_element.entity.class == Pupil
  end

  def guest?
    !self.known?
  end

  #
  #  Returns some text describing the type of user.
  #
  def type_text
    if self.own_element == nil
      "Guest"
    else
      self.own_element.entity_type
    end
  end

  def own_element
    unless @checked_own_element
      my_own_concern = self.concerns.me[0]
      if my_own_concern
        @own_element = my_own_concern.element
      else
        @own_element = nil
      end
      @checked_own_element = true
    end
    @own_element
  end

  def concern_with(element)
    possibles = self.concerns.default_view.concerning(element)
    if possibles.size == 1
      possibles[0]
    else
      nil
    end
  end

  def name_with_email
    "#{self.name} (#{self.email})"
  end

  #
  #  Could be made more efficient with an explicit d/b hit, but probably
  #  not worth it as each user is likely to own only a small number
  #  of elements.
  #
  #  item can be an element or an event.
  #
  def owns?(item)
    if item.instance_of?(Element)
      !!concerns.owned.detect {|c| (c.element_id == item.id)}
    elsif item.instance_of?(Event)
      item.owner_id == self.id
    else
      false
    end
  end

  #
  #  Used to decide whether we are controller of some kind of grouped
  #  resource.  We are passed an individual item (which is controlled)
  #  and we need to decide whether this user is a controller of the group
  #  to which this item belongs.
  #
  def owns_parent_of?(element)
    #
    #  Today's date, and don't recurse.
    #
    element.groups(nil, false).each do |group|
      if self.owns?(group.element)
        return true
      end
    end
    return false
  end

  #
  #  Can this user meaningfully see the menu in the top bar?
  #
  def sees_menu?
    self.known? &&
    (self.admin ||
     self.editor ||
     self.can_has_groups ||
     self.can_find_free ||
     self.element_owner ||
     self.exams)
  end

  #
  #  Called when one of our concerns has changed/gone.
  #
  def concern_changed(destroyed, concern)
    #
    #  If we are going ourselves, then don't bother.
    #
    unless @being_destroyed || self.destroyed?
      #
      #  If the concern has been destroyed.
      #
      if destroyed
        do_save = false
        #
        #  The concern has gone away.
        #
        if self.concerns.owned.count == 0
          self.element_owner = false
          do_save = true
        end
        #
        #  It might have been our corresponding staff member.
        #
        if concern.equality
          element = concern.element
          if element && element.entity == self.corresponding_staff
            self.corresponding_staff = nil
            reset_cache
            do_save = true
          end
        end
      else
        #
        #  The concern has merely been updated (or indeed, created)
        #
        if concern.owns?
          unless self.element_owner = true
            self.element_owner = true
            do_save = true
          end
        else
          if self.concerns.owned.count == 0
            self.element_owner = false
            do_save = true
          end
        end
        if concern.equality
          #
          #  Might need to set it as our corresponding staff member
          #
          unless self.corresponding_staff
            element = concern.element
            if element && element.entity_type == 'Staff'
              self.corresponding_staff = concern.element.entity
              do_save = true
            end
          end
        else
          #
          #  Might need to remove it as our corresponding staff member
          #
          element = concern.element
          if element && element.entity == self.corresponding_staff
            self.corresponding_staff = nil
            do_save = true
          end
          reset_cache
        end
      end
      if do_save
        self.save!
      end
    end
  end

  def free_colour(selector = nil)
    #
    #  I always specify colours in upper case, but it's possible that
    #  the user has entered one through the front end in lower case.
    #
    selector ||= self.concerns
    in_use = selector.collect {|i| i.colour ? i.colour.upcase : "dummy"}
    available = DECENT_COLOURS - in_use
    if available.size > 0
      available[0]
    else
      #
      #  Try and generate one.  Take care not to try forever.
      #
      100.times do |n|
        attempt = random_colour
        if !in_use.include?(attempt)
          return attempt
        end
      end
      "Gray"
    end
  end

  def field_title_text(field)
    #
    #  Note that the keys are exactly the names of the columns within
    #  the d/b record.
    #
    FIELD_TITLE_TEXTS[field]
  end

  def self.field_title_text(field)
    #
    #  Note that the keys are exactly the names of the columns within
    #  the d/b record.
    #
    FIELD_TITLE_TEXTS[field]
  end

  def list_days
    DaysOfWeek
  end

  def create_events?
    self.known? && self.editor?
  end

  def can_trigger_cover_check?
    self.arranges_cover
  end

  #
  #  What elements give us additional edit permissions?  This can
  #  be either full edit or sub-edit permission, but we cache them
  #  both at the same time because if we're being asked about one
  #  then we will almost certainly be asked about the other.
  #
  #  If both bits are set for an element, then put it in the more
  #  privileged set.
  #
  #  Note that only concerns in our default set can confer permissions.
  #  Any other sets are used purely for display purposes.
  #
  def ensure_elements_cache
    unless @elements_giving_edit && @elements_giving_subedit
      with_edit, with_subedit = self.concerns.
                                     default_view.
                                     includes(:element).
                                     either_edit_flag.
                                     partition {|c| c.edit_any}
      @elements_giving_edit = with_edit.collect {|c| c.element}
      @elements_giving_subedit = with_subedit.collect {|c| c.element}
    end
  end

  def elements_giving_edit
    ensure_elements_cache
    @elements_giving_edit
  end

  def elements_giving_subedit
    ensure_elements_cache
    @elements_giving_subedit
  end

  #
  #  Similarly, what elements do we own.
  #
  #  Owning means we approve requests to use it.  Confusingly, this appears
  #  as "controls" in the user interface.
  #
  def owned_elements
    unless @owned_elements
      @owned_elements =
        self.concerns.owned.includes(element: :entity).collect {|c| c.element}
    end
    @owned_elements
  end

  #
  #  A subset of owned elements.  Elements which we own and which can have
  #  requests made on them.
  #
  def owned_resources
    unless @owned_resources
      #
      #  Call the function to make the most of our cache.
      #
      @owned_resources =
        self.owned_elements.select {|oe| oe.can_have_requests?}
    end
    @owned_resources
  end

  def resource_owner?
    !self.owned_resources.empty?
  end

  #
  #  Can this user edit the indicated item?
  #
  def can_edit?(item)
    if item.instance_of?(Event)
      self.admin ||
      self.edit_all_events? ||
      item.id == nil ||
      (self.create_events? && item.owner_id == self.id) ||
      (self.create_events? && item.involves_any?(self.elements_giving_edit, true))
    elsif item.instance_of?(Group)
      self.admin ||
      (self.can_has_groups? &&
       item.owner_id == self.id &&
       item.user_editable?)
    elsif item.instance_of?(Concern)
      (item.user_id == self.id) || self.admin
    elsif item.instance_of?(Note)
      (item.owner_id == self.id ||
       (item.parent_type == "Commitment" && self.owns?(item.parent.element))) &&
       !item.read_only
    elsif item.instance_of?(Promptnote)
      self.owns?(item.element)
    else
      false
    end
  end

  #
  #  Basically, can the user edit the event, plus if the event is locked
  #  is the user one of the privileged few?
  #
  def can_edit_body_of?(event)
    self.can_edit?(event) &&
      (!event.locked? || self.can_override_locking_of?(event))
  end

  #
  #  Firstly the user must have the relevant permission bit, but also
  #  he might not be able to if the event is locked.
  #
  def can_beshadow?(event)
    self.can_make_shadows? &&
      (!event.locked? || self.can_override_locking_of?(event))
  end

  #
  #  Currently, sub-editing applies only to events and requests.
  #  You can sub-edit if you are the organizer of the event.
  #
  def can_subedit?(item)
    case item
    when Event
      self.can_edit?(item) ||
        self.subedit_all_events? ||
        self.organiser_of?(item) ||
        (self.create_events? &&
         item.involves_any?(self.elements_giving_subedit, true))
    when Request
      #
      #  Do a recursive call on ourselves, if possible.
      #
      event = item.event
      if event
        self.can_subedit?(event)
      else
        false
      end
    else
      false
    end
  end

  #
  #  Can this user set up a repeat for the event.
  #  Currently just needs (at least) sub-edit permission, plus
  #  the general repeat privilege bit.
  #
  def can_repeat?(event)
    self.can_repeat_events? &&
      self.can_subedit?(event) &&
      event.can_be_repeated?
  end

  #
  #  Slightly lesser check.  Could this user repeat the indicated
  #  event, even if just at this moment he can't.
  #
  def could_repeat?(event)
    self.can_repeat_events? &&
      self.can_subedit?(event) &&
      event.could_be_repeated?
  end

  #
  #  Can this user relocate the indicated event - that is, can he or
  #  she allocate another room to the event in the fashion of allocating
  #  a cover teacher?
  #
  #  Requirements:
  #
  #  * It's a system owned event (effectively a lesson)
  #  * It has a single room directly allocated.
  #  * Either:
  #    * User has the can_relocate_lessons flag set
  #    * User is the member of staff teaching the lesson
  #  * A room cover group element has been configured
  #
  def can_relocate?(event)
    if !event.owner &&
      event.direct_locations.count == 1 &&
      (self.can_relocate_lessons ||
       event.staff_entities.include?(self.corresponding_staff)) &&
      Setting.room_cover_group_element
      true
    else
      false
    end
  end

  def organiser_of?(event)
    staff = self.corresponding_staff
    staff && staff.element && (staff.element.id == event.organiser_id)
  end

  def can_override_locking_of?(event)
    #
    #  For a locked event, see whether there are any locking
    #  commitments which we don't have control over.  If there
    #  are, then we can't override the locking.
    #
    event.commitments.
          includes(element: :entity).
          firm.
          select { |c|
            c.locking? && !self.can_delete?(c)
          }.empty?
  end

  #
  #  Can this user delete the indicated item?
  #  We can only delete our own, and sometimes not even then.
  #
  def can_delete?(item)
    if item.instance_of?(Concern)
      #
      #  If you can't add concerns, then you can't delete them either.
      #  You get what you're given.
      #
      #  Admins can do what they like to other people's concerns.
      #  (As a possible slight oddity, when dealing with his own concerns
      #  the admin is as constrained as a non-admin.  This is intentional.)
      #
      if item.user_id == self.id
        self.can_add_concerns && item.user_can_delete?
      else
        self.admin?
      end
    elsif item.instance_of?(Note)
      #
      #  You can delete the ones you own, provided they're attached
      #  to events and you have note creation permission.
      #  If they're attached to commitments, you have to
      #  delete the commitment instead.
      #
      item.owner_id == self.id &&
      item.parent_type == "Event" &&
      self.can_add_notes?
    elsif item.instance_of?(Commitment)
      #
      #  With edit permission you can generally delete a commitment
      #  (the exception being if it was allocated via a request)
      #  but there are two cases which a sub-editor cannot delete.
      #
      #  1. An approved commitment (constraining == true)
      #  2. A commitment to a managed element which seems to have
      #     skipped the approvals process entirely.  None of
      #     tentative, rejected or constraining is set.
      #
      event = item.event
      element = item.element
      if event && element
        if item.request.nil?
          if self.can_edit?(event) ||
               (self.can_subedit?(event) &&
                !item.constraining? &&
                !(element.owned? && item.uncontrolled?))
            #
            #  Looking hopeful, but is it a locking commitment?
            #  We can render this slightly more efficient by checking
            #  the event first.  It has a simple flag to say whether it
            #  is locked or not, and if it is not locked then there
            #  isn't a problem.  Checking the item is more expensive.
            #
            if event.locked? && item.locking?
              #
              #  Yes.  In this case we impose a further requirement that
              #  the user is either a controller of the resource, or
              #  at least has the "skip_permissions" flag for that resource.
              #
              #  Or, in other words, to be able to delete the commitment
              #  you need to be able to create it without assistance.
              #
              self.could_commit?(element)
            else
              true
            end
          else
            false
          end
        else
          false
        end
      else
        #
        #  Doesn't seem to be a real commitment yet.
        #
        false
      end
    elsif item.instance_of?(Request)
      #
      #  can_subedit? can cope with a nil parameter.
      #
      self.can_subedit?(item.event)
    elsif item.instance_of?(Comment)
      (item.user_id == self.id) || self.admin?
    elsif item.instance_of?(Event)
      if self.can_edit?(item)
        #
        #  In principle, yes, but it might be locked
        #  in which case we need to be more privileged.
        #
        !item.locked? || self.can_override_locking_of?(item)
      else
        false
      end
    elsif item.instance_of?(UserFile)
      self.admin? || self.id == @user_file.owner_id
    else
      false
    end
  end

  #
  #  And specifically for events, can the user re-time the event?
  #  Sometimes users can edit, but not re-time.
  #
  #  Note that can_retime? is relatively expensive and used to
  #  enable/disable the dialogue box fields.  can_drag_timing? is
  #  cheaper, but will sometimes disallow it when can_retime? will
  #  allow it.  This is intentional.
  #
  def can_retime?(event)
    can_retime = false
    if event.id == nil || self.admin || self.edit_all_events?
      can_retime = true
    elsif self.can_edit?(event)
      if event.constrained?
        if event.locked?
          can_retime = self.can_override_locking_of?(event)
        else
          #
          #  We could at this point work out whether the user is
          #  a controller of all the constraining resources, in which
          #  case he or she could retime the event.
          #
          #  For now, those who acquire edit privilege via one of the
          #  resources can retime it.
          #
          can_retime = event.involves_any?(self.elements_giving_edit, true)
        end
      else
        can_retime = true
      end
    end
    can_retime
  end

  def can_drag_timing?(event)
    if self.admin || self.edit_all_events?
      can_drag_timing = true
    elsif self.create_events? &&
          event.owner_id == self.id &&
          !event.event_collection
      can_drag_timing = !event.constrained
    else
      can_drag_timing = false
    end
    can_drag_timing
  end

  def confidentiality_elements
    unless @confidentiality_elements
      @confidentiality_elements =
        #
        #  We want a list of all the elements which we are either
        #  equal to, or assistant to.
        #
        self.concerns.
             select { |c| c.equality? || c.assistant_to? }.
             collect {|c| c.element_id}
    end
    @confidentiality_elements
  end

  #
  #  A user can see the body of a confidential event if:
  #
  #  * He or she owns the event
  #  * He or she is invited to the event
  #  * He or she has a suitable link to an invitee.
  #
  #  Two evaluate those last two, we keep a cache of the elements
  #  which we are linked to by concerns which have either the
  #  "identity" (this is me) or "pa_to" flags set.
  #
  #  We need just a cache of the element ids, and we compare those
  #  to the elements attached to the event.
  #
  #  Note that currently you need a *direct* attachment to the event
  #  to see the body text.  Being attached via a group will not do.
  #
  def can_see_body_of?(event)
    !event.confidential? ||
    event.owner_id == self.id ||
    (
      event.commitments.detect { |c|
        confidentiality_elements.include?(c.element_id)
      } != nil
    )
  end

  #
  #  Does this user have appropriate permissions to approve/decline
  #  the indicated commitment?
  #
  def can_approve?(commitment)
    self.owns?(commitment.element)
  end

  #
  #  Can the user allocate (and de-allocate) actual resources to a
  #  current request?  This is dictated by the resource to which the
  #  request relates.
  #
  def can_allocate_to?(request)
    self.owns?(request.element)
  end

  #
  #  Can this user create a firm commitment for this element?  Note
  #  that this is slightly different from being able to approve a
  #  commitment.  Some users can bypass permissions, but don't actually
  #  have authority for approvals.
  #
  #  Takes account of whether the user has temporarily turned off
  #  his or her permission by setting the seek_permission bit.
  #
  def can_commit?(element)
    !!concerns.can_commit.detect {|c| (c.element_id == element.id)}
  end

  #
  #  *Could* this user commit, if he or she had not fiddled with
  #  the seek_permission bit.
  #
  def could_commit?(element)
    !!concerns.could_commit.detect {|c| (c.element_id == element.id)}
  end

  #
  #  Can this user complete forms for the indicated event?  Basically,
  #  is he either the owner or the organiser?
  #
  def can_complete_forms_for?(event)
    event.owner_id == self.id ||
      (self.corresponding_staff &&
       self.corresponding_staff.element == event.organiser)
  end

  def can_view_forms_for?(element)
    self.known? && (self.can_view_forms? || self.owns?(element))
  end

  def can_view_journal_for?(object)
    self.can_view_journals?
    #
    #  For now it's just the admin users, but we may add more fine-grained
    #  control later.
    #
#    if object.instance_of?(Element)
#      self.admin
#    elsif object.instance_of?(Event)
#      self.admin
#    elsif object == :elements
#      self.admin
#    elsif object == :events
#      self.admin
#    else
#      false
#    end
  end

  def can_add_comments_to?(item)
    if item.instance_of?(UserFormResponse)
      #
      #  UserFormResponse is attached to Commitment or Request.
      #  Are we an admin of the corresponding element?
      #
      self.admin || self.owns?(item.parent.element)
    else
      false
    end
  end

  #
  #  Can this user drag this concern onto the schedule?
  #
  def can_drag?(concern)
    (self.can_add_resources? || self.own_element == concern.element) &&
      #
      #  Things which have the add_directly? flag unset can only
      #  be dragged by their individual administrators.
      #
    (concern.element.add_directly? || self.owns_parent_of?(concern.element))
  end

  def can_upload_with_figures?
    if can_has_files?
      allowance = Setting.user_file_allowance
      total_size = self.user_files.inject(0) {|sum, uf| sum + uf.file_size}
      result = total_size < allowance
      return result, total_size, allowance
    else
      return false, 0, 0
    end
  end

  def can_upload?
    #
    #  Just the first value returned by the previous function.
    #
    can_upload_with_figures?[0]
  end

  #
  #  Does this user need permission to create a commitment for this
  #  element?
  #
  #  Are permissions switched on globally?
  #  Is there an owner for this resource?
  #  Does this particular user need permission OR is there a form to
  #  fill in?
  #
  #  Even users with permission need to go through the process if there
  #  is a form.
  #
  def needs_permission_for?(element)
    Setting.enforce_permissions? && element.owned &&
    (!self.can_commit?(element) || element.user_form)
  end

  #
  #  Is this user as privileged (in the admin-ey sense) as another
  #  user?
  #
  #  Although this method is invoked by the view code it is arguably
  #  useless there because currently if a user isn't an admin then he or she
  #  can't access the relevant user listing pages anyway.
  #
  #  We may however choose to add a specific path which allows a
  #  user with "can_su?" privileges to make use of them.
  #
  def as_privileged_as?(other_user)
    #
    #  Only one case which fails - when we are not an admin but
    #  the other user is.
    #
    #  Could be written as:
    #
    #    !(!self.admin? && other_user.admin?)
    #
    #  but that simplifies to:
    #
    self.admin? || !other_user.admin?
  end

  #
  #  Another thing which it is useful to cache for efficiency.
  #
  def owned_concerns
    unless @owned_concerns
      if self.element_owner
        @owned_concerns = self.concerns.owned.preload(:element).to_a
      else
        @owned_concerns = []
      end
    end
    @owned_concerns
  end
  #
  #  Another one to cache because it is needed a lot.
  #
  def permissions_pending
    unless @permissions_pending
      @permissions_pending = self.owned_concerns.inject(0) do |total, concern|
        total + concern.permissions_pending
      end
    end
    @permissions_pending
  end

  #
  #  This should be a count of the events which *this user* can do
  #  something about.  Being incomplete is not enough - they need to
  #  be rejected or "noted", or have pending forms.
  #
  #  Not really interested in ones in the past.
  #
  #  We are also interested in pending forms for events where we are
  #  the organiser, but not the owner.
  #
  def events_pending
    unless @events_pending
      staff = self.corresponding_staff
      if staff && staff.active
        selector = Event.where("owner_id = ? OR organiser_id = ?",
                               self.id,
                               staff.element.id)
      else
        selector = self.events
      end
      @events_pending =
        selector.future.
                 incomplete.
                 includes([commitments: [:element, :user_form_response],
                           requests: [:element, :user_form_response]]).
                 inject(0) do |total, event|
        count = 0
        event.commitments.each do |c|
          #
          #  If the event has been rejected, then we count that
          #  as 1, but we don't go on and count the corresponding
          #  forms as well.  If we do then it gets confusing.
          #  A rejected event, with a pending form (which it will
          #  be because the action of rejecting the event causes
          #  the form to be marked as pending) would get counted as 2.
          #
          if c.rejected? || c.noted?
            unless c.element.a_person?
              count += 1
            end
          else
            #
            #  Count incomplete forms *unless* the commitment has
            #  been approved.  It's possible that a commitment
            #  with an incomplete form gets approved, in which case
            #  the requester can no longer edit it.
            #
            if c.tentative?
              count += c.incomplete_ufr_count
            end
          end
        end
        event.requests.each do |r|
          if r.tentative?
            count += r.incomplete_ufr_count
          end
        end
        total + count
      end
    end
    @events_pending
  end

  #
  #  How many future events does this user have waiting for approval(s).
  #  I.e. not something this user can do anything about, but where
  #  he or she is waiting on someone else.
  #
  def events_waiting
    unless @events_waiting
      @events_waiting =
        self.events.
             future.
             incomplete.
             includes(commitments: :user_form_response).
             inject(0) do |total, event|
        count = 0
        event.commitments.each do |c|
          if !c.rejected?
            #
            #  Are all forms complete?
            #
            if c.user_form_response == nil ||
               c.user_form_response.complete?
              count += 1
            end
          end
        end
        total + count
      end
    end
    @events_waiting
  end

  def events_pending_total
    unless @events_pending_total
      @events_pending_total = permissions_pending + events_pending
    end
    @events_pending_total
  end

  #
  #  This function might appear at first sight to be redundant.  It's
  #  simply calling events_pending_total() and caching the result.
  #  However, we might in the future want to add other pending
  #  requests not relating to events.
  #
  #  That would result in this one calling whatever_pending_total
  #  as well, adding the two together and caching that result.
  #
  #  Leave it in.
  #
  def pending_grand_total
    unless @pending_grand_total
      @pending_grand_total = events_pending_total
    end
    @pending_grand_total
  end

  def start_auto_polling
    self.element_owner || self.events_waiting > 0
  end

  def events_on(start_date = nil,
                end_date = nil,
                eventcategory = nil,
                eventsource = nil,
                include_nonexistent = false)
    Event.events_on(start_date,
                    end_date,
                    eventcategory,
                    eventsource,
                    nil,
                    self,
                    include_nonexistent)
  end

  def find_matching_resources
    if self.email && !self.known?
      got_something = false
      if Setting.auth_type == "google_demo_auth"
        staff = Staff.first
      else
        staff = Staff.active.current.find_by_email(self.email)
      end
      if staff
        got_something = true
        self.user_profile = UserProfile.staff_profile
        concern = self.concern_with(staff.element)
        if concern
          unless concern.equality
            concern.equality = true
            concern.save!
          end
        else
          self.concerns.create!({
            element:  staff.element,
            equality: true,
            owns:     false,
            visible:  true,
            auto_add: true,
            colour:   "#225599"
          })
        end
      else
        #
        #  Look for a pupil record only if we've failed to
        #  find a staff one.  It's just possible that both exist,
        #  but staff get more privileges, and they can always
        #  choose to look at the corresponding pupil record
        #  if they want to.
        #
        pupil = Pupil.current.find_by_email(self.email)
        if pupil
          got_something = true
          self.user_profile = UserProfile.pupil_profile
          concern = self.concern_with(pupil.element)
          if concern
            unless concern.equality
              concern.equality = true
              concern.save!
            end
          else
            self.concerns.create!({
              element:  pupil.element,
              equality: true,
              owns:     false,
              visible:  true,
              auto_add: true,
              colour:   "#225599"
            })
          end
        end
      end
      if got_something
        #
        #  By default, each user gets the public calendars displayed.
        #  Students can't remove them (although they can suppress them).
        #
        if staff
          selector = Property.for_staff
        elsif pupil
          selector = Property.for_pupils
        else
          selector = Property.none
        end
        selector.each do |p|
          unless self.concern_with(p.element)
            self.concerns.create!({
              element:  p.element,
              equality: false,
              owns:     false,
              visible:  true,
              colour:   p.element.preferred_colour || "green"
            })
          end
        end
        #
        #  Set this user's day shape to the system default.
        #  He or she might choose to change it later.
        #
        self.day_shape = Setting.default_display_day_shape
        #
        #  Small frig for the demo system only.
        #
        if Setting.demo_system? && self.email == "jhwinters@gmail.com"
          self.permissions[:admin] = true
        end
        self.save!
      end
    end
  end

  #
  #  Create a new user record to match an omniauth authentication.
  #
  #  Anyone can have a user record, but only people with some sort
  #  of Staff or Pupil record get futher than that.
  #
  def self.create_from_omniauth(auth)
    new_user = create! do |user|
      user.provider = auth["provider"]
      user.uid      = auth["uid"]
      user.name     = auth["info"]["name"]
      user.email    = auth["info"]["email"].downcase
      user.user_profile = UserProfile.guest_profile
    end
    new_user.find_matching_resources
    new_user
  end

  def initials
    if self.corresponding_staff
      self.corresponding_staff.initials
    elsif self.pupil?
      "Pupil"
    else
      "UNK"
    end
  end

  #
  #  Retrieve our firstday value, coercing it to be meaningful.
  #
  def safe_firstday
    if self.firstday >=0 && self.firstday <= 6
      self.firstday
    else
      0
    end
  end

  #
  #  Similar, but only a general interest.
  #
  def to_view(element_or_name, visible = false)
    if element_or_name.instance_of?(Element)
      element = element_or_name
    else
      element = Element.find_by(name: element_or_name)
    end
    if element
      concern = self.concern_with(element)
      if concern
        #
        #  Already has a concern.  Just make sure the colour is right.
        #
        if element.preferred_colour &&
           concern.colour != element.preferred_colour
          concern.colour = element.preferred_colour
          concern.save!
          "Adjusted colour of #{element.name} for #{self.name}."
        else
          ""
        end
      else
        concern = Concern.new
        concern.user    = self
        concern.element = element
        concern.equality = false
        concern.owns     = false
        concern.visible  = visible
        concern.colour   = element.preferred_colour || self.free_colour
        concern.auto_add = false
        concern.edit_any = false
        concern.save!
        "User #{self.name} now viewing #{element.name}."
      end
    else
      "Can't find element #{element_or_name} for #{self.name} to view."
    end
  end

  def filter_state
    (self.suppressed_eventcategories.empty? &&
     self.extra_eventcategories.empty?) ? "off" : "on"
  end

  #
  #  Fix all users who are students so that they have a concern with
  #  themselves and the calendar, and no others.
  #
  def self.fix_students
    results = Array.new
    calendar_element = Element.find_by(name: "Calendar")
    if calendar_element
      User.all.each do |u|
        e = u.own_element
        if e && e.entity.class == Pupil
          results << "Processing #{e.name}"
          u.concerns.each do |c|
            if c.element != e
              results << "Removing concern with #{c.element.name}"
              c.destroy
            end
          end
          u.to_view(calendar_element, true)
        end
      end
    else
      results << "Unable to find Calendar element."
    end
    results.each do |text|
      puts text
    end
    nil
  end

  #
  #  Maintenance methods to populate the newly created "corresponding_staff"
  #  field.
  #
  #
  def set_corresponding_staff
    unless self.corresponding_staff
      self.concerns.me.each do |concern|
        if concern.element.entity_type == "Staff"
          self.corresponding_staff = concern.element.entity
          self.save!
        end
      end
    end
  end

  #
  #  Maintenance method to fix a user who is linked to the wrong member
  #  of staff record.
  #
  def set_right_staff
    own_concern = self.concerns.me[0]
    if own_concern
      if own_concern.element.current
        puts "#{self.name} already linked to current element."
      else
        staff = Staff.active.current.find_by(email: self.email)
        if staff
          puts "Found a current staff member for #{self.email}"
          own_concern.element = staff.element
          own_concern.save!
          self.corresponding_staff = staff
          self.save!
          puts "Updated user record."
        else
          puts "No current staff member for #{self.email}"
        end
      end
    else
      "#{self.email} has no \"me\" concern."
    end
    nil
  end


  def self.populate_corresponding_staff
    User.all.each do |u|
      u.set_corresponding_staff
    end
    nil
  end

  #
  #  For populating the new resource and note flags from existing
  #  fields.
  #
  def populate_resource_and_note_flags
    self.can_add_resources = self.editor?
    unless self.can_add_resources?
      #
      #  If this user can't add resources, then he'd better auto-add
      #  himself.
      #
      own_concern = self.concerns.me[0]
      if own_concern
        own_concern.auto_add = true
        own_concern.save!
      end
    end
    self.can_add_notes     = self.staff?
    self.save!
  end

  def self.populate_resource_and_note_flags
    User.all.each do |u|
      u.populate_resource_and_note_flags
    end
    nil
  end

  #
  #  Each time the user record is saved we update the legacy permission
  #  flags (those used at run-time to decide permissions) with a calculated
  #  value from the profile and new permission flags.
  #
  #  We also check whether our profile is a "known" one.
  #
  def update_from_profile
    PermissionFlags.permitted_keys.each do |pk|
      if self.permissions[pk] == PermissionFlags::PERMISSION_DONT_CARE
        value = self.user_profile.permissions[pk]
      else
        value = self.permissions[pk]
      end
      if value == PermissionFlags::PERMISSION_NO
        if self[pk]
          self[pk] = false
        end
      elsif value == PermissionFlags::PERMISSION_YES
        unless self[pk]
          self[pk] = true
        end
      else
        Rails.logger.debug("Calculated permission value for #{pk} for #{self.name} is #{value}")
      end
    end
    if self.user_profile
      self.known = self.user_profile.known
    end
    true
  end

  #
  #  Called to tell us that our user profile has been updated.
  #  A dummy save should be enough to get our flags updated.
  #
  def user_profile_updated
    self.save
  end

  #
  #  These next two are intended solely for use when migrating an existing
  #  system to having user profiles.  They will convert existing users.
  #
  #  TODO: Take account of any extra privilege bits the user might
  #  already have.
  #
  def link_to_profile
    if self.staff?
      self.user_profile = UserProfile.staff_profile
    elsif self.pupil?
      self.user_profile = UserProfile.pupil_profile
    else
      self.user_profile = UserProfile.guest_profile
    end
    PermissionFlags.permitted_keys.each do |pk|
      current_flag_value = self[pk]
      profile_value = self.user_profile.permissions[pk]
      if current_flag_value &&
         profile_value != PermissionFlags::PERMISSION_YES
        self.permissions[pk] = PermissionFlags::PERMISSION_YES
      elsif !current_flag_value &&
            profile_value != PermissionFlags::PERMISSION_NO
        self.permissions[pk] = PermissionFlags::PERMISSION_NO
      else
        self.permissions[pk] = PermissionFlags::PERMISSION_DONT_CARE
      end
    end
    self.save!
  end

  def self.link_to_profiles
    UserProfile.ensure_basic_profiles
    User.all.each do |u|
      u.link_to_profile
    end
    nil
  end

  def improve_colours
    changed_count = 0
    self.concerns.each do |c|
      if c.colour == "Gray"
        c.colour = free_colour
        c.save
        changed_count += 1
      end
    end
    if changed_count > 0
      return "Modified #{changed_count} colours for #{self.name}."
    else
      return nil

    end
  end

  #
  #  Client code is not allowed to modify uuid.
  #
  def uuid=(value)
  end

  #
  #  But it is allowed to pass in an initial UUID to use.
  #
  #  We will only use it if we don't already have something
  #  and it doesn't cause a clash.
  #
  def initial_uuid=(value)
    @initial_uuid = value
  end

  #
  #  This method is called as the element record is about to be
  #  created in the database.
  #
  def add_uuid
    #
    #  In theory we shouldn't get here if the record isn't valid, but...
    #
    if self.valid?
      generate_initial_uuid
      #
      #  This seems really stupid, but surely we should have some
      #  code to cope with the possibility of a clash?
      #
      #  I don't want a loop in case of a coding error which means
      #  it turns into an endless loop.
      #
      #  If after a second attempt our record is still invalid
      #  (meaning the uuid is still clashing with one already in
      #  the database) then the create!() (invoked from elemental.rb)
      #  will throw an error and the creation of the underlying
      #  element will be rolled back.  On the other hand, if you're
      #  that unlucky you're not going to live much longer anyway.
      #
      #  Note that by this point, the automatic Rails record validation
      #  has already been performed, and won't be performed again.
      #  The only thing which is going to stop the save succeeding
      #  is an actual constraint on the database - which is there.
      #
      #  This will also cope with the case where a caller has passed
      #  in an initial UUID, but it's not unique.  We will go on
      #  and generate a unique one.
      #
      unless self.valid?
        generate_uuid
      end
    end
  end

  def self.generate_uuids
    self.find_each do |user|
      if user.uuid.blank?
        user.generate_initial_uuid
        user.save!
      end
    end
    nil
  end

  #
  #  This one is public, but won't overwrite an existing uuid.
  #
  def generate_initial_uuid
    if self.uuid.blank?
      if @initial_uuid.blank?
        generate_uuid
      else
        write_attribute(:uuid, @initial_uuid)
      end
    end
  end

  protected

  def being_destroyed
    @being_destroyed = true
  end

  #
  #  Reset all the things which we keep cached.
  #
  def reset_cache
    @checked_own_element = false
    @own_element = nil
  end

  #
  #  Generate a random colour, reasonably dark.
  #
  def random_colour
    loop do
      red_bit = rand(256)
      green_bit = rand(256)
      blue_bit = rand(256)
      #
      #  Keep it reasonably dark.  Note that even our randomly generated
      #  colours are upper case.
      #
      if (red_bit + green_bit + blue_bit < 512)
        return sprintf("#%02X%02X%02X", red_bit, green_bit, blue_bit)
      end
    end
  end

  #
  #  This one generates a uuid regardless.
  #
  def generate_uuid
    write_attribute(:uuid, SecureRandom.uuid)
  end

end
