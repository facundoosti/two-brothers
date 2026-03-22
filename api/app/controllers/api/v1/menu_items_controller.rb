module Api
  module V1
    class MenuItemsController < BaseController
      # POST /api/v1/menu_items
      def create
        authorize MenuItem, :create?
        item = MenuItem.new(menu_item_params)
        if item.save
          render json: MenuItemBlueprint.render_as_hash(item), status: :created
        else
          render_error(item.errors.full_messages.join(", "))
        end
      end

      # PATCH /api/v1/menu_items/:id
      def update
        item = MenuItem.find(params[:id])
        authorize item
        if item.update(menu_item_params)
          render json: MenuItemBlueprint.render_as_hash(item)
        else
          render_error(item.errors.full_messages.join(", "))
        end
      end

      # DELETE /api/v1/menu_items/:id
      def destroy
        item = MenuItem.find(params[:id])
        authorize item
        item.destroy!
        head :no_content
      end

      private

      def menu_item_params
        params.require(:menu_item).permit(:category_id, :name, :description, :price, :available, :image_url)
      end
    end
  end
end
