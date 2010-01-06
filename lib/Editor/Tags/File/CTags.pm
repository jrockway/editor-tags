use MooseX::Declare;

class Editor::Tags::File::CTags with Editor::Tags::File {
    use Editor::Tags::Tag;
    use MooseX::Types::Path::Class qw(File);

    method _build_filename { 'tags' }

    method new_from_file($class: File $file does coerce){
        my $self = $class->new;
        my $fh = $file->openr;
        while(my $line = <$fh>){
            my ($name, $tag_file, $search) = split /\t/, $line;

            my $line_no = Scalar::Util::looks_like_number($search) ? $search : 0;
            my $definition = ($search =~ m{^/[\^](.+)\$?/$}) ? $1 : $search;
            warn "$name $tag_file $search $line_no $definition";
            $self->add_tag(
                Editor::Tags::Tag->new(
                    associated_file => $tag_file,
                    name            => $name,
                    line            => $line_no,
                    definition      => $definition,
                    offset          => ($definition =~ /^(\s+)/) ? length $1 : 0,
                ),
            );
        }
        return $self;
    }

    method build_file_contents {
        my $result;
        for my $tag (sort { $a->line <=> $b->line } @{$self->tags}){
            $result .= $tag->to_ctag . "\n";
        }
        return $result;
    }
}
