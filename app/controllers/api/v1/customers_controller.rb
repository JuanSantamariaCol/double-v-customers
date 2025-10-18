module Api
  module V1
    class CustomersController < ApplicationController
      include Pagy::Backend

      before_action :set_customer, only: [:show, :update, :destroy]

      # GET /api/v1/customers
      def index
        pagy, customers = pagy(Customer.actives.order(created_at: :desc), items: params[:per_page] || 20)

        render json: CustomerSerializer.new(customers).serializable_hash.merge(
          meta: pagy_metadata(pagy)
        )
      end

      # GET /api/v1/customers/:id
      def show
        render json: CustomerSerializer.new(@customer).serializable_hash
      end

      # POST /api/v1/customers
      def create
        result = Customers::CreatorService.new(customer_params).call

        if result.success?
          render json: CustomerSerializer.new(result.customer).serializable_hash, status: :created
        else
          render json: { errors: format_errors(result.errors) }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/customers/:id
      def update
        result = Customers::UpdaterService.new(@customer, customer_params).call

        if result.success?
          render json: CustomerSerializer.new(result.customer).serializable_hash
        else
          render json: { errors: format_errors(result.errors) }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/customers/:id
      def destroy
        if @customer.soft_delete
          head :no_content
        else
          render json: {
            error: {
              code: 'delete_failed',
              message: 'No se pudo eliminar el cliente'
            }
          }, status: :unprocessable_entity
        end
      end

      private

      def set_customer
        @customer = Customer.actives.find_by(id: params[:id])

        unless @customer
          render json: {
            error: {
              code: 'customer_not_found',
              message: "El cliente con ID #{params[:id]} no fue encontrado"
            }
          }, status: :not_found
        end
      end

      def customer_params
        params.require(:customer).permit(
          :name,
          :person_type,
          :identification,
          :email,
          :phone,
          :address
        )
      end

      def format_errors(errors)
        errors.map do |field, messages|
          {
            field: field,
            message: messages.is_a?(Array) ? messages.join(', ') : messages
          }
        end
      end

      def pagy_metadata(pagy)
        {
          current_page: pagy.page,
          total_pages: pagy.pages,
          total_count: pagy.count,
          per_page: pagy.items
        }
      end
    end
  end
end
