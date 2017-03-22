class AddPrintedAtToPrintJob < ActiveRecord::Migration
  def migrate(direction)
    super

    # Set printed_at based on (last) updated_at for existing jobs
    if direction == :up
      ActiveRecord::Base.connection.execute("update print_jobs set printed_at = updated_at where status_cd in (3, 4)")
    end
  end
  
  def change
    add_column :print_jobs, :printed_at, :datetime, :default => nil
    add_index :print_jobs, :printed_at
  end
end
