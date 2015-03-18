require 'chef/provisioning/aws_driver/aws_resource'

class Chef::Resource::AwsNetworkInterface < Chef::Provisioning::AWSDriver::AWSResource
  aws_sdk_type AWS::EC2::NetworkInterface, load_provider: false, id: :id

  actions :create, :delete, :nothing
  default_action :create

  attribute :name, kind_of: String, name_attribute: true

  attribute :network_interface_id, kind_of: String, aws_id_attribute: true, lazy_default: proc {
    name =~ /^eni-[a-f0-9]{8}$/ ? name : nil
  }

  attribute :subnet, kind_of: String

  attribute :private_ip_address, kind_of: String

  attribute :description, kind_of: String

  attribute :security_groups, kind_of: [Array, String]

  def aws_object
    result = driver.ec2.network_interfaces[network_interface_id]
    result && result.exists? ? result : nil
  end
end
