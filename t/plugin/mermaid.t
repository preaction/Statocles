
use Test::Lib;
use My::Test;
use Mojo::Log;
use Statocles::Plugin::Diagram::Mermaid;
use Statocles::Site;
use TestDeploy;
use Data::Dumper;

my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'mermaid basics' => sub {
  my $plugin = new_ok('Statocles::Plugin::Diagram::Mermaid', []);

  my $site = Statocles::Site->new(
      deploy => TestDeploy->new,
  );
  my $page = Statocles::Page::Plain->new(
      path => 'test.html',
      site => $site,
      content => '',
  );
  $plugin->register( $site );

  my $output = $plugin->mermaid({page => $page}, 'graph TD');
  is +Mojo::DOM->new($output)->at('div[class=mermaid]')->text, 'graph TD',
    'direct call functional';

  my ($script_ref, $javascript) = $page->links('script');
  is $script_ref->{href}, $plugin->mermaid_url, 'url match';
  like $javascript->{text}, qr/mermaid\.initialize/, 'javascript good';
};

subtest 'mermaid helper' => sub {
  my $plugin = new_ok('Statocles::Plugin::Diagram::Mermaid', []);
  my $site = Statocles::Site->new(
    plugins => { diagram => $plugin },
    deploy => TestDeploy->new,
  );
  my $graph = <<'END_OF_GRAPH';
graph TD
A[Christmas] -->|Get money| B(Go shopping)
B --> C{Let me think}
C -->|One| D[Laptop]
C -->|Two| E[iPhone]
C -->|Three| F[Car]
END_OF_GRAPH
  my $tmpl = $site->theme->build_template(
      test => <<EOF,
<%= diagram mermaid => begin %>
$graph
<% end %>
EOF
  );

  my $output = Mojo::DOM->new($tmpl->render);
  is $output->at('div[class=mermaid]')->text, "\n$graph", 'output has mermaids';
};

done_testing;
