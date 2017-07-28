"use strict";

if ($('#fullcalendar').length) {
  var roomCoverHandler = function() {
    var that = {};

    var Room = Backbone.Model.extend({
    });

    var RoomCollection = Backbone.Collection.extend({
      model: Room
    });

    //
    //  Model representing a single building.  It has a name, and
    //  then an array of rooms.
    //
    var Building = Backbone.Model.extend({
      createChildren: function() {
        this.rooms = new RoomCollection(this.get("rooms"));
        console.log("Got " + this.rooms.length + " rooms.");
      }
    });

    var BuildingCollection = Backbone.Collection.extend({
      model: Building,
      createChildren: function() {
        this.each(function(model) {
          model.createChildren();
        }, this);
      }
    });

    var Selector = Backbone.Model.extend({
      initialize: function(attributes, options) {
        this.event_id = options.event_id;
      },
      url: function() {
        return '/events/' + this.event_id + '/coverrooms';
      },
      createChildren: function () {
        console.log("Selector creating children.");
        this.buildings = new BuildingCollection(this.get("coverrooms"));
        console.log("Got " + this.buildings.length + " buildings.");
        this.buildings.createChildren();
      }
    });

    //
    //  Views
    //

    var RoomView = Backbone.View.extend({
      tagName: "option",
      attributes: function() {
        var result = {};
        if (this.model.get("selected")) {
          result["selected"] = "selected";
        }
        return result;
      },
      render: function() {
        this.$el.html(this.model.get("name"));
        return this;
      }
    });

    var BuildingView = Backbone.View.extend({
      tagName: "optgroup",
      attributes: function() {
        var result = {}
        result["label"] = this.model.get("name");
        return result;
      },
      render: function() {
        this.$el.empty();
        if (this.model.rooms.length > 0) {
          this.model.rooms.each(function(model) {
            var roomView = new RoomView({ model: model });
            this.$el.append(roomView.render().$el);
          }, this);
        } else {
          this.$el.append('<option value="disabled" disabled>None available</option');
        }
        return this;
      }
    });

    var SelectorView = Backbone.View.extend({
      tagName: 'select',
      initialize: function(options) {
        this.model = new Selector(null, {event_id: options.event_id});
        this.listenTo(this.model, 'sync', this.render);
        this.$el.html('<option value="0">Fetching free rooms</option>');
        this.model.fetch();
      },
      render: function() {
        console.log("Asked to render.");
        this.model.createChildren();
        this.$el.empty();
        this.$el.html('<option value="0">Stay in ' + this.model.get("orgroom") + "</option>");
        this.model.buildings.each(function(model) {
          var buildingView = new BuildingView({model: model});
          this.$el.append(buildingView.render().$el);
        }, this);
      }
    });

    that.linkClicked = function() {
      console.log("Link clicked.");
      $('#relocate-link').hide();
      var relocate_space = $('#relocate-space');
      var event_id = relocate_space.data('event-id');
      that.roomListsView = new SelectorView({event_id: event_id});
      var for_pop_down = relocate_space.find('#for-pop-down');
      for_pop_down.empty();
      for_pop_down.append(that.roomListsView.$el);
      relocate_space.show();
    }

    that.modalOpened = function() {
      console.log("Modal opened.");
      var our_link = $('#relocate-link');
      if (our_link.length) {
        console.log("And we have our link.");
        our_link.click(that.linkClicked);
        $('#relocate-ok').click(that.okClicked);
        $('#relocate-cancel').click(that.cancelClicked);
      }
    }

    that.okClicked = function() {
      console.log("OK clicked");
    }

    that.cancelClicked = function() {
      console.log("Cancel clicked");
    }

    that.init = function() {
      _.bindAll(that, 'modalOpened', "okClicked", "cancelClicked");
      $(document).on('opened', '[data-reveal]', that.modalOpened);
    };

    return that;
  }();

  $(roomCoverHandler.init);
}
