class TenantedSubdomain
  def self.matches?(request)
    subdomain = request.subdomain
    subdomain.present? && subdomain != 'www'
  end
end

Rails.application.routes.draw do
  constraints(TenantedSubdomain) do
    scope module: 'tenanted' do
      root 'posts#index'
      resources :posts
    end
  end

  resources :tenants, except: %[show]
end
