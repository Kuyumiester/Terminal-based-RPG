const devtools = @import("devtools.zig");

pub const Type = struct {
    name: []const u8 = "unnamed actor",
    health_max: u8,
    health: u8,
    armor: u5,
    //armor: [4]?ArmorStruct = .{
    //    .{ .defense = 3, .investment_cost = 2 },
    //    .{ .defense = 2, .investment_cost = 3 },
    //    null,
    //    null,
    //},
    balance: devtools.Int(99) = undefined,
    balance_max: devtools.Int(99),
    energy: devtools.Int(99) = undefined,
    energy_max: devtools.Int(99),
    mana: devtools.Int(99) = 0, // i think i want to rename mana to "magic points" or "magic energy"
    power: u3 = 0,
    //enchantment_power
    //sludge_power
    //golden_power
    //fire_power
};

//pub const ArmorStruct = struct {
//    defense: u5,
//    investment_cost: u5,
//};

pub const warrior = Type{
    .name = "warrior",
    .health = 11,
    .health_max = 11,
    .armor = 3,
    .balance_max = 9,
    .energy_max = 40,
};

pub const tank = Type{
    .name = "tank",
    .armor = 4,
    //.armor = .{
    //    .{ .defense = 5, .investment_cost = 3 },
    //    .{ .defense = 1, .investment_cost = 4 },
    //    null,
    //    null,
    //},

    .health_max = 8,
    .health = 8,
    .balance_max = 8, // nocheckin, how should tank be different than the others?
    .energy_max = 30,
};

pub const knight = Type{
    .name = "knight",
    .armor = 3,
    //.armor = .{
    //    .{ .defense = 6, .investment_cost = 1 },
    //    .{ .defense = 3, .investment_cost = 2 },
    //    .{ .defense = 2, .investment_cost = 3 },
    //    null,
    //},

    .health_max = 8,
    .health = 8,
    .balance_max = 8,
    .energy_max = 30,
};

pub const dragon = Type{
    .name = "dragon",
    .armor = 6,
    //.armor = .{
    //    .{ .defense = 6, .investment_cost = 9 },
    //    null,
    //    null,
    //    null,
    //},

    .health_max = 99,
    .health = 99,
    .balance_max = 50,
    .energy_max = 60,
};
