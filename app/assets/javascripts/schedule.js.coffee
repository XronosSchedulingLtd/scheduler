###*
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# Licensed under the GNU GPL, version 2.
# See COPYING and LICENCE in the root directory of the application
# for more information.
###
#
#  Because this bit of the program is written in CoffeeScript I can
#  be as copious as I like with the comments without worrying about
#  there being any overhead at all.  The comments will be stripped
#  out by the CoffeeScript compiler.
#
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
  $(document).on('opened', '[data-reveal]', ->
    $('#first_field').focus()
    $('#first_field').select()
    primeCloser()
    $('.datetimepicker').datetimepicker
      dateFormat: "dd/mm/yy"
      stepMinute: 5
    $('.rejection-link').click(noClicked)
    activateColourPicker('#dynamic_colour_picker', '#dynamic_colour_sample')
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
  #
  #  These are the parameters which we use to initialize FullCalendar
  #  regardless.
  #
  fcParams =
    height: 'parent'
    currentTimezone: 'Europe/London'
    header:
      left: 'prev,next today'
      center: 'title'
      right: 'month,agendaWeek,agendaDay,basicDay,listMonth'
    buttonText:
      basicDay: "day list"
    views:
      month:
        columnFormat: 'ddd'
        titleFormat: 'MMMM YYYY'
      week:
        columnFormat: 'ddd D/M'
        titleFormat: 'Do MMM, YYYY'
      day:
        columnFormat: 'ddd D/M'
        titleFormat: 'ddd Do MMM, YYYY'
    timeFormat: 'H:mm',
    defaultView: "agendaWeek"
    eventOrder: "sort_by"
    firstDay: $('#fullcalendar').data("firstday")
    defaultDate: $('#fullcalendar').data("defaultdate")
    snapDuration: "00:05"
    minTime: "06:00"
    scrollTime: "08:00"
    viewRender: (view, element) ->
      prepareToRender(view, element)
    eventRender: (event, element) ->
      tweakElement(event, element)
    eventAfterAllRender: (view) ->
      allRendered(view)
    eventSources: [{
      url: '/schedule/events'
    }]
    eventClick: (event, jsEvent, view) ->
      $('#eventModal').foundation('reveal',
                                  'open',
                                  '/events/' + event.id)
  #
  #  And these are the extra ones which we use if the user can edit
  #  events.
  #
  editFcParams =
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
    drop: (starts_at, jsEvent, ui) ->
      $('#eventModal').foundation('reveal', 'open', {
        url: newEventUrl(starts_at, null, $(this).data("eid"))
      })
    selectable: true
    selectHelper: true
    select: (starts_at, ends_at, jsEvent, view) ->
      $('#fullcalendar').fullCalendar('unselect')
      if ends_at - starts_at > 300000
        $('#eventModal').foundation('reveal', 'open', {
          url: newEventUrl(starts_at, ends_at)
        })
      else
        $('#eventModal').foundation('reveal', 'open', {
          url: newEventUrl(starts_at)
        })
  if ($('.withedit').length)
    $.extend(fcParams, editFcParams)
  $('#fullcalendar').fullCalendar(fcParams)
  $('.dynamic-element').each (index) ->
    addEventSource($(this).data('cid'))
  activateUserColumn()

newEventUrl = (starts_at, ends_at, precommit) ->
  #
  #  It may seem slightly odd to pass up the all_day flag separately
  #  given that it is derived from the starts_at field.  However it
  #  is technically possible to have a timed event which starts at
  #  00:00, even though the UI doesn't currently allow it.
  #  At this point we know the difference, but once the time has been
  #  turned into text we won't.  By adding the extra flag we preserve
  #  that information.
  #
  "/events/new?starts_at=#{
      starts_at.format("YYYY-MM-DD HH:mm")
    }#{
      if starts_at.hasTime()
        ""
      else
        "&all_day"
    }#{
      if ends_at
        "&ends_at=#{ends_at.format("YYYY-MM-DD HH:mm")}"
      else
        ""
    }#{
      if precommit
        "&precommit=#{precommit}"
      else
        ""
    }"

addEventSource = (cid) ->
  $('#fullcalendar').fullCalendar('addEventSource',
                                  '/schedule/events?cid=' + cid)

removeEventSource = (cid) ->
  $('#fullcalendar').fullCalendar('removeEventSource',
                                  '/schedule/events?cid=' + cid)

checkboxFlipped = (thebox) ->
  concern_id = $(thebox).data('cid')
  jQuery.ajax
    url: "/concerns/" + concern_id + "/flipped?state=" + if thebox.checked then "on" else "off"
    type: "PUT"
    dataType: "json"
    error: (jqXHR, textStatus, errorThrown) ->
      refreshConcerns()
    success: (data, textStatus, jqXHR) ->
      $('#fullcalendar').fullCalendar('refetchEvents')

refreshConcerns = ->
  $('#current_user').load('/concerns/sidebar', activateCheckboxes)
  $('#fullcalendar').fullCalendar('refetchEvents')

noClicked = (event) ->
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

concernClicked = (event) ->
  if $(this).hasClass('noclick')
    $(this).removeClass('noclick')
  else
    target = $(this).data('link-target')
    if target
      location.href = target

activateColourPicker = (field_id, sample_id) ->
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

prepareToRender = (view, element) ->
  $('#datepicker').datepicker('setDate', view.start.toDate())
  @viewStartDate = view.start.toDate()
  @viewName = view.name
  @elementsSeen = {}

allRendered = (view) ->
  @elementsSeen = {}

tweakElement = (event, element) ->
  if event.prefix
    #
    #  We are being asked, at least some of the time, to put a prefix
    #  on the event's title.  We do this only for elements which show
    #  the chronological start of the event - not those where it
    #  is just continuing.
    #
    if event.start >= @viewStartDate
      if (@viewName == "agendaWeek" ||
          @viewName == "agendaDay" ||
          @viewName == "basicDay")
        element.find('.fc-title').prepend(event.prefix)
      else if @viewName == "month"
        #
        #  This one takes a bit more thought.  The event may occur in
        #  several elements, and only the first gets the prefix.
        #
        if !@elementsSeen[event.id]
          @elementsSeen[event.id] = true
          element.find('.fc-title').prepend(event.prefix)
  #
  #  And now, do we need to add an icon?
  #
  if event.has_clashes
    icon = "rc.png"
  else if event.fc == "r"
    icon = "rf.png"
  else if event.fc == "y"
    icon = "yf.png"
  else if event.fc == "g"
    icon = "gf.png"
  else
    icon = null
  if icon
      #
      #  Have something.  Now decide where to put it, which depends on
      #  which view we are using.  This is quite hard.  See journal
      #  notes for 9th May, 2017 for an explanation of the various
      #  problems which resulted in this compromise solution.
      #
    if @viewName == "basicDay"
      element.find(".fc-time").
              before("<span><img src=\"images/#{icon}\" /></span>")
    else if @viewName == "agendaDay"
      element.find(".fc-content").
              append("<img class=\"evnearleft\" src=\"images/#{icon}\" />")
    else if @viewName == "agendaWeek" || @viewName == "month"
      element.find(".fc-content").
              append("<img class=\"evtopright\" src=\"images/#{icon}\" />")
  return true


activateCheckboxes = ->
  $('.active-checkbox').change( ->
    checkboxFlipped(this))

activateDragging = ->
  $('.dynamic-element').each (index) ->
    $(this).click(concernClicked)
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

activateAutoSubmit = ->
  $('.auto_submit_item').on( "autocompleteclose", (event, ui) ->
    if $('#concern_element_id').val().length > 0
      $('.hidden_submit').click())

activateUserColumn = ->
  activateCheckboxes()
  activateDragging()
  activateAutoSubmit()

primeCloser = ->
  $('.closer').click ->
    $('#eventModal').foundation('reveal', 'close')

hideCloser = ->
  $('#event-done-button').hide()

showCloser = ->
  $('#event-done-button').show()

#
#  All entrypoints - functions which can be called from outside this
#  module - are now below here.  Trying to cut them down.
#

window.updateUserColumn = (newContents, added, removed, doReload) ->
  $('#current_user').html(newContents)
  if doReload
    #
    #  Nothing added or removed, but we've changed at least one
    #  of the ticks, so re-fetch the events.
    #
    $('#fullcalendar').fullCalendar('refetchEvents')
  else
    if added
      addEventSource(added)
    else if removed
      removeEventSource(removed)
  #
  #  And now re-activate everything.
  #
  activateUserColumn()
  $('#concern_name').focus()

window.replaceShownCommitments = (new_html) ->
  $('#show-all-commitments').html(new_html)
  $('.rejection-link').click(noClicked)
  $('#fullcalendar').data("dorefresh", "1")

window.replaceEditingCommitments = (new_html) ->
  $('#event_resources').html(new_html)
  $('#fullcalendar').data("dorefresh", "1")

window.beginNoteEditing = (body_text) ->
  $('#event-notes').html(body_text)
  $('#note_contents').focus()
  hideCloser()

window.endNoteEditing = (new_note_text, new_shown_commitments) ->
  $('#event-notes').html(new_note_text)
  if new_shown_commitments
    window.replaceShownCommitments(new_shown_commitments)
  showCloser()

window.finishEditingEvent = (event_summary, do_refresh) ->
  $('#events-dialogue').html(event_summary)
  primeCloser()
  if do_refresh
    $('#fullcalendar').data('dorefresh', '1')


