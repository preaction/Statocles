requires "Beam::Emitter" => "0.007";
requires "Beam::Wire" => "1.014";
requires "Encode" => "0";
requires "File::Share" => "0";
requires "Git::Repository" => "0";
requires "Import::Base" => "0.012";
requires "List::UtilsBy" => "0.09";
requires "Mojolicious" => "6.0";
requires "Moo" => "2.000001";
requires "Path::Tiny" => "0.072";
requires "Pod::Simple" => "3.31";
requires "Pod::Usage::Return" => "0";
requires "Text::Markdown" => "0";
requires "Time::Piece" => "0";
requires "Type::Tiny" => "0";
requires "Types::Path::Tiny" => "0";
requires "YAML" => "0";
requires "perl" => "5.010";
requires "strict" => "0";
requires "warnings" => "0";
recommends "HTML::Lint::Pluggable" => "0.06";
recommends "PPI" => "0";
recommends "Pod::Elemental" => "0";
recommends "Pod::Weaver" => "0";
recommends "Syntax::Highlight::Engine::Kate" => "0";

on 'test' => sub {
  requires "Capture::Tiny" => "0";
  requires "Dir::Self" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Storable" => "0";
  requires "Test::Deep" => "0";
  requires "Test::Differences" => "0";
  requires "Test::Exception" => "0";
  requires "Test::Lib" => "0";
  requires "Test::More" => "1.001005";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::ShareDir::Install" => "0.06";
};
