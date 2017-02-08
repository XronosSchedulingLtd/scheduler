"use strict";

//
//  Do nothing at all unless we are on the right page.
//
if ($('#examcycle').length) {

//
//  Wrap everything in a function to avoid namespace pollution
//  Note that we invoke the function immediately.
//
var examcycles = function() {

  var that = {};

  var ProtoEvent = Backbone.Model.extend({
    defaults: {
      status: "created",
      room: "",
      rota_template_name: "",
      starts_on_text: "",
      ends_on_text: "",
      event_count: 0
    }
  });

  var ProtoEventView = Backbone.View.extend({
    model: ProtoEvent,
    tagName: 'tr',
    className: 'ec-protoevent',
    template: _.template($('#ec-protoevent-row').html()),
    initialize: function() {
      this.model.on('change', this.render, this);
      this.model.on('destroy', this.remove, this);
    },
    events: {
      'click .add'    : 'addProtoEvent',
      'click .edit'   : 'startEdit',
      'click .cancel' : 'cancelEdit',
    },
    setState: function(state) {
      this.$el.removeClass("creating");
      this.$el.removeClass("created");
      this.$el.removeClass("editing");
      this.$el.removeClass("generated");
      this.$el.addClass(state);
    },
    render: function() {
      console.log("ProtoEventView asked to render.");
//      console.log(this.template(this.model.toJSON()));
//      console.log("Currently contains: " + this.$el.html());
      this.setState(this.model.get("status"));
      this.$el.html(this.template(this.model.toJSON()));
      this.$el.find('.datepicker').datepicker({ dateFormat: "dd/mm/yy"});
      return this;
    },
    destroy: function() {
      this.model.destroy();
    },
    addProtoEvent: function() {
      //
      //  The user wants to create a new proto event.  We need all
      //  4 fields to have been filled in with useful values.
      //
      //  Should be able simply to read them, and then rely on
      //  validation in both our local model, and on the server,
      //  to pick up issues.
      //
    },
    startEdit: function() {
      this.setState("editing");
    },
    cancelEdit: function() {
      this.setState("created");
    }
  });

  var ProtoEvents = Backbone.Collection.extend({
    model: ProtoEvent,
    initialize: function(models, options) {
      this.ecid = options.ecid;
    },
    comparator: function(item) {
      return item.attributes.starts_on;
    },
    url: function() {
      return '/exam_cycles/' + this.ecid + '/proto_events'
    }
  });

  var ProtoEventsView = Backbone.View.extend({
    el: '#ec-table tbody',
    errortemplate: _.template($('#ec-error-msg').html()),
    initialize: function (ecid) {
      _.bindAll(this, 'creationOK');
      this.collection = new ProtoEvents(null, {ecid: ecid});
      this.listenTo(this.collection, 'sync', this.render);
      this.collection.fetch();
    },
    render: function() {
      console.log("Asked to render " + this.collection.length + " proto events");
      var $list = this.$el.empty();
      this.collection.each(function(model) {
        var protoEventView = new ProtoEventView({model: model});
        $list.append(protoEventView.render().$el);
      }, this);
      return this;
    },
    creationOK: function() {
      console.log("Created successfully.");
    },
    creationError: function(model, response, options) {
      var view, errors;

      console.log("ProtoEvents view noting error.");
      view = this;
      errors = $.parseJSON(response.responseText);
      for (var property in errors) {
        if (errors.hasOwnProperty(property)) {
          view.$el.find("#" + property).append(view.errortemplate({error_msg: errors[property]}));
        }
      }
    }
  });

  var ExamCycle = Backbone.Model.extend({
    urlRoot: '/exam_cycles'
  });

  var ExamCycleView = Backbone.View.extend({
    el: "#ec-table",
    model: ExamCycle,
    initialize: function(rtid) {
      this.model = new ExamCycle({id: rtid});
      this.listenTo(this.model, 'sync', this.render);
      this.$forentry = this.$('tfoot tr')
      this.model.fetch();
      //
      //  We also need a dummy ProtoEvent which will handle our
      //  input fields in the bottom row.
      //
      this.newPE = new ProtoEvent({
        status: "creating"
      });
      this.newPEView = new ProtoEventView({
        model: this.newPE,
        el: this.$forentry
      });
    },
    render: function() {
      console.log("ExamCycleView asked to render.");
      //
      //  Nothing actually to render of the cycle itself, but
      //  we do need to set up the input fields in the footer.
      //
      this.newPEView.render();
      return this;
    }
  });

  function getExamCycle(ecid) {
    var examCycleView = new ExamCycleView(ecid);
  };

  function getProtoEvents(ecid) {
    var protoEventsView = new ProtoEventsView(ecid);
  };

  that.init = function() {
    //
    //  We have already checked that our master parent division
    //  exists, otherwise we wouldn't be running at all.
    //
    var ecid = $('#examcycle').data("ecid");
    getExamCycle(ecid);
    getProtoEvents(ecid);
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(examcycles.init);

}
