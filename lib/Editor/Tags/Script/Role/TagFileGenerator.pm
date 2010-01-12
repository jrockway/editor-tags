use MooseX::Declare;

role Editor::Tags::Script::Role::TagFileGenerator {
    use MooseX::FileAttribute;

    use feature qw/switch/;

    has_file 'output' => (
        documentation => 'file to write tags data to (defaults to "TAGS" for etags or "tags" for ctags)',
        predicate     => 'has_output_file',
    );

    has 'format' => (
        is            => 'ro',
        isa           => 'Str',
        default       => 'ETags',
        documentation => 'format of tags file to write (default: ETags)',
    );

    has 'parser' => (
        is            => 'ro',
        isa           => 'Str',
        default       => 'Static::PPI',
        documentation => 'parser class to use for parsing Perl files (default: Static::PPI)',
    );

    has [qw/output_class parser_class/] => (
        traits     => ['NoGetopt'],
        is         => 'ro',
        isa        => 'ClassName',
        lazy_build => 1,
    );

    method _build_output_class {
        my $format = $self->format;
        given($format){
            when(/^(emacs|etags)$/i){
                $format = 'ETags';
            }
            when(/^(vim?|ctags)$/i){
                $format = 'CTags';
            }
            when(/^exuberant$/i){
                $format = 'ExuberantCTags';
            }
        }

        my $format_class = sprintf('Editor::Tags::File::%s', $format);
        Class::MOP::load_class($format_class);
        return $format_class;
    }

    method _build_parser_class {
        my $parser_class = sprintf('Editor::Tags::Parser::%s', $self->parser);
        Class::MOP::load_class($parser_class);
        return $parser_class;
    }

    method _get_output_instance {
        if($self->has_output_file){
            return $self->output_class->new(
                tags_file   => $self->output,
                relative_to => Path::Class::dir('.')->absolute,
            );
        }
        else {
            return $self->output_class->new;
        }
    }

    method _get_parser_instance($file) {
        $self->parser_class->new_from_file($file);
    }
}
