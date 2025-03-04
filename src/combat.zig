const std = @import("std");

const actors = @import("actors.zig");
const output = @import("output.zig");
const input = @import("input.zig");
const m = @import("main.zig");
const pc = @import("player_character.zig");
const equipment = @import("equipment.zig");
const objects = @import("objects.zig");

const Actor = actors.Type;

pub const ActionArgument = struct {
    user: *Actor,
    target: *Actor,
};

pub const Effect: type = struct { damage: u7 = 0, balance_damage: u7 = 0 };
pub var incoming_effect: Effect = .{};
pub var outgoing_effect: Effect = .{};

var xoshiro: std.Random.Xoshiro256 = undefined;
var random: std.Random = undefined;
pub fn init() void {
    xoshiro = std.Random.Xoshiro256.init(0);
    random = xoshiro.random();
}

pub fn main(enemy: *Actor) ?void {
    output.newScreen();
    output.print("combat initiated with opponent {s}", .{enemy.name});
    const participants = [2]*Actor{ &pc.attributes, enemy };

    pc.attributes.balance = pc.attributes.balance_max;
    pc.attributes.mana = 0;
    pc.attributes.energy = @divFloor(pc.attributes.energy_max, 3);

    enemy.balance = enemy.balance_max;
    enemy.energy = enemy.energy_max / 3;

    incoming_effect = .{};
    outgoing_effect = .{};

    const combat_result: ?void = combat: while (true) {
        for (participants) |acting_actor| {
            if (acting_actor == &pc.attributes) {
                playerTurn(enemy) orelse return null;
                effectTarget(&pc.attributes, &incoming_effect);
                if (pc.attributes.health == 0) {
                    output.print("\n{s} has died", .{pc.attributes.name});
                    break :combat null;
                }
            } else {
                output.print("\n\n", .{});
                enemy.energy = @min(enemy.energy_max, enemy.energy + 3);
                enemy.balance = @min(enemy.balance_max, enemy.balance + 1);
                if (enemy.energy >= 6) {
                    switch (random.intRangeAtMost(u8, 0, 1)) {
                        0 => {
                            output.print("{s} does nothing.", .{enemy.name});
                        },
                        1 => {
                            enemy.energy -= 6;
                            incoming_effect = equipment.attack();
                            output.print("{s} attacks!", .{enemy.name});
                        },
                        else => unreachable,
                    }
                } else {
                    output.print("{s} does nothing.", .{enemy.name});
                }
                effectTarget(enemy, &outgoing_effect);
                if (enemy.health == 0) break :combat;
            }
        }
    };

    output.print("\nbattle over\n\n", .{});

    return combat_result;
}

//var still_fighting : bool = undefined;

fn playerTurn(enemy: *Actor) ?void {
    pc.attributes.mana = @min(99, pc.attributes.mana + 1);
    pc.attributes.balance = @min(pc.attributes.balance_max, pc.attributes.balance + 1);
    pc.attributes.energy = @min(pc.attributes.energy_max, pc.attributes.energy + 3);

    // ====================================
    // print combat actions
    // and
    // add combat actions to options_buffer
    // ====================================

    output.print("\n\n{s}\nhealth: {}    defense: {}    balance: {}+{}    energy: {}+{}\n\n{s}\nhealth: {}    defense: {}    balance: {}    energy: {}    magic energy: {}", .{
        enemy.name,
        enemy.health,
        enemy.armor,
        enemy.balance,
        1,
        enemy.energy,
        3,
        pc.attributes.name,
        pc.attributes.health,
        pc.attributes.armor,
        pc.attributes.balance,
        pc.attributes.energy,
        pc.attributes.mana,
    });

    // print normal actions
    output.writeAll("\n");
    for (pc.weapon.action_names, pc.weapon.action_costs) |name, cost| output.print(output.selectable_color ++ "{s} " ++ output.standard_color ++ "{}    ", .{ name, cost });

    // print spells
    if (pc.spells_soa.len != 0) {
        output.writeAll("\n");
        for (
            pc.spells_soa.names[0..pc.spells_soa.len],
            pc.spells_soa.mana_costs[0..pc.spells_soa.len],
        ) |name, mana_cost| {
            output.print(output.selectable_color ++ "{s}" ++ output.standard_color ++ "  {}    ", .{ name, mana_cost });
        }
    }

    // print consumables
    if (pc.consumables_soa.len != 0) {
        output.writeAll("\n");
        for (
            pc.consumables_soa.names[0..pc.consumables_soa.len],
            pc.consumables_soa.quantities[0..pc.consumables_soa.len],
        ) |name, quantity| {
            output.print(output.selectable_color ++ "{s}" ++ output.standard_color ++ "  {}    ", .{ name, quantity });
        }
    }

    output.writeAll(output.standard_color ++ "\n");

    while (true) { // start a while loop in case the player chooses a spell they can't afford to cast
        const selection = input.selectFrom(&.{
            m.default_actions,
            pc.weapon.action_names,
            pc.spells_soa.names[0..pc.spells_soa.len],
            pc.consumables_soa.names[0..pc.consumables_soa.len],
        });

        switch (selection.which_array) {
            0 => m.switchOnDefaultActions(selection.index) orelse return null, // default actions eg. quit
            1 => { // normal action

                // check if the player has enough energy to do the action
                if (pc.weapon.action_costs[selection.index] >= pc.attributes.energy) {
                    input.maintainInvalidInputs();
                    output.print("not enough energy. you need {} energy to use {s}, but you only have {}.\n", .{
                        pc.weapon.action_costs[selection.index],
                        pc.weapon.action_names[selection.index],
                        pc.attributes.energy,
                    });
                    continue;
                }

                output.newScreen();

                pc.attributes.energy -= pc.weapon.action_costs[selection.index];

                outgoing_effect = pc.weapon.action_pointers[selection.index]();

                output.print("{s} {s}s!", .{ pc.attributes.name, pc.weapon.action_names[selection.index] });
            },
            2 => { // spell

                // check if the player has enough power to cast spell
                if (objects.array[pc.spells_soa.ids[selection.index]].onion.spell.power > pc.attributes.power) {
                    input.maintainInvalidInputs();
                    output.print("not enough power. you need {} power to cast {s}, but you only have {}.\n", .{
                        objects.array[pc.spells_soa.ids[selection.index]].onion.spell.power,
                        pc.spells_soa.names[selection.index],
                        pc.attributes.power,
                    });
                    continue;
                }

                // check if the player has enough mana to cast the spell
                if (pc.spells_soa.mana_costs[selection.index] > pc.attributes.mana) {
                    input.maintainInvalidInputs();
                    output.print("not enough mana. you need {} mana to cast {s}, but you only have {}.\n", .{
                        pc.spells_soa.mana_costs[selection.index],
                        pc.spells_soa.names[selection.index],
                        pc.attributes.mana,
                    });
                    continue;
                }

                output.newScreen();

                pc.attributes.mana -= pc.spells_soa.mana_costs[selection.index];

                // cast the spell
                outgoing_effect = objects.array[pc.spells_soa.ids[selection.index]].onion.spell.function_pointer(.{ .user = &pc.attributes, .target = enemy });
            },

            3 => { // consumable
                output.newScreen();

                objects.array[pc.inventory.ids[pc.consumables_soa.inventory_indexes[selection.index]]].onion.consumable.function_pointer(.{ .user = &pc.attributes, .target = enemy });

                if (pc.consumables_soa.quantities[selection.index] > 1) {
                    pc.consumables_soa.quantities[selection.index] -= 1;
                    pc.inventory.quantities[pc.consumables_soa.inventory_indexes[selection.index]] -= 1;
                } else {

                    // remove from the inventory
                    for ( // optimization, would abstracting pc.consumables_soa.inventory_indexes[selection.index] be faster? will the compiler just optimize this away anyway, such that abstracting it will just take more space and time?
                        pc.inventory.quantities[pc.consumables_soa.inventory_indexes[selection.index] .. pc.inventory.len - 1],
                        pc.inventory.quantities[pc.consumables_soa.inventory_indexes[selection.index] + 1 .. pc.inventory.len],

                        pc.inventory.ids[pc.consumables_soa.inventory_indexes[selection.index] .. pc.inventory.len - 1],
                        pc.inventory.ids[pc.consumables_soa.inventory_indexes[selection.index] + 1 .. pc.inventory.len],

                        pc.inventory.names[pc.consumables_soa.inventory_indexes[selection.index] .. pc.inventory.len - 1],
                        pc.inventory.names[pc.consumables_soa.inventory_indexes[selection.index] + 1 .. pc.inventory.len],

                        pc.inventory.soa_indexes[pc.consumables_soa.inventory_indexes[selection.index] .. pc.inventory.len - 1],
                        pc.inventory.soa_indexes[pc.consumables_soa.inventory_indexes[selection.index] + 1 .. pc.inventory.len],
                    ) |*quantity_index, quantity_element, *id_i, id_e, *name_i, name_e, *soa_index_i, soa_index_e| {
                        quantity_index.* = quantity_element;
                        id_i.* = id_e;
                        name_i.* = name_e;
                        soa_index_i.* = switch (soa_index_e) {
                            .consumable => |index| .{ .consumable = index + 1 },
                            else => soa_index_e,
                        };
                    }

                    pc.inventory.len -= 1;

                    //remove things from soa
                    // nocheckin, do this
                    // we're doing this after removing from inventory so we don't have to save the inventory_index temporarily
                    //
                    // oh right, i just remembered why this is hard. because we have to update the soa_indexes and inventory_indexes we just have to subtract though. but with the inventory, that means using a switch statement.
                    pc.consumables_soa.len -= 1;
                }
            },
            else => unreachable,
        }

        break;
    }
}

//pub fn damageTarget(target: *Actor, dmg: u7) void {
//    target.health -|= dmg;
//    output.print("\n{s} took {} damage", .{ target.name, dmg });
//}

pub fn effectTarget(target: *Actor, s: *Effect) void {
    var dmg = s.damage;
    if (target.balance <= 3 and s.damage > 0) dmg += 2;
    dmg -|= target.armor;

    output.print("\n{s} took {} damage and lost {} balance", .{ target.name, dmg, @min(target.balance, s.balance_damage) });
    target.health -|= dmg;
    target.balance -|= s.balance_damage;

    s.* = .{ .damage = 0, .balance_damage = 0 };
}
