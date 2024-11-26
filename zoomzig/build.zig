const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });

    const exe = b.addExecutable(.{
        .root_source_file = b.path("src/zoom.zig"),
        .name = "zoom",
        .target = target,
        .optimize = optimize,
    });

    exe.entry = .disabled;
    exe.rdynamic = true;
    exe.import_memory = true;
    exe.export_memory = true;
    exe.max_memory = std.wasm.page_size * 150; // 64 pages of 64kB = 15MB

    b.installArtifact(exe);
}
