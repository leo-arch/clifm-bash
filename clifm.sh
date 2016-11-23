#!/bin/sh
#/bin/sh is generally a symlink pointing to the default shell (ex: /bin/bash). If I use /bin/bash
#in the shebang, the script will not run in case bash is not installed.

#! [[ $(echo $SHELL | grep bash) ]] && echo "CliFM can only run in a bash shell." && exit 0

#CliFM was successfuly tested in the following shells: 
#sh, bash, zsh, tcsh, ksh, mksh, fish, dash.

#Note on POSIX compatibility: when using a variable as an argument for a command use double quotes
#(""). Ex: echo "$var"

#BUG: when using the cd built-in command with asterisk (*), it sometimes give an error, but it 
#doesn't when the full dirname is given. It mostly happens when the script has been running and 
#executing some commands for a while (though I'm not sure about what these commands are).

########CliFM############
version="1.5-4"
date="Nov 21, 2016"
clear="printf '\033c'" #I should replace all(?) the calls to the clean command by this one, since
#the former doesn't really clear the screen.

#If the config file doesn't exist yet, create it
if ! [[ -f $HOME/.config/clifm/clifmrc ]]; then
   mkdir -p $HOME/.config/clifm
   echo -e "CLiFM configuration file\n
\n========================\n\n\
default_editor=leafpad\n\
default_terminal=xterm\n\
color=true\n\
welcome_message=true\n\
show_hidden=true\n\
columns=true\n\
starting_path=default\n\
#Default starting path is $HOME, or $PWD is you run CliFM from within a\
running terminal\n
short_prompt=true" > $HOME/.config/clifm/clifmrc
fi

#read the config file
default_editor=$(cat $HOME/.config/clifm/clifmrc | grep "default_editor=" | cut -d"=" -f2)
default_terminal=$(cat $HOME/.config/clifm/clifmrc | grep "default_terminal=" | cut -d"=" -f2)
color=$(cat $HOME/.config/clifm/clifmrc | grep "color=" | cut -d"=" -f2)
welcome_message=$(cat $HOME/.config/clifm/clifmrc | grep "welcome_message=" | cut -d"=" -f2)
show_hidden=$(cat $HOME/.config/clifm/clifmrc | grep "show_hidden=" | cut -d"=" -f2)
columns=$(cat $HOME/.config/clifm/clifmrc | grep "columns=" | cut -d"=" -f2)
starting_path=$(cat $HOME/.config/clifm/clifmrc | grep "starting_path=" | cut -d"=" -f2)
short_prompt=$(cat $HOME/.config/clifm/clifmrc | grep "short_prompt=" | cut -d"=" -f2)
#By default, colored output, hidden files and columns are enabled. They may be disable though by 
#'color off', 'hidden off' and 'column off' respectivelly.
#The starting path is by deafult $HOME, or $PWD is you run CliFM from within a running terminal

#####Colors######

gray='\033[1;30m'
#d_gray='\033[0;30m'
red='\033[1;31m'
d_red='\033[0;31m'
green='\033[1;32m'
d_green='\033[0;32m'
yellow='\033[1;33m'
#d_yellow='\033[0;33m'
blue='\033[1;34m'
#d_blue='\033[0;34m'
magenta='\033[1;35m'
#d_magenta='\033[0;35m'
cyan='\033[1;36m'
d_cyan='\033[0;36m'
white='\033[1;37m'
d_white='\033[0;37m'
NC='\033[0m' #no color
cyan_b=""$'\001'"${d_cyan}"$'\002'""
red_b=""$'\001'"${d_red}"$'\002'""
NC_b=""$'\001'"$NC"$'\002'""

###Sourced scripts####
#source $HOME/scripts/ccolumn.sh

#misc operations
conflicting_commands=( cd mkdir touch )
[[ $(whoami) == "root" ]] && cd /root
[[ $starting_path != "default" ]] && cd "$starting_path"
clifm_functions=( cli load_files show_files select_operation prompt bookmarks_manager properties move_files paste_files symlink delete deselect)
HISTFILE=/tmp/.clifm_hist #tell history command where to find the CliFM commands history file
trap '' 1 2 3 20 #disable kill, interrupt, suspend signals

###FUNCTIONS####
function cli () #Document functions!
{
   #if it was called by the quick search function, inform it to the show_files function, since
   #this function has to replace the folder files list (dir_files) by the found files list (found) 
   found_mark=""
   [[ $1 == "found" ]] && found_mark=$1 && target=$2
   load_files
   if [[ $found_mark == "found" ]]; then
      show_files $found_mark $target
   else
      show_files
   fi
   unset elements
   #draw a line, composed by equal signs (=), between the elements list and the prompt.
   yes "$(echo -e "${blue}=$NC")" | head -$(tput cols) | paste -s -d '' -
   #if this function is invoked by the first time, or if the program is just started, print
   #the welcome message and the help suggestion, otherwise, ommit them.
   if [[ $welcome_message == true ]]; then 
      echo -e "${magenta}Welcome to CLiFM, the text-based file manager!$NC"
      echo -e "Type '${white}help$NC' or '${white}?$NC' for instructions."
   fi
   welcome_message=false
   prompt
}

function load_files ()
{
   unset dir_files
   if [[ $show_hidden == true ]]; then
      ls -A --color=never --group-directories-first > /tmp/list.txt
      #ls -A = do not list implied . and ..
#      dir_files=( $(ls -A --color=never -1) ) #send the output of ls directly to the array
       #ls -AF | nl [or cat -n] will list all the files, including those hidden and excluding .
       #and .., in a numbered form and with a file descriptor ('*'=exec, '/'=dir, '@'=simlink)
   else
      ls --color=never --group-directories-first > /tmp/list.txt
   fi
   longest=0
   while read line; do
      dir_files[${#dir_files[@]}]=$line
      [[ "${#line}" -gt "$longest" ]] && longest=${#line}
      #$longest will be used later (in the show_files function) to order the columns of the
      #listed files.         
   done < /tmp/list.txt
   rm /tmp/list.txt
#NOTE: a shorter alternative to the above would be this:
#unset dir_files
#for i in $PWD/*; do 
#   dir_files[${#dir_files[@]}]=$(echo $i | rev | cut -d"/" -f1 | rev)
#done
#it works fine, but is slower than the ls approach. There are still other alternatives:
# echo * #no hidden files
# printf "%s\n" * #no hidden files
#find . -maxdepth 1
}

function show_files ()
{
   $clear
   ###if it comes from the fast search function, replace the list of elements in the current
   #dir by the list of found elements.
   found_mark=""
   [[ $1 = "found" ]] && found_mark=$1 && target=$2	
   if [[ $found_mark == "found" ]]; then 
      unset dir_files
      for (( i=0;i<${#found[@]};i++ )); do
          dir_files[$i]=${found[$i]}
      done
      unset found
      if [[ ${#dir_files[@]} -gt 1 ]]; then
         echo -e "${#dir_files[@]} matches for ${cyan}$target$NC in ${white}$PWD$NC\n"
      elif [[ ${#dir_files[@]} -eq 1 ]]; then
         echo -e "1 match for ${cyan}$target$NC in ${white}$PWD$NC\n"
      else 
         echo -e "No matches for ${cyan}$target$NC in ${white}$PWD$NC\n"
         read -n1 -sp "Press any key to continue... "
         cli && break
      fi
   else
      echo ""
      [[ ${#dir_files[@]} -eq 0 ]] && echo -e "This folder is empty.\n" && return
   fi
   if [[ $color == false ]]; then
      for (( i=0;i<${#dir_files[@]};i++ )); do
#         echo "$((i+1)) - ${dir_files[$i]}"
         if [[ -h ${dir_files[$i]} ]]; then #if symlink
            echo -e " $((i+1)) - ${dir_files[$i]}@"
         elif [[ -d ${dir_files[$i]} ]]; then
            echo -e " $((i+1)) - ${dir_files[$i]}/"
         elif [[ -x ${dir_files[$i]} ]]; then
            echo -e " $((i+1)) - ${dir_files[$i]}*"
         else
            echo -e " $((i+1)) - ${dir_files[$i]}"
         fi
      done | column
      echo "" && return
   elif [[ $columns == true ]] && [[ ${#dir_files[@]} -le 500 ]]; then
      #The following is my own workaround to the column command issue:to order an array in
      #colored columns. It works fine, but it makes the process of showing files a bit slow.
      #This is why I decided to show columned output only in case the amount of elements is 
      #less than 500.   
      #Calculate the amount of possible columns according to the lenght of the largest element
      #and the width (in columns) of the running terminal. 
      #The longest element of the dir_files array ($longest) has been already calculated in the 
      #load_files function.
      dir_files_num=${#dir_files[@]}
      num_cols=$(echo $(($(tput cols)/$((longest+$((${#dir_files_num}+5)))))))
      #$((longest+$((${#dir_files_num}+5)))) gives the amount of chars of the longest element 
      #plus the chars needed to display the longest ELN plus two space chars. 
      #Ex: " 120 - longest_element "  
      [[ $num_cols -le 0 ]] && num_cols=1 #if longest element is larger than terminal's width,
      #in which case num_cols will be a number between 0 and 1, show only one column.
      for (( i=0;i<${#dir_files[@]};i++ )); do
         diff=0
         #get the difference between the current element and the longest one 
         [[ "${#dir_files[$i]}" -lt "$longest" ]] && diff=$((longest-${#dir_files[$i]}))
         #create a variable with the amount of space chars specified by the aforementioned difference.
         #The idea is to assign this amount of spaces to the current element so that it will become
         #as long as the longest one. In this way, all elements will have the same lenght. 
#         spaces="$(yes " " | head -$diff | paste -s -d '' -)"
#         ELN_n=$((i+1))
#         [[ $diff -gt 0 ]] && spaces="$(yes " " | head -$((diff-${#ELN_n}+3)) | paste -s -d '' -)" || spaces=""   
         [[ $((i+1)) -lt 10 ]] && spaces="$(yes " " | head -$((diff+2)) | paste -s -d '' -)"
         [[ $((i+1)) -ge 10 ]] && spaces="$(yes " " | head -$((diff+1)) | paste -s -d '' -)"         
         [[ $((i+1)) -gt 100 ]] && spaces="$(yes " " | head -$((diff)) | paste -s -d '' -)"
         [[ $((i+1)) -gt 1000 ]] && spaces="$(yes " " | head -$((diff-1)) | paste -s -d '' -)"
         [[ $((i+1)) -gt 10000 ]] && spaces="$(yes " " | head -$((diff-2)) | paste -s -d '' -)"
         #Once all elements have the same lenght, we need to add a \n char to some of them, but not
         #to all, to get the desired columns. Otherwise, we will only get one big line of elements.
         #Where to add the new line char, depends on the amount of columns we want, and the amount
         #of columns we can show depends on the largest element in the list. For this to be done,
         #I use modules: to a certain lenght of the longest element, I assigned a certain value to
         #the module (this value amounts to the amount of columns). Since I don't know any algorithm
         #able to do this for me, I've calculated it manually.   
         #if list number is an even (par) number...
         if [[ $(($((i+1)) % $num_cols)) -eq 0 ]]; then
         #0 means that the element is located at the last column. By contrast, 1, 2, 3, and so 
         #on, means that the element is located at the first, second, or third column respectivelly.
            if [[ -h ${dir_files[$i]} ]]; then #if symlink
               echo -e " $yellow$((i+1))$NC - $cyan${dir_files[$i]}$NC"
            elif [[ -d ${dir_files[$i]} ]]; then
               echo -e " $yellow$((i+1))$NC - $blue${dir_files[$i]}$NC"
            elif [[ -x ${dir_files[$i]} ]]; then
               echo -e " $yellow$((i+1))$NC - $green${dir_files[$i]}$NC"
            else
               echo -e " $yellow$((i+1))$NC - ${dir_files[$i]}"
            fi && last_new_line=1
         else #if not in the last column, add spaces to match the longest element
            if [[ -h ${dir_files[$i]} ]]; then #if symlink
               echo -ne " $yellow$((i+1))$NC - $cyan${dir_files[$i]}$NC$spaces"
            elif [[ -d ${dir_files[$i]} ]]; then
               echo -ne " $yellow$((i+1))$NC - $blue${dir_files[$i]}$NC$spaces"
            elif [[ -x ${dir_files[$i]} ]]; then
               echo -ne " $yellow$((i+1))$NC - $green${dir_files[$i]}$NC$spaces"
            else
               echo -ne " $yellow$((i+1))$NC - ${dir_files[$i]}$spaces"
            fi && last_new_line=0
         fi
      done
      #If the last listed line was echoed with the -n flag, it has one less new line char than 
      #those echoed without this flag. To avoid this inequality, we have to add a new line char 
      #when the last listed element doesn't have it.
      [[ $last_new_line -eq 0 ]] && echo ""    
      echo ""
   else
      for ((i=0;i<${#dir_files[@]};i++ )); do
      ###The output would be great in columns, but I can't make it work.
      #      for ((i=0;i<${#dir_files[@]};i++ )); do
      #         echo -e "$((i+1)) - ${dir_files[$i]}"
      #      done | column
      #This works fine; but whenever I add color code, it stops working. It seems that 'column' 
      #doesn't support color codes. 
      #Workaround: use SandersJ16's column function (from GitHub). It's a bit slow, but it works 
      #fine. Nonetheless, ccolumn sometimes hang up doing I don't know what.
         if [[ -h ${dir_files[$i]} ]]; then #if symlink
            echo -e " $yellow$((i+1))$NC - $cyan${dir_files[$i]}$NC"
         elif [[ -d ${dir_files[$i]} ]]; then
            echo -e " $yellow$((i+1))$NC - $blue${dir_files[$i]}$NC"
         elif [[ -x ${dir_files[$i]} ]]; then
            echo -e " $yellow$((i+1))$NC - $green${dir_files[$i]}$NC"
         else
            echo -e " $yellow$((i+1))$NC - ${dir_files[$i]}"
         fi   
      done
   echo ""
   fi
}

function select_operation ()
{
   ##In case enter is pressed or an empty string is entered, just display a new prompt.
   #Without this condition, enter key of empty string quits the script.
   [ "${elements[0]}" = "" ] && prompt && return
   for (( i=0;i<${#elements[@]};i++ )); do #the elements array has been set in the prompt function
      if [[ $i -eq 0 ]]; then #only perform the case statement with the FIRST introduced value,
      #that is, $i=0, for the first value contains the command to be executed. Then, analyze 
      #the rest, if any. The remaining elements are the arguments passed to the command.
         case ${elements[0]} in
           h|help|"?") 
              $clear
#              echo -e "The help section will be here soon.\n" 
              echo -e "${cyan}CliFM $version$NC ($date), by L. M. Abramovich\n
${white}Genereal Usage: command [arguments]$NC 
ELN = element line number. Ex: in '23 - openbox', '23' is the ELN of 'openbox'.\n 
${white}Commands$NC:
- ${yellow}h, help, ?${NC}: show this help.
- ${yellow}/${NC}*: This is the quick search function. Just type '/' followed by the string you are looking for, and CliFM will list all the matches in the current folder.
- ${yellow}bm, bookmarks${NC}: open the bookmarks menu. Here you can add, remove or edit your bookmarks to your liking, or simply cd into the desired bookmark by entering either its list number or its hotkey.  
- ${yellow}o, open$NC ELN (or path, or filename) [application name]: open either a folder (in \
which case you must specify either its list number or its path), or a file (in which case you \
must specify, again, either its list number or its name). By default, the 'open' function will \
open files with the default application associated to them. However, if you want to open a file \
with a different application, just add the application name as a second argument, e.g. 'open \
ELN (or file name) leafpad'.
- ${yellow}cd${NC}: run the built-in 'cd' command. 
- ${yellow}b, back${NC}: go back to the parent folder.
- ${yellow}pr, prop${NC} ELN: display the properties of the selected element.
- ${yellow}ren${NC} ELN new_name: rename an element.
- ${yellow}mkdir${NC}: run the built-in 'mkdir' command.
- ${yellow}touch${NC}: run the built-in 'touch' command.
- ${yellow}link${NC} [sel, ELN] [link_name]: create a simbolic link. The source element could be either a selected element, in which case you has to simply type 'sel' as first argument, or an element listed in the screen, in which case you simply has to specify its list number as first argument. The second argument is always a file name for the symlink.
- ${yellow}s, sel${NC} ELN ELN-ELN ... n: select one or multiple elements. Sel command accepts range of elements, say 1-6, just as '*' to select all the elements of the current folder. 
- ${yellow}sh, show, show sel${NC}: show currently selected elements.
- ${yellow}ds, desel${NC}: deselect currently selected elements.
- ${yellow}del${NC} [ELN ... n]: With no arguments, del command will delete those elements currently selected, if any. Otherwise, when one or more ELN's are passed to del, it will delete only those elements. 
- ${yellow}paste${NC}: copy selected elements into the current folder.
- ${yellow}move${NC}: move selected elements into the current folder.
- ${yellow}prompt${NC}: show the entire prompt.
- ${yellow}x, term${NC}: start a new terminal (xterm by default) in the current path and in a different window. 
- ${yellow}clr${NC}: refresh the screen.
- ${yellow}color${NC} [on off]: toggle colored output on/off.
- ${yellow}hidden${NC} [on off]: toggle hidden files on/off.
- ${yellow}col,columns${NC} [on off]: toggle columns on/off.
- ${yellow}hist, history clean${NC}: clean CliFM commands history.
- ${yellow}v, ver, version${NC}: show CliFM version details.
- ${yellow}q, quit, exit${NC}: quit CliFM.
\nBesides the above listed commands, in CliFM you can run every built-in Linux command or some \
other application by simply typing the command name and the arguments, if any, you want to be \
passed to it. Note that in case you want to use a non-CliFM command, 'mv' for instance, instead of 'ren', \
you won't be able to use the elements list numbers offered by CLiFM.
In case you want to run an external command whose name conflicts with some of the CliFM commands, \
for instance, 'sh', you can tell CliFM you want to run an external command by simply \
typing the command name preceded by a colon. Ex: ':sh'.
\n${white}Config file$NC: $HOME/.config/clifm/clifmrc
Here you can permanently set up some options such as color, columns, welcome message, starting \
path, default text editor and terminal, and hidden files.\n"
              read -rn1 -sp "Press any key to exit help... "
              cli && return;;
           #NOTE: Add: 'link' for symbolic links 
           bm|bookmarks) bookmarks_manager && cli && return;;
           b|back)
              #if it comes from the fast search function, don't cd .., for the fast search
              #function uses a different list of elements (the 'found' array). So, going back 
              #in this case would mean to show the original list of elements (dir_files) without
              #modifications.
              if [[ $found_mark == "found" ]]; then
                 #go back to the screen before the quick search.
                 cd "$old_PWD" && cli && return
              else
                 cd .. && cli && return
              fi;;
           o|open)
              if [[ -f ${elements[$i+1]} ]]; then
#              if [[ ${dir_files[@]} == *"${elements[$i+1]}"* ]]; then
                 if ! [[ -z ${elements[$i+2]} ]]; then
                    if [[ $(command -v ${elements[$i+2]}) ]]; then
                       (nohup ${elements[$i+2]} "${elements[$i+1]}" &) > /dev/null 2>&1
                       prompt && return
                    else
                       echo -e "open: '${elements[$i+2]}' doesn't exist."
                       prompt && return                       
                    fi
                 else
                    (nohup xdg-open "${elements[$i+1]}" &) > /dev/null 2>&1
                    prompt && return
                 fi
#              else
#                 echo "open: ${elements[i+1]} is not a valid file name."
#                 prompt && return
              fi
              if [[ -d ${elements[$i+1]} ]]; then
                 cd "${elements[$i+1]}"
                 cli && return
              fi
              #if the first argument is neither a file nor a directory...
              if ! [[ -z ${elements[$((i+1))]} ]] && ! [[ ${elements[$i+1]} -gt ${#dir_files[@]} ]]; then
              #${elements[$((i+1))]}, namely, the first argument.
                 open_file="${dir_files[$((elements[$((i+1))]-1))]}"
                 if ! [[ -z ${elements[$((i+2))]} ]]; then
                    if [[ $(command -v ${elements[$i+2]}) ]]; then
                       open "$open_file" ${elements[$i+2]} #&& prompt && return
                    else
                       echo -e "open: '${elements[$i+2]}' doesn't exist."
                       prompt && return
                    fi
                 else
                    open "$open_file" 
                 fi
              else
                 echo "open: You must specify a valid element."
                 prompt && return
              fi;;
              ##NOTE: thanks to both the 'back' option above and this one to open folders, cli
              #has become a basic files navigator!!!
           /*) ####QUICK SEARCH function (or something like that). Great!!!
              target=${elements[$i]:1} #remove "/" from search string.             
              #search for target in the listed elements array and save matches in a new array.
              for (( i=0;i<${#dir_files[@]};i++ )); do 
                 if [[ ${dir_files[$i]} == $target ]]; then
                     found[${#found[@]}]=${dir_files[$i]}
                  fi
              done
              #old_PWD saves the path where the quick search function were called, so that when
              #calling the 'back' function it will not redirect the user to the parent directory,
              #but to screen previous to the quick search screen (both paths are the same).
              found_mark="found" && old_PWD=$PWD
              set -f #disable globbing, that is, wildcards expansion. The target will be printed
              #verbatim in the found elements screen (show_files function). Ex: "Doc*"
              #instead of "Documents".  
              cli $found_mark $target
              set +f && return;; #reenable globbing
           pr|prop)
              [[ -z ${elements[1]} ]] && echo "Usage: prop ELN." && prompt && return
              if ! [[ -z ${elements[$((i+1))]} ]]; then
                 prop_file="${dir_files[$((elements[$((i+1))]-1))]}"
                 properties "$prop_file" && cli && return
              else
                 echo "prop: You must provide a file number." && prompt && return
              fi;;
           del) 
              ##if no argument were passed...
              [[ ${#elements[@]} -eq 1 ]] && delete && cli && return
              #remove the first value of the 'elements' array, since it contains 'del'.
              elem_no_del=( $(echo "${elements[@]:1}") )
              if [[ ${elements[@]:1:1} == "*" ]]; then
                 del_element="all"
                 delete $del_element
              else
                 for (( i=0;i<${#elem_no_del[@]};i++ )); do
                    if [[ $(echo "${elem_no_del[$i]}" | sed 's/[0-9]//g') ]]; then
                       if [[ ${dir_files[@]} == *${elem_no_del[@]}* ]]; then
                          del_element=${elem_no_del[@]} #if string, assign everything after 'del'
                          #to del_element, for it is supposed that that is the file name to delete
                          #Then, break the loop, for, having already assigned everything, there
                          #is no need to continue
                          delete "$del_element" && break
                       else 
                          echo "delete: Invalid file name." && prompt && return
                       fi
                    else 
                       if [[ ${elem_no_del[$i]} -ne 0 ]] && [[ ${elem_no_del[$i]} -le ${#dir_files[@]} ]]; then
                          del_element="${dir_files[$((elem_no_del[$i]-1))]}" #if list number
                          delete "$del_element"
                       else
                          echo "delete: Invalid file number." && prompt && return
                       fi
                    fi
                 done
              fi
              unset elem_no_del && cli && return;;
           ren) 
              [[ -z ${elements[1]} ]] && echo "Usage: ren ELN new_name." && prompt && return
              if ! [[ -z ${elements[$((i+1))]} ]] && [[ ${elements[$((i+1))]} -le ${#dir_files[@]} ]] && ! [[ ${elements[$((i+1))]} -eq 0 ]]; then
                 if ! [[ -z ${elements[$((i+2))]} ]]; then
                    ren_element="${dir_files[$((elements[$((i+1))]-1))]}"
                    mv "$ren_element" "${elements[$((i+2))]}" && cli && return
                 else
                    ren_element="${dir_files[$((elements[$((i+1))]-1))]}"
                    echo "Enter new name: "
                    read -erp "$(echo -e "${dir_files[$((elements[$((i+1))]-1))]}\r")" new_name
                    #Display the old file name and move the cursor to the beginning of the line.
                    #This still doesn't allow me to move the cursor forward with the arrow keys,
                    #but only typing some chars 
                    ! [[ -z $new_name ]] && mv "$ren_element" "$new_name" && cli && return
                    prompt && return
                 fi
              else 
                 echo "ren: You must provide a valid file number."
                 prompt && return
              fi;;
           #I removed 'ln' in order for it not to conflict with the built-in 'ln' command
           link) symlink;;
           s|sel)
              [[ -z ${elements[1]} ]] && echo "Usage: sel [ELN]" && prompt && return 
              #assign all the elements of the "elements" array to another array but excluding 
              #the first value, namely, 'sel'.
              elements[0]="sel" #see note to 'mkdir' function.
              for (( i=0;i<${#elements[@]};i++ )); do
                  if ! [[ ${elements[$i]} == "sel" ]]; then
                    elem_no_sel[${#elem_no_sel[@]}]=${elements[$i]}
                 fi
              done
              #now go through the new array and save in sel_file array what is needed.
              for (( j=0;j<${#elem_no_sel[@]};j++ )); do
                 #if sel's FIRST argument is "*", add all elements (in dir_files) to the array
                 #of selected elements (sel_file) and exit.              
                 if [[ ${elem_no_sel[0]} == "*" ]]; then
                    for ((k=0;k<${#dir_files[@]};k++ )); do
                       sel_file[${#sel_file[@]}]="$PWD/${dir_files[$k]}"
                    done
                 else
                 #if not "*", then if it is a range, add the whole range to sel_file array.   
                    if [[ ${elem_no_sel[$j]} == *"-"* ]]; then
                    #:Note: changing the IFS to "-", and then restore the orig value, would be 
                 #another option.
                    a="$(echo ${elem_no_sel[$j]} | cut -d"-" -f1)"
                    b="$(echo ${elem_no_sel[$j]} | cut -d"-" -f2)"
                       if [[ $a -ge $b ]] || [[ $a -gt ${#dir_files[@]} ]] || [[ $b -gt ${#dir_files[@]} ]]; then
                          echo "Wrong range." && prompt && return
                       else
                          for (( l=$a;l<=$b;l++ )); do
                             sel_file[${#sel_file[@]}]="$PWD/${dir_files[$((l-1))]}"
                          done
                       fi
#                   #if the element neither '*' nor a range, then...
                    #if it is neither a number nor is greater than listed elements, add it to 
                    #sel_file array.
                    else
                       if [[ $(echo ${elem_no_sel[$j]} | sed 's/[0-9]//g') ]] || [[ ${elem_no_sel[$j]} -gt ${#dir_files[@]} ]]; then
                          echo "Element ${elem_no_sel[$j]} doesn't exist." 
                          unset elem_no_sel && prompt && return
                       else
                          sel_file[${#sel_file[@]}]="$PWD/${dir_files[$((elem_no_sel[$j]-1))]}"
                       fi
                    fi
                 fi
              done
              unset elem_no_sel #clear the array of elements (minus sel) for a new selection.
              #print selected files 
              case ${#sel_file[@]} in
                0) echo -e "No element selected.";;
                1) echo -e "${cyan}1$NC element selected: ${sel_file[@]}";;
                *) echo -e "${cyan}${#sel_file[@]}$NC elements selected: Type 'sh' to see them.";;
               esac 
              #sel_file will keep all the selected elements until 'desel' command is executed.
               prompt && return;;
           ds|desel) deselect;; 
           sh|show|"show sel") ##I should rewrite this function for it to be able to show its
           #output in columns.
              clear
              if [[ ${#sel_file[@]} -ne 0 ]]; then
                 echo -e "Selected elements: \n"
                 for (( i=0;i<${#sel_file[@]};i++ )); do
                    if [[ -h ${sel_file[$i]} ]]; then #if symlink
                       echo -e " $yellow$((i+1))$NC - $cyan${sel_file[$i]}$NC"
                    elif [[ -d ${sel_file[$i]} ]]; then
                       echo -e " $yellow$((i+1))$NC - $blue${sel_file[$i]}$NC"
                    elif [[ -x ${sel_file[$i]} ]]; then
                       echo -e " $yellow$((i+1))$NC - $green${sel_file[$i]}$NC"
                    else
                       echo -e " $yellow$((i+1))$NC - ${sel_file[$i]}"
                    fi
                 done
              else
                 echo "There are no selected elements."
              fi
              echo ""
              read -rn1 -sp "Press any key to continue... "
              cli && return;;
           #paste and move functions will paste and move, respectivelly, all the selected files 
           #into the actual folder
           paste) paste_files && cli && return;;
           move) move_files && cli && return;;
           #'term' will open a terminal in the current path in a different window.
           clr) cli && return;;
           color) 
              [[ -z ${elements[i+1]} ]] && echo "Usage: color [on off]." && prompt && return
              case ${elements[$i+1]} in
                 off) color=false && cli && return;;
                 on) color=true && cli && return;;
                 *) echo "color: Wrong argument. Usage: color [on off]." && prompt && return
              esac;; 
           hidden) 
              [[ -z ${elements[i+1]} ]] && echo "Usage: hidden [on off]." && prompt && return
              case ${elements[$i+1]} in
                 off) show_hidden=false && cli && return;;
                 on) show_hidden=true && cli && return;;
                 *) echo "hidden: Wrong argument. Usage: hidden [on off]." && prompt && return
              esac;;
           col|columns) 
              [[ -z ${elements[i+1]} ]] && echo "Usage: columns [on off]." && prompt && return
              case ${elements[$i+1]} in
                 off) columns=false && cli && return;;
                 on) columns=true && cli && return;;
                 *) echo "columns: Wrong argument. Usage: columns [on off]." && prompt && return
              esac;;
           prompt) pwd && prompt && return;;
           x|term) (nohup $default_terminal &) > /dev/null 2>&1 && prompt && return;;
           v|ver|version) 
              echo -e "CliFM $version ($date), by L. M. Abramovich"
              prompt && return;;
           q|quit|exit) exit 0;; #rm /tmp/.clifm_hist && exit 0;;
           hist|history) 
              if [[ ${elements[1]} == "clean" ]]; then
                 rm /tmp/.clifm_hist && cli && return
              else
                 echo -e "CliFM: '${elements[@]}' is not a valid command or application. Type 'help' to know more about CLiFM commands." && prompt && return
              fi;;
           :*|*)
           #Allow the user to run built-in commands and applications from CliFM's prompt
           #In case the user wants to run a command whose name conflicts with some of the CliFM
           #commands, for instance, 'sh', he/she can tell CliFM he/she wants to run running an 
           #external command by simply typing ":command_name".
              #remove colon (:), if any, from the command.
              [[ ${elements[0]} == ":"* ]] && elements[0]=${elements[0]:1}
              cmd_path_found=false
              #prevent the user from invoking a CliFM internal function
              #if command is not a clifm function and it exists... 
              if ! [[ ${clifm_functions[@]} = *" ${elements[0]} "* ]] && [[ $(command -v ${elements[0]}) ]]; then 
                 #conflicting_commands are those which are built-in but need to refresh the elements
                 #list shown in CLiFM screen, for instance: cd, mkdir, and touch 
                 if [[ ${conflicting_commands[@]} != *${elements[0]}* ]]; then
                    #If the command to be executed is has a desktop file, it's
                    #quite possible that it is a GUI program, and in this case, it may be run as
                    #an independent process. However, this method isn't totally reliable. htop, for
                    #instance, appears in my applications folder, despite the fact that it isn't
                    #a gui program. This is why we need to take a look inside the desktop file,
                    #to see whether it is console only or not.
                    if [[ -f /usr/share/applications/${elements[0]}.desktop ]]; then
                       cmd_path=$(dirname /usr/share/applications/${elements[0]}.desktop)
                       cmd_path_found=true
                    elif [[ -f /usr/local/share/applications/${elements[0]}.desktop ]]; then
                       cmd_path=$(dirname /usr/local/share/applications/${elements[0]}.desktop)
                       cmd_path_found=true
                    elif [[ -f /$HOME/.local/share/applications/${elements[0]}.desktop ]]; then
                       cmd_path=$(dirname $HOME/.local/share/applications/${elements[0]}.desktop)
                       cmd_path_found=true
                    fi                    
                    #If the command has a desktop file and it doesn't work only inside a 
                    #terminal ("Categories=ConsoleOnly" in the command desktop file)...
                    if [[ $cmd_path_found == true ]] && ! [[ $(cat ${cmd_path}/${elements[0]}.desktop 2>/dev/null | grep "ConsoleOnly") ]]; then
                       #Allow the user to use an ELN as an argument for the program to be executed
                       #if the element to be opened is a number and it's contained in dir_files
                       #open the element corresponding to that number
                       if ! [[ $(echo "${elements[1]}" | sed 's/[0-9]//g') ]]; then
                          if [[ ${elements[1]} -ne 0 ]] && [[ ${elements[1]} -le ${#dir_files[@]} ]]; then
                             (nohup ${elements[0]} ${dir_files[$(( ${elements[1]}-1 ))]} &) > /dev/null 2>&1; prompt && return
                          else
                             echo "Clifm: ${elements[1]} is not a valid element." && prompt && return
                          fi
                       else
                          #if the element is not a number, simply use it as an argument for the
                          #command to be run
                          (nohup ${elements[@]} &) > /dev/null 2>&1; prompt && return
                       fi
                    else
                       eval "${elements[@]}"; prompt && return
                    fi
                 else
                    eval "${elements[@]}" 2>/dev/null
                    if [[ $? -eq 0 ]]; then
                       cli && return
                    else
                       echo "${elements[0]}: Error." && prompt && return
                    fi
                     #Here's a lesson: if I write "command && cli && return", this won't work 
                     #if the command fails (for "cli && return" will be executed only provided
                     #the precedent command was successful), and the script will get killed. To 
                     #prevent this I must write instead: "command; cli && return".
                 fi
              else 
                 echo -e "CliFM: '${elements[0]}' is not a valid command or application. Type 'help' to know more about CLiFM commands." && prompt && return
              fi;;
         esac
      fi
   done
}

function prompt ()
{
   if [[ $PWD == *"$HOME"* ]]; then
      new_PWD=$(echo ${PWD/$HOME/\~}) #replace $HOME by tilde (~)
   else 
      new_PWD=$PWD
   fi
   #reduce prompt when it becomes too long
   if [[ $short_prompt = true ]]; then
      [[ ${#new_PWD} -ge 35 ]] && new_PWD=$(echo $new_PWD | rev | cut -d"/" -f1 | rev) && new_PWD=$(echo "...$new_PWD")
   fi
   user=$(whoami)	
   if [[ $user == "root" ]]; then
      set -o history #enable bash history, which by default is disabled in non-interactive
      #shells, like scripts
      read -erp "$(echo -e "$red_b[$user: $new_PWD] \$ $NC_b")" -a elements
      #the -e option allows me to move the cursor backward and forward with the arrow keys. 
      #Otherwise, some weird characters ("^[[D", for instance) appears when the arrow keys are 
      #pressed. 
      #I use echo inside the read prompt in order to be able to use variables and colors.
      #Color codes generate a problem here. When the prompt line reaches approx the 54 
      #chars, is starts displaying the new chars in the beginning of the same line, overwriting
      #those already typed. The same happens when using tput.
      #SOLUTION: "$'\001'" and "$'\002'" tells 'read' that color codes between them are 
      #non-printing chars and that, therefore, it must not count them. In this way, it doesn't 
      #think that the line, due to color codes, is longer than it actually is.      
      set +o history #disable history in order to record only what is typed in the prompt
      #do not save exit commands
      if ! [[ ${elements[@]} == "q" ]] && ! [[ ${elements[@]} == "quit" ]] && ! [[ ${elements[@]} == "exit" ]]; then
         echo "${elements[@]}" >> /tmp/.clifm_hist
      fi
   else
      set -o history
      read -erp "$(echo -e "$cyan_b[$user: $new_PWD] \$ $NC_b")" -a elements
      set +o history
      if ! [[ ${elements[@]} == "q" ]] && ! [[ ${elements[@]} == "quit" ]] && ! [[ ${elements[@]} == "exit" ]]; then
         echo "${elements[@]}" >> /tmp/.clifm_hist
      fi
   fi
select_operation
}

####BOOKMARKS######
function bookmarks_manager ()
{
   #This function is aimed to create a little bookmarks manager within the bash shell. It reads
   #the bookmarks from a file, which can be accessed from within the function itself, allowing
   #the user to freely add, remove or modify the bookmarks. They can be selected in two different 
   #ways. Firstly, by the order number, and secondly, by a hotkey (managed by the user). It is 
   #also possible to use tags for each bookmark. A line containing a hotkey, a tag, and a path 
   #(though only the last one is necessary) looks like this: [t]test:/path/to/test
   $clear
   counter=0
   unset bookmarks #if I don't unset (clear) the array, it gets bigger and bigger with any new
   #execution of the script. This doesn't happen with mapfile.
   bookmarks_dir="$HOME/.config"
   ! [[ -d $bookmarks_dir ]] && mkdir "$bookmarks_dir"
#   bookmarks_dir="/home/$user/.config"   
   #print the bookmarks section header
   echo -e "${white}CliFM bookmarks manager\n"
   if ! [[ -f $bookmarks_dir/bookmarks.txt ]]; then
      touch $bookmarks_dir/bookmarks.txt
      echo "#Example: [t]test:/path/to/test" > $bookmarks_dir/bookmarks.txt
   fi
   #Save bookmarks file in an array ommitting commented lines
   while read line; do
      ! [[ $line == "#"* ]] && bookmarks[${#bookmarks[@]}]=$line
   done < $bookmarks_dir/bookmarks.txt
   if [[ ${#bookmarks[@]} -eq 0 ]]; then
      read -rp "No bookmarks. Do you want to edit the bookmarks file (y/n)? " answer
      case $answer in
        y) $default_editor "$bookmarks_dir/bookmarks.txt" && bookmarks_manager && return;;
        n) bookmarks_manager && return;;
        *) echo "Wrong answer." && bookmarks_manager && return;;
      esac
      ##'return' simply quits the function, while 'exit' quits the shell itself
   fi      
   for (( i=0;i<${#bookmarks[@]};i++ )); do
      counter=$((counter+1))
      #if there is a hotkey (always between brackets) (i.e. [t]test:/test)
      if [[ $(echo ${bookmarks[$i]} | grep ".*\[.*\].*") ]]; then
         #save the hotkey in an array using the same index of the bookmark where the hotkey
         #was found. In this way, we can link the two together later.
         h_key[$i]="$(echo ${bookmarks[$i]} | grep ".*\[.*\].*" | sed 's/.*\[\([^]]*\)\].*/\1/g')"
         #save hotkey, bookmark (if any), and path in different variables to be printed later
         bm="$(echo ${bookmarks[$i]} | cut -d"]" -f2)"
         path="$(echo ${bookmarks[$i]} | cut -d"]" -f2)"
         hkey="$(echo ${bookmarks[$i]} | grep -o "\[.*\]")"
      else
         #assign empty content to the hotkeys array in order to preserve the paralel with the
         #bookmarks array
         h_key[$i]=""
         bm=${bookmarks[$i]}
         path=${bookmarks[$i]}
         hkey=""
      fi
      #bookmarks for paths goes before ":" (i.e. bookmark:/path/)
      #if there is a bookmark...
      if [[ ${bookmarks[$i]} == *":"* ]]; then
         bm="$(echo ${bookmarks[$i]} | cut -d"]" -f2 | cut -d":" -f1)"
         path="$(echo ${bookmarks[$i]} | cut -d":" -f2)"
      fi
      #if the path indicated in the bookmark doesn't exist, listed shadowed, delete
      #the content of this position of the array to prevent access to a non-existent 
      #folder. 
      if ! [[ -d $path ]]; then 
         echo -e " ${gray}$counter - ${gray}$hkey$bm$NC"
         valid_path[$i]=false
      else
         echo -e " ${yellow}$counter$NC - ${white}$hkey${cyan} $bm$NC" #| grep --color "\[.*\]" 
      fi
   done
   echo -ne "\nChoose a bookmark ([e]dit, [q]uit): " 
   read -r sel_bm
   case $sel_bm in
      e|edit) $default_editor "$bookmarks_dir/bookmarks.txt" && return;;
      q|quit|exit) return;;
      #in case someone uses 'e','q','exit', or 'quit' as hotkey, this would produce an error
      #if not a number, or some char remains after removing all numbers...
      *) if [[ $(echo $sel_bm | sed 's/[0-9]//g') ]]; then 
            if [[ ${h_key[@]} == *"$sel_bm"* ]]; then #if input is contained in the hotkeys array
               for (( i=0;i<${#h_key[@]};i++ )); do #get the array index of the hotkey 
                  [[ $sel_bm == ${h_key[$i]} ]] && index=$i
               done
               #it was for this that the paralelism between bookmarks and hotkeys was to be conserved
               #leave only path, ommitting hotkey and bookmark, if any
               if ! [[ ${valid_path[$index]} == false ]]; then
                  cd $(echo ${bookmarks[$index]} | cut -d"]" -f2 | cut -d":" -f2) && return
               else 
                  read -rn1 -sp "Invalid path. Press any key to continue... " && bookmarks_manager && return
               fi
            else 
               read -rn1 -sp "Invalid hotkey. Press any key to continue... " && bookmarks_manager && return
            fi            
         fi
      ;;
   esac
   #At this point, we know the input to be a number. So, let's first validate it...
   ( [[ $sel_bm -eq 0 ]] || [[ $sel_bm -gt ${#bookmarks[@]} ]] ) && read -n1 -sp "Invalid bookmark number. Press any key to continue... " && bookmarks_manager && return
   if ! [[ ${valid_path[$((sel_bm-1))]} == false ]]; then #if not an invalid path...   
      #if the line contains a bookmark or a hotkey, ommit them, leaving only the path
      cd $(echo ${bookmarks[$((sel_bm-1))]} | cut -d"]" -f2 | cut -d":" -f2)
   else 
      read -rn1 -sp "Invalid path. Press any key to continue... " && bookmarks_manager && return
   fi
}

function properties ()
{
prop_file=$1 
if [[ -h "$PWD/$prop_file" ]]; then #if symlink
   echo -e "$PWD/${cyan}$prop_file$NC"
elif [[ -d "$PWD/$prop_file" ]]; then
   echo -e "$PWD/${blue}$prop_file$NC"
elif [[ -x "$PWD/$prop_file" ]]; then
   echo -e "$PWD/${green}$prop_file$NC"
else
   echo -e "$PWD/${white}$prop_file$NC"
fi
echo "File type: $(file "$prop_file" | cut -d":" -f2 | sed '0,/ /s///')" #| awk '{$1=""; print $0}' #| sed '0,/ /s///'
if [[ -d $prop_file ]]; then
   echo -e "Permisions: \n $(ls -lh --color=always $prop_file)"
else
   echo "Permissions: $(ls -lh "$prop_file" | awk '{for (i=1;i<9;i++) printf("%s%s",$i,(i==t)?"\n":OFS)}')"
fi
prompt && return
}

function open ()
{
   open_file="$PWD/$1"
   if ! [[ -z $2 ]]; then
      app=$2 && (nohup $app "$open_file" &) > /dev/null 2>&1
      prompt && return
   elif [[ -d $open_file ]]; then
      cd "$open_file" && cli && return
   else
      (nohup xdg-open "$open_file" &) > /dev/null 2>&1
      prompt && return
   fi
}

function symlink ()
{ #rewrite in a simpler way.
if ! [[ -z ${elements[$i+1]} ]]; then
   if ! [[ $(echo ${elements[$i+1]} | grep [a-Z]) ]] && [[ ${elements[$i+1]} -le ${#dir_files[@]} ]]; then
      if ! [[ -z ${elements[$i+2]} ]]; then
         link_elem="$PWD/${dir_files[$((elements[$i+1]-1))]}"
         ln -s $link_elem ${elements[$i+2]}
         cli && return
      else
         echo "link: You must provide a path and name for the symbolic link."
         prompt && return
      fi 
   else
      if [[ ${elements[$i+1]} == "sel" ]]; then
         if [[ ${#sel_file[@]} -gt 1 ]]; then
            echo "link: Cannot symlink multiple elements at the same time."
            prompt && return
         else 
            if [[ ${#sel_file[@]} -eq 0 ]]; then
               echo "link: There are no selected elements."
               prompt && return
            else
               ln -s ${sel_file[@]} ${elements[$i+2]}
               cli && return
            fi
         fi
      else
         echo "Usage: ln sel 'link_name'"
         prompt && return
      fi
   fi
else
   echo "Usage: ln sel 'link_name'"
   prompt && return
fi
}

function paste_files ()
{
   ###Should I TRAP signs? Yes, files might become corrupted if the process is interrupted.
#   trap '' 1 2 3 20 #disable SIGHUP, SIGINT (Ctrl-c), SIGQUIT (Ctrl-4), and SIGSTP (Ctrl-z)
   for (( i=0;i<${#sel_file[@]};i++ )); do
      if [[ -d ${sel_file[$i]} ]]; then
         cp -r "${sel_file[$i]}" .
      else
         cp "${sel_file[$i]}" .
      fi
   done
   unset sel_file
#   trap 1 2 3 20 #reenable SIGHUP, SIGINT (Ctrl-c), SIGQUIT (Ctrl-4), and SIGSTP (Ctrl-z)
}

function move_files ()
{
#   trap '' 1 2 3 20
   for (( i=0;i<${#sel_file[@]};i++ )); do
      mv "${sel_file[$i]}" .
   done
   unset sel_file
#   trap 1 2 3 20
}

function delete ()
{
   #just as the deselect function, 'delete' should allow the user to tell which of the selected 
   #elements he/she whishes to delete.
   if [[ $# -eq 0 ]]; then #if no arguments were passed, it will delete all the selected elements
      [[ ${#sel_file[@]} -eq 0 ]] && echo "del: There are no selected files." && prompt && return 
      echo ""
      for (( i=0;i<${#sel_file[@]};i++ )); do
         echo " ${sel_file[$i]}"
      done
      echo -ne "\nThe above selected elements will be deleted. Do you wish to continue [y/n]? "
      read -r answer
      case $answer in
        n) return;;
        y)
        ###Should I TRAP signs? Yes.
#           trap '' 1 2 3 20
           for (( i=0;i<${#sel_file[@]};i++ )); do
              if [[ -d ${sel_file[$i]} ]]; then
                 rm -r "${sel_file[$i]}" 
              else
                 rm "${sel_file[$i]}"
              fi
           done
           unset sel_file;;
#           trap 1 2 3 20;;
        *) echo "Wrong answer." && prompt && return;;
      esac
   else
      if [[ $(echo $1 | sed 's/[0-9]//g')  ]]; then #if string...
         del_element=$@
      else
         del_element=$1
      fi
      if [[ $del_element == "all" ]]; then
         echo -ne "Are you sure you want to delete ${white}all$NC the elements in this folder [y/n]? "
         read -r answer
         case $answer in
           y) 
              trap 1 2 3 20 #reenable kill signs to allow the user to stop the operation
              rm -r * 
              trap '' 1 2 3 20 && return;;
           n) prompt && return;;
           *) echo "Wrong answer." && prompt && return;;
         esac
      else      
         echo -ne "Are you sure you want to delete ${white}$PWD/$del_element$NC [y/n]? "   
         read -r answer
         case $answer in
           y)
#             trap '' 1 2 3 20
             if [[ -d $del_element ]]; then
                rm -r "$PWD/$del_element"
             else
                rm "$PWD/$del_element"
             fi
#             trap 1 2 3 20
             return;;
           n) return;;
           *) echo "Wrong answer." && prompt && return;;
         esac
      fi
   fi
}

function deselect ()
{
   clear
   if [[ ${#sel_file[@]} -ne 0 ]]; then
      echo -e "Selected elements: \n"
      for (( i=0;i<${#sel_file[@]};i++ )); do
         if [[ -h ${sel_file[$i]} ]]; then #if symlink
            echo -e " $yellow$((i+1))$NC - $cyan${sel_file[$i]}$NC"
         elif [[ -d ${sel_file[$i]} ]]; then
            echo -e " $yellow$((i+1))$NC - ${blue}${sel_file[$i]}$NC"
         elif [[ -x ${sel_file[$i]} ]]; then
            echo -e " $yellow$((i+1))$NC - $green${sel_file[$i]}$NC"
         else
            echo -e " $yellow$((i+1))$NC - ${sel_file[$i]}"
         fi
      done
      echo -e "\nEnter 'q' to quit."
      echo -ne "Elements to be deselected (ex: 1 or *)? "
      read -r desel_element
      [[ $desel_element == "" ]] && cli && return 
      [[ $desel_element == "q" ]] && cli && return
      if [[ $desel_element == "*" ]] || [[ $desel_element == "all" ]]; then
         read -rn1 -sp "All elements have been deselected. Press any key to continue... "
         unset sel_file && cli && return
      fi
      if [[ $(echo $desel_element | sed 's/[0-9]//g') ]] || [[ $desel_element -gt ${#sel_file[@]} ]]; then
         echo -e "Element '$desel_element' doesn't exist."
         prompt && return
      fi 
      echo -e "${white}${sel_file[$((desel_element-1))]}$NC has been deselected."
      #remove the element from the sel_file array. Quite confusing ahh!
      sel_file=(${sel_file[@]/${sel_file[$((desel_element-1))]}})
      read -rn1 -sp "Press any key to continue... "
      cli && return 
   else
      echo -e "desel: There are no selected elements.\n"
      read -rn1 -sp "Press any key to continue... "
      cli && return
   fi
}

cli
trap 1 2 3 20
