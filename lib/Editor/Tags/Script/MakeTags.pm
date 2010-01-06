use MooseX::Declare;

class Editor::Tags::Script::MakeTags with (MooseX::Runnable, MooseX::Getopt) {
    use MooseX::FileAttribute;

    use feature 'say';

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
        if ($format =~ /emacs|etags/i){
            $format = 'ETags';
        }
        elsif ($format =~ /vim?|ctags/i) {
            $format = 'CTags';
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
                tags_file => $self->output,
            );
        }
        else {
            return $self->output_class->new;
        }
    }

    method _get_parser_instance($file) {
        $self->parser_class->new_from_file($file);
    }

    method run(@files) {
        my $output = $self->_get_output_instance;
        local $| = 1;

        for my $file (@files){
            print "$file...";
            my $parser = $self->_get_parser_instance($file);
            my @tags = $parser->tags;
            $output->add_tags( @tags );
            print scalar @tags;
            say ".";
        }

        $output->write_file;
    }
}
