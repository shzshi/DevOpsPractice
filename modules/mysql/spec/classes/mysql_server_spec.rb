require 'spec_helper'

describe 'mysql::server' do
  on_pe_supported_platforms(PLATFORMS).each do |pe_version,pe_platforms|
    pe_platforms.each do |pe_platform,facts|
      describe "on #{pe_version} #{pe_platform}" do
        let(:facts) { facts }

        context 'with defaults' do
          it { is_expected.to contain_class('mysql::server::install') }
          it { is_expected.to contain_class('mysql::server::config') }
          it { is_expected.to contain_class('mysql::server::service') }
          it { is_expected.to contain_class('mysql::server::root_password') }
          it { is_expected.to contain_class('mysql::server::providers') }
        end

        # make sure that overriding the mysqld settings keeps the defaults for everything else
        context 'with overrides' do
          let(:params) {{ :override_options => { 'mysqld' => { 'socket' => '/var/lib/mysql/mysql.sock' } } }}
          it do
            is_expected.to contain_file('mysql-config-file').with({
              :mode => '0644',
            }).with_content(/basedir/)
          end
        end

        describe 'with multiple instance of an option' do
          let(:params) {{ :override_options => { 'mysqld' => { 'replicate-do-db' => ['base1', 'base2', 'base3'], } }}}
          it do
            is_expected.to contain_file('mysql-config-file').with_content(
              /^replicate-do-db = base1$/
            ).with_content(
              /^replicate-do-db = base2$/
            ).with_content(
              /^replicate-do-db = base3$/
            )
          end
        end

        describe 'an option set to true' do
          let(:params) {
            { :override_options => { 'mysqld' => { 'ssl' => true } }}
          }
          it do
            is_expected.to contain_file('mysql-config-file').with_content(/^\s*ssl\s*(?:$|= true)/m)
          end
        end

        describe 'an option set to false' do
          let(:params) {
            { :override_options => { 'mysqld' => { 'ssl' => false } }}
          }
          it do
            is_expected.to contain_file('mysql-config-file').with_content(/^\s*ssl = false/m)
          end
        end

        context 'with remove_default_accounts set' do
          let (:params) {{ :remove_default_accounts => true }}
          it { is_expected.to contain_class('mysql::server::account_security') }
        end

        describe 'possibility of disabling ssl completely' do
          let(:params) {
            { :override_options => { 'mysqld' => { 'ssl' => true, 'ssl-disable' => true } }}
          }
          it do
            is_expected.to contain_file('mysql-config-file').without_content(/^\s*ssl\s*(?:$|= true)/m)
          end
        end

        context 'mysql::server::install' do
          let(:params) {{ :package_ensure => 'present', :name => 'mysql-server' }}
          it do
            is_expected.to contain_package('mysql-server').with({
            :ensure => :present,
            :name   => 'mysql-server',
          })
          end
        end

        if pe_platform =~ /redhat-7/
          context 'mysql::server::install on RHEL 7' do
            let(:params) {{ :package_ensure => 'present', :name => 'mariadb-server' }}
            it do
              is_expected.to contain_package('mysql-server').with({
              :ensure => :present,
              :name   => 'mariadb-server',
            })
            end
          end
        end

        context 'mysql::server::config' do
          context 'with includedir' do
            let(:params) {{ :includedir => '/etc/my.cnf.d' }}
            it do
              is_expected.to contain_file('/etc/my.cnf.d').with({
                :ensure => :directory,
                :mode   => '0755',
              })
            end

            it do
              is_expected.to contain_file('mysql-config-file').with({
                :mode => '0644',
              })
            end

            it do
              is_expected.to contain_file('mysql-config-file').with_content(/!includedir/)
            end
          end

          context 'without includedir' do
            let(:params) {{ :includedir => '' }}
            it do
              is_expected.not_to contain_file('mysql-config-file').with({
                :ensure => :directory,
                :mode   => '0755',
              })
            end

            it do
              is_expected.to contain_file('mysql-config-file').with({
                :mode => '0644',
              })
            end

            it do
              is_expected.to contain_file('mysql-config-file').without_content(/!includedir/)
            end
          end
        end

        context 'mysql::server::service' do
          context 'with defaults' do
            it { is_expected.to contain_service('mysqld') }
          end

          context 'service_enabled set to false' do
            let(:params) {{ :service_enabled => false }}

            it do
              is_expected.to contain_service('mysqld').with({
                :ensure => :stopped
              })
            end
          end
        end

        context 'mysql::server::root_password' do
          describe 'when defaults' do
            it { is_expected.not_to contain_mysql_user('root@localhost') }
            it { is_expected.not_to contain_file('/root/.my.cnf') }
          end
          describe 'when set' do
            let(:params) {{:root_password => 'SET' }}
            it { is_expected.to contain_mysql_user('root@localhost') }
            it { is_expected.to contain_file('/root/.my.cnf') }
          end

        end

        context 'mysql::server::providers' do
          describe 'with users' do
            let(:params) {{:users => {
              'foo@localhost' => {
                'max_connections_per_hour' => '1',
                'max_queries_per_hour'     => '2',
                'max_updates_per_hour'     => '3',
                'max_user_connections'     => '4',
                'password_hash'            => '*F3A2A51A9B0F2BE2468926B4132313728C250DBF'
              },
              'foo2@localhost' => {}
            }}}
            it { is_expected.to contain_mysql_user('foo@localhost').with(
              :max_connections_per_hour => '1',
              :max_queries_per_hour     => '2',
              :max_updates_per_hour     => '3',
              :max_user_connections     => '4',
              :password_hash            => '*F3A2A51A9B0F2BE2468926B4132313728C250DBF'
            )}
            it { is_expected.to contain_mysql_user('foo2@localhost').with(
              :max_connections_per_hour => nil,
              :max_queries_per_hour     => nil,
              :max_updates_per_hour     => nil,
              :max_user_connections     => nil,
              :password_hash            => ''
            )}
          end

          describe 'with grants' do
            let(:params) {{:grants => {
              'foo@localhost/somedb.*' => {
                'user'       => 'foo@localhost',
                'table'      => 'somedb.*',
                'privileges' => ["SELECT", "UPDATE"],
                'options'    => ["GRANT"],
              },
              'foo2@localhost/*.*' => {
                'user'       => 'foo2@localhost',
                'table'      => '*.*',
                'privileges' => ["SELECT"],
              },
            }}}
            it { is_expected.to contain_mysql_grant('foo@localhost/somedb.*').with(
              :user       => 'foo@localhost',
              :table      => 'somedb.*',
              :privileges => ["SELECT", "UPDATE"],
              :options    => ["GRANT"]
            )}
            it { is_expected.to contain_mysql_grant('foo2@localhost/*.*').with(
              :user       => 'foo2@localhost',
              :table      => '*.*',
              :privileges => ["SELECT"],
              :options    => nil
            )}
          end

          describe 'with databases' do
            let(:params) {{:databases => {
              'somedb' => {
                'charset' => 'latin1',
                'collate' => 'latin1',
              },
              'somedb2' => {}
            }}}
            it { is_expected.to contain_mysql_database('somedb').with(
              :charset => 'latin1',
              :collate => 'latin1'
            )}
            it { is_expected.to contain_mysql_database('somedb2')}
          end
        end
      end
    end
  end
end
