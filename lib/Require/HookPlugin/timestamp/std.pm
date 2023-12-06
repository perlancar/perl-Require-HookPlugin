## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin::timestamp::std;

# IFUNBUILT
use strict;
use warnings;
# END IFUNBUILT

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
}

1;
# ABSTRACT: Record timestamp of each module's loading

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Require::HookPlugin -timestamp::std;
 # now each time we require(), the timestamp is recorded in %Require::HookPlugin::timestamp::std::Timestamps

 # later, print out the timestamps
 for (sort keys %Require::HookPlugin::timestamp::std::Timestamps) {
     print "Module $_ loaded at ", scalar(localtime $Require::HookPlugin::timestamp::std::Timestamps{$_}), "\n";
 }


=head1 DESCRIPTION


=head1 SEE ALSO

L<Require::HookPlugin::timestamp::hires> which uses L<Time::HiRes> to get
subsecond granularity but requires loading another module by itself.
