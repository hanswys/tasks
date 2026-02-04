class AddFieldsToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :priority, :integer, default: 0
    add_column :tasks, :status, :integer, default: 0
    add_column :tasks, :due_date, :datetime
    add_reference :tasks, :category, null: true, foreign_key: true
    add_column :tasks, :position, :integer, default: 0
    add_column :tasks, :estimated_minutes, :integer
    add_reference :tasks, :parent, null: true, foreign_key: { to_table: :tasks }
  end
end
