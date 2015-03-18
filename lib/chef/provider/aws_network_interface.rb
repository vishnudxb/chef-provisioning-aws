require 'chef/provisioning/aws_driver/aws_provider'
require 'cheffish'
require 'retryable'

class Chef::Provider::AwsNetworkInterface < Chef::Provisioning::AWSDriver::AWSProvider

  action :create do
    status = current_status
    if status == :deleted || status == :deleting
      Chef::Log.warn "#{new_resource} was associated with network interface #{aws_object.id}, which is now in #{status} state.  Replacing it ..."
      status = nil
    end
    case status
    when nil
      converge_by "Creating new network interface #{new_resource.name} in #{region}" do
        options = {}
        options[:subnet] = new_resource.subnet if new_resource.subnet
        options[:private_ip_address] = new_resource.private_ip_address if new_resource.private_ip_address
        options[:description] = new_resource.description if new_resource.description
        options[:security_groups] = new_resource.security_groups if new_resource.security_groups

        aws_object = driver.ec2.network_interfaces.create(AWSResource.lookup_options(options, resource: new_resource))
        aws_object.tags['Name'] = new_resource.name
      end

      converge_by "Waiting for network interface #{new_resource.name} to become available" do
        wait_for_status :available
      end
    when :error
      raise "Network interface #{new_resource.name} (#{aws_object.volume_id}) is in :error state!"
    end
    aws_object.tags['Name'] = new_resource.name
    new_resource.save_managed_entry(aws_object, action_handler)
  end

  action :attach do
    new_resource.save_managed_entry(aws_object, action_handler)
  end

  action :detach do
    new_resource.save_managed_entry(aws_object, action_handler)
  end

  action :delete do
    new_resource.delete_managed_entry(action_handler)
  end

  private

  def aws_object
    @aws_object ||= new_resource.aws_object
  end

  def current_status
    aws_object ? aws_object.status : nil
  end

  def wait_for_status(status)
    # TODO Retryable logic
  end
end
