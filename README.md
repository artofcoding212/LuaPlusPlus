
<p align="center">
  <img src="https://github.com/artofcoding212/LuaPlusPlus/assets/166761070/2c666901-8e09-45fa-b07c-e16160b069dd">
</p>

<div align="center">
  <b>Lua++ V1.0</b>
  <p>"The C++ of Lua"</p>
  <p>Created by artofcoding212 on Github.</p>
</div>


## Introduction
Lua++ is like the C++ of Roblox's Lua, it adds classes, ontop of some other things, to Roblox's Lua.

## Why Use Lua++?
There are numerous reasons, however the top ones are listed below:
* Lua++ is almost as fast as Roblox's Lua.
* Lua++ adds classes to Roblox's Lua.
* Lua++ adds the switch keyword to Roblox's Lua.
* In place of the odd "end" keyword, Lua++ uses curly braces.

## How Can I Use It?
#### Compiling
To compile your Lua++ code in Roblox, first get the [latest Roblox model of Lua++](create.roblox.com/store/asset/17809928169/Lua-V10) and insert it into anywhere in your game, which usually is in "ReplicatedStorage". Then, you can simply require it and use the "Compile" method that returns a string which can be executed via "loadstring", or other alternatives if you're trying to execute Lua++ on the client.\
Here's an example of a "Script" object that prints the value of 2 + 2:
```lua
--// Variables //--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LuaPlusPlus = require(ReplicatedStorage:WaitForChild("lua++"))
--// Main //--
loadstring(LuaPlusPlus.Compile([[
  class Math {
    func Add(x, y){
      return x+y;
    }
  }

  print(new Math().Add(2, 2));
]]))()
```
This prints 4!
#### VSCode Syntax Highlighting
As of now, the VSCode extension for Lua++'s syntax highlighting is not published, so you will manually have to put it into your VSCode files. To do this, first download the repository's main branch as a ".ZIP" file, and extract it. All you will need is the "highlighter" folder, so you may delete the rest of the contents of the extracted folder.
Then, move your highlighter folder into the path "C:\Users\\[USER\]\\.vscode\extensions" (change the "\[USER\]" field to the name of the desired user you want highlighting in). Then, you're done! Now you can freely create and write files ending with ".luapp" in VSCode, whilst getting syntax highlighting. There is no language server yet, so you won't get errors in your editor.
