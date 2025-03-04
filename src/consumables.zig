const combat = @import("combat.zig");
const output = @import("output.zig");
const devtools = @import("devtools.zig");
const objects = @import("objects.zig");

pub const Type = struct {
    function_pointer: *const fn (combat.ActionArgument) void,
};

// ===========
// consumables
// ===========

pub const potion_of_mana = objects.Type{
    .name = "potion of mana",
    .onion = .{ .consumable = .{
        .function_pointer = &potionOfMana,
    } },
};
fn potionOfMana(s: combat.ActionArgument) void {
    s.user.mana +|= 12;
    output.print("{s} used potion of mana", .{s.user.name});
}

//pub const thunder_missile = objects.Type{
//    .name = "thunder missile",
//    .onion = .{ .consumable = .{
//        .function_pointer = &thunderMissile,
//    } },
//};
//fn thunderMissile(s: combat.ActionArgument) void {
//    var defense: u5 = 0;
//    for (s.target.armor) |armor_struct| {
//        if (armor_struct == null) continue;
//        defense += armor_struct.?.defense;
//    }
//
//    const dmg_dealt: u7 = 10 -| defense;
//    output.print("{s} used thunder missile", .{s.user.name});
//    combat.damageTarget(s.target, dmg_dealt);
//}
//
//pub const holy_hand_grenade = objects.Type{
//    .name = "holy hand grenade",
//    .onion = .{ .consumable = .{
//        .function_pointer = &holyHandGrenade,
//    } },
//};
//fn holyHandGrenade(s: combat.ActionArgument) void {
//    var defense: u5 = 0;
//    for (s.target.armor) |armor_struct| {
//        if (armor_struct == null) continue;
//        defense += armor_struct.?.defense;
//    }
//
//    const dmg_dealt: u7 = 30 -| defense;
//    output.print("{s} used holy hand grenade", .{s.user.name});
//    combat.damageTarget(s.target, dmg_dealt);
//}
