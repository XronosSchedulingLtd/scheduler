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

  //
  //  Some constructors for my objects.  They are inside the function
  //  in order to avoid giving them global names.
  //
  //  My data from the host look a bit like this. (Delete later.)
  //
  var eric = {
    "id":3,
    "name":"S2021P1 try 1",
    "starts":"2021-04-26",
    "ends":"2021-05-29",
    "availables": [
      {
        "wday":2,
        "starts_at":"09:00",
        "ends_at":"13:00"
      },
      {
        "wday":3,
        "starts_at":"09:00",
        "ends_at":"13:00"
      }
    ],
    "weeks": {
      "2021-04-26":"A",
      "2021-04-27":"A",
      "2021-04-28":"A",
      "2021-04-29":"A",
      "2021-04-30":"A",
      "2021-05-10":"A",
      "2021-05-11":"A",
      "2021-05-12":"A",
      "2021-05-13":"A",
      "2021-05-14":"A",
      "2021-05-24":"A",
      "2021-05-25":"A",
      "2021-05-26":"A",
      "2021-05-27":"A",
      "2021-05-28":"A",
      "2021-05-04":"B",
      "2021-05-05":"B",
      "2021-05-06":"B",
      "2021-05-07":"B",
      "2021-05-17":"B",
      "2021-05-18":"B",
      "2021-05-19":"B",
      "2021-05-20":"B",
      "2021-05-21":"B"
    },
    "pupils": [
      {
        "pcid":9,
        "pupil_id":3805,
        "mins":45,
        "name":"Bertie Dinsey",
        "subject":"Triangle"
      },
      {
        "pcid":10,
        "pupil_id":2929,
        "mins":30,
        "name":"Adam Coombs",
        "subject":"Triangle"
      }
    ],
    "allocated": [],
    "timetables":
    {
      "2929": {
        "A": [
          null,
          [
            {
              "b":"08:35",
              "e":"08:50",
              "s":51
            },
            {
              "b":"09:00",
              "e":"09:50",
              "s":25
            },
            {
              "b":"10:00",
              "e":"10:50",
              "s":25
            },
            {
              "b":"11:15",
              "e":"12:10",
              "s":11
            },
            {
              "b":"12:20",
              "e":"13:10",
              "s":38
            },
            {
              "b":"15:05",
              "e":"16:00",
              "s":3
            }
          ],
          [
            {
              "b":"08:35",
              "e":"08:50",
              "s":73
            },
            {
              "b":"11:15",
              "e":"12:10",
              "s":3
            }
          ],
          [
            {
              "b":"08:35",
              "e":"08:50",
              "s":54
            },
            {
              "b":"09:00",
              "e":"09:50",
              "s":3
            },
            {
              "b":"10:00",
              "e":"10:50",
              "s":25
            },
            {
              "b":"11:15",
              "e":"12:10",
              "s":11
            },
            {
              "b":"14:15",
              "e":"14:45",
              "s":51
            }
          ],
          [
            {
              "b":"08:35",
              "e":"08:50",
              "s":51
            },
            {
              "b":"09:00",
              "e":"09:50",
              "s":3
            },
            {
              "b":"10:00",
              "e":"10:50",
              "s":3
            },
            {
              "b":"13:45",
              "e":"14:40",
              "s":25
            },
            {
              "b":"14:50",
              "e":"15:45",
              "s":11
            }
          ],
          [
            {
              "b":"08:35",
              "e":"08:50",
              "s":54
            },
            {
              "b":"09:00",
              "e":"09:50",
              "s":11
            },
            {
              "b":"10:00",
              "e":"10:50",
              "s":11
            },
            {
              "b":"11:15",
              "e":"12:10",
              "s":25
            },
            {
              "b":"12:20",
              "e":"13:10",
              "s":38
            }
          ]
        ],
        "B": [
          null,
          [
            {
              "b":"08:35",
              "e":"08:50",
              "s":51
            },
            {
              "b":"09:00",
              "e":"09:50",
              "s":25
            },
            {
              "b":"10:00",
              "e":"10:50",
              "s":25
            },
            {
              "b":"11:15",
              "e":"12:10",
              "s":11
            },
            {
              "b":"12:20",
              "e":"13:10",
              "s":38
            },
            {
              "b":"14:00",
              "e":"14:55",
              "s":3
            }
          ],
          [
            {
              "b":"08:35",
              "e":"08:50",
              "s":53
            },
            {
              "b":"10:00",
              "e":"10:50",
              "s":3
            },
            {
              "b":"14:50",
              "e":"15:45",
              "s":25
            }
          ],
          [
            {
              "b":"08:35",
              "e":"08:50",
              "s":51
            },
            {
              "b":"10:00",
              "e":"10:50",
              "s":25
            },
            {
              "b":"11:15",
              "e":"12:10",
              "s":11
            },
            {
              "b":"13:10",
              "e":"14:05",
              "s":3
            },
            {
              "b":"14:15",
              "e":"14:45",
              "s":51
            }
          ],
          [
            {
              "b":"08:35",
              "e":"08:50",
              "s":51
            },
            {
              "b":"11:15",
              "e":"12:10",
              "s":3
            },
            {
              "b":"14:50",
              "e":"15:45",
              "s":11
            }
          ],
          [
            {
              "b":"08:35",
              "e":"08:50",
              "s":54
            },
            {
              "b":"09:00",
              "e":"09:50",
              "s":11
            },
            {
              "b":"10:00",
              "e":"10:50",
              "s":11
            },
            {
              "b":"11:15",
              "e":"12:10",
              "s":25
            },
            {
              "b":"12:20",
              "e":"13:10",
              "s":38
            },
            {
              "b":"15:05",
              "e":"16:00",
              "s":3
            }
          ]
        ]
      },
      "3805":{
        // ...
      }
    },
    "subjects": {
      "51":"Tutor Period",
      "25":"Mathematics",
      "11":"Economics",
      "38":"Sport",
      "3":"Chemistry",
      "73":"Alt Chapel",
      "54":"Assembly",
      "53":"Chapel",
      "20":"History",
      "82":"Philosophy and Theology",
      "17":"Geography",
      "1":"Art",
      "4":"Ancient History",
      "8":"Drama",
      "44":"Physical Education",
      "18":"German",
      "12":"English",
      "36":"Science",
      "77":"Engineering Science",
      "28":"PSHCE",
      "56":"Design \u0026 Technology"
    },
    "current":0
  };

  //
  //  Subsidiary items for our dataset.
  //
  //
  //  An object to hold the complete data set sent down for one
  //  teacher's allocation.
  //
  //  The idea is that we take the raw data sent by the host and
  //  store it in a form convenient for front-end manipulation.
  //
  //  We can also generate a data stream to send back to the host
  //  to update its variables.
  //

  var makeDataset = function(spec) {
    var that = {};

    that.id   = spec.id;
    that.name = spec.name;
    that.start_date = moment(spec.starts);
    that.end_date   = moment(spec.ends);  // Exclusive
    //
    //  Things which are already provided in a convenient form we simply
    //  store.
    //
    that.availables = spec.availables;
    that.weeks      = spec.weeks;
    that.pupils     = spec.pupils;
    //
    //  Whilst other things are tweaked to make them easier to manipulate.
    //

    that.availables_on = function(date) {
      var wday = date.day();
      return _.select(that.availables, function(entry) {
        return entry.wday === wday;
      });
    };

    return that;
  };

  var that = {};

  var calDiv = $('#editing-allocation');
  var myData = $('#allocation-data');
  var allocation;
  var dataset;
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
    selectHelper: true,
    eventRender: tweakWidth,
    droppable: true,
    drop: entryDropped
  };

  function tweakWidth(event, element) {
    //
    //  This needs making more specific.  Want to tweak the student
    //  timetable events (which should be first in the sort order)
    //  only.
    //
    if (element.hasClass("fc-time-grid-event") && (event.timetable === 1)) {
      element.css("margin-right", "20px");
    }
  }

  function entryDropped(startsAt, jsEvent, ui) {
    //
    //  "this" is the object which was dropped.
    //
    //  If we simply add an item to the array and set it back,
    //  no change event is triggered because it's the same
    //  pointer as it was before.  Thus need to clone the
    //  array and set the new clone back.
    //
    var allocated = _.clone(allocation.get('allocated'));
    allocated.push({
      datetime: startsAt.format('YYYY-MM-DD HH:mm'),
      pcid: $(this).data('pcid')
    });
    allocation.set({allocated: allocated});
  }

  function serverResponded() {
  }

  function generateEvents(start, end, timezone, callback) {
    var i;
    var events = [];
    var entry;
    for (var date = moment(start); date.isBefore(end); date.add(1, 'days')) {
      //
      //  Does our model know about any background events which we can
      //  shove in?
      //
      var availables = dataset.availables_on(date);
      for (i = 0; i < availables.length; i++) {
        entry = availables[i];
        events.push({
          start: date.format('YYYY-MM-DD') + ' ' + entry.starts_at,
          end: date.format('YYYY-MM-DD') + ' ' + entry.ends_at,
          rendering: 'background'
        });
      }
    }
    if (currentlyShowing !== 0) {
      //
      //  Try to show a student's calendar.
      //
      var timetables = allocation.get('timetables');
      var weeks = allocation.get('weeks');
      var subjects = allocation.get('subjects');
      var timetable = timetables[currentlyShowing]
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
          var wday = date.day();
          var week_entries = timetable[week];
          if (week_entries) {
            var entries = week_entries[wday];
            if (entries) {
              //
              //  We finally have an array of entries.  Each of these
              //  should add one event to our display.
              //
              entries.forEach(function(entry) {
                events.push({
                  title: subjects[entry.s],
                  start: date.format('YYYY-MM-DD') + ' ' + entry.b,
                  end: date.format('YYYY-MM-DD') + ' ' + entry.e,
                  color: '#3b9653',
                  timetable: 1,
                  sort_by: "A"
                });
                // Amber '#d4a311'
                // Red   '#db4335'
              });

            }
          }
        }
      }
    }
    var allocated = allocation.get('allocated');
    if (allocated) {
      allocated.forEach(function(alloc) {
        var datetime = moment(alloc.datetime);
        if ((datetime >= start) && (datetime < end)) {
          events.push({
            title: "Hello",
            start: alloc.datetime,
            timetable: 0,
            sort_by: "B"
          });
        }
      });
    }
    callback(events);
  }

  //
  //  Called when our allocation has noticed a change.  We are particularly
  //  interested in the current pupil.
  //
  function checkChange() {
    var newCurrent = allocation.get("current");
//    if (newCurrent !== currentlyShowing) {
      currentlyShowing = newCurrent;
      calDiv.fullCalendar('refetchEvents');
 //   }
  }

  var Allocation = Backbone.Model.extend({
    //
    //  The documentation for Backbone is poor but it appears that
    //  this function is called after the basic initialization has
    //  been done.  We thus have access to all the attributes
    //  created from our initialization string, and can do things
    //  with them.
    //
    initialize: function() {
      var subjects = this.attributes.subjects;
    }
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
    highlighting: 0,
    initialize: function(options) {
      allocation.on("change", this.checkChanges, this);
    },
    clicked: function(event) {
      var button = event['currentTarget'];
      var pupilId = $(button).data('pupil-id');
      allocation.set("current", pupilId);
    },
    checkChanges: function() {
      var toHighlight = allocation.get("current");
      //if (toHighlight !== this.highlighting) {
        this.highlighting = toHighlight;
        this.render();
      //}
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
      var extraClass;
      var allocated = allocation.get('allocated');
      allocation.attributes.pupils.forEach(function(item, index) {
        if (allocated.find(function (alloc) {
          return alloc.pcid === item.pcid;
        }) === undefined) {
          if (item.pupil_id === that.highlighting) {
            extraClass = " selected";
          } else {
            extraClass = "";
          }
          texts.push(that.template({
            extra_class: extraClass,
            pcid: item.pcid,
            pupil_id: item.pupil_id,
            pupil: item.name,
            subject: item.subject
          }));
        }
      });
      this.$el.html(
        texts.join(" ")
      );
      //
      //  And make selected draggable.
      //
      this.$el.find('.single-allocation.selected').each(function(index) {
        $(this).draggable({
          revert: true,
          cursorAt: { top: 0 },
          zIndex: 10,
          revertDuration: 0
        });
      });
      this.$el.find('.single-allocation').each(function(index) {
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
    dataset = makeDataset(data);
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
