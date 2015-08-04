module Bosh
  module Director
    module Api
      class CloudConfigManager
        def update(cloud_config_yaml)
          cloud_config = Bosh::Director::Models::CloudConfig.new(
            properties: cloud_config_yaml
          )
          validate_manifest!(cloud_config)
          cloud_config.save
        end

        def list(limit)
          Bosh::Director::Models::CloudConfig.order(Sequel.desc(:id)).limit(limit).to_a
        end

        def latest
          list(1).first
        end

        private

        def validate_manifest!(cloud_config)
          # FIXME: we really just need to validate the manifest, we don't care about the subnets being able to reserve IPs here
          ip_provider_factory = Bosh::Director::DeploymentPlan::NullIpProviderFactory.new
          global_network_resolver = Bosh::Director::DeploymentPlan::NullGlobalNetworkResolver.new

          parser = Bosh::Director::DeploymentPlan::CloudManifestParser.new(Config.logger)
          _ = parser.parse(cloud_config.manifest, ip_provider_factory, global_network_resolver) # valid if this doesn't blow up
        end
      end
    end
  end
end
