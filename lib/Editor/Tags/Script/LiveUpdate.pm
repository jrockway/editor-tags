use MooseX::Declare;

class Editor::Tags::Script::LiveUpdate
  with (MooseX::Runnable, MooseX::Getopt, Editor::Tags::Script::Role::TagFileGenerator) {
    use MooseX::FileAttribute;
    use File::pushd;
    use EV;
    use AnyEvent::Inotify::Simple;

    use 5.010;

    has_directory 'project' => (
        must_exist => 1,
        default    => '.',
    );

    method find_perl {
        my $p = pushd $self->project;
        my @result = `find lib t -name *.pm -type f`;
        chomp @result;
        return map { Path::Class::file($_) } @result;
    }

    method parse_file($output, $file){
        local $| = 1;
        print "$file...";
        my $parser = $self->_get_parser_instance($file);
        my @tags = $parser->tags;
        $output->add_tags( @tags );
        print scalar @tags;
        say ".";
    }

    method run {
        my @files = $self->find_perl;
        my $output = $self->_get_output_instance;
        for my $file (@files) { $self->parse_file($output, $file) };
        $output->write_file;
        say "Waiting...";

        my $notify = AnyEvent::Inotify::Simple->new(
            directory      => $self->project,
            event_receiver => sub {
                my ($event, $file, @rest) = @_;
                $file = $file->relative($self->project);
                return if $event ~~ [qw/open close attribute_change access/];
                return if $file =~ /TAGS/; # wrong.
                given($event){
                    when('modify'){
                        $output->forget_file($file->stringify);
                        $self->parse_file($output, $file->stringify);
                        $output->write_file;
                    }
                    when('delete'){
                        $output->forget_file($file->stringify);
                        $output->write_file;
                    }
                    when('create'){
                        $self->parse_file($output, $file->stringify);
                        $output->write_file;
                    }
                    when('move'){
                        my $dest = $rest[0];
                        $dest = $dest->relative($self->project);
                        $output->forget_file($file->stringify);
                        $self->parse_file($output, $dest->stringify);
                        $output->write_file;
                    }
                    default {
                        warn "$event on $file (@rest)";
                    }
                }
            },
        );

        EV::loop;
    }
}
