require 'yaml'

module PrepParsing

  PrepRecord = Struct.new(:subject, :setname, :year)

  class PrepRecord
    def setname_matches?(name)
      if setname.blank?
        false
      elsif setname.include? "%"
        #
        #  For historical reasons, the file specifies wildcards using
        #  SQL database syntax. "%" is the wild card symbol.
        #
        @matcher ||= Regexp.new(setname.gsub('%', '.*'))
        (@matcher =~ name) != nil
      else
        setname == name
      end
    end

    def matches?(lesson)
      (!lesson.subject_name.empty? && lesson.subject_name == self.subject) ||
        setname_matches?(lesson.body_text)  #  Should really be the set name.
    end
  end

  # A class in which we store the prep timetable.
  class PrepTT
    def initialize(filename)
      prepdata = YAML.load(File.open(filename))
      #
      #  We try to be incredibly generous in the order in which we will
      #  accept information.  We need to know:
      #
      #    An academic year (1,2,3,... 7)
      #    A week (A, B)
      #    A subject (Maths, English,... )
      #
      #  and then we can accept information on prep days.  The three key
      #  items can be given in any order.  It's done by recursive calls
      #  on a function.
      #
      @weeks = Hash.new
      process(prepdata)
#      puts "Got #{@weeks.size} weeks of prep data."
#      @weeks.each do |key, days|
#        puts "Week #{key} has #{days.size} days"
#        days.each do |key, contents|
#          puts "  Day - #{key} has #{contents.size} entries"
#          contents.each do |year, records|
#            puts "Year #{year}"
#            records.each do |record|
#              puts "Subject: \"#{record.subject}\", setname: #{record.setname}, year: #{record.year}"
#            end
#          end
#        end
#      end
    end

    #
    #  Returns an array of all the preps for the indicated week, day
    #  and year group, or an empty array if none found.
    #
    def prepsfor(week, day, yeargroup)
#      puts "Asked for preps for week #{week}, day #{day}, yeargroup #{yeargroup}"
      @weeks[week] ?
        (@weeks[week][day] ? @weeks[week][day][yeargroup] || [] : []) : []
    end

    private

    def process(prepdata, year = nil, week = nil, day = nil, nesting = 0)
      if prepdata.instance_of?(Hash)
        #
        #  Must look for specific information at this level before thinking
        #  about recursing.
        #
        if prepdata["day"]
          day = prepdata["day"]
        end
        if prepdata["week"]
          week = prepdata["week"]
        end
        if prepdata["year"]
          year = prepdata["year"]
        end
        if prepdata["days"]
          process(prepdata["days"], year, week, day, nesting + 1)
        end
        if prepdata["weeks"]
          process(prepdata["weeks"], year, week, day, nesting + 1)
        end
        if prepdata["years"]
          process(prepdata["years"], year, week, day, nesting + 1)
        end
        if prepdata["subjects"]
          #
          #  Finally getting to the nitty gritty.
          #
          if year && week && day
            prepdata["subjects"].each do |subject|
#              puts "Year #{year} have #{subject} prep on #{day} in week #{week}"
              record(year, week, day, subject)
            end
          else
            raise "Can't handle prep information without having year, week and day first."
          end
        end
        if prepdata["sets"]
          if year && week && day
            prepdata["sets"].each do |setname|
#              puts "Year #{year} set #{setname} have prep on #{day} in week #{week}"
              record(year, week, day, nil, setname)
            end
          else
            raise "Can't handle prep information without having year, week and day first."
          end
        end
      elsif prepdata.instance_of?(Array)
        prepdata.each do |pd|
          process(pd, year, week, day, nesting + 1)
        end
      else
        puts "Prepdata is of class #{prepdata.class}"
      end
    end

    def record(year, week, day, subject, setname = nil)
      @weeks[week]            ||= Hash.new
      @weeks[week][day]       ||= Hash.new
      @weeks[week][day][year] ||= Array.new
      @weeks[week][day][year] << PrepRecord.new(subject, setname, year)
    end

  end

  class Prepper

    def initialize
      #
      #  There may be no prep file at all, in which case we don't
      #  bother.
      #
      filename = Rails.root.join(IMPORT_DIR, "modifiers", "Preps.yml")
      begin
        @preps = PrepTT.new(filename)
        property_element = Setting.prep_property_element
        if property_element
          @prep_property = MIS_Property.new(property_element.entity)
        else
          @prep_property = nil
        end
        @suffix = Setting.prep_suffix
      rescue Errno::ENOENT
        @preps = nil
        @prep_property = nil
        @suffix = ""
      end
    end

    def process_timetable(timetable)
      if @preps
        timetable.schedule.entries.each do |entry|
          if entry.prepable? && entry.subject && entry.yeargroups.size == 1
            preps = @preps.prepsfor(entry.week_letter,
                                    entry.short_day_of_week,
                                    entry.yeargroups[0])
            if preps
              if preps.detect { |p| p.matches?(entry) }
                entry.body_text = "#{entry.body_text} #{@suffix}"
                if @prep_property
                  entry.properties << @prep_property
                end
              end
            end
          end
        end
      end
    end
  end

end # Module
