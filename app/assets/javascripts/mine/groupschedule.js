"use strict";

if ($('#groupschedule').length) {
  var groupScheduleCode = function() {
    var that = {};

    that.init = function() {
      that.myDiv = $('#groupschedule');
      var fcParams = {
        schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
        height: 'parent',
        currentTimezone: 'Europe/London',
        header: {
          left:   'prev,next today',
          center: 'title',
          right:  'timelineDay,timelineWeek,timelineMonth'
        },
        views: {
          month: {
            titleFormat: 'MMMM YYYY'
          },
          week: {
            titleFormat: 'Do MMM, YYYY'
          },
          day: {
            titleFormat: 'ddd Do MMM, YYYY'
          }
        },
        defaultView: 'timelineDay',
        resourceGroupField: 'parentName',
        events: {
          color: '#1f94bc'
        }
      };
      var groupId = that.myDiv.data('groupid');
      fcParams.resources  = '/groups/' + groupId + '/scheduleresources';
      fcParams.events.url = '/groups/' + groupId + '/scheduleevents';
      that.myDiv.fullCalendar(fcParams);
    };

    return that;
  }();

  $(groupScheduleCode.init);
}
