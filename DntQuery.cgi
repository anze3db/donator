package DntQuery;
use strict;
use base qw(Apache::Request);

sub new {
    my($class, @args) = @_;
    return bless { _r => Apache::Request->new(@args) }, $class;
}
sub header {
    my $self = shift;
    $self->send_http_header();
    return '';
}
1;
