
//
//  Wrap everything in a function to avoid namespace pollution
//  Note that we invoke the function immediately.
//
rotatemplates = function() {

  that = {};

  that.init = function() {
    //
    //  If a div with our id exists, then we do stuff.
    //  If that div doesn't exist then we're on a different page.
    //
    var leftcol;

    if ($('#rotatemplate').length !== 0) {
    }
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(rotatemplates.init);

