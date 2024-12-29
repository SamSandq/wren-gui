# compile GUI version, production
# execute in <root>, binary to ./bin and named wgp
clang -o bin/wgp -framework Cocoa  -framework AVFoundation -framework AVKit -framework Quartz  -framework UniformTypeIdentifiers src/main.c src/wren-binding.c src/wren-gui.m -Iinclude lib/libwren.a
# strip symbols
strip bin/wgp
