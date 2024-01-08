martinaise: compiler/1/martinaise compiler/1/stdlib.mar
	@cp compiler/1/martinaise martinaise
	@cp compiler/1/stdlib.mar stdlib.mar
	@echo "# Done with bootstrapping"

compiler/0/martinaise: $(wildcard compiler/0/src/*) compiler/0/build.zig
	@echo "# Martinaise 0"
	cd compiler/0; \
		zig build && \
		cp zig-out/bin/martinaise martinaise

compiler/1/martinaise: compiler/0/martinaise $(wildcard compiler/1/*.mar)
	@echo "# Martinaise 1"
	cd compiler/0; \
		./martinaise compile ../1/compiler.mar && \
		cc output.c -o ../1/martinaise && \
		rm output.c

skip-zig:
	cd compiler/1; \
		cc compiler.c -o martinaise && \
		touch stdlib.mar

clean:
	rm -rf compiler/0/zig-out;
	rm -rf compiler/0/zig-cache;
	find . -name martinaise -delete
