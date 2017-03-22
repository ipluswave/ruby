class CreateWorkstationWorkersQueue < ActiveRecord::Migration
  def change
    add_column :workstations, :workers_queue, :string, :default => "print"
  end
end
