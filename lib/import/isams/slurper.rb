#
#  Slurper module for use by extractor program
#  Copyright (C) John Winters 2014-2016
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
#
#  but for reverse compatibility, false will still be taken as meaning
#  a string and true as meaning an integer.
#
Column = Struct.new(:label, :attr_name, :target_type)

#
#  A module containing the common code used to read in a CSV file
#  and save it in memory records.
#
module Slurper
  def self.included(parent)
    parent::REQUIRED_COLUMNS.each do |column|
      attr_accessor column[:attr_name]
    end
    parent.send :extend, ClassMethods
  end

  module ClassMethods
    def slurp(accumulator, import_dir, allow_empty)
      #
      #  Slurp in a file full of records and return them as an array.
      #
      #  Try to coerce everything to utf-8 at point of entry to avoid
      #  problems later.
      #
      raw_contents = File.read(File.expand_path(self::FILE_NAME, import_dir))
      detection = CharlockHolmes::EncodingDetector.detect(raw_contents)
      utf8_encoded_raw_contents =
        CharlockHolmes::Converter.convert(raw_contents,
                                          detection[:encoding],
                                          'UTF-8')
      contents = CSV.parse(utf8_encoded_raw_contents)
#      contents = CSV.read(Rails.root.join(IMPORT_DIR, self::FILE_NAME))
#      puts "Read in #{contents.size} lines."
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

              else
                entry.send("#{attr_name}=",
                           row[column_hash[attr_name]] ?
                           row[column_hash[attr_name]].strip : "")
              end
            end
            entry.adjust(accumulator)
            if entry.wanted?
              entries << entry
            else
              dropped += 1
            end
          end
        end
        if dropped > 0
          puts "Slurper dropped #{dropped} #{self} entries out of #{read_count}."
        end
        if allow_empty || entries.size > 0
          return entries, nil
        else
          return nil, "File #{self::FILE_NAME} is empty."
        end
      end
    end
  end
end

