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
  $('#datepicker').datepicker
    showOtherMonths: true
    selectOtherMonths: true
    dateFormat: 'yy-mm-dd',
    onSelect: (dateText, inst) ->
      $('#fullcalendar').fullCalendar( 'gotoDate', new Date(dateText))
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
    viewRender: (view, element) ->
      $('#datepicker').datepicker('setDate', view.start.toDate())
    eventSources: [{
      url: 'schedule/events'
    }]
