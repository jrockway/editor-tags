use MooseX::Declare;

class Editor::Tags::File::ExuberantCTags extends Editor::Tags::File::CTags {
    use Editor::Tags::Types qw(Tag);
    use Editor::Tags::Tag;

    method build_extra_info(ClassName|Object $class: Tag $tag){
        my %extra_info = %{$tag->extra_info};
        $extra_info{line} = $tag->line if $tag->line;

        my $kind = 's';
        $kind = 'p' if $extra_info{kind} && $extra_info{kind} =~ /package/;

        delete $extra_info{kind}; # special case.
        return ($kind, \%extra_info);
    }

    override build_formatted_tag(ClassName|Object $class: Tag $tag) {
        my $pattern = $tag->address_pattern;
        my ($kind, $extra_info) = $class->build_extra_info($tag);

        my $result = join "\t", $tag->name, $tag->associated_file,
          qq{$pattern;"}, $kind,
          map { join ':', $_, $extra_info->{$_} }
            grep { $extra_info->{$_} }
              keys %$extra_info;
        return "$result\n";
    }
}
