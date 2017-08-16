"use strict";

//
//  Do nothing at all unless we are on the right page.
//
if ($('#fb-editor').length) {

//
//  Wrap everything in a function to avoid namespace pollution
//  Note that we invoke the function immediately.
//
var user_forms = function() {

  var that = {};

  that.saveRequested = function(evt, formData) {
    //
    //  Shove the generated JSON into our field.
    //
    console.log("Saving");
    console.log("getData yields:");
    console.log(that.form_builder.actions.getData('json'));
    console.log("formData yields:");
    console.log(that.form_builder.formData);
    that.definition_field.val(that.form_builder.actions.getData('json'));
    //
    //  And submit our form.
    //
    that.myform.submit();
  }

  that.init = function() {
    //
    //  We have already checked that our master parent division
    //  exists, otherwise we wouldn't be running at all.
    //
    that.fb_editor = $('#fb-editor');
    that.myform = $("[class$=_user_form]");
    that.definition_field = $('#user_form_definition');

    var options = {
      disableFields: ['autocomplete', 'button', 'hidden', 'file'],
      onSave: that.saveRequested,
      dataType: 'json',
      formData: that.definition_field.val()
    };

    that.form_builder = $('#fb-editor').formBuilder(options);
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(user_forms.init);

}
