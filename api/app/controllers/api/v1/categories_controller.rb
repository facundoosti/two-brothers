module Api
  module V1
    class CategoriesController < BaseController
      skip_before_action :authenticate_user!, only: :index

      # GET /api/v1/categories — público, sin authorize
      def index
        categories = Category.includes(:menu_items).all
        render json: CategoryBlueprint.render_as_hash(categories, view: :with_items)
      end

      # POST /api/v1/categories
      def create
        authorize Category, :create?
        category = Category.new(category_params)
        if category.save
          render json: CategoryBlueprint.render_as_hash(category, view: :with_items), status: :created
        else
          render_error(category.errors.full_messages.join(", "))
        end
      end

      # PATCH /api/v1/categories/:id
      def update
        category = Category.find(params[:id])
        authorize category
        if category.update(category_params)
          render json: CategoryBlueprint.render_as_hash(category, view: :with_items)
        else
          render_error(category.errors.full_messages.join(", "))
        end
      end

      # DELETE /api/v1/categories/:id
      def destroy
        category = Category.find(params[:id])
        authorize category
        category.destroy!
        head :no_content
      end

      private

      def category_params
        params.require(:category).permit(:name, :position)
      end
    end
  end
end
