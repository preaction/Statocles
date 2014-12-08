requires "Beam::Wire" => "0";
requires "Encode" => "0";
requires "File::Copy::Recursive" => "0";
requires "File::Share" => "0";
requires "Git::Repository" => "0";
requires "Import::Base" => "0";
requires "List::MoreUtils" => "0";
requires "Memoize" => "0";
requires "Mojolicious" => "4.76";
requires "Moo::Lax" => "0";
requires "Path::Tiny" => "0.054";
requires "Pod::Usage::Return" => "0";
requires "Text::Markdown" => "0";
requires "Time::Piece" => "0";
requires "Type::Tiny" => "0";
requires "Types::Path::Tiny" => "0";
requires "YAML" => "0";
requires "perl" => "5.010";
requires "strict" => "0";
requires "warnings" => "0";
recommends "PPI" => "0";
recommends "Pod::Elemental" => "0";
recommends "Pod::Weaver" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.3601";
};

on 'test' => sub {
  requires "Capture::Tiny" => "0";
  requires "Dir::Self" => "0";
  requires "Test::Compile" => "0";
  requires "Test::Deep" => "0";
  requires "Test::Differences" => "0";
  requires "Test::Exception" => "0";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::ShareDir::Install" => "0.06";
  requires "Module::Build" => "0.3601";
};
