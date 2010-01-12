use MooseX::Declare;

# TagList is a Vim plugin that turns ctags data into a nice menu, but
# does, unfortunately, not actually understand the content of ctags
# files.  Oh, it also can't read tags from a *file*; only from stdin.
# It also can't read a tags file that has tags for more than one file.
# (You keep a tags file for each file in your project, riiiight?)
#
# So this app runs in the background, accepts a request (via pclient)
# for a file's tags, and prints them, in exactly the format taglist
# desires, to stdout.  (Did I mention that if the tags aren't in
# exactly the right format, with exactly the right metadata and only
# the right metadata, TagList totally ignores the tag?  Oh, well... it
# does.  Because vim can't parse files whose format specification
# document is included in the fucking vim source code.)
#
# I will mention that Emacs' Speedbar can handle a TAGS file for your
# entire project (or, get this, multiple TAGS files), but that's
# because smart people use Emacs.  It also doesn't whine when the TAGS
# file is changed out from under it; it just silently uses the new
# data.  It's like someone with a brain designed it...
#
# For maximum enjoyment; use Emacs and the Script::Update instead of
# this.  It's nicer, faster, and more user-friendly.  And you have
# Lisp.

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
