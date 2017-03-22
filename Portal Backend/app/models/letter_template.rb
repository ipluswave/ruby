class LetterTemplate < ActiveRecord::Base
  include Bootsy::Container

  belongs_to :organization
  belongs_to :font

  scope :global, -> { where(organization_id: nil) }

  def from_user_data(user_data, print_job)
    # TODO (HR): can't use all_data the way it is. It needs to have all data nested (organizatino [address, contact, etc], card template, and others)
    all_data = user_data.merge(print_job.context)
    all_data = all_data.merge(print_job.attributes)
    all_data = all_data.merge({print_date_time: print_job.created_at.strftime("%Y-%m-%d %H:%M:%S")})
    all_data = all_data.merge({print_date: print_job.created_at.strftime("%Y-%m-%d")})
    Mustache.render(self.template, all_data)
  end
  
  def to_pdf_options
    {
      orientation: self.orientation,
      page_size: self.page_size,
      margin: {
        top: self.margin_top,
        bottom: self.margin_bottom,
        left: self.margin_left,
        right: self.margin_right
      }
    }
  end
  
  def css_width
    return 215 if self.page_size.eql?'Letter'
    210
  end
  
  def css_height
    return 279 if self.page_size.eql?'Letter'
    297
  end
  
  def font_family
    self.font.present? ? self.font.name : 'Arial'
  end
  
  def change_replaceable_tokens
    attrs = [
      {from: "&lt;COMPNO&gt;", to: "{{{COMPNO}}}"},
      {from: "&lt;COMPNAME&gt;", to: "{{{COMPNAME}}}"},
      {from: "&lt;COMPADD1&gt;", to: "{{{COMPADD1}}}"},
      {from: "&lt;COMPADD2&gt;", to: "{{{COMPADD2}}}"},
      {from: "&lt;COMPADD3&gt;", to: "{{{COMPADD3}}}"},
      {from: "&lt;COMPADD4&gt;", to: "{{{COMPADD4}}}"},
      {from: "&lt;COMPPOSTCODE&gt;", to: "{{{COMPPOSTCODE}}}"},
      {from: "&lt;COMPPHONE&gt;", to: "{{{COMPPHONE}}}"},
      {from: "&lt;COMPCONTACT&gt;", to: "{{{COMPCONTACT}}}"},
      {from: "&lt;COMPEMAIL&gt;", to: "{{{COMPEMAIL}}}"},
      {from: "&lt;CARDTITLE&gt;", to: "{{{CARDTITLE}}}"},
      {from: "&lt;CARDFIRSTNAME&gt;", to: "{{{CARDFIRSTNAME}}}"},
      {from: "&lt;CARDLASTNAME&gt;", to: "{{{CARDLASTNAME}}}"},
      {from: "&lt;CARDFULLNAME&gt;", to: "{{{CARDFULLNAME}}}"},
      {from: "&lt;CARDADD1&gt;", to: "{{{CARDADD1}}}"},
      {from: "&lt;CARDADD2&gt;", to: "{{{CARDADD2}}}"},
      {from: "&lt;CARDADD3&gt;", to: "{{{CARDADD3}}}"},
      {from: "&lt;CARDADD4&gt;", to: "{{{CARDADD4}}}"},
      {from: "&lt;CARDPOSTCODE&gt;", to: "{{{CARDPOSTCODE}}}"},
      {from: "&lt;CARDJOBNO&gt;", to: "{{{CARDJOBNO}}}"}, 
      {from: "&lt;CARDCREF&gt;", to: "{{{CARDCREF}}}"}
    ]
    
    attrs.each do |attr|
      self.template = self.template.gsub(attr[:from], attr[:to])
    end
    
    self.save
  end
end
