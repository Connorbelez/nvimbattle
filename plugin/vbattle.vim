
" my_socket_plugin.vim
" my_socket_plugin.vim
let s:lua_rocks_deps_loc =  expand("<sfile>:h:r") . "/../lua/vbattle/deps/"
exe "lua package.path = package.path .. ';" . s:lua_rocks_deps_loc . "/lua-?/init.lua'"

command! RunSS lua require("vbattle").setup_deps()
command! -nargs=? RunSocketClient lua require("vbattle").run_socket_client(<f-args>)
command! -nargs=? SendSocketM lua require("vbattle").send(<f-args>)
command! -nargs=? Listen lua require("vbattle").listen(<f-args>)
command! RunSocketVAPI lua require("vbattle").VT()
command! VsockConn lua require("vbattle").VSOCK()
command! VsockR lua require("vbattle").VREAD()

" command! -nargs=0 FetchTodos lua require("vb").fetch_todos()
