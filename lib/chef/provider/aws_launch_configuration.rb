require 'chef/provisioning/aws_driver/aws_provider'
require 'chef/resource/aws_image'

class Chef::Provider::AwsLaunchConfiguration < Chef::Provisioning::AWSDriver::AWSProvider
  action :create do
    aws_object = new_resource.aws_object
    if aws_object.nil?
      converge_by "Creating new Launch Configuration #{new_resource.name} in #{region}" do
        image = new_resource.image
        image ||= driver.default_ami_for_region(driver.region)
        image = Chef::Resource::AwsImage.get_aws_object_id(image, resource: new_resource)
        instance_type = new_resource.instance_type || driver.default_instance_type
        options = AWSResource.lookup_options(new_resource.options || options, resource: new_resource)
        driver.auto_scaling.launch_configurations.create(
          new_resource.name,
          image,
          instance_type,
          options
        )
      end
    end
  end

  action :delete do
    aws_object = new_resource.aws_object
    if aws_object
      converge_by "Deleting Launch Configuration #{new_resource.name} in #{region}" do
        begin
          aws_object.delete
        rescue AWS::AutoScaling::Errors::ResourceInUse
          sleep 5
          retry
        end
      end
    end
  end

end
