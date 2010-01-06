use MooseX::Declare;

role Editor::Tags::Collection {
    use MooseX::Types::Path::Class qw(File);
    use Editor::Tags::Types qw(Tag);
    use MooseX::Types::Moose qw(ArrayRef HashRef);

    has 'tags' => (
        traits     => ['Array'],
        is         => 'ro',
        isa        => ArrayRef[Tag],
        required   => 1,
        default    => sub { +[] },
        auto_deref => 1,
        trigger    => sub {
            my $self = shift;
            $self->_clear_file_tag_map;
        },
        handles => {
            add_tag => 'push',
        },
    );

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
}
