require 'fog/aws'

CarrierWave.configure do |config|
  config.fog_provider = 'fog/aws'
  config.fog_credentials = {
    provider:              'AWS',
    aws_access_key_id:     Sofcoop::Application.secrets.aws_access_key_id,
    aws_secret_access_key: Sofcoop::Application.secrets.aws_secret_access_key,
    region:                'us-west-2'
  }
  config.fog_directory   = Sofcoop::Application.secrets.aws_s3_bucket
  config.fog_public      = false
end
