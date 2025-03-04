//
//    might rename to items.zig
//
//

const equipment = @import("equipment.zig");
const spells = @import("spells.zig");
const consumables = @import("consumables.zig");

pub const Enumerator = enum {
    weapon,
    trinket,
    spell,
    consumable,
};

pub const Type = struct {
    name: []const u8,
    onion: union(Enumerator) {
        weapon: equipment.Weapon,
        trinket: equipment.Trinket,
        spell: spells.Type,
        consumable: consumables.Type,
    },
};

const devtools = @import("devtools.zig");
pub const Id = devtools.Int(array.len - 1);

pub const array = [_]Type{
    equipment.hammer,
    equipment.gold_monogram_seal,
    spells.death,
    spells.fireball,
    spells.firegorger,
    spells.arc,
    consumables.potion_of_mana,
    //consumables.thunder_missile,
    //consumables.holy_hand_grenade,
};

pub const longest_name_len = init: {
    var longest_len: comptime_int = 0;
    for (array) |e| {
        if (e.name.len > longest_len) longest_len = e.name.len;
    }
    break :init longest_len;
};

pub const highest_word_count = init: {
    var most_spaces: comptime_int = 0;
    for (array) |object| {
        var spaces: comptime_int = 0;
        for (object.name) |byte| {
            if (byte == ' ') spaces += 1;
        }
        if (spaces > most_spaces) most_spaces = spaces;
    }
    break :init most_spaces + 1;
};

pub const number_of_spells = init: {
    var n: comptime_int = 0;
    for (array) |object| {
        if (object.onion == Enumerator.spell) n += 1;
    }
    break :init n;
};

pub fn getIndex(string: []const u8) Id {
    outer: for (array, 0..) |obj, index| {
        if (obj.name.len != string.len) continue;
        for (string, obj.name) |string_letter, obj_letter| {
            if (string_letter != obj_letter) continue :outer;
        }
        return @intCast(index);
    }
    return 2 * 2 * 2 - 1; // try to access an index that doesn't exist, since @compileError fucks everything up

    // this fucks things up for some reason
    //@compileError("no object name matches the given string"); // can't do `++ string` for some reason
}
