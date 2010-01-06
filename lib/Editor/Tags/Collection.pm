use MooseX::Declare;

role Editor::Tags::Collection {
    use MooseX::Types::Path::Class qw(File);
    use Editor::Tags::Types qw(Tag);
    use MooseX::Types::Moose qw(ArrayRef HashRef);

    use Set::Object;

    has '_tags' => (
        is         => 'ro',
        isa        => 'Set::Object',
        required   => 1,
        default    => sub { Set::Object->new },
        trigger    => sub {
            my $self = shift;
            $self->_clear_file_tag_map;
        },
        handles => {
            add_tag    => 'insert',
            remove_tag => 'delete',
            tags       => 'members',
        },
    );

    before add_tag(Tag $tag){
        return; # only here for type validation
    }

    has 'file_tag_map' => (
        init_arg   => undef,
        traits     => ['Hash'],
        is         => 'ro',
        isa        => HashRef[ArrayRef[Tag]],
        lazy_build => 1,
        handles    => {
            get_file_tags => 'get',
            list_files    => 'keys',
        },
    );

    method _build_file_tag_map {
        my $result = {};
        for my $tag ($self->tags){
            my $file = $tag->associated_file->stringify;
            $result->{$file} ||= [];
            push @{$result->{$file}}, $tag;
        }
        return $result;
    }

    method add_tags(@tags){
        $self->add_tag($_) for @tags;
    }

    method forget_file(Str $filename){
        $self->remove_tag($_) for @{$self->get_file_tags($filename)};
    }
}
