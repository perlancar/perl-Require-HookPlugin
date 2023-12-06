## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin::test::fail;

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

    my $filename = $r->filename;
    die "Can't locate $filename: test::fail";
}

1;
# ABSTRACT: Always fail a module loading

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Require::HookPlugin -test::fail;
 # now each subsequent require() will fail


=head1 DESCRIPTION

For testing only.


=head1 SEE ALSO

L<Require::HookPlugin::test::random_fail>
