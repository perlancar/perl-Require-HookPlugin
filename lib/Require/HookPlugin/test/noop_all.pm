## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin::test::noop_all;

# IFUNBUILT
use strict;
use warnings;
# END IFUNBUILT
#use Log::ger;

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

sub after_get_src {
    my ($self, $r) = @_;

    #print "Loading ", $r->filename, " ...\n";
    $r->src("1;");
}

1;
# ABSTRACT: Make module loading a no-op

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Require::HookPlugin -test::noop_all;
 # now each subsequent require() will do nothing and will not load any source


=head1 DESCRIPTION

For testing only.

This hook returns a source code of C<< 1; >> for all modules, effectively making
all module loading a no-op. On subsequent loading for a module, perl sees that
the source code has been applied and will not load the source again, which is
the regular "no-op" upon re-loading a module.


=head1 SEE ALSO

L<Require::HookPlugin::test::noop>
