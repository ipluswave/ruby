module Legacy
  class Transaction < LegacyBase
    self.table_name = "TTRANSACTION"

    def self.migrate(from_organization_id, to_organization_id, migration_task = nil)
      log_level = 0
      credit_by_check = FinancialTransactionSubType.find(1)
      credit_by_cc = FinancialTransactionSubType.find(2)
      credit_by_refund = FinancialTransactionSubType.find(3)
      debit_by_print_card = FinancialTransactionSubType.find(4)
      debit_by_other = FinancialTransactionSubType.find(5)
      comment_author = User.where(email: "admin@instantcard.net").first
      comment_author ||= User.where(email: "system@instantcard.net").first
      
      # Don't need ParperTrails during import process
      PaperTrail.enabled = false

      # Set organization balance to zero before importing its Transactions
      # Organization.update_all("balance = 0", "id >= #{from_organization_id} and id <= #{to_organization_id}")
      Organization.where("id >= #{from_organization_id} and id <= #{to_organization_id} and system_cd = 0").update_all(balance: 0)
      
      all_transactions = Legacy::Transaction.where("COMPANY_NO >= ? and COMPANY_NO <= ?", from_organization_id, to_organization_id).order("COMPANY_NO, TRAN_NO")
      all_transactions.each do |transaction|
        org = Organization.where(id: transaction.COMPANY_NO).first
        
        unless org.present?
          MigrationTask.log_error_message(migration_task, org, "Transaction for an unknown organization (ID: #{transaction.COMPANY_NO}).", :migration_log_warning)
          log_level = set_log_level(log_level, :migration_log_warning)
        end
        next unless org.present?
        next if org.NewSystem?

        # delele it to re-create and re-execute the fund operation
        # org.financial_transactions.where(:id => transaction.TRAN_NO).delete_all
        FinancialTransaction.where(:id => transaction.TRAN_NO).delete_all
        
        # Get a new one
        new_ft = org.financial_transactions.where(:id => transaction.TRAN_NO).first_or_initialize
        new_ft_comment = "Migrated at #{Time.now}\n"

        case transaction.TRAN_TYPE
        when 0
          new_ft.financial_transaction_sub_type = (transaction.JOB_NUMBER.present? ? debit_by_print_card : debit_by_other)
          new_ft.debit = transaction.DEBIT.present? ? transaction.DEBIT : 0
          new_ft_comment << "JOB NUMBER: #{transaction.JOB_NUMBER}\n" if transaction.JOB_NUMBER.present?
          new_ft_comment << "CARD COST: #{transaction.CARD_COST}\n" if transaction.CARD_COST.present?
          new_ft_comment << "SHIPPING COST: #{transaction.SHIPPING_COST}\n" if transaction.SHIPPING_COST.present?
          new_ft.Debit!
        when 1
          new_ft.financial_transaction_sub_type = credit_by_refund
          new_ft.credit = transaction.CREDIT.present? ? transaction.CREDIT : 0
          new_ft.Credit!
        when 2
          new_ft.financial_transaction_sub_type = credit_by_check
          new_ft.credit = transaction.CREDIT.present? ? transaction.CREDIT : 0
          new_ft.Credit!
        when 3
          new_ft.financial_transaction_sub_type = credit_by_cc
          new_ft.credit = transaction.CREDIT.present? ? transaction.CREDIT : 0
          new_ft.Credit!
        else
          if transaction.CREDIT.present?
            new_ft.financial_transaction_sub_type = credit_by_check
            new_ft.credit = transaction.CREDIT.present? ? transaction.CREDIT : 0
            new_ft.Credit!
          elsif transaction.DEBIT.present?
            new_ft.financial_transaction_sub_type = (transaction.JOB_NUMBER.present? ? debit_by_print_card : debit_by_other)
            new_ft.debit = transaction.DEBIT.present? ? transaction.DEBIT : 0
            new_ft_comment << "JOB NUMBER: #{transaction.JOB_NUMBER}\n" if transaction.JOB_NUMBER.present?
            new_ft_comment << "CARD COST: #{transaction.CARD_COST}\n" if transaction.CARD_COST.present?
            new_ft_comment << "SHIPPING COST: #{transaction.SHIPPING_COST}\n" if transaction.SHIPPING_COST.present?
            new_ft.Debit!
          else
            # In this case it will be ignored and listed as warning
            MigrationTask.log_error_message(migration_task, org, "Transaction of unknown type (Type: #{transaction.TRAN_TYPE}) (ID: #{transaction.TRAN_NO}) (Date: #{transaction.TRAN_DATE}) being ignored.", :migration_log_warning)
            new_ft.delete
            org.migration_status_cd = [org.migration_status_cd.to_i, 1] # 1 is for :migration_log_warning
            org.save!
            next
          end
        end

        # Transactions will re-construct the balance with no need for the skip callback for now
        # new_ft.skip_callbacks = true
        new_ft.balance = transaction.BALANCE
        new_ft.created_at = transaction.TRAN_DATE.utc + 4.hours
        new_ft.updated_at = transaction.TRAN_DATE.utc + 4.hours
        new_ft.description = "#{transaction.CHEQUE_NO}" # if transaction.CHEQUE_NO.present?
        
        begin
          new_ft.save!

          # create comment:
          comment = ActiveAdmin::Comment.new(
            resource_id: new_ft.id,
            resource_type: new_ft.class.to_s,
            namespace: 'admin',
            author_id: comment_author.id,
            author_type: comment_author.class.to_s,
            body: new_ft_comment
          ).save!
        rescue Exception => e
          MigrationTask.log_error_message(migration_task, org, "Exception saving transaction (TRAN_NO: #{transaction.TRAN_NO}). Error: #{e.message}", :migration_log_error)
          log_level = set_log_level(log_level, :migration_log_error)
        end
      end

      # Turn it back on
      PaperTrail.enabled = true

      log_level
    end
    
    def self.check_legacy_balance(from_organization_id, to_organization_id, migration_task = nil)

      # client = Savon::Client.new(wsdl: ENV['legacy_preview_root'])
      all_orgs = Organization.where("id >= #{from_organization_id} and id <= #{to_organization_id}")
      all_orgs.each do |org|
        log_level = 0

        # Don't need to check orgs in the NewSystem
        next if org.NewSystem?

        # Child organizations don't have balance to be verified
        unless org.parent_organization.present?
          unless org.balance.eql?org.legacy_balance
            MigrationTask.log_error_message(migration_task, org, "Organization financial transaction don't reconcile balance ($#{org.balance.to_s}) with legacy balance ($#{org.legacy_balance.to_s}).", :migration_log_error)
            log_level = set_log_level(log_level, :migration_log_error)
          end
        
          # This code was used during the migration and right after the migration
          # [HR] Delete if not used after 06/10/2017
          # wsdl_user = org.users.first
          # 
          # if wsdl_user.present?
          #   basic_params = { "email" => wsdl_user.email.upcase, "CompanyPIN" => wsdl_user.pin}
          #   wsdl_acc_balance = client.call(:acc_balance, message: basic_params)
          #   begin
          #     mres = wsdl_acc_balance.to_hash[:acc_balance_response][:return].match(/01#([\-0-9\.]+)#(.*)/)
          #     if mres
          #       legacy_balance = mres[1].to_f.round(2)
          #       unless org.balance.to_s.eql? legacy_balance.to_s
          #         MigrationTask.log_error_message(migration_task, org, "Organization balance ($#{org.balance.to_s}) is different from legacy system ($#{legacy_balance}). Requires a newer backup of the Legacy DB.", :migration_log_warning)
          #         log_level = set_log_level(log_level, :migration_log_warning)
          #       end
          #     else
          #       MigrationTask.log_error_message(migration_task, org, "Unable to check balance for Organization #{org.name}. Possibly auth failed for user '#{wsdl_user.email}' with '#{wsdl_user.pin}'", :migration_log_error)
          #       log_level = set_log_level(log_level, :migration_log_error)
          #     end
          #   rescue Exception => e
          #     # 2nd check not ok
          #   end
          # else
          #   MigrationTask.log_error_message(migration_task, org, "Organization don't have an Admin User (#{org.id} - #{org.name}).", :migration_log_warning)
          #   log_level = set_log_level(log_level, :migration_log_warning)
          # end
        end

        last_financial_transaction = org.financial_transactions.last
        if last_financial_transaction.present?
          if last_financial_transaction.created_at + 18.months < Time.now
            org.Inactive!
          else
            org.Active!
          end
        end
        
        org.migration_status_cd = [org.migration_status_cd.to_i, log_level].max
        org.save!
      end

    end
  
    def self.migrate_financial_transaction(company, migration_task = nil)
      self.migrate(company.COMPANY_NO, company.COMPANY_NO, migration_task)
    end
    
  end
  
end
