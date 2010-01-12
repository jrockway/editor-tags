use MooseX::Declare;

role t::Role::WithTagCollection {
    use Editor::Tags::Collection;

    requires 'build_collection';

    has 'collection' => (
        is         => 'ro',
        does       => 'Editor::Tags::Collection',
        lazy_build => 1,
    );

    method _build_collection {
        my $collection = $self->build_collection;
        $self->populate_tags($collection);
        return $collection;
    }

    method populate_tags($collection) {
        $collection->add_tags($self->get_tags);
    }

    method get_tags {
        return (
            Editor::Tags::Tag->new(
                associated_file => 'Foo.pm',
                name            => 'Foo',
                definition      => 'package Foo;',
                line            => 1,
                offset          => 0,
            ),
            Editor::Tags::Tag->new(
                associated_file => 'Foo.pm',
                name            => 'Foo::function',
                definition      => 'sub function',
                line            => 2,
                offset          => 0,
            ),
            Editor::Tags::Tag->new(
                associated_file => 'Bar.pm',
                name            => 'Bar',
                definition      => '    package Bar;',
                line            => 2,
                offset          => 4,
            ),
            Editor::Tags::Tag->new(
                associated_file => 'Complex.pm',
                name            => 'complex',
                definition      => '    method complex',
                line            => 3,
                offset          => 4,
                extra_info      => {
                    kind      => 'method',
                    access    => 'public',
                    signature => '(Proto $type)',
                },
            ),
        );
    }
}
