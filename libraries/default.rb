# frozen_string_literal: true
#
# Cookbook:: rabbitmq
# Library:: default
# Author:: Jake Davis (<jake@simple.com>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module RabbitMQ
    module CoreHelpers
    def rabbitmq_version
      node['rabbitmq']['version'].to_s
    end

    def rabbitmq_package_download_base_url
      case node['rabbitmq']['package_source'].to_s.downcase
      when :github, /github/i
        "https://github.com/rabbitmq/rabbitmq-server/releases/download/v#{rabbitmq_version}/"
      when :bintray, /bintray/i
        "https://dl.bintray.com/rabbitmq/all/rabbitmq-server/#{rabbitmq_version}/"
      else
        "https://github.com/rabbitmq/rabbitmq-server/releases/download/v#{rabbitmq_version}/"
      end
    end

    def manage_rabbitmq_service?
      node['rabbitmq']['manage_service']
    end

    def service_control_init?
      node['init_package'] == 'init' && node['rabbitmq']['job_control'] == 'init'
    end

    def service_control_upstart?
      node['rabbitmq']['job_control'] == 'upstart'
    end

    def service_control_systemd?
      node['init_package'] == 'systemd' || node['rabbitmq']['job_control'] == 'systemd'
    end

    def installed_rabbitmq_version
      # output a rabbitmq-server version string excluding anything after the "-",
      # e.g. "3.7.13". This strips off development version qualifiers, package
      # revision and so on.
      node['packages']['rabbitmq-server']['version'][/[^-]+/]
    end

    def rabbitmq_config_file_path
      configured_path = node['rabbitmq']['config']

      # If no extension is configured, append it.
      if ::File.extname(configured_path).empty?
        "#{configured_path}.config"
      else
        configured_path
      end
    end

    # This method does some of the yuckiness of formatting parameters properly
    # for rendering into the rabbit.config template.
    def format_kernel_parameters  # rubocop:disable all
      rendered = [] # rubocop:enable all
      kernel = node['rabbitmq']['kernel'].dup

      # This parameter is special and needs commas instead of periods.
      rendered << "{inet_dist_use_interface, {#{kernel[:inet_dist_use_interface].tr('.', ',')}}}" if kernel[:inet_dist_use_interface]
      kernel.delete(:inet_dist_use_interface)

      # Otherwise, we can just render it nicely as Erlang wants. This
      # theoretically opens the door for arbitrary kernel_app parameters to be
      # declared.
      kernel.select { |_k, v| !v.nil? }.each_pair do |param, val|
        rendered << "    {#{param}, #{val}}"
      end

      rendered.join(",\n")
    end

    def format_ssl_versions
      Array(node['rabbitmq']['ssl_versions']).map { |n| "'#{n}'" }.join(',')
    end

    def format_ssl_ciphers
      Array(node['rabbitmq']['ssl_ciphers']).join(',')
    end

    def shell_environment
      { 'HOME' => ENV.fetch('HOME', '/var/lib/rabbitmq') }
    end

    def cluster_name_with_fallback
      explicitly_configured_name = node['rabbitmq']['clustering']['cluster_name']
      return explicitly_configured_name if explicitly_configured_name

      cluster_nodes = node['rabbitmq']['clustering']['cluster_nodes']
      if cluster_nodes.any?
        cluster_nodes.first.name
      else
        'unnamed-rabbitmq-cluster'
      end
    end
  end
end

module Opscode
  module RabbitMQ
    include ::RabbitMQ::CoreHelpers
  end
end
