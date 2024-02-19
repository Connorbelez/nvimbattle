
" my_socket_plugin.vim
" my_socket_plugin.vim
let s:lua_rocks_deps_loc =  expand("<sfile>:h:r") . "/../lua/vbattle/deps/"
exe "lua package.path = package.path .. ';" . s:lua_rocks_deps_loc . "/lua-?/init.lua'"

command! RunSS lua require("vbattle").setup_deps()
command! RunSocketClient lua require("vbattle").run_socket_client()
command! RunSocketVAPI lua require("vbattle").VT()
command! SendSocketM lua require("vbattle").send()
" command! -nargs=0 FetchTodos lua require("vb").fetch_todos()
