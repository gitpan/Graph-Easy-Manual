#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 10;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy::Pod2HTML") or die($@);
   use_ok ("Graph::Easy") or die($@);
   };

can_ok ("Graph::Easy::Pod2HTML", qw/
  new
  go

  footer_contents
  css_file
  output_format
  /);

#############################################################################

my $parser = Graph::Easy::Pod2HTML->new();

is (ref($parser), 'Graph::Easy::Pod2HTML');

like ($parser->footer_contents(), qr/Generated.*Graph::Easy::Pod/, 'defaut footer');
is ($parser->footer_contents("foo"), "foo", 'user footer');

is ($parser->css_file(), "", 'default is no css file');
is ($parser->css_file(""), "", 'no CSS file');
is ($parser->css_file("my.css"), "my.css", 'my.css');
is ($parser->css_file(), "my.css", 'my.css');

