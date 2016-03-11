require 'uri'

class Itemreport < ActiveRecord::Base
  belongs_to :concern
  belongs_to :excluded_element,
             :class_name => :Element

  #
  #  Note that the concept of my_notes here relates to the item.  It's
  #  not a question of who owns the note, but whether it relates to
  #  this item's commitment to each event.
  #
  store :note_flags, accessors: [:my_notes, :other_notes, :general_notes]

  #
  #  Force the above to store as booleans.
  #
  def my_notes=(value)
    if value == "1"
      super(true)
    else
      super(false)
    end
  end

  def other_notes=(value)
    if value == "1"
      super(true)
    else
      super(false)
    end
  end

  def general_notes=(value)
    if value == "1"
      super(true)
    else
      super(false)
    end
  end

  def excluded_element_name
    if self.excluded_element
      excluded_element.name
    else
      ""
    end
  end

  def excluded_element_name=(name)
  end

  def note_type(commit_type)
    if commit_type == "csv"
      @report_type = :csv
    elsif commit_type == "doc"
      @report_type = :doc
    else
      @report_type = :html
    end
  end

  def note_options
    "#{self.my_notes ? "M" : ""}#{self.other_notes ? "O" : ""}#{self.general_notes ? "G" : ""}"
  end

  #
  #  Build a URL to generate this report.
  #
  def url
    base = "/item/#{self.concern.element_id}/days"
    if @report_type == :csv
      base += ".csv"
    elsif @report_type == :doc
      base += ".doc"
    end
    extras = Array.new
    extras << "compact" if self.compact
    extras << "duration" if self.duration
    extras << "mark_end" if self.mark_end
    extras << "locations" if self.locations
    extras << "staff" if self.staff
    extras << "pupils" if self.pupils
    extras << "periods" if self.periods
    extras << "twelve_hour" if self.twelve_hour
    extras << "no_space" if self.no_space
    extras << "no_end_time" unless self.end_time
    extras << "breaks" if self.breaks
    extras << "suppress_empties" if self.suppress_empties
    extras << "tentative" if self.tentative
    extras << "firm" if self.firm
    if self.my_notes || self.other_notes || self.general_notes
      extras << "notes=#{note_options}"
    end
    extras << "exclude=#{self.excluded_element_id}" if self.excluded_element_id
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
