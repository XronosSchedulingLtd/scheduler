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
        defaultView: 'timelineWeek',
        resourceGroupField: 'parentName',
        events: [
          {
            id: '1',
            resourceId: 'a',
            title: 'Meeting',
            start: '2018-10-22'
          }
        ]
      };
      var moreParams = JSON.parse($('#fc-parameters').text());
      $.extend(fcParams, moreParams);
      that.myDiv.fullCalendar(fcParams);
    };

    return that;
  }();

  $(groupScheduleCode.init);
}
