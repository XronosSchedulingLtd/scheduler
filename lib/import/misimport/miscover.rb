#
#  Note that this class does not inherit from MIS_Record because
#  it isn't actually a record in its own right.  It's a link between
#  other records.  Yes, the link is actually a record too, but it's
#  not something which can exist on its own.
#
#  Very little information is needed.
#
class MIS_Cover

  #
  #  It's up to MIS-specific code to provide these.
  #
  #  source_id                  Unique ID for this instance of cover
  #  date                       The date of the lesson being covered
  #  lesson_source_hash         Source hash of the relevant lesson.
  #  staff_covering             The staff member doing the cover.
  #  staff_covered              The staff member being covered.
  #
  #  and for reporting purposes
  #
  #  starts_at
  #  ends_at
  #
  attr_reader :source_id,
              :date,
              :lesson_source_hash,
              :staff_covering,
              :staff_covered,
              :starts_at,
              :ends_at

  #
  #  A class for recording details of an apparent clash.  For a clash
  #  to exist, the same resource must have a commitment to two simultaneous
  #  events.  This class therefore simply records references to the two
  #  commitments.
  #
  class Clash

    attr_reader :cover_commitment, :clashing_commitment

    def initialize(cover_commitment, clashing_commitment)
      @cover_commitment    = cover_commitment
      @clashing_commitment = clashing_commitment
    end

    #
    #  Clashes are sorted chronologically.
    #
    def <=>(other)
      self.cover_commitment.event.starts_at <=> other.cover_commitment.event.starts_at
    end

    def to_partial_path
      "user_mailer/clash"
    end

    def self.permitted_overload(cover_commitment, clashing_commitment)
      PERMITTED_OVERLOADS.each do |pe|
        if pe.cover_event_body =~ cover_commitment.event.body &&
           pe.clash_event_body =~ clashing_commitment.event.body
          return true
        end
      end
      false
    end

    def self.find_clashes(cover_commitment)
      #
      #  Finds anything which apparently clashes with this cover commitment.
      #  Ignores:
      #
      #    The cover commitment itself
      #    Additional commitments to the same event
      #    Commitments to events flagged as unimportant
      #    Commitments to events of the same category, flagged as mergeable,
      #    happening at exactly the same time (e.g. registration)
      #    Events flagged as can_borrow, where more then one member of
      #    staff is committed to the event.
      #
      #  It is possible for someone to be committed more than once
      #  to the same event, if he or she is a member of more than one
      #  group committed to the event.  Make sure we report on each
      #  clashing event only once.
      #
      clashes = []
      #
      #  Special case.  ICF uses a convention of saying an individual
      #  is covering his or her own lesson to indicate that no cover
      #  is actually needed at all.  Identify this case, and if we
      #  have it then do no further checks.
      #
      #  Need to be careful here, because we also check clashes for
      #  Invigilations, and there there is nothing being covered.
      #
      #  Also don't bother checking if the covering element is one
      #  which can cover many things at once.
      #
      unless ((cover_commitment.covering != nil) &&
              (cover_commitment.element ==
               cover_commitment.covering.element)) ||
              cover_commitment.element.multicover?
        event_ids_seen = []
        #
        #  Note that, because we haven't explicitly asked for them, we
        #  won't pick up commitments to events which are flagged as
        #  non-existent.
        #
        all_commitments =
          cover_commitment.element.commitments_during(
            start_time:        cover_commitment.event.starts_at,
            end_time:          cover_commitment.event.ends_at,
            excluded_category: Eventcategory.non_busy_categories)
        if all_commitments.size > 1
          #
          #  Possibly a problem.
          #
  #        puts "Possible cover clash for #{cover_commitment.element.name}."
          all_commitments.each do |c|
  #          puts "  #{c.event.starts_at}"
  #          puts "  #{c.event.ends_at}"
  #          puts "  #{c.event.body}"
            unless (c == cover_commitment) ||
                   (c.event == cover_commitment.event) ||
                   (c.covered) ||
                   (c.event.eventcategory.unimportant) ||
                   (c.event.eventcategory.can_merge &&
                    c.event.eventcategory == cover_commitment.event.eventcategory &&
                    c.event.starts_at == cover_commitment.event.starts_at &&
                    c.event.ends_at   == cover_commitment.event.ends_at) ||
                   (c.event.eventcategory.can_borrow &&
                    c.event.staff(true).size > 1) ||
                   permitted_overload(cover_commitment, c) ||
                   event_ids_seen.include?(c.event.id)
              clashes << Clash.new(cover_commitment, c)
              event_ids_seen << c.event.id
            end
          end
        end
      end
      clashes
    end

  end


  class Oddity

    attr_reader :descriptive_text

    #
    #  New version - now passed the actual cover commitment.
    #
    def initialize(staff_cover,
                   descriptive_text)
#      puts "Creating an oddity"
      @staff_cover        = staff_cover
      @descriptive_text   = descriptive_text
      #
      #  Now prepare the bits we need to produce formatted output.
      #

    end

    def to_partial_path
      "user_mailer/oddity"
    end

    def effective_date
      @staff_cover.date
    end

    def oddity_type
#      @staff_cover.cover_or_invigilation
      :cover
    end

    def activity_text
#      @staff_cover.cover_or_invigilation == :cover ? "Cover" : "Invigilation"
      "Cover"
    end
    
    def start_time
      @staff_cover.starts_at
    end

    def end_time
      @staff_cover.ends_at
    end

    def person
      @staff_cover.staff_covering.name
    end

    def problem
      @descriptive_text
    end

    def <=>(other)
      self.effective_date <=> other.effective_date
    end

  end

  #
  #  And this function does the job of ensuring that this particular
  #  instance of cover is in the d/b.
  #
  def ensure_db(loader, covered_property)
    added    = 0
    amended  = 0
    deleted  = 0
    clashes  = []
    oddities = []
    #
    #  Is it already in the database?
    #  It's a bit weird, but Ian sometimes does cover for non-existent
    #  lessons.
    #
    candidates =
      Commitment.commitments_on(startdate: self.date,
                                include_nonexistent: true).
                 covering_commitment.
                 where(source_id: self.source_id)
    if candidates.size == 0
      #
      #  Not there - need to create it.  Can we find the corresponding
      #  lesson?
      #
      #  We actually do cover by teacher, and for now we assume there
      #  is only one teacher per lesson.
      #
      dblesson = Event.on(@date).
                       eventsource_id(loader.event_source.id).
                       source_hash(@lesson_source_hash).take
      if dblesson
#        puts "Found the corresponding lesson."
        #
        #  Need to find the commitment by the covered teacher
        #  to the indicated lesson.
        #
        if dblesson.non_existent
          oddities << Oddity.new(self, "lesson is suspended")
        end
        original_commitment =
          Commitment.by(@staff_covered.dbrecord).to(dblesson).take
        if original_commitment
          if original_commitment.covered
            puts "Commitment seems to be covered already."
          end
          cover_commitment = Commitment.new
          cover_commitment.event = original_commitment.event
          cover_commitment.element = @staff_covering.dbrecord.element
          cover_commitment.covering = original_commitment
          cover_commitment.source_id = self.source_id
          if cover_commitment.save
            added += 1
            cover_commitment.reload
            #
            #  Does this clash with anything?
            #
            clashes = Clash.find_clashes(cover_commitment)
            #
            #  Flag lesson as covered.
            #
            if covered_property
              dblesson.ensure_property(covered_property)
            end
          else
            puts "Failed to save cover."
            cover_commitment.errors.full_messages.each do |msg|
              puts msg
            end
            puts "staff_covering:"
            puts "  name #{@staff_covering.name}"
#            puts "  does_cover #{@staff_covering.does_cover}"
            puts "dblesson:"
            puts "  body: #{dblesson.body}"
            puts "  eventcategory: #{dblesson.eventcategory.name}"
            puts "  starts_at: #{dblesson.starts_at}"
            puts "  ends_at: #{dblesson.ends_at}"
            puts "original_commitment:"
            puts "  element.name: #{original_commitment.element.name}"
          end
        else
          puts "Failed to find original commitment."
          puts "Covering: #{@staff_covering.name}"
          puts "Covered: #{@staff_covered.name}"
          puts "Starts at: #{@starts_at}"
          puts "Ends at: #{@ends_at}"
        end
      else
        puts "Failed to find corresponding lesson."
        puts "Covering: #{@staff_covering.name}"
        puts "Covered: #{@staff_covered.name}"
        puts "Starts at: #{@starts_at}"
        puts "Ends at: #{@ends_at}"
      end
    elsif candidates.size == 1
      cover_commitment = candidates[0]
#        puts "Cover is already there."
#        puts "Event #{candidates[0].event.body} at #{candidates[0].event.starts_at}"
      #
      #  Is it the right person doing it?
      #
      if cover_commitment.element != @staff_covering.dbrecord.element
        #
        #  No.  Adjust.
        #
        if loader.options.verbose
          puts "Amending cover for #{@staff_covered.name} at #{@starts_at}."
          puts "#{@staff_covering.dbrecord.element.name} replaces #{cover_commitment.element.name}."
        end
        cover_commitment.element = @staff_covering.dbrecord.element
        if cover_commitment.save
          amended += 1
        else
          puts "Failed to save amended cover."
        end
        #
        #  Reload regardless of whether or not the save succeeded,
        #  because if it failed we want to get back the consistent
        #  record which we had before.
        #
        cover_commitment.reload
      end
      #
      #  Again, need to check if it clashes with anything.
      #
      clashes = Clash.find_clashes(cover_commitment)
      if cover_commitment.event.non_existent
        oddities << Oddity.new(self, "lesson is suspended")
      end
    else
      puts "Weird - cover item #{self.source_id} is there more than once."
      candidates.each do |c|
        c.destroy
        deleted += 1
      end
    end
#    if oddities.size > 0
#      puts "Returning #{oddities.size} oddities."
#    end
    [added, amended, deleted, clashes, oddities]
  end

  #
  #  Work out the date of the last existing cover in the d/b, starting
  #  from base_date.  Return base_date if there aren't any.
  #
  def self.last_existing_cover_date(base_date)
    last_known = base_date
    Commitment.covering_commitment.each do |cc|
      event_date = cc.event.starts_at.to_date
      if event_date > last_known
        last_known = event_date
      end
    end
    last_known
  end

  #
  #  MIS-Specific code should override this.
  #
  def self.construct(loader, mis_data)
    []
  end
end

