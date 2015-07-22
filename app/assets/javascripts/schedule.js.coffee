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
  window.activateCheckboxes()
  $(document).on('opened', '[data-reveal]', ->
    $('.datetimepicker').datetimepicker
      dateFormat: "dd/mm/yy"
      stepMinute: 5
    $('#event_starts_at').change( (event) ->
      starts_at = new Date($('#event_starts_at').val())
      ends_at = new Date($('#event_ends_at').val())
      if starts_at > ends_at
        $('#event_ends_at').val($('#event_starts_at').val()))
    $('#event_ends_at').change( (event) ->
      starts_at = new Date($('#event_starts_at').val())
      ends_at = new Date($('#event_ends_at').val())
      if starts_at > ends_at
        $('#event_starts_at').val($('#event_ends_at').val())))
  if ($('.withedit').length)
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
        url: '/schedule/events'
      }]
      dayClick: (date, jsEvent, view) ->
        $('#eventModal').foundation('reveal', 'open', {
          url: '/events/new?date=' + date.format("YYYY-MM-DD HH:mm")
        })
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
          url:  "/events/" + event.id + "/moved"
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
          url:  "/events/" + event.id
          type: "PUT"
          dataType: "json"
          error: (jqXHR, textStatus, errorThrown) ->
            alert("Failed: " + textStatus)
            revertFunc()
          data:
            event:
              new_end: event.end.format()
    $('.dynamic-element').each (index) ->
      window.addEventSource($(this).attr('element_id'))
  else
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
        url: '/schedule/events'
      }]
      eventClick: (event, jsEvent, view) ->
        $('#eventModal').foundation('reveal',
                                    'open',
                                    '/events/' + event.id)

window.addEventSource = (eid) ->
  $('#fullcalendar').fullCalendar('addEventSource',
                                  '/schedule/events?eid=' + eid)

window.removeEventSource = (eid) ->
  $('#fullcalendar').fullCalendar('removeEventSource',
                                  '/schedule/events?eid=' + eid)

window.checkboxFlipped = (thebox) ->
  concern_id = $(thebox).attr("concern_id")
  jQuery.ajax
    url: "/concerns/" + concern_id + "/flipped"
    type: "PUT"
    dataType: "json"
    error: (jqXHR, textStatus, errorThrown) ->
      alert("Failed: " + textStatus)
    success: (data, textStatus, jqXHR) ->
      $('#fullcalendar').fullCalendar('refetchEvents')

window.activateCheckboxes = ->
  $('.active-checkbox').change( ->
    window.checkboxFlipped(this))

