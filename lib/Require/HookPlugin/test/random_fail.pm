## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin::test::random_fail;

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
        args => {
            probability => {
                schema => 'float*',
                default => 0.5,
            },
        },
    };
}

sub new {
    my ($class, %args) = @_;

    my $probability = delete $args{probability};
    $probability = 0.5 unless defined $probability;

    die "Unknown argument(s): ".join(", ", keys %args) if keys %args;

    bless {probability=>$probability}, $class;
}

sub before_get_src {
    my ($self, $r) = @_;

    if (rand() < $self->{probability}) {
        my $filename = $r->filename;
        die "Can't locate $filename: test::random_fail";
    }
    [200];
}

1;
# ABSTRACT: Fail a module loading randomly

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Require::HookPlugin -test::random_fail, 0.25; # probability, default is 0.5 (50%)
 # now each subsequent require() will ~25% fail


=head1 DESCRIPTION

For testing only.


=head1 SEE ALSO

L<Require::HookPlugin::test::fail>
