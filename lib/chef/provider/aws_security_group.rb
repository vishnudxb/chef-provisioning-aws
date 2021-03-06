require 'chef/provisioning/aws_driver/aws_provider'
require 'date'
require 'ipaddr'

class Chef::Provider::AwsSecurityGroup < Chef::Provisioning::AWSDriver::AWSProvider

  action :create do
    sg = new_resource.aws_object
    if !sg
      converge_by "Creating new SG #{new_resource.name} in #{region}" do
        options = { description: new_resource.description }
        options[:vpc] = new_resource.vpc if new_resource.vpc
        options = AWSResource.lookup_options(options, resource: new_resource)
        Chef::Log.debug("VPC: #{options[:vpc]}")

        sg = driver.ec2.security_groups.create(new_resource.name, options)
      end
    end

    new_resource.save_managed_entry(sg, action_handler)

    # Update rules
    apply_rules(sg)
  end

  action :delete do
    aws_object = new_resource.aws_object
    if aws_object
      converge_by "Deleting SG #{new_resource.name} in #{region}" do
        aws_object.delete
      end
    end

    new_resource.delete_managed_entry(action_handler)
  end

  # TODO check existing rules and compare / remove?
  def apply_rules(security_group)
    # Incoming
    if new_resource.inbound_rules
      new_resource.inbound_rules.each do |rule|
        begin
          converge_by "Updating SG #{new_resource.name} in #{region} to allow inbound #{rule[:protocol]}/#{rule[:ports]} from #{rule[:sources]}" do
            sources = get_sources(rule[:sources])
            security_group.authorize_ingress(rule[:protocol], rule[:ports], *sources)
          end
        rescue AWS::EC2::Errors::InvalidPermission::Duplicate
          Chef::Log.debug 'Duplicate rule, ignoring.'
        end
      end
    end

    # Outgoing
    if new_resource.outbound_rules
      new_resource.outbound_rules.each do |rule|
        begin
          converge_by "Updating SG #{new_resource.name} in #{region} to allow outbound #{rule[:protocol]}/#{rule[:ports]} to #{rule[:destinations]}" do
            security_group.authorize_egress( *get_sources(rule[:destinations]), :protocol => rule[:protocol], :ports => rule[:ports])
          end
        rescue AWS::EC2::Errors::InvalidPermission::Duplicate
          Chef::Log.debug 'Duplicate rule, ignoring.'
        end
      end
    end
  end

  # TODO need support for load balancers!
  def get_sources(sources)
    sources.map do |s|
      if s.is_a?(String)
        begin
          IPAddr.new(s)
          s
        rescue
          { group_id: Chef::Resource::AwsSecurityGroup.get_aws_object_id(s, resource: new_resource) }
        end
      else
        s
      end
    end
  end

end
