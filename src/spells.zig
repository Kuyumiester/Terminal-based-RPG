const combat = @import("combat.zig");
const output = @import("output.zig");
const devtools = @import("devtools.zig");
const objects = @import("objects.zig");

pub const Type = struct {
    function_pointer: *const fn (combat.ActionArgument) combat.Effect,
    power: u3, // will probably be a u4 in the future. i'm just doing this to default to minimalism
    mana_cost: u6,
};

// ======
// spells
// ======

pub const death = objects.Type{
    .name = "death spell",
    .onion = .{ .spell = .{
        .function_pointer = &deathFn,
        .power = 0,
        .mana_cost = 0,
    } },
};
fn deathFn(s: combat.ActionArgument) combat.Effect {
    output.print("{s} used death spell!", .{s.user.name});
    s.target.health = 0;
    return .{};
}

pub const fireball = objects.Type{
    .name = "fireball spell",
    .onion = .{ .spell = .{
        .function_pointer = &fireballFn,
        .power = 2,
        .mana_cost = 4,
    } },
};
fn fireballFn(s: combat.ActionArgument) combat.Effect {
    //var defense: u5 = 0;
    //for (s.target.armor) |armor_struct| {
    //    if (armor_struct == null) continue;
    //    defense += armor_struct.?.defense;
    //}
    //const dmg_dealt: u7 = 7 -| defense;
    output.print("{s} used fireball!", .{s.user.name});
    return .{ .damage = 7, .balance_damage = 3 };
    //combat.damageTarget(s.target, dmg_dealt);
}

pub const firegorger = objects.Type{
    .name = "firegorger spell",
    .onion = .{ .spell = .{
        .function_pointer = &firegorgerFn,
        .power = 4,
        .mana_cost = 8,
    } },
};
fn firegorgerFn(s: combat.ActionArgument) combat.Effect {
    //var defense: u5 = 0;
    //for (s.target.armor) |armor_struct| {
    //    if (armor_struct == null) continue;
    //    defense += armor_struct.?.defense;
    //}
    //const dmg_dealt: u7 = 14 -| defense;
    output.print("{s} used firegorger!", .{s.user.name});
    return .{ .damage = 14, .balance_damage = 4 };
    //combat.damageTarget(s.target, dmg_dealt);
}

pub const arc = objects.Type{
    .name = "arc spell",
    .onion = .{ .spell = .{
        .function_pointer = &arcFn,
        .power = 5,
        .mana_cost = 4,
    } },
};
pub fn arcFn(s: combat.ActionArgument) combat.Effect {
    //var defense: u5 = 0;
    //for (s.target.armor) |armor_struct| {
    //    if (armor_struct == null) continue;
    //    defense += armor_struct.?.defense;
    //}
    //const dmg_dealt: u7 = s.user.mana -| defense;
    const atk_pwr: u7 = s.user.mana + comptime arc.onion.spell.mana_cost;
    output.print("{s} used arc spell!", .{s.user.name});
    return .{ .damage = atk_pwr, .balance_damage = 2 };
    //combat.damageTarget(s.target, dmg_dealt);
}

//

// make a spell that attacks per turn or something. and maybe allow the user to increase the damage somehow
// the point is to force the enemy to keep dodging or blocking or something. it was inspired by outgoing_attack not resetting to 0 when it should.
//
