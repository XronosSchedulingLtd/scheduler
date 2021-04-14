"use strict";

//
//  Do nothing at all unless we are on the right page.
//
if ($('#editing-allocation').length && $('#allocation-data').length) {

//
//  Wrap everything in a function to avoid namespace pollution
//  Note that we invoke the function immediately.
//
var editing_allocation = function() {

  var that = {};

  var calDiv = $('#editing-allocation');
  var viewDiv = $('#pending-allocations');
  var myData = $('#allocation-data');
  var allocation;

  function serverResponded() {
  }

  var Allocation = Backbone.Model.extend({
  });

  //
  //  I propose to use the View for the bits where we need to do the
  //  drawing, but keep FullCalendar mostly outside it.  It can do its
  //  own drawing.  The view will however trigger FC to refetch its events
  //  when something interesting happens.
  //
  var AllocationView = Backbone.View.extend({
    fcParams: {
      schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
      currentTimezone: 'Europe/London',
      timeFormat: 'H:mm',
      header: {
        left: 'prev,next',
        center: 'title',
        right: null
      },
      views: {
        week: {
          columnFormat: 'ddd D/M',
          titleFormat: 'Do MMM, YYYY'
        }
      },
      defaultView: "agendaWeek",
      eventOrder: "sort_by",
      snapDuration: "00:05",
      minTime: "07:00",
      maxTime: "18:30",
      scrollTime: "08:00",
      allDaySlot: false,
  //    defaultDate: '2017-01-01',
  //    validRange: {
  //      start: '2017-01-03',
  //      end: '2017-01-18'
  //    },
  //    eventClick: eventClicked,
  //    eventResize: eventResized,
  //    eventDrop: eventDropped,
  //    select: handleSelect,
      selectable: true,
      selectHelper: true
    },

    generateEvents: function(start, end, timezone, callback) {
      var events = [];
      var availables = allocation.get('availables');
      for (var date = moment(start); date.isBefore(end); date.add(1, 'days')) {
        //
        //  Does our model know about any background events which we can
        //  shove in?
        //
        var wday = date.day();
        availables.forEach(function(entry) {
          if (entry.wday == wday) {
            //
            //  Correct day of week.
            //
            events.push({
              start: date.format('YYYY-MM-DD') + ' ' + entry.starts_at,
              end: date.format('YYYY-MM-DD') + ' ' + entry.ends_at,
              rendering: 'background'
            });
          }
        });
      }
      //
      //  And one fake foreground event.
      //
      events.push({
        start: start.format('YYYY-MM-DD') + ' 09:00',
        end: start.format('YYYY-MM-DD') + ' 09:45',
        title: 'James Smith'
      });
      callback(events);

      //var events = [];
      //availables.forEach(function(entry) {
        //
        //  Each of the "available" slots may appear multiple times,
        //  once for each of the weeks in our allocation.
        //
      //});
      //this.fcParams.events = events;
    },

    initialize: function(options) {
      //
      //  Now we need some info from the model to set up our
      //  parameters to pass to FullCalendar.
      //
      this.fcParams.defaultDate = allocation.get('starts');
      this.fcParams.validRange = {
        start: allocation.get('starts'),
        end:   allocation.get('ends')
      };
      this.fcParams.events = this.generateEvents;
      calDiv.fullCalendar(this.fcParams)
    }
  });

  that.init = function() {
    //
    //  We have already checked that our master parent division
    //  exists, otherwise we wouldn't be running at all.
    //
    var json_data = myData.text();
    var data = JSON.parse(json_data);
    //
    //  The allocation variable is defined globally in this module.
    //
    allocation = new Allocation(data);
    console.log({allocation});

    var av = new AllocationView(
      {
        el: viewDiv
      }
    );
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(editing_allocation.init);

}
