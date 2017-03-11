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
    window.primeCloser()
    $('.datetimepicker').datetimepicker
      dateFormat: "dd/mm/yy"
      stepMinute: 5
    $('.rejection-link').click(window.noClicked)
    window.activateColourPicker('#dynamic_colour_picker', '#dynamic_colour_sample')
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
  $(document).on('closed', '[data-reveal]', ->
    flag = $('#fullcalendar').data("dorefresh")
    if flag == "1"
      $('#fullcalendar').data("dorefresh", "0")
      $('#fullcalendar').fullCalendar('refetchEvents')
    )
  window.activateAutoSubmit()
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
      eventRender: (event, element) ->
        window.flagClashes(event, element)
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
      window.addEventSource($(this).data('cid'))
    window.activateDragging()
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
      eventRender: (event, element) ->
        window.flagClashes(event, element)
      eventSources: [{
        url: '/schedule/events'
      }]
      eventClick: (event, jsEvent, view) ->
        $('#eventModal').foundation('reveal',
                                    'open',
                                    '/events/' + event.id)
    $('.dynamic-element').each (index) ->
      window.addEventSource($(this).data('cid'))
    window.activateDragging()

window.addEventSource = (cid) ->
  $('#fullcalendar').fullCalendar('addEventSource',
                                  '/schedule/events?cid=' + cid)

window.removeEventSource = (cid) ->
  $('#fullcalendar').fullCalendar('removeEventSource',
                                  '/schedule/events?cid=' + cid)

window.checkboxFlipped = (thebox) ->
  concern_id = $(thebox).data('cid')
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
  $('.dynamic-element').each (index) ->
    $(this).click(window.concernClicked)
  if ($('.withedit').length)
    $('.dynamic-element').each (index) ->
      $(this).draggable
        revert: true
        revertDuration: 0
        zIndex: 100
        cursorAt:
          top: 0
        start: (event, ui) ->
          $(this).addClass('noclick')
      $(this).droppable();

window.refreshConcerns = ->
  $('#current_user').load('/concerns/sidebar', window.activateCheckboxes)
  $('#fullcalendar').fullCalendar('refetchEvents')

window.replaceShownCommitments = (new_html) ->
  $('#show-all-commitments').html(new_html)
  $('.rejection-link').click(window.noClicked)
  $('#fullcalendar').data("dorefresh", "1")

window.replaceEditingCommitments = (new_html) ->
  $('#event_resources').html(new_html)
  $('#fullcalendar').data("dorefresh", "1")

window.noClicked = (event) ->
  response = prompt("Please state the problem briefly:")
  if response == null
    #
    #  User clicked cancel.
    #
    return false
  else
    #
    #  It shouldn't happen, but it's just possible we might get called
    #  twice.  Make sure we don't add the modifier to the string twice.
    #
    base_url = event.target.href.split("?")[0]
    new_url = base_url + "?reason=" + encodeURIComponent(response)
    $(this).attr('href', new_url)

window.concernClicked = (event) ->
  if $(this).hasClass('noclick')
    $(this).removeClass('noclick')
  else
    target = $(this).data('link-target')
    if target
      location.href = target

window.primeCloser = ->
  $('.closer').click ->
    $('#eventModal').foundation('reveal', 'close')

window.hideCloser = ->
  $('#event-done-button').hide()

window.showCloser = ->
  $('#event-done-button').show()

window.resized = (event) ->
  $('#fullcalendar').fullCalendar('option',
                                  'height',
                                  $(window).height() - 46)

window.activateColourPicker = (field_id, sample_id) ->
  palette = ["#483D8B", "#CD5C5C", "#B8860B", "#7B68EE",
             "#808000", "#6B8E23", "#DB7093", "#2E8B57",
             "#A0522D", "#008080", "#3CB371", "#2F4F4F",
             "#556B2F", "#FF6347"]
  extra = $(field_id).data('default-colour')
  if extra
    palette.push extra
  $(field_id).spectrum
    preferredFormat: "hex"
    showInitial: true
    showPalette: true
    showSelectionPalette: true
    palette: palette
    appendTo: $(sample_id)
    change: (colour) ->
      $(sample_id).css('background-color', colour.toHexString())

window.flagClashes = (event, element) ->
  if event.has_clashes
    element.find(".fc-event-inner").append("<img class=\"evtopright\" src=\"images/rc.png\" />")
  else if event.fc == "r"
    element.find(".fc-event-inner").append("<img class=\"evtopleft\" src=\"images/rf.png\" />")
  else if event.fc == "y"
    element.find(".fc-event-inner").append("<img class=\"evtopleft\" src=\"images/yf.png\" />")
  else if event.fc == "g"
    element.find(".fc-event-inner").append("<img class=\"evtopleft\" src=\"images/gf.png\" />")
  return true

window.activateAutoSubmit = ->
  $('.auto_submit_item').on( "autocompleteclose", (event, ui) ->
    if $('#concern_element_id').val().length > 0
      $('.hidden_submit').click())
