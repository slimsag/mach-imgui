const std = @import("std");
const mach = @import("mach");
const ImGui = @import("imgui");
const gpu = mach.gpu;

// Globally unique name of our module
pub const name = .game;
pub const Mod = mach.Mod(@This());
pub const global_events = .{
    .init = .{ .handler = init },
    .tick = .{ .handler = tick },
};

f: f32 = 0.0,
color: [3]f32 = undefined,

pub fn init(game: *Mod, imgui: *ImGui.Mod) !void {
    imgui.init(.{ .allocator = std.heap.page_allocator });
    try imgui.state().init(.{});
    game.init(.{});
}

pub fn tick(engine: *mach.Engine.Mod, game: *Mod, imgui: *ImGui.Mod) !void {
    var iter = mach.core.pollEvents();
    while (iter.next()) |event| {
        _ = ImGui.processEvent(event);
        switch (event) {
            .close => engine.send(.exit, .{}),
            else => {},
        }
    }

    const io = imgui.state().getIO();
    try imgui.state().newFrame();

    ImGui.c.text("Hello, world!");
    _ = ImGui.c.sliderFloat("float", &game.state().f, 0.0, 1.0);
    _ = ImGui.c.colorEdit3("color", &game.state().color, ImGui.c.ColorEditFlags_None);
    ImGui.c.text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / io.framerate, io.framerate);
    ImGui.c.showDemoWindow(null);

    const back_buffer_view = mach.core.swap_chain.getCurrentTextureView().?;
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = gpu.Color{ .r = 0.2, .g = 0.2, .b = 0.2, .a = 1.0 },
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = mach.core.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
    });

    const pass = encoder.beginRenderPass(&render_pass_info);
    try imgui.state().render(pass);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    var queue = mach.core.queue;
    queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    mach.core.swap_chain.present();
    back_buffer_view.release();
}
