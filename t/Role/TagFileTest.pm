use MooseX::Declare;

role Test::Sweet::Meta::Test::Trait::NeedsOutputFile {
    before run($test_class, @args) {
        $test_class->ensure_file;
    }
}

role Test::Sweet::Meta::Test::Trait::WithParsedOutputFile with Test::Sweet::Meta::Test::Trait::NeedsOutputFile {
    around run($test_class, @args) {
        my $new = $test_class->file_class->new_from_file( $test_class->tags_file );
        return $self->$orig($test_class, $new, @args);
    }
}

role t::Role::TagFileTest with t::Role::WithTagCollection {
    use Test::Sweet;
    use Directory::Scratch;
    use MooseX::FileAttribute;

    # has '+collection' => ( does => 'Editor::Tags::File' );

    has 'tmp' => (
        is      => 'ro',
        isa     => 'Directory::Scratch',
        default => sub { Directory::Scratch->new },
        handles => ['exists'],
    );

    has_file 'tags_file' => (
        lazy_build => 1,
    );

    method _build_tags_file {
        my $tmp = $self->tmp;
        return "$tmp/TAGS";
    }

    requires 'file_class';

    method build_collection {
        return $self->file_class->new(
            tags_file => $self->tags_file,
        )
    }

    method ensure_file {
        $self->collection->write_file;
    }

    test file_written_ok(NeedsOutputFile) {
        ok -e $self->tags_file, 'tags file created ok';
        open my $fh, '<', $self->tags_file or die 'Failed to open tags file for reading';
        my $data = do { local $/; <$fh> };
        is $data, $self->collection->build_file_contents, 'data in file == return value of build_file_contents';
    }

    test roundtrip_ok(WithParsedOutputFile) {
        my $new = shift;
        is $new->build_file_contents, $self->collection->build_file_contents,
          'tags file round-trips identically';
    }

    requires 'compare_tags'; # (Tag $got, Tag $expected)

    test correct_tags_in_file(WithParsedOutputFile) {
        my $new = shift;
        my @expected_tags = $self->get_tags;
        my @found_tags = $new->tags;
        is scalar @found_tags, scalar @expected_tags, 'got expected number of tags';

        for my $expected (@expected_tags){
            my $got = $new->find_tag($expected->name);
            is $got->name, $expected->name, 'found tag named '. $got->name. ' ok';
            $self->compare_tags($got, $expected);
        }
    }
}

1;
