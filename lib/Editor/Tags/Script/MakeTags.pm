use MooseX::Declare;

class Editor::Tags::Script::MakeTags
  with (MooseX::Runnable, MooseX::Getopt, Editor::Tags::Script::Role::TagFileGenerator) {
    use feature 'say';

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
        return 0;
    }
}
