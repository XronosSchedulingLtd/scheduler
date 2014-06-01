class Element < ActiveRecord::Base
  belongs_to :entity, :polymorphic => true
  has_many :memberships, :dependent => :destroy
  has_many :commitments, :dependent => :destroy
  
  #
  #  This method is much like the "members" method in the Group model,
  #  except the other way around.  It provides a list of all the groups
  #  of which this element is a member on the indicated date.  If no
  #  date is given then use today's date.
  #
  #  Different processing however is required to handle inverses.  We need
  #  to work up to the groups of which we are potentially a member, then
  #  check we're not excluded from there by an inverse membership record.
  #
  #  If recursion is required then we have to select *all* groups of which
  #  we are a member, and not just those for the indicated date.  This is
  #  because recursion may specify a different date to think about.
  #
  #  Returns and array of *Visible Group* objects.
  #
  def groups(given_date = nil, recurse = true)
    given_date ||= Date.today
    if recurse
      #
      #  With recursion, life gets a bit more entertaining.  We need to
      #  find all groups of which we might be a potential member (working
      #  up the tree until we find groups which aren't members of anything)
      #  then check which ones of these we are actually a member of on
      #  the indicated date.  The latter step could be done by a sledgehammer
      #  approach (call member?) for each of the relevant groups, but that
      #  might be a bit inefficient.  I'm hoping to do it as we reverse
      #  down the recursion tree.
      #
      #  When working our way up the tree we have to include *all*
      #  memberships, regardless of apparently active date because there
      #  might be an as_at date in one of the membership records which
      #  affects things on the way back down.
      #
      #  E.g. Able was a member of the group A back in June, but isn't now.
      #  Group A is a member of group B, with an as_at date of 15th June.
      #  Able is therefore a member of B, even though he isn't currently
      #  a member of A.
      #
      #  If we terminated the search on discovering that Able is not currently
      #  a member of A, we wouldn't discover that Able is in fact currently
      #  a member of B.
      #
      #  There is on the other hand no point in looking at exclusions on
      #  the way up the tree.  We look at inclusions on the way up,
      #  because without an inclusion of some sort the exclusion is irrelevant,
      #  then look at both on the way back down.
      #
      self.memberships.inclusions.collect {|membership| 
        membership.group.parents_for(self, given_date)
      }.flatten.uniq.collect {|g| g.visible_group}
    else
      #
      #  If recursion is not required then we just return a list of the
      #  groups of which this element is an immediate member.
      #
      self.memberships.active_on(given_date).inclusions.collect {|m| m.group.visible_group}
    end
  end

end
