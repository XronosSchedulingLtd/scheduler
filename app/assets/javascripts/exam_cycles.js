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
      location_id: "",
      rota_template_name: "",
      starts_on_text: "",
      ends_on_text: "",
      event_count: 0
    },
    initialize: function(options) {
      _.bindAll(this, 'generationResponse');
    },
    generate: function(callback) {
      console.log("Model asked to generate.");
      //
      //  Sends a generate request for this model to the host.
      //
      this.generationDoneCallback = callback;
      $.post(this.url() + '/generate',
             {},
             this.generationResponse,
             "json");
    },
    generationResponse: function (data, textStatus, jqXHR) {
      console.log("In response function.");
      if (textStatus === "success") {
        this.set(data);
      }
      this.generationDoneCallback();
    }
  });

  var SplitView = Backbone.View.extend({
    model: ProtoEvent,
    //
    //  We'll need to create our own element within the pop-up element
    //  because when we remove() ourselves our element will go too.
    //
    tagName: 'div',
    template: _.template($('#ec-split-dialog').html()),
    initialize: function() {
    },
    render: function() {
    }
  });

  var ProtoEventView = Backbone.View.extend({
    model: ProtoEvent,
    tagName: 'tr',
    className: 'ec-protoevent',
    template: _.template($('#ec-protoevent-row').html()),
    errortemplate: _.template($('#ec-error-msg').html()),
    splittemplate: _.template($('#ec-split-dialog').html()),
    initialize: function(options) {
      _.bindAll(this, 'updateError', 'updateOK', 'generationDone');
      this.model.on('change', this.render, this);
      this.model.on('destroy', this.remove, this);
      this.owner = options.owner;
    },
    events: {
      'click .add'               : 'addProtoEvent',
      'click .edit'              : 'startEdit',
      'click .cancel'            : 'cancelEdit',
      'click .update'            : 'update',
      'click .destroy'           : 'destroy',
      'click .generate'          : 'generate',
      'click .split'             : 'showSplitDialog',
      'keypress input.inputname' : 'mightSubmit'
    },
    setState: function(state) {
      this.$el.removeClass("creating");
      this.$el.removeClass("created");
      this.$el.removeClass("editing");
      this.$el.removeClass("generated");
      this.$el.removeClass("generating");
      this.$el.addClass(state);
    },
    render: function() {
      console.log("ProtoEventView asked to render.");
//      console.log(this.template(this.model.toJSON()));
//      console.log("Currently contains: " + this.$el.html());
      this.setState(this.model.get("status"));
      this.$el.html(this.template(this.model.toJSON()));
      //
      //  The pop-down list needs to have its value set explicitly.
      //
      this.$el.find('div.rota_template select').val(this.model.get("rota_template_id"));
      this.$el.find('.datepicker').datepicker({ dateFormat: "dd/mm/yy"});
      if (this.model.get("event_count") === 0) {
        this.$('button.generate').html("Generate");
      } else {
        this.$('button.generate').html("Regenerate");
      }
      return this;
    },
    destroy: function() {
      this.model.destroy();
    },
    syncModel: function() {
      //
      //  Read fields from the view back into the model.
      //
      this.model.set({
        "room":             this.$('input.inputname').val(),
        "location_id":      this.$('input.location_id').val(),
        "rota_template_id": this.$('select.inputrtname').val(),
        "starts_on_text":   this.$('input.starts_on').val(),
        "ends_on_text":     this.$('input.ends_on').val()
      });
    },
    fieldContents: function() {
      return {
        location_id:      this.$('.location_id').val(),
        rota_template_id: this.$('.inputrtname').val(),
        starts_on_text:   this.$('input.starts_on').val(),
        ends_on_text:     this.$('input.ends_on').val()
      }
    },
    clearErrorMessages: function() {
      this.$("small.error").remove();
      this.$("div.error").removeClass("error");
    },
    mightSubmit: function(e) {
      if (e.which === 13 &&
          this.$('input.inputname').val() &&
          this.model.get('status') === 'creating') {
        this.addProtoEvent();
      }
    },
    addProtoEvent: function() {
      //
      //  First get rid of any left over error messages and attributes.
      //
      this.clearErrorMessages();
      //
      //  The user wants to create a new proto event.  We need all
      //  4 fields to have been filled in with useful values.
      //
      //  Should be able simply to read them, and then rely on
      //  validation in both our local model, and on the server,
      //  to pick up issues.
      //
      this.syncModel();
      this.owner.createNewProtoEvent(this.fieldContents(),
                                     this.creationOK,
                                     this.creationError,
                                     this);
    },
    creationOK: function() {
      console.log("Created successfully.");
      this.model.set("room", "");
      this.$('input.inputname').focus();
    },
    creationError: function(model, response, options) {
      var view, errors;

      console.log("ProtoEvent view noting error.");
      view = this;
      errors = $.parseJSON(response.responseText);
      for (var property in errors) {
        if (errors.hasOwnProperty(property)) {
          console.log(property + ": " + errors[property]);
          var div = view.$el.find("div." + property);
          div.append(view.errortemplate({error_msg: errors[property]}));
          div.addClass("error");
        }
      }
    },
    startEdit: function() {
      this.$('.location_id').val(this.model.get('location_id'));
      this.$('.inputname').val(this.model.get('room'));
      this.$('.inputrtname').val(this.model.get('rota_template_id'));
      this.clearErrorMessages();
      this.setState("editing");
    },
    cancelEdit: function() {
      this.setState("created");
    },
    update: function() {
      this.clearErrorMessages();
      this.model.save(
          this.fieldContents(),
          {
            error: this.updateError,
            wait: true
          })
    },
    updateError: function(model, response) {
      var view, errors;

      console.log("ProtoEvent view noting update error.");
      view = this;
      errors = $.parseJSON(response.responseText);
      for (var property in errors) {
        if (errors.hasOwnProperty(property)) {
          console.log(property + ": " + errors[property]);
          var div = view.$el.find("div." + property);
          div.append(view.errortemplate({error_msg: errors[property]}));
          div.addClass("error");
        }
      }
    },
    updateOK: function(model, response) {
      this.setState("created");
    },
    generate: function() {
      console.log("View asked to generate.");
      this.setState("generating");
      this.model.generate(this.generationDone);
    },
    generationDone: function() {
      this.setState("created");
    },
    showSplitDialog: function() {
      var splitModal = $('#splitModal');
      splitModal.html(this.splittemplate(this.model.toJSON()));
      splitModal.foundation('reveal', 'open', {
      });
      var datePicker = splitModal.find('.datepicker');
      //
      //  Try to find a date half way between the start and the end.
      //
      console.log("Starts on " + this.model.get("starts_on"));
      var startDate = moment(this.model.get("starts_on"));
      var endDate   = moment(this.model.get("ends_on"));
      var diff = endDate.diff(startDate, "days");
      var middle = startDate;
      middle.add(diff / 2, "days");
      var dayBefore = moment(middle);
      dayBefore.subtract(1, "days");
      datePicker.val(middle.format("DD/MM/YYYY"));
      splitModal.find("#daybefore").html(dayBefore.format("DD/MM/YYYY"));
      datePicker.datepicker({ dateFormat: "dd/mm/yy"});
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
    initialize: function (ecid) {
      _.bindAll(this, 'addOne');
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
    addOne: function(params, success, failure, object) {
      var newProtoEvent = this.collection.create(
        params,
        {
          wait: true
        }).on('sync', success, object).on('error', failure, object);
    },
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
        status: "creating",
        id: ""
      });
      this.newPEView = new ProtoEventView({
        model: this.newPE,
        el: this.$forentry,
        owner: this
      });
    },
    render: function() {
      console.log("ExamCycleView asked to render.");
      //
      //  Nothing actually to render of the cycle itself, but
      //  we do need to set up the input fields in the footer.
      //
      this.newPE.set({
        "rota_template_id": this.model.get("default_rota_template_id"),
        "starts_on_text":   this.model.get("starts_on_text"),
        "ends_on_text":     this.model.get("ends_on_text")
      });
      return this;
    },
    createNewProtoEvent: function(params, success, failure, object) {
      console.log("Asked to create a new ProtoEvent.");
      that.protoEventsView.addOne(params, success, failure, object);
    }
  });

  function getExamCycle(ecid) {
    var examCycleView = new ExamCycleView(ecid);
  };

  function getProtoEvents(ecid) {
    that.protoEventsView = new ProtoEventsView(ecid);
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
