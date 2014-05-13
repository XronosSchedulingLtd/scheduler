# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
#`
#$(document).ready(function() {
#    // page is now ready, initialize the calendar...
#    $('#fullcalendar').fullCalendar({
#    })
#});
#`
$(document).ready ->
  $('#fullcalendar').fullCalendar
    currentTimezone: 'Europe/London'
    columnFormat:
      month: 'ddd'
      week: 'ddd D/M'
      day: 'dddd D/M'
    header:
      left: 'prev,next today'
      center: 'title'
      right: 'month,agendaWeek,agendaDay'
    titleFormat:
      month: 'MMMM YYYY'
      week: 'Do MMM, YYYY'
      day: 'dddd Do MMM, YYYY'
    defaultView: "agendaWeek"
    minTime: 6
    firstHour: 8,
    viewDisplay: (view) ->
      $('#datepicker').datepicker('setDate', view.start)
    eventSources: [{
      url: 'schedule/events'
    }]
  $('#datepicker').datepicker
    showOtherMonths: true
    selectOtherMonths: true
    dateFormat: 'yy-mm-dd'
