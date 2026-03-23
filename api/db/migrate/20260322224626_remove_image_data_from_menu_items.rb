class RemoveImageDataFromMenuItems < ActiveRecord::Migration[8.0]
  def change
    remove_column :menu_items, :image_data, :text
  end
end
