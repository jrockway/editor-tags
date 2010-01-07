use strict;
use warnings;
use Test::More;

use Editor::Tags::Parser::Static::PPI;
use Directory::Scratch;
use Editor::Tags::Collection::Memory;

my $tmp = Directory::Scratch->new;
$tmp->touch(
    'Foo.pm',
    'use MooseX::Declare;',
    'class Foo {',
    '    method a { ... }',
    '    method b{ ... }',
    '    method A (Proto $type) { ... }',
    '    method B ($inv: $arg) { ... }',
    '};',
    'package Bar;',
    'sub c { ... }',
    'sub d{ ... }',
    'sub e(&@) { ... }',
    'sub f (&) { ... }',
    'sub g($){ ... }',
    '1;',
);

chdir $tmp;
my $parser = Editor::Tags::Parser::Static::PPI->new_from_file( 'Foo.pm' );
my @tags = $parser->tags;

is scalar @tags, 11, 'got correct number of tags (2 packages + 9 methods)';

# XXX: too lazy to check them all
my $set = Editor::Tags::Collection::Memory->new;
$set->add_tags(@tags);

is_deeply [$set->list_files], ['Foo.pm'], 'got files';

my $A = $set->find_tag('Foo::A');
ok $A, 'got Foo::A';
is $A->extra_info->{signature}, '(Proto $type)', 'got Foo::A prototype';
is $A->offset, 12, 'got Foo::A offset'; # the A in "method A"
is $A->line, 5, 'got Foo::A line';
is $A->associated_file, 'Foo.pm', 'got Foo::A file';
is $A->definition, '    method A', 'got Foo::A definition';

chdir '/';
done_testing;
