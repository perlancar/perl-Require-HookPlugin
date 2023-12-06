## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin::test::noop;

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

1;
# ABSTRACT: Do nothing when a module is loaded

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Require::HookPlugin -test::noop;
 # now each subsequent require() will behave the same as before


=head1 DESCRIPTION

For testing only.

This plugin does nothing.


=head1 SEE ALSO

L<Require::HookPlugin::test::noop_all>
