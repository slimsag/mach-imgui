const std = @import("std");
const mach = @import("mach");

const Game = @import("Game.zig");
const ImGui = @import("imgui");

// The global list of Mach modules registered for use in our application.
pub const modules = .{
    mach.Engine,
    Game,
    ImGui,
};

pub const App = mach.App;
