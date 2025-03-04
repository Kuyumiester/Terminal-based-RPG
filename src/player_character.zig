// potential names for this file: sailor, wizard, hero, player, character, player_character (abbreviated to pc in other files), adventurer, avatar, protagonist,
const std = @import("std");

const actors = @import("actors.zig");
const output = @import("output.zig");
const combat = @import("combat.zig");
const devtools = @import("devtools.zig");

pub var attributes: actors.Type = .{
    .name = undefined,
    .health_max = 8,
    .health = 8,
    .armor = 3,
    //.armor = .{
    //    if (devtools.developer_build) .{ .defense = 5, .investment_cost = 4 } else .{ .defense = 2, .investment_cost = 2 },
    //    .{ .defense = 2, .investment_cost = 3 },
    //    null,
    //    null,
    //},
    .balance_max = 8,
    .energy_max = 30,
    .power = 2,
};

pub var name_buffer: [60]u8 = undefined;

// =========
// inventory
// =========

const objects = @import("objects.zig");
pub inline fn init() void {
    if (devtools.developer_build) {
        addToInventory(objects.getIndex("death spell"), 1);
    }
}

// consider putting this in a money struct |if and only if| there's a good reason
pub var copper: u16 = 20;
pub var silver: u16 = 0;
pub var gold: u16 = 0;

// =================================================================================
// weapon the player has equipped, affecting what normal actions they have access to
// =================================================================================

const equipment = @import("equipment.zig");

pub var weapon: equipment.Weapon = equipment.hammer.onion.weapon;

const FieldType = std.meta.FieldType;

// ==============================
// spells the player has equipped
// ==============================

const spells = @import("spells.zig");

pub var spells_soa: SpellsSoa = .{};
const spells_soa_capacity = objects.number_of_spells; // what's the highest number of spells the player can cast at any given time?
const SpellsSoa = struct {
    len: devtools.Int(spells_soa_capacity) = 0,
    ids: [spells_soa_capacity]objects.Id = undefined,
    names: [spells_soa_capacity][]const u8 = undefined,
    mana_costs: [spells_soa_capacity]FieldType(spells.Type, .mana_cost) = undefined,

    fn add(
        self: *SpellsSoa,
        id: objects.Id,
    ) devtools.Int(spells_soa_capacity) {
        self.ids[self.len] = id;
        self.names[self.len] = objects.array[id].name;
        self.mana_costs[self.len] = objects.array[id].onion.spell.mana_cost; // optimization, still unsure about this one...
        defer self.len += 1;
        return self.len;
    }
};

// ==========================
// consumables the player has
// ==========================

const consumables = @import("consumables.zig");

const consumables_soa_capacity = 4; // what's the highest number of consumables the player can carry?

// optimization, if we always have equal access to all consumables in our inventory, and our inventory will always be organized such that all consumables are next to each other, then we don't need a separate consumables_soa. *but* there's a half-decent chance we won't always have access to all our consumables.
pub var consumables_soa: struct {
    len: devtools.Int(consumables_soa_capacity) = 0,
    inventory_indexes: [consumables_soa_capacity]devtools.Int(inventory_capacity) = undefined,
    names: [consumables_soa_capacity][]const u8 = undefined,
    quantities: [consumables_soa_capacity]@TypeOf(inventory.quantities[0]) = undefined, // optimization, we should probably just use the quantities in the inventory. why didn't i do that?
} = .{};

// ==================================================================================
// the player's inventory, which holds all the player's consumables, spells, weapons,
// ==================================================================================

const inventory_capacity = objects.array.len; // what's the highest number of items the player can carry?

pub var inventory: struct {
    len: devtools.Int(inventory_capacity) = 0,
    quantities: [inventory_capacity]devtools.Int(99) = undefined,
    ids: [inventory_capacity]objects.Id = undefined,
    //enums: [inventory_capacity]objects.Enumerator { spell, consumable, weapon },
    names: [inventory_capacity][]const u8 = undefined,
    soa_indexes: [inventory_capacity]union(objects.Enumerator) {
        weapon: void,
        trinket: void,
        spell: devtools.Int(spells_soa_capacity),
        consumable: devtools.Int(consumables_soa_capacity),
    } = undefined,
} = .{};

pub fn addToInventory(
    id: objects.Id,
    quantity: devtools.Int(99),
) void {

    //      see if we already have this object in the inventory
    //
    for (inventory.ids, 0..) |inv_id, index| {
        if (inv_id == id) {
            inventory.quantities[index] += quantity;
            if (objects.array[id].onion == .consumable) {
                consumables_soa.quantities[inventory.soa_indexes[index].consumable] += quantity;
            }
            return;
        }
    }

    //      add the object to the inventory
    //

    inventory.ids[inventory.len] = id;
    inventory.names[inventory.len] = objects.array[id].name;
    inventory.quantities[inventory.len] = quantity;

    switch (objects.array[id].onion) {
        .trinket => |trinket| trinket.equip(&attributes),
        .spell => {
            inventory.soa_indexes[inventory.len] = .{ .spell = spells_soa.add(id) };
        },

        .consumable => {
            inventory.soa_indexes[inventory.len] = .{ .consumable = consumables_soa.len };

            // add consumable to the consumables_soa
            consumables_soa.inventory_indexes[consumables_soa.len] = inventory.len;
            consumables_soa.names[consumables_soa.len] = objects.array[id].name;
            consumables_soa.quantities[consumables_soa.len] = quantity;
            consumables_soa.len += 1;
        },
        else => {},
    }

    inventory.len += 1;
}
