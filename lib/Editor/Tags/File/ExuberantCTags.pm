use MooseX::Declare;

class Editor::Tags::File::ExuberantCTags extends Editor::Tags::File::CTags {
    use Editor::Tags::Types qw(Tag);
    use Editor::Tags::Tag;
    
    override build_formatted_tag(ClassName|Object $class: Tag $tag) {
        my $pattern = $tag->address_pattern;
        my $result = join "\t", $tag->name, $tag->associated_file, qq{$pattern;"},
          map { join ':', $_, $tag->extra_info->{$_} } grep { $tag->extra_info->{$_} } keys %{$tag->extra_info};
        return "$result\n";
    }
}
