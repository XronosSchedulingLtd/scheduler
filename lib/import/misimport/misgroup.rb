#
#  A module to be mixed in by any MIS_Record which happens also to
#  be a group, of whatever kind.
#
module MIS_Group

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

end
