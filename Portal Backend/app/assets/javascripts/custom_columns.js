var admin = {

  init: function(){
    admin.set_admin_editable_events();
    admin.set_admin_selectable_events();
    admin.set_admin_minimizable_events();
  },

  set_admin_editable_events: function(){
    $(".admin-editable").on("keypress", function(e){
      if ( e.keyCode==27 )
        $( e.currentTarget ).hide();

      if ( e.keyCode==13 ){
        var path        = $( e.currentTarget ).attr("data-path");
        var attr        = $( e.currentTarget ).attr("data-attr");
        var resource_id = $( e.currentTarget ).attr("data-resource-id");
        var val         = $( e.currentTarget ).val();

        val = $.trim(val)
        if (val.length==0)
          val = "&nbsp;";

        $("div#"+$( e.currentTarget ).attr("id")).html(val);
        $( e.currentTarget ).hide();

        var payload = {}
        resource_class = path.slice(0,-1) // e.g. path = meters, resource_class = meter
        payload[resource_class] = {};
        payload[resource_class][attr] = val;

        $.ajax({
          method: "PUT",
          url: "/admin/"+path+"/"+resource_id+"/update_no_redir",
          data: payload
        }).done(function(result){
          current_target = e.currentTarget;
          $(current_target.parentElement.parentElement).fadeIn("slow", "swing", $(current_target.parentElement.parentElement).fadeOut());
        });
      }
    });

    $(".admin-editable").on("blur", function(e){
      $( e.currentTarget ).hide();
    });
  },

  editable_text_column_do: function(el){
    var input = "input#"+$(el).attr("id")

    $(input).width( $(el).width()+4 ).height( $(el).height()+4 );
    $(input).css({top: ( $(el).offset().top-2 ), left: ( $(el).offset().left-2 ), position:'absolute'});

    val = $.trim( $(el).html() );
    if (val=="&nbsp;")
      val = "";
      
    $(input).val( val );
    $(input).show();
    $(input).focus();
  },
  
  set_admin_selectable_events: function(){
    $("select.admin-selectable").on("change", function(e){
      var path        = $( e.currentTarget ).attr("data-path");
      var attr        = $( e.currentTarget ).attr("data-attr");
      var resource_id = $( e.currentTarget ).attr("data-resource-id");
      var val         = $( e.currentTarget ).val();

      val = $.trim(val)

      var payload = {}
      resource_class = path.slice(0,-1)
      payload[resource_class] = {};
      payload[resource_class][attr] = val;

      $.ajax({
        method: "PUT",
        url: "/admin/"+path+"/"+resource_id+"/update_no_redir",
        data: payload
      }).done(function(result){
        current_target = e.currentTarget;
        $("#workstation_select_warning_modal_body").empty();
        $.each(result.messages, function(i, val){
          $('#workstation_select_warning_modal_body').append('<p>'+val+'</p>');
        });
        if( result.messages.length > 0 ) {
          $("#workstation_select_warning_modal").modal();
        } else {
          $(current_target.parentElement.parentElement).fadeIn("slow", "swing", $(current_target.parentElement.parentElement).fadeOut());
        }
      });

    });
  },
  
  set_admin_minimizable_events: function(){
    var print_job_summary_panel = $('#summary-panel'),
      panel_minimized = localStorage.getItem('print_job_summary_panel_minimized');

    if(typeof(panel_minimized) !== 'undefined' && panel_minimized == 'true') {
      print_job_summary_panel.find('.panel_contents').hide();
    }

    print_job_summary_panel.on('click', function() {
      var panel = $(this).find('.panel_contents');
      localStorage.setItem('print_job_summary_panel_minimized', panel.is(':visible'));
      panel.toggle();
    });
  }
}

$( document ).ready(function() {
  admin.init();
});
