module CustomHelper
  def _select set, selected, options={}
    style = "margin:0;padding:0;#{options["style"]}"

    selected  = options["default"] if selected.blank?
    cache     = options["cache"] || nil
    id        = options["id"] || nil

    id ||= "ch#{ch_uniq_id}" unless cache.blank?

    html = ""
    html << "<select "
    html << " style='#{style}' "
    html << " #{options["attrs"]} "
    html << " data-cache='#{cache}' " unless cache.blank?
    html << " id='#{id}' " unless id.blank?
    html << ">"

    if options["blank"]
      html << "<option></option>"
    end

    unless cache.blank?
      options_html = Rails.cache.fetch("CustomHelper:#{cache}", expires_in: 1.minute ) { _select_options set, selected, options }
    else
      options_html = _select_options set, selected, options
    end

    html << options_html
    html << "</select>"

    unless cache.blank?
      html << %{
        <script type="text/javascript">
          $( document ).ready(function() {
            $("select##{id}").val("#{selected.to_s.strip}");
          });
        </script>
      }
    end

    html
  end

  def _select_options set, selected, options
    html = ""
    selected = selected.to_s.strip
    arr_match = options["arr_match"] || 0

    set.each do |option|
      check = option
      value = option

      if option.is_a? Array
        check  = option[arr_match]
        value  = option[0]
        option = option[1]
      end

      if selected==check.to_s.strip
        html << "<option value='#{value}' selected>#{option}</option>"
      else
        html << "<option value='#{value}'>#{option}</option>"
      end
    end

    html
  end

  def ch_uniq_id
    @ch_uniq_id ||= Time.now.to_i
    @ch_uniq_id += 1
  end
end
