//
//     nocheckin, some of this stuff needs to be recommented

const std = @import("std");
const output = @import("output.zig");
const objects = @import("objects.zig");
const devtools = @import("devtools.zig");
const builtin = @import("builtin");

pub var first_try: bool = true;

pub fn maintainInvalidInputs() void {
    if (first_try) {
        first_try = false;
    } else {
        output.print(output.previousLine(3) ++ output.clear_to_screen_end ++ output.scrollDown(1) ++ output.subsequentLine(1) ++ output.input_color ++ "{s}\n" ++ output.standard_color, .{input_string});
    }
}

var input_buffer: [objects.longest_name_len + 2 + 4]u8 = undefined;
// you need one extra index for the newline, and another extra index to not get an "integer overflow" somewhere.
// you should also have one or two more extra indexes in case the player adds some redundant spaces that will get scrubbed.
var input_string: []const u8 = undefined;

// if you save the string returned by getPlayerInput(), you'll get back gibberish when you read it later, because the string references the data in "buffer", which is a variable that ceases to exist after getPlayerInput() finishes.
// getAndSavePlayerInput() lets you provide the buffer/array that gets modified, so you can keep the data around as long as you want. example: if you let the player name their character, you'll need to remember that name for the rest of the game.

// allow the player to enter text via the command line interface, storing the data in memory you provide and returning a string from it.
pub fn getPlayerInput(buffer: []u8) []const u8 {
    var buffer_stream = std.io.fixedBufferStream(buffer);

    // we have a while loop here so that when our input string is too long, we can 'continue' to try again, asking the player for a different input
    while (true) {
        // we use getPlayerInput() as the regular interval to flush our buffered writer, since new information is only readable (with human reaction times) once the program is waiting for the player's input.
        if (devtools.show_timings) {
            devtools.printTime(" " ** 46 ++ "gameplay code: ");
            devtools.startTiming();
            output.flush();
            devtools.printTime(" " ** 54 ++ "flush: ");
        }
        output.writeAll(output.input_color);
        output.flush();

        switch (builtin.target.os.tag) {
            .windows => {
                std.io.getStdIn().reader().streamUntilDelimiter(buffer_stream.writer(), '\r', buffer.len) catch |err| switch (err) { // for some reason, pressing enter/return in cli inputs a carriage return and a newline ("\r\n" aka &.{13, 10}) instead of just a newline ('\n' aka '10')
                    error.StreamTooLong => {
                        if (first_try) {
                            first_try = false;
                        } else {
                            output.print(output.csi ++ "3F" ++ output.clear_to_screen_end ++ output.csi ++ "1T" ++ output.subsequentLine(1) ++ output.input_color ++ "{s}\n", .{buffer_stream.getWritten()});
                        }
                        output.writeAll(output.standard_color ++ "input is too long. enter something else\n");
                        // we have to "drain" the file or whatever it is otherwise it'll just give us the same input next time minus [buffer.len] characters from the beginning
                        std.io.getStdIn().reader().streamUntilDelimiter(std.io.null_writer, '\n', null) catch unreachable;
                        buffer_stream.reset();
                        continue;
                    },
                    else => {
                        output.print(output.standard_color ++ "{!}\n", .{err});
                        continue;
                    },
                };
                std.io.getStdIn().reader().streamUntilDelimiter(std.io.null_writer, '\n', null) catch unreachable; // the '\n' is still there in the StdIn, and we have to clear it out, otherwise our next input will start with '\n'
            },
            .macos, .linux => {
                std.io.getStdIn().reader().streamUntilDelimiter(buffer_stream.writer(), '\n', buffer.len) catch |err| switch (err) {
                    error.StreamTooLong => {
                        if (first_try) {
                            first_try = false;
                        } else {
                            output.print(output.csi ++ "3F" ++ output.clear_to_screen_end ++ output.csi ++ "1T" ++ output.subsequentLine(1) ++ output.input_color ++ "{s}\n", .{buffer_stream.getWritten()});
                        }
                        output.writeAll(output.standard_color ++ "input is too long. enter something else\n");
                        // we have to "drain" the file or whatever it is otherwise it'll just give us the same input next time minus [buffer.len] characters from the beginning
                        std.io.getStdIn().reader().streamUntilDelimiter(std.io.null_writer, '\n', null) catch unreachable;
                        buffer_stream.reset();
                        continue;
                    },
                    else => {
                        output.print(output.standard_color ++ "{!}\n", .{err});
                        continue;
                    },
                };
            },
            else => unreachable,
        }

        output.writeAll(output.standard_color);

        if (devtools.show_timings) devtools.startTiming();
        return buffer_stream.getWritten();
    }
}

const ReturnType = struct {
    which_array: u4, //is it better to return a usize?
    index: usize,
};

// have the player select an option from a list
pub fn selectFrom(slices: []const []const []const u8) ReturnType {

    // **how this parser is intended to function**
    //
    // options: "fire lance", "heavy sword", "steel hammer"
    //
    //     fi lan => fire lance
    //     f => fire lance
    //     l => fire lance
    //     i => error! (no word starts with i)
    //     h => error! (multiple words start with h)
    //     ha => steel hammer
    //     s h => steel hammer
    //
    // note that the return value will be an integer corresponding to the string's position in the array, not the string itself.

    // i still need a synopsis

    function: while (true) {
        input_string = getPlayerInput(&input_buffer);

        var selection: ?ReturnType = null; // if we find a valid answer, we'll put it here.

        // ============================================
        // turn the input_string into an array of words
        // ============================================

        // we need to identify each word in the input string so we can operate on them individually
        // we'll need these multiple times, so we're gonna turn it into an array so we don't have to re-find it each time.

        // slicing the words out of the string one by one so we can operate on them individually eg. slicing "fi" out of "fi lan" (the desired option is "fire lance")
        const input_words = init: {
            // we're going to return a slice containing every word in the input string in sequential order
            // eg. "fi lan" => &.{"fi", "lan"}

            //// "words" might still not be the best variable name
            var words: [objects.highest_word_count][]const u8 = undefined; // this is the array we're going to slice from, after we've "filled" it.
            // as we modify the elements of the words array, we're going to use this to keep track of which elements in the array are still undefined.
            var index_to_modify: devtools.Int(objects.highest_word_count) = 0; // the element at this index and all succeeding elements are undefined. preceding elements have been modified.

            // to get the words from the input_string, we'll slice from the beginning to the end of each word. we'll find the beginnings and ends by looping through the input_string. when we reach the beginning of a word, we'll take note of it's location; when we reach the end of a word, we'll slice it.
            var word_start_index: usize = 0; // we use this to record the index where a word starts.
            var last_item_was_a_space: bool = true; // we use spaces to tell us where a word starts. since input_string probably won't start with a space, we need this to be true by default to make sure we catch the first word.
            for (input_string, 0..) |input_string_byte, input_string_index| {
                const is_a_space: bool = input_string_byte == ' ';

                // example input: "fi  lan" (notice the 'accidental' second space)
                //  first space: == ' ' and !LIWAS   => slice it!
                // second space: == ' ' and LIWAS    => do nothing / continue
                //            l: != ' ' and LIWAS    => set start then continue
                //            a: != ' ' and !LIWAS   => do nothing / continue
                if (is_a_space == last_item_was_a_space) continue // accounts for two scenarios: a space after a space, and a letter after a letter
                else if (!is_a_space and last_item_was_a_space) {
                    word_start_index = input_string_index;
                    last_item_was_a_space = false;
                    continue;
                }

                if (index_to_modify == words.len) {
                    // we've found more words in the input string than our array can hold, so we can't keep track of any more words. if we don't stop it, our code will try to modify an array element that doesn't exist.
                    maintainInvalidInputs();
                    //output.writeAll("input has too many words. enter something else\n");
                    output.writeAll("none of the options match that input. enter something else\n"); // unsure which to use
                    continue :function;
                }

                // we found where a word ends, so we'll slice it.
                // the following code is reached if (is_a_space and !last_item_was_a_space). putting an 'else if' or 'else' would be redundant.
                last_item_was_a_space = true;

                words[index_to_modify] = input_string[word_start_index..input_string_index];
                index_to_modify += 1;
            }
            // since we slice words based on spaces and the input_string won't end in a space (most likely), we need code after the for loop to slice that last word.
            // we just need to run code as if we just found a space
            if (!last_item_was_a_space) {
                if (index_to_modify == words.len) {
                    maintainInvalidInputs();
                    //output.writeAll("input has too many words. enter something else\n");
                    output.writeAll("none of the options match that input. enter something else\n"); // unsure which to use
                    continue :function;
                }

                words[index_to_modify] = input_string[word_start_index..input_string.len];
                index_to_modify += 1;
            }

            break :init words[0..index_to_modify];
        };

        // ======================================================
        // figure out which option the player is trying to select
        // ======================================================

        // 1
        for (slices, 0..) |options, which_slice| {
            options_loop: for (options, 0..) |option, options_index| { // look at each option

                var option_string_bookmark: usize = 0; // this is to keep our place in the option string, to make sure we don't parse over words twice
                var beginning_of_word: bool = true; // there's no space before the first word in a string (at least there shouldn't be), so we set this to true by default to make sure we catch the first word.
                // 2
                input_words_loop: for (input_words) |input_word| {

                    // 3
                    // find the beginning of each word so we know where to start our slices (we don't need to know where they end)
                    option_word_loop: for (option[option_string_bookmark..], option_string_bookmark..) |potential_space, beginning_of_word_index| {
                        if (potential_space == ' ') {
                            beginning_of_word = true; // this doesn't account for double spaces, but that's okay because no names should have double spaces anyway
                            continue;
                        } else if (!beginning_of_word) continue;
                        beginning_of_word = false;

                        if (input_word.len > option[beginning_of_word_index..].len) continue :options_loop; // we know the option is wrong if the input is longer than the rest of the option slice

                        // the actual comparison
                        // 4
                        for (input_word, option[beginning_of_word_index .. beginning_of_word_index + input_word.len]) |input_byte, option_byte| {
                            if (option_byte != input_byte) continue :option_word_loop;
                        }
                        // we found an option word that matches the input word! onto the next input word!
                        option_string_bookmark = beginning_of_word_index + input_word.len;
                        continue :input_words_loop;
                    }
                    // we couldn't find an option word that matches the input word; we ran out of option words; we reached the end of option_word_loop
                    continue :options_loop;
                }

                // we found an answer!
                if (selection == null) {
                    // this is the first time we've found an answer! yay!
                    selection = .{
                        .which_array = @intCast(which_slice), // optimization, do switch statements cast small integers to usize?
                        .index = options_index,
                    };
                    continue :options_loop;
                } else { // oh no! this isn't the first answer we've found! at least two options match the player's input, so we don't know what to select!
                    maintainInvalidInputs();
                    output.writeAll("multiple options match that input. enter something else\n");
                    continue :function;
                }
            }
        }

        //
        //    see if we caught something
        //
        if (selection) |v| {
            return v;
        } else {
            // oh no! we didn't find any matching words!
            maintainInvalidInputs();
            output.writeAll("none of the options match that input. enter something else\n");
            continue :function;
        }
    }
}

// ====================================================
//
//            ideas to maybe implement
//
// ====================================================
//
//
// pressing enter when there's only one option is a feature i want. but when there are default options like "quit" and "inventory" that are so commonly options, then it's gonna be very uncommmon to take advantage of this nice feature. so i suggest making it so that if you press enter with only one visible/non-default option, it ignores the default options, and just selects the one visible option.
//
//
// maybe if multiple options are valid, the game should show those options, so the player knows how specific they need to be. this doubles as a search function (but then you run the risk of accidentally selecting something when you didn't realize there was only one option. so there should probably be a separate dedicated search function). we would just need some way to go back to viewing them all. "\n" ie. [nothing] should be perfect.
// question is: what does the player type next? do they type only what distinguishes those two options? or does what they type need to distinguish the selection from all options? this sounds like an obvious answer, but what if they find themselves in the "spear section" and decide they want that flame sword they saw earlier instead? should the game select that sword, or should the player have to back out of the spear section to select it?
// i'm leaning towards the player needing to back out to select something else, and therefore being able to just type the distinguisher between the new options.
