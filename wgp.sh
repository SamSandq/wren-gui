# compile GUI version, production
# use new main.c for simplicity
# execute in <root>, binary to ./bin and named wgp
clang -o bin/wgp -DS_SQL -framework Cocoa  -framework AVFoundation -framework AVKit -framework Quartz  -framework UniformTypeIdentifiers src/main.c src/wren-binding.c src/wren-gui.m -Iinclude lib/libwren.a #-l sqlite3
strip bin/wgp
