package Mojolicious::Plugin::Fondation::Devel::Controller::Registry;

# ABSTRACT: Development endpoint showing the Fondation plugin registry

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub registry ($c) {
    $c->render_later;
    my $manager  = $c->app->manager;
    my $registry = $manager->registry;

    my $clean = {};
    for my $long (keys %$registry) {
        my $entry = {%{$registry->{$long}}};
        if (exists $entry->{instance}) {
            $entry->{instance} = 'bless( ' . ref($entry->{instance}) . ' )';
        }
        $clean->{$long} = $entry;
    }

    $c->stash(
        title        => 'Fondation Registry',
        manager      => $manager,
        registry     => $clean,
        load_order   => $manager->load_order,
        fixture_sets => $manager->fixture_sets,
    );

    $c->render(template => 'devel/registry');
}

1;
