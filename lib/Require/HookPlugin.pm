## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookPlugin;

# AUTHORITY
# DATE
# DIST
# VERSION

#IFUNBUILT
use strict 'subs','vars';
use warnings;
#END IFUNBUILT

our $SEPARATOR;
BEGIN {
    if ($^O =~ /^(dos|os2)/i) {
        $SEPARATOR = '\\';
    } elsif ($^O =~ /^MacOS/i) {
        $SEPARATOR = ':';
    } else {
        $SEPARATOR = '/';
    }
}

my $our_hook;
my $r;

# be minimalistic, use our own blessed() so we don't have to load any module (in this case, Scalar::Util)
unless (defined &blessed) {
    *blessed = sub { my $arg = shift; my $ref = ref $arg; $ref && $ref !~ /\A(SCALAR|ARRAY|HASH|GLOB|Regexp)\z/ };
}

our $debug;
our @Plugin_Instances;
our %Handlers; # key=event name, val=[ [$label, $prio, $handler, $epoch], ... ]

sub _run_event {
    my ($self, %args) = @_;

    my $name = $args{name};
    warn "[Require::HookPlugin] -> run_event(name=>$name, ...)\n" if $debug;
    defined $name or die "Please supply 'name'";
    $Handlers{$name} ||= [];

    my $before_name = "before_$name";
    $Handlers{$before_name} ||= [];

    my $after_name = "after_$name";
    $Handlers{$after_name} ||= [];

    my $req_handler                          = $args{req_handler};                          $req_handler                          = 0 unless defined $req_handler;
    my $run_all_handlers                     = $args{run_all_handlers};                     $run_all_handlers                     = 1 unless defined $run_all_handlers;
    my $allow_before_handler_to_cancel_event = $args{allow_before_handler_to_cancel_event}; $allow_before_handler_to_cancel_event = 1 unless defined $allow_before_handler_to_cancel_event;
    my $allow_before_handler_to_skip_rest    = $args{allow_before_handler_to_skip_rest};    $allow_before_handler_to_skip_rest    = 1 unless defined $allow_before_handler_to_skip_rest;
    my $allow_handler_to_skip_rest           = $args{allow_handler_to_skip_rest};           $allow_handler_to_skip_rest           = 1 unless defined $allow_handler_to_skip_rest;
    my $allow_handler_to_repeat_event        = $args{allow_handler_to_repeat_event};        $allow_handler_to_repeat_event        = 1 unless defined $allow_handler_to_repeat_event;
    my $allow_after_handler_to_repeat_event  = $args{allow_after_handler_to_repeat_event};  $allow_after_handler_to_repeat_event  = 1 unless defined $allow_after_handler_to_repeat_event;
    my $allow_after_handler_to_skip_rest     = $args{allow_after_handler_to_skip_rest};     $allow_after_handler_to_skip_rest     = 1 unless defined $allow_after_handler_to_skip_rest;
    my $stop_after_first_handler_failure     = $args{stop_after_first_handler_failure};     $stop_after_first_handler_failure     = 1 unless defined $stop_after_first_handler_failure;

    my ($res, $is_success, $is_unhandled);

  RUN_BEFORE_EVENT_HANDLERS:
    {
        last if $name =~ /\A(after|before)_/;
        local $r->{event} = $before_name;
        my $i = 0;
        for my $rec (@{ $Handlers{$before_name} }) {
            $i++;
            my ($label, $prio, $handler) = @$rec;
            warn "[Require::HookPlugin] [event $before_name] [$i/${\( scalar(@{ $Handlers{$before_name} }) )}] -> handler $label ...\n" if $debug;
            $res = $handler->($r);
            $is_success = $res->[0] =~ /\A[123]/;
            warn "[Require::HookPlugin] [event $before_name] [$i/${\( scalar(@{ $Handlers{$before_name} }) )}] <- handler $label: [".join(",",@$res)."] (".($is_success ? "success":"fail").")\n" if $debug;
            if ($res->[0] == 601) {
                if ($allow_before_handler_to_cancel_event) {
                    warn "[Require::HookPlugin] Cancelling event $name (status 601)\n" if $debug;
                    goto RETURN;
                } else {
                    die "$before_name handler returns 601 when allow_before_handler_to_cancel_event is set to false";
                }
            }
            if ($res->[0] == 201) {
                if ($allow_before_handler_to_skip_rest) {
                    warn "[Require::HookPlugin] Skipping the rest of the $before_name handlers (status 201)\n" if $debug;
                    last RUN_BEFORE_EVENT_HANDLERS;
                } else {
                    warn "[Require::HookPlugin] $before_name handler returns 201, but we ignore it because allow_before_handler_to_skip_rest is set to false";
                }
            }
        }
    }

  RUN_EVENT_HANDLERS:
    {
        local $r->{event} = $name;
        my $i = 0;
        $res = [304, "There is no handler for event $name"];
        $is_unhandled = 1;
        $is_success = 1;
        if ($req_handler) {
            die "There is no handler for event $name"
                unless @{ $Handlers{$name} };
        }

        for my $rec (@{ $Handlers{$name} }) {
            $i++;
            my ($label, $prio, $handler) = @$rec;
            warn "[Require::HookPlugin] [event $name] [$i/${\( scalar(@{ $Handlers{$name} }) )}] -> handler $label ...\n" if $debug;
            $res = $handler->($r);
            $is_unhandled = 0;
            $is_success = $res->[0] =~ /\A[123]/;
            warn "[Require::HookPlugin] [event $name] [$i/${\( scalar(@{ $Handlers{$name} }) )}] <- handler $label: [".join(",", @$res)."] (".($is_success ? "success":"fail").")\n" if $debug;
            last RUN_EVENT_HANDLERS if $is_success && !$run_all_handlers;
            if ($res->[0] == 601) {
                die "$name handler is not allowed to return 601";
            }
            if ($res->[0] == 602) {
                if ($allow_handler_to_repeat_event) {
                    warn "[Require::HookPlugin] Repeating event $name (handler returns 602)\n" if $debug;
                    goto RUN_EVENT_HANDLERS;
                } else {
                    die "$name handler returns 602 when allow_handler_to_repeat_event is set to false";
                }
            }
            if ($res->[0] == 201) {
                if ($allow_handler_to_skip_rest) {
                    warn "[Require::HookPlugin] Skipping the rest of the $name handlers (status 201)\n" if $debug;
                    last RUN_EVENT_HANDLERS;
                } else {
                    warn "[Require::HookPlugin] $name handler returns 201, but we ignore it because allow_handler_to_skip_rest is set to false\n" if $debug;
                }
            }
            last RUN_EVENT_HANDLERS if !$is_success && $stop_after_first_handler_failure;
        }
    }

    if ($is_unhandled && $args{on_unhandled}) {
        warn "[Require::HookPlugin] Running on_unhandled ...\n" if $debug;
        $args{on_unhandled}->($r);
    } elsif ($is_success && $args{on_success}) {
        warn "[Require::HookPlugin] Running on_success ...\n" if $debug;
        $args{on_success}->($r);
    } elsif (!$is_success && $args{on_failure}) {
        warn "[Require::HookPlugin] Running on_failure ...\n" if $debug;
        $args{on_failure}->($r);
    }

  RUN_AFTER_EVENT_HANDLERS:
    {
        last if $name =~ /\A(after|before)_/;
        local $r->{event} = $after_name;
        my $i = 0;
        for my $rec (@{ $Handlers{$after_name} }) {
            $i++;
            my ($label, $prio, $handler) = @$rec;
            warn "[Require::HookPlugin] [event $after_name] [$i/${\( scalar(@{ $Handlers{$after_name} }) )}] -> handler $label ...\n" if $debug;
            $res = $handler->($r);
            $is_success = $res->[0] =~ /\A[123]/;
            warn "[Require::HookPlugin] [event $after_name] [$i/${\( scalar(@{ $Handlers{$after_name} }) )}] <- handler $label: [".join(",",@$res)."] (".($is_success ? "success":"fail").")\n" if $debug;
            if ($res->[0] == 602) {
                if ($allow_after_handler_to_repeat_event) {
                    warn "[Require::HookPlugin] Repeating event $name (status 602)\n" if $debug;
                    goto RUN_EVENT_HANDLERS;
                } else {
                    die "$after_name handler returns 602 when allow_after_handler_to_repeat_event it set to false";
                }
            }
            if ($res->[0] == 201) {
                if ($allow_after_handler_to_skip_rest) {
                    warn "[Require::HookPlugin] Skipping the rest of the $after_name handlers (status 201)\n" if $debug;
                    last RUN_AFTER_EVENT_HANDLERS;
                } else {
                    warn "[Require::HookPlugin] $after_name handler returns 201, but we ignore it because allow_after_handler_to_skip_rest is set to false\n" if $debug;
                }
            }
        }
    }

  RETURN:
    warn "[Require::HookPlugin] <- run_event(name=$name)\n" if $debug;
    undef;
}

my $handler_seq = 0;
sub _add_handler {
    my ($self, $event, $label, $prio, $handler) = @_;

    # XXX check for known events?
    $Handlers{$event} ||= [];

    # keep sorted
    splice @{ $Handlers{$event} }, 0, scalar(@{ $Handlers{$event} }),
        (sort { $a->[1] <=> $b->[1] || $a->[3] <=> $b->[3] } @{ $Handlers{$event} },
         [$label, $prio, $handler, $handler_seq++]);
}

sub _activate_single {
    my ($self, $plugin_name0, $args) = @_;

    my ($plugin_name, $wanted_event, $wanted_prio) =
        $plugin_name0 =~ /\A(\w+(?:::\w+)*)(?:\@(\w+)(?:\@(\d+))?)?\z/
        or die "Invalid plugin name syntax, please use Foo::Bar or ".
        "Foo::Bar\@event or Foo::Bar\@event\@prio\n";

    local $r->{plugin_name} = $plugin_name;
    local $r->{plugin_args} = $args;

    $self->_run_event(
        name => 'activate_plugin',
        on_success => sub {
            my $package = "Require::HookPlugin::$plugin_name";
            (my $package_pm = "$package.pm") =~ s!::!/!g;
            warn "[Require::HookPlugin] Loading module $package ...\n" if $debug;
            require $package_pm;
            my $obj = $package->new(%{ $args || {} });

            my $symtbl = \%{$package . "::"};

            my $meta;
          CHECK_META: {
                defined &{"$package\::meta"} or die "$package does not define meta()";
                $meta = &{"$package\::meta"}();
                my $v = $meta->{v}; $v = 1 unless defined $v;
                if ($v != 1) {
                    die "Cannot use $package: meta: I only support v=1 ".
                        "but the module has v=$v";
                }
            }

            # register in @Plugin_Instances
            {
                no warnings 'once';
                push @Plugin_Instances, $obj;
            }

            for my $k (keys %$symtbl) {
                my $v = $symtbl->{$k};
                next unless ref $v eq 'CODE' || defined *$v{CODE};
                next unless $k =~ /^(before_|on_|after_)(.+)$/;

                my $meta_method = "meta_$k";
                my $methmeta = $self->can($meta_method) ? $self->$meta_method : {};

                (my $event = $k) =~ s/^on_//;

                $self->_add_handler(
                    defined $wanted_event ? $wanted_event : $event,
                    $plugin_name,
                    (defined $wanted_prio ? $wanted_prio :
                     defined $methmeta->{prio} ? $methmeta->{prio} :
                     defined $meta->{prio} ? $meta->{prio} : 50),
                    sub {
                        my $stash = shift;
                        $obj->$k($stash);
                    },
                );
            }
        },
        on_failure => sub {
            die "Cannot activate plugin $plugin_name";
        },
    );
}

sub _activate_plugins {
    my $self = shift;

    while (@_) {
        my $plugin_name0 = shift;
        $plugin_name0 =~ s/\A-// or die "Invalid import argument '$plugin_name0', must be -PLUGIN_NAME";
        my @plugin_args;
        while (@_ && $_[0] !~ /\A-/) {
            push @plugin_args, splice(@_,0,2);
        }
        $self->_activate_single($plugin_name0, {@plugin_args});
    }
}

# from Module::Installed::Tiny
sub _parse_name {
    my $name = shift;

    my ($name_mod, $name_pm, $name_path);
    # name_mod is Foo::Bar form, name_pm is Foo/Bar.pm form, name_path is
    # Foo/Bar.pm or Foo\Bar.pm (uses native path separator), name_path_prefix is
    # Foo/Bar.

    if ($name =~ m!/|\.pm\z!) {
        # assume it's name_pm form
        $name_pm = $name;
        $name_mod = $name;    $name_mod =~ s/\.pm\z//; $name_mod =~ s!/!::!g;
        $name_path = $name_pm; $name_path =~ s!/!$SEPARATOR!g if $SEPARATOR ne '/';
    } elsif ($SEPARATOR ne '/' && $name =~ m!\Q$SEPARATOR!) {
        # assume it's name_path form
        $name_path = $name;
        ($name_pm = $name_path) =~ s!\Q$SEPARATOR!/!g;
        $name_mod = $name_pm; $name_mod =~ s/\.pm\z//; $name_mod =~ s!/!::!g;
    } else {
        # assume it's name_mod form
        $name_mod = $name;
        ($name_pm  = "$name_mod.pm") =~ s!::!/!g;
        $name_path = $name_pm; $name_path =~ s!/!$SEPARATOR!g if $SEPARATOR ne '/';
    }

    ($name_mod, $name_pm, $name_path);
}

# modified from Module::Installed::Tiny
sub _get_src_from_rest_of_INC {
    warn "D1";
    my ($self, $name) = @_;

    my ($name_mod, $name_pm, $name_path) = _parse_name($name);

    my $index = -1;
    my @res;
  ENTRY:
    for my $entry (@INC) {
        $index++;
        next unless defined $entry;
        my $ref = ref($entry);
        next if $ref && blessed($entry) && $entry == $our_hook;

        my ($is_hook, @hook_res);
        if ($ref eq 'ARRAY') {
            $is_hook++;
            eval { @hook_res = $entry->[0]->($entry, $name_pm) };
            if ($@) { warn "[Require::HookPlugin] array hook in \@INC ($entry) died: $@" if $debug; return }
        } elsif (UNIVERSAL::can($entry, 'INC')) {
            $is_hook++;
            eval { @hook_res = $entry->INC($name_pm) };
            if ($@) { warn "[Require::HookPlugin] INC hook in \@INC ($entry) died: $@" if $debug; return }
        } elsif ($ref eq 'CODE') {
            $is_hook++;
            eval { @hook_res = $entry->($entry, $name_pm) };
            if ($@) { warn "[Require::HookPlugin] coderef hook in \@INC ($entry) died: $@" if $debug; return }
        } else {
            my $path = "$entry$SEPARATOR$name_path";
            if (-f $path) {
                my $fh;
                unless (open $fh, "<", $path) {
                    warn "[Require::HookPlugin] Can't open $path from \@INC ($entry)" if $debug;
                    return;
                }
                local $/;
                my $res = wantarray ? [scalar <$fh>, $path, $entry, $index, $name_mod, $name_pm, $name_path] : scalar <$fh>;
                return wantarray ? @$res : $res;
            }
        }

        if ($is_hook) {
            next unless @hook_res;
            my ($src, $fh, $code);
            eval {
                my $prepend_ref; $prepend_ref = shift @hook_res if ref($hook_res[0]) eq 'SCALAR';
                $fh                           = shift @hook_res if ref($hook_res[0]) eq 'GLOB';
                $code                         = shift @hook_res if ref($hook_res[0]) eq 'CODE';
                my $code_state ; $code_state  = shift @hook_res if @hook_res;
                if ($fh) {
                    $src = "";
                    local $_;
                    while (!eof($fh)) {
                        $_ = <$fh>;
                        if ($code) {
                            $code->($code, $code_state);
                        }
                        $src .= $_;
                    }
                    $src = $$prepend_ref . $src if $prepend_ref;
                } elsif ($code) {
                    $src = "";
                    local $_;
                    while ($code->($code, $code_state)) {
                        $src .= $_;
                    }
                    $src = $$prepend_ref . $src if $prepend_ref;
                }
            }; # eval
            if ($@) { warn "[Require::HookPlugin] Can't load $name_pm from hook in \@INC ($entry)" if $debug; return }
            my $res = wantarray ? [$src, undef, $entry, $index, $name_mod, $name_pm, $name_path] : $src;
            return wantarray ? @$res : $res;
        } # if $is_hook
    }

    if (@res) {
        return wantarray ? @res : \@res;
    } else {
        warn "[Require::HookPlugin] Can't find $name_pm in \@INC" if $debug;
        return;
    }
}

sub new {
    my $class = shift;

    bless {}, $class;
}

sub Require::HookPlugin::INC {
    my ($self, $filename) = @_;

    warn "[Require::HookPlugin] require($filename) ...\n" if $debug;

    $r = Require::HookPlugin::r->new(filename => $filename, caller=>[caller(0)]);

    {
        my $handler = sub {
            # fallback to getting source from other items in @INC
            my $src = $self->_get_src_from_rest_of_INC($filename);
            if (defined $src) {
                $r->src($src);
            }
        };
        $self->_run_event(
            name => 'get_src',
            on_failure => $handler,
            on_unhandled => $handler,
        );
    }

    #print "D:src=<<".$r->src.">>\n";

    my $src = $r->src;
    if (defined $src) {
        return $src;
    } else {
        die "Can't locate $filename in \@INC";
    }
}

sub import {
    my $class = shift;

    warn "[Require::HookPlugin] (Re-)installing our own hook at the beginning of \@INC ...\n" if $debug;
    unless (@INC && blessed($INC[0]) && $INC[0] == $our_hook) {
        @INC = ($our_hook, grep { !(blessed($_) && $_ == $our_hook) } @INC);
    }

    $class->_activate_plugins(@_);
}

$our_hook = __PACKAGE__->new;

package Require::HookPlugin::r;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub filename {
    my $self = shift;
    $self->{filename};
}

sub src {
    my $self = shift;
    if (@_) {
        my $old = $self->{src};
        $self->{src} = shift;
        return $old;
    } else {
        return $self->{src};
    }
}

sub caller {
    my $self = shift;
    $r->{caller};
}

1;
# ABSTRACT: Pluggable require hooks

=for Pod::Coverage ^(blessed)$

=head1 SYNOPSIS

Say you want to create a require hook to prepend some code to the module source
code that is loaded. In your hook source, in
F<Require/HookPlugin/munge/prepend.pm>:

 package Require::HookPlugin::munge::prepend;

 sub meta {
     return {
         prio => 50, # 50=normal (default), 10=high (run before most other plugins), 90=low (run after most other plugins)
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

     # we only munge source code, when source code has not been loaded by other
     # hooks, we decline.
     return unless defined $src;

     $src = "$self->{preamble};\n$src";
     $r->src($src);
 }

 1;

In a code to use this hook:

 use Require::HookPlugin -munge::prepend => (preamble => 'use strict');
 use Foo::Bar; # Foo/Bar.pm will be loaded with added 'use strict;' at the start

or from the command line:

 % perl -MRHP=-

To install other hooks:

 use Require::HookPlugin
   -munge::append => (postamble => 'some code'),
   -log::stderr;


=head1 DESCRIPTION

This module lets you create pluggable require hooks. It allows you to add
multiple behaviors, when Perl loads modules, by writing plugins instead of
writing require hooks directly.

When C<use>'d, C<Require::HookPlugin> will install its own hook at the beginning
of C<@INC> as well as load plugins you specify. This is the only hook that will
be installed. The hook, when run by perl, will in turn run the loaded plugins in
a defined order.

=head2 Writing plugins

A plugin is a Perl module in the C<Require::HookPlugin::*> namespace. As shown
in the Synopsis, a plugin needs to define C<meta()> that returns a hash
(L<DefHash>) specifying its priority, arguments, and other things. It also needs
to define handler(s) (method(s)) for one or more of these events:

 before_get_src
 get_src
 after_get_src

(There are also special events: C<tivate_plugin>).

For each event, handlers from all plugins will be executed in order of each
plugin's priority. All handlers will be executed unless a handler gives a signal
to stop early.

The handler will be passed, as argument, the stash hashref (C<$r>) containing
various stuffs. The method can do things on C<$r>, for example retrieve the
loaded source code via C<< $r->src >> or modify source code via C<<
$r->src($new_content) >>. After that it must return an enveloped result:

 [$status_code, $message]

C<$status_code> is 200 to signal OK (so C<Require::HookPlugin> hook can continue
to the next handler), 201 (or 601) to signal OK and skip the rest of the
handlers for the event, 500 to signal fatal error (C<Require::HookPlugin> will
die with C<$message>), 602 to repeat from the first handler of the event.

After all handlers from all events are executed, C<Require::HookPlugin> hook
will return the final source perl, retrieved from C<< $r->src >>, for perl.

=back


=head2 Subnamespace organization

=over

=item * Require::HookPlugin::debug::

Plugins that do debugging-related stuffs. See also: C<log::> subnamespace,
C<timestamp::> subnamespace.

=item * Require::HookPlugin::log::

Plugins that add logging to module loading process. See also: C<debug::>
subnamespace.

=item * Require::HookPlugin::munge::

Pllugins that modify source code.

=item * Require::HookPlugin::postcheck::

Plugins that perform checks after the source code is loaded (eval-ed). See also
C<precheck::> subnamespace.

=item * Require::HookPlugin::precheck::

Plugins that perform checks before the source code is loaded (eval-ed). See also
C<postcheck::> subnamespace.

=item * Require::HookPlugin::source::

Plugins that allow loading module source from alternative sources.

=item * Require::HookPlugin::test::

Testing-related, particularly testing the Require::HookPlugin itself.

=item * Require::HookPlugin::timestamp::

Plugins that add timestamps during module loading process.

=back

=head2 Require::HookPlugin::r OBJECT

=head2 Methods

=head3 filename

Usage:

 my $filename = $r->filename;

Get the filename (the argument to C<require()>, the filename that the user
requests when she calls C<require()>).

=head3 src

Usage:

 my $src = $r->src;
 $r->src($new_src);

Get or set source code content. Will return undef if source code has not been
found or set.

=head3 caller

Usage:

 my $caller = $r->caller; # arrayref


=head1 FAQ

=head2 Loading a hook plugin does nothing!

Make sure you use a hook plugin this way:

 use Require::HookPlugin 'pluginname'; # correct

instead of:

 use Require::HookPlugin::pluginname; # INCORRECT, this does not install the hook to @INC

=head2 What are the differences between Require::HookChain and Require::HookPlugin?

=for BEGIN_BLOCK:rhc_vs_rhp

Require::HookChain (RHC) and Require::HookPlugin (RHP) are both frameworks to
add custom behavior to the module loading process. The following are the
comparison between the two:

RHC and RHP both work by installing its own handler (a coderef) at the beginning
of C<@INC>. They then evaluate the rest of C<@INC> like Perl does, with some
differences.

Perl stops at the first C<@INC> element where it finds the source code, while
RHC's handler evaluates all the entries of C<@INC> looking for hooks in the form
of objects of the class under the C<Require::HookChain::> namespace.

RHP's plugins, on the other hand, are not installed directly in C<@INC> but in
another array (C<@Require::HookPlugin::Plugin_Instances>), so the only entry
installed in C<@INC> is RHP's own handler.

RHC evaluates hooks in C<@INC> in order, so you have to install the hooks in the
right order to get the correct behavior. On the other hand, RHP evaluates
plugins based on events, plugins' priority, and activation order. Plugins have a
default priority value (though you can override it). In general you can activate
plugins in whatever order and generally they will do the right thing. RHP is
more flexible and powerful than RHC, but is slightly more complex.

Writing hooks for RHC (or plugins for RHP) are roughly equally easy.

=for END_BLOCK:rhc_vs_rhp


=head1 SEE ALSO

L<RHP> for convenience of using on the command-line or one-liners.

Previous projects: L<Require::Hook> (RH), Require::HookChain (RHC).
