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
        setname_matches?(lesson.code)  #  Should really be the set name.
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

    def initialize(filename)
      @preps = PrepTT.new(filename)
      property = Property.find_by(name: "Prep")
      unless property
        raise "No Property called \"Prep\" found."
      end
      @prep_property = MIS_Property.new(property)
    end

    def process_timetable(timetable)
#      puts "#{timetable.schedule.entries.count} entries to process."
#      puts "Of which, #{timetable.schedule.entries.select {|e| e.instance_of?(ISAMS_TimetableEntry)}.count} seem to be timetable."
      timetable.schedule.entries.each do |entry|
        if entry.instance_of?(ISAMS_TimetableEntry) && entry.subject
          preps = @preps.prepsfor(entry.week_just_letter,
                                  entry.short_day_of_week,
                                  entry.yeargroup)
          if preps
#            puts "Got #{preps.size} preps to consider"
            if preps.detect { |p| p.matches?(entry) }
#              puts "Got a match"
              entry.code = "#{entry.code} (P)"
              entry.properties << @prep_property
            end
          end
        end
      end
    end
  end

end # Module
