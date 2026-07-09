package Mojolicious::Plugin::Fondation::Devel::Controller::Graph;

# ABSTRACT: Dependency graph visualization using Mermaid.js

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub graph ($c) {
    my $api      = $c->fondation;
    my $registry = $api->registry;
    my @load     = @{$api->load_order};

    my %ids;
    my $next_id = 0;

    my @lines;
    my %seen;

    for my $long (@load) {
        my $entry  = $registry->{$long} or next;
        my $config = $entry->{config}         // {};
        my $meta   = $entry->{fondation_meta} // {};
        my $short  = $entry->{short_name}     // $long;

        my $key   = _short($short);
        my $id    = $ids{$key} //= 'P' . $next_id++;
        my $label = $key;

        # dependencies (solid arrow)
        my $deps = [ @{ $config->{dependencies} // [] },
                     @{ $meta->{dependencies}   // [] } ];
        for my $dep (@$deps) {
            my $d = _short(_dep_name($dep));
            $ids{$d} //= 'P' . $next_id++;
            next if $seen{"$id-->$ids{$d}"}++;
            push @lines, qq{    $id\["$label"\] --> $ids{$d}\["$d"\]};
        }

        # after — dashed arrow to target
        my $after = [ @{ $config->{after} // [] },
                      @{ $meta->{after}   // [] } ];
        for my $t (@$after) {
            my $tn = _short($t);
            $ids{$tn} //= 'P' . $next_id++;
            next if $seen{"$id-.->$ids{$tn}"}++;
            push @lines, qq{    $id\["$label"\] -.-> $ids{$tn}\["$tn"\]};
        }

        # before — dashed arrow from target
        my $before = [ @{ $config->{before} // [] },
                       @{ $meta->{before}   // [] } ];
        for my $t (@$before) {
            my $tn = _short($t);
            $ids{$tn} //= 'P' . $next_id++;
            next if $seen{"$ids{$tn}-.->$id"}++;
            push @lines, qq{    $ids{$tn}\["$tn"\] -.-> $id\["$label"\]};
        }
    }

    my $mermaid = "graph TD\n" . join("\n", @lines) . "\n";

    $c->stash(
        title   => 'Plugin Dependency Graph',
        mermaid => $mermaid,
    );

    $c->render(template => 'devel/graph');
}

sub _short ($name) {
    $name =~ s/^Mojolicious::Plugin:://;
    $name =~ s/^Fondation:://;
    return $name;
}

sub _dep_name ($spec) {
    return $spec unless ref $spec eq 'HASH';
    my ($name) = keys %$spec;
    return $name;
}

1;
