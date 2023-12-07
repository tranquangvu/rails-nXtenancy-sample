class TenantsController < ApplicationController
  before_action :set_tenant, only: %i[edit update destroy]

  # GET /tenants
  def index
    @tenants = Tenant.all
  end

  # GET /tenants/new
  def new
    @tenant = Tenant.new
  end

  # GET /tenants/1/edit
  def edit; end

  # POST /tenants
  def create
    @tenant = Tenant.new(
      tenant_params.merge(
        dbc_adapter: 'postgresql',
        dbc_encoding: 'unicode',
        dbc_pool: 5
      )
    )
    if @tenant.save
      redirect_to tenants_path, notice: 'Tenant was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tenants/1
  def update
    if @tenant.update(tenant_params)
      redirect_to tenants_path, notice: 'Tenant was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /tenants/1
  def destroy
    @tenant.destroy
    redirect_to tenants_path, notice: 'Tenant was successfully destroyed.', status: :see_other
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tenant
    @tenant = Tenant.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def tenant_params
    params.require(:tenant).permit(
      :subdomain,
      :shard,
      :dbc_host,
      :dbc_port,
      :dbc_username,
      :dbc_password,
      :dbc_database
    )
  end
end
