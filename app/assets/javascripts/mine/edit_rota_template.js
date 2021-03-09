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
  var staff_id = myDiv.data('staff-id');
  var base_url = '/ad_hoc_domain_staffs/' + staff_id + '/events'

  function createdOK() {
    myDiv.fullCalendar('refetchEvents');
  }

  function handleSelect(starts_at, ends_at, jsEvent, view) {
    //
    //  We need to send a create request up to our host.
    //  It will decide on the actual event duration.
    //
    myDiv.fullCalendar('unselect');
    var to_send = {
      starts_at: starts_at.format("YYYY-MM-DD HH:mm")
    };
    if (ends_at - starts_at > 300000) {
      to_send['ends_at'] = ends_at.format("YYYY-MM-DD HH:mm");
    }
    var prepared_data = JSON.stringify({
      ahd_event: to_send
    });
    console.log({prepared_data});
    $.ajax({
      url: base_url,
      type: "POST",
      dataType: "json",
      contentType: 'application/json',
      data: prepared_data}).done(createdOK);
  }

  function eventClicked(event, jsEvent, view) {
    //
    //  Our rather naive response is simply to delete the indicated
    //  event.
    //
    $.ajax({
      url: base_url + '/' + event.id,
      type: "DELETE",
      dataType: 'json',
      contentType: 'application/json'}).done(createdOK);
  }

  function eventResized(event, delta, revertFunc) {
    var to_send = {
      ends_at: event.end.format()
    };
    var prepared_data = JSON.stringify({
      ahd_event: to_send
    });
    $.ajax({
      url: base_url + '/' + event.id,
      type: "PUT",
      dataType: 'json',
      contentType: 'application/json',
      data: prepared_data}).done(createdOK);
  }

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
    minTime: "07:00",
    maxTime: "18:30",
    scrollTime: "08:00",
    allDaySlot: false,
    columnHeaderText: function(mom) {
      return mom.format('ddd');
    },
    defaultDate: '2017-01-01',
    eventClick: eventClicked,
    eventResize: eventResized,
    selectable: true,
    selectHelper: true,
    select: handleSelect
  }

  that.init = function() {
    //
    //  We have already checked that our master parent division
    //  exists, otherwise we wouldn't be running at all.
    //
    fcParams.eventSources = [{
      url: base_url
    }];
    myDiv.fullCalendar(fcParams)
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(editing_rota_templates.init);

}
