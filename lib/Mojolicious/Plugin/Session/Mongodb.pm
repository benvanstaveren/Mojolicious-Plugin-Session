use strict;
use warnings;
package Mojolicious::Plugin::Session::Mongodb;
# ABSTRACT: Mongodb storage class for session module
use Mojo::Base 'Mojolicious::Plugin::Session::Base';
use MongoDB;
use Storable qw/freeze thaw/;

has database => undef;
has collection => undef;
has host => undef;
has port => undef;

has '_conndata' => sub { {} };

sub new {
    my $package = shift;
    my $self = $package->SUPER::new(@_);
    for(qw/database collection/) {
        die $package, q|: missing required parameter '|, $_, "'\n" if(!$self->$_());
        $self->{_conndata}->{$_} = $self->$_();
    }
    for(qw/host port/) {
        $self->{_conndata}->{$_} = $self->$_() if($self->$_());
    }
    return bless($self, $package);
}

sub _conn {
    my $self = shift;
    return MongoDB::Connection->new(%{$self->_conndata});
}

sub cleanup_data {
    my $self = shift;
    my $conn = $self->_conn;
    $conn->get_database($self->database)->get_collection($self->collection)->remove({ expires => { '$gte' => 0, '$lt' => time() } });
    $conn = undef;
}

sub create_data {
    my $self = shift;
    my %args = (@_);
    my $session = {
        _id     => $args{'key'},
        data    => undef,
        touched => Time::HiRes::time(),
        expires => -1,
        };

    my $conn = $self->_conn;
    $conn->get_database($self->database)->get_collection($self->collection)->insert($session);
    $conn = undef;
    return $args{'key'};
}

sub load_data {
    my $self = shift;
    my %args = (@_);

    my $conn = $self->_conn;
    my $session = $conn->get_database($self->database)->get_collection($self->collection)->find_one({ _id => $args{'key'}});
    $conn = undef;
    return ($session) ? $session->{data} : {};
}

sub store_data {
    my $self = shift;
    my %args = (
        expires => -1,
        data => undef,
        @_);

    my $conn = $self->_conn;
    my $update = {
        '$set' => {
            data => $args{'data'},
            expires => $args{'expires'},
        },
    };
    $conn->get_database($self->database)->get_collection($self->collection)->update({ _id => $args{'key'}}, $update, { safe => 1 });
    $conn = undef;
}

sub clear_data {
    my $self = shift;
    my %args = (@_);

    my $conn = $self->_conn;
    $conn->get_database($self->database)->get_collection($self->collection)->remove({ _id => $args{'key'}});
    $conn = undef;
}

1;
=pod
=head1 NAME

Mojolicious::Plugin::Session::Mongodb - MongoDB backend driver

=head1 CONFIGURATION

This driver accepts the following options

    host        (optional)  The host to connect to
    port        (optional)  Port to connect to
    database    (REQUIRED)  The database to use for the session storage
    collection  (REQUIRED)  The collection to use for the session storage

=head1 BUGS/CONTRIBUTING

Please report any bugs or feature requests through the web interface at L<https://github.com/benvanstaveren/Mojolicious-Plugin-Session/issues>. 
You can fork my Git repository at L<https://github.com/benvanstaveren/Mojolicious-Plugin-Session/> if you want to make changes or supply me with patches.
=cut
