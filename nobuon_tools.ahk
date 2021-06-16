#include findpic.ahk
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
functionList := "稼業連點|轉圈掛機|原地掛機|賭場掛機|自動射箭"
IsStandByText:="|<>*80$14.xvkA1nB1sIzDTu5u3SlbalswSA7UfBmn0Ak3A9hYsQC78"
InCombatText:="|<>*111$23.zzzzU307060C0A0TzzzvzvzUzUDjzjzzzzw"
IsCombatEndText:="|<>*80$31.00000000003zzzz1DzzyEbzzrAG4A8W9+won4hW2NWKxDAl/Eka8zzzzw3zzzU0Tzz000000000004"


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

Gui Show, w386 h258, 信長online小工具

MyListBox:
{
    GuiControlGet, MyListBoxIndex
    active_id := winIDs[MyListBoxIndex]
    WinGetPos,  winX, winY, winWidth, winHeight, ahk_id %active_id%
    OutputDebug, Nobunaga window get. ID:  %active_id%.
    OutputDebug, Nobunaga window is %winWidth% wide`, %winHeight% tall`, and positioned at %winX%`,%winY%.

    MsgBox SelectItem: %active_id%
}
return

FuncListBox:
{
    GuiControlGet, FuncListBoxIndex
    funcSelect := FuncListBoxIndex
    MsgBox SelectItem: %FuncListBoxIndex%
}
return

MyGo:
{
    MsgBox MyGo pressed!. funcSelect: %funcSelect%
    bExit := false

    switch funcSelect
    {
        case 1:
            ;NoTurn_Combat_AFK()
            return
        case 2:
            Turn_Combat_AFK()
            return
        case 3:
            NoTurn_Combat_AFK()
            return
        case 4:
        case 5:
            Nobu_Auto_Arrow()
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
