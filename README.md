# CliFM 1.4-8 (2016)

As its ver name suggests, CliFM's most distinctive feature is that it's entirely 
text-based: no mouse, no graphical interface of any kind (not even ncurses and its 
keyboard arrows), but only CLI commands (something we, the keyboard lovers, certainly 
enjoy). To be sure, there are lots of GUI file managers out there (from Dolphin to 
Thunar) and a few TUI-based others as well (such as MC, Ranger, or ViFM). But, as far 
as I know, and leaving aside Linux' own built-in commands, there is no completely CLI 
file manager in the Linux world (and this, let me say, is quite weird). This is the 
hole CliFM is intended to fill. However, even if it were not the only one, it's still a 
nice and functional alternative. After all, this is what Linux is all about: freedom; 
and freedom no doubt implies alternatives. Furthermore, the CLI is one of Linux' most 
most distinctive hallmarks. So, how could it be possible not to have a CLI file manager 
for our beloved Linux?

CliFM was first deviced with purely self-educational purposes. All I wanted was to 
learn more about the amazing bash. But then the project began growing rapidilly, up to 
the point where it became what it is today: a simple, but fully functional file manager. 
As such file manager, CliFM is intended to perform all the basic operations you may 
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
to a distant path with the 'cp' command, could be a true PITA. Well, with CliFM you 
can do this in a much simpler way. Why? In the first place, because you don't have to 
type the name of the file you want, say, to copy, but only its corresponding list number. 
In the second place, because you don't need to type any path either, for with CliFM you 
browse your files via short commands followed by list numbers; and the thing gets even 
faster with CLiFM bookmarks manager.


General Usage:
ELN = element line number. E.g. "23 - openbox". 23 is the ELN of openbox 

Commands:
- h, help, ?: show this help.
- /*: This is the quick search function. Just type '/' followed by the string you 
    are looking for, and CliFM will list all the matches in the current folder.
- bm, bookmarks: open the bookmarks menu. Here you can add, remove or edit your 
    bookmarks to your liking, or simply cd into the desired bookmark by entering 
    either its list number or its hotkey.
- o, open ELN: open a folder or a file. I you want to open a file with a different 
    program, just add the command name as a second argument, e.g. 'open ELN leafpad' 
- cd [path]: it works just as the built-in 'cd' command.
- b, back: go back to the parent folder.
- pr, prop ELN: display the properties of the selected element.
- ren ELN: rename an element.
- md, mkdir name ... n: create one or more new folders.
- t, touch name ... n: create one or more new files.
- ln, link [sel, ELN] [link_name]: create a simbolic link. The source element could 
  be either a selected element, in which case you has to simply type 'sel' as first 
  argument, or an element listed in the screen, in which case you simply has to specify 
  its list number as first argument. The second argument is always a file name for the 
  symlink.
- s, sel ELN ELN-ELN ... n: select one or multiple elements. Sel command accepts range
    of elements, say 1-6, just as '*' to select all the elements of the current folder. 
- sh, show, show sel: show currently selected elements.
- ds, desel: deselect currently selected elements.
- del [ELN ... n]: With no arguments, del command will delete those elements currently
    selected, if any. Otherwise, when one or more ELN's are passed, it will delete
    only those elements. 
- paste: copy selected elements into the current folder.
- move: move selected elements into the current folder.
- x, term: open a new terminal (xterm by default) in the current path and in a different
     window. 
- v, ver, version: show CliFM version.
- q, quit, exit: quit CliFM.