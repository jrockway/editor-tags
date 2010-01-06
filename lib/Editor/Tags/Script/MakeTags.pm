use MooseX::Declare;

class Editor::Tags::Script::MakeTags with (MooseX::Runnable, MooseX::Getopt) {
    use MooseX::FileAttribute;

    use feature 'say';

    has_file 'output' => (
        default       => 'TAGS',
        documentation => 'file to write tags data to',
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
        my $format_class = sprintf('Editor::Tags::File::%s', $self->format);
        Class::MOP::load_class($format_class);
        return $format_class;
    }

    method _build_parser_class {
        my $parser_class = sprintf('Editor::Tags::Parser::%s', $self->parser);
        Class::MOP::load_class($parser_class);
        return $parser_class;
    }

    method _get_output_instance {
        return $self->output_class->new(
            file => $self->output,
        );
    }

    method run(@files) {
        my $output = $self->_get_output_instance;

        for my $file (@files){
            say "Parsing $file...";
            $output->add_tags(
                $self->parser_class->new_from_file($file)->tags,
            );
        }

        $output->write_file;
    }
}
