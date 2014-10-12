#!/bin/bash
cd ~/Work/Coding/scheduler/import
mv Abingdon.ics Abingdon.ics.prev
/usr/bin/wget http://calendar.abingdon.org.uk/schoolcalendars/remote/ical.php/10/Abingdon.ics
