#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

Rails.application.config.middleware.use OmniAuth::Builder do
  #
  #  We decide which ones to initialize based on what environment
  #  variables are defined.
  #
  #  Which one we actually *use* is controlled by our application
  #  settings.
  #
  if ENV["GOOGLE_CLIENT_ID"] && ENV["GOOGLE_CLIENT_SECRET"]
    provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"]
  end
  if ENV["AZURE_CLIENT_ID"] && ENV["AZURE_CLIENT_SECRET"] && ENV["AZURE_TENANT_ID"]
    provider :azure_activedirectory_v2,
      {
        client_id: ENV['AZURE_CLIENT_ID'],
        client_secret: ENV['AZURE_CLIENT_SECRET'],
        tenant_id: ENV['AZURE_TENANT_ID']
      }
  end
end
