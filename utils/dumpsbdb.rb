#!/usr/bin/env ruby
#
#  A ruby script to dump the whole of the SchoolBase database.
#
#  Dumps only actual tables and not views because we don't want
#  duplication.
#
#  Note that the utility does not correctly escape quote strings so
#  the files thus generated will not be good for automatic processing.
#  If necessary, this utility could be enhanced to identify those
#  columns which require escaping and then produced modified SQL to
#  turn '"' into '""'.
#


require 'tempfile'
require 'csv'
require 'tiny_tds'

TARGET_DIR="/home/john/Work/Coding/scheduler/import/tables/dump/"
UTILITY="/usr/bin/isql"

class SchoolBaseDumper
  @@password = nil

  def self.old_invoke_sql(command, output_file = nil)
    tf = Tempfile.new("foo")
    puts "Temporary file is #{tf.path}"
    tf.puts command 
    tf.close
    if output_file
      command = "#{UTILITY} Schoolbase winters #{@@password} -b -d, -q -c <#{tf.path} >#{output_file}"
      puts "Command is \"#{command}\""
      system command
    else
      command = "#{UTILITY} Schoolbase winters #{@@password} -b -d, -q -c <#{tf.path}"
      puts "Command is \"#{command}\""
      `#{command}`
    end
  end

  def self.invoke_sql(command, output_file = nil)
    client = TinyTds::Client.new(
      username: "winters",
      password: @@password,
      dataserver: "Schoolbase",
      database: "Schoolbase")
    result = client.execute(command)
    fields = result.fields
    if output_file
      CSV.open(output_file, "wb") do |csv|
        csv << fields
        result.each(:cache_rows => false) do |row|
          csv << fields.collect do |f|
            data = row[f]
            if data.class == String && data.encoding != Encoding::UTF_8
              data.force_encoding("iso-8859-1").encode("utf-8")
            else
              data
            end
          end
        end
      end
      csv_string = ""
    else
      csv_string = CSV.generate do |csv|
        csv << fields
        result.each do |row|
          csv << fields.collect {|f| row[f]}
        end
      end
    end
    client.close
    csv_string
  end

  def self.dump_tables
    get_password unless @@password
    listing = self.old_invoke_sql("help")
    processed = CSV.parse(listing)
    name_index = nil
    type_index = nil
    processed.each_with_index do |row, i|
      if i == 0
        name_index = row.index "TABLE_NAME"
        type_index = row.index "TABLE_TYPE"
        exit unless name_index && type_index
      else
        if (row[type_index] == "TABLE")
          table_name = row[name_index]
          self.invoke_sql("select * from [#{table_name}];", "#{TARGET_DIR}#{table_name}.csv")
        end
      end
    end
#    tf = Tempfile.new("#{@table_name}")
#    puts "Temporary file is #{tf.path}"
#    tf.puts "select #{columns} from #{@table_name};"
#    tf.close
#    command = "#{UTILITY} Schoolbase winters #{@@password} -b -d, -q -c <#{tf.path} >#{TARGET_DIR}#{@table_name}.csv"
#    puts "Command is:"
#    puts command
#    puts "Temporary file contains:"
#    system "cat #{tf.path}"
#    system command
  end

  def self.get_password
    if ENV["PASSWORD"]
      @@password = ENV["PASSWORD"]
    else
      begin
        print 'Password: '
        # We hide the entered characters before to ask for the password
        system 'stty -echo'
        @@password = $stdin.gets.chomp
        system 'stty echo'
      rescue NoMethodError, Interrupt
        # When the process is exited, we display the characters again
        # And we exit
        system 'stty echo'
        exit
      end
    end
  end

end

SchoolBaseDumper.dump_tables
