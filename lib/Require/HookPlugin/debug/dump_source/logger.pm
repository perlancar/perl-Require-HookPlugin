## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin::debug::dump_source::logger;

# IFUNBUILT
use strict;
use warnings;
# END IFUNBUILT
use Log::ger;

# AUTHORITY
# DATE
# DIST
# VERSION

sub meta {
    return {
        prio => 99,
        args => {},
    };
}

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub after_get_src {
    my ($self, $r) = @_;

    my $src = $r->src;
    return [404] unless defined $src;

    log_trace "Require::HookPlugin::debug::dump_source::logger: source code of %s <<END_DUMP\n%s\nEND_DUMP", $r->filename, $src;
    [200];
}

1;
# ABSTRACT: Log a message to Log::ger

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Require::HookPlugin -log::ger;
 # now each time we require(), a logging statement is produced at the trace level

A demo (L<nauniq> is a Perl script you can get from CPAN, and
L<Log::ger::Screen> is a module to show log statements on the terminal. Note
that the loading of L<strict>.pm and L<warnings>.pm are not logged because they
are already loaded by C<Log::ger::Screen>. If you want logging of such modules
you can try L<Require::HookPlugin::log::stderr> which avoids the use of any
module itself.

 $ TRACE=1 PERL5OPT="-MLog::ger::Screen -MRequire::HookPlugin=-log::logger" nauniq ~/samples/1.csv
 Require::HookPlugin::log::logger: Require-ing App/nauniq.pm (called from package main file /home/u1/perl5/perlbrew/perls/perl-5.34.0/bin/nauniq:7) ...
 Require::HookPlugin::log::logger: Require-ing Getopt/Long.pm (called from package main file /home/u1/perl5/perlbrew/perls/perl-5.34.0/bin/nauniq:8) ...
 Require::HookPlugin::log::logger: Require-ing vars.pm (called from package Getopt::Long file /loader/0x56139558fdb0/Getopt/Long.pm:20) ...
 Require::HookPlugin::log::logger: Require-ing warnings/register.pm (called from package vars file /loader/0x56139558fdb0/vars.pm:7) ...
 Require::HookPlugin::log::logger: Require-ing constant.pm (called from package Getopt::Long file /loader/0x56139558fdb0/Getopt/Long.pm:220) ...
 Require::HookPlugin::log::logger: Require-ing overload.pm (called from package Getopt::Long::CallBack file /loader/0x56139558fdb0/Getopt/Long.pm:1574) ...
 Require::HookPlugin::log::logger: Require-ing overloading.pm (called from package overload file /loader/0x56139558fdb0/overload.pm:84) ...
 Require::HookPlugin::log::logger: Require-ing Exporter/Heavy.pm (called from package Exporter file /home/u1/perl5/perlbrew/perls/perl-5.34.0/lib/5.34.0/Exporter.pm:13) ...
 ...


=head1 DESCRIPTION


=head1 SEE ALSO

L<Require::HookPlugin::log::stderr>
