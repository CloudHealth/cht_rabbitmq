# frozen_string_literal: true
#
# Cookbook:: rabbitmq
# Provider:: cluster
#
# Author: Sunggun Yu <sunggun.dev@gmail.com>
# Copyright:: (C) 2015 Sunggun Yu
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

include RabbitMQ::CoreHelpers

# Get ShellOut
def get_shellout(cmd)
  sh_cmd = Mixlib::ShellOut.new(cmd, env: shell_environment)
  sh_cmd
end

# Execute rabbitmqctl command with args
def run_rabbitmqctl(*args)
  cmd = "rabbitmqctl #{args.join(' ')}"
  Chef::Log.debug("[rabbitmq_cluster] Executing #{cmd}")
  cmd = get_shellout(cmd)
  cmd.run_command
  begin
    cmd.error!
    Chef::Log.debug("[rabbitmq_cluster] #{cmd.stdout}")
  rescue
    raise("[rabbitmq_cluster] #{cmd.stderr}")
  end
end

# Get cluster status result
def cluster_status
  # Default formatting changed to "table" in 3.8, need to explicity specify
  # "erlang" to parse output properly.
  installed_version = Gem::Version.new(installed_rabbitmq_version)
  version_requiring_formatter = Gem::Version.new('3.8.0')
  cmd = +'rabbitmqctl -q cluster_status'
  cmd << ' --formatter erlang' if installed_version >= version_requiring_formatter
  # execute > rabbitmqctl cluster_status"
  # This removes an optional "... Done" linee that older version used to output
  Chef::Log.debug("[rabbitmq_cluster] Executing #{cmd}")
  cmd = get_shellout(cmd)
  cmd.run_command
  cmd.error!
  result = cmd.stdout.squeeze(' ').gsub(/\n */, '').gsub('...done.', '')
  Chef::Log.debug("[rabbitmq_cluster] #{cmd} : #{result}")
  result
end

# Match regex pattern from result of rabbitmqctl cluster_status
def match_pattern_cluster_status(cluster_status, pattern)
  if cluster_status.nil? || cluster_status.to_s.empty?
    raise('[rabbitmq_cluster] cluster_status should not be empty')
  end
  match = cluster_status.match(pattern)
  match && match[2]
end

# Get currently joined cluster name from result string of "rabbitmqctl cluster_status"
def current_cluster_name(cluster_status)
  pattern = '({cluster_name,<<")(.*?)(">>})'
  result = match_pattern_cluster_status(cluster_status, pattern)
  Chef::Log.debug("[rabbitmq_cluster] current_cluster_name : #{result}")
  result
end

# Get running nodes
def running_nodes(cluster_status)
  pattern = '({running_nodes,\[\'*)(.*?)(\'*\]})'
  match = match_pattern_cluster_status(cluster_status, pattern)
  result = match && match.delete("'")
  Chef::Log.debug("[rabbitmq_cluster] running_nodes : #{result}")
  result.nil? ? [] : result
end

# Get disc nodes
def disc_nodes(cluster_status)
  pattern = '({disc,\[\'*)(.*?)(\'*\]})'
  match = match_pattern_cluster_status(cluster_status, pattern)
  result = match && match.delete("'").split(',')
  Chef::Log.debug("[rabbitmq_cluster] disc_nodes : #{result}")
  result.nil? ? [] : result
end

# Get ram nodes
def ram_nodes(cluster_status)
  pattern = '({ram,\[\'*)(.*?)(\'*\]})'
  match = match_pattern_cluster_status(cluster_status, pattern)
  result = match && match.delete("'").split(',')
  Chef::Log.debug("[rabbitmq_cluster] ram_nodes : #{result}")
  result.nil? ? [] : result
end

# Get node name
def node_name
  # execute > rabbitmqctl eval 'node().'
  cmd = 'rabbitmqctl eval "node()." | head -1'
  Chef::Log.debug("[rabbitmq_cluster] Executing #{cmd}")
  cmd = get_shellout(cmd)
  cmd.run_command
  cmd.error!
  result = cmd.stdout.chomp.delete("'")
  Chef::Log.debug("[rabbitmq_cluster] node name : #{result}")
  result
end

# Get cluster_node_type of current node
def current_cluster_node_type(node_name, cluster_status)
  var_cluster_node_type = ''
  if disc_nodes(cluster_status).include?(node_name)
    var_cluster_node_type = 'disc'
  elsif ram_nodes(cluster_status).include?(node_name)
    var_cluster_node_type = 'ram'
  end
  Chef::Log.debug("[rabbitmq_cluster] current cluster node type : #{var_cluster_node_type}")
  var_cluster_node_type
end

# Parse hash string of cluster_nodes to a JSON object
def parse_cluster_nodes_string(cluster_nodes)
  JSON.parse(cluster_nodes.gsub('=>', ':'))
end

# Check whether the node has joined the cluster
def joined_cluster?(node_name, cluster_status)
  (running_nodes(cluster_status) || '').include?(node_name)
end

# Custom exception for join errors
class JoinError < StandardError
end

# Join cluster.
def join_cluster(cluster_name, type)
  cmd = "rabbitmqctl join_cluster #{type == 'ram' ? '--ram' : ''} #{cluster_name}".squeeze(' ')
  Chef::Log.debug("[rabbitmq_cluster] Executing #{cmd}")
  cmd = get_shellout(cmd)
  cmd.run_command
  begin
    cmd.error!
    Chef::Log.info("[rabbitmq_cluster] #{cmd.stdout}")
  rescue
    err = cmd.stderr
    Chef::Log.warn("[rabbitmq_cluster] #{err}")
    if err.include?('{ok,already_member}')
      Chef::Log.info('[rabbitmq_cluster] Node is already a member of the cluster, error will be ignored.')
    elsif err.include?('cannot_cluster_node_with_itself')
      Chef::Log.info('[rabbitmq_cluster] Cannot cluster node itself, error will be ignored.')
    else
      # Don't fatal here, raise JoinError so that Rabbit can be restarted for the next run
      raise JoinError, err
    end
  end
end

# Change cluster node type
def change_cluster_node_type(cluster_node_type)
  cmd = "rabbitmqctl change_cluster_node_type #{cluster_node_type}"
  Chef::Log.debug("[rabbitmq_cluster] Executing #{cmd}")
  cmd = get_shellout(cmd)
  cmd.run_command
  begin
    cmd.error!
    Chef::Log.debug("[rabbitmq_cluster] #{cmd.stdout}")
  rescue
    err = cmd.stderr
    Chef::Log.warn("[rabbitmq_cluster] #{err}")
    if err.include?('{not_clustered,"Non-clustered nodes can only be disc nodes."}')
      Chef::Log.info('[rabbitmq_cluster] Node is not clustered yet, error will be ignored.')
    else
      raise("[rabbitmq_cluster] #{err}")
    end
  end
end

########################################################################################################################
# Actions
#  :join
#  :set_cluster_name
#  :change_cluster_node_type
########################################################################################################################

# Action for joining cluster
action :join do
  Chef::Log.info('[rabbitmq_cluster] Action join ... ')

  raise('rabbitmq_cluster with action :join requires a non-nil/empty cluster_nodes.') if new_resource.cluster_nodes.nil? || new_resource.cluster_nodes.empty?

  var_cluster_status = cluster_status
  var_node_name = node_name
  var_node_name_to_join = parse_cluster_nodes_string(new_resource.cluster_nodes).first['name']
  var_node_type = parse_cluster_nodes_string(new_resource.cluster_nodes).first['type']
  var_cluster_name = new_resource.cluster_name

  if var_node_name == var_node_name_to_join
    Chef::Log.warn('[rabbitmq_cluster] This node was configured to join itself. Skipping.')
  elsif joined_cluster?(var_node_name, var_cluster_status) && current_cluster_name(var_cluster_status) == var_cluster_name
    Chef::Log.warn("[rabbitmq_cluster] Node is already member of the target cluster #{current_cluster_name(var_cluster_status)}. Skipping.")
  else
    if joined_cluster?(var_node_name, var_cluster_status) && current_cluster_name(var_cluster_status) != var_cluster_name
      unless var_cluster_name.nil?
        Chef::Log.warn("[rabbitmq_cluster] Node is already member of #{current_cluster_name(var_cluster_status)}. Rejoining the desired cluster.")
      end
    end
    run_rabbitmqctl('stop_app')

    # Catch JoinError so that we can leave Rabbit started, if possible
    begin
      join_cluster(var_node_name_to_join, var_node_type)
    rescue JoinError => exc
      raise("[rabbitmq_cluster] #{exc.message}")
    ensure
      run_rabbitmqctl('start_app')
    end

    Chef::Log.info("[rabbitmq_cluster] Node #{var_node_name} joined in #{var_node_name_to_join} with type #{var_node_type}")
    Chef::Log.info(cluster_status)
  end
end

# Action for set cluster name
action :set_cluster_name do
  raise('rabbitmq_cluster with action :set_cluster_name requires a non-nil/empty cluster_nodes.') if new_resource.cluster_nodes.nil? || new_resource.cluster_nodes.empty?
  var_cluster_status = cluster_status
  var_cluster_name = new_resource.cluster_name
  if current_cluster_name(var_cluster_status).nil?
    Chef::Log.warn('[rabbitmq_cluster] Currently not a cluster. Set cluster name will be skipped.')
  else
    unless current_cluster_name(var_cluster_status) == var_cluster_name
      unless var_cluster_name.empty?
        run_rabbitmqctl("set_cluster_name #{var_cluster_name}")
        Chef::Log.info("[rabbitmq_cluster] Cluster name has been set : #{current_cluster_name(cluster_status)}")
      end
    end
  end
end

# Action for changing cluster node type
action :change_cluster_node_type do
  Chef::Log.info('[rabbitmq_cluster] Action change_cluster_node_type ... ')

  raise('rabbitmq_cluster with action :join requires a non-nil/empty cluster_nodes.') if new_resource.cluster_nodes.nil? || new_resource.cluster_nodes.empty?

  var_cluster_status = cluster_status
  var_node_name = node_name
  var_current_cluster_node_type = current_cluster_node_type(var_node_name, var_cluster_status)
  var_cluster_node_type = parse_cluster_nodes_string(new_resource.cluster_nodes).compact.select { |node| node['name'] == var_node_name }.first['type'] # ~FC039

  if var_current_cluster_node_type == var_cluster_node_type
    Chef::Log.warn('[rabbitmq_cluster] Skip changing cluster node type: the node is already of the desired type')
    node_type_changeable = false
  else
    if var_cluster_node_type == 'ram' # rubocop:disable all
      if var_current_cluster_node_type == 'disc' && disc_nodes(var_cluster_status).length < 2
        Chef::Log.warn('[rabbitmq_cluster] At least one disc node is required for rabbitmq cluster. Changing cluster node type will be ignored.')
        node_type_changeable = false
      else
        node_type_changeable = true
      end
    elsif var_cluster_node_type == 'disc'
      node_type_changeable = true
    else
      Chef::Log.warn("[rabbitmq_cluster] Unexpected cluster_note_type #{var_cluster_node_type}. Changing cluster node type will be ignored.")
      node_type_changeable = false
    end
  end

  # Change cluster node type
  if node_type_changeable
    run_rabbitmqctl('stop_app')
    change_cluster_node_type(var_cluster_node_type)
    run_rabbitmqctl('start_app')
    Chef::Log.info("[rabbitmq_cluster] The cluster node type of #{var_node_name} has been changed into #{var_cluster_node_type}")
    Chef::Log.info(cluster_status)
  end
end
