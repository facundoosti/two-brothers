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
      rescue ActiveRecord::InvalidForeignKey
        render_error(I18n.t("errors.menu_item_has_orders"), status: :unprocessable_entity)
      end

      # DELETE /api/v1/menu_items/:id/image
      def destroy_image
        item = MenuItem.find(params[:id])
        authorize item, :update?
        item.image.purge
        render json: MenuItemBlueprint.render_as_hash(item)
      end

      private

      def menu_item_params
        params.require(:menu_item).permit(:category_id, :name, :description, :price, :available, :daily_stock, :image)
      end
    end
  end
end
