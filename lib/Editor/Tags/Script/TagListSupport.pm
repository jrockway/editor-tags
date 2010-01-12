use MooseX::Declare;

# TagList is a Vim plugin that claims to support ctags, but does not
# actually understand the content.  It also can't read tags from a
# file; only from stdin.  So this app runs in the background, accepts
# a request (via pclient) for a file's tags, and prints the result.
# (Oh, and if the tags aren't in exactly the right format, TagList
# totally ignores the tag.  Because it's fucking dumb.)
#
# Emacs' Speedbar can handle a tag file for your entire project, but
# that's because smart people use Emacs.  (It also doesn't whine when
# the TAGS file is changed out from under it; it just silently uses
# the new data.  It's like someone with a brain designed it...)

class Editor::Tags::Script::TagListSupport
  with (MooseX::Runnable, MooseX::Getopt) {

    use App::Persistent::Server;

    with 'Editor::Tags::Script::Role::TagFileGenerator';

    has '+format' => ( default => 'ExuberantCTags' );

    method run {

        # preload the classes
        $self->_get_output_instance;
        $self->_get_parser_instance('/dev/null');

        my $server = App::Persistent::Server->new(
            name => 'taglist',
            code => sub {
                my $c = shift;
                chdir $c->working_directory;
                my @files = $c->cmdline_args;

                my $output = $self->_get_output_instance;
                for(@files){
                    my $parser = $self->_get_parser_instance($_);
                    $output->add_tags( $parser->tags );
                    print $output->build_file_contents, "\n";
                }

                return 0;
            }
        );

        $server->start;
        print "Server started.\n";
        $server->completion_condvar->recv;
        return 0;
    }

}

# use like:
#
# pclient +PC --name=taglist -PC lib/File.pm
#
# filenames end up relative to the directory you run pclient from
# (you can run this script from anywhere.)
