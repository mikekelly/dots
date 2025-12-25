const std = @import("std");

const version = "0.2.0";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Get git short hash (trimmed)
    const git_hash = std.mem.trim(u8, b.run(&.{ "git", "rev-parse", "--short", "HEAD" }), "\n\r ");

    const exe = b.addExecutable(.{
        .name = "dot",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const options = b.addOptions();
    options.addOption([]const u8, "version", version);
    options.addOption([]const u8, "git_hash", git_hash);
    exe.root_module.addOptions("build_options", options);

    // Link SQLite statically
    exe.addObjectFile(.{ .cwd_relative = "/opt/homebrew/Cellar/sqlite/3.51.1/lib/libsqlite3.a" });
    exe.root_module.addIncludePath(.{ .cwd_relative = "/opt/homebrew/Cellar/sqlite/3.51.1/include" });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run dot");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });


    const tests = b.addTest(.{
        .root_module = test_mod,
    });

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
