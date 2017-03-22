$(document).ready(function () {
  if ($('.organization-add-form').length) {
    var step = 1,
      first_error = $('.inline-errors').first();

    if (first_error.length) {
      var error_container_form = first_error.parents('.organization-add-form');

      $('.organization-add-form').hide();
      error_container_form.show();

      step = error_container_form.attr('class').replace(/[^0-9]/g, '');

      if (step == 1) {
        $('.organization-add-prev, .organization-add-save').hide();
      } else if (step < 4) {
        $('.organization-add-prev').show();
        $('.organization-add-save').hide();
      } else if (step == 4) {
        $('.organization-add-next').hide();
        $('.organization-add-prev, .organization-add-save').show();
      }
    }

    $('.organization-add-next').on('click', function (e) {
      e.preventDefault();

      step++;

      $('.organization-add-form').hide();
      $('.step-' + step + ', .organization-add-prev').show();

      if (step == 4) {
        $('.organization-add-next, .organization-add-save').toggle();
      }
    });

    $('.organization-add-prev').on('click', function (e) {
      e.preventDefault();

      step--;

      $('.organization-add-form, .organization-add-save').hide();
      $('.step-' + step + ', .organization-add-next').show();

      if (step == 1) {
        $('.organization-add-prev').hide();
      }
    });
  }

  if ($('.printer-form-card-types').length) {
    var printer_form_select_all_checked = $('.printer-form-card-types').parents('.choices-group').find('.printer-form-card-types:checked').length == $('.printer-form-card-types').parents('.choices-group').find('.printer-form-card-types').length;
    $('.printer-form-card-types').parents('.choices-group').prepend('<li class="choice"><label for="printer_card_type_ids"><input type="checkbox" name="printer[card_type_ids][]" id="printer_card_type_ids" value="" class="printer-form-card-types"' + (printer_form_select_all_checked ? ' checked ' : '') + '>Select All</label></li>');

    $('.printer-form-card-types').on('click', function () {
      if (!this.value.length) {
        $(this).parents('.choices-group').find('.printer-form-card-types').prop('checked', $(this).is(':checked'))
      }
    });
  }


});
