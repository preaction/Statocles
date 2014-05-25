
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "A static site generator",
  "AUTHOR" => "Doug Bell <preaction\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Statocles",
  "EXE_FILES" => [
    "bin/statocles"
  ],
  "LICENSE" => "perl",
  "NAME" => "Statocles",
  "PREREQ_PM" => {
    "Beam::Wire" => 0,
    "File::Basename" => 0,
    "File::Copy::Recursive" => 0,
    "File::Find" => 0,
    "File::Path" => 0,
    "File::Slurp" => 0,
    "File::Spec::Functions" => 0,
    "Git::Repository" => 0,
    "Import::Base" => 0,
    "Mojolicious" => 0,
    "Moo::Lax" => 0,
    "Pod::Usage::Return" => 0,
    "Text::Markdown" => 0,
    "YAML" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Cwd" => 0,
    "Dir::Self" => 0,
    "File::Temp" => 0,
    "Test::Compile" => 0,
    "Test::Most" => 0
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t t/app/*.t t/page/*.t t/site/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


