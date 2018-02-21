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
        this.buildings = new BuildingCollection(this.get("coverrooms"));
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
        result["value"] = this.model.get("element_id");
        if (this.model.get("selected")) {
          result["selected"] = "selected";
        }
        if (!this.model.get("available")) {
          result["class"] = "location-unavailable";
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
        if (!this.model.get("available")) {
          result["class"] = "location-unavailable";
        }
        return result;
      },
      render: function() {
        this.$el.empty();
        var available = this.model.get("available");
        if (this.model.rooms.length > 0) {
          this.model.rooms.each(function(model) {
            model.set({available: available});
            var roomView = new RoomView({ model: model });
            this.$el.append(roomView.render().$el);
          }, this);
        } else {
          if (available) {
            this.$el.append('<option value="disabled" disabled>None available</option');
          }
        }
        return this;
      }
    });

    //
    //  This view handles *just* the pop-down list - not the surrounding
    //  buttons.
    //
    var SelectorView = Backbone.View.extend({
      tagName: 'select',
      attributes: {
        id: 'room-cover-selector'
      },
      initialize: function(options) {
        this.event_id = options.event_id;
        //
        //  Set up placeholder contents.
        //
        this.$el.html('<option value="0">Fetching free rooms...</option>');
        //
        //  And get ourselves some real data.
        //
        this.model = new Selector(null, {event_id: this.event_id});
        this.listenTo(this.model, 'sync', this.render);
        this.model.fetch();
      },
      render: function() {
        this.model.createChildren();
        this.$el.empty();
        this.$el.html('<option value="0">Stay in ' + this.model.get("orgroom") + "</option>");
        this.model.buildings.each(function(model) {
          var buildingView = new BuildingView({model: model});
          this.$el.append(buildingView.render().$el);
        }, this);
      }
    });

    //
    //  Whilst this one handles the whole area, including the pop-down
    //  list and buttons.
    //
    var CoverView = Backbone.View.extend({
      events: {
        'click #relocate-ok'     : 'okClicked',
        'click #relocate-cancel' : 'cancelClicked'
      },
      initialize: function() {
        var event_id = this.$el.data('event-id');
        this.commitment_id = this.$el.data('commitment-id');
        this.popdown_container = this.$el.find('#for-pop-down');
        this.popdown_container.empty();
        this.selectorView = new SelectorView({event_id: event_id});
        this.popdown_container.append(this.selectorView.$el);
        this.$el.show();
      },
      okClicked: function() {
        var selector = this.$el.find('#room-cover-selector');
        var value = selector.find(':selected').val();
        $.ajax({
          url: "/commitments/" + this.commitment_id + "/coverwith/" + value,
          type: 'POST',
          context: this,
          contentType: 'application/json',
        }).done(this.coverSucceeded).
           fail(this.coverFailed);
      },
      cancelClicked: function() {
        this.$el.hide();
        this.unbind();
        this.undelegateEvents();
        this.stopListening();
        $('#relocate-link').show();
      },
      coverSucceeded: function(data, textStatus, jqXHR) {
        this.cancelClicked();
        //
        //  Replacement HTML should be in data["newhtml"]
        //
        window.replaceShownCommitments(data["newhtml"]);
        window.activateRelocateLink();
      },
      coverFailed: function() {
        console.log("Cover failed");
      }
    });

    that.linkClicked = function() {
      $('#relocate-link').hide();
      that.coverView = new CoverView({el: '#relocate-space'});
    }

    that.modalOpened = function() {
      window.activateRelocateLink();
    }

    that.modalClosed = function() {
      if (that.coverView) {
        that.coverView.unbind();
        that.coverView.undelegateEvents();
        that.coverView.stopListening();
        delete that.coverView;
      }
    }

    that.init = function() {
      _.bindAll(that, 'modalOpened', 'modalClosed');
      $(document).on('opened', '[data-reveal]', that.modalOpened);
      $(document).on('closed', '[data-reveal]', that.modalClosed);
      window.activateRelocateLink = function() {
        var our_link = $('#relocate-link');
        if (our_link.length) {
          our_link.click(that.linkClicked);
        }
      }
    };

    return that;
  }();

  $(roomCoverHandler.init);
}
