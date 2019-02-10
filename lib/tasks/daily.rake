
namespace :daily do
  desc "Check for pending approvals."
  task :check_approvals => :environment do
    ApprovalNotifier.new.scan_elements.send_emails
  end

  desc "Report on resource loading."
  task :report_loadings => :environment do
    LoadingNotifier.new.scan_elements.send_emails
  end

  desc "Adjust group currency flags."
  task :adjust_currency_flags => :environment do
    Group.adjust_currency_flags
  end
end
