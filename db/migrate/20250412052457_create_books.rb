class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.string :title
      t.string :author
      t.string :isbn
      t.string :genre
      t.text :description
      t.date :publication_date
      t.string :publisher
      t.integer :page_count

      t.timestamps
    end
  end
end
