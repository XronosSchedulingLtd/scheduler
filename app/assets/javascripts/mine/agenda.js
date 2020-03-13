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
        eventSources: [{
          url: '/agenda/events'
        }],
        eventStartEditable: false,
        eventDurationEditable: false,
        eventClick: that.handleClick
      };
      that.myDiv.fullCalendar(fcParams);
      $(document).on('closed', '[data-reveal]', modalClosed);
    };

    that.handleClick = function(event, jsEvent, view) {
      if (that.doZoomLinks) {
        if (event.zoomId.length) {
          window.open(that.zoomLinkBaseUrl + event.zoomId, '_blank');
        }
      }
    };

    return that;
  }();

  $(personalAgendaCode.init);
}
