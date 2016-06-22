#
#  A class to be used as the superclass of any MIS_Record which
#  is also a group.
#
class MIS_Group < MIS_Record

  #
  #  Given an array of records of things, assemble a list of their
  #  element ids, which is what drives membership in Scheduler.
  #
  #  Each thing must have a dbrecord method, and each dbrecord must
  #  have an element, which has an id.
  #
  def assemble_membership_list(members)
    @member_list = members.collect do |member|
      member.try(:dbrecord).try(:element).try(:id)
    end.compact
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
      #
      #  It's possible that, although there is a record in the d/b
      #  no longer current.
      #
      unless @dbrecord.current
        @dbrecord.reincarnate
        @dbrecord.reload
        #
        #  Reincarnating a group sets its end date to nil, but we kind
        #  of want it to be the end of the current era.
        #
        @dbrecord.ends_on = loader.era.ends_on
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
      if @member_list.size > 0
        if self.save_to_db(starts_on: loader.start_date,
                           ends_on: loader.era.ends_on,
                           era: loader.era)
          loaded_count += 1
        end
      end
    end
    if @dbrecord
      #
      #  And now sort out the pupils for this tutor group.
      #
      db_member_ids =
        @dbrecord.members(loader.start_date).collect {|s| s.source_id}
      sb_member_ids = self.records.collect {|r| r.pupil_ident}
      missing_from_db = sb_member_ids - db_member_ids
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
              pupil.force_save
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
      extra_in_db = db_member_ids - sb_member_ids
      extra_in_db.each do |pupil_id|
        pupil = loader.pupil_hash[pupil_id]
        if pupil && pupil.dbrecord
          @dbrecord.remove_member(pupil.dbrecord, loader.start_date)
          #
          #  Likewise, removing a pupil can change his element name.
          #
          pupil.force_save
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
end
