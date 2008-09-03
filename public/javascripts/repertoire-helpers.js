// Repertoire library of jquery utilities

jQuery(document).ready(function() {
	
  // support for ajax links via "remote" class
  // e.g. <a href='ajax-page-url' rel='#targetdiv' class='remote'>click here!</a>
  $("a.remote").click(function() { 
    $(this.rel).load(this.href); 
  });

  // notice animation
  $(".notice").animate( { backgroundColor: "#ff9900" }, 500)
              .animate( { backgroundColor: "#feffd3" }, 1000);

});



// this adapted from http://ejohn.org/blog/jquery-livesearch/

jQuery.fn.liveUpdate = function(list){
  list = jQuery(list);

  if ( list.length ) {
    var rows = list.children('li'),
      cache = rows.map(function(){
        return this.innerHTML.toLowerCase();
      });
     
    this
      .keyup(filter).keyup()
      .parents('form').submit(function(){
        return false;
      });
  }
   
  return this;
   
  function filter(){
    var term = jQuery.trim( jQuery(this).val().toLowerCase() ), scores = [];
   
    if ( !term ) {
      rows.show();
    } else {
      rows.hide();

      cache.each(function(i){
        var score = this.score(term);
        if (score > 0) { scores.push([score, i]); }
      });

      jQuery.each(scores.sort(function(a, b){return b[0] - a[0];}), function(){
        jQuery(rows[ this[1] ]).show();
      });
    }
  }
};