require 'chef/provisioning/aws_driver/aws_resource_with_entry'

class Chef::Resource::AwsEbsVolume < Chef::Provisioning::AWSDriver::AWSResourceWithEntry
  aws_sdk_type AWS::EC2::Volume, backcompat_data_bag_name: 'ebs_volumes'

  actions :create, :delete, :nothing
  default_action :create

  attribute :name,    kind_of: String, name_attribute: true

  attribute :availability_zone, kind_of: String
  attribute :size,              kind_of: Integer
  attribute :snapshot,          kind_of: String

  attribute :iops,              kind_of: Integer
  attribute :volume_type,       kind_of: Symbol
  attribute :encrypted,         kind_of: [ TrueClass, FalseClass ]

  attribute :volume_id,         kind_of: String, aws_id_attribute: true, lazy_default: proc {
    name =~ /^vol-[a-f0-9]{8}$/ ? name : nil
  }

  def aws_object
    driver, id = get_driver_and_id
    result = driver.ec2.volumes[id] if id
    result && result.exists? ? result : nil
  end
end
