## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin::munge::prepend;

#IFUNBUILT
use strict;
use warnings;
#END IFUNBUILT

# AUTHORITY
# DATE
# DIST
# VERSION

sub meta {
    return {
        prio => 50,
        args => {
            preamble => {
                summary => 'String to add to the beginning of source code',
                schema => 'str*',
            },
        },
    };
}

sub new {
    my ($class, %args) = @_;

    defined(my $preamble = delete $args{preamble}) or die "Please specify preamble";
    die "Unknown argument(s): ".join(", ", keys %args) if keys %args;

    bless { preamble => $preamble }, $class;
}

sub after_get_src {
    my ($self, $r) = @_;

    my $src = $r->src;
    return [404] unless defined $src;

    $src = "$self->{preamble};\n$src";
    $r->src($src);
    [200];
}

1;
# ABSTRACT: Prepend a piece of code to module source

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Require::HookPlugin -munge::prepend => (preamble=>'use strict'); # the semicolon and newline is added automatically

The above has a similar effect to:

 use everywhere 'strict';

because it will prepend this line to each source code being loaded:

 use strict;

=cut
