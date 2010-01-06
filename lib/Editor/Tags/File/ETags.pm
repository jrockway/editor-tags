use MooseX::Declare;

class Editor::Tags::File::ETags with Editor::Tags::File {
    use Editor::Tags::Tag;
    use MooseX::Types::Path::Class qw(File);

    method _build_filename { 'TAGS' }

    method new_from_file($class: File $file does coerce){
        my $self = $class->new;
        local $/ = "\x0c\n";
        my $fh = $file->openr;
        while (my $chunk = <$fh>){
            my ($first, @rest) = split /\n/s, $chunk;
            my ($file, $len) = split /,/, $first;
            for my $line (@rest){
                next if $line !~ /\x{7f}/;
                my ($def, $name, $line, $offset) = split /(?:\x{7f}|\x{01}|,)/, $line;
                $self->add_tag(
                    Editor::Tags::Tag->new(
                        associated_file => $file,
                        definition      => $def,
                        name            => $name,
                        line            => $line,
                        offset          => $offset,
                    ),
                );
            }
        }
        return $self;
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
