# compile GUI version with DEBUG
# use new main.c for simplicity
# execute in <root>, binary to ./bin and named wgd
# cd /Volumes/SAMSUNG/wren-project
clang -w -g -o bin/wgd -DDEBUG -DGUI -DS_SQL -framework Cocoa -framework AVFoundation -framework AVKit -framework Quartz -framework UniformTypeIdentifiers src/main.c src/wren-binding.c src/wren-gui.m -Iinclude lib/libwren_d.a #-l sqlite3
