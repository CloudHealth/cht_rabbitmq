# frozen_string_literal: true
#
# Cookbook:: rabbitmq_test
# Recipe:: cluster
#
# Copyright:: 2012-2019, Chef Software, Inc. <legal@chef.io>
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

# 2017, @rmoriz, this is broken and probably never worked
node.override['rabbitmq']['cluster'] = true
include_recipe 'rabbitmq::default'
