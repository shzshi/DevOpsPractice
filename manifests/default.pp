Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

class system-update {

  exec { 'yum update':
    command => 'yum update -y',
  }

  $sysPackages = [ "Development Tools" ]
  package { $sysPackages:
    ensure => "installed",
    require => Exec['yum update'],
  }
}

include system-update

include tomcat
class {'apache':}
class {'::mysql::server':
root_password    => "my5qlp@ssw0rd",
override_options => $override_options
}
class {'mysql::client':}
class {'jenkins':}
