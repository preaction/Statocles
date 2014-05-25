
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "A static site generator",
  "dist_author" => [
    "Doug Bell <preaction\@cpan.org>"
  ],
  "dist_name" => "Statocles",
  "dist_version" => "0.003",
  "license" => "perl",
  "module_name" => "Statocles",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
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
  "script_files" => [
    "bin/statocles"
  ],
  "share_dir" => {
    "dist" => "share"
  },
  "test_requires" => {
    "Cwd" => 0,
    "Dir::Self" => 0,
    "File::Temp" => 0,
    "Test::Compile" => 0,
    "Test::Most" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
