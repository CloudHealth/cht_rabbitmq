# RabbitMQ Chef Cookbook

[![Build Status](https://travis-ci.org/rabbitmq/chef-cookbook.svg?branch=master)](https://travis-ci.org/rabbitmq/chef-cookbook)
[![Cookbook Version](https://img.shields.io/cookbook/v/rabbitmq.svg)](https://supermarket.chef.io/cookbooks/rabbitmq)

This is a cookbook for managing RabbitMQ with Chef.

## Supported Chef Versions

This cookbook targets Chef 13.0 and later.


## Supported RabbitMQ Versions

`5.x` release series targets RabbitMQ `3.8.x` releases.
It can also provision `3.7.x` series (which are [out of general support](https://www.rabbitmq.com/versions.html)),

For any series used, a [supported Erlang version](http://www.rabbitmq.com/which-erlang.html) must be installed.


## Supported Distributions

The cookbook targets and is tested against

 * Ubuntu 16.04 through 20.04
 * Debian 9 and 10
 * RHEL 7 and 8
 * CentOS 7 and 8
 * Fedora 30 or later
 * Amazon Linux 2
 * Scientific Linux 7

Those are the distributions currently used to run tests [with Kitchen](.kitchen.yml).

### Newer Versions

Newer Debian, Ubuntu and RHEL/CentOS 8.x versions should work.

### Older Versions

CentOS 6.x, Ubuntu 14.04 and Debian 8.0 might
work just fine but their support has been discontinued. Some of those distributions
will go out of vendor support in 2019.


## Dependencies

This cookbook depends on the [Erlang cookbook](https://supermarket.chef.io/cookbooks/erlang)
and assumes that the user can configure it to provision a [supported Erlang/OTP version](https://www.rabbitmq.com/which-erlang.html).

Two more recipes are provided by this cookbook:`rabbitmq::erlang_package` and `rabbitmq::esl_erlang_package`.
The latter is an alias to the `erlang::esl` recipe in the Erlang
cookbook.

The former uses [Debian Erlang packages](https://github.com/rabbitmq/erlang-debian-package/) and [zero dependency Erlang RPM package](https://github.com/rabbitmq/erlang-rpm) produced and published by Team RabbitMQ.
Those packages provide the latest patch releases of Erlang/OTP.

Both options are covered below.


## Supported RabbitMQ Versions

`6.x` release series of this cookbook only support RabbitMQ `3.8.x` versions.
A [supported Erlang version](https://www.rabbitmq.com/which-erlang.html) must also be provisioned.

`5.x` release series of this cookbook can provision any recent (`3.7.x`, `3.6.16`) version
if a [supported Erlang version](https://www.rabbitmq.com/which-erlang.html) is also provisioned.

## Provisioning RabbitMQ 3.8.x

### Provision Erlang/OTP 22.3 or Later

Before provisioning a 3.8.x release, please learn about
the [minimum required Erlang/OTP version](https://www.rabbitmq.com/which-erlang.html)
and Erlang/OTP version recommendations.

Most distributions provide older versions, so Erlang must be provisioned either
using [RabbitMQ's zero dependency Erlang RPM](https://github.com/rabbitmq/erlang-rpm),
[Debian Erlang packages](https://github.com/rabbitmq/erlang-debian-package/),
or from [Erlang Solutions](https://packages.erlang-solutions.com/erlang/)

#### Installing Erlang Using Packages by Team RabbitMQ

`rabbitmq::erlang_package` is a recipe that provisions latest Erlang packages from team RabbitMQ.
The packages support

 * Debian 9 and 10
 * Ubuntu 16.04 through 20.04
 * RHEL 7 and 8
 * CentOS 7 and 8
 * Fedora 30 or later
 * Scientific Linux 7
 * Amazon Linux 2

The packages are **cannot be installed alongside with other Erlang packages**, for example, those
from standard Debian repositories or Erlang Solutions.

To make sure that the Erlang cookbook is not used by `rabbitmq::default`, `rabbitmq::cluster`,
and other recipes, set `node['rabbitmq']['erlang']['enabled']` to `true`:

``` ruby
node['rabbitmq']['erlang']['enabled'] = true
```

By default `rabbitmq::erlang_package` will install the latest Erlang version available.
To override package version, use `node['rabbitmq']['erlang']['version']`:

``` ruby
# Debian
node['rabbitmq']['erlang']['version'] = '1:23.0.3-1'

# RPM
node['rabbitmq']['erlang']['version'] = '23.0.3'
```

On Ubuntu and Debian the distribution will be picked from node attributes.
It is possible to override the component used (see [Ubuntu and Debian installation guide](https://www.rabbitmq.com/install-debian.html)
to learn more):

``` ruby
# provisions Erlang 23.x
node['rabbitmq']['erlang']['apt']['components'] = ["erlang-23.x"]
```

``` ruby
# provisions Erlang 22.3.x
node['rabbitmq']['erlang']['apt']['components'] = ["erlang-22.x"]
```

Most of the time there is no need to override other attributes. Below is a list of defaults
used on Ubuntu and Debian:

``` ruby
# RabbitMQ Erlang packages
default['rabbitmq']['erlang']['apt']['uri'] = "https://dl.bintray.com/rabbitmq-erlang/debian"
default['rabbitmq']['erlang']['apt']['lsb_codename'] = node['lsb']['codename']
default['rabbitmq']['erlang']['apt']['components'] = ["erlang"]
default['rabbitmq']['erlang']['apt']['key'] = "6B73A36E6026DFCA"

default['rabbitmq']['erlang']['apt']['install_options'] = %w(--fix-missing)
```

On CentOS 8 and 7, base Yum repository URL will be picked based on distribution versions.
On Fedora, a suitable CentOS package will be used. Erlang package version is set the same way
as for Debian (see above).

Below are the defaults used by the Yum repository (assuming RHEL or CentOS 8):

``` ruby
# Provisions CentOS 8 RPMs of Erlang 23
default['rabbitmq']['erlang']['yum']['baseurl'] = 'https://dl.bintray.com/rabbitmq-erlang/rpm/erlang/23/el/8'
default['rabbitmq']['erlang']['yum']['gpgkey'] = 'https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc'
default['rabbitmq']['erlang']['yum']['gpgcheck'] = true
default['rabbitmq']['erlang']['yum']['repo_gpgcheck'] = false
```

To provision Erlang `22.x`, change `default['rabbitmq']['erlang']['yum']['baseurl']`:

``` ruby
# Provisions CentOS 8 RPMs of Erlang 22
default['rabbitmq']['erlang']['yum']['baseurl'] = 'https://dl.bintray.com/rabbitmq-erlang/rpm/erlang/22/el/8'
```

To provision Erlang `22.x` on CentOS 7:

``` ruby
default['rabbitmq']['erlang']['yum']['baseurl'] = 'https://dl.bintray.com/rabbitmq-erlang/rpm/erlang/22/el/7'
```

#### Installing Erlang with the Erlang Cookbook

The Erlang cookbook will provision [packages from Erlang Solutions](https://www.erlang-solutions.com/resources/download.html)
if `node['erlang']['install_method']` is set to `esl`.
Note that Erlang Solutions repositories can be behind the latest Erlang/OTP patch releases.

``` ruby
# will install the latest release, please
# consult with https://www.rabbitmq.com/which-erlang.html first
node['erlang']['install_method'] = "esl"
```

to provision a specific version, e.g. `22.3.4.10.4`:

``` ruby
node['erlang']['install_method'] = "esl"
# Ubuntu and Debian
# note the "1:" package epoch prefix
node['erlang']['esl']['version'] = "1:22.3.4.10.4"
```

``` ruby
node['erlang']['install_method'] = "esl"
# CentOS, RHEL, Fedora
node['erlang']['esl']['version'] = "22.3.4.10.4-1"
```

### Seting RabbitMQ Version

Set `node['rabbitmq']['version']` to specify a version:

``` ruby
node['rabbitmq']['version'] = "3.8.8"
```

If you have `node['rabbitmq']['deb_package_url']` or `node['rabbitmq']['rpm_package_url']` overridden
from earlier versions, consider omitting those attributes. Otherwise see a section on download
location customization below.

RabbitMQ packages will be downloaded [from Bintray](https://bintray.com/rabbitmq/all/) by default.


## Supported Distributions

The release was tested with recent RabbitMQ releases on

 * Ubuntu 18.04
 * Ubuntu 16.04
 * Debian Stretch and Buster
 * Ubuntu 16.04 through 20.04
 * RHEL 7 and 8
 * CentOS 7 and 8
 * Fedora 30 or later
 * Scientific Linux 7
 * Amazon Linux 2

The packages are **cannot be installed alongside with other Erlang packages**, for example, those
from standard Debian repositories or Erlang Solutions.

To make sure that the Erlang cookbook is not used by `rabbitmq::default`, `rabbitmq::cluster`,
and other recipes, set `node['rabbitmq']['erlang']['enabled']` to `true`:

``` ruby
node['rabbitmq']['erlang']['enabled'] = true
```

By default `rabbitmq::erlang_package` will install the latest Erlang version available.
To override package version, use `node['rabbitmq']['erlang']['version']`:

``` ruby
# Debian
node['rabbitmq']['erlang']['version'] = '1:22.3.4.10.4-1'

# RPM
node['rabbitmq']['erlang']['version'] = '22.3.4.10.4'
```

On Ubuntu and Debian the distribution will be picked from node attributes.
It is possible to override the component used (see [Ubuntu and Debian installation guide](https://www.rabbitmq.com/install-debian.html) to learn more):

``` ruby
# provisions Erlang 22.x
node['rabbitmq']['erlang']['apt']['components'] = ["erlang-22.x"]
```

Most of the time there is no need to override other attributes. Below is a list of defaults
used on Ubuntu and Debian:

``` ruby
# RabbitMQ Erlang packages
default['rabbitmq']['erlang']['apt']['uri'] = "https://dl.bintray.com/rabbitmq-erlang/debian"
default['rabbitmq']['erlang']['apt']['lsb_codename'] = node['lsb']['codename']
default['rabbitmq']['erlang']['apt']['components'] = ["erlang"]
default['rabbitmq']['erlang']['apt']['key'] = "6B73A36E6026DFCA"

default['rabbitmq']['erlang']['apt']['install_options'] = %w(--fix-missing)
```

On CentOS 8 and 7, base Yum repository URL will be picked based on distribution versions.
On Fedora, a suitable CentOS package will be used. Erlang package version is set the same way
as for Debian (see above).

Below are the defaults used by the Yum repository (assuming RHEL or CentOS 7):

``` ruby
default['rabbitmq']['erlang']['yum']['baseurl'] = 'https://dl.bintray.com/rabbitmq-erlang/rpm/erlang/22/el/7'
default['rabbitmq']['erlang']['yum']['gpgkey'] = 'https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc'
default['rabbitmq']['erlang']['yum']['gpgcheck'] = true
default['rabbitmq']['erlang']['yum']['repo_gpgcheck'] = false
```

To provision Erlang `22.x` on CentOS 6:

``` ruby
default['rabbitmq']['erlang']['yum']['baseurl'] = 'https://dl.bintray.com/rabbitmq-erlang/rpm/erlang/22/el/6'
```

#### Installing Erlang with the Erlang Cookbook

The Erlang cookbook will provision packages from Erlang Solutions if `node['erlang']['install_method']` is set to `esl`:

``` ruby
# will install the latest release, please
# consult with https://www.rabbitmq.com/which-erlang.html first
node['erlang']['install_method'] = "esl"
```

to provision a specific version, e.g. `22.3.4.10.4`:

``` ruby
node['erlang']['install_method'] = "esl"
# Ubuntu and Debian
# note the "1:" package epoch prefix
node['erlang']['esl']['version'] = "1:22.3.4.10.4"
```

``` ruby
node['erlang']['install_method'] = "esl"
# CentOS, RHEL, Fedora
node['erlang']['esl']['version'] = "22.3.4.10.4-1"
```

### Seting RabbitMQ Version

Newer Debian, Ubuntu and CentOS 7.x versions should work.

### Older Versions

CentOS 6.x, Ubuntu 14.04 and Debian 8.0 might
work just fine but their support has been discontinued. Some of those distributions
will go out of vendor support in 2019.


## Recipes

### default

Installs `rabbitmq-server` via direct download (from Bintray or GitHub, depending on the version) of
the installation package or using the distribution version. Depending on your distribution,
the provided version may be quite old so direct download is the default option.

#### Clustering Essentials

Set the `['rabbitmq']['clustering']['enable']` attribute to `true`, `['rabbitmq']['clustering']['cluster_disk_nodes']`
array of `node@host` strings that describe cluster members,
and a alphanumeric string for the [`erlang_cookie`](https://www.rabbitmq.com/clustering.html#erlang-cookie).

#### TLS

To enable [TLS for client connections](https://www.rabbitmq.com/ssl.html), set the `ssl` to `true` and set the paths to your cacert, cert and key files.

``` ruby
node['rabbitmq']['ssl'] = true
# path to the CA bundle file
node['rabbitmq']['ssl_cacert'] = '/path/to/cacert.pem'
# path to the server certificate (pubic key) PEM file
node['rabbitmq']['ssl_cert'] = '/path/to/cert.pem'
# path to the server private key file
node['rabbitmq']['ssl_key'] = '/path/to/key.pem'
```

#### Client Connection Listeners

[TCP connection listeners](https://rabbitmq.com/networking.html) may be limited to a specific interface
using the `node['rabbitmq']['tcp_listen_interface']` attribute.

Its [TLS connection listener](https://rabbitmq.com/networking.html) counterpart is `node['rabbitmq']['ssl_listen_interface']`.


#### Custom Package Download Locations

`node['rabbitmq']['deb_package_url']` and `node['rabbitmq']['rpm_package_url']` can be used
to override the package download location. They configure a prefix without a version.
Set them to a download location without a version if you want to provision from a custom
endpoint such as a local mirror.

The `default` recipe will append a version suffix that matches RabbitMQ tag naming scheme.
For `3.7.x` or later, it is just the version (the value is used as is).

Lastly, a package name will be appended to form a full download URL. They rarely need
changing but can also be overridden using the `node['rabbitmq']['deb_package']`
and `node['rabbitmq']['rpm_package']` attributes.


#### Attributes

A full list of attributes related to [TLS in RabbitMQ](https://www.rabbitmq.com/ssl.html)
can be found in [attributes/default.rb](attributes/default.rb).

Default values and usage information of important attributes are shown below.  More attributes are documented in metadata.rb.

##### Username and Password

The default username and password are `guest`/`guest`, with [access limited to localhost connections](https://www.rabbitmq.com/access-control.html#loopback-users):

``` ruby
['rabbitmq']['default_user'] = 'guest'
['rabbitmq']['default_pass'] = 'guest'
```

It is [highly recommended](https://www.rabbitmq.com/production-checklist.html#users-and-permissions) that a different
default user name is used with a reasonably long (say, 30-40 characters) **generated password**.

##### Loopback Users

By default, the guest user [can only connect from localhost](https://www.rabbitmq.com/access-control.html#loopback-users).
This prevents remote access for installations that use the well-known default credentials.
It is [highly recommended](https://www.rabbitmq.com/production-checklist.html#users-and-permissions) that remote access for the default user is not enabled
but if **security is of absolutely no importance** in a certain environment, this can be done:

``` ruby
['rabbitmq']['loopback_users'] = []
```

Learn more in the RabbitMQ [Access Control guide](https://www.rabbitmq.com/access-control.html).

##### Definitions Import

It is possible to to load a [definitions (schema) file](https://www.rabbitmq.com/definitions.html) on node boot.
Consult RabbitMQ's [Definitions](https://www.rabbitmq.com/definitions.html)
and [Backup](https://www.rabbitmq.com/backup.html) doc guides to learn more.

To configure definition loading, set the following attribute:

`['rabbitmq']['management']['load_definitions'] = true`

By default, the node will be configured to load a JSON at `/etc/rabbitmq/load_definitions.json`;
however, you can define another path if you'd prefer using the following attribute:

`['rabbitmq']['management']['definitions_file'] = '/path/to/your/definitions.json'`

In order to use this functionality, you will need to provision a file referenced by the above attribute
before you execute any recipes in the RabbitMQ cookbook (in other words, before the node starts). For example, this can be done
using a remote file resource.

### management_ui

Installs the [RabbitMQ management plugin]().

To enable HTTPS for the management UI and HTTP API, set `['rabbitmq']['web_console_ssl']` attribute to `true`.
The HTTPS port for the management UI can be configured by setting attribute `['rabbitmq']['web_console_ssl_port']`,
whose default value is 15671.

### plugins

Enables any plugins listed in the `node['rabbitmq']['enabled_plugins']` and disables any listed
in `node['rabbitmq']['disabled_plugins']` attributes.

### LDAP Configuration

To enable the [LDAP plugin](https://www.rabbitmq.com/ldap.html), a few attributes have to be used
in combination:

1. Set `node['rabbitmq']['ldap']['enabled'] = true`
2. Enable `auth_backends`: `node['rabbitmq']['auth_backends'] = 'rabbit_auth_backend_internal,rabbit_auth_backend_ldap'`
3. Enable the `rabbitmq_auth_backend_ldap` plugin
4. Configure LDAP servers and queries via the `node['rabbitmq']['ldap']['conf']` variable

##### Example configuration

``` ruby

# this is just an example
node['rabbitmq']['ldap']['conf'] = {
  :servers => ["ldap-host1", "ldap-host2"],
  :user_bind_pattern => "${username}@<domain>",
  :dn_lookup_attribute => "sAMAccountName",
  :dn_lookup_base => "DC=<CHANGEME>,DC=<CHANGEME>",
  :port => <CHANGEME (number)>,
  :log => <CHANGEME (boolean)>,
  :vhost_access_query => '{constant, true}',
  :topic_access_query => '{constant, true}',
  :resource_access_query => '{constant, true}',
  :tag_queries => "[{administrator, {constant, false}}]"
  }
```

### Auth Backend Cache

To enable the [RabbitMQ access control cache plugin](https://github.com/rabbitmq/rabbitmq-auth-backend-cache), a few
steps have to be taken:

1. Set `node['rabbitmq']['auth']['cache']['enabled'] = true`
2. Enable `auth_backends`: `node['rabbitmq']['auth_backends'] = 'rabbit_auth_backend_internal,rabbit_auth_backend_cache'`
3. Enable the `rabbitmq_auth_backend_cache` plugin
4. Configure auth backend to cache via the `node['rabbitmq']['auth']['cache']['conf']` attribute

##### Example Configuration

```ruby
node['rabbitmq']['auth']['cache']['conf'] = {
  :cached_backend => 'rabbit_auth_backend_ldap',
  :cache_ttl => 300000
}
```
You can see more examples [here](https://github.com/rabbitmq/rabbitmq-auth-backend-cache)

### users

Enables any [RabbitMQ users](https://www.rabbitmq.com/access-control.html) listed in the `node['rabbitmq']['enabled_users']` and disables any listed in `node['rabbitmq']['disabled_users']` attributes.
You can provide user credentials, the vhosts that they need to have access to and the permissions that should be allocated to each user.

``` ruby
node['rabbitmq']['enabled_users'] = [
    {
        name: 'kitten',
        password: 'kitten',
        tag: 'leader',
        rights => [
            {
                vhost: 'nova',
                conf: '.*',
                write: '.*',
                read: '.*'
            }
        ]
    }
]
```

Note that with this approach user credentials will be stored in the attribute file.
Using encrypted data bags is therefore highly recommended.

Alternatively [definitions export and import](https://www.rabbitmq.com/management.html#load-definitions) (see above) can be used.
Definition files contain password hashes since clear text values are not stored.

### vhosts

Enables any [virtual hosts](https://www.rabbitmq.com/vhosts.html) listed in the `node['rabbitmq']['virtualhosts']`
and disables any listed in `node['rabbitmq']['disabled_virtualhosts']` attributes.

### cluster

Forms a [cluster RabbitMQ of nodes](https://www.rabbitmq.com/clustering.html).

It supports two clustering modes: auto or manual.

* Auto clustering: lists [cluster members in the RabbitMQ config file](https://www.rabbitmq.com/cluster-formation.html#peer-discovery-classic-config). Those are taken from lists the nodes `node['rabbitmq']['clustering']['cluster_nodes']`.
* Manual clustering : joins cluter members using `rabbitmqctl join_cluster`.

#### Attributes

* `node['rabbitmq']['clustering']['enable']` : Default decision flag of clustering
* `node['rabbitmq']['erlang_cookie']` : Same erlang cookie is required for the cluster
* `node['rabbitmq']['clustering']['use_auto_clustering']` : Default is false. (manual clustering is default)
* `node['rabbitmq']['clustering']['cluster_name']` : Name of cluster. default value is nil. In case of nil or '' is set for `cluster_name`, first node name in `node['rabbitmq']['clustering']['cluster_nodes']` attribute will be set for manual clustering. for the auto clustering, one of the node name will be set.
* `node['rabbitmq']['clustering']['cluster_nodes']`  List of cluster nodes. it required node name and cluster node type. please refer to example in below.

Example

``` ruby
node['rabbitmq']['clustering']['enable'] = true
node['rabbitmq']['erlang_cookie'] = 'AnyAlphaNumericStringWillDo'
node['rabbitmq']['clustering']['cluster_partition_handling'] = 'pause_minority'
node['rabbitmq']['clustering']['use_auto_clustering'] = false
node['rabbitmq']['clustering']['cluster_name'] = 'qa_env'
node['rabbitmq']['clustering']['cluster_nodes'] = [
    {
        :name: 'rabbit@rabbit1'
    },
    {
        name: 'rabbit@rabbit2'
    },
    {
        name: 'rabbit@rabbit3'
    }
]
```

### policies

Enables any policies listed in the `node['rabbitmq']['policies']` and disables any listed in `node['rabbitmq']['disabled_policies']` attributes.

See examples in attributes file.

### community_plugins

Downloads, installs and enables pre-built community plugins binaries.

To specify a plugin, set the attribute `node['rabbitmq']['community_plugins']['PLUGIN_NAME']` to `'{DOWNLOAD_URL}'`.


## Available Resources/Providers

There are several LWRPs for interacting with RabbitMQ and a few setting up Erlang repositories
and package.

## erlang_apt_repository_on_bintray

`erlang_apt_repository_on_bintray` sets up a [Debian package](https://www.rabbitmq.com/install-debian.html) repository [from Bintray](https://bintray.com/rabbitmq-erlang).
It is a wrapper around the standard `apt_repository` resource provider.

See also [RabbitMQ Erlang Compatibility guide](https://www.rabbitmq.com/which-erlang.html).

``` ruby
rabbitmq_erlang_apt_repository_on_bintray 'rabbitmq_erlang_repo_on_bintray' do
  distribution node['lsb']['codename'] unless node['lsb'].nil?
  # See https://www.rabbitmq.com/install-debian.html
  components ['erlang-21.x']

  action :add
end
```

## erlang_yum_repository_on_bintray

`erlang_apt_repository_on_bintray` sets up an [RPM package](https://www.rabbitmq.com/install-rpm.html) repository [from Bintray](https://bintray.com/rabbitmq-erlang).
It is a wrapper around the standard `apt_repository` resource provider.

See also [RabbitMQ Erlang Compatibility guide](https://www.rabbitmq.com/which-erlang.html).

``` ruby
rabbitmq_erlang_yum_repository_on_bintray 'rabbitmq_erlang' do
  # for RHEL/CentOS 7+, Fedora. See https://www.rabbitmq.com/install-rpm.html.
  baseurl 'https://dl.bintray.com/rabbitmq/rpm/rabbitmq-server/v3.7.x/el/7/'
  gpgkey 'https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc'

  action :add
end
```

## erlang_package_from_bintray

Install the package. Here's an example for Debian-based systems:

``` ruby
rabbitmq_erlang_package_from_bintray 'rabbitmq_erlang' do
  # This package version assumes a Debian-based distribution.
  version '1:23.0.3-1'

  action :install
end
```

Here's another one for RPM-based ones:

``` ruby
rabbitmq_erlang_package_from_bintray 'rabbitmq_erlang' do
  version '23.0.3'

  action :install
end
```

## plugin

Enables or disables a rabbitmq plugin. Plugins are not supported for releases prior to 2.7.0.

- `:enable` enables a `plugin`
- `:disable` disables a `plugin`

### Examples

``` ruby
rabbitmq_plugin "rabbitmq_stomp" do
  action :enable
end
```

``` ruby
rabbitmq_plugin "rabbitmq_shovel" do
  action :disable
end
```

## policy

Sets or clears a RabbitMQ [policy](https://www.rabbitmq.com/parameters.html#policies).

- `:set` sets a `policy`
- `:clear` clears a `policy`
- `:list` lists `policy`s

### Examples

``` ruby

rabbitmq_policy "classic-queue-mirroring-2-replicas" do
  pattern "^(?!amq\\.).*"
  parameters ({"ha-mode" => "exactly", "ha-params" => 2})
  priority 1
  action :set
end
```

``` ruby
rabbitmq_policy "queue-length-limit" do
  pattern "^limited\\.*"
  parameters ({"max-length" => "exactly"})
  priority 1
  action :set
end
```

``` ruby
rabbitmq_policy "classic-queue-mirroring-2-replicas" do
  action :clear
end
```

## user

Adds and deletes [users](https://www.rabbitmq.com/access-control.html):

- `:add` adds a `user` with a `password`
- `:delete` deletes a `user`
- `:set_permissions` sets the `permissions` for a `user`, `vhost` is optional
- `:clear_permissions` clears the permissions for a `user`
- `:set_tags` set the tags on a user
- `:clear_tags` clear any tags on a user
- `:change_password` set the `password` for a `user`

### Examples

``` ruby
rabbitmq_user "guest" do
  action :delete
end
```

``` ruby
rabbitmq_user "nova" do
  password "sekret"
  action :add
end
```

``` ruby
rabbitmq_user "nova" do
  vhost "/nova"
  permissions ".* .* .*"
  action :set_permissions
end
```

``` ruby
rabbitmq_user "rmq" do
  vhost ["/", "/rmq", "/nova"]
  permissions ".* .* .*"
  action :set_permissions
end
```

``` ruby
rabbitmq_user "joe" do
  tag "admin,lead"
  action :set_tags
end
```

## vhost

Adds and deletes [virtual hosts](https://www.rabbitmq.com/vhosts.html).

- `:add` adds a `vhost`
- `:delete` deletes a `vhost`

### Examples

``` ruby
rabbitmq_vhost "/nova" do
  action :add
end
```

## cluster

[Forms a cluster](https://www.rabbitmq.com/clustering.html) and controls cluster name.

- `:join` join in cluster as a manual clustering. node will join in first node of json string data.

 - cluster nodes data json format : Data should have all the cluster nodes information.

 ```
 [
     {
         "name" : "rabbit@rabbit1",
         "type" : "disc"
     },
     {
         "name" : "rabbit@rabbit2",
         "type" : "ram"
     },
     {
         "name" "rabbit@rabbit3",
         "type" : "disc"
     }
]
 ```

- `:set_cluster_name` set the cluster name.
- `:change_cluster_node_type` change cluster type of node. `disc` or `ram` should be set.

### Examples

``` ruby
rabbitmq_cluster '[{"name":"rabbit@rabbit1","type":"disc"},{"name":"rabbit@rabbit2","type":"ram"},{"name":"rabbit@rabbit3","type":"disc"}]' do
  action :join
end
```

``` ruby
rabbitmq_cluster '[{"name":"rabbit@rabbit1","type":"disc"},{"name":"rabbit@rabbit2","type":"ram"},{"name":"rabbit@rabbit3","type":"disc"}]' do
  cluster_name 'seoul_tokyo_newyork'
  action :set_cluster_name
end
```

``` ruby
rabbitmq_cluster '[{"name":"rabbit@rabbit1","type":"disc"},{"name":"rabbit@rabbit2","type":"ram"},{"name":"rabbit@rabbit3","type":"disc"}]' do
  action :change_cluster_node_type
end
```

### Removing Nodes from an Existing Cluster

This cookbook provides the primitives to remove a node from a cluster via helper functions but do not include these in any recipes. This is something that is potentially very dangerous and different deployments will have different needs and IF you decide you need this it should be implemented in your wrapper with EXTREME caution. There are 2 helper methods for 2 different scenario:
- removing self from cluster. This should likely only be considered for machines on a normal decommission. This is accomplished by using the helper fucntion `reset_current_node`.
- removing another node from cluster. This should only be done once you are sure the machine is gone and won't come back. This can be accomplished via `remove_remote_node_from_cluster`.


## Limitations

For an already running cluster, these actions still require manual intervention:

- changing the [shared cluster secret](https://www.rabbitmq.com/clustering.html#erlang-cookie) using the `:erlang_cookie` attribute
- disabling clutering entirely by setting `:cluster` from `true` to `false`


## License & Authors

- Author:: Benjamin Black
- Author:: Daniel DeLeo
- Author:: Matt Ray
- Author:: Seth Thomas
- Author:: JJ Asghar
- Author:: Team RabbitMQ

```text
Copyright (c) 2009-2018, Chef Software, Inc.
Copyright (c) 2018-2020, VMware, Inc. or its affiliates.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
