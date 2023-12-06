## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin::source::test::str;

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
            src => {
                summary => 'String to return as source code',
                schema => 'str*',
            },
        },
    };
}

sub new {
    my ($class, %args) = @_;

    defined(my $src = delete $args{src}) or die "Please specify src";
    die "Unknown argument(s): ".join(", ", keys %args) if keys %args;

    bless { src => $src }, $class;
}

sub on_get_src {
    my ($self, $r) = @_;

    $r->src($self->{src});
    [201];
}

1;
# ABSTRACT: Use a constant string as source code

=for Pod::Coverage .+

=head1 SYNOPSIS

In Perl code:

 use Require::HookPlugin -source::test::str => (str => "1;\n");
 use Foo; # will use "1;\n" as source code even if the real Foo.pm is installed

On the command-line:

 # will use string '1' if Foo is not installed
 % perl -MRHP=-source::test::src,src,1 -MFoo -E...


=head1 DESCRIPTION

This is a test hook to load a constant string as source code of modules you are
loading. You can also achieve the same effect by directly installing an C<@INC>
hook without the L<Require::HookPlugin> framework like this:

 unshift @INC, sub { \"some string" };


=head1 SEE ALSO

Other C<Require::HookPlugin::source::*>
