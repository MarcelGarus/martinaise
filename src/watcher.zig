// The high-level file watching API doesn't work on the self-hosted Zig compiler
// yet because it requires async/await. Hence, this is a crude, blocking version
// that directly makes syscalls. It only works on Linux though.
// Followed the inotify tutorial from this blog: https://www.linuxjournal.com/article/8478

const std = @import("std");
const os = std.os;

const is_linux = @import("builtin").os.tag == .linux;
const libc = if (is_linux) os.linux else @compileError("Not supported");

pub const Watcher = struct {
    inotify_fd: i32,
    watch: usize,

    const Self = @This();
    pub fn init(file_path: [*:0]const u8) !Self {
        const inotify_fd: i32 = @intCast(libc.inotify_init1(0));
        if (inotify_fd <= 0) return error.Todo;

        const watch = libc.inotify_add_watch(
            inotify_fd,
            file_path,
            libc.IN.MODIFY | libc.IN.CREATE | libc.IN.DELETE,
        );
        if (watch == 0) return error.Todo;

        return .{ .inotify_fd = inotify_fd, .watch = watch };
    }

    pub fn deinit(self: Self) void {
        _ = libc.close(self.inotify_fd);
    }

    pub fn wait_for_change(self: Self) !void {
        const event_size_without_name = @sizeOf(libc.inotify_event);
        const buf_len = (1024 * event_size_without_name) + 16;
        var buf = [_]u8{0} ** buf_len;

        while (true) {
            const len = libc.read(self.inotify_fd, (&buf).ptr, buf_len);
            if (len == 0) return error.Todo;
            var i: usize = 0;
            while (i < len) {
                // This is the part where the blog said "Clever readers will
                // immediately question whether the following code is safe with
                // respect to alignment requirements". In Zig, this was a
                // compile error and requires the @alignCast.
                // Why this works: In practice, the event.len field is
                // guaranteed to be set to a value so that the following event
                // is aligned as well.
                const event: *libc.inotify_event = @alignCast(@ptrCast(&buf[i]));
                // std.debug.print("Event: {}\n", .{event});
                i += event_size_without_name + event.len;
                if (event.wd == self.watch) return;
            }
        }
    }
};
