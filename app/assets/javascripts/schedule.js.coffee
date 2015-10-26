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
  $('#topdatepicker').datepicker
    showOtherMonths: true
    selectOtherMonths: true
    dateFormat: 'yy-mm-dd'
    firstDay: $('#fullcalendar').data("firstday")
    defaultDate: $('#fullcalendar').data("defaultdate")
    onSelect: (dateText, inst) ->
      $('#fullcalendar').fullCalendar( 'gotoDate', new Date(dateText))
      $('#topdatepicker').val("").datepicker("hide")
  window.activateCheckboxes()
  $(document).on('opened', '[data-reveal]', ->
    $('#first_field').focus()
    $('#first_field').select()
    $('.datetimepicker').datetimepicker
      dateFormat: "dd/mm/yy"
      stepMinute: 5
    $('.rejection-link').click(window.noClicked)
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
        day: 'ddd D/M'
      timeFormat: 'H:mm',
      header:
        left: 'prev,next today'
        center: 'title'
        right: 'month,agendaWeek,agendaDay,basicDay'
      buttonText:
        basicDay: "day list"
      titleFormat:
        month: 'MMMM YYYY'
        week: 'Do MMM, YYYY'
        day: 'ddd Do MMM, YYYY'
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
        if event.edit_dialogue
          $('#eventModal').foundation('reveal', 'open', {
            url: '/events/' + event.id + '/edit'
          })
        else
          $('#eventModal').foundation('reveal',
                                      'open',
                                      '/events/' + event.id)
      eventDrop: (event, delta, revertFunc) ->
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
        day: 'ddd D/M'
      timeFormat: 'H:mm',
      header:
        left: 'prev,next today'
        center: 'title'
        right: 'month,agendaWeek,agendaDay,basicDay'
      buttonText:
        basicDay: "day list"
      titleFormat:
        month: 'MMMM YYYY'
        week: 'Do MMM, YYYY'
        day: 'ddd Do MMM, YYYY'
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

window.noClicked = (event) ->
  response = prompt("Please give a brief reason for rejecting this request:")
  #
  #  It shouldn't happen, but it's just possible we might get called
  #  twice.  Make sure we don't add the modifier to the string twice.
  #
  base_url = event.target.href.split("?")[0]
  new_url = base_url + "?reason=" + encodeURIComponent(response)
  $(this).attr('href', new_url)
  #$(this).attr('href', event.target.href + "?reason=" + encodeURIComponent(response))
  #alert(event.target.href)
