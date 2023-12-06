## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin::timestamp::hires;

# IFUNBUILT
use strict;
use warnings;
# END IFUNBUILT

use Time::HiRes qw(time);

# AUTHORITY
# DATE
# DIST
# VERSION

our %Timestamps; # key=module name, value=epoch

sub meta {
    return {
        prio => 50,
        args => {
        },
    };
}

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub after_get_src {
    my ($self, $r) = @_;

    $Timestamps{$r->filename} = time()
        unless defined $Timestamps{$r->{filename}};
    [404];
}

1;
# ABSTRACT: Record timestamp of each module's loading (uses Time::HiRes)

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Require::HookPlugin -timestamp::hires;
 # now each time we require(), the timestamp is recorded in %Require::HookPlugin::timestamp::hires::Timestamps

 # later, print out the timestamps
 for (sort keys %Require::HookPlugin::timestamp::hires::Timestamps) {
     print "Module $_ loaded at ", scalar(localtime $Require::HookPlugin::timestamp::hires::Timestamps{$_}), "\n";
 }


=head1 DESCRIPTION


=head1 SEE ALSO

L<Require::HookPlugin::timestamp::std> which uses built-in time() which only has
1-second granularity but does not require loading any module by itself.

L<Require::HookPlugin>
