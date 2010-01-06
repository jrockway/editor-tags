use MooseX::Declare;

class Editor::Tags::Script::Update with (MooseX::Runnable, MooseX::Getopt) {
    use MooseX::FileAttribute;
    use Editor::Tags::File::ETags;
    use Editor::Tags::Parser::Static::PPI;

    use feature 'say';

    has_file 'tags_file' => (
        must_exist => 1,
        default    => 'TAGS',
    );

    method run(@files) {
        my $output = Editor::Tags::File::ETags->new_from_file($self->tags_file);
        local $| = 1;

        for my $file (@files){
            print "$file...";
            my $parser = Editor::Tags::Parser::Static::PPI->new( file => $file );
            my @tags = $parser->tags;

            $output->forget_file( $file );
            $output->add_tags( @tags );
            print scalar @tags;
            say ".";
        }

        $output->write_file;
    }
}
