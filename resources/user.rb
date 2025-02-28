# frozen_string_literal: true
#
# Cookbook:: rabbitmq
# Resource:: user
#
# Copyright:: 2011-2013, Chef Software, Inc.
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

actions :add, :delete, :set_permissions, :clear_permissions, :set_tags, :clear_tags, :change_password

default_action :add

attribute :user, kind_of: String, name_attribute: true
attribute :password, kind_of: String
attribute :vhost, kind_of: [String, Array]
attribute :permissions, kind_of: String
attribute :tag, kind_of: String
