#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin;

use lib "$FindBin::Bin/../lib";

# ─── Create app with Fondation + Devel ────────────────────────────────────────

use Mojolicious::Lite;

app->mode('development');
app->log->level('error');

plugin 'Fondation' => {
    dependencies => ['Fondation::Devel'],
};

my $t = Test::Mojo->new;

# ─── 1. Plugin loaded ─────────────────────────────────────────────────────────

my $app = $t->app;
ok $app, 'app exists';

# ─── 2. Registry route is accessible ──────────────────────────────────────────

$t->get_ok('/fondation/registry')
  ->status_is(200, '/fondation/registry returns 200');

# ─── 3. Registry page content ─────────────────────────────────────────────────

$t->content_like(qr/Fondation Plugin Registry/, 'page title found');
$t->content_like(qr/Load order/,            'load order section found');
$t->content_like(qr/Plugin details/,        'plugin details section found');
$t->content_like(qr/Fondation::Devel/,      'Devel plugin listed');

done_testing;
