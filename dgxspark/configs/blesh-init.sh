# Keep ble.sh deliberately quiet: ordinary Readline-style completion with no
# ghost suggestions, menus, filename coloring, or variable coloring.
bleopt complete_auto_complete=
bleopt complete_auto_history=
bleopt complete_ambiguous=
bleopt complete_menu_complete=
bleopt complete_menu_filter=
# Command resolution is part of ble.sh's filename highlighter, so leave that
# engine enabled and neutralize its display faces below.
bleopt highlight_filename=1
bleopt highlight_variable=

# Syntax parsing remains enabled only to show resolved command words in green.
# Unknown commands and every other shell token retain the terminal's default.
for face in \
  syntax_command syntax_quoted syntax_quotation syntax_escape syntax_expr \
  syntax_error syntax_varname syntax_delimiter syntax_param_expansion \
  syntax_history_expansion syntax_function_name syntax_comment syntax_glob \
  syntax_brace syntax_tilde syntax_document syntax_document_begin \
  command_jobs command_directory command_suffix command_suffix_new \
  filename_directory filename_directory_sticky filename_link filename_orphan \
  filename_setuid filename_setgid filename_executable filename_other \
  filename_socket filename_pipe filename_character filename_block \
  filename_warning filename_url filename_ls_colors argument_option \
  argument_error; do
  ble-face -s "$face" none
done
for face in \
  command_builtin_dot command_builtin command_alias command_function \
  command_file command_keyword; do
  ble-face -s "$face" fg=green
done
unset face
