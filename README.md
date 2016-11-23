# CliFM 1.5-4 (Nov 21, 2016)

As its very name suggests, Cli File Manager's (CliFM) most distinctive feature is that 
it's entirely text-based: no mouse, no graphical interface of any kind (not even ncurses 
and its keyboard arrows), but only CLI commands (something we, the keyboard lovers, 
certainly enjoy). To be sure, there are lots of GUI file managers out there (from Dolphin 
to Thunar) and a couple of TUI-based others as well (such as MC, Ranger, ViFM, Lfm, VFU or 
Clist). But, as far as I know, and leaving aside Linux' own built-in commands, there is no 
completely CLI file manager in the Linux world (and this, let me say, is quite weird). 
This is the hole CliFM is intended to fill. However, even if it were not the only one, 
it's still a nice and functional alternative. After all, this is what Linux is all 
about: freedom; and freedom no doubt implies alternatives. Furthermore, the CLI is 
one of Linux' most distinctive hallmarks. So, how could it be possible not to have a 
CLI file manager for our beloved Linux?

CliFM was first deviced with purely self-educational purposes. All I wanted was to 
learn more about the amazing bash. But then the project began growing rapidilly, up to 
the point where it became what it is today: a simple, but fully functional file manager.
Insofar as it is entirely written in Shell script, CliFM's code is accesible and easily
modifiable by any average Linux user. Furthermore, being a simple CLI program, the source
code takes only 50Kb, while the weight of the application when running is about a few 
hundred Kb, leaving aside the memory consumed by the terminal on which it is running.

As a file manager, CliFM is intended to perform all the basic operations you may 
expect from any file manager out there: navigate through your files and folders, 
bookmark your favorite paths, copy, rename, delete, move, paste, open, create files and 
folders, and, this is one of its most distinctive features, the ability to remember 
your selections. While browsing your files, you can select different elements (be it 
files or folders) in one path and then a couple more in a different path; CliFM will 
recollect all of them, so that you can later paste or move them wherever you want, or 
simply delete them.

CliFM is basically aimed to make easier and faster all the common file operations of your 
everyday work, such as copy, move, delete, etc. (specially when files or paths are 
too long), which tend to be too tedious when carried out via Linux' built-in commands. 
A concrete example: to copy a file with a long name (even worse if it has spaces) 
to a distant path with the 'cp' command, often results in a quite long command. Well, with 
CliFM this can be achieved in a much simpler way. Why? In the first place, because you 
don't have to type the name of the file you want, say, to copy, but only its corresponding 
list number. In the second place, because you don't need to type any path either, for with 
CliFM you browse your files via short commands followed by list numbers; and the thing gets 
even faster with CLiFM bookmarks manager.

General Usage:

ELN = element line number. E.g. "23 - openbox". 23 is the ELN of the openbox file.
Arguments in square brackets ([]) point to different possible arguments. Only one of
them is to be passed to the command.
Arguments in curly brackets ({}) are optional arguments, i.e. they may not be passed to
the command.

Commands:
- h, help, ?: show this help.
- /*: This is the quick search function. Just type '/' followed by the string you 
    are looking for, and CliFM will list all the matches in the current folder.
- :* In case some external command conflicts with some of the CliFM internal commands, 
    you can still run it by typing the command you want preceded by a colon (:)
- bm, bookmarks: open the bookmarks menu. Here you can add, remove or edit your 
    bookmarks to your liking, or simply cd into the desired bookmark by entering 
    either its list number or its hotkey.
- o, open ELN: open a folder or a file. I you want to open a file with a different 
    program, just add the command name as a second argument, e.g. 'open ELN leafpad' 
- cd {path}: it works just as the built-in 'cd' command.
- b, back: go back to the parent folder.
- pr, prop ELN: display the properties of the selected element.
- ren ELN {new_name}: rename an element.
- md, mkdir name ... n: create one or more new folders.
- t, touch name ... n: create one or more new files.
- ln, link [sel, ELN] link_name: create a simbolic link. The source element could 
  be either a selected element, in which case you has to simply type 'sel' as first 
  argument, or an element listed in the screen, in which case you simply has to specify 
  its list number as first argument. The second argument is always a file name for the 
  symlink.
- s, sel [ELN, ELN-ELN, ... n]: select one or multiple elements. Sel command accepts range
    of elements, say 1-6, just as '*' to select all the elements of the current folder. 
- sh, show, show sel: show currently selected elements.
- ds, desel: deselect currently selected elements.
- del {ELN ... n}: With no arguments, del command will delete those elements currently
    selected, if any. Otherwise, when one or more ELN's are passed, it will delete
    only those elements. 
- paste: copy selected elements into the current folder.
- move: move selected elements into the current folder.
- clr: clear the screen.
- color [on off]: toggle colored output on/off.
- hidden [on off]: toggle hidden files on/off.
- col,columns [on off]: toggle columns on/off.
- x, term: open a new terminal (xterm by default) in the current path and in a different
     window. 
- v, ver, version: show CliFM version.
- q, quit, exit: quit CliFM.

Besides all these commands, you can also run built-in or external commands from the CliFM 
prompt by simply typing the command you want to run.
   In case the command accepts a file or folder as input, you can of course type the entire command
just as if you were in the command line. Yet, you can also make use of the ELN to make the thing
easier. For instance, let's suppose you want to open a text file via Leafpad. In this case all you 
need to do is to type at the CliFM prompt: "leafpad filename" or "leafpad ELN". 

Config file: $HOME/.config/clifm/clifmrc
