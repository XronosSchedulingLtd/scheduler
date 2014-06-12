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

TARGET_DIR="/home/john/Work/Coding/scheduler/import/"
UTILITY="/usr/bin/isql"

class SchoolBaseTable
  @@password = nil

  def initialize(table_name, fields)
    @table_name = table_name
    @fields = []
    if fields == :all
      @get_all = true
    else
      @get_all = false
      if fields.is_a?(String)
        @fields << fields
      elsif fields.is_a?(Array)
        fields.each do |field|
          @fields << field
        end
      else
        raise "Can't cope with \"fields\" as a #{fields.class}"
      end
    end
  end

  def columns
    if @get_all
      "*"
    else
      @fields.join(",")
    end
  end

  def dump
    get_password unless @@password
    tf = Tempfile.new("#{@table_name}")
#    puts "Temporary file is #{tf.path}"
    tf.puts "select #{columns} from #{@table_name};"
    tf.close
    command = "#{UTILITY} Schoolbase winters #{@@password} -b -d, -q -c <#{tf.path} >#{TARGET_DIR}#{@table_name}.csv"
#    puts "Command is:"
#    puts command
#    puts "Temporary file contains:"
#    system "cat #{tf.path}"
    system command
  end

  def get_password
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

TABLES = [SchoolBaseTable.new("academicrecord", :all),
          SchoolBaseTable.new("academicyear", :all),
          SchoolBaseTable.new("curriculum",
                              ["CurrIdent",
                               "AcYearIdent",
                               "YearIdent",
                               "SubjectIdent"]),
          SchoolBaseTable.new("groups",
                              ["GroupIdent",
                               "GroupName"]),
          SchoolBaseTable.new("house",
                              ["HouseIdent",
                               "HouseName",
                               "PType"]),
          SchoolBaseTable.new("period",
                              ["Period",
                               "DayName",
                               "TeachingPeriod",
                               "PeriodWeek"]),
          SchoolBaseTable.new("periodtimes",
                              ["PeriodTimesIdent",
                               "PeriodTimeStart",
                               "PeriodTimeEnd",
                               "Period",
                               "PeriodTimeSetIdent"]),
          SchoolBaseTable.new("pupil",
                              ["PupOrigNum",
                               "Pu_Surname",
                               "Pu_Firstname",
                               "Pu_GivenName",
                               "PupilDisplayName",
                               "PupReportName",
                               "PupEmail",
                               "Pu_CandNo",
                               "YearIdent",
                               "Pu_Doe",
                               "PupDateofLeaving",
                               "PType"]),
          SchoolBaseTable.new("room",
                              ["RoomIdent",
                               "Room",
                               "RoomName"]),
          SchoolBaseTable.new("staff",
                              ["UserIdent",
                               "UserName",
                               "UserMnemonic",
                               "UserSurname",
                               "UserTitle",
                               "UserForename",
                               "UserEmail"]),
          SchoolBaseTable.new("subjects",
                              ["SubCode",
                               "SubName",
                               "SubIdent"]),
          SchoolBaseTable.new("timetable",
                              ["TimetableIdent",
                               "GroupIdent",
                               "StaffIdent",
                               "RoomIdent",
                               "Period",
                               "AcYearIdent"]),
          SchoolBaseTable.new("tutorgroup",
                              ["UserIdent",
                               "YearIdent",
                               "PupOrigNum",
                               "Pu_House"]),
          SchoolBaseTable.new("years",
                              ["YearIdent",
                               "YearDesc",
                               "YearName",
                               "Ptype"]),
          SchoolBaseTable.new("staffcovers",
                              ["StaffAbLineIdent",
                               "AbsenceDate",
                               "UserIdent",
                               "Staff",
                               "PType"]),
          SchoolBaseTable.new("staffabline",
                              ["StaffAbLineIdent",
                               "StaffAbIdent",
                               "StaffAbsenceDate",
                               "Period",
                               "StaffAbCoverNeed",
                               "UserIdent",
                               "RoomIdent",
                               "TimetableIdent"]),
          SchoolBaseTable.new("staffabsence",
                              ["StaffAbIdent",
                               "StaffAbsenceDate",
                               "Period",
                               "StaffAbsenceDate2",
                               "Period2",
                               "UserIdent"])]

TABLES.each do |table|
  table.dump
end
