const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nabla_module = b.addModule("nabla", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const core_mod = b.addModule("core", .{
        .root_source_file = b.path("src/core/root.zig"),
        .target = target,
        .optimize = optimize
    });

    const linalg_mod = b.addModule("linalg", .{
        .root_source_file = b.path("src/linalg/root.zig"),
        .target = target,
        .optimize = optimize
    });
    linalg_mod.addImport("core", core_mod);

    const main_exe = b.addExecutable(.{
        .name = "nabla lib",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .optimize = optimize,
            .target = target,
      }),
    });


    const example = b.option([]const u8, "example", "run an example file") orelse "main";
    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .target = target,
            .root_source_file = b.path(b.fmt("src/examples/{s}.zig", .{example})),
            .optimize = optimize,

        }),
    });

    exe.root_module.addImport("core", core_mod);
    exe.root_module.addImport("linalg", linalg_mod);
    main_exe.root_module.addImport("core", core_mod);
    main_exe.root_module.addImport("linalg", linalg_mod);
    


    const lib_tests = b.addTest(.{
        .root_module = nabla_module,
    });


    const run_example_cmd = b.addRunArtifact(exe);

    const run_example_step = b.step("run-ex", "run the app");
    run_example_step.dependOn(&run_example_cmd.step);

    if (b.args) |args| {
        run_example_cmd.addArgs(args);
    }

    const run_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
