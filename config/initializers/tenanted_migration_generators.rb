module Tenanted
  module Generators
    module Migration
      extend ActiveSupport::Concern

      private

      def configured_migrate_path
        return 'db/tenants_migrate' if options[:database] == 'tenants'
        super
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  if defined?(ActiveRecord::Generators::Base)
    ActiveRecord::Generators::Base.include Tenanted::Generators::Migration
  end
end
