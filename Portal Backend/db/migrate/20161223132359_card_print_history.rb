class CardPrintHistory < ActiveRecord::Migration
  def change
    create_table :card_print_histories do |t|
      t.references :cards, index: true
      t.references :user_data, index: true

      t.timestamps null: false
    end
  end
end
