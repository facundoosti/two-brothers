class ReplaceImageUrlWithImageDataInMenuItems < ActiveRecord::Migration[8.0]
  def change
    remove_column :menu_items, :image_url, :string
    add_column :menu_items, :image_data, :text
  end
end
