#
#  A class to be used as the superclass of any MIS_Record which
#  is also a group.
#
class MIS_Group < MIS_Record

  #
  #  Some common items are required by all groups.  Specific types of
  #  groups may require more.
  #
  #  Note that whilst we *define* what the critical items are here,
  #  it may well be up to the platform-specific implementation actually
  #  to provide them.
  #
  DB_KEY_FIELD = [:source_id_str, :datasource_id]
  FIELDS_TO_CREATE = [:name, :era, :starts_on, :ends_on, :current]
  FIELDS_TO_UPDATE = [:name, :era, :ends_on, :current]

  #
  #  A helper method to simplify the task fo adding to the above arrays.
  #
  #  You call it in the definition of a sub-class with something like:
  #
  #  add_fields(:FIELDS_TO_CREATE, [:able, :baker])
  #
  #  It creates a new constant attached to the sub-class, containing
  #  all the values from the parent, plus your extras.
  #
  def self.add_fields(identifier, values)
    self.const_set(identifier,
                   self.superclass.const_get(identifier) + values)
  end

  #
  #  Sub-classes may well want to override these.
  #
  def starts_on
    @@loader.start_date
  end

  def ends_on
    @@loader.era.ends_on
  end

  def era
    @@loader.era
  end

  #
  #  Ensure this group is correctly represented in the
  #  database.
  #
  #  By default we will populate the group but we can be told not to.
  #
  def ensure_db(loader, populate = true)
    loaded_count           = 0
    changed_count          = 0
    unchanged_count        = 0
    reincarnated_count     = 0
    begun_count            = 0
    member_loaded_count    = 0
    member_removed_count   = 0
    member_unchanged_count = 0
    #
    #  First call the method, then we can access @dbrecord directly.
    #
    self.dbrecord
    if @dbrecord
#      puts "Found existing group."
      #
      #  It's possible that, although there is a record in the d/b
      #  it's not current and we think it should be.
      #
      if self.current && !@dbrecord.current
        #
        #  Two possibilities.
        #
        #  1) This is an old group which is coming back.
        #  2) This is a new (future) group which is just coming alive
        #     for the first time.
        #
        if @dbrecord.ends_on && @dbrecord.ends_on < loader.start_date
          #
          #  Case 1 - reincarnation.
          #
          @dbrecord.reincarnate
          @dbrecord.reload
          #
          #  Reincarnating a group sets its end date to nil, but we kind
          #  of want it to be the end of the indicated era.
          #
          @dbrecord.ends_on = self.era.ends_on
          @dbrecord.save
          reincarnated_count += 1
        else
          #
          #  Case 2 - just starting.
          #
          @dbrecord.current = true
          @dbrecord.save
          begun_count += 1
        end
      end
      #
      #  Need to check the group details still match.
      #
      if self.check_and_update
        changed_count += 1
      else
        unchanged_count += 1
      end
    else
#      puts "Failed to find existing group."
#      if self.save_to_db(starts_on: loader.start_date,
#                         ends_on: self.era.ends_on,
#                         era: self.era)
      if self.save_to_db
        loaded_count += 1
      end
    end
    if @dbrecord && populate
      #
      #  And now sort out the members for this group.
      #  Note that we handle only members who seem to have originated
      #  from our current MIS.
      #
      #  It is possible that the group starts its existence at a later
      #  date than our loader start date - we are loading it in advance.
      #  In that case, use the start date of the group, rather than
      #  the loader's start date.
      #
      if self.starts_on > loader.start_date
        start_date = self.starts_on
      else
        start_date = loader.start_date
      end
      db_members =
        @dbrecord.members(start_date, false).
                  select {|m| m.datasource_id == @@primary_datasource_id}
      db_member_ids = db_members.collect {|m| m.element.id}
      mis_member_ids = Array.new
      #
      #  First make sure all our proposed members are indeed members.
      #
      self.members.each do |member|
        if member.dbrecord
          mis_member_ids << member.dbrecord.element.id
          unless db_member_ids.include?(member.dbrecord.element.id)
            begin
              if @dbrecord.add_member(member.dbrecord, start_date)
                #
                #  Adding a pupil to a tutor group effectively changes the
                #  pupil's element name.  Save the pupil record so the
                #  element name gets updated.
                #
                if self.class.const_get(:DB_CLASS) == Tutorgroup
                  member.force_save
                end
                member_loaded_count += 1
              else
                puts "Failed to add #{member.name} to group #{self.name}"
              end
            rescue ActiveRecord::RecordInvalid => e
              puts "Failed to add #{member.name} to group #{self.name}"
              puts e
            end
          end
        else
          puts "#{member.name} for #{self.name} has no d/b record!"
        end
      end
      #
      #  And now is there anyone who should be removed?
      #
      extra_in_db = db_member_ids - mis_member_ids
      db_members.each do |member|
        if extra_in_db.include?(member.element.id)
          @dbrecord.remove_member(member, start_date)
          #
          #  Likewise, removing a pupil can change his element name.
          #
          if self.class.const_get(:DB_CLASS) == Tutorgroup
            member.save!
          end
          member_removed_count += 1
        end
      end
      member_unchanged_count += (db_member_ids.size - extra_in_db.size)
    end
    [loaded_count,
     reincarnated_count,
     changed_count,
     unchanged_count,
     member_loaded_count,
     member_removed_count,
     member_unchanged_count]
  end

  #
  #  Note that this method doesn't do nearly enough, and the assumption
  #  is that most of the functionality will be provided by the platform-
  #  specific code.  However that code should call "super" in order to
  #  let this do a bit too.
  #
  #  We have no idea what the whatever parameter is, nor how to interpret
  #  it.  It's there solely so the calling code can just do "super".
  #
  def self.construct(loader, whatever)
    @@loader = loader
    []
  end

end
