use MooseX::Declare;

class Editor::Tags::File::ETags with Editor::Tags::File {
    use MooseX::Types::Path::Class qw(File);

    method new_from_file(File $filename? does coerce){
        die 'not implemented';
    }

    method build_file_contents {
        my $result;
        for my $file ($self->list_files){
            my $file_data;
            for my $tag (@{$self->get_file_tags($file)}){
                $file_data .= $tag->to_etag . "\n";
            }

            $result .= "\x0c\n";
            $result .= "$file,". length($file_data). "\n";
            $result .= $file_data;
        }
        return $result;
    }
}
