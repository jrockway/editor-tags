use MooseX::Declare;

role Editor::Tags::File with Editor::Tags::Collection {
    use MooseX::FileAttribute;
    use MooseX::Types::Path::Class qw(File);

    has_file 'tags_file' => (
        builder => '_build_filename',
    );

    requires 'parse_file'; # (File $file)
    requires 'build_formatted_tag'; # (Tag $tag)

    method new_from_file($class: File $file does coerce){
        my $self = $class->new( tags_file => $file );
        $self->parse_file($file);
        return $self;
    }

    method write_file() {
        my $tags = $self->tags_file->openw;
        $tags->print($self->build_file_contents);
        $tags->close;
    }

    method build_file_contents() {
        my $result;
        for my $file ($self->get_sorted_files){
            $result .= $self->build_one_file_block($file);
        }
        return $result;
    }

    method build_one_file_block(Str $file) {
        my $result;
        for my $tag ($self->get_sorted_tags_for($file)){
            $result .= $self->build_formatted_tag($tag);
        }
        return $result;
    }

};

1;
