#!/usr/bin/env ruby
#
#  A ruby script to fetch all the reguired data from SchoolBase.  There are
#  a number of tables, and for security we don't want to fetch all columns
#  from some of them.
#
#  I could connect Ruby directly to UnixODBC, but for now I'm going to
#  invoke the command line isql utility.
#

require 'tempfile'
require 'csv'

TARGET_DIR="/home/john/Work/Coding/scheduler/import/tables/"
UTILITY="/usr/bin/isql"

class SchoolBaseScanner
  @@password = nil

  def self.invoke_sql(command, output_file = nil)
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

  def self.scan_tables
    get_password unless @@password
    listing = self.invoke_sql("help")
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
          self.invoke_sql("select count(*) from [#{table_name}];", "#{TARGET_DIR}#{table_name}.count")
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

SchoolBaseScanner.scan_tables
