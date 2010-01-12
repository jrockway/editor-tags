use strict;
use warnings;
use Test::More;

use File::pushd;
use Directory::Scratch;
use Editor::Tags::Collection::Memory;
use Editor::Tags::Tag;

use Scalar::Util qw(refaddr);

plan skip_all => 'This test is probably broken on your OS, but the actual app should work fine'
  if $^O =~ /MSWin32|MacOS|VMS|NetWare/;

my $tmp = Directory::Scratch->new;
$tmp->touch('lib/Baz.pm');
$tmp->touch('lib/Quux.pm');

my $scope = pushd($tmp->base);

{
    my $col = Editor::Tags::Collection::Memory->new( relative_to => $tmp->base );
    my $baz = $col->add_tag(
        Editor::Tags::Tag->new(
            name            => 'Baz',
            associated_file => $tmp->exists('lib/Baz.pm')->absolute->stringify,
        ),
    );
    is $baz->associated_file, 'lib/Baz.pm', 'file was relative-ized ok';

    my $quux = $col->add_tag(
        Editor::Tags::Tag->new(
            name            => 'Quux',
            associated_file => 'lib/Quux.pm',
            line            => 1,
        ),
    );
    is $quux->associated_file, 'lib/Quux.pm', 'relative file is still relative';


    my $quux2 = $col->add_tag(
        Editor::Tags::Tag->new(
            name            => 'Quux::method',
            associated_file => $tmp->exists('lib/Quux.pm')->absolute->stringify,
            line            => 42,
        ),
    );
    is $quux2->associated_file, 'lib/Quux.pm', 'absolute to relative (same file) ok';

    ok $col->contains_tag($baz), 'collection contains baz';
    ok $col->contains_tag($quux), 'collection contains quux';
    ok $col->contains_tag($quux2), 'collection contains quux2';

    # make sure that the translation does not depend on the PWD
    for my $test_in ( $tmp->base, '/' ) {
        my $scope2 = pushd($test_in);

        is_deeply
          [$col->get_sorted_tags_for($tmp->exists('lib/Quux.pm'))],
          [$quux, $quux2],
            'correct tags are returned when passed an absolute File';

        is_deeply
          [$col->get_sorted_tags_for(Path::Class::file(qw/lib Quux.pm/))],
          [$quux, $quux2],
            'correct tags are returned when passed an relative File';

        is_deeply
          [$col->get_sorted_tags_for($tmp->exists('lib/Quux.pm')->stringify)],
          [$quux, $quux2],
            'correct tags are returned when passed an absolute filename';

        is_deeply
          [$col->get_sorted_tags_for('lib/Quux.pm')],
          [$quux, $quux2],
            'correct tags are returned when passed an relative filename';
    }

    $col->forget_file(Path::Class::file(qw/lib Baz.pm/));
    ok !$col->contains_tag($baz), 'baz was forgotten ok';

    $col->forget_file('lib/Quux.pm');
    ok !$col->contains_tag($quux), 'quux was also forgotten';
}

{
    my $col = Editor::Tags::Collection::Memory->new;
    my $baz = $col->add_tag(
        Editor::Tags::Tag->new(
            name            => 'Baz',
            associated_file => 'lib/Baz.pm',
        ),
    );
    is $baz->associated_file, 'lib/Baz.pm', 'filename is unchanged';

    my $quux = $col->add_tag(
        Editor::Tags::Tag->new(
            name            => 'Quux',
            associated_file => '/Quux.pm',
            line            => 1,
        ),
    );
    is $quux->associated_file, '/Quux.pm', 'absolute filename also unchanged';

    ok $col->contains_tag($baz), 'collection contains baz';
    ok $col->contains_tag($quux), 'collection contains quux';

    # make sure that the translation does not depend on the PWD
    for my $test_in ( $tmp->base, '/' ) {
        my $scope2 = pushd($test_in);

        is_deeply
          [$col->get_sorted_tags_for('/Quux.pm')],
          [$quux],
            'correct tags are returned';

        is_deeply
          [$col->get_sorted_tags_for('Quux.pm')],
          [],
            'no tags for non-file';


        is_deeply
          [$col->get_sorted_tags_for('lib/Baz.pm')],
          [$baz],
            'correct tags are returned';

        is_deeply
          [$col->get_sorted_tags_for('/lib/Baz.pm')],
          [],
            'no tags for non-file';
    }


    $col->forget_file(Path::Class::file(qw/lib Baz.pm/));
    ok !$col->contains_tag($baz), 'baz was forgotten ok';
    $col->forget_file(Path::Class::file('', 'Quux.pm'));
    ok !$col->contains_tag($quux), 'quux was also forgotten';
}

undef $scope;

done_testing;
