HISTCONTROL=ignoreboth



# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/conda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
        . "/opt/conda/etc/profile.d/conda.sh"
    else
        export PATH="/opt/conda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


function _update_ps1() {
    PS1="$(/usr/local/bin/powerline-shell -git-mode simple -hostname-only-if-ssh -cwd-max-depth 5 -modules venv,cwd -error $? -jobs $(jobs -p | wc -l) -mode compatible -modules ssh,venv,cwd,git,root)"
}

if [ "$TERM" != "linux" ] && [ -f "/usr/local/bin/powerline-shell" ]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi

alias ..="cd .."
alias ll="ls -lh"
alias dlab='echo "                                                     
                                    ###              
                               *########             
                          +#############:            
                      ###################            
                 #########################           
            *#############################:          
       +###################################          
  =#########################################         
 ###########################################+        
 :###########################################        
  ############################################       
   ############################################      
    ###############==#==############==#########:     
    *##############  #  ############  ##########     
     ########:       #  ###        #        #####    
      ######  *###   #  #*  ####   #   ####  *###-   
      -####  :#####  #  #  *#####  #  ######  ####   
       ####+  #####  #  #   ####*  #  =####-  #####  
        ####=        #  ##:        #         ######* 
        :########################################### 
         *#######################################    
          ##################################=        
           ############################*             
           =######################*                  
            ##################                       
             ############:                           
             .######=                                
              #*                                     "'



# check whether the conda env default exists and activate it
conda activate default > /dev/null 2>&1
dlab
# go to the home directory if at the root
[ "$(pwd)" = "/" ] && cd ~