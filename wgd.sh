# compile GUI version with DEBUG
# execute in <root>, binary to ./bin and named wgd
clang -w -g -o bin/wgd -DDEBUG -framework Cocoa -framework AVFoundation -framework AVKit -framework Quartz -framework UniformTypeIdentifiers src/main.c src/wren-binding.c src/wren-gui.m -Iinclude lib/libwren_d.a
