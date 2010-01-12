use strict;
use warnings;
use Test::More;

use Directory::Scratch;
use File::pushd;

use Editor::Tags::Script::MakeTags;
use Editor::Tags::File::ETags;
use Editor::Tags::Parser::Static::PPI;

my $tmp = Directory::Scratch->new;
my $scope = pushd($tmp->base);

$tmp->touch('lib/Foo.pm',
            'package Foo;',
            '',
            'use MooseX::Method::Signatures;',
            'use Moose;',
            '',
            'method oh_hai(You $person){',
            ' code_goes_here("perhaps");',
            '}',
            '',
            'sub not_a_method($) { warn "OH HAI @_" }',
            '',
            '1;',
        );


$tmp->touch('lib/Foo/Bar.pm',
            'use MooseX::Declare;',
            '',
            'class Foo::Bar with (A::Role, Or::Two) {',
            '    method oh_hai {',
            '       code_goes_here("perhaps");',
            '    }',
            '}',
        );

my $make_tags = Editor::Tags::Script::MakeTags->new(
    output => $tmp->base->file('TAGS'),
    format => 'ETags',
    parser => 'Static::PPI',
);

is $make_tags->run('lib/Foo.pm', 'lib/Foo/Bar.pm'), 0, 'no errors';

ok $tmp->exists('TAGS'), 'TAGS was created';

my $generated_tags = Editor::Tags::File::ETags->new_from_file(
    $tmp->exists('TAGS'),
);

ok $generated_tags, 'got Editor::Tags::File object from output';

my @files = $generated_tags->get_sorted_files;
is_deeply \@files, [qw{lib/Foo.pm lib/Foo/Bar.pm}], 'got files';

undef $scope;

done_testing;
