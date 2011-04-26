use strict;
use warnings;
package Mojolicious::Plugin::Session;
# ABSTRACT: Server-side data storage for Mojolicious sessions
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $conf) = (@_);
    $conf ||= {};

    die ref($self), q|: missing required parameter 'backend'|, "\n" unless($conf->{backend});
    die ref($self), q|: no such backend '|, $conf->{backend}, "'\n" if($conf->{backend} !~/^(mongodb|dbi|dummy)$/);

    my $backend_class = sprintf('%s::%s', __PACKAGE__, ucfirst(lc(delete($conf->{backend}))));
    eval 'use ' . $backend_class . ';'; 
    die ref($self), q|: could not load backend module for: '|, $conf->{backend}, "\n" if($@);
    my $backend = $backend_class->new(%{$conf});

    $app->plugins->add_hook(before_dispatch => sub {
        my $self = shift;
        my $c    = shift;

        $backend->load($c); 
    });
    $app->plugins->add_hook(after_dispatch => sub {
        my $self = shift;
        my $c    = shift;

        $backend->store($c);
        $backend->cleanup($c);
    });
}

1;
=pod
=head1 SYNOPSIS

    $app->plugin('session', { 
        backend => 'mongodb',
        ...
        });

=head1 DESCRIPTION

L<Mojolicious> comes equipped with built-in session handling, it stores your session data in a signed cookie. This is often more than enough for most applications, however, if you need to store more than 4Kb in data, you're out of luck. That is where this module steps in. It also lets you set up per-user sessions, normal sessions are per-device (read: browser), per-user sessions mean that a user logging in on his iPad, then logging in on his desktop, will see the same session data. 

=head1 CONFIGURATION

The following options can be passed during plugin registration

    backend             (REQUIRED)  -   The name of a backend (see also L<STORAGE BACKENDS>), in lowercase. 
    peruser             (optional)  -   See L<PER USER SESSIONS> for an explanation of how to use this.
    dont_gack_session   (optional)  -   When set, it will not do a destructive copy of Mojolicious' session to the
                                        backend data store, instead it will make a copy. 

All other options will be passed to the backend module. 

=head1 STORAGE BACKENDS

Please see the documentation for L<Mojolicious::Plugin::Session::Dummy>, L<Mojolicious::Plugin::Session::Mongodb> and L<Mojolicious::Plugin::Session::Dbi> for backend configuration options.

=head1 PER USER SESSIONS

Normally speaking, sessions are kept on a per device basis, meaning that if you are using some form of logging users in, the same user can log in from multiple devices, but will have one session per device. In this context a device also refers to a single web-browser. 

If you want your application to have the ability to share the same session data even if a user logs in from multiple devices, that is where the 'peruser' option comes in. In order to know which user we're actually looking for, you will have to pass a callback that returns an ID (string) of the user whose session we're actually looking for. 

If you are using L<Mojolicious::Plugin::Authentication>, you would configure this module as follows:

    $app->plugin(authentication => { 
        session_key => 'foo_bar',
    });

    $app->plugin(session => { 
        backend => 'mongodb',
        backend_options => { ... },
        peruser => 'foo_bar',
    });

If you are using another way to authenticate your users, make sure that you set per_user to the session key holding the user's ID, name, or other uniquely identifying bit of data.

=head1 BUGS/CONTRIBUTING

Please report any bugs or feature requests through the web interface at L<https://github.com/benvanstaveren/Mojolicious-Plugin-Session/issues>. 
You can fork my Git repository at L<https://github.com/benvanstaveren/Mojolicious-Plugin-Session/> if you want to make changes or supply me with patches.
