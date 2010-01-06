use MooseX::Declare;

class Editor::Tags::File::CTags with Editor::Tags::File {
    use MooseX::Types::Path::Class qw(File);

    method _build_filename { 'tags' }

    method new_from_file(File $filename? does coerce){
        die 'not implemented';
    }

    method build_file_contents {
        my $result;
        for my $file ($self->list_files){
            my $file_data;
            for my $tag (@{$self->get_file_tags($file)}){
                $result .= $tag->to_ctag . "\n";
            }
        }
        return $result;
    }
}
