## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin::debug::dump_source::stderr;

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

    warn "Require::HookPlugin::debug::dump_source::stderr: source code of ", $r->filename, " <<END_DUMP\n$src\nEND_DUMP\n";
    [200];
}

1;
# ABSTRACT: Dump loaded source code to STDERR

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Require::HookPlugin -end=>1,  'debug::dump_source::stderr';
 # now each time we require(), source code is printed to STDERR

A demo (L<nauniq> is a script available on CPAN):

 % PERL5OPT="-MRequire::HookPlugin=-debug::dump_source::stderr" nauniq ~/samples/1.csv
 Require::HookPlugin::debug::dump_source::stderr: source code of App/nauniq.pm <<END_DUMP
 ...
 END_DUMP
 ...


=head1 DESCRIPTION


=head1 SEE ALSO

L<Require::HookPlugin::debug::dump_source::logger>
