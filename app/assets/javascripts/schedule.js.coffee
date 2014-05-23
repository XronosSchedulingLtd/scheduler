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
  $(document).on('opened', '[data-reveal]', ->
    $('.datetimepicker').datetimepicker
      dateFormat: "dd/mm/yy"
      stepMinute: 5)
  $('#fullcalendar').fullCalendar
    currentTimezone: 'Europe/London'
    columnFormat:
      month: 'ddd'
      week: 'ddd D/M'
      day: 'dddd D/M'
    timeFormat: 'H:mm',
    header:
      left: 'prev,next today'
      center: 'title'
      right: 'month,agendaWeek,agendaDay'
    titleFormat:
      month: 'MMMM YYYY'
      week: 'Do MMM, YYYY'
      day: 'dddd Do MMM, YYYY'
    defaultView: "agendaWeek"
    snapDuration: "00:05"
    minTime: "06:00"
    scrollTime: "08:00"
    viewRender: (view, element) ->
      $('#datepicker').datepicker('setDate', view.start.toDate())
    eventSources: [{
      url: 'schedule/events'
    }]
    eventClick: (event, jsEvent, view) ->
      if event.editable
        $('#eventModal').foundation('reveal', 'open', {
          url: '/events/' + event.id + '/edit'
        })
      else
        $('#eventModal').foundation('reveal',
                                    'open',
                                    '/events/' + event.id)
    eventDrop: (event, revertFunc) ->
      jQuery.ajax
        url:  "events/" + event.id + "/moved"
        type: "PUT"
        dataType: "json"
        error: (jqXHR, textStatus, errorThrown) ->
          alert("Failed: " + textStatus)
          revertFunc()
        data:
          event:
            new_start: event.start.format()
            all_day: !event.start.hasTime()
    eventResize: (event, revertFunc) ->
      jQuery.ajax
        url:  "events/" + event.id
        type: "PUT"
        dataType: "json"
        error: (jqXHR, textStatus, errorThrown) ->
          alert("Failed: " + textStatus)
          revertFunc()
        data:
          event:
            new_end: event.end.format()
