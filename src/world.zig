const output = @import("output.zig");
const input = @import("input.zig");
const pc = @import("player_character.zig");
const combat = @import("combat.zig");
const actors = @import("actors.zig");
const main = @import("main.zig");

pub fn init() void {
    town.routes = &.{&dungeon_entrance};
    town.route_names = &.{"dungeon entrance"}; // can't use dungeon_entrance.name instead of "dungeon entrance" for some reason. i can set it to foo_string if it's const, but not if it's var.
    // this applies to all location.routes_names, not just for town

    dungeon_entrance.routes = &.{ &town, &dungeon_1 };
    dungeon_entrance.route_names = &.{ "town", "d" };

    dungeon_1.routes = &.{ &dungeon_entrance, &dungeon_2 };
    dungeon_1.route_names = &.{ "dungeon entrance", "ek" };

    dungeon_2.routes = &.{ &dungeon_1, &dungeon_r1, &dungeon_l1 };
    dungeon_2.route_names = &.{ "d", "r", "l" };

    dungeon_l1.routes = &.{&dungeon_2}; //, &dungeon_l2 };
    dungeon_l1.route_names = &.{"ek"}; //, "m" };

    //dungeon_l2.routes = &.{&dungeon_l1};
    //dungeon_l2.route_names = &.{"l"};

    dungeon_r1.routes = &.{ &dungeon_2, &dungeon_r2 };
    dungeon_r1.route_names = &.{ "ek", "dragon_room" };

    dungeon_r2.routes = &.{&dungeon_r1};
    dungeon_r2.route_names = &.{"r"};
}
// supposedly, i won't have to init the route pointers after an eventual zig update.

pub const Location = struct { // scene is another good word
    name: []const u8,
    encounter: *const fn () ?void,
    action_names: []const []const u8 = &.{},
    action_functions: []const *const fn () ?void = &.{},
    route_names: []const []const u8 = undefined,
    routes: []const *Location = undefined,
};

const Action = struct {
    name: []const u8,
    function: *const fn () ?void,
};

// ==============
//      map
// ==============

pub var town = Location{
    .name = "town",
    .action_names = &.{ rest.name, shop.name },
    .action_functions = &.{ rest.function, shop.function },

    .encounter = &nothing,
};

const rest = Action{
    .name = "rest",
    .function = &rest_function,
};
fn rest_function() ?void {
    output.newScreen();
    if (pc.copper >= 4) {
        pc.copper -= 4;
        pc.attributes.health = pc.attributes.health_max;
        output.writeAll("\nhealth fully restored for 4 copper\n\n");
    } else {
        output.print("\nyou don't have enough money to rest. you need 4 copper, but only have {}\n\n", .{pc.copper});
    }
}

const shop = Action{
    .name = "shop",
    .function = &vendor,
};

//
//
//     shop
//
//

// i want to use the same memory for all the vendors, and i was prepared to get memory allocation on board, but it seems we've evaded it once again.
// note that if two or more vendors are very close to each other on the map, we maybe should have extra space and arrays or whatever to hide load times from getting data from storage
// what should i store? just ids and quantities? would including names and costs be faster? it's storage, so i wouldn't count on it. and it definitely takes up more space.

pub fn init_shop() void {
    addToInventory(objects.getIndex("fireball spell"), 1);
    addToInventory(objects.getIndex("firegorger spell"), 1);
    addToInventory(objects.getIndex("arc spell"), 1);
    addToInventory(objects.getIndex("potion of mana"), 12);
    addToInventory(objects.getIndex("zeniba's solid gold monogram seal"), 1);
}

const devtools = @import("devtools.zig");
const objects = @import("objects.zig");
const FieldType = @import("std").meta.FieldType;

pub var inventory: Inventory = .{};
const inventory_capacity = 6;
const Inventory = struct { // optimization, we might be very slightly better off with AOS here for costs and quantities (and maybe ids, too), since we use them at the same time
    len: devtools.Int(inventory_capacity) = 0,
    quantities: [inventory_capacity]devtools.Int(99) = undefined,
    costs: [inventory_capacity]devtools.Int(80) = undefined,
    ids: [inventory_capacity]objects.Id = undefined,
    names: [inventory_capacity][]const u8 = undefined,
};

fn removeInventoryIndex(index: usize) void {
    for (
        inventory.costs[index .. inventory.len - 1],
        inventory.costs[index + 1 .. inventory.len],

        inventory.quantities[index .. inventory.len - 1],
        inventory.quantities[index + 1 .. inventory.len],

        inventory.ids[index .. inventory.len - 1],
        inventory.ids[index + 1 .. inventory.len],

        inventory.names[index .. inventory.len - 1],
        inventory.names[index + 1 .. inventory.len],
    ) |
        *cost_i,
        cost_e,
        *quantity_i,
        quantity_e,
        *id_i,
        id_e,
        *name_i,
        name_e,
    | {
        cost_i.* = cost_e;
        quantity_i.* = quantity_e;
        id_i.* = id_e;
        name_i.* = name_e;
    }

    inventory.len -= 1;
}

fn addToInventory(id: objects.Id, quantity: devtools.Int(99)) void {
    inventory.quantities[inventory.len] = quantity;
    inventory.ids[inventory.len] = id;
    inventory.costs[inventory.len] = cost_catalogue[id];
    inventory.names[inventory.len] = objects.array[id].name;
    inventory.len += 1;
}

const cost_catalogue = [_]devtools.Int(80){
    0,
    30,
    0,
    10,
    20,
    40,
    10,
};

fn vendor() ?void {
    output.newScreen();
    while (true) {
        output.writeAll("\nyou walk into a shop. a vendor shows you his wares");
        output.writeAll("\n\n" ++ output.selectable_color ++ "leave\n" ++ output.standard_color ++ " " ** (objects.longest_name_len + 4) ++ "cost" ++ " " ** 8 ++ "in stock");

        // =======================
        //       print names
        // =======================

        // feature, turn this into a function and add indexes to the struct so we can print newlines in between the item types
        for (
            inventory.names[0..inventory.len],
            inventory.costs[0..inventory.len],
            inventory.quantities[0..inventory.len],
        ) |name, cost, quantity| {
            // format to line up the text like so:
            // potion of mana          cost: 4      in stock: 10
            // arc spell               cost: 20     in stock: 1

            output.print(output.selectable_color ++ "\n{s: <" ++ devtools.numberAsString(objects.longest_name_len + 4) ++ "}" ++ output.standard_color ++ "{: <12}{}", .{ name, cost, quantity });
        }
        output.print("\n\n" ++ " " ** (objects.longest_name_len + 4 - 9) ++ "you have {} currency\n\n", .{pc.copper});

        // =========================
        //       the other bit
        // =========================

        while (true) { // continue when the player doesn't have enough money
            const s = input.selectFrom(&.{
                main.default_actions,
                &.{"leave"},
                inventory.names[0..inventory.len],
            });
            switch (s.which_array) {
                0 => main.switchOnDefaultActions(s.index) orelse return null, // quit
                1 => { // leave the shop
                    output.newScreen();
                    return;
                },
                2 => {
                    output.newScreen();
                    if (pc.copper < inventory.costs[s.index]) {
                        input.maintainInvalidInputs();
                        output.writeAll("not enough money\n");
                        continue;
                    }
                    pc.copper -= inventory.costs[s.index];
                    output.print("purchased {s}", .{inventory.names[s.index]});
                    pc.addToInventory(inventory.ids[s.index], 1);

                    if (inventory.quantities[s.index] > 1) {
                        inventory.quantities[s.index] -= 1;
                    } else {
                        removeInventoryIndex(s.index);
                    }

                    break;
                },
                else => unreachable,
            }
        }
    }
}

//
//
//     not shop
//
//

pub var dungeon_entrance = Location{
    .name = "dungeon entrance",

    .encounter = &fight_tank,
};

pub var dungeon_1 = Location{
    .name = "d",

    .encounter = &find_copper,
};

pub var dungeon_2 = Location{
    .name = "ek",

    .encounter = &fight_warrior,
};

pub var dungeon_l1 = Location{
    .name = "l",

    .encounter = &find_gold,
};
//pub var dungeon_l2 = Location{
//    .name = "m",
//
//    .encounter = &find_gold,
//};
pub var dungeon_r1 = Location{
    .name = "r",

    .encounter = &nothing,
};
pub var dungeon_r2 = Location{
    .name = "dragon room",

    .encounter = &fightDragon,
};

// =========
// functions
// =========

fn find_copper() ?void {
    pc.copper += 50;
    output.print("\nfound 20 copper coins\n", .{});
}

fn fight_knight() ?void {
    combat.main(&knight) orelse return null;
}
var knight = actors.knight;

fn fight_warrior() ?void {
    combat.main(&warrior) orelse return null;
}
var warrior = actors.warrior;

fn fight_tank() ?void {
    combat.main(&tank) orelse return null;
}
var tank = actors.tank;

fn fightDragon() ?void {
    combat.main(&dragon) orelse return null;
}
var dragon = actors.dragon;

fn find_gold() ?void {
    pc.copper += 100;
    output.print("\nfound 100 copper coins! you're rich!", .{});
    //pc.gold += 1;
    //output.print("\nfound a gold coin! you're rich!", .{});
}

pub fn setNothing() void {
    main.scene.*.encounter = &nothing;
}

fn nothing() ?void {}
