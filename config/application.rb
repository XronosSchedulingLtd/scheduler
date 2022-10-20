require_relative 'boot'

require 'rails/all'

#
#  This really doesn't seem to be the right place to put this
#  but it needs to be included before we specify them as being serializable,
#  and there doesn't seem to be a logical position early enough in the 
#  Rails boot sequence.
#
require_relative '../lib/permission_flags'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Scheduler
  class Application < Rails::Application
    config.load_defaults 5.1
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'London'

    config.active_record.time_zone_aware_types = [:datetime, :time]

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths += %W(#{config.root}/engines/public_api/lib)

    config.active_job.queue_adapter = :delayed_job

    config.before_initialize do
      PublicApi::Engine.instance.initializers.map {|e| e.run Rails.application }
    end

    config.active_record.yaml_column_permitted_classes = [
      Symbol,
      PermissionFlags,
      ShadowPermissionFlags,
      ActiveSupport::HashWithIndifferentAccess
    ]
  end
end
