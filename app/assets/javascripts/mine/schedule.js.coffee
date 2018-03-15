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
that = {}
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
    $('.noted-link').click(notedClicked)
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
        $('#event_starts_at').val($('#event_ends_at').val()))
    filter_dialogue = $('#filter-dialogue')
    if filter_dialogue.length > 0
      filter_dialogue.find('#all').click(wantsAll)
      filter_dialogue.find('#none').click(wantsNone)
    primePreRequisites()
  )

  $(document).on('closed', '[data-reveal]', ->
    #
    #  The dorefresh flag is set using a class selector, so a single bit
    #  of setting code can set it anywhere in the whole application.
    #
    #  However, it's checked using a specific ID, because we want to
    #  check our very own instance.  We also reset it by ID, so we affect
    #  only ours.
    #
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
    timeFormat: 'H:mm'
    nowIndicator: true
    defaultView: "agendaWeek"
    eventOrder: "sort_by"
    firstDay: $('#fullcalendar').data("firstday")
    defaultDate: $('#fullcalendar').data("defaultdate")
    snapDuration: "00:05"
    minTime: "06:00"
    scrollTime: "08:00"
    viewRender: prepareToRender
    eventRender: tweakElement
    eventAfterAllRender: allRendered
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

notedClicked = (event) ->
  response = prompt("Additional information for requester - (optional):")
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

filterClicked = (event) ->
  $('#eventModal').foundation(
    'reveal',
    'open',
    "/users/#{$('div#filter-switch').data('userid')}/filters/1/edit")

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
  that.viewStartDate = view.start.toDate()
  that.viewName = view.name
  that.elementsSeen = {}

allRendered = (view) ->
  that.elementsSeen = {}

tweakElement = (event, element) ->
  if event.prefix
    #
    #  We are being asked, at least some of the time, to put a prefix
    #  on the event's title.  We do this only for elements which show
    #  the chronological start of the event - not those where it
    #  is just continuing.
    #
    if event.start >= that.viewStartDate
      if (that.viewName == "agendaWeek" ||
          that.viewName == "agendaDay" ||
          that.viewName == "basicDay")
        element.find('.fc-title').prepend(event.prefix)
      else if that.viewName == "month"
        #
        #  This one takes a bit more thought.  The event may occur in
        #  several elements, and only the first gets the prefix.
        #
        if !that.elementsSeen[event.id]
          that.elementsSeen[event.id] = true
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
    if that.viewName == "basicDay"
      element.find(".fc-time").
              before("<span><img src=\"images/#{icon}\" /></span>")
    else if that.viewName == "agendaDay"
      element.find(".fc-content").
              append("<img class=\"evnearleft\" src=\"images/#{icon}\" />")
    else if that.viewName == "agendaWeek" || that.viewName == "month"
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
    $('.draggable-element').each (index) ->
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

activateFilterSwitch = ->
  $('div#filter-switch').click(filterClicked)

activateUserColumn = ->
  activateCheckboxes()
  activateDragging()
  activateAutoSubmit()
  activateFilterSwitch()

primeCloser = ->
  $('.closer').click ->
    $('#eventModal').foundation('reveal', 'close')

#
#  I want to share a couple of variables between the next two functions,
#  so I think I need to put them here.
#
prOwnForm = null
prTargetForm = null

submittingCreate = ->
  targetField = prTargetForm.find('#event_precommit_element_id')
  if targetField.length
    sources = prOwnForm.find('.pr-checkbox')
    result = targetField.val()
    sources.each (index, source) =>
      if source.checked
        result = result + ',' + $(source).val()
    targetField.val(result)

primePreRequisites = ->
  prOwnForm = $('form#event-pre-requisites')
  prTargetForm = $('form#new_event')
  if prOwnForm.length && prTargetForm.length
    prTargetForm.submit(submittingCreate)

handleQuickAdd = (event) ->
  element_id = $(event.target).data('element-id')
  #
  #  All we do is put this element id in the relevant field of the form,
  #  then submit the form.
  #
  form = $('#new_commitment')
  if form && element_id
    $('#commitment_element_id').val(element_id)
    form.submit()


primeQuickAddButtons = ->
  $('.quick-add-button').click(handleQuickAdd)

hideCloser = ->
  $('#event-done-button').hide()

showCloser = ->
  $('#event-done-button').show()

#
#  Functions for the filter dialogue.
#
wantsAll = ->
  $('#filter-dialogue #exclusions input:checkbox').prop('checked', true)

wantsNone = ->
  $('#filter-dialogue #exclusions input:checkbox').prop('checked', false)

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

window.updateConcernListing = (newContents) ->
  $('#user-concerns-list').html(newContents)
  $('#concern_name').val('')

window.replaceShownCommitments = (new_html) ->
  $('#show-all-commitments').html(new_html)
  $('.rejection-link').click(noClicked)
  $('.noted-link').click(notedClicked)
  window.refreshNeeded()

window.beginEditingEvent = (contents) ->
  $('#events-dialogue').html(contents)
  $('.datetimepicker').datetimepicker( { dateFormat: "dd/mm/yy", stepMinute: 5 })
  primeQuickAddButtons()
  $('#commitment_element_name').focus()

window.replaceEditingCommitments = (new_html) ->
  $('#event_resources').html(new_html)
  primeQuickAddButtons()
  window.refreshNeeded()

window.beginNoteEditing = (body_text) ->
  $('#event-notes').html(body_text)
  $('#note_contents').focus()
  hideCloser()

window.endNoteEditing = (new_note_text, new_shown_commitments) ->
  $('#event-notes').html(new_note_text)
  if new_shown_commitments
    window.replaceShownCommitments(new_shown_commitments)
  showCloser()

window.switchToEditingEvent = (contents) ->
  $('#events-dialogue').html(contents)
  $('.datetimepicker').datetimepicker( { dateFormat: "dd/mm/yy", stepMinute: 5 })
  primeQuickAddButtons()
  $('#commitment_element_name').focus()
  window.triggerCountsUpdate()

window.finishEditingEvent = (event_summary, do_refresh) ->
  $('#events-dialogue').html(event_summary)
  primeCloser()
  if typeof window.activateRelocateLink == 'function'
    window.activateRelocateLink()
  if do_refresh
    window.refreshNeeded()
    window.triggerCountsUpdate()

window.closeModal = (full_reload, just_events, filter_state) ->
  $('#eventModal').foundation('reveal', 'close')
  if full_reload
    location.reload()
  else
    if just_events
      $('#fullcalendar').fullCalendar('refetchEvents')
      if filter_state
        el = $('#filter-state')
        el.removeClass('filter-on')
        el.removeClass('filter-off')
        el.addClass("filter-#{filter_state}")
        el.text(filter_state)

window.refreshNeeded = ->
  $('.flag-refreshes').data("dorefresh", "1")

window.beginWrapping = (contents) ->
  $('#events-dialogue').html(contents)
  primeCloser()

