package CGI::Wiki::Formatter::Pod;

use strict;

use vars qw( $VERSION );
$VERSION = '0.02';

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
                       node_prefix           => 'wiki.cgi?node=',
                       usemod_extended_links => 0,
  );

C<node_prefix> is optional and defaults to the value shown above.

If C<usemod_extended_links> is supplied and true, then UseModWiki-style
extended links C<[[like this]]> will be supported - ie

  [[foo bar]]

will be translated into a link to the node named "Foo Bar".  (Node
names are forced to ucfirst, ie first letter of each word is capitalised.)

=cut

sub new {
    my ($class, %args) = @_;
    my $self = { };
    bless $self, $class;
    my $node_prefix = $args{node_prefix} || "wiki.cgi?node=";
    $self->{_node_prefix} = $node_prefix;
    $self->{_usemod_extended_links} = $args{usemod_extended_links} || 0;
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
    if ( $self->{_usemod_extended_links} ) {
        # Create link from [[foo bar]].
        $formatted =~ s/(\[\[[^\]]+\]\])/$self->_linkify($1)/egs;
    }
    return $formatted;
}

sub _linkify {
    my ($self, $node) = @_;
    require CGI::Wiki::Formatter::UseMod;
    my $formatter = CGI::Wiki::Formatter::UseMod->new(
        implicit_links => 0,
        extended_links => 1,
        node_prefix    => $self->{_node_prefix},
    );
    my $snippet = $formatter->format($1);
    # Snippet will be created as a paragraph, which we don't want as we're
    # inlining this.
    $snippet =~ s/^<p>//s;
    $snippet =~ s/<\/p>$//s;
    return $snippet;
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
