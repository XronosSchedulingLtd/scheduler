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
  def ensure_db(loader)
    loaded_count           = 0
    changed_count          = 0
    unchanged_count        = 0
    reincarnated_count     = 0
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
      #  no longer current.
      #
      unless @dbrecord.current
        @dbrecord.reincarnate
        @dbrecord.reload
        #
        #  Reincarnating a group sets its end date to nil, but we kind
        #  of want it to be the end of the indicated era.
        #
        @dbrecord.ends_on = self.era.ends_on
        @dbrecord.save
        reincarnated_count += 1
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
    if @dbrecord
      #
      #  And now sort out the members for this group.
      #  Note that we handle only members who seem to have originated
      #  from our current MIS.
      #
      db_member_ids =
        @dbrecord.members(loader.start_date).
                  select {|m| m.datasource_id == @@primary_datasource_id}.
                  collect {|m| m.source_id}
      mis_member_ids =
        self.members.collect {|m| m.source_id}
      missing_from_db = mis_member_ids - db_member_ids
      missing_from_db.each do |pupil_id|
        pupil = loader.pupil_hash[pupil_id]
        if pupil && pupil.dbrecord
          begin
            if @dbrecord.add_member(pupil.dbrecord, loader.start_date)
              #
              #  Adding a pupil to a tutor group effectively changes the
              #  pupil's element name.  Save the pupil record so the
              #  element name gets updated.
              #
              if self.class.const_get(:DB_CLASS) == Tutorgroup
                pupil.force_save
              end
              member_loaded_count += 1
            else
              puts "Failed to add #{pupil.name} to tutorgroup #{self.name}"
            end
          rescue ActiveRecord::RecordInvalid => e
            puts "Failed to add #{pupil.name} to tutorgroup #{self.name}"
            puts e
          end
        end
      end
      extra_in_db = db_member_ids - mis_member_ids
      extra_in_db.each do |pupil_id|
        pupil = loader.pupil_hash[pupil_id]
        if pupil && pupil.dbrecord
          @dbrecord.remove_member(pupil.dbrecord, loader.start_date)
          #
          #  Likewise, removing a pupil can change his element name.
          #
          if self.class.const_get(:DB_CLASS) == Tutorgroup
            pupil.force_save
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
  end

end
