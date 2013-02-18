package Teng::Plugin::CommonInflator;
use strict;
use warnings;
use 5.008_001;
use Carp qw/carp croak/;

our $VERSION = '0.01';
our @EXPORT = qw/add_common_inflator add_common_deflator/;

sub add_common_inflator {
    my $self = shift;

    _call_each_table($self, 'add_inflator', @_);
}

sub add_common_deflator {
    my $self = shift;

    _call_each_table($self, 'add_deflator', @_);
}

sub _call_each_table {
    my ($self, $method, @args) = @_;
    croak 'Odd number of elements in assignment.' if @args % 2;

    my ($rule, $code, $exclude);
    while (my ($key, $val) = splice @args, 0, 2) {
        if (ref($val) eq 'CODE') {
            $rule = $key;
            $code = $val;
        }
        elsif ($key eq 'exclude') {
            $val = [$val] unless ref $val;
            croak 'exclude value is invalid! (should be array_ref or scalar).' unless ref($val) eq 'ARRAY';
            $exclude = $val;
        }
        else {
            carp "unknown argument [$key].";
        }
    }
    croak '(in|de)flate rule is not specified!' unless $rule;

    if ( ref $rule ne 'Regexp' ) {
        $rule = qr/^\Q$rule\E$/;
    }
    my %exclude = map {($_ => 1)} @{$exclude || []};
    my $tables = $self->schema->tables;
    for my $table_name (keys %$tables) {
        next if $exclude{$table_name};

        my $table = $tables->{$table_name};
        next unless grep {/$rule/} @{$table->columns};
        $table->$method($rule => $code);
    }

    $self;
}

1;
__END__

=head1 NAME

Teng::Plugin::CommonInflator - Perl extention to do something

=head1 VERSION

This document describes Teng::Plugin::CommonInflator version 0.01.

=head1 SYNOPSIS

    package My::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('CommonInflator');

    package main;
    my $teng = My::DB->new;

    $teng->add_common_inflator(
        qr/_at$/ => sub {
            my $col_value = shift;
            ...
            $col_value;
        },
        exclude => [qw/user/], # exclude tables
    );

    $teng->add_common_deflator(qr/_at$/ => sub {
        my $col_value = shift;
        ...
        $col_value;
    });


=head1 DESCRIPTION

# TODO

=head1 INTERFACE

=head2 Functions

=head3 C<< hello() >>

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Masayuki Matsuki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
