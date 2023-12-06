## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin::source::test::code;

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
            code => {
                summary => 'Code to return as source code',
                schema => 'code*',
            },
        },
    };
}

sub new {
    my ($class, %args) = @_;

    defined(my $code = delete $args{code}) or die "Please specify code";
    die "Unknown argument(s): ".join(", ", keys %args) if keys %args;

    bless { code => $code }, $class;
}

sub on_get_src {
    my ($self, $r) = @_;

    $r->src($self->{code}->($r));
    [201];
}

1;
# ABSTRACT: Specify a code to provide source code

=for Pod::Coverage .+

=head1 SYNOPSIS

In Perl code:

 use Require::HookPlugin -source::test::code => (code => sub { my $r = shift; $r->src("1;\n") unless defined $r->src });
 use Foo; # will use "1;\n" as source code even if the real Foo.pm is installed

On the command-line:

 # will use code if Foo is not installed
 % perl -E'use RHP -source::test::code => (code => sub { my $r = shift; $r->src("1;\n") unless defined $r->src }); use Foo; ...'


=head1 DESCRIPTION

This is a test hook to call specified code to provide source code of modules you
are loading. The code is called with C<$r> (see
L<Require::HookPlugin/"Require::HookPlugin::r OBJECT">) as the argument. To
provide source code, you can call C<< $r->src >> as shown in Synopsis.

You can also achieve the same effect by directly installing an C<@INC> hook
without the L<Require::HookPlugin> framework like this:

 unshift @INC, sub { ... };


=head1 SEE ALSO

Other C<Require::HookPlugin::source::*>
