const combat = @import("combat.zig");
const output = @import("output.zig");
const objects = @import("objects.zig");
const devtools = @import("devtools.zig");

pub const Weapon = struct {
    action_names: []const []const u8,
    action_pointers: []const *const fn () combat.Effect,
    action_costs: []const u7,
};

pub const hammer = objects.Type{
    .name = "hammer",
    .onion = .{ .weapon = .{
        .action_names = &.{ "attack", "kick", "defend" },
        .action_pointers = &.{ &attack, &kick, &defend },
        .action_costs = &.{ 6, 2, 3 },
    } },
};

pub fn attack() combat.Effect {
    //player.crit_counter -= 1;
    //if (player.crit_counter == 0) {
    //player.crit_counter = 3;
    //stdout.print("{s} attacked and struck a critical blow!\n", .{self.name}) catch unreachable;
    //damage(target, self.crit_damage);
    //return;
    //}
    //var defense: u5 = 0;
    //var investment_cost: u5 = 0;
    //for (s.target.armor) |armor_struct| {
    //    if (armor_struct == null) continue;
    //    if (s.user.investment >= armor_struct.?.investment_cost) {
    //        if (armor_struct.?.investment_cost > investment_cost) investment_cost = armor_struct.?.investment_cost;
    //    } else defense += armor_struct.?.defense;
    //}
    //const dmg_dealt: u7 = s.user.damage -| defense;
    //s.user.investment -= investment_cost;
    //combat.damageTarget(s.target, dmg_dealt);
    return .{ .damage = 5, .balance_damage = 3 };
}

fn kick() combat.Effect {
    return .{ .damage = 0, .balance_damage = 5 };
}

fn defend() combat.Effect {
    combat.incoming_effect.damage -|= 5;
    combat.incoming_effect.balance_damage -|= 1;
    return .{ .damage = 0, .balance_damage = 0 };
}

//const excalibur = Weapon{
//    .name = "excalibur",
//    .action_names = &.{ "attack", "invest" },
//    .action_pointers = &.{ &attack, &invest },
//};

// trinkets    artifacts?    charms?
// (i'm not sure if trinkets should be in a "trinkets" file, or in a "equipment" file. (similar deal with armor and weapons)
//

const actors = @import("actors.zig");

pub const Trinket = struct {
    equip: *const fn (*actors.Type) void,
};

pub const gold_monogram_seal = objects.Type{
    .name = "zeniba's solid gold monogram seal",
    .onion = .{ .trinket = .{
        .equip = &gold_monogram_sealFn,
    } },
};
fn gold_monogram_sealFn(actor: *actors.Type) void {
    actor.*.power += 3;
}

// wizard suit

// writing down equipment-type stuff to add here
// longsword
//  can block, low energy usage or whatever
// hammer/mace
//  high balance damage
// spear
//  high damage, higher energy, lower balance damage?
// magic swords/weapons
//  +1 stamina regen
//  enchanted effect like attacking thrice in a row does extra (magical) damage on the third strike
//  spell attached that lets you buff your weapon
//  normal-ish fireball-like spell attached
//
// heavy armor
// shield
// heavy shield
//  better blocking power, but harder to use
//
// spells
//  enchantment
//
// something that increases these stats:
//  health
//  stamina max
//  stamina regen
//  balance max
//  balance regen
//  defense
//  magic energy regen
//
//
//
//
// it'd be good to tackle these one *type* at a time. ie. make a bunch of weapons, *then* make a bunch of armor
