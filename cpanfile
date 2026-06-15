# CPAN dependencies for Mojolicious-Plugin-Fondation-Devel

# Minimum Perl version required (for Mojolicious signatures feature)
requires 'perl' => '5.026';

# Runtime dependencies
requires 'Mojolicious::Plugin::Fondation', '>= 0.02';

# Testing dependencies
on test => sub {
    requires 'Test::More' => '1.00';
    requires 'Test::Mojo' => '0';
};

# Development dependencies (for author)
on develop => sub {
    recommends 'Perl::Critic' => '1.00';
    recommends 'Perl::Tidy' => '20200000';
    recommends 'Pod::Checker' => '1.00';
};
