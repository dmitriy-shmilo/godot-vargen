SRC = $(wildcard src/*.c)

all: build/vargen.dll

build/vargen.o: $(SRC)
	mkdir -p build
	gcc -o build/vargen.o $^ -std=c11 -c -Igodot-headers -DDEBUG


build/vargen.dll: build/vargen.o
	gcc -Igodot-headers -shared -Wl,--out-implib,build/libvargen.a -o build/vargen.dll build/vargen.o 
