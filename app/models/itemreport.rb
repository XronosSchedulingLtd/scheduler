require 'uri'

class Itemreport < ActiveRecord::Base
  belongs_to :concern

  #
  #  Build a URL to generate this report.
  #
  def url
    base = "/item/#{self.concern.element_id}/days"
    extras = Array.new
    extras << "compact" if self.compact
    extras << "duration" if self.duration
    extras << "mark_end" if self.mark_end
    extras << "locations" if self.locations
    extras << "staff" if self.staff
    extras << "pupils" if self.pupils
    extras << "periods" if self.periods
    extras << "twelve_hour" if self.twelve_hour
    extras << "no_end_time" unless self.end_time
    extras << "breaks" if self.breaks
    extras << "suppress_empties" if self.suppress_empties
    extras << "tentative" if self.tentative
    extras << "firm" if self.firm
    extras << "start_date=#{self.starts_on}" if self.starts_on
    extras << "end_date=#{self.ends_on}" if self.ends_on
    unless self.categories.empty?
      #
      #  Remove any spaces the user has embedded.  Spaces other than
      #  around a comma need to be preserved and encoded.
      #
      broken = self.categories.split(",").collect {|s| s.strip}
      extras << "categories=#{URI.encode(broken.join(","))}"
    end
    if extras.size == 0
      base
    else
      base + "?" + extras.join("&")
    end
  end

end
