
//
//  Wrap everything in a function to avoid namespace pollution
//  Note that we invoke the function immediately.
//
rotatemplates = function() {

  that = {};

  var RotaSlot = Backbone.Model.extend({
  });

  var RotaSlotView = Backbone.View.extend({
    model: RotaSlot,
    tagName: 'tr',
    className: 'rt-rotaslot',
    template: _.template($('#rt-slot-row').html()),
    initialize: function() {
      this.model.on('change', this.render, this);
      this.model.on('destroy', this.remove, this);
    },
    events: {
      'click .destroy' : 'destroy'
    },
    render: function() {
      this.$el.html(this.template(this.model.toJSON()));
      return this;
    },
    destroy: function() {
      this.model.destroy();
    }
  });

  var RotaSlots = Backbone.Collection.extend({
    model: RotaSlot,
    initialize: function(models, options) {
      this.rtid = options.rtid;
    },
    comparator: function(item) {
      return item.attributes.start_second;
    },
    url: function() {
      return '/rota_templates/' + this.rtid + '/rota_slots'
    }
  });

  var SlotsView = Backbone.View.extend({
    el: '#rt-table',
    headertemplate: _.template($('#rt-header-row').html()),
    newslottemplate: _.template($('#rt-newslot-row').html()),
    initialize: function (rtid) {
      this.collection = new RotaSlots(null, {rtid: rtid});
      this.listenTo(this.collection, 'sync', this.render);
      this.collection.fetch();
      //
      //  Also need a spare model to store stuff we might use to
      //  create a new model in the database.
      //
      this.pendingSlot = new RotaSlot({
        days: [false, true, true, true, true, true, false],
        starts_at: "",
        ends_at: ""
      });
    },
    events: {
      'click .add' : 'addSlot'
    },
    render: function() {
      console.log("Asked to render " + this.collection.length + " slots");
      $list = this.$el.empty();
      $list.append(this.headertemplate);
      this.collection.each(function(model) {
        var slotView = new RotaSlotView({model: model});
        $list.append(slotView.render().$el);
      }, this);
      $list.append(this.newslottemplate(this.pendingSlot.toJSON()));
      this.saInput = this.$('#new-starts-at')
      this.eaInput = this.$('#new-ends-at')
      this.saInput.focus();
      return this;
    },
    addSlot: function() {
      //alert("Asked to add. " + this.saInput.val());
      //
      //  Need to get values from the two input fields, plus build an
      //  array of values from the checkboxes.  This then should
      //  give me enough to request that a new model be created.
      //  The server tries to make sense of the time fields and may
      //  reject the request if it can't.
      //
      days = [];
      pendingSlotDays = this.pendingSlot.get('days');
      this.$el.find('#rt-newslot-row').find('.toggle').each(function(index, element)  {
        days[index] = element.checked;
        //
        //  If we succeed in creating the new element then our whole
        //  collection will be re-displayed, and it's friendly to our
        //  end user if we keep his set of flags.
        //
        //  Can assign to the attribute directly, because don't need
        //  any events triggering.
        //
        pendingSlotDays[index] = element.checked;
      });
      newSlot = this.collection.create({
        days: days,
        starts_at: this.saInput.val(),
        ends_at: this.eaInput.val()
      }, {
        wait: true,
        success: function() {
          console.log("Created successfully.");
        },
        error: function() {
          console.log("Failed to create.");
        }
      });
    }
  });

  function getSlots(rtid) {
    slotsView = new SlotsView(rtid);
  };

  that.init = function() {
    //
    //  If a div with our id exists, then we do stuff.
    //  If that div doesn't exist then we're on a different page.
    //
    ourdiv = $('#rotatemplate');
    if (ourdiv.length !== 0) {
      rtid = ourdiv.data("rtid");
      getSlots(rtid);
    }
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(rotatemplates.init);

