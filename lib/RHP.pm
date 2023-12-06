## no critic: TestingAndDebugging::RequireUseStrict
package RHP;
use alias::module 'Require::HookPlugin';

1;
# ABSTRACT: Short alias for Require::HookPlugin

=for Pod::Coverage ^(blessed)$

=head1 SYNOPSIS

On the command-line:

 # add 'use strict' to all loaded modules
 % perl -MRHP=-munge::prepend,'use strict' ...


=head1 DESCRIPTION

This is a short alias for L<Require::Hookplugin> for less typing on the
command-line.


=head1 SEE ALSO

L<Require::HookPlugin>
