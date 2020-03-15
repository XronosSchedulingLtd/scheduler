#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  The last field in the following structure used to be of a boolean
#  type called "numeric".  True meant to expect a number, false implied
#  a string.
#
#  It's now been enhanced to specify a type.  Possibles are:
#
#  :string
#  :boolean
#  :integer
#  :date
#  :time
#  :datetime
#
#  but for reverse compatibility, false will still be taken as meaning
#  a string and true as meaning an integer.
#
CSVColumn = Struct.new(:label, :attr_name, :target_type)

#
#  A module containing the common code used to read in a CSV file
#  and save it in memory records.
#
module CSVImport
  def self.included(parent)
    parent::REQUIRED_COLUMNS.each do |column|
      attr_accessor column[:attr_name]
    end
    parent.send :extend, ClassMethods
  end

  module ClassMethods
    def slurp(file_name, accumulator = nil, allow_empty = false)
      #
      #  Slurp in a file full of records and return them as an array.
      #
      #  Try to coerce everything to utf-8 at point of entry to avoid
      #  problems later.
      #
      raw_contents = File.read(file_name, encoding: 'bom|utf-8')
      contents = CSV.parse(raw_contents)
#      puts "Read in #{contents.size} lines."
#      puts contents[0].inspect
#      puts contents[0][0]
#      puts self::REQUIRED_COLUMNS[0][:label]
#      puts "Comparison result is"
#      puts contents[0][0] == self::REQUIRED_COLUMNS[0][:label]
#      puts contents[0][0].dump
#      puts self::REQUIRED_COLUMNS[0][:label].dump

      #
      #  Do we have the necessary columns?
      #
      missing = false
      column_hash = {}
      self::REQUIRED_COLUMNS.each do |column|
        index = contents[0].find_index(column[:label])
        if index
          column_hash[column[:attr_name]] = index
        else
          puts "Can't find #{column[:label]}"
          missing = true
        end
      end
      if missing
        return nil, "One or more required column(s) missing."
      else
        dropped = 0
        read_count = 0
        entries = []
        contents.each_with_index do |row, i|
          read_count += 1
          if i != 0
            entry = self.new
            self::REQUIRED_COLUMNS.each do |column|
              attr_name = column[:attr_name]
              case column.target_type
              when true, :integer
                #
                #  Leave as nil if nothing provided.
                #
                unless row[column_hash[attr_name]] == nil
                  entry.send("#{attr_name}=", row[column_hash[attr_name]].to_i)
                end

              when :boolean
                text = row[column_hash[attr_name]]
                if text
                  value = (text.downcase == "true")
                else
                  value = false
                end
                entry.send("#{attr_name}=", value)

              when :date
                #
                #  Leave as nil if nothing provided.
                #
                unless row[column_hash[attr_name]] == nil
                  entry.send("#{attr_name}=",
                             Date.parse(row[column_hash[attr_name]]))
                end

              when :time
                #
                #  Leave as nil if nothing provided.
                #
                unless row[column_hash[attr_name]] == nil
                  entry.send("#{attr_name}=",
                             Time.parse(row[column_hash[attr_name]]))
                end

              when :datetime
                #
                #  Leave as nil if nothing provided.
                #
                unless row[column_hash[attr_name]] == nil
                  entry.send("#{attr_name}=",
                             Time.zone.parse(row[column_hash[attr_name]]))
                end

              else
                entry.send("#{attr_name}=",
                           row[column_hash[attr_name]] ?
                           row[column_hash[attr_name]].strip : "")
              end
            end
            if entry.respond_to?(:adjust)
              entry.adjust(accumulator)
            end
            if entry.wanted?
              entries << entry
            else
              dropped += 1
            end
          end
        end
#        if dropped > 0
#          puts "Slurper dropped #{dropped} #{self} entries out of #{read_count}."
#        end
        if allow_empty || entries.size > 0
          return entries, nil
        else
          return nil, "File #{self::FILE_NAME} is empty."
        end
      end
    end
  end
end

