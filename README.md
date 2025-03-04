# Terminal-Based RPG

This is a WIP RPG that you can play in a terminal emulator.

This program is written in the Zig programming language.
See this page for installing Zig: https://ziglang.org/learn/getting-started/#direct
The code is compatible with Zig 0.13.

### To compile and run the program:
Open a terminal emulator in the same directory/folder as the "build.zig" file and "src" folder, then enter:

    zig build run


## How to Play

All interactions in the game are achieved by typing a string and pressing enter. Gameplay typically consists of
selecting between several options presented to you. Options will be in blue text. Select an option by entering
text matching the option.

If you see an option like "big hat". you select it by typing `big hat` and pressing enter.
but you don't have to type the whole string. here are some possible shorthand inputs: `big`, `bi ha`, `h`.
but if you can choose between "big hat" and "big sword", then `big` won't work as an input, and you'll have to
include at least an `h` or an `s`.

most actions that you can do you'll be able to see. but some common actions won't be visible.
for instance, you can type `quit` from anywhere in the game, and you'll exit the program.

arrow keys and some other buttons don't work on macos and linux, and cause bugs.
despite having save files, progress is not saved yet.

Gameplay consists of actions like traveling, shopping, and fighting.

combat is __extremely WIP__, but here's how it works at the moment:
you'll find that attacking will often do little or no damage. you have to `invest` a number of times to get behind
the enemy's armor before each attack to do more damage.
that might sound boring, because it is. the only fun part at the moment is your spells. buy spells
from the shop. spells need "power" to use. buy the artifact "zeniba's solid gold monogram seal" from the shop to
increase your power. once in battle, you will generate an amount of "mana" each turn. once you have enough mana, you
can use a spell.
here's generally how each spell works:
- fireball: damage
- firegorger: more damage
- arc spell: damage based on how much mana you have
- death spell (developer build only): instantly kills your opponent

### Screenshots

![shop](/screenshot1.png)
![combat](/screenshot2.png)