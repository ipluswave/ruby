class AddTotalJobsToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :total_jobs, :integer, :default => 0
    add_column :print_jobs, :is_sample, :boolean, :default => false

    Organization.all.each do |org|
      org.total_jobs = org.card_templates.joins(:print_jobs).where('print_jobs.type_cd' => 0).where('print_jobs.status_cd > 1').count
      org.save!
    end
    
    PrintJob.all.each do |pj|
      if pj.status_message.match(/Sample print job.*/)
        pj.is_sample = true
        pj.save!
      end
    end

  end
end
