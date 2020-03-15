"use strict";

if ($('#personal-agenda').length) {
  var personalAgendaCode = function() {
    var that = {};

    var modalClosed = function() {
      //
      //  The dorefresh flag is set using a class selector, so a single bit
      //  of setting code can set it anywhere in the whole application.
      //
      //  However, it's checked using a specific ID, because we want to
      //  check our very own instance.  We also reset it by ID, so we affect
      //  only ours.
      //
      var flag = that.myDiv.data('dorefresh');
      if (flag == "1") {
        that.myDiv.data('dorefresh', '0');
        that.myDiv.fullCalendar('refetchEvents')
      }
    }

    var handleClick = function(event, jsEvent, view) {
      if (that.doZoomLinks) {
        if (event.hasOwnProperty('zoomId')) {
          window.open(that.zoomLinkBaseUrl + event.zoomId, '_blank');
        }
      }
    }

    //
    //  Test whether the indicated fullCalendar event is currently
    //  active-ish.  We look at the current time and if that lies between
    //  15 minutes before the start of the event, and 5 minutes after
    //  the end then we count it as active-ish.
    //
    var currentlyActiveish = function(event) {
      var time_now = moment();
      //
      //  The Moment.js library is slightly odd in that the subtract()
      //  and add() methods actually modify the Moment on which
      //  you call them!  You need to clone the Moment first if
      //  you want to keep your original Moment intact.
      //
      var effective_start = moment(event.start).subtract(15, 'minutes');
      var effective_end   = moment(event.end).add(5, 'minutes');

      if (time_now.isAfter(effective_start) &&
          time_now.isBefore(effective_end)) {
//        console.log("Starts at " + event.start.format());
//        console.log("Ends at   " + event.end.format());
//        console.log("Now       " + time_now.format());
        return true;
      } else {
        return false;
      }
    }

    var startingToRender = function(view, element) {
      that.elementList = [];
    }

    //
    //  As we're not using ES6, can't use string interpolation
    //
    var zoomText = function(zoomLinkText, active) {
      if (active) {
        return ' '.concat("<span class='zoom-link zl-active'>",
                          zoomLinkText,
                          "</span>")
      } else {
        return ' '.concat("<span class='zoom-link'>",
                          zoomLinkText,
                          "</span>")
      }
    }

    var addZoomText = function(event, element) {
      currentlyActiveish(event);
      if (that.doZoomLinks) {
        if (event.hasOwnProperty('zoomId')) {
          element.find('.fc-list-item-title').
                  append(zoomText(that.zoomLinkText,
                                  currentlyActiveish(event)));
          var eventRecord = {
            event: event,
            element: element
          }
          that.elementList.push(eventRecord);
        }
      }
    }

    var updateActiveness = function(er) {
      var thing = er.element.find('.zoom-link');
      if (thing) {
        if (currentlyActiveish(er.event)) {
          thing.addClass('zl-active');
        } else {
          thing.removeClass('zl-active');
        }
      }
    }

    var handleTimer = function() {
//      console.log("Tick");
      that.elementList.forEach(updateActiveness);
    }

    var stopTimer = function() {
//      console.log("Stopping timer.");
      window.clearInterval(that.timerID);
      that.elementList = [];
    }

    var startTimer = function() {
//      console.log("Starting timer.");
      that.timerID = window.setInterval(handleTimer, 60000);
      window.addEventListener("beforeunload", stopTimer);
    }

    that.init = function() {
      that.myDiv = $('#personal-agenda');
      var zoomFlag = that.myDiv.data('do-zoom-links');
      if (zoomFlag == "1") {
        that.doZoomLinks = true;
        that.zoomLinkText = that.myDiv.data('zoom-link-text');
        that.zoomLinkBaseUrl = that.myDiv.data('zoom-link-base-url');
      } else {
        that.doZoomLinks = false;
        that.zoomLinkText = "";
        that.zoomLinkBaseUrl = "";
      }
      that.elementList = [];

      var fcParams = {
        schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
        height: 'parent',
        currentTimezone: 'Europe/London',
        views: {
          week: {
            titleFormat: 'Do MMMM'
          }
        },
        header: {
          left: '',
          center: 'title'
        },
        defaultView: 'listWeek',
        defaultDate: that.myDiv.data("defaultdate"),
        eventSources: [{
          url: '/agenda/events'
        }],
        viewRender: startingToRender,
        eventStartEditable: false,
        eventDurationEditable: false,
        eventClick: handleClick,
        eventRender: addZoomText
      };
      that.myDiv.fullCalendar(fcParams);
      $(document).on('closed', '[data-reveal]', modalClosed);
      startTimer();
    };

    return that;
  }();

  $(personalAgendaCode.init);
}
