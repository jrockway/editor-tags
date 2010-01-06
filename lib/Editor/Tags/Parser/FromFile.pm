use MooseX::Declare;

role Editor::Tags::Parser::FromFile with Editor::Tags::Parser {
    requires 'new_from_file';
};

1;
