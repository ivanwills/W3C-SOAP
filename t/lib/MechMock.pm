package MechMock;

use strict;
use warnings;
use parent qw/WWW::Mechanize/;

sub post {
    return;
}

my $content;
sub content {
    my ($self, $text) = @_;
    $content = $text if @_ > 1;
    return $content;
}

1;
