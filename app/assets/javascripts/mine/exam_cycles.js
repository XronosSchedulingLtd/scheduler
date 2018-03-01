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

  var ExamCycle = Backbone.Model.extend({
    urlRoot: '/exam_cycles'
  });

  var ProtoEvent = Backbone.Model.extend({
    defaults: {
      status: "created",
      room: "",
      location_id: "",
      rota_template_name: "",
      starts_on_text: "",
      ends_on_text: "",
      event_count: 0,
      num_staff: 0
    },
    initialize: function(options) {
      _.bindAll(this, 'generationResponse');
    },
    generate: function(callback) {
      //
      //  Sends a generate request for this model to the host.
      //
      this.generationDoneCallback = callback;
      $.post(this.url() + '/generate',
             {},
             this.generationResponse,
             "json");
    },
    generationResponse: function(data, textStatus, jqXHR) {
      if (textStatus === "success") {
        this.set(data);
      }
      this.generationDoneCallback();
    },
    paramsToCreate: function() {
      return {
        location_id:      this.get('location_id'),
        rota_template_id: this.get('rota_template_id'),
        starts_on_text:   this.get('starts_on_text'),
        ends_on_text:     this.get('ends_on_text'),
        num_staff:        this.get('num_staff')
      }
    },
    canSplit: function() {
      return moment(this.get("ends_on")) > moment(this.get("starts_on"));
    },
    splitDates: function() {
      //
      //  Try to find suitable middling dates to split this interval.
      //  Special care is needed when the interval is very short - 2 days.
      //
      var startDate = moment(this.get("starts_on"));
      var endDate   = moment(this.get("ends_on"));
      var diff = endDate.diff(startDate, "days");
      var results = {}
      if (diff === 1) {
        results.beforeDate = startDate;
        results.afterDate = endDate;
        results.maxAfter = endDate;
        results.minAfter = endDate;
      } else {
        var middle = moment(startDate);
        middle.add(diff / 2, "days");
        var dayBefore = moment(middle);
        dayBefore.subtract(1, "days");
        var maxAfter = moment(endDate);
        var minAfter = moment(startDate);
        minAfter.add(1, "days");
        results.beforeDate = dayBefore;
        results.afterDate = middle;
        results.maxAfter = maxAfter;
        results.minAfter = minAfter;
      }
      return results;
    }
  });

  var SplitView = Backbone.View.extend({
    //
    //  We'll need to create our own element within the pop-up element
    //  because when we remove() ourselves our element will go too.
    //
    tagName: 'div',
    template: _.template($('#ec-split-dialog').html()),
    initialize: function() {
      _.bindAll(this, 'modalClosed', 'dateSelected', 'splitOK', 'splitFail');
      this.splitModal = $('#splitModal');
    },
    events: {
      'click .split'  : 'doSplit',
      'click .cancel' : 'doCancel'
    },
    setState: function(state) {
      this.myTable.removeClass("ready");
      this.myTable.removeClass("splitting");
      this.myTable.addClass(state);
    },
    render: function() {
      this.$el.html(this.template(this.model.toJSON()));
      this.myTable = this.$el.find(".splittable");
      var datePicker = this.$el.find('.datepicker');
      this.dates = this.model.splitDates();
      datePicker.val(this.dates.afterDate.format("DD/MM/YYYY"));
      this.$el.find("#daybefore").html(this.dates.beforeDate.format("DD/MM/YYYY"));
      datePicker.datepicker({
        dateFormat: "dd/mm/yy",
        minDate: this.dates.minAfter.format("DD/MM/YYYY"),
        maxDate: this.dates.maxAfter.format("DD/MM/YYYY"),
        onSelect: this.dateSelected
      });
      this.splitModal.html(this.el);
      this.splitModal.foundation('reveal', 'open', { });
      $(document).on('closed', '[data-reveal]', this.modalClosed);
      this.setState("ready");
    },
    dateSelected: function(dateText, inst) {
      var newDate = moment(dateText, "DD/MM/YYYY");
      if (newDate.isValid() &&
          newDate >= this.dates.minAfter &&
          newDate <= this.dates.maxAfter) {
        this.dates.afterDate = newDate;
        this.dates.beforeDate = moment(newDate);
        this.dates.beforeDate.subtract(1, "days");
        this.splitModal.find("#daybefore").html(this.dates.beforeDate.format("DD/MM/YYYY"));

      } else {
        var datePicker = this.splitModal.find('.datepicker');
        datePicker.val(this.dates.afterDate.format("DD/MM/YYYY"));
      }
    },
    url: function() {
      return "/proto_events/" + this.model.get("id") + "/split";
    },
    doSplit: function() {
      this.setState("splitting");
      $.post(this.url(),
             {afterdate: this.dates.afterDate.format("YYYY-MM-DD")},
             null,
             "json").done(this.splitOK).fail(this.splitFail);
    },
    splitOK: function(data, textStatus, jqXHR) {
      //
      //  We update our existing model with its new end date (which
      //  we already know, and then add the new model (details of
      //  which we have just received) to the collection.  Finally
      //  we close the dialogue.
      //
      var newPE = new ProtoEvent(data);
      that.protoEventsView.collection.add(newPE);
      this.splitModal.foundation('reveal', 'close');
      //
      //  The simplest way to get the remainder of our existing
      //  model up to date is to re-fetch it.
      //
      this.model.fetch();
    },
    splitFail: function(jqXHR, textStatus, errorThrown) {
      alert("Split failed.");
      this.splitModal.foundation('reveal', 'close');
    },
    doCancel: function() {
      this.splitModal.foundation('reveal', 'close');
    },
    modalClosed: function() {
      $(document).off('closed', '[data-reveal]', this.modalClosed);
      this.remove();
    }
  });

  var ProtoEventView = Backbone.View.extend({
    tagName: 'tbody',
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
      if (this.model.get("event_count") === 0) {
        this.model.destroy();
      } else {
        alert("Won't delete a room entry with active events.\nIf you really want to delete it, change the template to one with no entries, re-generate the events and then hit Delete again.");
      }
    },
    fieldContents: function() {
      return {
        room:             this.$('input.inputname').val(),
        location_id:      this.$('.location_id').val(),
        rota_template_id: this.$('.inputrtname').val(),
        starts_on_text:   this.$('input.starts_on').val(),
        ends_on_text:     this.$('input.ends_on').val(),
        num_staff:        this.$('input.num_staff').val()
      }
    },
    syncModel: function() {
      //
      //  Read fields from the view back into the model.
      //
      this.model.set(this.fieldContents());
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
      this.model.trigger("addRequested");
    },
    creationOK: function() {
      this.model.set({
        room: "",
        location_id: ""
      });
      this.$('input.inputname').focus();
    },
    creationError: function(model, response, options) {
      var view, errors;

      view = this;
      errors = $.parseJSON(response.responseText);
      for (var property in errors) {
        if (errors.hasOwnProperty(property)) {
          console.log("Error for " + property);
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

      view = this;
      errors = $.parseJSON(response.responseText);
      for (var property in errors) {
        if (errors.hasOwnProperty(property)) {
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
      this.setState("generating");
      this.model.generate(this.generationDone);
    },
    generationDone: function() {
      this.setState("created");
    },
    showSplitDialog: function() {
      if (this.model.canSplit()) {
        (new SplitView({model: this.model})).render();
      } else {
        alert("Can't split a one-day room allocation.");
      }
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
    el: '#ec-table',
    headerTemplate: _.template($('#ec-protoevents-header').html()),
    initialize: function (ecid) {
      this.examCycle = new ExamCycle({id: ecid});
      this.listenTo(this.examCycle, 'sync', this.gotExamCycle);
      this.collection = new ProtoEvents(null, {ecid: ecid});
      this.listenTo(this.collection, 'sync', this.render);
      this.newPE = new ProtoEvent({
        status: "creating",
        id: ""
      });
      this.listenTo(this.newPE, 'addRequested', this.processAdd);
    },
    render: function() {
//      console.log("Rendering collection.");
      var $list = this.$el.empty();
      $list.html(this.headerTemplate());
      this.collection.each(function(model) {
        var protoEventView = new ProtoEventView({model: model});
        $list.append(protoEventView.render().$el);
      }, this);
      this.inputView = new ProtoEventView({
        model: this.newPE
      });
      $list.append(this.inputView.render().$el);
      return this;
    },
    processAdd: function() {
      var newProtoEvent = this.collection.create(
        this.newPE.paramsToCreate(),
        {
          wait: true
        }).on('sync',
              this.inputView.creationOK,
              this.inputView).
           on('error',
              this.inputView.creationError,
              this.inputView);
    },
    fetchExamCycle: function() {
      this.examCycle.fetch();
    },
    gotExamCycle: function() {
      this.newPE.set({
        "rota_template_id": this.examCycle.get("default_rota_template_id"),
        "starts_on_text":   this.examCycle.get("starts_on_text"),
        "ends_on_text":     this.examCycle.get("ends_on_text"),
        "num_staff":        this.examCycle.get("default_quantity")
      });
      this.collection.fetch();
    }
  });

  function fetchData(ecid) {
    that.protoEventsView = new ProtoEventsView(ecid);
    that.protoEventsView.fetchExamCycle();
  };

  that.init = function() {
    //
    //  We have already checked that our master parent division
    //  exists, otherwise we wouldn't be running at all.
    //
    var ecid = $('#examcycle').data("ecid");
    fetchData(ecid);
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(examcycles.init);

}
