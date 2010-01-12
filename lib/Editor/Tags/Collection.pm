use MooseX::Declare;

role Editor::Tags::Collection {
    use MooseX::Types::Path::Class qw(File Dir);
    use Editor::Tags::Types qw(Tag);
    use MooseX::Types::Moose qw(ArrayRef HashRef Undef);

    use MooseX::FileAttribute;
    use MooseX::MultiMethods;

    use Set::Object;

    has_directory 'relative_to' => (
        predicate => 'has_relative_to',
    );

    method canonicalize_path(File|Dir $p){
        if($self->has_relative_to) {
            return $p->relative($self->relative_to)->cleanup
              if $p->is_absolute;
            return $p;
        }

        # no relative_to?  then don't touch anything.
        return $p;
    }

    has '_tags' => (
        is         => 'ro',
        isa        => 'Set::Object',
        required   => 1,
        default    => sub { Set::Object ->new },
        handles => {
            _add_tag      => 'insert',
            remove_tag    => 'delete',
            tags          => 'members',
            contains_tag  => 'member',
        },
    );

    method add_tag(Tag $tag){
        $self->clear_file_tag_map;

        my $fixed_path = $self->canonicalize_path($tag->associated_file);
        my $fixed_tag  = $tag->clone(
            associated_file => $fixed_path,
        );

        $self->_add_tag($fixed_tag);
        return $fixed_tag;
    }

    has 'file_tag_map' => (
        init_arg   => undef,
        traits     => ['Hash'],
        is         => 'ro',
        isa        => HashRef[ArrayRef[Tag]],
        lazy_build => 1,
        handles    => {
            _get_file_tags => 'get',
            list_files     => 'keys',
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

    multi method get_file_tags(File $file){
        my $translated = $self->canonicalize_path($file);
        return $self->_get_file_tags($translated->stringify);
    }

    multi method get_file_tags(Str $file){
        my $f = Path::Class::file($file)->relative;
        return $self->get_file_tags(Path::Class::file($file));
    }

    method add_tags(@tags){
        $self->add_tag($_) for @tags;
    }

    method forget_file(Str|File $filename){
        $self->remove_tag($_) for @{$self->get_file_tags($filename) || []};
        $self->clear_file_tag_map;
    }

    method find_tag(Str $name){
        for my $tag ($self->tags){
            return $tag if $tag->name eq $name;
        }
    }

    method get_sorted_files {
        my @result = sort $self->list_files;
        return @result if wantarray;
        return \@result;
    }

    method get_sorted_tags_for(Str|File $file) {
        my @result = sort { $a->line <=> $b->line } @{$self->get_file_tags($file) || []};
        return @result if wantarray;
        return \@result;
    }

}
