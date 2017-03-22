ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do
    # div class: "blank_slate_container", id: "dashboard_default_message" do
    #   span class: "blank_slate" do
    #     span I18n.t("active_admin.dashboard_welcome.welcome")
    #     small I18n.t("active_admin.dashboard_welcome.call_to_action")
    #   end
    # end

    @total_jobs, @jobs_per_shipping, @companies = PrintJob.summary
    columns do
      column do
        panel "Companies with Jobs today (#{@companies.count})" do
          ul do
            @companies.each do |company|
              li company
            end
          end
        end
      end

      column do
        panel "Info" do
          para do
            text_node "Total cards in the queue: "
            span @total_jobs, class: 'badge'
          end
        end
        panel "Jobs per shipping" do
          para do
            text_node "USPS: "
            span @jobs_per_shipping[0], class: 'badge'
          end
          para do
            text_node "Fedex Overnight: "
            span @jobs_per_shipping[1], class: 'badge'
          end
          para do
            text_node "UPS Overnight: "
            span @jobs_per_shipping[2], class: 'badge'
          end
        end
        panel "(Last) Card per Workstation" do
          ul do
            Printer.card_printers.includes(:workstation).where("workstations.status_cd" => 1).each do |printer|
              li do
                text_node "#{printer.workstation.name}: "
                span "#{printer.last_card_type_name}", class: 'badge'
              end
            end
          end
        end
      end
    end

    render partial: "layouts/reload"
  end # content
end
