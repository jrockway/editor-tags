use MooseX::Declare;

role Editor::Tags::File with Editor::Tags::Collection {
    use MooseX::FileAttribute;

    has_file 'tags_file' => (
        default => 'TAGS',
    );

    requires 'new_from_file';
    requires 'build_file_contents';

    method write_file {
        my $tags = $self->tags_file->openw;
        $tags->print($self->build_file_contents);
        $tags->close;
    }

};

1;
