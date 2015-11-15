
require_relative 'approvals'

namespace :daily do
  desc "Check for pending approvals."
  task :check_approvals => :environment do
    puts "Checking pending approvals."
    Element.owned.each do |element|
      set = PendingSet.new(element)
      unless set.empty?
        set.report
      end
    end
  end
end
