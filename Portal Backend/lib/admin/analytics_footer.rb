module Admin
  class AnalyticsFooter < ActiveAdmin::Views::Footer
    def build
      super
      render('layouts/analytics')
    end
    
    def powered_by_message
      para I18n.t('instant_card.powered_by',
        instant_card: link_to("InstantCard", "http://instantcard.net"),
        instant_card_version: InstantCard::VERSION,
        active_admin: link_to("Active Admin", "http://www.activeadmin.info"),
        version: ActiveAdmin::VERSION).html_safe
    end

   end
 end