
class UserNotificationSet
  @@user_sets = Hash.new

  attr_reader :pending_sets

  def initialize(u)
    @user = u
    @pending_sets = Array.new
  end

  def add(pending_set)
    @pending_sets << pending_set
  end

  def report
    puts "User #{@user.name} has #{@pending_sets.size} sets."
  end

  def send_email
    UserMailer.pending_approvals_email(@user.email, self).deliver
  end

  #
  #  Passed a set of pending commitments, attaches them to a user
  #  record for each potentially interested user.
  #
  def self.note_pending(pending_set)
    unless pending_set.empty?
      pending_set.interested_users.each do |u|
        user_set = (@@user_sets[u.uid] ||= UserNotificationSet.new(u))
        user_set.add(pending_set)
      end
    end
  end

  def self.dump
#    puts @@user_sets.inspect
    puts "#{@@user_sets.size} user sets."
    @@user_sets.each do |key, us|
      us.report
    end
  end

  def self.send_emails
    @@user_sets.each do |key, us|
      us.send_email
    end
  end

end

class PendingSet

  attr_reader :element, :pending

  def initialize(element)
    @element = element
    @pending = element.commitments.tentative.future.not_rejected.
               preload([:element, :event]).to_a
    @rejected = element.commitments.tentative.future.rejected.
                preload([:element, :event]).to_a
  end

  def empty?
    @pending.size == 0
  end

  def report
    puts "Requests for #{@element.name}"
    @pending.each do |p|
      puts "  #{p.event.owners_initials} proposes \"#{p.event.body}\" on #{p.event.starts_at_text}."
    end
    @rejected.each do |p|
      puts "  #{p.event.owners_initials} wanted \"#{p.event.body}\" on #{p.event.starts_at_text}."
      puts "    Rejected by #{p.by_whom ? p.by_whom.name : "unknown"} - #{p.reason}."
    end
  end

  #
  #  Returns a list of the users who own the relevant element and who
  #  would like e-mail notifications.
  #
  def interested_users
    (@element.concerns.owned.collect {|c| c.user} +
     User.administrators.to_a).uniq.select {|u| u.email_notification}
  end

end
