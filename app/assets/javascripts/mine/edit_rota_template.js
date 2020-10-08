"use strict";

//
//  Do nothing at all unless we are on the right page.
//
if ($('#editing-rota-template').length) {

//
//  Wrap everything in a function to avoid namespace pollution
//  Note that we invoke the function immediately.
//
var editing_rota_templates = function() {

  var that = {};

  var myDiv = $('#editing-rota-template');

  var fcParams = {
    schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
    currentTimezone: 'Europe/London',
    header: {
      left: null,
      center: null,
      right: null
    },
    timeFormat: 'H:mm',
    defaultView: "agendaWeek",
    eventOrder: "sort_by",
    snapDuration: "00:05",
    minTime: "06:00",
    scrollTime: "08:00",
    allDaySlot: false,
    columnHeaderText: function(mom) {
      return mom.format('ddd');
    },
    defaultDate: '2020-01-01'
  }

  that.init = function() {
    //
    //  We have already checked that our master parent division
    //  exists, otherwise we wouldn't be running at all.
    //
    myDiv.fullCalendar(fcParams)
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(editing_rota_templates.init);

}
