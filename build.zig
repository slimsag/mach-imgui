const std = @import("std");
const builtin = @import("builtin");

const mach = @import("mach");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const imgui = b.dependency("imgui", .{});
    const mach_dep = b.dependency("mach", .{ .target = target, .optimize = optimize });
    const use_freetype = b.option(bool, "use_freetype", "Use Freetype") orelse false;

    const module = b.addModule("mach_imgui", .{
        .root_source_file = .{ .path = "src/ImGui.zig" },
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
    module.addCSourceFile(.{ .file = .{ .path = "src/cimgui.cpp" }, .flags = flags.items });
    module.addCSourceFile(.{ .file = imgui.path("imgui.cpp"), .flags = flags.items });
    module.addCSourceFile(.{ .file = imgui.path("imgui_widgets.cpp"), .flags = flags.items });
    module.addCSourceFile(.{ .file = imgui.path("imgui_tables.cpp"), .flags = flags.items });
    module.addCSourceFile(.{ .file = imgui.path("imgui_draw.cpp"), .flags = flags.items });
    module.addCSourceFile(.{ .file = imgui.path("imgui_demo.cpp"), .flags = flags.items });
    module.addIncludePath(imgui.path("."));
    module.addIncludePath(.{ .path = "src" });

    // Example
    const app = try mach.CoreApp.init(b, mach_dep.builder, .{
        .name = "mach-imgui-example",
        .src = "example/main.zig",
        .target = target,
        .deps = &[_]std.Build.Module.Import{
            .{ .name = "imgui", .module = module },
        },
        .optimize = optimize,
    });

    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&app.run.step);

    // Generator
    const generator_exe = b.addExecutable(.{
        .name = "mach-imgui-generator",
        .root_source_file = .{ .path = "tools/generate_binding.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(generator_exe);

    const generate_step = b.step("generate", "Generate the bindings");
    generate_step.dependOn(&b.addRunArtifact(generator_exe).step);
}
