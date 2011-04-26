use strict;
use warnings;
package Mojolicious::Plugin::Session::Base;
# ABSTRACT: Base class for session module
use Mojo::Base 'Mojolicious::Sessions';
use Time::HiRes ();

has peruser => undef;
has dont_gack_session => sub { 0 };

# here's the science
# in mojolicious' session, all we keep is a reference to our own session key,
# if we don't have it, we create it and set it, and create an empty session
# in the database. If we have it, we load.
#
# Storage is a bit more finicky in the sense that we want to take the existing session,
# and flat out remove everything that isn't: flash, expires, session_key - this we store,
# the rest we plain out suck out of it. 
#
# IF peruser is set, it should be set to whatever key in the session contains a unique
# user id, which we will also leave alone.
#
# IF dont_gack_session is set, it will make a copy and store that 
#
# For the curious ones, "gacking" something is the equivalent of a violent stabbing murder. Which is about
# what we do to Mojolicious' sessions. 

sub load {
    my $self = shift;
    my $c    = shift;

    return unless($c);

    my $mojo_session = $c->session;
    my $session_key  = $mojo_session->{'mps.key'};
    my $uid          = ($self->peruser) ? $mojo_session->{$self->peruser} : undef;

    $session_key = sprintf('mps.peruser.%s', "$uid") if($uid);

    # well nao. 
    if($session_key and my $session_from_database = $self->load_data(key => $session_key)) {
        # we could use Hash::Merge but then we'd still end up copying things back and forth,
        # we'll do this instead. same as right_predecence merges anyway. 
        @{$mojo_session}{keys %$session_from_database} = values(%$session_from_database); 
    } elsif($session_key) {
        # we have a key, so the load or thaw failed
        $self->clear_data(key => $session_key);
        $mojo_session->{'mps.key'} = $self->create_data(key => $session_key);
    } else {
        # really nothing here? oh well
        $mojo_session->{'mps.key'} = $self->create_data(key => $self->generate_key);
    }
}

sub store {
    my $self = shift;
    my $c    = shift;

    return unless($c);

    my $mojo_session = $c->session;
    my $session_key  = $mojo_session->{'mps.key'};

    my $session_to_database = {};

    my $exclude = 'mps\.|mojo\.|expires|flash';
    $exclude .= '|' . quotemeta($self->peruser) if($self->peruser); # because we don't want to gack that at all
    my $exclude_re = qr/$exclude/;

    foreach my $key (keys(%$mojo_session)) {
        next if($key =~ $exclude_re);
        $session_to_database->{$key} = ($self->dont_gack_session) 
            ? $mojo_session->{$key}
            : delete($mojo_session->{$key});
    }
    # transplant the expiry if we have it 

    $self->store_data(key => $session_key, data => $session_to_database, expires => $mojo_session->{expires});
    return $self;
}

sub cleanup {
    my $self = shift;
    my $c    = shift;

    return unless(defined($c->session->{expires})); # if it's not there, means we haven't ever stored this session, so better not because it'll mess with
                                                    # create_data
    $self->cleanup_data();
}

sub generate_key {
    my $self = shift;
    my @seed = ('a'..'z','A'..'Z','0'..'9');
    my $key = Time::HiRes::time();
    while(length($key) < 32) {
        $key .= $seed[int(rand($#seed))]; # add some randomness 
    }
    return $key;
}

sub store_data {}
sub load_data {}
sub clear_data {}
sub create_data {}
sub cleanup_data {}

1;
=pod
=head1 BUGS/CONTRIBUTING

Please report any bugs or feature requests through the web interface at L<https://github.com/benvanstaveren/Mojolicious-Plugin-Session/issues>. 
You can fork my Git repository at L<https://github.com/benvanstaveren/Mojolicious-Plugin-Session/> if you want to make changes or supply me with patches.
=cut
