martinaise: compiler/2/martinaise compiler/2/stdlib.mar
	@cp compiler/2/martinaise martinaise
	@cp compiler/2/stdlib.mar stdlib.mar
	@echo "# Done with bootstrapping"

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

skip-zig:
	cd compiler/1; \
		cc compiler.c -o martinaise && \
		touch stdlib.mar

clean:
	rm -rf compiler/0/zig-out;
	rm -rf compiler/0/zig-cache;
	find . -name martinaise -delete
