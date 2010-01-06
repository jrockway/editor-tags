use MooseX::Declare;

class Editor::Tags::Parser::Static::PPI
  with (Editor::Tags::Parser::FromFile) {
    use MooseX::FileAttribute;
    use MooseX::Types::Path::Class qw(File);
    use MooseX::Types::Structured qw(Dict);
    use MooseX::Types::Moose qw(ArrayRef);

    use Editor::Tags::Tag;
    use Editor::Tags::Types qw(Tag);

    use PPI;

    use 5.010;

    has_file 'file' => (
        must_exist => 1,
        required   => 1,
    );

    method new_from_file($class: $filename, @rest) {
        return $class->new( file => $filename, @rest );
    }

    has 'document' => (
        init_arg   => undef,
        is         => 'ro',
        isa        => 'PPI::Document',
        lazy_build => 1,
    );

    has 'methods' => (
        init_arg   => undef,
        is         => 'ro',
        isa        => ArrayRef[Tag],
        auto_deref => 1,
        lazy_build => 1,
    );

    method _build_document {
        return PPI::Document->new( $self->file->stringify );
    }


    my $next_nonwhitespace = sub {
        my $next = shift;
        while ( $next = $next->next_sibling ) {
            return $next unless $next->isa('PPI::Token::Whitespace');
        }
    };

    method _build_methods {
        my $doc = $self->document;
        my @result;

        my @methods;
        $doc->find( sub {
            my ($top, $elt) = @_;
            return 0 unless $elt->isa('PPI::Token::Word');
            return 0 unless $elt->literal ~~ [qw/method override/]; # also before/after/around/inner?
            my $name = $next_nonwhitespace->($elt);
            my $proto_or_block = $next_nonwhitespace->($name);
            my ($proto, $block);
            if ($proto_or_block->isa('PPI::Structure::List')) {
                $proto = $proto_or_block;
                $block = $next_nonwhitespace->($proto_or_block);
            }
            else {
                $block = $proto_or_block;
            }
            return 0 unless $block->isa('PPI::Structure::Block');

            push @methods, [ $elt->literal, $name->literal, @{$name->location}[0,1], (defined $proto ? $proto : ''), $elt ];
            return $elt;
        });

        my @subs = $doc->find('PPI::Statement::Sub');

        use Tie::File;
        tie my @file , 'Tie::File' , $self->file->stringify;

        for my $method (@methods) {
            my ($type, $name, $line, $offset, $proto, $elt) = @$method;

            my $tag = Editor::Tags::Tag->new(
                associated_file => $self->file,
                name            => $name,
                definition      => substr ($file[$line-1], 0, $offset + length($name) - 1),
                line            => $line,
                offset          => $offset,
                extra_info      => {
                    access    => ($name =~ /^_/ ? 'private' : 'public'),
                    signature => eval { $proto->literal } || '',
                    kind      => $type,
                    file      => 1,
                },
            );

            push @result, $tag;
        }

        return \@result;
    }

    method tags {
        return $self->methods;
    }
}
