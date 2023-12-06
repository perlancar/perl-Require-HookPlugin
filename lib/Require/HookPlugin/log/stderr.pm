## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin::log::stderr;

# IFUNBUILT
use strict;
use warnings;
# END IFUNBUILT

# AUTHORITY
# DATE
# DIST
# VERSION

sub meta {
    return {
        args => {},
    };
}

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub before_get_src {
    my ($self, $r) = @_;

    my $elapsed = time() - $^T;
    warn "[time +${elapsed}s] Require::HookPlugin::log::stderr: Require-ing ".$r->filename.
        " (called from package ".$r->caller->[0]." file ".$r->caller->[1].": ".$r->caller->[2].") ...\n";
    [200];
}

1;
# ABSTRACT: Log a message to STDERR

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Require::HookPlugin 'log::stderr';
 # now each time we require(), a message is printed to STDERR

A demo (L<nauniq> is a Perl script you can get from CPAN):

 % PERL5OPT="-MRequire::HookPlugin=-log::stderr" nauniq ~/samples/1.csv
 Require::HookPlugin::log::stderr: Require-ing strict.pm (called from package main file /home/u1/perl5/perlbrew/perls/perl-5.34.0/bin/nauniq:4) ...
 Require::HookPlugin::log::stderr: Require-ing warnings.pm (called from package main file /home/u1/perl5/perlbrew/perls/perl-5.34.0/bin/nauniq:5) ...
 Require::HookPlugin::log::stderr: Require-ing App/nauniq.pm (called from package main file /home/u1/perl5/perlbrew/perls/perl-5.34.0/bin/nauniq:7) ...
 Require::HookPlugin::log::stderr: Require-ing Getopt/Long.pm (called from package main file /home/u1/perl5/perlbrew/perls/perl-5.34.0/bin/nauniq:8) ...
 Require::HookPlugin::log::stderr: Require-ing vars.pm (called from package Getopt::Long file /loader/0x559d7b7578b0/Getopt/Long.pm:20) ...
 Require::HookPlugin::log::stderr: Require-ing warnings/register.pm (called from package vars file /loader/0x559d7b7578b0/vars.pm:7) ...
 Require::HookPlugin::log::stderr: Require-ing constant.pm (called from package Getopt::Long file /loader/0x559d7b7578b0/Getopt/Long.pm:220) ...
 Require::HookPlugin::log::stderr: Require-ing overload.pm (called from package Getopt::Long::CallBack file /loader/0x559d7b7578b0/Getopt/Long.pm:1574) ...
 Require::HookPlugin::log::stderr: Require-ing overloading.pm (called from package overload file /loader/0x559d7b7578b0/overload.pm:84) ...
 Require::HookPlugin::log::stderr: Require-ing Exporter/Heavy.pm (called from package Exporter file /home/u1/perl5/perlbrew/perls/perl-5.34.0/lib/5.34.0/Exporter.pm:13) ...
 ...


=head1 DESCRIPTION


=head1 SEE ALSO

Alternatives: L<Require::HookPlugin::log::logger>

L<Require::HookPlugin>
