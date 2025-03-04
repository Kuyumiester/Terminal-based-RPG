# Terminal-Based RPG

This is an RPG than you can play in a terminal emulator.  
It's far from being done, though. Many of the systems have very temporary implementations, and many comments 
are a mess.

This program is written in the Zig programming language.  
See this page for installing Zig: https://ziglang.org/learn/getting-started/#direct  
The code is compatible with Zig 0.13.

### To compile and run the program:
Open a terminal emulator in the same directory/folder as the "build.zig" file and "src" folder, then enter:

    zig build run


## About the game

All interactions in the game are achieved by typing a string and pressing enter. Gameplay typically consists of
selecting between several options presented to you. Select an option by entering
text matching the option.

If you see an option like "big hat", you select it by typing `big hat` and pressing enter.  
But you don't have to type the whole string. Here are some possible shorthand inputs: `big`, `bi ha`, `h`.  
But if you can choose between "big hat" and "big sword", then `big` won't work as an input, and you'll have to
include at least an `h` or an `s`.

Most actions that you can do will be visible as blue text, but some common actions won't be visible.
For instance, you can type `quit` from anywhere in the game, and you'll exit the program.

Gameplay consists of actions like traveling, shopping, and fighting.

### Combat
Combat is subject to change, but here's how it works at the moment:
Combat is turn-based. You take a turn, then your enemy takes a turn, then it repeats.  
Whatever action you selected on your turn will not affect the enemy until their turn. Whatever action your enemy 
takes will not affect you until after you decide what action to take.  
If you choose to `defend`, the incoming effect of the enemy's action will be diminished.

Attacking, kicking, and defending all cost energy. You regenerate some energy each turn.  
Effects of actions usually involve normal damage and balance damage. If you or an enemy get hit while your balance 
is 3 or lower, you'll take 2 extra normal damage.

You can buy spells from the shop. Spells need "power" to use. You have only enough power by default to use the 
`fireball` spell. Buy the artifact `zeniba's solid gold monogram seal` from the shop to increase your power and 
use more powerful spells.  
Once in battle, you will generate an amount of "magic energy" each turn. Once you have enough magic energy, you 
can cast a spell. Here's generally how each spell works:
- fireball: damage
- firegorger: more damage
- arc spell: damage proportional to magic energy
- death spell (developer build only): instantly kills your opponent

### Screenshots

![shop](/screenshot1.png)
![combat](/screenshot2.png)

### Things to note

On MacOS and Linux, some buttons—like arrow keys—can mess up the UI.  
Despite using save files, your game can't be saved yet.
