
use Test::Lib;
use My::Test;
use Mojo::Log;
use Statocles::Plugin::Diagram::Mermaid;
use Data::Dumper;

my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'mermaid basics' => sub {
  my $plugin = new_ok('Statocles::Plugin::Diagram::Mermaid', []);

  my $site = build_test_site();
  my $page = Statocles::Page::Plain->new(
      path => 'test.html',
      site => $site,
      content => '',
  );
  $plugin->register( $site );

  $plugin->mermaid({page => $page});

  my ($script_ref, $javascript) = $page->links('script');
  is $script_ref->{href}, $plugin->mermaid_url, 'url match';
  like $javascript->{text}, qr/mermaid\.initialize/, 'javascript good';
};

subtest 'mermaid helper' => sub {

  ok 1;
};

done_testing;
