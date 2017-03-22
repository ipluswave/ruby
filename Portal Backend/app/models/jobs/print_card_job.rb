module Jobs
  class PrintCardJob
    attr_accessor :print_job_id

    def initialize(options)
      self.print_job_id = options[:print_job_id]
    end

    def perform
      print_job = PrintJob.find(self.print_job_id)
      organization = print_job.organization
      if print_job.Normal? and !print_job.is_sample
        organization.total_jobs += 1
        organization.save!
      end
      card_template = print_job.card_template
      orientation = card_template.option_key("orientation")
      card_type = card_template.card_type
      shipping_provider = print_job.shipping_provider

      # Check if workstation is ready before printing and paying for the job
      printer = Printer.where(:workstation_id => print_job.workstation_id).joins(:card_types).where('card_types_printers.card_type_id' => card_type.id).first
      if !printer.present? and print_job.should_print_cards?
        print_job.append_status_message "Printer not found for card type #{card_type.name}"
        print_job.Failed!
        print_job.set_printed_date
        print_job.save
        return
      end

      screenshot = Screenshot.new

      label_printer = Printer.where(:workstation_id => print_job.workstation_id).where(:print_label => true).first
      if label_printer.present? and print_job.should_print_label?
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
      
      letter_id = card_template.option_key("letter_id")
      if letter_id.present? and print_job.should_print_letter?
        letter = LetterTemplate.find(letter_id)
        letter_printer = Printer.where(:workstation_id => print_job.workstation_id).where(:print_letter => true).first
        letter_printer ||= print_job.site.printers.where(:print_letter => true).first
      end

      lu = print_job.list_users.first
      lu.user_datum.each do |ua|
        begin
          if print_job.should_print_cards?
            card_url = "#{ENV['preview_root']}/card_templates/#{card_template.id}/image/#{ua.id}/front?_t=#{Time.now.to_i}"
            card_path = "#{Rails.root.to_s}/tmp/cards/card-#{self.print_job_id}-#{ua.id}-front.jpg"
            
            # fix UD: replace characters that can break from and back canvas JSON
            ua.fix_data

            page = screenshot.capture(card_url, card_path, card_template.width, card_template.height)
            unless page.first
              ua.Failed!
              ua.save!
              next
            end
            
            card_document = Magick::ImageList.new
            front_size = Magick::Image.read(card_path).first
            # front_size.resample!(300)
            # front_size.resize!(663,1052) # for 300 DPI
            # front_size.resize!(1306,2070) # for 600 DPI
            # front_size.write(card_path)
            # front_size = Magick::Image.read(card_path).first
            card_document << front_size

            sides_opt = card_template.option_key("sides")
            if sides_opt.present? and sides_opt.eql?"double"
              # This is a double sided card
              card_url = "#{ENV['preview_root']}/card_templates/#{card_template.id}/image/#{ua.id}/back?_t=#{Time.now.to_i}"
              card_path = "#{Rails.root.to_s}/tmp/cards/card-#{self.print_job_id}-#{ua.id}-back.jpg"

              page = screenshot.capture(card_url, card_path, card_template.width, card_template.height)
              unless page.first
                ua.Failed!
                ua.save!
                next
              end

              back_size = Magick::Image.read(card_path).first
              # back_size.resample!(300)
              # back_size.resize!(663,1052) # for 300 DPI
              # back_size.resize!(1306,2070) # for 600 DPI
              # back_size.write(card_path)
              # back_size = Magick::Image.read(card_path).first
              if orientation.eql? "portrait"
                back_size = back_size.rotate(180)
              end
              card_document << back_size
            end

            card_document_path = "#{Rails.root.to_s}/tmp/cards/card-#{self.print_job_id}-#{ua.id}.pdf"
            card_document.write(card_document_path)

            printing_options = card_template.print_options(ua)
            Rails.logger.info("Print options (CRDT: #{card_template.id}, UD: #{ua.id}): #{printing_options}")

            # Through CUPS gem the fit-to-page parameter is not being processed
            # cups_printer ||= CupsPrinter.new(printer.name)
            # cups_printer.print_file(card_document_path, printing_options)
            system("lpr -P #{printer.name} #{printing_options} #{card_document_path}") unless ENV['IMAGE_TEST'].present?
          end
          
          # Generate and print letter
          if letter_printer.present? and print_job.should_print_letter?
            letter_to_print = letter.from_user_data(ua.template_fields_data(card_template.template_fields), print_job)
            letter_to_print = letter_to_print.gsub(/\r\n/,"<br>")
            @message = letter_to_print
            @template = File.read("#{Rails.root.to_s}/lib/templates/erb/letter_template/letter_template.html.erb")
            @letter = letter
            html_letter_to_print = ERB.new(@template).result( binding )

            html_letter_file_path = "#{Rails.root.to_s}/public/letters/card-#{self.print_job_id}-#{ua.id}-letter.html"
            File.open(html_letter_file_path, 'w') { |file| file.write(html_letter_to_print) }

            letter_file_path = "#{Rails.root.to_s}/tmp/cards/card-#{self.print_job_id}-#{ua.id}-letter.pdf"
            # pdf = WickedPdf.new.pdf_from_string(letter_to_print, letter.to_pdf_options)
            # File.open(letter_file_path, 'wb') { |file| file << pdf }
            
            html_letter_url = "#{ENV['preview_root']}/letters/card-#{self.print_job_id}-#{ua.id}-letter.html?_t=#{Time.now.to_i}"
            result = screenshot.capture_screenshot(html_letter_url, letter_file_path, {format: letter.page_size})
            
            begin
              cups_letter_printer ||= CupsPrinter.new(letter_printer.name)
              # cups_letter_printer.print_file(letter_file_path, {})
              cups_letter_printer.print_file(letter_file_path, {})
              # system("lpr -P #{letter_printer.name} #{letter_file_path}")
            rescue Exception => e
              Rails.logger.error("Exception print card letter (Job:#{self.print_job_id} - UserData:#{ua.id})")
              Rails.logger.error("Exception: #{e.to_s}")
              print_job.append_status_message "Exception printing card letter (UserData:#{ua.id}). Error: #{e.to_s}"
            end
          end
          
          ua.Printed!
          ua.save!
        rescue Exception => e
          Rails.logger.error("Exception print card (Job:#{self.print_job_id} - UserData:#{ua.id})")
          Rails.logger.error("Exception: #{e.to_s}")
          Rails.logger.debug("Stacktrace: #{e.backtrace}")
          print_job.append_status_message "Exception printing card (UserData:#{ua.id}). Error: #{e.to_s}"
          ua.Failed!
          ua.save!
        end
      end if lu.present?

      screenshot.reset_session
      
      print_job.append_status_message "Job finished successfully"
      print_job.Finished!
      print_job.set_printed_date
      print_job.save
    end

    def self.enqueue(options, queue = 'print')
      new_job = PrintCardJob.new(options)
      Delayed::Job.enqueue queue: queue, payload_object: new_job, run_at: Time.now
    end

  end
end
