use MooseX::Declare;

class Editor::Tags::File::CTags with Editor::Tags::File {
    use Editor::Tags::Tag;
    use Editor::Tags::Types qw(Tag);
    use MooseX::Types::Path::Class qw(File);

    my $have_exuberant = eval { require Parse::ExuberantCTags; 1 };

    method _build_filename { 'tags' }

    method new_from_file($class: File $file does coerce){
        my $self = $class->new;

        if( $have_exuberant ) {
            my $parser = Parse::ExuberantCTags->new( $file->stringify );
            my $tag;
            while ( defined ( $tag = $parser->nextTag ) ){
                $tag->{extension}{file} = $tag->{fileScope} if exists $tag->{fileScope};
                $tag->{extension}{kind} = $tag->{kind}      if exists $tag->{kind};

                $self->add_tag(
                    Editor::Tags::Tag->new(
                        associated_file => $tag->{file},
                        name            => $tag->{name},
                        address_pattern => $tag->{addressPattern},
                        extra_info      => $tag->{extension},
                        ($tag->{addressLineNumber} ? (line => $tag->{addressLineNumber}) : ()),
                    ),
                );
            }
        }
        else {
            my $fh = $file->openr;
            while (my $line = <$fh>) {
                my ($name, $tag_file, $search) = split /\t/, $line;

                my $line_no = Scalar::Util::looks_like_number($search) ? $search : 0;
                my $definition = ($search =~ m{^/[\^](.+)\$?/$}) ? $1 : $search;

                $self->add_tag(
                    Editor::Tags::Tag->new(
                        associated_file => $tag_file,
                        name            => $name,
                        line            => $line_no,
                        definition      => $definition,
                        address_pattern => $search,
                        offset          => ($definition =~ /^(\s+)/) ? length $1 : 0,
                    ),
                );
            }
        }
        return $self;
    }

    method build_formatted_tag(ClassName|Object $class: Tag $tag) {
        my $pattern = $tag->address_pattern;
        my $result = join "\t", $tag->name, $tag->associated_file, qq{$pattern};
        return "$result\n";
    }
}
