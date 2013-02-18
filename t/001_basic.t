use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use Time::Piece;
use Teng::Schema::Loader;

{
    package My::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('CommonInflator');
}

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1, AutoCommit => 1});
$dbh->do(q{CREATE TABLE user (id integer primary key, name, updated_at)});
$dbh->do(q{CREATE TABLE book (id, title, created_at)});
$dbh->do(q{CREATE TABLE station (id, name)});

my $format   = '%Y-%m-%d %H:%M:%S';
my $date_str = '2000-01-01 10:10:10';
$dbh->do(qq{
    INSERT INTO user (id, name, updated_at)
    VALUES
        (1, 'user1', '$date_str')
});

my $teng = Teng::Schema::Loader->load(dbh => $dbh, namespace => 'My::DB');

subtest method_plugged => sub {
    ok $teng->can('add_common_inflator');
    ok $teng->can('add_common_deflator');
};

my $user = $teng->schema->get_table('user');
my $book = $teng->schema->get_table('book');
my $station = $teng->schema->get_table('station');

subtest add_common_inflator => sub {
    $teng->add_common_inflator(qr/_at$/ => sub {
        my $col_value = shift;
        $col_value && Time::Piece->strptime($col_value, $format);
    });

    is $user->has_inflators, 2;
    is $book->has_inflators, 2;
    is $station->has_inflators, 0;
};

subtest inflate_correctly => sub {
    my $user_row = $teng->single(user => {id => 1});
    my $updated_at = $user_row->updated_at;
    isa_ok $updated_at, 'Time::Piece';
    is $updated_at->strftime($format), $date_str;
};

subtest exclude => sub {
    $teng->add_common_inflator(
        qr/_at$/ => sub {
            shift;
        },
        exclude => 'user',
    );
    is $user->has_inflators, 2;
    is $book->has_inflators, 4;
    is $station->has_inflators, 0;
};

subtest add_common_deflator => sub {
    $teng->add_common_deflator(qr/_at$/ => sub {
        my $col_value = shift;

        $col_value = $col_value->strftime($format) if ref $col_value && $col_value->isa('Time::Piece');
        $col_value;
    });

    is $user->has_deflators, 2;
    is $book->has_deflators, 2;
    is $station->has_deflators, 0;
};

subtest deflate_correctly => sub {
    my $user_row = $teng->single(user => {id => 1});

    my $now = localtime;
    my $now_str = $now->strftime($format);

    ok $user_row->update({
        updated_at => $now,
    });
    is $user_row->get_column('updated_at'), $now_str;
};

done_testing;
