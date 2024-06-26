const std = @import("std");
const builtin = @import("builtin");

const mach = @import("mach");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const imgui = b.dependency("imgui", .{});
    const use_freetype = b.option(bool, "use_freetype", "Use Freetype") orelse false;

    const mach_dep = b.dependency("mach", .{
        .target = target,
        .optimize = optimize,
    });

    const module = b.addModule("mach_imgui", .{
        .root_source_file = b.path("src/ImGui.zig"),
        .target = target,
        .optimize = optimize,
    });

    var flags = std.ArrayList([]const u8).init(b.allocator);
    defer flags.deinit();

    if (use_freetype) {
        try flags.append("-DIMGUI_ENABLE_FREETYPE");
        module.addCSourceFile(.{ .file = imgui.path("imgui/misc/freetype/imgui_freetype.cpp"), .flags = flags.items });
        module.linkLibrary(b.dependency("freetype", .{
            .target = target,
            .optimize = optimize,
        }).artifact("freetype"));
    }

    module.addImport("mach", mach_dep.module("mach"));
    module.addCSourceFile(.{ .file = b.path("src/cimgui.cpp"), .flags = flags.items });
    module.addCSourceFile(.{ .file = imgui.path("imgui.cpp"), .flags = flags.items });
    module.addCSourceFile(.{ .file = imgui.path("imgui_widgets.cpp"), .flags = flags.items });
    module.addCSourceFile(.{ .file = imgui.path("imgui_tables.cpp"), .flags = flags.items });
    module.addCSourceFile(.{ .file = imgui.path("imgui_draw.cpp"), .flags = flags.items });
    module.addCSourceFile(.{ .file = imgui.path("imgui_demo.cpp"), .flags = flags.items });
    module.addIncludePath(imgui.path("."));
    module.addIncludePath(b.path("src"));

    // Example
    const exe = b.addExecutable(.{
        .name = "mach-imgui-example",
        .root_source_file = b.path("example/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    // Add Mach dependency
    exe.root_module.addImport("mach", mach_dep.module("mach"));
    @import("mach").link(mach_dep.builder, exe);

    // Add imgui dependency
    exe.root_module.addImport("imgui", module);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Generator
    const generator_exe = b.addExecutable(.{
        .name = "mach-imgui-generator",
        .root_source_file = b.path("tools/generate_binding.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(generator_exe);

    const generate_step = b.step("generate", "Generate the bindings");
    generate_step.dependOn(&b.addRunArtifact(generator_exe).step);
}
