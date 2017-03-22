#= require active_admin/base
#= require bootstrap-sprockets
#= require bootsy
#= require croppic.min
#= require custom_columns
#= require custom_forms
#= require select2

$("document").ready ->
  $("#report_organization_id").select2({
    placeholder: 'Select an Organization',
    theme: "bootstrap"
  })
  
  $("#q_organization_id").select2({
    theme: "bootstrap"
  })
  
  $("#financial_transaction_organization_id").select2({
    theme: "bootstrap"
  })
  
  $("#card_template_organization_id").select2({
    theme: "bootstrap"
  })

  $("#cost_organization_id").select2({
    theme: "bootstrap"
  })

  $("#cost_costable_item").select2({
    width: '384px',
    theme: "bootstrap"
  })

  $("#user_organization_id").select2({
    theme: "bootstrap"
  })

  $("#font_organization_ids").select2({
    multiple: true,
    theme: "bootstrap"
  })

  $("#card_type_organization_ids").select2({
    multiple: true,
    theme: "bootstrap"
  })
  
  $("#q_card_template_id").select2({
    theme: "bootstrap"
  })
  
  $("#q_clone_card_template_id").select2({
    theme: "bootstrap"
  })
