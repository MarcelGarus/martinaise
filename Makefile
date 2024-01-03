martinaise: martinaise_1 compiler/2/stdlib.mar
	cp martinaise_1 martinaise
	cp compiler/2/stdlib.mar stdlib.mar

martinaise_0: $(wildcard compiler/0/src/*) compiler/0/build.zig
	@echo "# Martinaise 0"
	cd compiler/0; \
		zig build
	cp compiler/0/zig-out/bin/martinaise martinaise_0

martinaise_1: martinaise_0 $(wildcard compiler/1/*)
	@echo "# Martinaise 1"
	cd compiler/1; \
		./../../martinaise_0 compile compiler.mar; \
		cc output.c -o ../../martinaise_1; \
		rm output.c

clean:
	rm martinaise_*
