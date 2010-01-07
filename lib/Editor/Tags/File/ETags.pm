use MooseX::Declare;

class Editor::Tags::File::ETags {
    use Editor::Tags::Tag;
    use Editor::Tags::Types qw(Tag);
    use MooseX::Types::Path::Class qw(File);

    method _build_filename { 'TAGS' }

    method parse_file(File $file){
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
    }

    method build_formatted_tag(ClassName|Object $class: Tag $tag){
        my $result = $tag->definition . "\x{7f}". $tag->name. "\x{01}". $tag->line. ','. $tag->offset;
        return "$result\n";
    }

    with 'Editor::Tags::File';

    around build_one_file_block(Str $file){
        my $block = $self->$orig($file);
        return "\x0c\n$file,". length($block)."\n$block";
    }
}
