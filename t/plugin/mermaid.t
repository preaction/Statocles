
use Test::Lib;
use My::Test;
use Mojo::Log;
use Statocles::Plugin::Diagram::Mermaid;
use Statocles::App::Basic;
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

  my $output = $plugin->mermaid({page => $page}, 'graph TD');
  is +Mojo::DOM->new($output)->at('div[class=mermaid]')->text, 'graph TD',
    'direct call functional';

  my ($script_ref, $javascript) = $page->links('script');
  is $script_ref->{href}, $plugin->mermaid_url, 'url match';
  like $javascript->{text}, qr/mermaid\.initialize/, 'javascript good';
};

subtest 'mermaid helper' => sub {
  my $plugin = new_ok('Statocles::Plugin::Diagram::Mermaid', []);
  my $site = build_test_site(
    plugins => { diagram => $plugin }
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

subtest 'mermaid site' => sub {
  my $plugin = new_ok 'Statocles::Plugin::Diagram::Mermaid', [];
  my $app = new_ok 'Statocles::App::Basic', [
    store => $SHARE_DIR->child( qw( app basic-diagrams ) ),
    url_root => '/',
    ];
  my $site = build_test_site(
      theme => $SHARE_DIR->child( 'theme' ),
      apps => {
        basic => $app,
        },
      plugins => {
          diagram => $plugin,
      }
  );

  test_pages( $site, $app,
    '/gantt.html' => sub {
      my ($html, $dom) = @_;
      ok +(grep { $_->attr('src') && $_->attr('src') =~ m/mermaid\.min\.js/ } $dom->find('script')->each),
        'script included';
      is $dom->find('div[class=mermaid]')->size, 1, 'dom query for diagram';
    },
    '/index.html' => sub {
      my ($html, $dom) = @_;
      is $dom->find('div[class=mermaid]')->size, 1, 'dom query for diagram';
      like $dom->at('div[class=mermaid]')->text, qr/end$/m, 'div content';
    },

  );

};

done_testing;
