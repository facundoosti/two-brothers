class Superadmin::TenantsController < Superadmin::BaseController
  before_action :set_tenant, only: %i[edit update destroy]

  def index
    @tenants = Tenant.order(:name)
  end

  def new
    @tenant = Tenant.new
  end

  def create
    @tenant = Tenant.new(tenant_params)

    if @tenant.save
      Apartment::Tenant.create(@tenant.subdomain)
      TenantSeeder.call(@tenant.subdomain, name: @tenant.name)
      redirect_to superadmin_tenants_path,
                  notice: "Empresa '#{@tenant.name}' creada. Subdominio: #{@tenant.subdomain}.two-brothers.shop"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @tenant.update(tenant_params)
      redirect_to superadmin_tenants_path,
                  notice: "Empresa '#{@tenant.name}' actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Apartment::Tenant.drop(@tenant.subdomain)
    @tenant.destroy
    redirect_to superadmin_tenants_path,
                notice: "Empresa '#{@tenant.name}' eliminada permanentemente."
  end

  private

  def set_tenant
    @tenant = Tenant.find(params[:id])
  end

  def tenant_params
    params.require(:tenant).permit(:name, :subdomain, :active)
  end
end
