package CGI::Wiki::Formatter::Pod;

use strict;

use vars qw( $VERSION );
$VERSION = '0.01';

use IO::Scalar;
use Pod::Tree::HTML;

=head1 NAME

CGI::Wiki::Formatter::Pod - A Pod to HTML formatter for CGI::Wiki.

=head1 DESCRIPTION

A Pod to HTML formatter backend for L<CGI::Wiki>.

=head1 SYNOPSIS

  my $store     = CGI::Wiki::Store::SQLite->new( ... );
  my $formatter = CGI::Wiki::Formatter::Pod->new;
  my $wiki      = CGI::Wiki->new( store     => $store,
                                  formatter => $formatter );

Go look at L<CGI::Wiki> to find out more. This module is distributed
separately solely for convenience of testing and maintenance; it's
probably not too useful on its own.

=head1 METHODS

=over 4

=item B<new>

  my $formatter = CGI::Wiki::Formatter::Pod->new(
                       node_prefix => 'wiki.cgi?node=' );

Takes one optional parameter, C<node_prefix>, which defaults to the
value shown above.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = { };
    bless $self, $class;
    my $node_prefix = $args{node_prefix} || "wiki.cgi?node=";
    $self->{_node_prefix} = $node_prefix;
    my $link_mapper = CGI::Wiki::Formatter::Pod::LinkMapper->new(
                                               node_prefix => $node_prefix );
    $self->{_link_mapper} = $link_mapper;
    return $self;
}

=item B<format>

  my $html = $formatter->format( $content );

Uses L<Pod::Tree::HTML> to translate the pod supplied in C<$content>
into HTML.  Links will be treated as links to other wiki pages.

=cut

sub format {
    my ($self, $raw) = @_;
    return "" unless $raw;
    my $source = \$raw;
    my $formatted;
    my $dest = IO::Scalar->new( \$formatted );
    my %options = ( link_map => $self->{_link_mapper} );
    my $html = Pod::Tree::HTML->new( $source, $dest, %options );
    $html->translate;
    $formatted =~ s/^.*<BODY[^>]*>//s;
    $formatted =~ s|</BODY>.*$||s;
    return $formatted;
}

=head1 SEE ALSO

L<CGI::Wiki>, L<Pod::Tree::HTML>.

=head1 AUTHOR

Kake Pugh (kake@earth.li), idea stolen from Matt Sergeant.  Many thanks to
Steven W McDougall for extending the capabilities of L<Pod::Tree::HTML> so
I could make this work.

=head1 COPYRIGHT

     Copyright (C) 2003 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


package CGI::Wiki::Formatter::Pod::LinkMapper;

sub new {
    my ($class, %args) = @_;
    my $self = { };
    bless $self, $class;
    $self->{_node_prefix} = $args{node_prefix} || "";
    return $self;
}

sub url {
    my ($self, $html, $target) = @_;
    my $page = $target->get_page;
    my $section = $target->get_section;
    if ( $page ) {
        $page = $self->{_node_prefix} . $html->escape_2396($page);
    }
    $section = $html->escape_2396($section);
    return $html->assemble_url("", $page, $section);
}

1;
