class ApplicationService
  Result = Data.define(:success, :payload, :error) do
    def success? = success
    def failure? = !success
  end

  def self.call(...)
    new(...).call
  end

  private

  def success(payload = nil)
    Result.new(success: true, payload: payload, error: nil)
  end

  def failure(error)
    Result.new(success: false, payload: nil, error: error)
  end
end
