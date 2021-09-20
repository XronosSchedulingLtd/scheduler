
namespace :daily do
  desc 'Check for pending approvals.'
  task check_approvals: :environment do
    ApprovalNotifier.new.scan_elements.send_emails
  end

  desc 'Check for clashes in controlled resources.'
  task check_resource_clashes: :environment do
    ResourceClashNotifier.new.scan_elements.send_emails
  end

  desc 'Report on resource loading.'
  task report_loadings: :environment do
    LoadingNotifier.new.scan_elements.send_emails
  end

  desc 'Prompt people to complete forms.'
  task prompt_for_forms: :environment do
    FormPrompter.new.scan_elements.send_emails
  end

  desc 'Prompt people to re-confirm their resource bookings.'
  task prompt_for_reconfirmation: :environment do
    ReconfirmationPrompter.new.scan_requests.send_emails
  end

  desc 'Prompt people to list drivers etc.'
  task prompt_for_staff: :environment do
    StaffPrompter.new.scan_events.send_emails
  end

  desc 'Adjust group currency flags.'
  task adjust_currency_flags: :environment do
    Group.adjust_currency_flags
  end

  desc 'Check user files.'
  task check_user_files: :environment do
    UserFile.check_for_missing
  end

  desc 'Purge old emails.'
  task purge_emails: :environment do
    EmailPurger.do_purge
  end
end
