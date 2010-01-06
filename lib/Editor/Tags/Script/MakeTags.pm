use MooseX::Declare;

class Editor::Tags::Script::MakeTags with (MooseX::Runnable, MooseX::Getopt) {
    use MooseX::FileAttribute;

    use Editor::Tags::Generate::Static::PPI;

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

    # has 'parser' => ...

    method run(@files) {
        my $output_class = sprintf('Editor::Tags::File::%s', $self->format);
        Class::MOP::load_class($output_class);

        my $output = $output_class->new(
            file => $self->output,
        );

        for my $file (@files){
            say "Parsing $file...";
            my $parser = Editor::Tags::Generate::Static::PPI->new(
                file => $file,
            );

            $output->add_tags( $parser->tags );
        }

        $output->write_file;
    }
}
