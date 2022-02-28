#include findpic.ahk
#include nobuon_utils.ahk
#include nobuon_pictext.ahk

#SingleInstance force
; Run as admin
if not A_IsAdmin
{
    params := ""
    ShellExecute := A_IsUnicode ? "shell32\ShellExecute":"shell32\ShellExecuteA"

    if A_IsCompiled
       DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_ScriptFullPath, str, params , str, A_WorkingDir, int, 1)
    else
       DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """" . A_Space . params, str, A_WorkingDir, int, 1)
    ExitApp
}

;#IfWinActive ahk_class Nobunaga Online Game MainFrame

CoordMode, Pixel, Screen
SetWorkingDir %A_ScriptDir%
numMoveFB := 0
numMoveLR := 0
numLoop := 0
;bMoveFlag := 0
StartTime := A_TickCount
active_id := 0
active_id2 := 0
idlist := ""
winIDs := []
bExit := false
funcSelect := 0
Target_Array:={tx:0,ty:0,twidth:150,theight:70}
NBattle := 0

functionList := "稼業連點|轉圈掛機|原地掛機|賭場掛機|自動射箭|冥宮掛機|武士拉狗|自動跟隨戰鬥|原地確定戰鬥掛機"
;Get nobu window ID/position
;WinGet active_id, ID, ahk_class Nobunaga Online Game MainFrame

WinGet get_id, List, ahk_class Nobunaga Online Game MainFrame

;Get the other one inactive nobu on id
;Support only 2 windows
Loop %get_id%
{
    id := get_id%A_Index%
    winIDs[A_Index] := id
    WinGetTitle wTitle, ahk_id %id%
    if (A_Index = 1) 
        idlist .= wTitle "||"
    else 
        idlist .= wTitle "|"

}

SetBatchLines -1

Gui Font, s9, Segoe UI
Gui Add, ListBox, AltSubmit vMyListBoxIndex gMyListBox x23 y46 w182 h154, %idlist%
Gui Add, Text, x68 y21 w72 h23 +0x200, 信長視窗列表
Gui Add, Button, gMyGo x29 y220 w80 h23, 開始
Gui Add, ListBox, AltSubmit vFuncListBoxIndex gFuncListBox x232 y45 w120 h154, %functionList%
Gui Add, Text, x279 y18 w34 h23 +0x200, 功能
Gui Add, Button, gMyCancel x273 y219 w80 h23, 中止
Gui Add, Text, x128 y220 w57 h23 +0x200, 戰鬥場次:
Gui Add, Text, vCombat x189 y220 w41 h23 +0x200, %NBattle%


Gui Show, w386 h258, 信長online小工具

MyListBox:
{
    GuiControlGet, MyListBoxIndex
    active_id := winIDs[MyListBoxIndex]
    WinGetPos,  winX, winY, winWidth, winHeight, ahk_id %active_id%
    OutputDebug, Nobunaga window get. ID:  %active_id%.
    OutputDebug, Nobunaga window is %winWidth% wide`, %winHeight% tall`, and positioned at %winX%`,%winY%.
    Target_Array:={tx:0,ty:0,twidth:150,theight:70}:={tx:0,ty:0,twidth:150,theight:70}
    Target_Array.tx:=winX+winWidth-150
    Target_Array.ty:=WinY+60
    
    ;MsgBox SelectItem: %active_id%
}
return

FuncListBox:
{
    GuiControlGet, FuncListBoxIndex
    funcSelect := FuncListBoxIndex
    ;MsgBox SelectItem: %FuncListBoxIndex%
}
return

MyGo:
{
    MsgBox MyGo pressed!. funcSelect: %funcSelect%
    bExit := false
    NBattle := 0
    Nobuon_Utils_UpdateNBattle()

    switch funcSelect
    {
        case 1:
            Production_Enter_AFK()
            return
        case 2:
            Turn_Combat_AFK()
            return
        case 3:
            NoTurn_Combat_AFK()
            return
        case 4:
            Nobu_CasinoKarutaBet_AFK()
        case 5:
            Nobu_Auto_Arrow()
            return
        case 6:
            HellDoungeon_Combat_AFK()
            return
        case 7:
            FastSkill_AFK()
            return
        case 8:
            Nobu_FollowCombat_AFK()
            return
        case 9:
            NoTurn_Combat_Checkbox_AFK()
            return
            

        default:
            NoTurn_Combat_AFK()
            return
    }

}
return

MyCancel:
{
    bExit := true
    MsgBox MyCancel pressed!
}
return

;^Enter:: ; Ctrl+Enter

GoStraight(mTime, aid)
{	
	ControlSend ,,{w Down},ahk_id %aid%
    Sleep mTime
	ControlSend ,,{w Up},ahk_id %aid%
}

NoTurnClick(mTime, aid)
{	
	ControlSend ,,{Enter Down},ahk_id %aid%
    Sleep 200
	ControlSend ,,{Enter Up},ahk_id %aid%
}

TurnClick(mTime, aid)
{	
	ControlSend ,,{a Down},ahk_id %aid%
	
	Sleep mTime
	ControlSend ,,{a Up},ahk_id %aid%
	ControlSend ,,{Enter Down},ahk_id %aid%
	ControlSend ,,{Enter Up},ahk_id %aid%
	
}

MoveCircle(mTime, bReverse)
{
	if (bReverse) {
		Send {s Down}
		Send {e Down}
		Sleep mTime
		Send {s Up}
		Send {e Up}
	} else{
		Send {w Down}
		Send {q Down}
		Sleep mTime
		Send {w Up}
		Send {q Up}
	}
}


ReturnStandBy(aid)
{
	static bMoveFlag := false
	if (bMoveFlag) {
		ControlSend ,,{a Down},ahk_id %aid%
		Sleep 100
		ControlSend ,,{a Up},ahk_id %aid%
		bMoveFlag := false
	} else {
		ControlSend ,,{d Down},ahk_id %aid%
		Sleep 100
		ControlSend ,,{d Up},ahk_id %aid%
		bMoveFlag := true
	}
   	OutputDebug, Nobunaga: ReturnStandBy: id: %aid%. bMoveFlag: %bMoveFlag%
}

Production_Enter_AFK() {
    global active_id
    global NotEnoughPeriodText
    global winX,winY,winWidth,winHeight
    global bExit
    global NBattle
    
    while (!bExit){

        ;MsgBox, 4, ,Nobunaga window get. ID:  %active_id%
        ControlSend , ,{Enter Down}, ahk_id %active_id%  

        ;Send {Enter} 

        ;MsgBox, 4, ,Nobunaga test %dlg_period%
        ;Sleep 200

        ;MsgBox loop cnt: %loop_cnt%. %A_ScriptDir%\%dlg_period%
        Sleep 250
        ;ImageSearch, FoundX, FoundY, 0,0, A_ScreenWidth, A_ScreenHeight, *30 %A_ScriptDir%\%dlg_period%
                ;Sleep 500

        ;if ErrorLevel = 2
        ;    MsgBox Could not conduct the search.
        ;else if ErrorLevel = 1
        ;    MsgBox Icon could not be found on the screen.
        ;else
        ;    MsgBox The icon was found at %FoundX%x%FoundY%.
        ControlSend , ,{Enter Up},  ahk_id %active_id%
        if (ok:=FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, NotEnoughPeriodText)){
            break
        }

     }
     
}

Turn_Combat_AFK() {
    global active_id
    global InCombatText
    global IsCombatEndText
    global IsStandByText
    global winX,winY,winWidth,winHeight
    global bExit
    global winIDs

    ;check combat loop
    while (!bExit){
        TurnClick(50, active_id)

        Sleep 300

        ; isCombat
        if (ok:=FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, InCombatText)) {

            OutputDebug, Nobunaga: InCombat
            ;check combat end
            Loop{
                Sleep 5000
                if (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, IsCombatEndText)) {
                    OutputDebug, Nobunaga: CombatEND
                    ;MsgBox OutCombat

                    ;press enter to enter into standby
                    ;WinActivate, ahk_id %active_id%
                    while (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, IsStandByText)) {
                        OutputDebug, Nobunaga: standbyEnter
                        ;MsgBox standbyEnter, id: %active_id%
                        ;ControlSend , ,{Enter},ahk_id %active_id%
                        ControlSend ,,{Enter Down},ahk_id %active_id%
                        ;PostMessage, 0x100, 0x0d, 0x001F0001, , ahk_id %active_id%
                        Sleep 200
                        ;PostMessage, 0x101, 0x0d, 0xC01F0001, , ahk_id %active_id%
                        ControlSend ,,{Enter Up},ahk_id %active_id%
                    }
                    OutputDebug, Nobunaga: OutStandBy
                    ;tid := winIDs[2]
                    ;WinActivate, ahk_id %tid%
                    ;MsgBox OutStandBy

                    Sleep 2000
                    ;WinActivate, ahk_id %active_id%
                    ;ReturnStandBy(active_id)
                    ;WinActivate, ahk_id %tid%
                    break
                } ;if IsCombatEnd

            } ;IsCombatEnd Loop

        }else{ ;if IsCombat
            ElapsedTime := A_TickCount - StartTime
            if (ElapsedTime > 1*60*1000) {
                ;MsgBox, %ElapsedTime% ms have elapsed.
                bMoveFlag := !bMoveFlag
                StartTime := A_TickCount
            }
        }

    }

    return
}

NoTurn_Combat_AFK() {
    global active_id
    global InCombatText
    global IsCombatEndText
    global IsStandByText
    global winX,winY,winWidth,winHeight
    global bExit
    global winIDs

    ;check combat loop
    while (!bExit){
        NoTurnClick(50, active_id)

        Sleep 300

        ; isCombat
        if (ok:=FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, InCombatText)) {
            numMoveFB := 0
            numMoveLR := 0
            OutputDebug, Nobunaga: InCombat
            ;check combat end
            Loop{
                Sleep 5000
                if (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, IsCombatEndText)) {
                    OutputDebug, Nobunaga: CombatEND
                    ;MsgBox OutCombat

                    ;press enter to enter into standby
                    ;WinActivate, ahk_id %active_id%
                    while (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, IsStandByText)) {
                        OutputDebug, Nobunaga: standbyEnter
                        ;MsgBox standbyEnter, id: %active_id%
                        ;ControlSend , ,{Enter},ahk_id %active_id%
                        ControlSend ,,{Enter Down},ahk_id %active_id%
                        ;PostMessage, 0x100, 0x0d, 0x001F0001, , ahk_id %active_id%
                        Sleep 200
                        ;PostMessage, 0x101, 0x0d, 0xC01F0001, , ahk_id %active_id%
                        ControlSend ,,{Enter Up},ahk_id %active_id%
                    }
                    OutputDebug, Nobunaga: OutStandBy
                    ;tid := winIDs[2]
                    ;WinActivate, ahk_id %tid%
                    ;MsgBox OutStandBy

                    Sleep 2000
                    ;WinActivate, ahk_id %active_id%
                    ReturnStandBy(active_id)
                    ;WinActivate, ahk_id %tid%
                    break
                } ;if IsCombatEnd

            } ;IsCombatEnd Loop

        }else{ ;if IsCombat
            ElapsedTime := A_TickCount - StartTime
            if (ElapsedTime > 1*60*1000) {
                ;MsgBox, %ElapsedTime% ms have elapsed.
                bMoveFlag := !bMoveFlag
                StartTime := A_TickCount
            }
        }

    }

    return
}

NoTurn_Combat_Checkbox_AFK() {
    global active_id
    global InCombatText
    global IsCombatEndText
    global IsStandByText
    global winX,winY,winWidth,winHeight
    global bExit
    global winIDs
    global WinLoseText
    global NBattle

    ;check combat loop
    while (!bExit){
        NoTurnClick(50, active_id)

        Sleep 300
        
        ; Find 無法達成條件，是否挑戰
        if (ok:=FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, WinLoseText)) {
            Nobuon_Utils_Left()
        }

        ; isCombat
        if (ok:=FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, InCombatText)) {
            numMoveFB := 0
            numMoveLR := 0
            OutputDebug, Nobunaga: InCombat
            ;check combat end
            Loop{
                Sleep 5000
                if (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, IsCombatEndText)) {
                    OutputDebug, Nobunaga: CombatEND
                    ;MsgBox OutCombat

                    ;press enter to enter into standby
                    ;WinActivate, ahk_id %active_id%
                    while (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, IsStandByText)) {
                        OutputDebug, Nobunaga: standbyEnter
                        ;MsgBox standbyEnter, id: %active_id%
                        ;ControlSend , ,{Enter},ahk_id %active_id%
                        ControlSend ,,{Enter Down},ahk_id %active_id%
                        ;PostMessage, 0x100, 0x0d, 0x001F0001, , ahk_id %active_id%
                        Sleep 200
                        ;PostMessage, 0x101, 0x0d, 0xC01F0001, , ahk_id %active_id%
                        ControlSend ,,{Enter Up},ahk_id %active_id%
                    }
                    OutputDebug, Nobunaga: OutStandBy
                    ;tid := winIDs[2]
                    ;WinActivate, ahk_id %tid%
                    ;MsgBox OutStandBy

                    Sleep 2000
                    ;WinActivate, ahk_id %active_id%
                    ReturnStandBy(active_id)
                    NBattle++
                    Nobuon_Utils_UpdateNBattle()
                    ;WinActivate, ahk_id %tid%
                    break
                } ;if IsCombatEnd

            } ;IsCombatEnd Loop

        }else{ ;if IsCombat
            ElapsedTime := A_TickCount - StartTime
            if (ElapsedTime > 1*60*1000) {
                ;MsgBox, %ElapsedTime% ms have elapsed.
                bMoveFlag := !bMoveFlag
                StartTime := A_TickCount
            }
        }

    }

    return
}

Nobu_Auto_Arrow()
{
    global active_id
    global bExit
    
    while (!bExit){
        SetKeyDelay, 100
        ControlSend , ,{i down}{i up},  ahk_id %active_id%

        ControlSend , ,{F7 down}{F7 up},  ahk_id %active_id%

        SetKeyDelay, 350
        Loop 4{
            ControlSend , ,{Enter down}{Enter up},  ahk_id %active_id%
        }
        
        Sleep 350

        SetKeyDelay, 200
        ;input 99 to dialoge
        ControlSend , ,{j down}{j up},  ahk_id %active_id%
        ControlSend , ,{j down}{j up},  ahk_id %active_id%

        SetKeyDelay, 300
        ;Start to fire
        ControlSend , ,{Enter down}{Enter up},  ahk_id %active_id%

        Sleep 300

        ;move cursor and enter
        ControlSend , ,{j down}{j up},  ahk_id %active_id%
        Loop 8 {
            ControlSend , ,{Enter down}{Enter up},  ahk_id %active_id%
        }

        Loop 4 {
            ControlSend , ,{Esc down}{Esc up},  ahk_id %active_id%
        }
    
    }
    
}

SetMari_Skill() {
    global active_id
    global winX,winY,winWidth,winHeight
    global Hero_MariText

    SetKeyDelay, 300
    
    heroName_X:= winX+winWidth-150
    heroName_Y:= WinY+60
    
    ;MsgBox winX: %winX%, winY:%winY%
    
    ;MsgBox heroName_X: %heroName_X%, heroName_Y: %heroName_Y%
    
    
    while (!ok:=FindText(heroName_X, heroName_Y, heroName_X+150, heroName_Y+70, 0, 0, Hero_MariText)) {
        ControlSend , ,{l down}{l up},  ahk_id %active_id%
        Sleep 100
    }
    
    ;check again
    if (ok:=FindText(heroName_X, heroName_Y, heroName_X+150, heroName_Y+70, 0, 0, Hero_MariText)) {
        ControlSend , ,{enter down}{enter up},  ahk_id %active_id%
;        MsgBox Enter Press
        Sleep 1000
        ControlSend , ,{k down}{k up},  ahk_id %active_id%
        ControlSend , ,{enter down}{enter up},  ahk_id %active_id%
        Sleep 500
        Loop 2 {
            ControlSend , ,{k down}{k up},  ahk_id %active_id%
        }
        ControlSend , ,{Tab down}{Tab up},  ahk_id %active_id%
        Sleep 500
        ControlSend , ,{i down}{i up},  ahk_id %active_id%
        ControlSend , ,{enter down}{enter up},  ahk_id %active_id% 
        ControlSend , ,{esc down}{esc up},  ahk_id %active_id%
    }
}

HellDoungeon_Combat_AFK() {
    global active_id
    global InCombatText
    global IsCombatEndText
    global IsStandByText
    global winX,winY,winWidth,winHeight
    global bExit
    global winIDs
    global HellhoundText
    global Target_Array
    
    SetKeyDelay, 300
    WinActivate, ahk_id %active_id%
    Sleep 300
    ;heroName_X:= winX+winWidth-150
    ;heroName_Y:= WinY+60
    
    heroName_X:= Target_Array.tx
    heroName_Y:= Target_Array.ty
    
    MsgBox heroName_X: %heroName_X%, heroName_Y: %heroName_Y%
    
    
    GoStraight(1000, active_id)
    ControlSend , ,{i down}{i up},  ahk_id %active_id%
    while (!ok:=FindText(heroName_X, heroName_Y, heroName_X+150, heroName_Y+70, 0, 0, HellhoundText)) {
        ControlSend , ,{L down}{L up},  ahk_id %active_id%
        Sleep 100
    }
    
    if (ok:=FindText(heroName_X, heroName_Y, heroName_X+150, heroName_Y+70, 0, 0, HellhoundText)) {
        SetMari_Skill()
    }

    ;check combat loop
    ;while (!bExit){
        ;GoStraight(1200, active_id)
    

        Sleep 300
    ;}

    return
}

FastSkill_AFK() {
    global active_id
    global InCombatText
    global IsCombatEndText
    global IsStandByText
    global SkillReadyText
    global winX,winY,winWidth,winHeight
    global bExit
    global winIDs
    
    WinActivate, ahk_id %active_id%
    Sleep 100
    SetKeyDelay, 50
    
                 ;Sleep 50
           
    while (!bExit){
        ;check inCombat
        if (ok:=FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, InCombatText)) {
            
                ;MsgBox INCOMBAT!
            if (FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, SkillReadyText)){
                 ;MsgBox SkillReady!
                 ControlSend , ,{k down}{k up},  ahk_id %active_id%
                 ControlSend , ,{Enter down}{Enter up},  ahk_id %active_id%
                 ControlSend , ,{Enter down}{Enter up},  ahk_id %active_id%
                 ControlSend , ,{k down}{k up},  ahk_id %active_id%
                 ControlSend , ,{Enter down}{Enter up},  ahk_id %active_id%
                 ControlSend , ,{k down}{k up},  ahk_id %active_id%
                 ControlSend , ,{k down}{k up},  ahk_id %active_id%
                 ControlSend , ,{k down}{k up},  ahk_id %active_id%
                 ControlSend , ,{Enter down}{Enter up},  ahk_id %active_id%
                bExit := true
            }
         }
            
        ;}
    }
}

Nobu_FollowCombat_AFK() {
    global active_id
    global InCombatText
    global IsCombatEndText
    global IsStandByText
    global EndCombatItemSelectText
    global EndCombatItemConfirmText
    global EndCombatExpText
    global winX,winY,winWidth,winHeight
    global bExit
    global winIDs

    ;check combat loop
    while (!bExit){
        Sleep 100

        ; isCombat
        if (ok:=FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, InCombatText)) {
            numMoveFB := 0
            numMoveLR := 0
            OutputDebug, Nobunaga: InCombat
            ;check combat end
            while (!bExit){
                Sleep 5000
                if (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, IsCombatEndText)) {
                    OutputDebug, Nobunaga: CombatEND
                    ;MsgBox OutCombat
                    ;press one enter key
                    
                    Sleep 5000
                    while (FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, EndCombatExpText)) {
                        Nobuon_Utils_Enter()
                        Sleep 1500
                    }
                    ;MsgBox "after Exp"
                    
                    
                    ;Check do we have drop item selection
                    Loop 10{
                        OutputDebug, Nobunaga: item box finding
                        if (ok:=FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0,  EndCombatItemSelectText)) {
                            OutputDebug, Nobunaga: Found drop item box
;MsgBox "Found drop item box"
                            while (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0,  EndCombatItemConfirmText)) {
                                
                                ControlSend , ,{k down}{k up},  ahk_id %active_id%
                                Sleep 500                            
                            }
                            break                    
                        }
                        Sleep 1000
               
                    }
                    
                    
                    
                    ;press enter to enter into standby
                    while (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, IsStandByText)) {
                        OutputDebug, Nobunaga: standbyEnter
                       
                        Nobuon_Utils_Enter()
                    }
                    OutputDebug, Nobunaga: OutStandBy
                    break
                } ;if IsCombatEnd

            } ;IsCombatEnd Loop

        }else{ ;if IsCombat
            ElapsedTime := A_TickCount - StartTime
            if (ElapsedTime > 1*60*1000) {
                ;MsgBox, %ElapsedTime% ms have elapsed.
                StartTime := A_TickCount
            }
        }

    }
    ;Msgbox "<==Nobu_FollowCombat_AFK"

    return
    
}

Nobu_CasinoKarutaBet_AFK() {
    global active_id
    global CasinoBetSelectText ;"10張" 賭場哥留多 10張下注
    global CasinoBetInputText ;"最小" 賭場哥留多 下注數字輸入計算機
    global CasinoBetConfirm_DgText ;"張數 。" 賭場哥留多 確認下注張數對話框
    global CasinoResult_DgText ;"退還" 賭場哥留多 結果確認對話框
    global CasinoAgain_DgText  ;"次嗎?" 賭場哥留多 再玩一次嗎對話框
    global CasinoMoreCardText  ;"再抽一張" 賭場哥留多 再抽一張對話框
    global winX,winY,winWidth,winHeight
    global bExit
    global winIDs
    BetInputCnt := 0

    ;check combat loop
    while (!bExit){
        Sleep 200
        
        ;10張選擇
        while (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, CasinoBetSelectText)) {
            Nobuon_Utils_Enter()
            Sleep 300            
        }
        Loop 5 {
            if (FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, CasinoBetSelectText)) {
                Nobuon_Utils_Down()
                Sleep 200
                Nobuon_Utils_Enter()
                break
            }
        }
        
        ;找尋下注輸入框
        while (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, CasinoBetInputText)) {
            Nobuon_Utils_Enter()
            Sleep 200            
        }
        
        ;下注
        ;Msgbox "下注"
        
        Sleep 200
        
        Loop 4 {
            Nobuon_Utils_Down()
            Sleep 200
            Nobuon_Utils_Enter()
            Sleep 200
            Nobuon_Utils_Right()
            Sleep 200
            Nobuon_Utils_Enter()
            Sleep 200
        }
        
        ;確認下注張數
        while (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, CasinoBetConfirm_DgText)) {
            Nobuon_Utils_Enter()
            Sleep 200            
        }
        Loop 10 {
            if (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, CasinoBetConfirm_DgText)) {
                Nobuon_Utils_Enter()
                Sleep 200
            } else break
        }
        Sleep 500
        Loop 10 {
            if (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, CasinoBetConfirm_DgText)) {
                Nobuon_Utils_Enter()
                Sleep 200
            } else {
                Nobuon_Utils_Left()
                break
            }
        }

        Sleep 500
        Nobuon_Utils_Enter()
        Sleep 200
        
        ;再抽一張        
        while (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, CasinoResult_DgText)) {
            if (FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, CasinoMoreCardText)) {
                Nobuon_Utils_Left()  
            }
            Nobuon_Utils_Enter()
            Sleep 500            
        }
        
        Sleep 200
        
        while (!FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, CasinoAgain_DgText)) {
            Nobuon_Utils_Esc()
            Sleep 200            
        }
        
        Sleep 500
        Nobuon_Utils_Enter()       
        Sleep 500                
        ;Msgbox "確定賭注"
        
        
        ;break
        
            
    }
    ;Msgbox "<=Nobu_CasinoBet_AFK"

    return
    
}

Nobu_CasinoRouletteBet_AFK() {
    global active_id
    global CasinoBetStartText
    global winX,winY,winWidth,winHeight
    global bExit
    global winIDs

    ;check combat loop
    while (!bExit){
        Sleep 200

        ; isCombat
        if (ok:=FindText(winX-50, winY-50, winX+winWidth+50, winY+winHeight+50, 0, 0, CasinoBetStartText)) {
            Loop 15 {
                Nobuon_Utils_Enter()
            }
        }
            
    }
    ;Msgbox "<=Nobu_CasinoBet_AFK"

    return
    
}