martinaise: compiler/3/martinaise compiler/3/stdlib.mar
	@cp compiler/3/martinaise martinaise
	@cp compiler/3/stdlib.mar stdlib.mar
	@echo "# Done with bootstrapping"

dev: compiler/4/martinaise compiler/4/stdlib.mar
	@cp compiler/4/martinaise martinaise
	@cp compiler/4/stdlib.mar stdlib.mar
	@echo "# Ready for dev work"

compiler/0/martinaise: $(wildcard compiler/0/src/*) compiler/0/build.zig
	@echo "# Martinaise 0"
	cd compiler/0; \
		zig build && \
		cp zig-out/bin/martinaise martinaise

compiler/1/martinaise: compiler/1/compiler.mar compiler/0/martinaise compiler/0/stdlib.mar
	@echo "# Martinaise 1"
	cd compiler/0; \
		./martinaise compile ../1/compiler.mar && \
		cc output.c -o ../1/martinaise && \
		rm output.c

compiler/2/martinaise: compiler/2/compiler.mar compiler/1/martinaise compiler/1/stdlib.mar
	@echo "# Martinaise 2"
	cd compiler/1; \
		./martinaise c ../2/compiler.mar > output.c && \
		cc output.c -o ../2/martinaise && \
		rm output.c

compiler/3/martinaise: compiler/3/compiler.mar compiler/2/martinaise compiler/2/stdlib.mar
	@echo "# Martinaise 3"
	cd compiler/2; \
		./martinaise c ../3/compiler.mar > compiler.c && \
		cc compiler.c -o ../3/martinaise && \
		rm compiler.c

compiler/4/martinaise: compiler/4/compiler.mar compiler/3/martinaise compiler/3/stdlib.mar
	@echo "# Martinaise 4"
	cd compiler/3; \
		./martinaise asm ../4/compiler.mar > compiler.s && \
		nasm -f elf64 compiler.s -o compiler.o && \
		ld -o ../4/martinaise compiler.o && \
		rm compiler.s compiler.o

skip-zig:
	cd compiler/1; \
		cc compiler.c -o martinaise && \
		touch stdlib.mar

editor: martinaise editor.mar
	./martinaise compile editor.mar -sdl

clean:
	rm -rf compiler/0/zig-out;
	rm -rf compiler/0/zig-cache;
	find . -name martinaise -delete
