requires "Encode" => "0";
requires "Git::Repository" => "0";
requires "Mojolicious::Command::export" => "0.005";
requires "Mojolicious::Plugin::PODViewer" => "0";
requires "Yancy" => "1.035";
requires "Yancy::Backend::Static" => "0.004";
requires "perl" => "5.014";
requires "strict" => "0";
requires "warnings" => "0";
recommends "HTML::Lint::Pluggable" => "0.06";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Storable" => "0";
  requires "Test::More" => "1.001005";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'configure' => sub {
  suggests "JSON::PP" => "2.27300";
};
