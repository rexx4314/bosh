module Bosh::Director
  module Jobs
    class DeleteDeployment < BaseJob
      include DnsHelper
      include LockHelper

      @queue = :normal

      def self.job_type
        :delete_deployment
      end

      def initialize(deployment_name, options = {})
        @deployment_name = deployment_name
        @force = options['force']
        @keep_snapshots = options['keep_snapshots']
        @cloud = Config.cloud
        @deployment_manager = Api::DeploymentManager.new
      end

      def perform
        logger.info("Deleting: #{@deployment_name}")

        with_deployment_lock(@deployment_name) do
          deployment_model = @deployment_manager.find_by_name(@deployment_name)

          deleter_options = {
            force: @force,
            keep_snapshots_in_the_cloud: @keep_snapshots
          }

          # using_global_networking is always true
          ip_provider = DeploymentPlan::IpProviderV2.new(DeploymentPlan::InMemoryIpRepo.new(logger), DeploymentPlan::VipRepo.new(logger), true, logger)
          skip_drain_decider = DeploymentPlan::AlwaysSkipDrain.new

          instance_deleter = InstanceDeleter.new(ip_provider, skip_drain_decider, deleter_options)

          dns_manager = DnsManager.new(logger)
          deployment_deleter = DeploymentDeleter.new(event_log, logger, dns_manager, Config.max_threads, Config.dns_enabled?)

          vm_deleter = Bosh::Director::VmDeleter.new(@cloud, logger, force: @force)
          deployment_deleter.delete(deployment_model, instance_deleter, vm_deleter)

          "/deployments/#{@deployment_name}"
        end
      end
    end
  end
end
