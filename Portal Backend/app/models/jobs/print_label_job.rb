module Jobs
  class PrintLabelJob
    attr_accessor :print_job_id

    def initialize(options)
      self.print_job_id = options[:print_job_id]
    end

    def perform
      print_job = PrintJob.find(self.print_job_id)
      organization = print_job.organization
      card_template = print_job.card_template

      screenshot = Screenshot.new

      label_printer = Printer.where(:workstation_id => print_job.workstation_id).where(:print_label => true).first
      if label_printer.present?
        # drop_ship_address = print_job.address if print_job.address.present?
        if print_job.address.present?
          address_to_print = print_job.drop_ship_address
        else
          address_to_print = organization.delivery_address  
        end

        shipping_on_label = (print_job.shipping_provider.present?) ? "#{print_job.shipping_provider.name} " : ""

        begin
          @first_line = "#{print_job.id} " + shipping_on_label + card_template.extended_special_handlings_tokens + " #{print_job.total_cards}     "
          # @from_address = (drop_ship_address.present?) ? drop_ship_address : address_to_print.first
          @from_address = address_to_print.first
          @to_address = address_to_print.second

          label_version = "v2"
          label_version = ENV['USE_LABEL_VERSION'] if ENV['USE_LABEL_VERSION'].present?
          label_template_file = "#{Rails.root.to_s}/lib/templates/erb/label_template/label_template_#{label_version}.html.erb"
          
          @template = File.read(label_template_file)
          html_label_to_print = ERB.new(@template).result( binding )

          html_label_file_path = "#{Rails.root.to_s}/public/labels/card-#{self.print_job_id}-label.html"
          File.open(html_label_file_path, 'w') { |file| file.write(html_label_to_print) }

          label_file_path = "#{Rails.root.to_s}/tmp/cards/card-#{self.print_job_id}-label.pdf"
          
          html_label_url = "#{ENV['preview_root']}/labels/card-#{self.print_job_id}-label.html?_t=#{Time.now.to_i}"
          result = screenshot.capture_screenshot(html_label_url, label_file_path, {width: '100mm', height: '59mm'})
          
          # To use CUPS gem is necessary to pass parameters with only a key, like -o landscape
          # cups_label_printer ||= CupsPrinter.new(label_printer.name)
          # cups_label_printer.print_file(label_file_path, {"PageSize"=>"w167h288"})
          system("lpr -P #{label_printer.name} -o page-ranges=1-1 -o landscape -o PageSize=w167h288 #{label_file_path}")
        rescue Exception => e
          Rails.logger.error("Exception print card (Job:#{self.print_job_id} - LabelPrinter:#{label_printer.name})")
          Rails.logger.error("Exception: #{e.to_s}")
          print_job.append_status_message "Exception printing label (LabelPrinter:#{label_printer.name}). Error: #{e.to_s}"
        end
      else
        print_job.append_status_message "Couldn't find a Label Printer on Workstation #{print_job.workstation.name}" if print_job.should_print_label?
      end

      screenshot.reset_session
      
      print_job.append_status_message "Print Label Job finished successfully"
      print_job.save
    end

    def self.enqueue(options, queue = 'print')
      new_job = PrintLabelJob.new(options)
      Delayed::Job.enqueue queue: queue, payload_object: new_job, run_at: Time.now
    end

  end
end
