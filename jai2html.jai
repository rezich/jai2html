#import "Basic";
#import "Jai_Lexer";
#import "Clipboard"; // os_clipboard_set_text
#import "String";

CSS_BLOCK_CLASS  :: "Jai";
CSS_CLASS_PREFIX :: "Jai_";

append_wrapped :: (builder: *String_Builder, token_type: Token_Type, s: string) {
    class_name: string;
    if token_type >= .__FIRST_KEYWORD && token_type <= .__LAST_KEYWORD then class_name = "KEYWORD";
    else class_name = sprint("%", token_type);
    append_wrapped(builder, class_name, s);
}
append_wrapped :: (builder: *String_Builder, class_name: string, s: string) {
    append(builder, "<span class=\"");
    append(builder, CSS_CLASS_PREFIX);
    append(builder, class_name);
    append(builder, "\">");
    append(builder, tokenize(s));
    append(builder, "</span>");
}
tokenize :: (s: string) -> string {
    s2 := replace(s,  "&", "&amp;");
    s2  = replace(s2, "<", "&lt;");
    s2  = replace(s2, ">", "&gt;");
    return s2;
}

main :: () {
    lexer: Lexer;
    input := os_clipboard_get_text();
    set_input_from_string(*lexer, copy_string(input));

    last_line    := 1;
    char_in_line := 0;

    builder: String_Builder;
    print(*builder, "<div class=\"%\">", CSS_BLOCK_CLASS);

    while true {
        token := peek_next_token(*lexer);
        if token.type == .END_OF_INPUT break;

        eat_token(*lexer);

        while token.l0 > last_line {
            found:, to_add:, input = split_from_left(input, "\n");
            assert(found);

            start_of_comment := find_index_from_left(to_add, "//");
            if start_of_comment != -1 {
                append(*builder, slice(to_add, 0, start_of_comment));
                to_add.data += start_of_comment;
                to_add.count -= start_of_comment;
                to_add = trim_right(to_add, "\r\n");
                append_wrapped(*builder, "COMMENT_LINE", to_add);
                append(*builder, "\n");
            }
            else {
                append(*builder, tokenize(to_add));
                append(*builder, "\n");
            }
            last_line += 1;
            char_in_line = 0;
        }
        if token.type >= 128 {
            before := slice(input, 0, token.c0-1-char_in_line);
            append(*builder, tokenize(before));
            assert(token.c1 != -1);
            unwrapped := slice(input, token.c0-1-char_in_line, token.c1-token.c0);
            append_wrapped(*builder, token.type, unwrapped);
            advanced := before.count + unwrapped.count;
            input.data   += advanced;
            input.count  -= advanced;
            char_in_line += advanced;
        }
    }
    append(*builder, input);
    append(*builder, "\n</div>");

    os_clipboard_set_text(builder_to_string(*builder));
}
