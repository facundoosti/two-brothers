class Superadmin::ExchangeRatesController < Superadmin::BaseController
  before_action :set_exchange_rate, only: %i[edit update]

  def index
    @exchange_rates = ExchangeRate.order(year: :desc, month: :desc)
    @current_rate   = ExchangeRate.for(Date.today)
    @new_rate       = ExchangeRate.new(year: Date.today.year, month: Date.today.month)
  end

  def create
    @exchange_rates = ExchangeRate.order(year: :desc, month: :desc)
    @new_rate       = ExchangeRate.new(exchange_rate_params)

    if @new_rate.save
      redirect_to superadmin_exchange_rates_path,
                  notice: "Cotización #{@new_rate.month}/#{@new_rate.year} registrada: $#{@new_rate.blue_rate}."
    else
      @current_rate = ExchangeRate.for(Date.today)
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @exchange_rate.update(exchange_rate_params)
      redirect_to superadmin_exchange_rates_path,
                  notice: "Cotización #{@exchange_rate.month}/#{@exchange_rate.year} actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_exchange_rate
    @exchange_rate = ExchangeRate.find(params[:id])
  end

  def exchange_rate_params
    params.require(:exchange_rate).permit(:year, :month, :blue_rate)
  end
end
