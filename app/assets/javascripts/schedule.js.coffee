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
    dateFormat: 'yy-mm-dd'
    firstDay: $('#fullcalendar').data("firstday")
    onSelect: (dateText, inst) ->
      $('#fullcalendar').fullCalendar( 'gotoDate', new Date(dateText))
  window.activateCheckboxes()
  $(document).on('opened', '[data-reveal]', ->
    $('#first_field').focus()
    $('#first_field').select()
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
      firstDay: $('#fullcalendar').data("firstday")
      defaultDate: $('#fullcalendar').data("defaultdate")
      snapDuration: "00:05"
      minTime: "06:00"
      scrollTime: "08:00"
      viewRender: (view, element) ->
        $('#datepicker').datepicker('setDate', view.start.toDate())
      eventSources: [{
        url: '/schedule/events'
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
      droppable: true
      drop: (date, jsEvent, ui) ->
        $('#eventModal').foundation('reveal', 'open', {
          url: '/events/new?date=' +
               date.format("YYYY-MM-DD HH:mm") +
               '&precommit=' +
               $(this).data("eid")
        })
      selectable: true
      selectHelper: true
      select: (start_time, end_time, jsEvent, view) ->
        $('#fullcalendar').fullCalendar('unselect')
        if end_time - start_time > 300000
          $('#eventModal').foundation('reveal', 'open', {
            url: '/events/new?date=' +
                 start_time.format("YYYY-MM-DD HH:mm") +
                 '&enddate=' +
                 end_time.format("YYYY-MM-DD HH:mm")
          })
        else
          $('#eventModal').foundation('reveal', 'open', {
            url: '/events/new?date=' +
                 start_time.format("YYYY-MM-DD HH:mm")
          })
    $('.dynamic-element').each (index) ->
      window.addEventSource($(this).attr('concern_id'))
      $(this).draggable({revert: true, revertDuration: 0, zIndex: 100, cursorAt: { top: 0 }})
      $(this).droppable();
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
      firstDay: $('#fullcalendar').data("firstday")
      defaultDate: $('#fullcalendar').data("defaultdate")
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
    $('.dynamic-element').each (index) ->
      window.addEventSource($(this).attr('concern_id'))

window.addEventSource = (cid) ->
  $('#fullcalendar').fullCalendar('addEventSource',
                                  '/schedule/events?cid=' + cid)

window.removeEventSource = (cid) ->
  $('#fullcalendar').fullCalendar('removeEventSource',
                                  '/schedule/events?cid=' + cid)

window.checkboxFlipped = (thebox) ->
  concern_id = $(thebox).attr("concern_id")
  jQuery.ajax
    url: "/concerns/" + concern_id + "/flipped?state=" + if thebox.checked then "on" else "off"
    type: "PUT"
    dataType: "json"
    error: (jqXHR, textStatus, errorThrown) ->
      window.refreshConcerns()
    success: (data, textStatus, jqXHR) ->
      $('#fullcalendar').fullCalendar('refetchEvents')

window.activateCheckboxes = ->
  $('.active-checkbox').change( ->
    window.checkboxFlipped(this))

window.activateDragging = ->
  if ($('.withedit').length)
    $('.dynamic-element').each (index) ->
      $(this).draggable({revert: true, revertDuration: 0, zIndex: 100, cursorAt: { top: 0 }})
      $(this).droppable();

window.refreshConcerns = ->
  $('#current_user').load('/concerns/sidebar', window.activateCheckboxes)
  $('#fullcalendar').fullCalendar('refetchEvents')
