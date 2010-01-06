use MooseX::Declare;

class Editor::Tags::Script::Convert with (MooseX::Runnable, MooseX::Getopt){
    use MooseX::FileAttribute;

    use Editor::Tags::File::CTags;
    use Editor::Tags::File::ETags;

    has_file 'input' => (
        must_exist => 1,
        required   => 1,
    );

    method run {
        my ($in, $out);
        if ($self->input =~ /tags$/) {
            $in = Editor::Tags::File::CTags->new_from_file($self->input);
            $out = Editor::Tags::File::ETags->new;
        }
        else {
            $in = Editor::Tags::File::ETags->new_from_file($self->input);
            $out = Editor::Tags::File::CTags->new;
        }
        $out->add_tags( $in->tags );
        $out->write_file;
    }
}
