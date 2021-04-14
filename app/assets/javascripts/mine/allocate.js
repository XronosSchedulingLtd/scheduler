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
  var myData = $('#allocation-data');
  var allocation;
  var currentlyShowing;

  var fcParams = {
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
    selectable: true,
    selectHelper: true
  };

  function serverResponded() {
  }

  function generateEvents(start, end, timezone, callback) {
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
//    events.push({
//      start: start.format('YYYY-MM-DD') + ' 09:00',
//      end: start.format('YYYY-MM-DD') + ' 09:45',
//      title: 'James Smith'
//    });
    console.log({currentlyShowing});
    if (currentlyShowing !== 0) {
      //
      //  Try to show a student's calendar.
      //
      var timetables = allocation.get('timetables');
      var weeks = allocation.get('weeks');
      var subjects = allocation.get('subjects');
      console.log({timetables});
      var timetable = timetables[currentlyShowing]
      console.log({timetable});
      if (timetable) {
        //
        //  We have a pointer to the student's timetable.  Now need
        //  to process each of the requested dates.
        //
        for (var date = moment(start);
             date.isBefore(end);
             date.add(1, 'days')) {
          //
          //  What week is this date?
          //
          var week = weeks[date.format('YYYY-MM-DD')];
          console.log({week});
          var wday = date.day();
          console.log({wday});
          var week_entries = timetable[week];
          console.log({week_entries});
          if (week_entries) {
            var entries = week_entries[wday];
            console.log({entries});
            if (entries) {
              //
              //  We finally have an array of entries.  Each of these
              //  should add one event to our display.
              //
              entries.forEach(function(entry) {
                events.push({
                  title: subjects[entry.s],
                  start: date.format('YYYY-MM-DD') + ' ' + entry.b,
                  end: date.format('YYYY-MM-DD') + ' ' + entry.e
                });
              });

            }
          }
        }
      }
    }
    callback(events);

    //var events = [];
    //availables.forEach(function(entry) {
      //
      //  Each of the "available" slots may appear multiple times,
      //  once for each of the weeks in our allocation.
      //
    //});
    //this.fcParams.events = events;
  }

  //
  //  Called when our allocation has noticed a change.  We are particularly
  //  interested in the current pupil.
  //
  function checkChange() {
    var newCurrent = allocation.get("current");
    if (newCurrent !== currentlyShowing) {
      //alert("Current has changed to " + newCurrent);
      currentlyShowing = newCurrent;
      calDiv.fullCalendar('refetchEvents');
    }
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
    el: '#pending-allocations',
    template: _.template($('#an-allocation').html()),
    initialize: function(options) {
      allocation.on("change", this.checkChanges, this);
    },
    clicked: function(event) {
      console.log({event});
      var button = event['currentTarget'];
      var pupilId = $(button).data('pupil-id');
      console.log({pupilId});
      allocation.set("current", pupilId);
    },
    checkChanges: function() {
      //
      //  We don't want to re-render on every change.  Only if the
      //  list of allocations has changed.
      //
    },
    render: function() {
      //
      //  Cancel draggability of any existing items.
      //
      this.$el.find('.single-allocation').each(function(index) {
        if ($(this).data('ui-draggable')) {
          $(this).draggable("destroy");
        }
      });
      //
      //  Set up our new list.
      //
      var texts = [];
      var that = this;
      allocation.attributes.pupils.forEach(function(item, index) {
        texts.push(that.template({
          pupil_id: item.pupil_id,
          pupil: item.name,
          subject: item.subject
        }));
      });
      this.$el.html(
        texts.join(" ")
      );
      //
      //  And make them all draggable.
      //
      this.$el.find('.single-allocation').each(function(index) {
        $(this).draggable({
          revert: true
        });
        $(this).click(that.clicked);
      });
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
    currentlyShowing = allocation.get("current");

    //
    //  Now we need some info from the model to set up our
    //  parameters to pass to FullCalendar.
    //
    fcParams.defaultDate = allocation.get('starts');
    fcParams.validRange = {
      start: allocation.get('starts'),
      end:   allocation.get('ends')
    };
    fcParams.events = generateEvents;
    calDiv.fullCalendar(fcParams);
    //
    //  And a view to handle the LHS bit.
    //
    var av = new AllocationView();
    av.render();
    //
    //  And we need to do things to the Calendar if the current
    //  attribute changes.
    //
    allocation.on("change", checkChange);
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(editing_allocation.init);

}
