#############################################################################
# Convert pod with =begin graph/=end graph paragraphs as HTML.
#
# (c) by Tels 2005.
#############################################################################

package Graph::Easy::Pod2HTML;

use 5.006001;
require Exporter;
use Pod::Simple::XHTML;
use Graph::Easy;
use Graph::Easy::Parser;
use strict;
use vars qw/$VERSION @ISA @EXPORT_OK/;

@ISA = qw/Pod::Simple::XHTML Exporter/;
@EXPORT_OK = qw/go/;

$VERSION = '0.04';

BEGIN { $|++; }

#############################################################################

sub new
  {
  my $class = shift;
  
  my $self = $class->SUPER::new(@_);

  $self->accept_targets(qw/ graph graph-common /);

  # our own namespace to store stuff under
  $self->{_graph} = {}; my $g = $self->{_graph};

  # reusable parser object for the graph paragraphs
  $g->{parser} = Graph::Easy::Parser->new();

  $g->{id} = ''; 		# counting ID for each graph (first one is empty)
  $g->{state} = 0;		# 0: outside graph, 1: graph, 2: common parts
  $g->{common} = '';		# no common texts as default
  $g->{css} = '';		# start with empty CSS
  $g->{css_file} = '';		# no CSS file for now
  $g->{menulinks} = [];		# no menu links for now

  $g->{format} = 'html';	# default is 'html' only

  # set default footer contents
#  $self->footer_contents(
#   "Generated at " . scalar localtime() . " by " . __PACKAGE__ . " v$VERSION");

  $self;
  }

#############################################################################
# customizations:

# This handles =begin and =for blocks of all kinds.
sub start_for
  {
  my ($self, $flags) = @_;

  my $g = $self->{_graph};

  if ($flags->{target} eq 'graph')
    {
    $g->{parser}->reset();
    $g->{state} = 1;					# in graph
    }
  elsif ($flags->{target} eq 'graph-common')
    {
    $g->{state} = 2;
    }
  else
    {
    $self->SUPER::start_for($flags);
    }
  }

sub handle_text 
  {
  my ($self, $text) = @_;
  
  my $g = $self->{_graph};
  if ($g->{state} == 0)
    {
    # not a graph- paragraph
    $self->{scratch} .= $text;
    }
  else
    {
    if ($g->{state} == 2)
      {
      $g->{common} = $text."\n";	# store for later usage
      }
    else
      {
      my $parser = $g->{parser};
      my $graph = $parser->from_text( $g->{common} . $text );

      if ($parser->error())
	{
        $self->{scratch} = '<span class="error">Parser error: ' . $parser->error() . "</span>\n";
        }
      elsif ($graph->error())
	{
        $text = '<span class="error">Graph error: ' . $graph->error() . "</span>\n";
	}
      else
        {
        # give graph the running ID
        $graph->id( $g->{id} );

	$g->{css} .= $graph->css();

        foreach my $format (split /,/, $g->{format})
          {
          if ($format eq 'src')
            {
            $self->{scratch} .= "<pre style='float: left;' class='graph'>\n" . $text . "</pre>";
            }
          else
	    {
	    my $method = 'as_' . $format;
	    $method .= '_html' if $format =~ /^(ascii|boxart)\z/;	# ascii => as_ascii_html()
	    $self->{scratch} .= $graph->$method() . "\n<div class='clear'></div>\n"
	      if $graph->can($method);
	    }
	  }
	}
      $g->{id}++; 				# next graph get's a new ID
      }
    $g->{state} = 0;				# reset state
    }
  }

sub footer_contents
  {
  # get/set the contents of the footer paragraph. Pass '' to disable footer box.
  my $self = shift;
  my $footertext = shift;

  if (defined $footertext)
    {
    $self->{_graph}->{footertext} = $footertext;

    my $footer;

    if ($footertext eq '')
      {
      $footer = <<EOF3

  </div>

  </div> <!-- end right side -->
  <!-- end doc -->
</body></html>
EOF3
      ;
      }
    else
      {
    $footer = <<EOF3

  </div>

  <div class="footer">
  ##footer##
  </div>

  </div> <!-- end right side -->
  <!-- end doc -->
</body></html>
EOF3
      ;

      $footer =~ s/##footer##/$footertext/;
      }
    $self->html_footer($footer);
    }

  $self->{_graph}->{footertext};
  }

sub css_file
  {
  # Get/set an additional (optional) CSS file. Set to '' to disable
  my $self = shift;

  $self->{_graph}->{css_file} = $_[0] if defined $_[0];
  $self->{_graph}->{css_file};
  }

sub output_format
  {
  my $self = shift;

  my $g = $self->{_graph};

  $g->{format} = shift if $_[0];
  $g->{format};
  }

#############################################################################
#############################################################################

sub html_css
  {
  # return the accumulated CSS code
  my $self = shift;

  my $css_file = $self->css_file() || '';

  my $css = '';
  $css = ' <link rel="stylesheet" type="text/css" href="' . "$css_file\">\n"
    if $css_file ne ''; 

  # insert a marker so that we can later insert the real accumulated CSS:
  $css . " <style type='text/css'><!--\n" .
         "##CSS_CODE##" .
         " --> </style>"; 
  }

sub _create_TOC
  {
  my $self = shift;

  my $g = $self->{graph};

  # insert the menu links into the menu
  my $menu_tpl = '  <p class="menuext"><a class="menuext" href="##FILE##" title="##TITLE##">##NAME##</a></p>';

  my $menu = '';
  if (@{ $g->{menulinks} } > 0)
    {
    $menu = "<div class='menu'>\n\n";
    foreach my $bl (@{ $g->{menulinks} })
      {
      my ($name,$file,$title) = @$bl;
      my $m = $menu_tpl;
      $title = $name unless defined $title;

      $m =~ s/##FILE##/$file/g;
      $m =~ s/##TITLE##/$title/g;
      $m =~ s/##NAME##/$name/g;
      $menu .= "$m\n";
      }
    $menu .= "\n  </div>\n\n  <div class='right'>\n";

    }

# $g->{output_string} =~ s/##MENU##/$menu/;
#
# print STDOUT $g->{output_string};
  }

sub add_menulink
  {
  my $self = shift;
  my $menulink = shift || '';

  return unless $menulink ne '';

  push @{$self->{_graph}->{menulinks}}, [ split /\|/, $menulink ];
  }

sub go
  {
  my $self = __PACKAGE__->new();

  $self->parse_from_file(@_);
  }

1;
__END__
=head1 NAME

Graph::Easy::Pod2HTML - Render pod with graph code as HTML

=head1 SYNOPSIS

	perl -MGraph::Easy::Pod2HTML=go -e 'go thingy.pod'
	
=head1 DESCRIPTION

C<Graph::Easy::Pod2HTML> uses L<Pod::Simple::XHTML> to render POD
as HTML. In addition to Pod::Simple::XHTML, it also handles paragraphs
of the type C<graph> like shown here:

	=for graph [ A ] => [ B ]

	=begin graph

	 [ A ] => [ B ] -> [ C ]
	 [ C ] => [ D ]

	=end graph

In addition to C<graph> code, you can also use C<graph-common> to
store graph code that should be common to all following graphs.
Each C<graph-common> paragraph will replace the former definition:

	This graph will have default settings:

	=for graph [ A ] => [ B ]

	Store now a different background color:

	=begin graph-common

	graph { background: #deadff; }
	node { background: #fff000; }

	=end graph-common

	This graph will use the common part defined above:

	=for graph [ A ] => [ B ]

	This will replace the common parts with only a
	blue background for nodes:

	=for graph-common node { background: blue; }

	So this graph will have blue nodes:

	=for graph [ A ] => [ B ]

More info about the graph code can be found at L<http://bloodgate.com/perl/graph/>.

=head1 METHODS

=head2 new()

	$converter = Graph::Easy::Pod2HTML->new();

Creates a new converter object, which takes pod and emit's HTML.

=head2 go()

	$conveter->go( $filename );

Parse C<$filename> and emit HTML on STDOUT.

=head1 CUSTOMIZATION

The following methods can be used to customize the appearance and the
contents of the output of C<Graph::Easy::Pod2HTML>:

=head2 footer_contents

	$footer = $converter->footer_contents();	# query
	$converter->footer_contents('');		# disable
	$converter->footer_contents('Hello HTML!');	# set

This method let's you decide whether you want a final footer paragraph,
or not, and what it should contain. The default is a timestamp and the
version of C<Graph::Easy> and C<Graph::Easy::Pod2HTML> used to generate
the document.

=head2 css_file

	$converter->css_file('');			# none
	$converter->css_file('base.css');		# base.css

This method can be used to set the name of an external stylesheet file
that should be linked from the generated document.

=head1 EXPORT

Exports nothing, but can export C<go()> on request.

=head1 SEE ALSO

L<Graph::Easy>, L<Pod::Simple>.

More info about the graph code can be found at L<http://bloodgate.com/perl/graph/>.

=head1 AUTHOR

Copyright (C) 2005 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
