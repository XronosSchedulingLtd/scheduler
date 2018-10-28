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
          right:  'timelineDay,timelineThreeDays,timelineFourDays,timelineWeek'
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
          },
          timelineThreeDays: {
            type: 'timeline',
            duration: { days: 3 }
          },
          timelineFourDays: {
            type: 'timeline',
            duration: { days: 4 }
          }
        },
        defaultView: 'timelineDay',
        slotDuration: "02:00:00",
        slotLabelInterval: "06:00:00",
        minTime: "06:00:00",
        maxTime: "21:00:00",
        resourceGroupField: 'parentName',
        resourceColumns: [
//          {
//            group: true,
//            labelText: 'Grouping',
//            field:     'parentName'
//          },
          {
            labelText: 'Resource',
            field:     'title'
          },
          {
            labelText: '',
            width:     22,
            text: function() { return '';},
            render: function(resource, el) {
              if (resource.colour) {
                el.css('background-color', resource.colour);
              }
            }
          }
        ],
        events: {
          color: '#1f94bc'
        },
        eventStartEditable: false,
        eventDurationEditable: false,
        eventDrop: that.handleDrop
      };
      var groupId = that.myDiv.data('groupid');
      fcParams.resources  = '/groups/' + groupId + '/scheduleresources';
      fcParams.events.url = '/groups/' + groupId + '/scheduleevents';
      that.myDiv.fullCalendar(fcParams);
    };

    that.handleDrop = function(event, delta, revertFunc) {
      var requestId = event.requestId;
      if (requestId == 0) {
        //
        //  This particular displayed event does not relate to a request
        //  and therefore it makes no sense to drag it.  Put things back.
        //
        revertFunc();
      } else {
        //
        //  Need to establish where it has been dropped, and pass that
        //  information to the server.  The server may still reject the
        //  change.
        //
        jQuery.ajax({
          url: "/requests/" + requestId + "/dragged",
          type: "PUT",
          dataType: "json",
          data: {
            element_id: event.resourceId,
            item_id: event.id
          },
          success: function(data, textStatus, jqXHR) {
            if (data.message) {
              alert(data.message);
              revertFunc();
            } else {
              that.myDiv.fullCalendar('refetchEvents');
            }
          },
          error: function(jqXHR, textStatus, errorThrown) {
            alert("Failed: " + textStatus);
            revertFunc();
          }
        });
      }
      
    };
//    eventDrop: (event, delta, revertFunc) ->
//      jQuery.ajax
//        url:  "/events/" + event.id + "/moved"
//        type: "PUT"
//        dataType: "json"
//        error: (jqXHR, textStatus, errorThrown) ->
//          alert("Failed: " + textStatus)
//          revertFunc()
//        data:
//          event:
//            new_start: event.start.format()
//            all_day: !event.start.hasTime()
    return that;
  }();

  $(groupScheduleCode.init);
}
