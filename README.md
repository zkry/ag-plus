# ag-plus: Extensions for ag-mode

This package provides functions to extend ag-mode to additive
searching on a results page.  For example, after doing a project wide
ag search, you can run `ag-plus-filter-files` to filter the results
buffer to only show files that match a certain regex.  You can perform
this repeatedly to get the desired results.  The provided commands are as follows:

- `ag-plus-mode`: the mode which has default keymap for ap-plus commands.
- `ag-plus-additive-search`: after being prompted for a string, search
  all the files in the buffer for provided string, and add the results
  under the file heading.  If the search resulted in no result, then
  the file and its results are deleted. (bound to <kbd>s</kbd> in
  `ag-plus-mode-map`)
- `ag-plus-remove-files`: after being prompted for a string, remove
  all files and their contents if the filename matches the provided
  string. (bound to <kbd>r</kbd> in `ag-plus-mode-map`)
- `ag-plus-filter-files`: after being prompted for a string, remove
  all files and their contents if the filename doesn't match the
  provided string. (bound to <kbd>f</kbd> in `ag-plus-mode-map`)
