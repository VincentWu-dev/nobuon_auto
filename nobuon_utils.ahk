Nobuon_Utils_Enter(){
    global active_id
    
    ControlSend ,,{Enter Down},ahk_id %active_id%
    Sleep 200
    ControlSend ,,{Enter Up},ahk_id %active_id%
}

Nobuon_Utils_Up(){
    global active_id
    
    ControlSend ,,{i Down},ahk_id %active_id%
    Sleep 200
    ControlSend ,,{i Up},ahk_id %active_id%
}

Nobuon_Utils_Down(){
    global active_id
    
    ControlSend ,,{k Down},ahk_id %active_id%
    Sleep 200
    ControlSend ,,{k Up},ahk_id %active_id%
}

Nobuon_Utils_Left(){
    global active_id
    
    ControlSend ,,{j Down},ahk_id %active_id%
    Sleep 200
    ControlSend ,,{j Up},ahk_id %active_id%
}

Nobuon_Utils_Right(){
    global active_id
    
    ControlSend ,,{l Down},ahk_id %active_id%
    Sleep 200
    ControlSend ,,{l Up},ahk_id %active_id%
}

Nobuon_Utils_Esc(){
    global active_id
    
    ControlSend ,,{Esc Down},ahk_id %active_id%
    Sleep 200
    ControlSend ,,{Esc Up},ahk_id %active_id%
}

Nobuon_Utils_UpdateNBattle(){
    global NBattle
    
    GuiControl,,Combat, %NBattle%
}

