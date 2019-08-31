#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class EmailPurger
  def self.do_purge
    email_keep_days = Setting.first.email_keep_days
    if email_keep_days > 0
      threshold_date = Date.today - email_keep_days
      selector = Ahoy::Message.where("sent_at < ?", threshold_date)
      destroy_count = selector.count
      if destroy_count > 0
        selector.destroy_all
        Rails.logger.info("Purged #{destroy_count} old emails.")
      end
    end
  end
end

