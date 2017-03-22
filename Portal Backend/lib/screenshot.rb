require "capybara/dsl"
require "capybara/poltergeist"
require "nokogiri"

class Screenshot
  include Capybara::DSL

  # Captures a screenshot of +url+ saving it to +path+.
  def capture(url, path, width = 457, height = 288, screenshot = false, wait_cycles = 21)
    # Browser settings
    # Width and Height are inherited from CardTemplate -> CardType
    page.driver.resize(width, height)
    page.driver.headers = {
      "User-Agent" => "Webshot 1.0",
    }

    # Open page
    visit url

    if page.driver.status_code == 200
      # Wait until HTML page has a token indicating the canvas has been completely rendered
      loop do
        break unless Screenshot.is_html_ready(page.html).nil?
        if wait_cycles.eql?0
          Rails.logger.error("[Screenshot] URL (#{url}) is taking too long to load")
          return [false, "", ""]
        end
        wait_cycles -= 1
        sleep(1)
      end
      
      # Rails.logger.info("[Screenshot] WC: #{wait_cycles}")

      # Save screenshot
      if screenshot
        image_data = page.driver.render_base64()
      else
        html = Nokogiri::HTML(page.html)
        base64_image = html.css('div').last.text
        image_data = Base64.decode64(base64_image['data:image/jpeg;base64,'.length .. -1])

        image = File.new(path, "wb")
        image.write(image_data)
      end

      ret_value = [true, image_data, page.html]
    else
      Rails.logger.error("[Screenshot] Invalid HTTP status code: #{page.driver.status_code}")
      ret_value = [false, "", ""]
    end

    ret_value
  end
  
  def capture_screenshot(url, path, paper_size = {format: 'Letter'})
    # Browser settings
    page.driver.headers = {
      "User-Agent" => "Webshot 1.0",
    }
    page.driver.paper_size = paper_size

    # Open page
    visit url

    if page.driver.status_code == 200
      page.driver.save_screenshot(path, :full => true)
      true
    else
      false
    end
  end
  
  def capture_card_preview(card, side, wait_cycles = 21)
    card_url = "#{ENV['preview_root']}/card/#{card.id}/#{side}/preview?_t=#{Time.now.to_i}"
    width = card.card_template.width+1
    height = card.card_template.height+1

    page.driver.resize(width, height)
    page.driver.headers = {
      "User-Agent" => "Webshot 1.0",
    }

    # Open page
    visit card_url

    if page.driver.status_code == 200
      # Wait until HTML page has a token indicating the canvas has been completely rendered
      loop do
        break unless Screenshot.is_html_ready(page.html).nil?
        if wait_cycles.eql?0
          Rails.logger.error("[Screenshot] URL (#{card_url}) is taking too long to load")
          return [false, ""]
        end
        wait_cycles -= 1
        sleep(1)
      end
      
      # Capture base64
      image_data = page.driver.render_base64()

      ret_value = [true, image_data]
    else
      Rails.logger.error("[Screenshot] Invalid HTTP status code: #{page.driver.status_code}")
      ret_value = [false, ""]
    end

    ret_value
  end
  
  def reset_session
    begin
      page.reset!
    rescue
    end
  end
  
  def self.is_html_ready(html)
    html.match(/\>isReady<\/div>/)
  end
end
