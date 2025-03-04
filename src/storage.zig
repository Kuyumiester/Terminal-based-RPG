const output = @import("output.zig");
const input = @import("input.zig");
const pc = @import("player_character.zig");
const devtools = @import("devtools.zig");

const std = @import("std");
const fs = std.fs;

const rpg_file_type = ".rpg";

pub var file: fs.File = undefined;

pub fn mainMenu() ?void {
    var aa: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer aa.deinit();
    const allocator: std.mem.Allocator = aa.allocator();

    var directory_path_buffer: [fs.max_path_bytes]u8 = undefined;
    var dir: fs.Dir = fs.openDirAbsolute(fs.selfExeDirPath(&directory_path_buffer) catch unreachable, .{ .iterate = true }) catch unreachable; // https://ziglang.org/documentation/master/std/#std.fs.Dir.OpenOptions
    defer dir.close();

    var file_names = std.ArrayList([]const u8).init(allocator);
    defer file_names.deinit();

    var iterator: fs.Dir.Iterator = dir.iterate();
    wloop: while (iterator.next() catch unreachable) |entry| { // returns: windows: std.fs.Dir.IteratorError!?std.fs.Dir.Entry
        //                                                                     mac: !?std.fs.Dir.Entry

        // check if it's the right kind of file
        //
        if (entry.kind != .file) continue;
        if (entry.name.len < rpg_file_type.len) continue;
        const tnl = entry.name.len - rpg_file_type.len; // this line is just a tiny optimization
        for (entry.name[tnl..], rpg_file_type) |a, b| {
            if (a != b) continue :wloop;
        }

        // keep track of the file name
        file_names.append(allocator.dupe(u8, entry.name[0..tnl]) catch unreachable) catch unreachable; //
    }
    if (file_names.items.len == 0) { // do we actually want this? is there a chance they'll want to quit? probably not.
        newCharacter(dir);
        return;
    }
    output.writeAll(output.selectable_color ++ "\n\nnew character        quit" ++ output.standard_color);
    output.writeAll("\n\ncharacters\n" ++ output.selectable_color);
    for (file_names.items) |s| output.print("\n{s}", .{s});
    output.writeAll("\n\n" ++ output.standard_color);

    input.first_try = true;
    const default_menu_options = &.{ "quit", "new character" };
    const selection = input.selectFrom(&.{
        default_menu_options,
        file_names.items,
    });
    switch (selection.which_array) {
        0 => switch (selection.index) {
            0 => return null, // quit
            1 => newCharacter(dir),
            else => unreachable,
        },
        1 => {
            {
                // rebuild the file name with ".rpg" at the end
                var file_name_buffer: [pc.name_buffer.len + rpg_file_type.len]u8 = undefined;
                const l = file_names.items[selection.index].len;
                const l2 = l + rpg_file_type.len;
                for (file_name_buffer[0..l], file_names.items[selection.index]) |*to, from| to.* = from;
                for (file_name_buffer[l..l2], rpg_file_type) |*to, from| to.* = from;

                file = dir.openFile(file_name_buffer[0..l2], .{ .mode = .read_write }) catch unreachable; // openFile: open an existing file. error if the file doesn't exist

                // set the character's name in memory
                for (pc.name_buffer[0..l], file_names.items[selection.index]) |*to, from| to.* = from;
                pc.attributes.name = pc.name_buffer[0..l];
            }

            //
            //      start putting the rest of the data in order
            //

        },
        else => unreachable,
    }
}

fn newCharacter(dir: fs.Dir) void {
    var file_name_buffer: [pc.name_buffer.len + rpg_file_type.len]u8 = undefined;
    const new_character_name = blk: {
        if (devtools.developer_build and false) {
            const default_name = "player";
            for (file_name_buffer[0..default_name.len], default_name) |*to, from| to.* = from;
            break :blk file_name_buffer[0..default_name.len];
        } else {
            output.print("\nname your character\n", .{});
            input.first_try = true;
            while (true) {
                const new_string = input.getPlayerInput(&file_name_buffer);
                // resolve conflicts with default_menu_buttons
                // nocheckin, i think for now i'll just restrict their choice "fully"
                //for (default_menu_options) |option| {
                //    for (option, new_string) |option_byte, new_string_byte| {
                //        //
                //        // the new character on the block
                //        // ne chara
                //        //
                //        //
                ////default_menu_buttons
                //
                //impossible to focus
                //

                //  i think we just need to make sure the smaller one isn't wholly contained within the larger one, and account for word starts
                //  so just make sure not every word in the smaller one is shared with the bigger one
                //  on making assumptions based on which string is bigger: you probably need to scrub spaces. does which one is bigger actually matter?
                //      one two three
                //      one twooooooooooooooo three
                //  let's get more specific:
                //      get the first word of the smaller string

                // starts here
                // =====================================================================================================
                //
                //     function: while (true) {
                //         input_string = getAndSavePlayerInput(&input_buffer);
                //
                //         var selection: ?ReturnType = null; // if we find a valid answer, we'll put it here.
                //
                //         // ============================================
                //         // turn the input_string into an array of words
                //         // ============================================
                //
                //         // we need to identify each word in the input string so we can operate on them individually
                //         // we'll need these multiple times, so we're gonna turn it into an array so we don't have to re-find it each time.
                //
                //         // slicing the words out of the string one by one so we can operate on them individually eg. slicing "fi" out of "fi lan" (the desired option is "fire lance")
                //         const input_words = init: {
                //             // we're going to return a slice containing every word in the input string in sequential order
                //             // eg. "fi lan" => &.{"fi", "lan"}
                //
                //             //// "words" might still not be the best variable name
                //             var words: [pc.name_buffer.len / 2][]const u8 = undefined; // this is the array we're going to slice from, after we've "filled" it.
                //             // as we modify the elements of the words array, we're going to use this to keep track of which elements in the array are still undefined.
                //             var index_to_modify: devtools.Int(objects.highest_word_count) = 0; // the element at this index and all succeeding elements are undefined. preceding elements have been modified.
                //
                //             // to get the words from the input_string, we'll slice from the beginning to the end of each word. we'll find the beginnings and ends by looping through the input_string. when we reach the beginning of a word, we'll take note of it's location; when we reach the end of a word, we'll slice it.
                //             var word_start_index: usize = 0; // we use this to record the index where a word starts.
                //             var last_item_was_a_space: bool = true; // we use spaces to tell us where a word starts. since input_string probably won't start with a space, we need this to be true by default to make sure we catch the first word.
                //             for (input_string, 0..) |input_string_byte, input_string_index| {
                //                 const is_a_space: bool = input_string_byte == ' ';
                //
                //                 // example input: "fi  lan" (notice the 'accidental' second space)
                //                 //  first space: == ' ' and !LIWAS   => slice it!
                //                 // second space: == ' ' and LIWAS    => do nothing / continue
                //                 //            l: != ' ' and LIWAS    => set start then continue
                //                 //            a: != ' ' and !LIWAS   => do nothing / continue
                //                 if (is_a_space == last_item_was_a_space) continue // accounts for two scenarios: a space after a space, and a letter after a letter
                //                 else if (!is_a_space and last_item_was_a_space) {
                //                     word_start_index = input_string_index;
                //                     last_item_was_a_space = false;
                //                     continue;
                //                 }
                //
                //
                //                 // we found where a word ends, so we'll slice it.
                //                 // the following code is reached if (is_a_space and !last_item_was_a_space). putting an 'else if' or 'else' would be redundant.
                //                 last_item_was_a_space = true;
                //
                //                 words[index_to_modify] = input_string[word_start_index..input_string_index];
                //                 index_to_modify += 1;
                //             }
                //             // since we slice words based on spaces and the input_string won't end in a space (most likely), we need code after the for loop to slice that last word.
                //             // we just need to run code as if we just found a space
                //             if (!last_item_was_a_space) {
                //                 if (index_to_modify == words.len) {
                //                     maintainInvalidInputs();
                //                     //output.writeAll("input has too many words. enter something else\n");
                //                     output.writeAll("none of the options match that input. enter something else\n"); // unsure which to use
                //                     continue :function;
                //                 }
                //
                //                 words[index_to_modify] = input_string[word_start_index..input_string.len];
                //                 index_to_modify += 1;
                //             }
                //
                //             break :init words[0..index_to_modify];
                //         };
                //
                //         // ======================================================
                //         // figure out which option the player is trying to select
                //         // ======================================================
                //
                //         // 1
                //         for (slices, 0..) |options, which_slice| {
                //             options_loop: for (options, 0..) |option, options_index| { // look at each option
                //
                //                 var option_string_bookmark: usize = 0; // this is to keep our place in the option string, to make sure we don't parse over words twice
                //                 var beginning_of_word: bool = true; // there's no space before the first word in a string (at least there shouldn't be), so we set this to true by default to make sure we catch the first word.
                //                 // 2
                //                 input_words_loop: for (input_words) |input_word| {
                //
                //                     // 3
                //                     // find the beginning of each word so we know where to start our slices (we don't need to know where they end)
                //                     option_word_loop: for (option[option_string_bookmark..], option_string_bookmark..) |potential_space, beginning_of_word_index| {
                //                         if (potential_space == ' ') {
                //                             beginning_of_word = true; // this doesn't account for double spaces, but that's okay because no names should have double spaces anyway
                //                             continue;
                //                         } else if (!beginning_of_word) continue;
                //                         beginning_of_word = false;
                //
                //                         if (input_word.len > option[beginning_of_word_index..].len) continue :options_loop; // we know the option is wrong if the input is longer than the rest of the option slice
                //
                //                         // the actual comparison
                //                         // 4
                //                         for (input_word, option[beginning_of_word_index .. beginning_of_word_index + input_word.len]) |input_byte, option_byte| {
                //                             if (option_byte != input_byte) continue :option_word_loop;
                //                         }
                //                         // we found an option word that matches the input word! onto the next input word!
                //                         option_string_bookmark = beginning_of_word_index + input_word.len;
                //                         continue :input_words_loop;
                //                     }
                //                     // we couldn't find an option word that matches the input word; we ran out of option words; we reached the end of option_word_loop
                //                     continue :options_loop;
                //                 }
                //
                //                 // we found an answer!
                //                 if (selection == null) {
                //                     // this is the first time we've found an answer! yay!
                //                     selection = .{
                //                         .which_array = @intCast(which_slice), // optimization, do switch statements cast small integers to usize?
                //                         .index = options_index,
                //                     };
                //                     continue :options_loop;
                //                 } else { // oh no! this isn't the first answer we've found! at least two options match the player's input, so we don't know what to select!
                //                     maintainInvalidInputs();
                //                     output.writeAll("multiple options match that input. enter something else\n");
                //                     continue :function;
                //                 }
                //             }
                //
                //         //
                //         //    see if we caught something
                //         //
                //         if (selection) |v| {
                //             return v;
                //         } else {
                //             // oh no! we didn't find any matching words!
                //             maintainInvalidInputs();
                //             output.writeAll("none of the options match that input. enter something else\n");
                //             continue :function;
                //         }
                //     }
                // }

                // ================================================================================================
                // ends here
                break :blk new_string;
            }
        }
    };

    // add ".rpg" to the end of the name
    for (file_name_buffer[new_character_name.len .. new_character_name.len + rpg_file_type.len], rpg_file_type) |*to, from| to.* = from;
    // create a new save file
    file = dir.createFile(file_name_buffer[0 .. new_character_name.len + rpg_file_type.len], .{ .read = true }) catch unreachable; // createFile: create a new file. if a file of the same name exists already, delete it first.

    //
    //      start putting data in order
    //

    for (pc.name_buffer[0..new_character_name.len], file_name_buffer[0..new_character_name.len]) |*to, from| {
        to.* = from;
    }
    pc.attributes.name = pc.name_buffer[0..new_character_name.len];
}

// for getting input for characters, we should copy the functions in input.zig and modify them for longer inputs

fn saveGameFile() void {
    // should i save a new file every time? or should i try to only change what i need to? if i pack the file tightly enough, i may have to move everything after the thing i change, too. so i guess i could just not pack the file so tightly?
    _ = try file.write("oppa!"); // "``write`` is allowed to only partially write the input"
    // "write is basically only useful when you have a buffer of data and you want to conserve syscalls as much as possible
    // ie. if there are only 10 bytes left to write, hold off and write them later
    // but in general, ``write`` in isolation is wrong, and a ``write`` where you throw away the return is certainly wrong"
    _ = try file.writeAll("Hi, mom!\n"); // guaranteed to write the whole string by calling ``write`` in a loop
    try file.writer().print("Hello, sailor!\n", .{}); //allows formatting, as opposed to only taking a string as an argument

    // writing to a file will overwrite the existing data. the "cursor" so-to-speak, that decides what bytes will get overwritten, starts at the beginning of the file.
    // use "seek" functions to move the cursor. the argument represents how many bytes to offset the cursor location by.
    //file.seekTo() offsets the cursor position relative to the beginning
    //try file.seekFromEnd(0); use this function with the argument 0 to put the "cursor" at the end of the file, so you can append instead of overwriting.
    //file.seekBy() offsets the cursor position relative to current position
}
