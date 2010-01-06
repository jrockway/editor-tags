use MooseX::Declare;

role Editor::Tags::Parser::FromClass with Editor::Tags::Parser {
    requires 'new_from_class';
}
