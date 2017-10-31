
require_relative 'approvals'

namespace :daily do
  desc "Check for pending approvals."
  task :check_approvals => :environment do
#    puts "Checking pending approvals."
    ApprovalNotifier.new.scan_elements.send_emails
#      set = PendingSet.new(element)
#      UserNotificationSet.note_pending(set)
#      unless set.empty?
#        set.report
#      end
#    end
#    UserNotificationSet.dump
#    UserNotificationSet.send_emails
  end

  desc "Adjust group currency flags."
  task :adjust_currency_flags => :environment do
    Group.adjust_currency_flags
  end
end
