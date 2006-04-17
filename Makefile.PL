use 5.008000;
use ExtUtils::MakeMaker;
use strict;

sub MY::metafile {
  package MY;
  my $self = shift;
  if (!eval { require YAML; 1 })
  {
    warn ("YAML not installed, 'make dist' will not override 'META.yml'.");
    return $self->SUPER::metafile_target(@_);
  };

  require YAML::Node;
  my $node = YAML::Node->new({});

  $node->{name}                 = $self->{DISTNAME};
  $node->{version}              = $self->{VERSION};
  $node->{version_from}         = $self->{VERSION_FROM};
  $node->{license}              = 'gpl';
  $node->{distribution_type}    = 'module';
  $node->{generated_by}         = "$self->{DISTNAME} version $self->{VERSION}";
  $node->{installdirs}          = 'site';
  $node->{requires}             = $self->{PREREQ_PM};

  my $dump = YAML::Dump( $node );

  $dump =~ s/^(.*)$/\t\$(NOECHO) \$(ECHO) "$1" >>META.yml/gm;
  $dump =~ s/>>META\.yml/>META.yml/;

  return "metafile:\n$dump";
}

WriteMakefile(
    NAME		=> 'Graph::Easy::Manual',
    VERSION_FROM	=> 'lib/Graph/Easy/Manual.pm',
    PREREQ_PM		=> {
	'Graph::Easy' => 0.44,
	'File::Spec' => 3.01,
	'Pod::Simple' => 3.02,
#	'HTML::Tagset' => 3.10,
#	'HTML::Parser' => 3.48,
	},
    ABSTRACT_FROM	=> 'lib/Graph/Easy/Manual.pm', 	# retrieve abstract from module
    AUTHOR		=> 'Tels <nospam-abuse@bloodgate.com>',
    PREREQ_FATAL	=> 1,	# can't work without the prereqs
);
