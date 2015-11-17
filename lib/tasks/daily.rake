
require_relative 'approvals'

namespace :daily do
  desc "Check for pending approvals."
  task :check_approvals => :environment do
#    puts "Checking pending approvals."
    Element.owned.each do |element|
      set = PendingSet.new(element)
      UserNotificationSet.note_pending(set)
#      unless set.empty?
#        set.report
#      end
    end
#    UserNotificationSet.dump
    UserNotificationSet.send_emails
  end
end
