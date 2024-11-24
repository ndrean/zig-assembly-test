const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding, // no specific OS
        .cpu_features_add = std.Target.wasm.featureSet(&.{
            //  atomics and bulk_memory are needed for threads
            .atomics,
            .bulk_memory,
        }),
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    const app = b.addExecutable(.{
        .name = "zoom",
        .root_source_file = b.path("src/zoom.zig"),
        .target = target,
        .optimize = optimize,
    });

    app.entry = .disabled;
    // needed so wasmtime can find `wasi_thread_start`
    app.rdynamic = true;
    app.import_memory = true;
    app.export_memory = true;
    // default limit (64mb) crashes wasmtime
    app.max_memory = std.wasm.page_size * 128; // 64 pages of 64kB = 4MB

    b.installArtifact(app);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(app);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
