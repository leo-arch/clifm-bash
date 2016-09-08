#!/bin/sh

#! [[ $(echo $SHELL | grep bash) ]] && echo "CliFM can only run in a bash shell." && exit 0

#CliFM was successfuly tested in the following shells: 
#sh, bash, zsh, tcsh, ksh, mksh, fish, dash.

#On POSIX compatibility: when using a variable as an argument for a command use double quotes
#(""). Ex: echo "$var"

########CliFM############
version="1.4-8"
year="2016"

#####Colors######

#gray='\033[1;30m'
#d_gray='\033[0;30m'
red='\033[1;31m'
d_red='\033[0;31m'
green='\033[1;32m'
d_green='\033[0;32m'
yellow='\033[1;33m'
#d_yellow='\033[0;33m'
blue='\033[1;34m'
#d_blue='\033[0;34m'
#magenta='\033[1;35m'
#d_magenta='\033[0;35m'
cyan='\033[1;36m'
d_cyan='\033[0;36m'
white='\033[1;37m'
d_white='\033[0;37m'
NC='\033[0m' #no color

###Sourced scripts####
#source $HOME/scripts/ccolumn.sh

default_editor="leafpad"
default_terminal="xterm"

###FUNCTIONS####
function cli () #Document functions!
{
   #if it comes from the quick search function, inform it to the show_files function, since
   #this function has to replace the folder files list (dir_files) by the found files list (found) 
   found_mark=""
   [[ $1 == "found" ]] && found_mark=$1 && target=$2
   clear && load_files
   if [[ $found_mark == "found" ]]; then
      show_files $found_mark $target
   else
      show_files
   fi
   echo ""
   unset elements
   echo -e "Type 'help' or '?' for help."
   prompt
}

function load_files ()
{
   unset dir_files
   ls -a > /tmp/list.txt
   while read line; do
      if [[ $line != "." ]] && [[ $line != ".." ]]; then
         dir_files[${#dir_files[@]}]=$line
      fi
   done < /tmp/list.txt
   rm /tmp/list.txt
}

function show_files ()
{
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
         echo -e "${#dir_files[@]} matches for ${cyan}'$target'$NC in ${white}$PWD$NC\n"
      elif [[ ${#dir_files[@]} -eq 1 ]]; then
         echo -e "1 match for ${cyan}'$target'$NC in ${white}$PWD$NC\n"
      else 
         echo -e "No matches for ${cyan}'$target'$NC in ${white}$PWD$NC\n"
         read -n1 -sp "Press any key to continue... " key
         clear && cli && break
      fi
   else
      echo ""
      [[ ${#dir_files[@]} -eq 0 ]] && echo "This folder is empty." && return
   fi
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
   done #| ccolumn
}

function select_operation ()
{
#   IFS_old=$IFS; IFS=" " #for some reason the default value of IFS doesn't allow me to enter
   #multiple values into the array, since the whole input is taken as one. However, it is 
   #supposed that space, along with newline and tab, is a default value of IFS.
   read -a elements
   ##In case enter is pressed or an empty string is entered, just display a new prompt.
   #Without this condition, enter key of empty string quits the script.
   [ "${elements[0]}" = "" ] && prompt && return
#   IFS=$IFS_old #restore the original value of IFS
   for (( i=0;i<${#elements[@]};i++ )); do
      if [[ $i -eq 0 ]]; then #only perform the case statement with the FIRST introduced value,
      #that is, $i=0, for the first value contains the command to be executed. Then, analyze 
      #the rest, if any. The remaining elements are the arguments passed to the command.
         case ${elements[$i]} in
           h|help|"?") 
              clear
#              echo -e "The help section will be here soon.\n" 
              echo -e "${cyan}CliFM $version$NC ($year), by L. M. Abramovich\n
${white}Genereal Usage: command [arguments]$NC 
ELN = element line number. Ex: in '23 - openbox', 23 is the ELN of openbox. 

${white}Commands$NC:
- ${yellow}h, help, ?${NC}: show this help.
- ${yellow}/${NC}*: This is the quick search function. Just type '/' followed by the string you are looking for, and CliFM will list all the matches in the current folder.
- ${yellow}bm, bookmarks${NC}: open the bookmarks menu. Here you can add, remove or edit your bookmarks to your liking, or simply cd into the desired bookmark by entering either its list number or its hotkey.  
- ${yellow}o, open$NC ELN (or path, or filename) [application name]: open either a folder (in which case you must specify either its list number or its path), or a file (in which case you must specify, again, either its list number or its name). By default, the 'open' function will open files with the default application associated to them. However, if you want to open a file with a different application, just add the application name as a second argument, e.g. 'open ELN (or file name) leafpad'. 
- ${yellow}cd$NC [path]: it works just as the built-in 'cd' command. 
- ${yellow}b, back${NC}: go back to the parent folder.
- ${yellow}pr, prop${NC} ELN: display the properties of the selected element.
- ${yellow}ren${NC} ELN new_name: rename an element.
- ${yellow}md, mkdir${NC} name ... n: create one or more new folders.
- ${yellow}t, touch${NC} name ... n: create one or more new files.
- ${yellow}ln, link${NC} [sel, ELN] [link_name]: create a simbolic link. The source element could be either a selected element, in which case you has to simply type 'sel' as first argument, or an element listed in the screen, in which case you simply has to specify its list number as first argument. The second argument is always a file name for the symlink.
- ${yellow}s, sel${NC} ELN ELN-ELN ... n: select one or multiple elements. Sel command accepts range of elements, say 1-6, just as '*' to select all the elements of the current folder. 
- ${yellow}sh, show, show sel${NC}: show currently selected elements.
- ${yellow}ds, desel${NC}: deselect currently selected elements.
- ${yellow}del${NC} [ELN ... n]: With no arguments, del command will delete those elements currently selected, if any. Otherwise, when one or more ELN's are passed to del, it will delete only those elements. 
- ${yellow}paste${NC}: copy selected elements into the current folder.
- ${yellow}move${NC}: move selected elements into the current folder.
- ${yellow}x, term${NC}: start a new terminal (xterm by default) in the current path and in a different window. 
- ${yellow}clear${NC}: clear the screen.
- ${yellow}v, ver, version${NC}: show CliFM version details.
- ${yellow}q, quit, exit${NC}: quit CliFM.\n"
              read -n1 -sp "Press any key to exit help... " key
              clear && cli && return;;
           #NOTE: Add: 'link' for symbolic links 
           bm|bookmarks) clear && bookmarks_manager && clear && cli && return;;
           b|back)
              #if it comes from the fast search function, don't cd .., for the fast search
              #function uses a different list of elements (the 'found' array). So, going back 
              #in this case would mean to show the original list of elements (dir_files) without
              #modifications.
              if [[ $found_mark == "found" ]]; then
                 #go back to the last recorded path. Last path is recorded by the 'open' function.
                 cd "$old_PWD" && clear && cli && return
              else
                 cd .. && old_PWD=$PWD && clear && cli && return
              fi;;
           o|open)
              if [[ -f ${elements[$i+1]} ]]; then
                 if ! [[ -z ${elements[$i+2]} ]]; then
                    ${elements[$i+2]} "${elements[$i+1]}"
                    clear && cli && return
                 else
                    xdg-open "${elements[$i+1]}"
                    clear && cli && return
                 fi
              fi
              if [[ -d ${elements[$i+1]} ]]; then
                 cd "${elements[$i+1]}"
                 clear && cli && return
              fi
              if ! [[ -z ${elements[$((i+1))]} ]] && ! [[ ${elements[$i+1]} -gt ${#dir_files[@]} ]]; then
              #${elements[$((i+1))]}, namely, the argument.
                 open_file="${dir_files[$((elements[$((i+1))]-1))]}"
                 if ! [[ -z ${elements[$((i+2))]} ]]; then
                    if [[ $(command -v ${elements[$i+2]}) ]]; then
                       open $open_file ${elements[$((i+2))]} && clear && cli && return
                    else
                       echo -e "'${elements[$i+2]}' doesn't exist."
                       prompt && return
                    fi
                 else
                    open $open_file && clear && cli && return 
                 fi
              else
                 echo "open: Invalid element."
                 prompt && return
              fi;;
              ##NOTE: thanks to both the 'back' option above and this one to open folders, cli
              #has become a basic files navigator!!!
           cd) 
              if ! [[ -z ${elements[$i+1]} ]]; then
                 if [[ -d ${elements[$i+1]} ]]; then
                    cd ${elements[$i+1]} 
                    clear && cli && return
                 else
                    echo "cd: '${elements[$i+1]}' is not a valid path."
                    prompt && return
                 fi
              else
                 cd && clear && cli && return
              fi;;
           /*) ####QUICK SEARCH function (or something like that). Great!!!
              target=${elements[$i]:1} #remove "/" from search string.
              #search for target in the listed elements array and save matches in a new array.
              for (( i=0;i<${#dir_files[@]};i++ )); do 
                 if [[ ${dir_files[$i]} == $target ]]; then
                     found[${#found[@]}]=${dir_files[$i]}
                  fi
              done
              found_mark="found"
              clear && cli $found_mark $target && return;;
           pr|prop) 
              if ! [[ -z ${elements[$((i+1))]} ]]; then
                 prop_file="${dir_files[$((elements[$((i+1))]-1))]}"
                 properties $prop_file && clear && cli && return
              else
                 echo "prop: You must provide a file number."
                 prompt && return
              fi;;
           del) 
#              elements[0]="del"
              [[ ${#elements[@]} -eq 1 ]] && delete && clear && cli && return
              for (( i=0;i<${#elements[@]};i++ )); do
                 if ! [[ ${elements[$i]} == "del" ]]; then
                    elem_no_del[${#elem_no_del[@]}]=${elements[$i]}
                 fi
              done
              if [[ ${elem_no_del[0]} == "*" ]]; then
                 del_element="all"
                 delete $del_element
              else
                 for (( i=0;i<${#elem_no_del[@]};i++ )); do
                    del_element="${dir_files[$((elem_no_del[$i]-1))]}"
                    delete $del_element
                 done
              fi
              unset elem_no_del && clear && cli && return;;
           ren) 
              if ! [[ -z ${elements[$((i+1))]} ]]; then
              ##VALIDATE firt element!
                 if ! [[ -z ${elements[$((i+2))]} ]]; then
                 ###VALIDATE second element!
                    ren_element="${dir_files[$((elements[$((i+1))]-1))]}"
                    mv "$ren_element" "${elements[$((i+2))]}" && clear && cli && return
                 else
                    echo "ren: You must provide a new name."
#                    read -s -n1 key  && clear && cli && return
                    prompt && return
                 fi
              else 
                 echo "ren: You must provide a file number."
                 prompt && return
              fi;;
           md|mkdir)
              #if the user accessed by "md", the condition below, since it searches for "mkdir",
              #will fail. So either accessing by "md" or "mkdir", make the first element of the
              #array to be "mkdir".            
              elements[0]="mkdir"
              for (( i=0;i<${#elements[@]};i++ )); do
                 if ! [[ ${elements[$i]} == "mkdir" ]]; then
                    elem_no_mkdir[${#elem_no_mkdir[@]}]=${elements[$i]}
                 fi
              done
              mkdir "${elem_no_mkdir[@]}"
              unset elem_no_mkdir && clear && cli && return;;
           t|touch) 
              elements[0]="touch" #see note to 'mkdir' function.
              for (( i=0;i<${#elements[@]};i++ )); do
                 if ! [[ ${elements[$i]} == "touch" ]]; then
                    elem_no_touch[${#elem_no_touch[@]}]=${elements[$i]}
                 fi
              done
              touch "${elem_no_touch[@]}"
              unset elem_no_touch && clear && cli && return;;
           ln|link) symlink;;
           s|sel)
              #assign all the elements of the "elements" array to another array but excluding 
              #the first value, namely, 'sel'.
              elements[0]="sel" #see note to 'mkdir' function.
              for (( i=0;i<${#elements[@]};i++ )); do
                  if ! [[ ${elements[$i]} == "sel" ]]; then
                    elem_no_sel[${#elem_no_sel[@]}]=${elements[$i]}
                 fi
              done
              #now go though the new array and save in sel_file array what is needed.
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
                1) echo -e "${cyan}1$NC element selected.";;
                *) echo -e "${cyan}${#sel_file[@]}$NC elements selected.";;
               esac 
#              read -p "Press any key to continue... " key
#              clear && cli && return;;
              #sel_file will keep all the selected elements until 'desel' command is executed.
               prompt && return;;
           ds|desel) deselect;; 
           sh|show|"show sel") 
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
                 done #| ccolumn
              else
                 echo "There are no selected elements."
              fi
              echo ""
              read -n1 -s -p "Press any key to continue... " key
              clear && cli && return;;
           #paste and move functions will paste and move, respectivelly, all the selected files 
           #into the actual folder
           paste) paste_files && clear && cli && return;;
           move) move_files && clear && cli && return;;
           #'term' will open a terminal in the current path in a different window.
           x|term) $default_terminal && clear && cli && return;;
           v|ver|version) 
              echo -e "\nCliFM $version ($year). By L. M. Abramovich\n"
              prompt && return;;
           q|quit|exit) exit 0;; #or 'exit 0' if running as an independent script
           "") echo "You pressed enter." && prompt && return;;
           clear) clear && cli && return;;
           *) echo -e "CliFM: '${elements[0]}' is not a valid command." && prompt && return;;
         esac
      fi
   done
}

function prompt ()
{
   user="$(whoami)"	
   if [[ $user == "root" ]]; then
      if [[ $PWD == $HOME ]]; then
         echo -ne "${d_red}[$user: ~] # $NC"
      else
         echo -ne "${d_red}[$user: $PWD] # $NC"
      fi
   else
      if [[ $PWD == $HOME ]]; then 
         echo -ne "${d_cyan}[$user: ~] $ $NC"
      else
         echo -ne "${d_cyan}[$user: $PWD] $ $NC"
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
   counter=0
   unset bookmarks #if I don't unset (clear) the array, it gets bigger and bigger with any new
   #execution of the script. This doesn't happen with mapfile.
   bookmarks_dir="$HOME/.config"
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
      read -p "No bookmarks. Do you want to edit the bookmarks file (y/n)? " answer
      case $answer in
        y) $default_editor "$bookmarks_dir/bookmarks.txt" && return;;
        n) return;;
        *) echo "Wrong answer." && prompt && return;;
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
      #if the path indicated in the bookmark doesn't exist, listed shadowed and delete
      #the content of this position of the array to prevent access to a non-existent 
      #folder
      if ! [[ -d $path ]]; then 
         echo -e " ${gray}$counter - ${gray}$hkey$bm$NC"
         bookmarks[$i]=""
      else
         echo -e " ${yellow}$counter$NC - ${white}$hkey${cyan} $bm$NC" #| grep --color "\[.*\]" 
      fi
   done
   echo -ne "\nChoose a bookmark ([e]dit, [q]uit): " 
   read sel_bm
   case $sel_bm in
      e|edit) $default_editor "$bookmarks_dir/bookmarks.txt" && return;;
      q|quit|exit) return;;
      #in case someone uses 'e','q','exit', or 'quit' as hotkey, this would produce an error
      #if not a number, or some char remains after deleteing all numbers...
      *) if [[ $(echo $sel_bm | sed 's/[0-9]//g') ]]; then 
            if [[ ${h_key[@]} == *"$sel_bm"* ]]; then #if input is contained in the hotkeys array
               for (( i=0;i<${#h_key[@]};i++ )); do #get the array index of the hotkey 
                  [[ $sel_bm == ${h_key[$i]} ]] && index=$i
               done
               #it was for this that the paralelism between bookmarks and hotkeys was to be conserved
               #leave only path, ommitting hotkey and bookmark, if any
               cd $(echo ${bookmarks[$index]} | cut -d"]" -f2 | cut -d":" -f2) && return
            fi
         fi
      ;;
   esac
   #At this point, we know the input to be a number. So, first validate it...
   ( [[ $sel_bm -eq 0 ]] || [[ $sel_bm -gt ${#bookmarks[@]} ]] ) && echo -e "${red}This bookmark doesn't exist!$NC" && return
   #if the line contains a bookmark or a hotkey, ommit them, leaving only the path
      cd $(echo ${bookmarks[$((sel_bm-1))]} | cut -d"]" -f2 | cut -d":" -f2)
}

function properties ()
{
prop_file=$1 
if [[ -h "$PWD/$prop_file" ]]; then #if symlink
   echo -e "\n$PWD/${cyan}$prop_file$NC"
elif [[ -d "$PWD/$prop_file" ]]; then
   echo -e "\n$PWD/${blue}$prop_file$NC"
elif [[ -x "$PWD/$prop_file" ]]; then
   echo -e "\n$PWD/${green}$prop_file$NC"
else
   echo -e "\n$PWD/${white}$prop_file$NC"
fi
ls -lh "$prop_file"
echo ""
prompt && return
}

function open ()
{
   open_file="$PWD/$1"
   if ! [[ -z $2 ]]; then
      app=$2 && $app "$open_file" &
   elif [[ -d $open_file ]]; then
      cd "$open_file"
      old_PWD=$PWD #save last path so that the 'back' is able to come back to it.
   else
      xdg-open "$open_file" &
   fi
}

function symlink ()
{ #rewrite in a simpler way.
if ! [[ -z ${elements[$i+1]} ]]; then
   if ! [[ $(echo ${elements[$i+1]} | grep [a-Z]) ]] && [[ ${elements[$i+1]} -le ${#dir_files[@]} ]]; then
      if ! [[ -z ${elements[$i+2]} ]]; then
         link_elem="$PWD/${dir_files[$((elements[$i+1]-1))]}"
         ln -s $link_elem ${elements[$i+2]}
         clear && cli && return
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
               clear && cli && return
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
   trap '' 1 2 3 20 #disable SIGHUP, SIGINT (Ctrl-c), SIGQUIT (Ctrl-4), and SIGSTP (Ctrl-z)
   for (( i=0;i<${#sel_file[@]};i++ )); do
      if [[ -d ${sel_file[$i]} ]]; then
         cp -r "${sel_file[$i]}" .
      else
         cp "${sel_file[$i]}" .
      fi
   done
   unset sel_file
   trap 1 2 3 20 #reenable SIGHUP, SIGINT (Ctrl-c), SIGQUIT (Ctrl-4), and SIGSTP (Ctrl-z)
}

function move_files ()
{
   trap '' 1 2 3 20
   for (( i=0;i<${#sel_file[@]};i++ )); do
      mv "${sel_file[$i]}" .
   done
   unset sel_file
   trap 1 2 3 20
}

function delete ()
{
   #just as the deselect function, 'delete' should allow the user to tell which of the selected 
   #elements he/she whises to delete.
   if [[ $# -eq 0 ]]; then #if no arguments were passed, it will delete selected elements
      [[ ${#sel_file[@]} -eq 0 ]] && echo "There are no selected files." && return 
      echo ""
      for (( i=0;i<${#sel_file[@]};i++ )); do
         echo " ${sel_file[$i]}"
      done
      echo -ne "\nThe above elements will be deleted. Do you wish to continue [y/n]? "
      read answer
      case $answer in
        n) return;;
        y)
        ###Should I TRAP signs? Yes.
           trap '' 1 2 3 20
           for (( i=0;i<${#sel_file[@]};i++ )); do
              if [[ -d ${sel_file[$i]} ]]; then
                 rm -r "${sel_file[$i]}" 
              else
                 rm "${sel_file[$i]}"
              fi
           done
           unset sel_file
           trap 1 2 3 20;;
        *) echo "Wrong answer." && prompt && return;;
      esac
   else
      del_element=$1
      if [[ $del_element == "all" ]]; then
         echo -ne "Are you sure you want to delete ${white}all$NC elements in this folder [y/n]? "
         read answer
         case $answer in
           y) 
#              trap '' 1 2 3 20
              rm -r * && return;; 
#              trap 1 2 3 20 && return;;
           n) return;;
           *) echo "Wrong answer." && prompt && return;;
         esac
      else      
         echo -ne "Are you sure you want to delete ${white}$PWD/$del_element$NC [y/n]? "   
#      fi
         read answer
         case $answer in
           y)
             trap '' 1 2 3 20
             if [[ -d $del_element ]]; then
                rm -r "$PWD/$del_element"
             else
                rm "$PWD/$del_element"
             fi
             trap 1 2 3 20
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
      done #| ccolumn
      echo -e "\nEnter 'q' to quit."
      echo -ne "Elements to be deselected (ex: 1 or *)? "
      read desel_element
      [[ $desel_element == "" ]] && clear && cli && return 
      [[ $desel_element == "q" ]] && clear && cli && return
      if [[ $desel_element == "*" ]] || [[ $desel_element == "all" ]]; then
         read -n1 -sp "All elements have been deselected. Press any key to continue... " key
         unset sel_file && clear && cli && return
      fi
      if [[ $(echo $desel_element | sed 's/[0-9]//g') ]] || [[ $desel_element -gt ${#sel_file[@]} ]]; then
         echo -e "Element '$desel_element' doesn't exist."
         prompt && return
      fi 
      echo -e "${white}${sel_file[$((desel_element-1))]}$NC has been deselected."
      #remove the element from the sel_file array. Quite confusing ahh!
      sel_file=(${sel_file[@]/${sel_file[$((desel_element-1))]}})
      read -n1 -sp "Press any key to continue... " key
      clear && cli && return 
   else
      echo -e "There are no selected elements.\n"
      read -n1 -sp "Press any key to continue... " key
      clear && cli && return
   fi
}

cli
