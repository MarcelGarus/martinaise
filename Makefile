martinaise: martinaise_0
	cp martinaise_0 martinaise

martinaise_0: $(wildcard bootstrapping/0/src*) bootstrapping/0/build.zig
	@echo "# Martinaise 0"
	cd bootstrapping/0; \
		zig build
	cp bootstrapping/0/zig-out/bin/martinaise martinaise_0

martinaise_1: martinaise_0
	@echo "# Martinaise 1"
	cd bootstrapping/1; \
		./../../martinaise_0 compile compiler.mar; \
		cc output.c -o ../../martinaise_1; \
		rm output.c

clean:
	rm martinaise_*
