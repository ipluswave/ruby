ActiveAdmin.register_page 'Monthly Reports' do
  menu parent: 'Reports', priority: 2

  content title: 'Monthly Reports' do
    render "admin/organizations/monthly_reports"
  end
  
  page_action :generate_report, method: :post do
    org = Organization.find(params[:report][:organization_id])

    filename = "#{Rails.root.to_s}/tmp/reports/#{SecureRandom.uuid}-#{org.id}.xls"
    book = org.build_report_xls(params[:report])
    book.write filename

    send_file filename,
      :type => 'application/vnd.ms-excel; charset=UTF-8;',
      :disposition => "attachment; filename=report-#{org.name.gsub(/[^a-zA-Z0-9]+/, '_')}.xls"
  end

end
