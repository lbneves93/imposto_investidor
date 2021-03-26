class CreateAssetPositions < ActiveRecord::Migration[6.1]
  def change
    create_table :asset_positions, id: :uuid do |t|
      t.integer :year
      t.string :code
      t.integer :quotas
      t.decimal :total_cost, precision: 11, scale: 2
      t.timestamps
    end
  end
end
