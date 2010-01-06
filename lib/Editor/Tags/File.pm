use MooseX::Declare;

role Editor::Tags::File with Editor::Tags::Collection {
    use MooseX::FileAttribute;

    has_file 'tags_file' => (
        builder => '_build_filename',
    );

    requires 'new_from_file';
    requires 'build_formatted_tag';

    method write_file {
        my $tags = $self->tags_file->openw;
        $tags->print($self->build_file_contents);
        $tags->close;
    }

    method build_file_contents {
        my $result;
        for my $file (sort $self->list_files){
            $result .= $self->build_one_file_block($file);
        }
        return $result;
    }

    method build_one_file_block(Str $file) {
        my $result;
        for my $tag (sort { $a->line <=> $b->line } @{$self->get_file_tags($file)}){
            $result .= $self->build_formatted_tag($tag);
        }
        return $result;
    }

};

1;
