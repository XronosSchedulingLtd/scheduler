#!/usr/bin/env ruby
#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
#  MsSQL Database => CSV data extractor.
#
#  This version is for extracting table contents from iSAMS in order
#  to produce an XML file suitable for our existing importer.
#  

require 'csv'
require 'optparse'

require_relative 'extractor'

tables = [
  DatabaseTable.new("TblPupilManagementPupils",
                    %w(
                        TblPupilManagementPupilsID
                        txtSchoolCode
                        txtSchoolID
                        txtInitials
                        txtTitle
                        txtForename
                        txtSurname
                        txtEmailAddress
                        intNCYear
                        txtFullName
                        txtPreName
                        txtForm
                        txtAcademicHouse
                        txtBoardingHouse
                      ),
                    "WHERE intSystemStatus = 1"
                   ),
  DatabaseTable.new("TblPupilManagementSelections",         :all),
  DatabaseTable.new("TblPupilManagementSelectionsStudents", :all),
  DatabaseTable.new("TblSchoolManagementBuildings",         :all),
  DatabaseTable.new("TblSchoolManagementClassrooms",        :all),
  DatabaseTable.new("TblSchoolManagementForms",             :all),
  DatabaseTable.new("TblSchoolManagementHouses",            :all),
  DatabaseTable.new("TblStaff",
                    %w(
                        TblStaffID
                        txtPreviousMISStaffID
                        Initials
                        NameInitials
                        Title
                        Firstname
                        PreName
                        Surname
                        SchoolEmailAddress
                        Fullname
                        User_Code
                      ),
                    "WHERE SystemStatus = 1"
                   ),
  DatabaseTable.new("TblTeachingManagerSetLists",           :all),
  DatabaseTable.new("TblTeachingManagerSets",               :all),
  DatabaseTable.new("TblTeachingManagerSubjectDepartments", :all),
  DatabaseTable.new("TblTeachingManagerSubjectDepartmentsSubjectLinks", :all),
  DatabaseTable.new("TblTeachingManagerSubjectForms",       :all),
  DatabaseTable.new("TblTeachingManagerSubjects",           :all),
  DatabaseTable.new("TblTimetableManagerCalendar",          :all),
  DatabaseTable.new("TblTimetableManagerDays",              :all),
  DatabaseTable.new("TblTimetableManagerPeriods",           :all),
  DatabaseTable.new("TblTimetableManagerSchedule",          :all),
  DatabaseTable.new("TblTimetableManagerStaffMeetings",     :all),
  DatabaseTable.new("TblTimetableManagerTimetables",        :all),
  DatabaseTable.new("TblTimetableManagerTutorials",         :all),
  DatabaseTable.new("TblTimetableManagerTutorialsPeriods",  :all),
  DatabaseTable.new("TblTimetableManagerTutorialsPupils",   :all),
  DatabaseTable.new("TblTimetableManagerTutorialsTeachers", :all),
  DatabaseTable.new("TblTimetableManagerWeeksAllocations",  :all),
  DatabaseTable.new("TblTimetableManagerWeeks",             :all),
  DatabaseTable.new("TblUsefulLists",                       :all),
  DatabaseTable.new("TbliSAMSManagerUsers",
                    %w(
                        TbliSAMSManagerUsersID
                        txtUserCode
                      )
                   )

]
options = Options.new

DatabaseTable.dump_tables(options, tables)
