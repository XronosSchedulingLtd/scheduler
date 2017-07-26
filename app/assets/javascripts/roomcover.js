"use strict";

if ($('#fullcalendar').length) {
  var roomCoverHandler = function() {
    var that = {};

    var CandidateRoom = Backbone.Model.extend({
    });

    var CandidateRoomView = Backbone.View.extend({
      tagName: "li",
      template: _.template($('#room-candidate-line').html()),
      events: {
        "click" : "roomSelected"
      },
      render: function() {
        this.$el.html(this.template(this.model.toJSON()));
        return this;
      },
      roomSelected: function(event) {
        console.log("Room selected - " + this.model.name);
      }
    });

    var RoomListsView = Backbone.View.extend({
      template: _.template($('#room-lists-template').html()),
      initialize: function() {
        var event_id = this.$el.data('event-id');
        console.log("Event id = " + event_id);
      }
    });

    that.linkClicked = function() {
      console.log("Link clicked.");
      $('#relocate-link').hide();
      $('#event-notes').hide();
      $('#event-done-button').hide();
      var relocate_space = $('#relocate-space');
      relocate_space.html("Populating");
      that.roomListsView = new RoomListsView({el: relocate_space});
      relocate_space.show();
    }

    that.modalOpened = function() {
      console.log("Modal opened.");
      var our_link = $('#relocate-link');
      if (our_link.length) {
        console.log("And we have our link.");
        our_link.click(that.linkClicked);
      }
    }

    that.init = function() {
      _.bindAll(that, 'modalOpened');
      $(document).on('opened', '[data-reveal]', that.modalOpened);
    };

    return that;
  }();

  $(roomCoverHandler.init);
}
