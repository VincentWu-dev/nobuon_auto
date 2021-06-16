;===== Copy The Following Functions To Your Own Code Just once =====


;--------------------------------
;  FindText - Capture screen image into text and then find it
;--------------------------------
;    returnArray := FindText(
;      X1 --> the search scope's upper left corner X coordinates
;    , Y1 --> the search scope's upper left corner Y coordinates
;    , X2 --> the search scope's lower right corner X coordinates
;    , Y2 --> the search scope's lower right corner Y coordinates
;    , err1 --> Fault tolerance percentage of text       (0.1=10%)
;    , err0 --> Fault tolerance percentage of background (0.1=10%)
;    , Text --> can be a lot of text parsed into images, separated by "|"
;    , ScreenShot --> if the value is 0, the last screenshot will be used
;    , FindAll --> if the value is 0, Just find one result and return
;    , JoinText --> if the value is 1, Join all Text for combination lookup
;    , offsetX --> Set the max text offset (X) for combination lookup
;    , offsetY --> Set the max text offset (Y) for combination lookup
;  )
;
;  The function returns a second-order array containing
;  all lookup results, Any result is an associative array
;  {1:X, 2:Y, 3:W, 4:H, x:X+W//2, y:Y+H//2, id:Comment}
;  if no image is found, the function returns 0.
;  All coordinates are relative to Screen, colors are in RGB format,
;  and combination lookup must use uniform color mode
;
;  If the return variable is set to "ok", ok.1 is the first result found.
;  Where ok.1.1 is the X coordinate of the upper left corner of the found image,
;  and ok.1.2 is the Y coordinate of the upper left corner of the found image,
;  ok.1.3 is the width of the found image, and ok.1.4 is the height of the found image,
;  ok.1.x <==> ok.1.1+ok.1.3//2 ( is the Center X coordinate of the found image ),
;  ok.1.y <==> ok.1.2+ok.1.4//2 ( is the Center Y coordinate of the found image ),
;  ok.1.id is the comment text, which is included in the <> of its parameter.
;  ok.1.x can also be written as ok[1].x, which supports variables. (eg: ok[A_Index].x)
;
;--------------------------------

FindText(args*)
{
  return FindText.FindText(args*)
}

Class FindText
{  ;// Class Begin

static bind:=[], bits:=[], Lib:=[]

__New()
{
  this.bind:=[], this.bits:=[], this.Lib:=[]
}

__Delete()
{
  if (this.bits.hBM)
    DllCall("DeleteObject", "Ptr",this.bits.hBM)
}

FindText( x1, y1, x2, y2, err1, err0, text, ScreenShot:=1
  , FindAll:=1, JoinText:=0, offsetX:=20, offsetY:=10 )
{
  local
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  x:=(x1<x2?x1:x2), y:=(y1<y2?y1:y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  this.xywh2xywh(x,y,w,h,x,y,w,h,zx,zy,zw,zh)
  if (w<1 or h<1)
  {
    SetBatchLines, %bch%
    return 0
  }
  bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy,zw,zh)
  sx:=x-zx, sy:=y-zy, sw:=w, sh:=h, arr:=[], info:=[]
  Loop, Parse, text, |
    if IsObject(j:=this.PicInfo(A_LoopField))
      info.Push(j)
  if (!(num:=info.MaxIndex()) or !bits.Scan0)
  {
    SetBatchLines, %bch%
    return 0
  }
  VarSetCapacity(input, num*7*4), k:=0
  For i,j in info
    k+=Round(j.2 * j.3)
  VarSetCapacity(s1, k*4), VarSetCapacity(s0, k*4)
  , VarSetCapacity(gs, (sw+2)*(sh+2))
  , VarSetCapacity(ss, sw*sh)
  , allpos_max:=(FindAll ? 10240 : 1)
  , VarSetCapacity(allpos, allpos_max*8)
  Loop, 2
  {
    if (err1=0 and err0=0) and (num>1 or A_Index>1)
      err1:=0.05, err0:=0.05
    if (JoinText)
    {
      j:=info[1], v:="", mode:=j.8
      , color:=j.9, n:=j.10, comment:="", k:=0
      For i,j in info
      {
        Loop, 7
          NumPut((A_Index=1 ? StrLen(v)
          : A_Index=6 and err1 and !j.12 ? Round(j.4*err1)
          : A_Index=7 and err0 and !j.12 ? Round(j.5*err0)
          : j[A_Index]), input, 4*(k++), "int")
        v.=j.1, comment.=j.11
      }
      ok:=this.PicFind( mode,color,n,offsetX,offsetY
      , bits,sx,sy,sw,sh,gs,ss,v,s1,s0
      , input,num*7,allpos,allpos_max )
      Loop, % ok
        pos:=NumGet(allpos, 8*(A_Index-1), "uint")
        , rx:=(pos&0xFFFF)+zx, ry:=(pos>>16)+zy
        , pos:=NumGet(allpos, 8*A_Index-4, "uint")
        , w:=pos&0xFFFF, h:=pos>>16
        , arr.Push( {1:rx, 2:ry, 3:w, 4:h
        , x:rx+w//2, y:ry+h//2, id:comment} )
    }
    else
    {
      For i,j in info
      {
        v:=j.1, w:=j.2, h:=j.3, mode:=j.8
        , color:=j.9, n:=j.10, comment:=j.11
        Loop, 7
          NumPut((A_Index=1 ? 0
          : A_Index=6 and err1 and !j.12 ? Round(j.4*err1)
          : A_Index=7 and err0 and !j.12 ? Round(j.5*err0)
          : j[A_Index]), input, 4*(A_Index-1), "int")
        ok:=this.PicFind( mode,color,n,offsetX,offsetY
        , bits,sx,sy,sw,sh,gs,ss,v,s1,s0
        , input,7,allpos,allpos_max )
        Loop, % ok
          pos:=NumGet(allpos, 8*(A_Index-1), "uint")
          , rx:=(pos&0xFFFF)+zx, ry:=(pos>>16)+zy
          , arr.Push( {1:rx, 2:ry, 3:w, 4:h
          , x:rx+w//2, y:ry+h//2, id:comment} )
        if (ok and !FindAll)
          Break
      }
    }
    if (err1=0 and err0=0 and num=1 and !arr.MaxIndex())
    {
      k:=0
      For i,j in info
        k+=(!j.12)
      if (k=0)
        Break
    }
    else Break
  }
  SetBatchLines, %bch%
  return arr.MaxIndex() ? arr:0
}

; Bind the window so that it can find images when obscured
; by other windows, it's equivalent to always being
; at the front desk. Unbind Window using FindText.BindWindow(0)

BindWindow(bind_id:=0, bind_mode:=0, get_id:=0, get_mode:=0)
{
  local
  bind:=this.bind
  if (get_id)
    return bind.id
  if (get_mode)
    return bind.mode
  if (bind_id)
  {
    bind.id:=bind_id, bind.mode:=bind_mode, bind.oldStyle:=0
    if (bind_mode & 1)
    {
      WinGet, oldStyle, ExStyle, ahk_id %bind_id%
      bind.oldStyle:=oldStyle
      WinSet, Transparent, 255, ahk_id %bind_id%
      Loop, 30
      {
        Sleep, 100
        WinGet, i, Transparent, ahk_id %bind_id%
      }
      Until (i=255)
    }
  }
  else
  {
    bind_id:=bind.id
    if (bind.mode & 1)
      WinSet, ExStyle, % bind.oldStyle, ahk_id %bind_id%
    bind.id:=0, bind.mode:=0, bind.oldStyle:=0
  }
}

xywh2xywh(x1,y1,w1,h1, ByRef x,ByRef y,ByRef w,ByRef h
  , ByRef zx:="", ByRef zy:="", ByRef zw:="", ByRef zh:="")
{
  local
  SysGet, zx, 76
  SysGet, zy, 77
  SysGet, zw, 78
  SysGet, zh, 79
  left:=x1, right:=x1+w1-1, up:=y1, down:=y1+h1-1
  , left:=(left<zx ? zx:left), right:=(right>zx+zw-1 ? zx+zw-1:right)
  , up:=(up<zy ? zy:up), down:=(down>zy+zh-1 ? zy+zh-1:down)
  , x:=left, y:=up, w:=right-left+1, h:=down-up+1
}

GetBitsFromScreen(x, y, w, h, ScreenShot:=1
  , ByRef zx:="", ByRef zy:="", ByRef zw:="", ByRef zh:="")
{
  local
  static Ptr:="Ptr"
  bits:=this.bits
  if (!ScreenShot)
  {
    zx:=bits.zx, zy:=bits.zy, zw:=bits.zw, zh:=bits.zh
    return bits
  }
  bch:=A_BatchLines, cri:=A_IsCritical
  Critical
  if (zw<1 or zh<1)
    this.xywh2xywh(x,y,w,h,x,y,w,h,zx,zy,zw,zh)
  bits.zx:=zx, bits.zy:=zy, bits.zw:=zw, bits.zh:=zh
  if (zw>bits.oldzw or zh>bits.oldzh or !bits.hBM)
  {
    if (bits.hBM)
      DllCall("DeleteObject", Ptr,bits.hBM)
    VarSetCapacity(bi, 40, 0), NumPut(40, bi, 0, "int")
    NumPut(zw, bi, 4, "int"), NumPut(-zh, bi, 8, "int")
    NumPut(1, bi, 12, "short"), NumPut(bpp:=32, bi, 14, "short")
    bits.hBM:=DllCall("CreateDIBSection", Ptr,0, Ptr,&bi
      , "int",0, "Ptr*",ppvBits:=0, Ptr,0, "int",0, Ptr)
    bits.Scan0:=(!bits.hBM ? 0:ppvBits)
    bits.Stride:=((zw*bpp+31)//32)*4
    bits.oldzw:=zw, bits.oldzh:=zh
  }
  if (bits.hBM) and !(w<1 or h<1)
  {
    win:=DllCall("GetDesktopWindow", Ptr)
    hDC:=DllCall("GetWindowDC", Ptr,win, Ptr)
    mDC:=DllCall("CreateCompatibleDC", Ptr,hDC, Ptr)
    oBM:=DllCall("SelectObject", Ptr,mDC, Ptr,bits.hBM, Ptr)
    DllCall("BitBlt",Ptr,mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
      , Ptr,hDC, "int",x, "int",y, "uint",0x00CC0020|0x40000000)
    DllCall("ReleaseDC", Ptr,win, Ptr,hDC)
    if (id:=this.BindWindow(0,0,1))
      WinGet, id, ID, ahk_id %id%
    if (id)
    {
      WinGetPos, wx, wy, ww, wh, ahk_id %id%
      left:=x, right:=x+w-1, up:=y, down:=y+h-1
      , left:=(left<wx ? wx:left), right:=(right>wx+ww-1 ? wx+ww-1:right)
      , up:=(up<wy ? wy:up), down:=(down>wy+wh-1 ? wy+wh-1:down)
      , x:=left, y:=up, w:=right-left+1, h:=down-up+1
    }
    if (id) and !(w<1 or h<1)
    {
      if (mode:=this.BindWindow(0,0,0,1))<2
      {
        hDC2:=DllCall("GetDCEx", Ptr,id, Ptr,0, "int",3, Ptr)
        DllCall("BitBlt",Ptr,mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
        , Ptr,hDC2, "int",x-wx, "int",y-wy, "uint",0x00CC0020|0x40000000)
        DllCall("ReleaseDC", Ptr,id, Ptr,hDC2)
      }
      else
      {
        VarSetCapacity(bi, 40, 0), NumPut(40, bi, 0, "int")
        NumPut(ww, bi, 4, "int"), NumPut(-wh, bi, 8, "int")
        NumPut(1, bi, 12, "short"), NumPut(32, bi, 14, "short")
        hBM2:=DllCall("CreateDIBSection", Ptr,0, Ptr,&bi
        , "int",0, "Ptr*",0, Ptr,0, "int",0, Ptr)
        mDC2:=DllCall("CreateCompatibleDC", Ptr,0, Ptr)
        oBM2:=DllCall("SelectObject", Ptr,mDC2, Ptr,hBM2, Ptr)
        DllCall("PrintWindow", Ptr,id, Ptr,mDC2, "uint",(mode>3)*3)
        DllCall("BitBlt",Ptr,mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
        , Ptr,mDC2, "int",x-wx, "int",y-wy, "uint",0x00CC0020|0x40000000)
        DllCall("SelectObject", Ptr,mDC2, Ptr,oBM2)
        DllCall("DeleteDC", Ptr,mDC2)
        DllCall("DeleteObject", Ptr,hBM2)
      }
    }
    DllCall("SelectObject", Ptr,mDC, Ptr,oBM)
    DllCall("DeleteDC", Ptr,mDC)
  }
  Critical, %cri%
  SetBatchLines, %bch%
  return bits
}

PicInfo(text)
{
  local
  static info:=[]
  If !InStr(text,"$")
    return
  if (info[text])
    return info[text]
  v:=text, comment:="", e1:=e0:=0, set_e1_e0:=0
  ; You Can Add Comment Text within The <>
  if RegExMatch(v,"<([^>]*)>",r)
    v:=StrReplace(v,r), comment:=Trim(r1)
  ; You can Add two fault-tolerant in the [], separated by commas
  if RegExMatch(v,"\[([^\]]*)]",r)
  {
    v:=StrReplace(v,r)
    r:=StrSplit(r1, ",")
    e1:=r.1, e0:=r.2, set_e1_e0:=1
  }
  r:=StrSplit(v,"$")
  color:=r.1, v:=r.2
  r:=StrSplit(v,".")
  w1:=r.1, v:=this.base64tobit(r.2), h1:=StrLen(v)//w1
  if (w1<1 or h1<1 or StrLen(v)!=w1*h1)
    return
  mode:=InStr(color,"-") ? 4 : InStr(color,"#") ? 3
    : InStr(color,"**") ? 2 : InStr(color,"*") ? 1 : 0
  if (mode=4)
  {
    color:=StrReplace(color,"0x")
    r:=StrSplit(color,"-")
    color:="0x" r.1, n:="0x" r.2
  }
  else
  {
    color:=RegExReplace(color,"[*#]")
    r:=StrSplit(color,"@")
    color:=r.1, n:=Round(r.2,2)+(!r.2)
    , n:=Floor(9*255*255*(1-n)*(1-n))
  }
  StrReplace(v,"1","",len1), len0:=StrLen(v)-len1
  , e1:=Round(len1*e1), e0:=Round(len0*e0)
  return info[text]:=[v,w1,h1,len1,len0,e1,e0
    , mode,color,n,comment,set_e1_e0]
}

PicFind(mode, color, n, offsetX, offsetY, bits, sx, sy, sw, sh
  , ByRef gs, ByRef ss, ByRef text, ByRef s1, ByRef s0
  , ByRef input, num, ByRef allpos, allpos_max)
{
  local
  static MyFunc:=""
  if (!MyFunc)
  {
    x32:=""
    . "5557565381EC940000008B8424F0000000C7442420000000008B400489442448"
    . "8B8424F00000008B40088944244C8B8424F00000008B400C89C78B8424F00000"
    . "008B401089C68B8424F00000008B401489C38944242C8B8424F00000008B4018"
    . "89C18944243031C039DF0F4EF839CE0F4FC6897C242439C7894424180F4DC789"
    . "4424288B8424F400000085C00F8E200100008B4424208BBC24F00000008B3C87"
    . "897C24108BBC24F00000008B7C8704897C24148BBC24F00000008B44870885C0"
    . "8944241C0F8ED20000008B6C2410C744240C00000000C744240800000000C744"
    . "240400000000892C248DB426000000008B5C24148B7424088B4C24108B54240C"
    . "89DF89F029F101F78BB424E400000001CE85DB7E5E8B0C2489EB893C2489D7EB"
    . "198BAC24EC00000083C70483C00189548D0083C101390424742C83BC24A80000"
    . "000389FA0F45D0803C063175D48BAC24E800000083C70483C00189549D0083C3"
    . "0139042475D48B7424140174241089DD890C2483442404018BB424D40000008B"
    . "442404017424088B8C24C0000000014C240C3944241C0F8554FFFFFF83442420"
    . "078B442420398424F40000000F8FE0FEFFFF83BC24A8000000030F841F070000"
    . "8B8424C00000008BB424CC0000000FAF8424D00000008B9C24A80000008D3CB5"
    . "00000000897C242001F88BBC24C00000008944241C8B8424D4000000F7D885DB"
    . "8D04878944240C0F84CD02000083BC24A8000000010F84390B000083BC24A800"
    . "0000020F84DD0800008B8424AC0000008B9C24B00000000FB6B424AC0000000F"
    . "B6BC24B0000000C744242000000000C744243400000000C1E8100FB6DF0FB6D0"
    . "8B8424AC00000089D50FB6CC8B8424B0000000C1E8100FB6C029C501D0890424"
    . "8D0419896C243C89CD8B8C24D8000000894424088D043E29DD896C240489F589"
    . "4424148B8424D400000029FD896C2410C1E00285C9894424380F8EBB0000008B"
    . "4C241C8B6C243C8B9424D400000085D20F8E8A0000008B8424BC0000008B5424"
    . "34039424E000000001C8034C243889CF894C241C03BC24BC000000EB368D7600"
    . "391C247C3D394C24047F37394C24087C3189F30FB6F3397424100F9EC3397424"
    . "140F9DC183C00483C20121D9884AFF39C7741E0FB658020FB648010FB63039DD"
    . "7EBE31C983C00483C201884AFF39C775E28BBC24D4000000017C24348B4C241C"
    . "8344242001034C240C8B442420398424D80000000F854DFFFFFF8B8424D40000"
    . "002B4424488944241C8B8424D80000002B44244C8944247C0F887A0A00008B44"
    . "244C8BBC24E8000000C744240C00000000C744245400000000C7442438000000"
    . "00C1E0100B442448898424880000008B4424248D3C8789C589BC24900000008B"
    . "7C24288B44241C85C00F88BC0000008B442454038424D0000000C70424000000"
    . "00C1E010898424840000008B8424CC000000894424088D76008DBC2700000000"
    . "8B04240344240C85FF89C2894424200F8E940100008B7424308B5C242C31C003"
    . "9424E000000089742404EB2F8D742600394424187E1A8BB424EC0000008B0C86"
    . "01D18039007409836C2404017827669083C00139C70F844E01000039C57ED18B"
    . "B424E80000008B0C8601D180390075C083EB0179BB8304240183442408018B04"
    . "243944241C0F8D75FFFFFF83442454018B9C24D40000008B442454015C240C39"
    . "44247C0F8D1AFFFFFF8B44243881C4940000005B5E5F5DC258008B8424AC0000"
    . "008B8C24D80000000FB6AC24AC000000C744240800000000C744241000000000"
    . "C1E8100FB6C08904248B8424AC0000000FB6C4894424048B8424D4000000C1E0"
    . "0285C9894424208B44241C0F8E49FEFFFF8B9424D400000085D27E6E8B9C24BC"
    . "0000008B7424108BBC24BC00000003B424E000000001C3034424208944241401"
    . "C70FB643020FB64B012B04242B4C24040FB6130FAFC00FAFC929EA8D04400FAF"
    . "D28D04888D0450398424B00000000F930683C30483C60139DF75C68BBC24D400"
    . "0000017C24108B44241483442408010344240C8B7C240839BC24D80000000F85"
    . "6DFFFFFFE9B1FDFFFF83BC24F4000000070F8EFF0100008B4424548B74244CC7"
    . "44246407000000896C246C897C247001C68944246089442410897424688BB424"
    . "F00000008B042483C6208974245C8B74244889442434897424588B7C245C8B74"
    . "2458017424348B9424B40000008B4424348B378B4F108B6F0C89F3897424588B"
    . "77088B7F14894C244039CEB900000000897C24440F4EF139FDBF000000000F4E"
    . "EF01C289C78B8424D400000029D839C20F4EC289C38944247489F839D80F8F46"
    . "0100008B542410BF000000008B5C245C89E989D02B8424B80000000F48C739EE"
    . "0F4DCE89C7039424B8000000894C24048984248C0000008B8C24D80000008B43"
    . "0429C18984248000000039CA89C88B4C24040F4EC2894424508B8424D4000000"
    . "0FAFC78BBC24E8000000894424788B43FC89442410C1E00201C7038424EC0000"
    . "00894424148B442434034424788944243C8B84248C0000003944245089442410"
    . "0F8C9000000085C90F8E1B0100008B4424448B54243C897C2404039424E00000"
    . "00894424288B4424408944242431C0EB2A39C57E1B8B7C24148B1C8701D3803B"
    . "00740D836C242801782A8DB60000000083C00139C10F84CE00000039C67ED28B"
    . "7C240489D3031C87803B0075C4836C24240179BD83442410018B9424D4000000"
    . "8B4424100154243C394424508B7C24040F8D70FFFFFF83442434018B4424343B"
    . "4424740F8E3CFFFFFF8B6C246C8B7C2470E9BFFCFFFF8B4424080B8424840000"
    . "008B9C24F80000008B7424388904F389D88B9C2488000000895CF00483442438"
    . "018B442438398424FC0000000F8EB7FCFFFF85ED0F8E7BFCFFFF8B5C24208BB4"
    . "24E00000008B8424E80000008D0C1E8B9C24900000008B1083C00401CA39D8C6"
    . "020075F2E94CFCFFFF8B4424608B7424108B7C246839F00F4FC6894424608B84"
    . "248000000001F039C70F4DC783442464078344245C1C894424688B4424643984"
    . "24F40000000F8F8FFDFFFF8B7424608B8424D00000008B8C24F80000008B5C24"
    . "388B6C246C8B7C247001F0C1E0100B4424088904D98B4C246829F18BB424F800"
    . "000089C8C1E01089C28B442458034424342B042409D08944DE04E91DFFFFFF8B"
    . "7424488B8424AC00000031D2F7F60FAF8424C00000008D04908944241C8B8424"
    . "D4000000038424CC00000029F0894424208B8424D0000000038424D80000002B"
    . "44244C398424D00000008944243C0F8FE40400008B44244C8BBC24CC0000008B"
    . "B424BC000000C744243800000000C1E0100B442448894424448B8424C0000000"
    . "0FAF8424D00000008D04B80344241C894424348B442420398424CC0000000F8F"
    . "240100008B8424D0000000C1E010894424408B442434894424148B8424CC0000"
    . "00894424088B4424140FB67C060289C52B6C241C893C240FB67C0601897C2404"
    . "0FB63C068B44242885C00F8E010100008B442430894424108B44242C8944240C"
    . "31C0EB59394424187E468B9C24EC0000008B0C8301E90FB6540E020FB65C0E01"
    . "2B14242B5C24040FB60C0E0FAFD20FAFDB29F98D14520FAFC98D149A8D144A39"
    . "9424B00000007208836C24100178619083C001394424280F8494000000394424"
    . "247EA18B9C24E80000008B0C8301E90FB6540E020FB65C0E012B14242B5C2404"
    . "0FB60C0E0FAFD20FAFDB29F98D14520FAFC98D149A8D144A3B9424B00000000F"
    . "865FFFFFFF836C240C010F8954FFFFFF834424080183442414048B4424083944"
    . "24200F8DFDFEFFFF838424D0000000018BBC24C00000008B44243C017C24343B"
    . "8424D00000000F8DA7FEFFFFE9F8F9FFFF8B4424400B4424088B7C24388B9C24"
    . "F80000008904FB89D88B5C2444895CF80483C7013BBC24FC000000897C24387C"
    . "8FE9C3F9FFFF8B8424D4000000038424CC0000008BB424D0000000894424048B"
    . "8424D00000008D7EFF038424D800000039F80F8C070100008BB424CC00000083"
    . "C001C744240C00000000894424108B8424A80000002B8424CC00000083EE0189"
    . "7424148BB424C000000089C30FAFF7897424088B74240401F38D6E01895C2434"
    . "8B442414394424040F8C990000008B4C240C2B8C24CC00000089FB8BB424DC00"
    . "00008B542408C1EB1F03542420891C24039424BC00000001CEEB4C398424C400"
    . "00007E4C803C2400754639BC24C80000007E3D0FB65AFE0FB64AFD83C2046BC9"
    . "4B6BDB2601CB895C241C0FB65AF889D9C1E10429D9034C241CC1F907884C0601"
    . "83C00139E8741889C1C1E91F84C974ABC64406010083C00183C20439E875E88B"
    . "7424340174240C83C7018BB424C000000001742408397C24100F8541FFFFFF8B"
    . "8424D40000008BB424D800000083C00285F6894424080F8E1EF7FFFF8B442408"
    . "038424DC000000C744240401000000C744240C000000008904248B8424D80000"
    . "0083C001894424108B8424D400000083C004894424148B9C24D400000085DB0F"
    . "8E900000008B04248B5C240C8B742414039C24E000000089C12B8C24D4000000"
    . "89C201C60FB642010FB62ABF01000000038424AC00000039E87C390FB66A0239"
    . "E87C310FB669FF39E87C290FB66EFF39E87C210FB669FE39E87C190FB62939E8"
    . "7C120FB66EFE39E87C0A0FB63E39F80F9CC089C789F883C20183C3018843FF83"
    . "C60183C101390C24759A8BBC24D4000000017C240C83442404018B7424088B44"
    . "2404013424394424100F8547FFFFFFE926F6FFFF8B8424AC0000008BAC24D800"
    . "0000C7042400000000C74424040000000083C001C1E00789C78B8424D4000000"
    . "C1E00285ED894424080F8EEBF5FFFF8B44241C89FD8BBC24D400000085FF7E5F"
    . "8B8C24BC0000008B5C2404039C24E000000001C10344240889442410038424BC"
    . "00000089C70FB651020FB641010FB6316BC04B6BD22601C289F0C1E00429F001"
    . "D039C50F970383C10483C30139F975D58BBC24D4000000017C24048B44241083"
    . "0424010344240C8B342439B424D80000007582E962F5FFFFC744243800000000"
    . "E9A4F6FFFF9090909090909090909090"
    x64:=""
    . "4157415641554154555756534881ECB8000000488B8424900100004C8BBC2480"
    . "01000089542430448944241044898C24180100004C8BAC24880100008B4004C7"
    . "4424080000000089442434488B8424900100008B400889442438488B84249001"
    . "00008B400C89C7488B8424900100008B401089C6488B8424900100008B401489"
    . "C389442420488B8424900100008B401889C28944242431C039DF0F4EF839D60F"
    . "4FC6897C245C39C78944241C0F4DC789442458488B8424900100004889442428"
    . "8B84249801000085C00F8ECC000000488B4424288B38448B70048B4008897C24"
    . "1885C08904240F8E930000008B7424184531E431FF31ED4189F1660F1F440000"
    . "4585F67E634863542418418D1C3E89F848039424780100004589E0EB1E0F1F00"
    . "83C0014D63D94183C0044183C1014883C20139D84789549D00742883F9034589"
    . "C2440F45D0803A3175D683C0014C63DE4183C00483C6014883C20139D8478914"
    . "9F75D8440174241883C50103BC24580100004403A42430010000392C24758183"
    . "4424080748834424281C8B442408398424980100000F8F34FFFFFF83F9030F84"
    . "2F0700008B8424300100008BBC24480100000FAF8424500100008BB424300100"
    . "008D3CB88B842458010000F7D885C98D0486894424180F840C01000083F9010F"
    . "84C20B000083F9020F843E0900008B742430C7042400000000C7442408000000"
    . "0089F0440FB6F6C1E8104589F40FB6D84889F08B7424100FB6D44189DB89F048"
    . "89F1440FB6C6C1E8100FB6CD89D60FB6C029CE8D2C0A4129C301C38B8C246001"
    . "00008B8424580100004529C44501C6C1E00285C9894424100F8E670100004C89"
    . "BC2480010000448BBC24580100004585FF0F8EF2040000488B8C242801000048"
    . "63C74C6354240831D24C03942470010000488D440102EB3A0F1F840000000000"
    . "4439CB7C3F39CE7F3B39CD7C374539C4410F9EC14539C60F9DC14421C941880C"
    . "124883C2014883C0044139D70F8E8E040000440FB6080FB648FF440FB640FE45"
    . "39CB7EBC31C9EBD58B5C243031ED4531E44889D84189DB0FB6DB0FB6F48B8424"
    . "5801000041C1EB10450FB6DB448D3485000000008B84246001000085C00F8EA2"
    . "0000004C89BC24800100004C89AC2488010000448B7C2410448BAC2458010000"
    . "4585ED7E60488B8C24280100004D63D44C039424700100004863C74531C94C8D"
    . "440102410FB600410FB648FF410FB650FE4429D829F10FAFC029DA0FAFC98D04"
    . "400FAFD28D04888D04504139C7430F93040A4983C1014983C0044539CD7FC444"
    . "01F74501EC83C501037C241839AC2460010000758B4C8BBC24800100004C8BAC"
    . "24880100008B8424580100002B442434894424108B8424600100002B44243889"
    . "8424840000000F88640A00008B4424384C89EE448B74241C4D89FD4531E448C7"
    . "44244000000000C7442428000000004489642408C1E0100B4424348984249400"
    . "00008B44245C83E801498D448704448B7C245848898424A00000008B54241048"
    . "8B44244085D28984249C0000000F88B2000000898424A8000000038424500100"
    . "004C89EB4889F5448B6C245C488BB4247001000031FF4989FCC1E01089842490"
    . "0000008B4424084585FF448924244489642418428D3C200F8EA3000000448B4C"
    . "2424448B44242031C0EB2E0F1F4400004139CE7E1B8B54850001FA4863D2803C"
    . "1600740C4183E901782A660F1F4400004883C0014139C77E674139C589C17ED0"
    . "8B148301FA4863D2803C160075C24183E80179BC4983C40144396424107D8449"
    . "89DD4889EE4883442440018B9C2458010000488B442440015C24083984248400"
    . "00000F8D13FFFFFF8B4424284881C4B80000005B5E5F5D415C415D415E415FC3"
    . "83BC2498010000070F8E400200008B442438038424A80000008B542434448974"
    . "247044897C247448896C2450C74424640700000044896C246C89442468488B84"
    . "2490010000895424588B14244C8964247889BC24AC0000004883C02048895C24"
    . "484889C18B84249C0000004189D74989CE8944246089C5418B0644037C245845"
    . "8B4608458B4E0C418B5E148B94241801000089C789442458418B4610895C2430"
    . "4139C08944241CB800000000440F4EC04139D9440F4EC88B8424580100004401"
    . "FA29F839C20F4EC24139C7898424800000000F8F1501000089E82B8424200100"
    . "00BF000000004589CB8B9C24600100004D6366FC0F48C74539C8450F4DD889C7"
    . "03AC242001000089842498000000418B460429C38984248800000039DD89D80F"
    . "4EC549C1E4028944243C8B8424580100000FAFC78984248C000000488B442448"
    . "4E8D2C204C036424508B84248C000000458D14078B8424980000003944243C89"
    . "C57C784585DB0F8E640100008B7C24308B5C241C31C0EB350F1F840000000000"
    . "4139C97E1B418B14844401D24863D2803C1600740B83EF017830660F1F440000"
    . "4883C0014139C30F8E230100004139C089C17ECC418B5485004401D24863D280"
    . "3C160075BB83EB0179B683C5014403942458010000396C243C7D884183C70144"
    . "3BBC24800000000F8E5CFFFFFF4C8B642478448B6C246C448B742470448B7C24"
    . "74488B5C2448488B6C24504983C40144396424100F8D29FDFFFFE9A0FDFFFF90"
    . "037C241044017C240883042401037C24188B0424398424600100000F85EDFAFF"
    . "FF4C8BBC2480010000E937FCFFFF8B4424288B54241803942448010000488B8C"
    . "24A00100000B94249000000001C048988914818B942494000000895481048344"
    . "2428018B442428398424A80100000F8E54FDFFFF4585ED0F8E17FDFFFF488B8C"
    . "24A00000004889D88B104883C00401FA4839C84863D2C604160075EC4983C401"
    . "44396424100F8D78FCFFFFE9EFFCFFFF8B4424608B7C246839E80F4FC5894424"
    . "608B84248800000001E839C70F4DC783442464074983C61C894424688B442464"
    . "398424980100000F8F6AFDFFFF8B442428448B5C24604589F98B542418039424"
    . "48010000448B6C246C448B74247001C04C8B6424788BBC24AC0000004863C88B"
    . "842450010000448B7C2474488B5C2448488B6C24504401D8C1E01009D0488B94"
    . "24A001000089048A8B5424684429DA89D0C1E01089C28B4424584401C82B0424"
    . "09D0488B9424A001000089448A04E9EBFEFFFF8B4424308B7C243431D2F7F70F"
    . "AF8424300100008D0490894424308B8424580100000384244801000029F88944"
    . "243C8B842450010000038424600100002B44243839842450010000894424400F"
    . "8F2B0500008B4424388BBC2448010000448B64245C448B7424584C8B8C242801"
    . "0000C744242800000000C1E0100B442434894424488B8424300100000FAF8424"
    . "500100008D04B803442430894424348B44243C398424480100000F8F40010000"
    . "8B8424500100008B6C2434C1E010894424388B842448010000894424188D4502"
    . "89EF2B7C24304585F64898450FB61C018D45014898410FB61C014863C5410FB6"
    . "34010F8E280100008B442424894424088B44242089042431C0EB720F1F440000"
    . "443954241C7E59418B4C850001F98D5102448D41014863C9410FB60C094863D2"
    . "4D63C0410FB61411470FB6040129F10FAFC94429DA4129D80FAFD2450FAFC08D"
    . "1452428D14828D144A395424107211836C2408017874662E0F1F840000000000"
    . "4883C0014139C60F8EA30000004139C44189C27E8B418B0C8701F98D5102448D"
    . "41014863C9410FB60C094863D24D63C0410FB61411470FB6040129F10FAFC944"
    . "29DA4129D80FAFD2450FAFC08D1452428D14828D144A3B5424100F8640FFFFFF"
    . "832C24010F8936FFFFFF834424180183C5048B4424183944243C0F8DDDFEFFFF"
    . "83842450010000018BBC24300100008B442440017C24343B8424500100000F8D"
    . "8BFEFFFFE93FFAFFFF0F1F80000000008B7C24288B5424380B542418488BB424"
    . "A00100008B5C244889F801C04898891486895C860489F883C0013B8424A80100"
    . "00894424287C83E9FCF9FFFF8B8424500100008BBC2450010000038424600100"
    . "00448BB424580100004403B4244801000083EF0139F80F8C1F0100008BB42448"
    . "0100002B8C244801000083C001448BA4243001000089442418418D6E01448D5E"
    . "FF31F6440FAFE7428D1C9D000000004863C348890424428D04318944243C4539"
    . "DE0F8CBF000000418D0C1C4C8B04244189FA4863D64489D84803942468010000"
    . "4863C941C1EA1F4989C94929C84963CC4C038C24280100004C8944241048894C"
    . "2428EB63398424380100007E634584D2755E39BC24400100007E55450FB64102"
    . "410FB6490183C0014883C201456BC0266BC94B4401C14C8B442428894C240848"
    . "8B4C24104C01C94983C104460FB604014489C1C1E1044429C1034C2408C1F907"
    . "884AFF39C5741B89C1C1E91F84C9749483C001C602004983C1044883C20139C5"
    . "75E50374243C83C7014403A42430010000397C24180F8523FFFFFF448B8C2460"
    . "0100008B8424580100004585C9448D60020F8E2EF7FFFF488B8424680100004D"
    . "63E4BF0100000031ED4A8D7420018B84246001000083C0018944241848638424"
    . "580100004C8D700348F7D0488904248B84245801000083E8014883C001488944"
    . "2408448B8424580100004585C00F8E9F000000488B04244863CD48038C247001"
    . "00004D8D0C364C8D0430488B442408488D1C304889F00FB610440FB658FF41BA"
    . "01000000035424304439DA7C46440FB658014439DA7C3C450FB658FF4439DA7C"
    . "32450FB659FF4439DA7C28450FB658FE4439DA7C1E450FB6184439DA7C15450F"
    . "B659FE4439DA7C0B450FB6114439D2410F9CC24883C0014488114983C1014883"
    . "C1014983C0014839D8758B03AC245801000083C7014C01E6397C24180F8540FF"
    . "FFFFE91EF6FFFF448B5C2430448B94246001000031DB8B84245801000031F641"
    . "83C30141C1E3074585D28D2C85000000000F8EEEF5FFFF448B94245801000045"
    . "85D27E57488B8C24280100004C63CE4C038C24700100004863C74531C0488D4C"
    . "01020FB6110FB641FF440FB661FE6BC04B6BD22601C24489E0C1E0044429E001"
    . "D04139C3430F9704014983C0014883C1044539C27FCC01EF4401D683C301037C"
    . "2418399C24600100007594E975F5FFFFC744242800000000E9CBF6FFFF909090"
    this.MCode(MyFunc, A_PtrSize=8 ? x64:x32)
  }
  return !bits.Scan0 ? 0:DllCall(&MyFunc, "int",mode
    , "uint",color, "uint",n, "int",offsetX, "int",offsetY
    , "Ptr",bits.Scan0, "int",bits.Stride, "int",bits.zw
    , "int",bits.zh, "int",sx, "int",sy, "int",sw, "int",sh
    , "Ptr",&gs, "Ptr",&ss, "AStr",text, "Ptr",&s1, "Ptr",&s0
    , "Ptr",&input, "int",num, "Ptr",&allpos, "int",allpos_max)
}

MCode(ByRef code, hex)
{
  local
  ListLines, % (lls:=A_ListLines=0?"Off":"On")?"Off":"Off"
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  VarSetCapacity(code, len:=StrLen(hex)//2)
  Loop, % len
    NumPut("0x" SubStr(hex,2*A_Index-1,2),code,A_Index-1,"uchar")
  DllCall("VirtualProtect","Ptr",&code,"Ptr",len,"uint",0x40,"Ptr*",0)
  SetBatchLines, %bch%
  ListLines, %lls%
}

base64tobit(s)
{
  local
  Chars:="0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    . "abcdefghijklmnopqrstuvwxyz"
  ListLines, % (lls:=A_ListLines=0?"Off":"On")?"Off":"Off"
  Loop, Parse, Chars
  {
    i:=A_Index-1, v:=(i>>5&1) . (i>>4&1)
      . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1)
    s:=RegExReplace(s,"[" A_LoopField "]",StrReplace(v,"0x"))
  }
  ListLines, %lls%
  return RegExReplace(RegExReplace(s,"10*$"),"[^01]+")
}

bit2base64(s)
{
  local
  s:=RegExReplace(s,"[^01]+")
  s.=SubStr("100000",1,6-Mod(StrLen(s),6))
  s:=RegExReplace(s,".{6}","|$0")
  Chars:="0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    . "abcdefghijklmnopqrstuvwxyz"
  ListLines, % (lls:=A_ListLines=0?"Off":"On")?"Off":"Off"
  Loop, Parse, Chars
  {
    i:=A_Index-1, v:="|" . (i>>5&1) . (i>>4&1)
      . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1)
    s:=StrReplace(s,StrReplace(v,"0x"),A_LoopField)
  }
  ListLines, %lls%
  return s
}

ASCII(s)
{
  local
  if RegExMatch(s,"\$(\d+)\.([\w+/]+)",r)
  {
    s:=RegExReplace(this.base64tobit(r2),".{" r1 "}","$0`n")
    s:=StrReplace(StrReplace(s,"0","_"),"1","0")
  }
  else s=
  return s
}

; You can put the text library at the beginning of the script,
; and Use FindText.PicLib(Text,1) to add the text library to PicLib()'s Lib,
; Use FindText.PicLib("comment1|comment2|...") to get text images from Lib

PicLib(comments, add_to_Lib:=0, index:=1)
{
  local
  Lib:=this.Lib
  if (add_to_Lib)
  {
    re:="<([^>]*)>[^$]+\$\d+\.[\w+/]+"
    Loop, Parse, comments, |
      if RegExMatch(A_LoopField,re,r)
      {
        s1:=Trim(r1), s2:=""
        Loop, Parse, s1
          s2.="_" . Format("{:d}",Ord(A_LoopField))
        Lib[index,s2]:=r
      }
    Lib[index,""]:=""
  }
  else
  {
    Text:=""
    Loop, Parse, comments, |
    {
      s1:=Trim(A_LoopField), s2:=""
      Loop, Parse, s1
        s2.="_" . Format("{:d}",Ord(A_LoopField))
      Text.="|" . Lib[index,s2]
    }
    return Text
  }
}

; Decompose a string into individual characters and get their data

PicN(Number, index:=1)
{
  return this.PicLib(RegExReplace(Number,".","|$0"), 0, index)
}

; Use FindText.PicX(Text) to automatically cut into multiple characters
; Can't be used in ColorPos mode, because it can cause position errors

PicX(Text)
{
  local
  if !RegExMatch(Text,"\|([^$]+)\$(\d+)\.([\w+/]+)",r)
    return Text
  v:=this.base64tobit(r3), Text:=""
  c:=StrLen(StrReplace(v,"0"))<=StrLen(v)//2 ? "1":"0"
  txt:=RegExReplace(v,".{" r2 "}","$0`n")
  While InStr(txt,c)
  {
    While !(txt~="m`n)^" c)
      txt:=RegExReplace(txt,"m`n)^.")
    i:=0
    While (txt~="m`n)^.{" i "}" c)
      i:=Format("{:d}",i+1)
    v:=RegExReplace(txt,"m`n)^(.{" i "}).*","$1")
    txt:=RegExReplace(txt,"m`n)^.{" i "}")
    if (v!="")
      Text.="|" r1 "$" i "." this.bit2base64(v)
  }
  return Text
}

; Screenshot and retained as the last screenshot.

ScreenShot(x1:="", y1:="", x2:="", y2:="")
{
  local
  if (x1+y1+x2+y2="")
    n:=150000, x:=y:=-n, w:=h:=2*n
  else
    x:=(x1<x2?x1:x2), y:=(y1<y2?y1:y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  this.GetBitsFromScreen(x,y,w,h,1)
}

; Get the RGB color of a point from the last screenshot.
; If the point to get the color is beyond the range of
; Screen, it will return White color (0xFFFFFF).

GetColor(x, y, fmt=1)
{
  local
  c:=!(bits:=this.GetBitsFromScreen(0,0,0,0,0,zx,zy,zw,zh))
    or (x<zx or x>zx+zw-1 or y<zy or y>zy+zh-1 or !bits.Scan0)
    ? 0xFFFFFF : NumGet(bits.Scan0+(y-zy)*bits.Stride+(x-zx)*4,"uint")
  return (fmt ? Format("0x{:06X}",c&0xFFFFFF) : c)
}

; Identify a line of text or verification code
; based on the result returned by FindText().
; offsetX is the maximum interval between two texts,
; if it exceeds, a "*" sign will be inserted.
; offsetY is the maximum height difference between
; the following text and the first text.
; Return Association array {ocr:Text, x:X, y:Y}

Ocr(ok, offsetX:=20, offsetY:=20)
{
  local
  ocr_Text:=ocr_X:=min_X:=""
  For k,v in ok
    x:=v.1
    , min_X:=(A_Index=1 or x<min_X ? x : min_X)
    , max_X:=(A_Index=1 or x>max_X ? x : max_X)
  While (min_X!="" and min_X<=max_X)
  {
    LeftX:=""
    For k,v in ok
    {
      x:=v.1, y:=v.2, w:=v.3, h:=v.4
      if (x<min_X) or Abs(y-ocr_Y)>offsetY
        Continue
      ; Get the leftmost X coordinates
      if (LeftX="" or x<LeftX)
        LeftX:=x, LeftY:=y, LeftW:=w, LeftH:=h, LeftOCR:=v.id
    }
    if (ocr_X="")
      ocr_X:=LeftX, ocr_Y:=LeftY, min_Y:=LeftY, max_Y:=LeftY+LeftH
    ; If the interval exceeds the set value, add "*" to the result
    ocr_Text.=(ocr_Text!="" and LeftX-min_X>offsetX ? "*":"") . LeftOCR
    ; Update min_X for next search
    min_X:=LeftX+LeftW
    , (min_Y>LeftY ? (min_Y:=LeftY):"")
    , (max_Y<LeftY+LeftH ? (max_Y:=LeftY+LeftH):"")
  }
  return {ocr:ocr_Text, x:ocr_X, y:ocr_Y
    , w: min_X-ocr_X, h: max_Y-min_Y}
}

; Sort the results returned by FindText() from left to right
; and top to bottom, ignore slight height difference

Sort(ok, dy:=10)
{
  local
  if !IsObject(ok)
    return ok
  ypos:=[]
  For k,v in ok
  {
    x:=v.x, y:=v.y, add:=1
    For k2,v2 in ypos
      if Abs(y-v2)<=dy
      {
        y:=v2, add:=0
        Break
      }
    if (add)
      ypos.Push(y)
    n:=(y*150000+x) "." k, s:=A_Index=1 ? n : s "-" n
  }
  Sort, s, N D-
  ok2:=[]
  Loop, Parse, s, -
    ok2.Push( ok[(StrSplit(A_LoopField,".")[2])] )
  return ok2
}

; Reordering according to the nearest distance

Sort2(ok, px, py)
{
  local
  if !IsObject(ok)
    return ok
  For k,v in ok
    n:=((v.x-px)**2+(v.y-py)**2) "." k, s:=A_Index=1 ? n : s "-" n
  Sort, s, N D-
  ok2:=[]
  Loop, Parse, s, -
    ok2.Push( ok[(StrSplit(A_LoopField,".")[2])] )
  return ok2
}

; Prompt mouse position in remote assistance

MouseTip(x:="", y:="", w:=10, h:=10, d:=4)
{
  local
  if (x="")
  {
    VarSetCapacity(pt,16,0), DllCall("GetCursorPos","ptr",&pt)
    x:=NumGet(pt,0,"uint"), y:=NumGet(pt,4,"uint")
  }
  x:=Round(x-w-d), y:=Round(y-h-d), w:=(2*w+1)+2*d, h:=(2*h+1)+2*d
  ;-------------------------
  Gui, _MouseTip_: +AlwaysOnTop -Caption +ToolWindow +Hwndmyid -DPIScale
  Gui, _MouseTip_: Show, Hide w%w% h%h%
  ;-------------------------
  DetectHiddenWindows, % (dhw:=A_DetectHiddenWindows)?"On":"On"
  i:=w-d, j:=h-d
  s=0-0 %w%-0 %w%-%h% 0-%h% 0-0  %d%-%d% %i%-%d% %i%-%j% %d%-%j% %d%-%d%
  WinSet, Region, %s%, ahk_id %myid%
  DetectHiddenWindows, %dhw%
  ;-------------------------
  Gui, _MouseTip_: Show, NA x%x% y%y%
  Loop, 4
  {
    Gui, _MouseTip_: Color, % A_Index & 1 ? "Red" : "Blue"
    Sleep, 500
  }
  Gui, _MouseTip_: Destroy
}

; Quickly get the search data of screen image

GetTextFromScreen(x1, y1, x2, y2, Threshold:=""
  , ScreenShot:=1, ByRef rx:="", ByRef ry:="")
{
  local
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  x:=(x1<x2?x1:x2), y:=(y1<y2?y1:y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  this.xywh2xywh(x,y,w,h,x,y,w,h,zx,zy,zw,zh)
  if (w<1 or h<1)
  {
    SetBatchLines, %bch%
    return
  }
  ListLines, % (lls:=A_ListLines=0?"Off":"On")?"Off":"Off"
  this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy,zw,zh)
  gs:=[], k:=0
  Loop, %h%
  {
    j:=y+A_Index-1
    Loop, %w%
      i:=x+A_Index-1, c:=this.GetColor(i,j,0)
      , gs[k++]:=(((c>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
  }
  if InStr(Threshold,"**")
  {
    Threshold:=StrReplace(Threshold,"*")
    if (Threshold="")
      Threshold:=50
    s:="", sw:=w, w-=2, h-=2, x++, y++
    Loop, %h%
    {
      y1:=A_Index
      Loop, %w%
        x1:=A_Index, i:=y1*sw+x1, j:=gs[i]+Threshold
        , s.=( gs[i-1]>j || gs[i+1]>j
        || gs[i-sw]>j || gs[i+sw]>j
        || gs[i-sw-1]>j || gs[i-sw+1]>j
        || gs[i+sw-1]>j || gs[i+sw+1]>j ) ? "1":"0"
    }
    Threshold:="**" Threshold
  }
  else
  {
    Threshold:=StrReplace(Threshold,"*")
    if (Threshold="")
    {
      pp:=[]
      Loop, 256
        pp[A_Index-1]:=0
      Loop, % w*h
        pp[gs[A_Index-1]]++
      IP:=IS:=0
      Loop, 256
        k:=A_Index-1, IP+=k*pp[k], IS+=pp[k]
      Threshold:=Floor(IP/IS)
      Loop, 20
      {
        LastThreshold:=Threshold
        IP1:=IS1:=0
        Loop, % LastThreshold+1
          k:=A_Index-1, IP1+=k*pp[k], IS1+=pp[k]
        IP2:=IP-IP1, IS2:=IS-IS1
        if (IS1!=0 and IS2!=0)
          Threshold:=Floor((IP1/IS1+IP2/IS2)/2)
        if (Threshold=LastThreshold)
          Break
      }
    }
    s:=""
    Loop, % w*h
      s.=gs[A_Index-1]<=Threshold ? "1":"0"
    Threshold:="*" Threshold
  }
  ;--------------------
  w:=Format("{:d}",w), CutUp:=CutDown:=0
  re1=(^0{%w%}|^1{%w%})
  re2=(0{%w%}$|1{%w%}$)
  While RegExMatch(s,re1)
    s:=RegExReplace(s,re1), CutUp++
  While RegExMatch(s,re2)
    s:=RegExReplace(s,re2), CutDown++
  rx:=x+w//2, ry:=y+CutUp+(h-CutUp-CutDown)//2
  s:="|<>" Threshold "$" w "." this.bit2base64(s)
  ;--------------------
  SetBatchLines, %bch%
  ListLines, %lls%
  return s
}

; Quickly save screen image to BMP file for debugging

SavePic(file, x1:="", y1:="", x2:="", y2:="", ScreenShot:=1)
{
  local
  static Ptr:="Ptr"
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  if (x1+y1+x2+y2="")
    n:=150000, x:=y:=-n, w:=h:=2*n
  else
    x:=(x1<x2?x1:x2), y:=(y1<y2?y1:y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  this.xywh2xywh(x,y,w,h,x,y,w,h,zx,zy,zw,zh)
  bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy,zw,zh)
  if (!bits.hBM) or (w<1 or h<1)
  {
    SetBatchLines, %bch%
    return
  }
  VarSetCapacity(bi, 40, 0), NumPut(40, bi, 0, "int")
  NumPut(w, bi, 4, "int"), NumPut(h, bi, 8, "int")
  NumPut(1, bi, 12, "short"), NumPut(bpp:=24, bi, 14, "short")
  hBM:=DllCall("CreateDIBSection", Ptr,0, Ptr,&bi
    , "int",0, "Ptr*",ppvBits:=0, Ptr,0, "int",0, Ptr)
  mDC:=DllCall("CreateCompatibleDC", Ptr,0, Ptr)
  oBM:=DllCall("SelectObject", Ptr,mDC, Ptr,hBM, Ptr)
  ;-------------------------
  mDC2:=DllCall("CreateCompatibleDC", Ptr,0, Ptr)
  oBM2:=DllCall("SelectObject", Ptr,mDC2, Ptr,bits.hBM, Ptr)
  DllCall("BitBlt",Ptr,mDC,"int",0,"int",0,"int",w,"int",h
    , Ptr,mDC2, "int",x-zx, "int",y-zy, "uint",0x00CC0020)
  DllCall("SelectObject", Ptr,mDC2, Ptr,oBM2)
  DllCall("DeleteDC", Ptr,mDC2)
  ;-------------------------
  size:=((w*bpp+31)//32)*4*h
  VarSetCapacity(bf, 14, 0), StrPut("BM", &bf, "CP0")
  NumPut(54+size, bf, 2, "uint"), NumPut(54, bf, 10, "uint")
  f:=FileOpen(file,"w"), f.RawWrite(bf,14), f.RawWrite(bi,40)
  , f.RawWrite(ppvBits+0, size), f.Close()
  ;-------------------------
  DllCall("SelectObject", Ptr,mDC, Ptr,oBM)
  DllCall("DeleteDC", Ptr,mDC)
  DllCall("DeleteObject", Ptr,hBM)
  SetBatchLines, %bch%
}

; Show the last screen shot

ShowScreenShot(onoff:=1)
{
  local
  static Ptr:="Ptr"
  Gui, FindText_Screen: Destroy
  bits:=this.GetBitsFromScreen(0,0,0,0,0,zx,zy,zw,zh)
  if (!onoff or !bits.hBM or zw<1 or zh<1)
    return
  mDC:=DllCall("CreateCompatibleDC", Ptr,0, Ptr)
  oBM:=DllCall("SelectObject", Ptr,mDC, Ptr,bits.hBM, Ptr)
  hBrush:=DllCall("CreateSolidBrush", "uint",0xFFFFFF, Ptr)
  oBrush:=DllCall("SelectObject", Ptr,mDC, Ptr,hBrush, Ptr)
  DllCall("BitBlt", Ptr,mDC, "int",0, "int",0, "int",zw, "int",zh
    , Ptr,mDC, "int",0, "int",0, "uint",0xC000CA) ; MERGECOPY
  DllCall("SelectObject", Ptr,mDC, Ptr,oBrush)
  DllCall("DeleteObject", Ptr,hBrush)
  DllCall("SelectObject", Ptr,mDC, Ptr,oBM)
  DllCall("DeleteDC", Ptr,mDC)
  ;---------------------
  Gui, FindText_Screen: +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000
  Gui, FindText_Screen: Margin, 0, 0
  Gui, FindText_Screen: Add, Picture, x0 y0 w%zw% h%zh% +Hwndid +0xE
  SendMessage, 0x172, 0, bits.hBM,, ahk_id %id%
  Gui, FindText_Screen: Show, NA x%zx% y%zy% w%zw% h%zh%, Show ScreenShot
}

; Running AHK code dynamically with new threads

Class Thread
{
  __New(args*)
  {
    this.pid:=this.Exec(args*)
  }
  __Delete()
  {
    Process, Close, % this.pid
  }
  Exec(s, Ahk:="", args:="")
  {
    local
    Ahk:=Ahk ? Ahk:A_IsCompiled ? A_ScriptDir "\AutoHotkey.exe":A_AhkPath
    s:="DllCall(""SetWindowText"",""Ptr"",A_ScriptHwnd,""Str"",""<AHK>"")`n"
      . StrReplace(s,"`r"), pid:=""
    Try
    {
      shell:=ComObjCreate("WScript.Shell")
      oExec:=shell.Exec("""" Ahk """ /f * " args)
      oExec.StdIn.Write(s)
      oExec.StdIn.Close(), pid:=oExec.ProcessID
    }
    Catch
    {
      f:=A_Temp "\~ahk.tmp"
      s:="`n FileDelete, " f "`n" s
      FileDelete, %f%
      FileAppend, %s%, %f%
      r:=ObjBindMethod(this, "Clear")
      SetTimer, %r%, -3000
      Run, "%Ahk%" /f "%f%" %args%,, UseErrorLevel, pid
    }
    return pid
  }
  Clear()
  {
    FileDelete, % A_Temp "\~ahk.tmp"
    SetTimer,, Off
  }
}

/***** C source code of machine code *****

int __attribute__((__stdcall__)) PicFind(
  int mode, unsigned int c, unsigned int n
  , int offsetX, int offsetY
  , unsigned char * Bmp, int Stride, int zw, int zh
  , int sx, int sy, int sw, int sh
  , unsigned char * gs, char * ss, char * text
  , int * s1, int * s0, int * input, int num
  , unsigned int * allpos, int allpos_max )
{
  int ok, o, o1, o2, i, j, x, y, r, g, b, rr, gg, bb, e1, e0;
  int x1, y1, w1, h1, sx1, sy1, len1, len0, err1, err0, max;
  int x2, y2, w2, h2, sx2, sy2, len21, len20, err21, err20, max2;
  int r_min, r_max, g_min, g_max, b_min, b_max, y_min, y_max;
  //----------------------
  ok=0; w1=input[1]; h1=input[2];
  len1=input[3]; len0=input[4];
  err1=input[5]; err0=input[6];
  if (err1>=len1) len1=0;
  if (err0>=len0) len0=0;
  max=len1>len0 ? len1 : len0;
  //----------------------
  // Generate Lookup Table
  for (j=0; j<num; j+=7)
  {
    o=o1=o2=input[j]; w2=input[j+1]; h2=input[j+2];
    for (y=0; y<h2; y++)
    {
      for (x=0; x<w2; x++)
      {
        i=(mode==3) ? y*Stride+x*4 : y*sw+x;
        if (text[o++]=='1')
          s1[o1++]=i;
        else
          s0[o2++]=i;
      }
    }
  }
  // Color Position Mode
  // This mode is not support combination lookup
  // only used to recognize multicolored Verification Code
  if (mode==3)
  {
    c=(c/w1)*Stride+(c%w1)*4;
    sx1=sx+sw-w1; sy1=sy+sh-h1;
    for (y=sy; y<=sy1; y++)
    {
      for (x=sx; x<=sx1; x++)
      {
        o=y*Stride+x*4; e1=err1; e0=err0;
        j=o+c; rr=Bmp[2+j]; gg=Bmp[1+j]; bb=Bmp[j];
        for (i=0; i<max; i++)
        {
          if (i<len1)
          {
            j=o+s1[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb;
            if (3*r*r+4*g*g+2*b*b>n && (--e1)<0)
              goto NoMatch3;
          }
          if (i<len0)
          {
            j=o+s0[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb;
            if (3*r*r+4*g*g+2*b*b<=n && (--e0)<0)
              goto NoMatch3;
          }
        }
        allpos[ok*2]=(y<<16)|x;
        allpos[ok*2+1]=(h1<<16)|w1;
        if (++ok>=allpos_max)
          goto Return1;
        NoMatch3:
        continue;
      }
    }
    goto Return1;
  }
  // Generate Two Value Image
  o=sy*Stride+sx*4; j=Stride-4*sw; i=0;
  if (mode==0)  // Color Mode
  {
    rr=(c>>16)&0xFF; gg=(c>>8)&0xFF; bb=c&0xFF;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
      {
        r=Bmp[2+o]-rr; g=Bmp[1+o]-gg; b=Bmp[o]-bb;
        ss[i]=(3*r*r+4*g*g+2*b*b<=n) ? 1:0;
      }
  }
  else if (mode==1)  // Gray Threshold Mode
  {
    c=(c+1)*128;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
        ss[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15<c) ? 1:0;
  }
  else if (mode==2)  // Gray Difference Mode
  {
    sx1=sx+sw; sy1=sy+sh;
    for (y=sy-1; y<=sy1; y++)
    {
      for (x=sx-1; x<=sx1; x++, i++)
        if (x<0 || x>=zw || y<0 || y>=zh)
          gs[i]=0;
        else
        {
          o=y*Stride+x*4;
          gs[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15)>>7;
        }
    }
    w2=sw+2; i=0;
    for (y=1; y<=sh; y++)
      for (x=1; x<=sw; x++, i++)
      {
        o=y*w2+x; j=gs[o]+c;
        ss[i]=( gs[o-1]>j || gs[o+1]>j
          || gs[o-w2]>j   || gs[o+w2]>j
          || gs[o-w2-1]>j || gs[o-w2+1]>j
          || gs[o+w2-1]>j || gs[o+w2+1]>j ) ? 1:0;
      }
  }
  else // (mode==4) Color Difference Mode
  {
    r=(c>>16)&0xFF; g=(c>>8)&0xFF; b=c&0xFF;
    rr=(n>>16)&0xFF; gg=(n>>8)&0xFF; bb=n&0xFF;
    r_min=r-rr; g_min=g-gg; b_min=b-bb;
    r_max=r+rr; g_max=g+gg; b_max=b+bb;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
      {
        r=Bmp[2+o]; g=Bmp[1+o]; b=Bmp[o];
        ss[i]=(r>=r_min && r<=r_max
            && g>=g_min && g<=g_max
            && b>=b_min && b<=b_max) ? 1:0;
      }
  }
  // Start Lookup
  sx1=sw-w1; sy1=sh-h1;
  for (y=0; y<=sy1; y++)
  {
    for (x=0; x<=sx1; x++)
    {
      o=y*sw+x; e1=err1; e0=err0;
      for (i=0; i<max; i++)
      {
        if ((i<len1 && ss[o+s1[i]]==0 && (--e1)<0)
        || (i<len0 && ss[o+s0[i]]!=0 && (--e0)<0))
          goto NoMatch1;
      }
      //------------------
      // Combination lookup
      if (num>7)
      {
        x2=x; y2=y; w2=w1; y_min=y2; y_max=y2+h1;
        for (j=7; j<num; j+=7)
        {
          x1=x2+w2; y1=y2-offsetY; if (y1<0) y1=0;
          o2=input[j]; w2=input[j+1]; h2=input[j+2];
          len21=input[j+3]; len20=input[j+4];
          err21=input[j+5]; err20=input[j+6];
          if (err21>=len21) len21=0;
          if (err20>=len20) len20=0;
          max2=len21>len20 ? len21 : len20;
          sx2=x1+offsetX; if (sx2>sw-w2) sx2=sw-w2;
          sy2=y2+offsetY; if (sy2>sh-h2) sy2=sh-h2;
          for (x2=x1; x2<=sx2; x2++)
          {
            for (y2=y1; y2<=sy2; y2++)
            {
              o1=y2*sw+x2; e1=err21; e0=err20;
              for (i=0; i<max2; i++)
              {
                if ((i<len21 && ss[o1+s1[o2+i]]==0 && (--e1)<0)
                || (i<len20 && ss[o1+s0[o2+i]]!=0 && (--e0)<0))
                  goto NoMatch2;
              }
              goto MatchOK;
              NoMatch2:
              continue;
            }
          }
          goto NoMatch1;
          MatchOK:
          if (y2<y_min) y_min=y2;
          if (y2+h2>y_max) y_max=y2+h2;
        }
        allpos[ok*2]=((sy+y_min)<<16)|(sx+x);
        allpos[ok*2+1]=((y_max-y_min)<<16)|(x2+w2-x);
      }
      else
      {
        allpos[ok*2]=((sy+y)<<16)|(sx+x);
        allpos[ok*2+1]=(h1<<16)|w1;
      }
      if (++ok>=allpos_max)
        goto Return1;
      // Clear the image that has been found
      for (i=0; i<len1; i++)
        ss[o+s1[i]]=0;
      NoMatch1:
      continue;
    }
  }
  Return1:
  return ok;
}

*/


;==== Optional GUI interface ====


Gui(cmd, arg1:="")
{
  local
  static
  global FindText
  local lls, bch, cri
  ListLines, % InStr("|KeyDown|LButtonDown|MouseMove|"
    , "|" cmd "|") ? "Off" : A_ListLines
  static init:=0
  if (!init)
  {
    init:=1
    Gui_:=ObjBindMethod(FindText,"Gui")
    Gui_G:=ObjBindMethod(FindText,"Gui","G")
    Gui_Run:=ObjBindMethod(FindText,"Gui","Run")
    Gui_Off:=ObjBindMethod(FindText,"Gui","Off")
    Gui_Show:=ObjBindMethod(FindText,"Gui","Show")
    Gui_KeyDown:=ObjBindMethod(FindText,"Gui","KeyDown")
    Gui_LButtonDown:=ObjBindMethod(FindText,"Gui","LButtonDown")
    Gui_MouseMove:=ObjBindMethod(FindText,"Gui","MouseMove")
    Gui_ScreenShot:=ObjBindMethod(FindText,"Gui","ScreenShot")
    Gui_ShowPic:=ObjBindMethod(FindText,"Gui","ShowPic")
    Gui_ToolTip:=ObjBindMethod(FindText,"Gui","ToolTip")
    Gui_ToolTipOff:=ObjBindMethod(FindText,"Gui","ToolTipOff")
    bch:=A_BatchLines, cri:=A_IsCritical
    Critical
    #NoEnv
    %Gui_%("Load_Language_Text")
    %Gui_%("MakeCaptureWindow")
    %Gui_%("MakeMainWindow")
    OnMessage(0x100, Gui_KeyDown)
    OnMessage(0x201, Gui_LButtonDown)
    OnMessage(0x200, Gui_MouseMove)
    Menu, Tray, Add
    Menu, Tray, Add, % Lang["1"], %Gui_Show%
    if (!A_IsCompiled and A_LineFile=A_ScriptFullPath)
    {
      Menu, Tray, Default, % Lang["1"]
      Menu, Tray, Click, 1
      Menu, Tray, Icon, Shell32.dll, 23
    }
    Critical, %cri%
    SetBatchLines, %bch%
  }
  Switch cmd
  {
  Case "Off":
    return
  Case "G":
    GuiControl, +g, %id%, %Gui_Run%
    return
  Case "Run":
    Critical
    %Gui_%(A_GuiControl)
    return
  Case "Show":
    Gui, FindText_Main: Default
    Gui, Show, Center
    GuiControl, Focus, scr
    return
  Case "MakeCaptureWindow":
    ww:=35, hh:=12, WindowColor:="0xDDEEFF"
    Gui, FindText_Capture: New
    Gui, +AlwaysOnTop -DPIScale +HwndCapture_ID
    Gui, Margin, 15, 15
    Gui, Color, %WindowColor%
    Gui, Font, s12, Verdana
    Gui, Add, Text, xm w855 h315 Section
    Gui, -Theme
    nW:=71, nH:=25, w:=11, C_:=[], Cid_:=[]
    Loop, % nW*(nH+1)
    {
      i:=A_Index, j:=i=1 ? "xs ys" : Mod(i,nW)=1 ? "xs y+1":"x+1"
      j.=i>nW*nH ? " cRed BackgroundFFFFAA" : ""
      Gui, Add, Progress, w%w% h%w% %j% +Hwndid
      Control, ExStyle, -0x20000,, ahk_id %id%
      C_[i]:=id, Cid_[id]:=i
    }
    Gui, +Theme
    Gui, Add, Slider, xm w855 vMySlider1 Hwndid Disabled
      +Center Page20 Line10 NoTicks AltSubmit
    %Gui_G%()
    Gui, Add, Slider, ym h315 vMySlider2 Hwndid Disabled
      +Center Page20 Line10 NoTicks AltSubmit +Vertical
    %Gui_G%()
    MySlider1:=MySlider2:=dx:=dy:=0
    Gui, Add, Button, xm+125 w50 vRepU Hwndid, % Lang["RepU"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutU Hwndid, % Lang["CutU"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutU3 Hwndid, % Lang["CutU3"]
    %Gui_G%()
    ;--------------
    Gui, Add, Text, x+50 yp+3 Section, % Lang["SelGray"]
    Gui, Add, Edit, x+3 yp-3 w60 vSelGray ReadOnly
    Gui, Add, Text, x+15 ys, % Lang["SelColor"]
    Gui, Add, Edit, x+3 yp-3 w120 vSelColor ReadOnly
    Gui, Add, Text, x+15 ys, % Lang["SelR"]
    Gui, Add, Edit, x+3 yp-3 w60 vSelR ReadOnly
    Gui, Add, Text, x+5 ys, % Lang["SelG"]
    Gui, Add, Edit, x+3 yp-3 w60 vSelG ReadOnly
    Gui, Add, Text, x+5 ys, % Lang["SelB"]
    Gui, Add, Edit, x+3 yp-3 w60 vSelB ReadOnly
    ;--------------
    Gui, Add, Button, xm w50 vRepL Hwndid, % Lang["RepL"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutL Hwndid, % Lang["CutL"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutL3 Hwndid, % Lang["CutL3"]
    %Gui_G%()
    Gui, Add, Button, x+15 w70 vAuto Hwndid, % Lang["Auto"]
    %Gui_G%()
    Gui, Add, Button, x+15 w50 vRepR Hwndid, % Lang["RepR"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutR Hwndid, % Lang["CutR"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutR3 Hwndid Section, % Lang["CutR3"]
    %Gui_G%()
    Gui, Add, Button, xm+125 w50 vRepD Hwndid, % Lang["RepD"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutD Hwndid, % Lang["CutD"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutD3 Hwndid, % Lang["CutD3"]
    %Gui_G%()
    ;--------------
    Gui, Add, Tab3, ys-8 -Wrap, % Lang["2"]
    Gui, Tab, 1
    Gui, Add, Text, x+15 y+15, % Lang["Threshold"]
    Gui, Add, Edit, x+15 w100 vThreshold
    Gui, Add, Button, x+15 yp-3 vGray2Two Hwndid, % Lang["Gray2Two"]
    %Gui_G%()
    Gui, Tab, 2
    Gui, Add, Text, x+15 y+15, % Lang["GrayDiff"]
    Gui, Add, Edit, x+15 w100 vGrayDiff, 50
    Gui, Add, Button, x+15 yp-3 vGrayDiff2Two Hwndid, % Lang["GrayDiff2Two"]
    %Gui_G%()
    Gui, Tab, 3
    Gui, Add, Text, x+15 y+15, % Lang["Similar1"] " 0"
    Gui, Add, Slider, x+0 w100 vSimilar1 Hwndid
      +Center Page1 NoTicks ToolTip, 100
    %Gui_G%()
    Gui, Add, Text, x+0, 100
    Gui, Add, Button, x+15 yp-3 vColor2Two Hwndid, % Lang["Color2Two"]
    %Gui_G%()
    Gui, Tab, 4
    Gui, Add, Text, x+15 y+15, % Lang["Similar2"] " 0"
    Gui, Add, Slider, x+0 w100 vSimilar2 Hwndid
      +Center Page1 NoTicks ToolTip, 100
    %Gui_G%()
    Gui, Add, Text, x+0, 100
    Gui, Add, Button, x+15 yp-3 vColorPos2Two Hwndid, % Lang["ColorPos2Two"]
    %Gui_G%()
    Gui, Tab, 5
    Gui, Add, Text, x+10 y+15, % Lang["DiffR"]
    Gui, Add, Edit, x+2 w70 vDiffR Limit3
    Gui, Add, UpDown, vdR Range0-255 Wrap
    Gui, Add, Text, x+5, % Lang["DiffG"]
    Gui, Add, Edit, x+2 w70 vDiffG Limit3
    Gui, Add, UpDown, vdG Range0-255 Wrap
    Gui, Add, Text, x+5, % Lang["DiffB"]
    Gui, Add, Edit, x+2 w70 vDiffB Limit3
    Gui, Add, UpDown, vdB Range0-255 Wrap
    Gui, Add, Button, x+5 yp-3 vColorDiff2Two Hwndid, % Lang["ColorDiff2Two"]
    %Gui_G%()
    Gui, Tab
    ;--------------
    Gui, Add, Button, xm vReset Hwndid, % Lang["Reset"]
    %Gui_G%()
    Gui, Add, Checkbox, x+15 yp+5 vModify Hwndid, % Lang["Modify"]
    %Gui_G%()
    Gui, Add, Text, x+30, % Lang["Comment"]
    Gui, Add, Edit, x+5 yp-2 w150 vComment
    Gui, Add, Button, x+30 yp-3 vSplitAdd Hwndid, % Lang["SplitAdd"]
    %Gui_G%()
    Gui, Add, Button, x+10 vAllAdd Hwndid, % Lang["AllAdd"]
    %Gui_G%()
    Gui, Add, Button, x+10 w80 vButtonOK Hwndid, % Lang["ButtonOK"]
    %Gui_G%()
    Gui, Add, Button, x+10 wp vClose gCancel, % Lang["Close"]
    Gui, Add, Button, xm vBind0 Hwndid, % Lang["Bind0"]
    %Gui_G%()
    Gui, Add, Button, x+15 vBind1 Hwndid, % Lang["Bind1"]
    %Gui_G%()
    Gui, Add, Button, x+15 vBind2 Hwndid, % Lang["Bind2"]
    %Gui_G%()
    Gui, Add, Button, x+15 vBind3 Hwndid, % Lang["Bind3"]
    %Gui_G%()
    Gui, Add, Button, x+15 vBind4 Hwndid, % Lang["Bind4"]
    %Gui_G%()
    Gui, Show, Hide, % Lang["3"]
    return
  Case "MakeMainWindow":
    Gui, FindText_Main: New
    Gui, +AlwaysOnTop -DPIScale
    Gui, Margin, 15, 15
    Gui, Color, %WindowColor%
    Gui, Font, s12 cBlack, Verdana
    Gui, Add, Text, xm, % Lang["NowHotkey"]
    Gui, Add, Edit, x+5 w200 vNowHotkey ReadOnly
    Gui, Add, Hotkey, x+5 w200 vSetHotkey1
    Gui, Add, DDL, x+5 w180 vSetHotkey2
      , % "||F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|MButton"
      . "|ScrollLock|CapsLock|Ins|Esc|BS|Del|Tab|Home|End|PgUp|PgDn"
      . "|NumpadDot|NumpadSub|NumpadAdd|NumpadDiv|NumpadMult"
    Gui, Add, GroupBox, xm y+0 w280 h55 vMyGroup
    Gui, Add, Text, xp+15 yp+20 Section, % Lang["Myww"] ": "
    Gui, Add, Text, x+0 w60, %ww%
    Gui, Add, UpDown, vMyww Range1-50, %ww%
    Gui, Add, Text, x+15 ys, % Lang["Myhh"] ": "
    Gui, Add, Text, x+0 w60, %hh%
    Gui, Add, UpDown, vMyhh Range1-50, %hh%
    GuiControlGet, p, Pos, Myhh
    GuiControl, Move, MyGroup, % "w" (pX+pW) " h" (pH+30)
    x:=pX+pW+15*2
    Gui, Add, Button, x%x% ys-8 w150 vApply Hwndid, % Lang["Apply"]
    %Gui_G%()
    Gui, Add, Checkbox, x+15 ys Checked vAddFunc, % Lang["AddFunc"] " FindText()"
    Gui, Add, Button, xm y+18 w144 vCutL2 Hwndid, % Lang["CutL2"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutR2 Hwndid, % Lang["CutR2"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutU2 Hwndid, % Lang["CutU2"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutD2 Hwndid, % Lang["CutD2"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vUpdate Hwndid, % Lang["Update"]
    %Gui_G%()
    Gui, Font, s6 bold, Verdana
    Gui, Add, Edit, xm y+10 w720 r20 vMyPic -Wrap
    Gui, Font, s12 norm, Verdana
    Gui, Add, Button, xm w240 vCapture Hwndid, % Lang["Capture"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vTest Hwndid, % Lang["Test"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCopy Hwndid, % Lang["Copy"]
    %Gui_G%()
    Gui, Add, Button, xm y+0 wp vCaptureS Hwndid, % Lang["CaptureS"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vGetRange Hwndid, % Lang["GetRange"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vTestClip Hwndid, % Lang["TestClip"]
    %Gui_G%()
    Gui, Font, s12 cBlue, Verdana
    Gui, Add, Edit, xm w720 h350 vscr Hwndhscr -Wrap HScroll
    Gui, Show, Hide, % Lang["4"]
    return
  Case "Capture","CaptureS":
    Critical
    Gui, FindText_Main: +Hwndid
    if (show_gui:=(WinExist()=id))
    {
      Gui, FindText_Main: Default
      Gui, +LastFound
      WinMinimize
      Gui, Hide
    }
    ShowScreenShot:=InStr(cmd,"CaptureS")
    if (ShowScreenShot)
      FindText.ShowScreenShot(1)
    ;----------------------
    Gui, FindText_HotkeyIf: New, -Caption +ToolWindow
    Gui, Show, NA x0 y0 w0 h0, FindText_HotkeyIf
    Hotkey, IfWinExist, FindText_HotkeyIf
    Hotkey, *RButton, %Gui_Off%, On UseErrorLevel
    ListLines, % (lls:=A_ListLines=0?"Off":"On")?"Off":"Off"
    CoordMode, Mouse
    KeyWait, RButton
    KeyWait, Ctrl
    w:=ww, h:=hh, oldx:=oldy:="", r:=StrSplit(Lang["5"],"|")
    if (!show_gui)
      w:=20, h:=8
    Loop
    {
      Sleep, 50
      MouseGetPos, x, y, Bind_ID
      if (!show_gui)
      {
        w:=x<=1 ? w-1 : x>=A_ScreenWidth-2 ? w+1:w
        h:=y<=1 ? h-1 : y>=A_ScreenHeight-2 ? h+1:h
        w:=(w<1 ? 1:w), h:=(h<1 ? 1:h)
      }
      %Gui_%("Mini_Show")
      if (oldx=x and oldy=y)
        Continue
      oldx:=x, oldy:=y
      ToolTip, % r.1 " : " x "," y "`n" r.2
    }
    Until GetKeyState("RButton","P") or GetKeyState("Ctrl","P")
    KeyWait, RButton
    KeyWait, Ctrl
    px:=x, py:=y, oldx:=oldy:=""
    Loop
    {
      Sleep, 50
      %Gui_%("Mini_Show")
      MouseGetPos, x1, y1
      if (oldx=x1 and oldy=y1)
        Continue
      oldx:=x1, oldy:=y1
      ToolTip, % r.1 " : " x "," y "`n" r.2
    }
    Until GetKeyState("RButton","P") or GetKeyState("Ctrl","P")
    KeyWait, RButton
    KeyWait, Ctrl
    ToolTip
    %Gui_%("Mini_Hide")
    ListLines, %lls%
    Hotkey, *RButton, %Gui_Off%, Off UseErrorLevel
    Hotkey, IfWinExist
    Gui, FindText_HotkeyIf: Destroy
    if (ShowScreenShot)
      FindText.ShowScreenShot(0)
    if (!show_gui)
      return [px-w, py-h, px+w, py+h]
    ;-----------------------
    %Gui_%("getcors", !ShowScreenShot)
    %Gui_%("Reset")
    Gui, FindText_Capture: Default
    Loop, 71
      GuiControl,, % C_[71*25+A_Index], 0
    Loop, 6
      GuiControl,, Edit%A_Index%
    GuiControl,, Modify, % Modify:=0
    GuiControl,, GrayDiff, 50
    GuiControl, Focus, Gray2Two
    GuiControl, +Default, Gray2Two
    Gui, Show, Center
    Event:=Result:=""
    DetectHiddenWindows, Off
    Critical, Off
    WinWaitClose, ahk_id %Capture_ID%
    Critical
    Gui, FindText_Main: Default
    ;--------------------------------
    if (cors.bind!="")
    {
      WinGetTitle, tt, ahk_id %Bind_ID%
      WinGetClass, tc, ahk_id %Bind_ID%
      tt:=Trim(SubStr(tt,1,30) (tc ? " ahk_class " tc:""))
      tt:=StrReplace(RegExReplace(tt,"[;``]","``$0"),"""","""""")
      Result:="`nSetTitleMatchMode, 2`nid:=WinExist(""" tt """)"
        . "`nFindText.BindWindow(id" (cors.bind=0 ? "":"," cors.bind)
        . ")  `; " Lang["6"] " FindText.BindWindow(0)`n`n" Result
    }
    if (Event="ButtonOK")
    {
      if (!A_IsCompiled)
      {
        FileRead, s, %A_LineFile%
        s:=SubStr(s, s~="i)\n[;=]+ Copy The")
      }
      else s:=""
      GuiControl,, scr, % Result "`n" s
      GuiControl,, MyPic, % Trim(FindText.ASCII(Result),"`n")
      Result:=s:=""
    }
    else if (Event="SplitAdd") or (Event="AllAdd")
    {
      GuiControlGet, s,, scr
      i:=j:=0, r:="\|<[^>\n]*>[^$\n]+\$\d+\.[\w+/]+"
      While j:=RegExMatch(s,r,"",j+1)
        i:=InStr(s,"`n",0,j)
      GuiControl,, scr, % SubStr(s,1,i) . Result . SubStr(s,i+1)
      GuiControl,, MyPic, % Trim(FindText.ASCII(Result),"`n")
      Result:=s:=""
    }
    ;----------------------
    Gui, Show
    GuiControl, Focus, scr
    return
  Case "Mini_Show":
    Gui, FindText_Mini_4: +LastFoundExist
    IfWinNotExist
    {
      Loop, 4
      {
        i:=A_Index
        Gui, FindText_Mini_%i%: +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000
        Gui, FindText_Mini_%i%: Show, Hide, Mini
      }
    }
    d:=2, w:=w<0 ? 0:w, h:=h<0 ? 0:h, c:=A_MSec<500 ? "Red":"Blue"
    Loop, 4
    {
      i:=A_Index
      x1:=Floor(i=3 ? x+w+1 : x-w-d)
      y1:=Floor(i=4 ? y+h+1 : y-h-d)
      w1:=Floor(i=1 or i=3 ? d : 2*(w+d)+1)
      h1:=Floor(i=2 or i=4 ? d : 2*(h+d)+1)
      Gui, FindText_Mini_%i%: Color, %c%
      Gui, FindText_Mini_%i%: Show, NA x%x1% y%y1% w%w1% h%h1%
    }
    return
  Case "Mini_Hide":
    Gui, FindText_Mini_4: +Hwndid
    Loop, 4
      Gui, FindText_Mini_%A_Index%: Destroy
    WinWaitClose, ahk_id %id%,, 3
    return
  Case "getcors":
    FindText.xywh2xywh(px-ww,py-hh,2*ww+1,2*hh+1,x,y,w,h)
    if (w<1 or h<1)
      return
    SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
    if (arg1) or (!FindText.GetBitsFromScreen(0,0,0,0,0).hBM)
      FindText.ScreenShot()
    cors:=[], gray:=[], k:=0
    ListLines, % (lls:=A_ListLines=0?"Off":"On")?"Off":"Off"
    Loop, %nH%
    {
      j:=py-hh+A_Index-1, i:=px-ww
      Loop, %nW%
        cors[++k]:=c:=FindText.GetColor(i++,j,0)
        , gray[k]:=(((c>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
    }
    ListLines, %lls%
    cors.CutLeft:=Abs(px-ww-x)
    cors.CutRight:=Abs(px+ww-(x+w-1))
    cors.CutUp:=Abs(py-hh-y)
    cors.CutDown:=Abs(py+hh-(y+h-1))
    SetBatchLines, %bch%
    return
  Case "GetRange":
    Critical
    Gui, FindText_Main: +Hwndid
    if (show_gui:=(WinExist()=id))
      Gui, FindText_Main: Hide
    ;---------------------
    Gui, FindText_GetRange: New
    Gui, +LastFound +AlWaysOnTop +ToolWindow -Caption -DPIScale +E0x08000000
    Gui, Color, White
    WinSet, Transparent, 10
    FindText.xywh2xywh(0,0,0,0,0,0,0,0,x,y,w,h)
    Gui, Show, NA x%x% y%y% w%w% h%h%, GetRange
    ;---------------------
    Gui, FindText_HotkeyIf: New, -Caption +ToolWindow
    Gui, Show, NA x0 y0 w0 h0, FindText_HotkeyIf
    Hotkey, IfWinExist, FindText_HotkeyIf
    Hotkey, *LButton, %Gui_Off%, On UseErrorLevel
    ListLines, % (lls:=A_ListLines=0?"Off":"On")?"Off":"Off"
    CoordMode, Mouse
    KeyWait, LButton
    KeyWait, Ctrl
    oldx:=oldy:="", r:=Lang["7"]
    Loop
    {
      Sleep, 50
      MouseGetPos, x, y
      if (oldx=x and oldy=y)
        Continue
      oldx:=x, oldy:=y
      ToolTip, %r%
    }
    Until GetKeyState("LButton","P") or GetKeyState("Ctrl","P")
    px:=x, py:=y, oldx:=oldy:=""
    Loop
    {
      Sleep, 50
      MouseGetPos, x, y
      w:=Abs(px-x)//2, h:=Abs(py-y)//2, x:=(px+x)//2, y:=(py+y)//2
      %Gui_%("Mini_Show")
      if (oldx=x and oldy=y)
        Continue
      oldx:=x, oldy:=y
      ToolTip, %r%
    }
    Until !(GetKeyState("LButton","P") or GetKeyState("Ctrl","P"))
    ToolTip
    %Gui_%("Mini_Hide")
    ListLines, %lls%
    Hotkey, *LButton, %Gui_Off%, Off UseErrorLevel
    Hotkey, IfWinExist
    Gui, FindText_HotkeyIf: Destroy
    Gui, FindText_GetRange: Destroy
    Clipboard:=p:=(x-w) ", " (y-h) ", " (x+w) ", " (y+h)
    if (!show_gui)
      return StrSplit(p, ",", " ")
    ;---------------------
    Gui, FindText_Main: Default
    GuiControlGet, s,, scr
    if RegExMatch(s, "i)(=\s*FindText\()([^,]*,){4}", r)
    {
      s:=StrReplace(s, r, r1 . p ",", 0, 1)
      GuiControl,, scr, %s%
    }
    Gui, Show
    return
  Case "Test","TestClip":
    Gui, FindText_Main: Default
    Gui, +LastFound
    WinMinimize
    Gui, Hide
    DetectHiddenWindows, Off
    WinWaitClose, % "ahk_id " WinExist()
    Sleep, 100
    ;----------------------
    if (cmd="Test")
      GuiControlGet, s,, scr
    else
      s:=Clipboard
    if (!A_IsCompiled) and InStr(s,"MCode(") and (cmd="Test")
    {
      s:="`n#NoEnv`nMenu, Tray, Click, 1`n" s "`nExitApp`n"
      Thread:= new FindText.Thread(s)
      DetectHiddenWindows, On
      WinWait, % "ahk_class AutoHotkey ahk_pid " Thread.pid,, 3
      if (!ErrorLevel)
        WinWaitClose,,, 30
      Thread:=""  ; kill the Thread
    }
    else
    {
      Gui, +OwnDialogs
      t:=A_TickCount, n:=150000
      , RegExMatch(s,"\|<[^>\n]*>[^$\n]+\$\d+\.[\w+/]+",v)
      , ok:=FindText.FindText(-n, -n, n, n, 0, 0, v)
      , X:=ok.1.x, Y:=ok.1.y, Comment:=ok.1.id
      r:=StrSplit(Lang["8"],"|")
      MsgBox, 4096, Tip, % r.1 ":`t" Round(ok.MaxIndex()) "`n`n"
        . r.2 ":`t" (A_TickCount-t) " " r.3 "`n`n"
        . r.4 ":`t" X ", " Y "`n`n"
        . r.5 ":`t" (ok ? r.6 " ! " Comment : r.7 " !"), 3
      for i,v in ok
        if (i<=2)
          FindText.MouseTip(ok[i].x, ok[i].y)
      ok:=""
    }
    ;----------------------
    Gui, Show
    GuiControl, Focus, scr
    return
  Case "Copy":
    Gui, FindText_Main: Default
    ControlGet, s, Selected,,, ahk_id %hscr%
    if (s="")
    {
      GuiControlGet, s,, scr
      GuiControlGet, r,, AddFunc
      if (r != 1)
        s:=RegExReplace(s,"\n\K[\s;=]+ Copy The[\s\S]*")
    }
    Clipboard:=RegExReplace(s,"\R","`r`n")
    ;----------------------
    Gui, Hide
    Sleep, 100
    Gui, Show
    GuiControl, Focus, scr
    return
  Case "Apply":
    Gui, FindText_Main: Default
    GuiControlGet, NowHotkey
    GuiControlGet, SetHotkey1
    GuiControlGet, SetHotkey2
    if (NowHotkey!="")
      Hotkey, *%NowHotkey%,, Off UseErrorLevel
    k:=SetHotkey1!="" ? SetHotkey1 : SetHotkey2
    if (k!="")
      Hotkey, *%k%, %Gui_ScreenShot%, On UseErrorLevel
    GuiControl,, NowHotkey, %k%
    GuiControl,, SetHotkey1
    GuiControl, Choose, SetHotkey2, 0
    ;------------------------
    GuiControlGet, Myww
    GuiControlGet, Myhh
    if (Myww!=ww or Myhh!=hh)
    {
      nW:=71, dx:=dy:=0
      Loop, % 71*25
        k:=A_Index, c:=WindowColor, %Gui_%("SetColor")
      ww:=Myww, hh:=Myhh, nW:=2*ww+1, nH:=2*hh+1
      i:=nW>71, j:=nH>25
      Gui, FindText_Capture: Default
      GuiControl, Enable%i%, MySlider1
      GuiControl, Enable%j%, MySlider2
      GuiControl,, MySlider1, % MySlider1:=0
      GuiControl,, MySlider2, % MySlider2:=0
    }
    return
  Case "ScreenShot":
    Critical
    FindText.ScreenShot()
    Gui, FindText_Tip: New
    ; WS_EX_NOACTIVATE:=0x08000000, WS_EX_TRANSPARENT:=0x20
    Gui, +LastFound +AlwaysOnTop +ToolWindow -Caption -DPIScale +E0x08000020
    Gui, Color, Yellow
    Gui, Font, cRed s48 bold
    Gui, Add, Text,, % Lang["9"]
    WinSet, Transparent, 200
    Gui, Show, NA y0, ScreenShot Tip
    Sleep, 1000
    Gui, Destroy
    return
  Case "Bind0","Bind1","Bind2","Bind3","Bind4":
    Critical
    FindText.BindWindow(Bind_ID, bind_mode:=SubStr(cmd,0))
    Gui, FindText_HotkeyIf: New, -Caption +ToolWindow
    Gui, Show, NA x0 y0 w0 h0, FindText_HotkeyIf
    Hotkey, IfWinExist, FindText_HotkeyIf
    Hotkey, *RButton, %Gui_Off%, On UseErrorLevel
    ListLines, % (lls:=A_ListLines=0?"Off":"On")?"Off":"Off"
    CoordMode, Mouse
    KeyWait, RButton
    KeyWait, Ctrl
    oldx:=oldy:=""
    Loop
    {
      Sleep, 50
      MouseGetPos, x, y
      if (oldx=x and oldy=y)
        Continue
      oldx:=x, oldy:=y
      ;---------------
      px:=x, py:=y, %Gui_%("getcors",1)
      %Gui_%("Reset"), r:=StrSplit(Lang["10"],"|")
      ToolTip, % r.1 " : " x "," y "`n" r.2
    }
    Until GetKeyState("RButton","P") or GetKeyState("Ctrl","P")
    KeyWait, RButton
    KeyWait, Ctrl
    ToolTip
    ListLines, %lls%
    Hotkey, *RButton, %Gui_Off%, Off UseErrorLevel
    Hotkey, IfWinExist
    Gui, FindText_HotkeyIf: Destroy
    FindText.BindWindow(0), cors.bind:=bind_mode
    return
  Case "MySlider1","MySlider2":
    Thread, Priority, 10
    Critical, Off
    dx:=nW>71 ? Round((nW-71)*MySlider1/100) : 0
    dy:=nH>25 ? Round((nH-25)*MySlider2/100) : 0
    if (oldx=dx and oldy=dy)
      return
    oldx:=dx, oldy:=dy, k:=0
    Loop, % nW*nH
      c:=(!show[++k] ? WindowColor
      : bg="" ? cors[k] : ascii[k]
      ? "Black":"White"), %Gui_%("SetColor")
    if (cmd="MySlider2")
      return
    Loop, 71
      GuiControl,, % C_[71*25+A_Index], 0
    Loop, % nW
    {
      i:=A_Index-dx
      if (i>=1 && i<=71 && show[nW*nH+A_Index])
        GuiControl,, % C_[71*25+i], 100
    }
    return
  Case "Reset":
    show:=[], ascii:=[], bg:=""
    CutLeft:=CutRight:=CutUp:=CutDown:=k:=0
    Loop, % nW*nH
      show[++k]:=1, c:=cors[k], %Gui_%("SetColor")
    Loop, % cors.CutLeft
      %Gui_%("CutL")
    Loop, % cors.CutRight
      %Gui_%("CutR")
    Loop, % cors.CutUp
      %Gui_%("CutU")
    Loop, % cors.CutDown
      %Gui_%("CutD")
    return
  Case "SetColor":
    if (nW=71 && nH=25)
      tk:=k
    else
    {
      tx:=Mod(k-1,nW)-dx, ty:=(k-1)//nW-dy
      if (tx<0 || tx>=71 || ty<0 || ty>=25)
        return
      tk:=ty*71+tx+1
    }
    c:=c="Black" ? 0x000000 : c="White" ? 0xFFFFFF
      : ((c&0xFF)<<16)|(c&0xFF00)|((c&0xFF0000)>>16)
    SendMessage, 0x2001, 0, c,, % "ahk_id " . C_[tk]
    return
  Case "RepColor":
    show[k]:=1, c:=(bg="" ? cors[k] : ascii[k]
      ? "Black":"White"), %Gui_%("SetColor")
    return
  Case "CutColor":
    show[k]:=0, c:=WindowColor, %Gui_%("SetColor")
    return
  Case "RepL":
    if (CutLeft<=cors.CutLeft)
    or (bg!="" and InStr(color,"**")
    and CutLeft=cors.CutLeft+1)
      return
    k:=CutLeft-nW, CutLeft--
    Loop, %nH%
      k+=nW, (A_Index>CutUp and A_Index<nH+1-CutDown
        ? %Gui_%("RepColor") : "")
    return
  Case "CutL":
    if (CutLeft+CutRight>=nW)
      return
    CutLeft++, k:=CutLeft-nW
    Loop, %nH%
      k+=nW, (A_Index>CutUp and A_Index<nH+1-CutDown
        ? %Gui_%("CutColor") : "")
    return
  Case "CutL3":
    Loop, 3
      %Gui_%("CutL")
    return
  Case "RepR":
    if (CutRight<=cors.CutRight)
    or (bg!="" and InStr(color,"**")
    and CutRight=cors.CutRight+1)
      return
    k:=1-CutRight, CutRight--
    Loop, %nH%
      k+=nW, (A_Index>CutUp and A_Index<nH+1-CutDown
        ? %Gui_%("RepColor") : "")
    return
  Case "CutR":
    if (CutLeft+CutRight>=nW)
      return
    CutRight++, k:=1-CutRight
    Loop, %nH%
      k+=nW, (A_Index>CutUp and A_Index<nH+1-CutDown
        ? %Gui_%("CutColor") : "")
    return
  Case "CutR3":
    Loop, 3
      %Gui_%("CutR")
    return
  Case "RepU":
    if (CutUp<=cors.CutUp)
    or (bg!="" and InStr(color,"**")
    and CutUp=cors.CutUp+1)
      return
    k:=(CutUp-1)*nW, CutUp--
    Loop, %nW%
      k++, (A_Index>CutLeft and A_Index<nW+1-CutRight
        ? %Gui_%("RepColor") : "")
    return
  Case "CutU":
    if (CutUp+CutDown>=nH)
      return
    CutUp++, k:=(CutUp-1)*nW
    Loop, %nW%
      k++, (A_Index>CutLeft and A_Index<nW+1-CutRight
        ? %Gui_%("CutColor") : "")
    return
  Case "CutU3":
    Loop, 3
      %Gui_%("CutU")
    return
  Case "RepD":
    if (CutDown<=cors.CutDown)
    or (bg!="" and InStr(color,"**")
    and CutDown=cors.CutDown+1)
      return
    k:=(nH-CutDown)*nW, CutDown--
    Loop, %nW%
      k++, (A_Index>CutLeft and A_Index<nW+1-CutRight
        ? %Gui_%("RepColor") : "")
    return
  Case "CutD":
    if (CutUp+CutDown>=nH)
      return
    CutDown++, k:=(nH-CutDown)*nW
    Loop, %nW%
      k++, (A_Index>CutLeft and A_Index<nW+1-CutRight
        ? %Gui_%("CutColor") : "")
    return
  Case "CutD3":
    Loop, 3
      %Gui_%("CutD")
    return
  Case "Gray2Two":
    Gui, FindText_Capture: Default
    GuiControl, Focus, Threshold
    GuiControlGet, Threshold
    if (Threshold="")
    {
      pp:=[]
      Loop, 256
        pp[A_Index-1]:=0
      Loop, % nW*nH
        if (show[A_Index])
          pp[gray[A_Index]]++
      IP:=IS:=0
      Loop, 256
        k:=A_Index-1, IP+=k*pp[k], IS+=pp[k]
      Threshold:=Floor(IP/IS)
      Loop, 20
      {
        LastThreshold:=Threshold
        IP1:=IS1:=0
        Loop, % LastThreshold+1
          k:=A_Index-1, IP1+=k*pp[k], IS1+=pp[k]
        IP2:=IP-IP1, IS2:=IS-IS1
        if (IS1!=0 and IS2!=0)
          Threshold:=Floor((IP1/IS1+IP2/IS2)/2)
        if (Threshold=LastThreshold)
          Break
      }
      GuiControl,, Threshold, %Threshold%
    }
    Threshold:=Round(Threshold)
    color:="*" Threshold, k:=i:=0
    Loop, % nW*nH
    {
      ascii[++k]:=v:=(gray[k]<=Threshold)
      if (show[k])
        i:=(v?i+1:i-1), c:=(v?"Black":"White"), %Gui_%("SetColor")
    }
    bg:=i>0 ? "1":"0"
    return
  Case "GrayDiff2Two":
    Gui, FindText_Capture: Default
    GuiControlGet, GrayDiff
    if (GrayDiff="")
    {
      Gui, +OwnDialogs
      MsgBox, 4096, Tip, % "`n" Lang["11"] " !`n", 1
      return
    }
    if (CutLeft=cors.CutLeft)
      %Gui_%("CutL")
    if (CutRight=cors.CutRight)
      %Gui_%("CutR")
    if (CutUp=cors.CutUp)
      %Gui_%("CutU")
    if (CutDown=cors.CutDown)
      %Gui_%("CutD")
    GrayDiff:=Round(GrayDiff)
    color:="**" GrayDiff, k:=i:=0
    Loop, % nW*nH
    {
      j:=gray[++k]+GrayDiff
      , ascii[k]:=v:=( gray[k-1]>j or gray[k+1]>j
      or gray[k-nW]>j or gray[k+nW]>j
      or gray[k-nW-1]>j or gray[k-nW+1]>j
      or gray[k+nW-1]>j or gray[k+nW+1]>j )
      if (show[k])
        i:=(v?i+1:i-1), c:=(v?"Black":"White"), %Gui_%("SetColor")
    }
    bg:=i>0 ? "1":"0"
    return
  Case "Color2Two","ColorPos2Two":
    Gui, FindText_Capture: Default
    GuiControlGet, c,, SelColor
    if (c="")
    {
      Gui, +OwnDialogs
      MsgBox, 4096, Tip, % "`n" Lang["12"] " !`n", 1
      return
    }
    UsePos:=(cmd="ColorPos2Two") ? 1:0
    GuiControlGet, n,, Similar1
    n:=Round(n/100,2), color:=c "@" n
    , n:=Floor(9*255*255*(1-n)*(1-n)), k:=i:=0
    , rr:=(c>>16)&0xFF, gg:=(c>>8)&0xFF, bb:=c&0xFF
    Loop, % nW*nH
    {
      c:=cors[++k], r:=((c>>16)&0xFF)-rr
      , g:=((c>>8)&0xFF)-gg, b:=(c&0xFF)-bb
      , ascii[k]:=v:=(3*r*r+4*g*g+2*b*b<=n)
      if (show[k])
        i:=(v?i+1:i-1), c:=(v?"Black":"White"), %Gui_%("SetColor")
    }
    bg:=i>0 ? "1":"0"
    return
  Case "ColorDiff2Two":
    Gui, FindText_Capture: Default
    GuiControlGet, c,, SelColor
    if (c="")
    {
      Gui, +OwnDialogs
      MsgBox, 4096, Tip, % "`n" Lang["12"] " !`n", 1
      return
    }
    GuiControlGet, dR
    GuiControlGet, dG
    GuiControlGet, dB
    rr:=(c>>16)&0xFF, gg:=(c>>8)&0xFF, bb:=c&0xFF
    , n:=Format("{:06X}",(dR<<16)|(dG<<8)|dB)
    , color:=StrReplace(c "-" n,"0x"), k:=i:=0
    Loop, % nW*nH
    {
      c:=cors[++k], r:=(c>>16)&0xFF, g:=(c>>8)&0xFF
      , b:=c&0xFF, ascii[k]:=v:=(Abs(r-rr)<=dR
      and Abs(g-gg)<=dG and Abs(b-bb)<=dB)
      if (show[k])
        i:=(v?i+1:i-1), c:=(v?"Black":"White"), %Gui_%("SetColor")
    }
    bg:=i>0 ? "1":"0"
    return
  Case "Modify":
    GuiControlGet, Modify, FindText_Capture:, Modify
    return
  Case "Similar1":
    GuiControl, FindText_Capture:, Similar2, %Similar1%
    return
  Case "Similar2":
    GuiControl, FindText_Capture:, Similar1, %Similar2%
    return
  Case "GetTxt":
    txt:=""
    if (bg="")
      return
    ListLines, % (lls:=A_ListLines=0?"Off":"On")?"Off":"Off"
    k:=0
    Loop, %nH%
    {
      v:=""
      Loop, %nW%
        v.=!show[++k] ? "" : ascii[k] ? "1":"0"
      txt.=v="" ? "" : v "`n"
    }
    ListLines, %lls%
    return
  Case "Auto":
    %Gui_%("GetTxt")
    if (txt="")
    {
      Gui, FindText_Capture: +OwnDialogs
      MsgBox, 4096, Tip, % "`n" Lang["13"] " !`n", 1
      return
    }
    While InStr(txt,bg)
    {
      if (txt~="^" bg "+\n")
        txt:=RegExReplace(txt,"^" bg "+\n"), %Gui_%("CutU")
      else if !(txt~="m`n)[^\n" bg "]$")
        txt:=RegExReplace(txt,"m`n)" bg "$"), %Gui_%("CutR")
      else if (txt~="\n" bg "+\n$")
        txt:=RegExReplace(txt,"\n\K" bg "+\n$"), %Gui_%("CutD")
      else if !(txt~="m`n)^[^\n" bg "]")
        txt:=RegExReplace(txt,"m`n)^" bg), %Gui_%("CutL")
      else Break
    }
    txt:=""
    return
  Case "ButtonOK","SplitAdd","AllAdd":
    Gui, FindText_Capture: Default
    Gui, +OwnDialogs
    %Gui_%("GetTxt")
    if (txt="")
    {
      MsgBox, 4096, Tip, % "`n" Lang["13"] " !`n", 1
      return
    }
    if InStr(color,"@") and (UsePos)
    {
      r:=StrSplit(color,"@")
      k:=i:=j:=0
      Loop, % nW*nH
      {
        if (!show[++k])
          Continue
        i++
        if (k=cors.SelPos)
        {
          j:=i
          Break
        }
      }
      if (j=0)
      {
        MsgBox, 4096, Tip, % "`n" Lang["12"] " !`n", 1
        return
      }
      color:="#" (j-1) "@" r.2
    }
    GuiControlGet, Comment
    if (cmd="SplitAdd")
    {
      if InStr(color,"#")
      {
        MsgBox, 4096, Tip, % Lang["14"], 3
        return
      }
      bg:=StrLen(StrReplace(txt,"0"))
        > StrLen(StrReplace(txt,"1")) ? "1":"0"
      s:="", i:=0, k:=nW*nH+1+CutLeft
      Loop, % w:=nW-CutLeft-CutRight
      {
        i++
        if (!show[k++] and A_Index<w)
          Continue
        i:=Format("{:d}",i)
        v:=RegExReplace(txt,"m`n)^(.{" i "}).*","$1")
        txt:=RegExReplace(txt,"m`n)^.{" i "}"), i:=0
        While InStr(v,bg)
        {
          if (v~="^" bg "+\n")
            v:=RegExReplace(v,"^" bg "+\n")
          else if !(v~="m`n)[^\n" bg "]$")
            v:=RegExReplace(v,"m`n)" bg "$")
          else if (v~="\n" bg "+\n$")
            v:=RegExReplace(v,"\n\K" bg "+\n$")
          else if !(v~="m`n)^[^\n" bg "]")
            v:=RegExReplace(v,"m`n)^" bg)
          else Break
        }
        if (v!="")
        {
          v:=Format("{:d}",InStr(v,"`n")-1) "." FindText.bit2base64(v)
          s.="`nText.=""|<" SubStr(Comment,1,1) ">" color "$" v """`n"
          Comment:=SubStr(Comment, 2)
        }
      }
      Event:=cmd, Result:=s
      Gui, Hide
      return
    }
    txt:=Format("{:d}",InStr(txt,"`n")-1) "." FindText.bit2base64(txt)
    s:="`nText.=""|<" Comment ">" color "$" txt """`n"
    if (cmd="AllAdd")
    {
      Event:=cmd, Result:=s
      Gui, Hide
      return
    }
    x:=px-ww+CutLeft+(nW-CutLeft-CutRight)//2
    y:=py-hh+CutUp+(nH-CutUp-CutDown)//2
    s:=StrReplace(s, "Text.=", "Text:="), r:=StrSplit(Lang["8"],"|")
    s:="`; #Include <FindText>`n"
    . "`n t1:=A_TickCount, X:=Y:=""""`n" s
    . "`n if (ok:=FindText(" x "-150000, " y "-150000, " x "+150000, " y "+150000, 0, 0, Text))"
    . "`n {"
    . "`n   CoordMode, Mouse"
    . "`n   X:=ok.1.x, Y:=ok.1.y, Comment:=ok.1.id"
    . "`n   `; Click, `%X`%, `%Y`%"
    . "`n }`n"
    . "`n MsgBox, 4096, Tip, `% """ r.1 ":``t"" Round(ok.MaxIndex())"
    . "`n   . ""``n``n" r.2 ":``t"" (A_TickCount-t1) "" " r.3 """"
    . "`n   . ""``n``n" r.4 ":``t"" X "", "" Y"
    . "`n   . ""``n``n" r.5 ":``t"" (ok ? """ r.6 " !"" : """ r.7 " !"")`n"
    . "`n for i,v in ok"
    . "`n   if (i<=2)"
    . "`n     FindText.MouseTip(ok[i].x, ok[i].y)`n"
    Event:=cmd, Result:=s
    Gui, Hide
    return
  Case "KeyDown":
    Critical
    if (A_Gui="FindText_Main" && A_GuiControl="scr")
      SetTimer, %Gui_ShowPic%, -150
    return
  Case "ShowPic":
    ControlGet, i, CurrentLine,,, ahk_id %hscr%
    ControlGet, s, Line, %i%,, ahk_id %hscr%
    GuiControl, FindText_Main:, MyPic, % Trim(FindText.ASCII(s),"`n")
    return
  Case "LButtonDown":
    Critical
    if (A_Gui!="FindText_Capture")
      return %Gui_%("KeyDown")
    MouseGetPos,,,, k2, 2
    if (k1:=Round(Cid_[k2]))<1
      return
    Gui, FindText_Capture: Default
    if (k1>71*25)
    {
      GuiControlGet, k3,, %k2%
      GuiControl,, %k2%, % k3 ? 0:100
      show[nW*nH+(k1-71*25)+dx]:=(!k3)
      return
    }
    k2:=Mod(k1-1,71)+dx, k3:=(k1-1)//71+dy
    if (k2>=nW || k3>=nH)
      return
    k1:=k, k:=k3*nW+k2+1, k2:=c
    if (Modify and bg!="" and show[k])
    {
      c:=((ascii[k]:=!ascii[k]) ? "Black":"White")
      , %Gui_%("SetColor")
    }
    else
    {
      c:=cors[k], cors.SelPos:=k
      GuiControl,, SelGray, % gray[k]
      GuiControl,, SelColor, % Format("0x{:06X}",c&0xFFFFFF)
      GuiControl,, SelR, % (c>>16)&0xFF
      GuiControl,, SelG, % (c>>8)&0xFF
      GuiControl,, SelB, % c&0xFF
    }
    k:=k1, c:=k2
    return
  Case "MouseMove":
    static PrevControl:=""
    if (PrevControl!=A_GuiControl)
    {
      PrevControl:=A_GuiControl
      SetTimer, %Gui_ToolTip%, % PrevControl ? -500 : "Off"
      SetTimer, %Gui_ToolTipOff%, % PrevControl ? -5500 : "Off"
      ToolTip
    }
    return
  Case "ToolTip":
    MouseGetPos,,, _TT
    IfWinExist, ahk_id %_TT% ahk_class AutoHotkeyGUI
      ToolTip, % Tip_Text[PrevControl ""]
    return
  Case "ToolTipOff":
    ToolTip
    return
  Case "CutL2","CutR2","CutU2","CutD2":
    Gui, FindText_Main: Default
    GuiControlGet, s,, MyPic
    s:=Trim(s,"`n") . "`n", v:=SubStr(cmd,4,1)
    if (v="U")
      s:=RegExReplace(s,"^[^\n]+\n")
    else if (v="D")
      s:=RegExReplace(s,"[^\n]+\n$")
    else if (v="L")
      s:=RegExReplace(s,"m`n)^[^\n]")
    else if (v="R")
      s:=RegExReplace(s,"m`n)[^\n]$")
    GuiControl,, MyPic, % Trim(s,"`n")
    return
  Case "Update":
    Gui, FindText_Main: Default
    GuiControl, Focus, scr
    ControlGet, i, CurrentLine,,, ahk_id %hscr%
    ControlGet, s, Line, %i%,, ahk_id %hscr%
    if !RegExMatch(s,"(\|<[^>]*>[^$]+\$)[\w+/.]+",r)
      return
    GuiControlGet, v,, MyPic
    v:=Trim(v,"`n") . "`n", w:=Format("{:d}",InStr(v,"`n")-1)
    v:=StrReplace(StrReplace(v,"0","1"),"_","0")
    s:=StrReplace(s,r,r1 . w "." FindText.bit2base64(v))
    v:="{End}{Shift Down}{Home}{Shift Up}{Del}"
    ControlSend,, %v%, ahk_id %hscr%
    Control, EditPaste, %s%,, ahk_id %hscr%
    ControlSend,, {Home}, ahk_id %hscr%
    return
  Case "Load_Language_Text":
    s=
    (
Myww       = Width = Adjust the width of the capture range
Myhh       = Height = Adjust the height of the capture range
AddFunc    = Add = Additional FindText() in Copy
NowHotkey  = Hotkey = Current screenshot hotkey
SetHotkey1 = = First sequence Screenshot hotkey
SetHotkey2 = = Second sequence Screenshot hotkey
Apply      = Apply = Apply new screenshot hotkey and adjusted capture range values
CutU2      = CutU = Cut the Upper Edge of the text in the edit box below
CutL2      = CutL = Cut the Left Edge of the text in the edit box below
CutR2      = CutR = Cut the Right Edge of the text in the edit box below
CutD2      = CutD = Cut the Lower Edge of the text in the edit box below
Update     = Update = Update the text in the edit box below to the line of code
GetRange   = GetRange = Get screen range to clipboard and replace the range in the code
TestClip   = TestClipboard = Test the Text data in the clipboard for searching images
Capture    = Capture = Initiate Image Capture Sequence
CaptureS   = CaptureS = Restore the last screenshot and then start capturing
Test       = Test = Test Results of Code
Copy       = Copy = Copy Code to Clipboard
Reset      = Reset = Reset to Original Captured Image
SplitAdd   = SplitAdd = Using Markup Segmentation to Generate Text Library
AllAdd     = AllAdd = Append Another FindText Search Text into Previously Generated Code
ButtonOK   = OK = Create New FindText Code for Testing
Close      = Close = Close the Window Don't Do Anything
Gray2Two      = Gray2Two = Converts Image Pixels from Gray Threshold to Black or White
GrayDiff2Two  = GrayDiff2Two = Converts Image Pixels from Gray Difference to Black or White
Color2Two     = Color2Two = Converts Image Pixels from Color Similar to Black or White
ColorPos2Two  = ColorPos2Two = Converts Image Pixels from Color Position to Black or White
ColorDiff2Two = ColorDiff2Two = Converts Image Pixels from Color Difference to Black or White
SelGray    = Gray = Gray value of the selected color
SelColor   = Color = The selected color
SelR       = R = Red component of the selected color
SelG       = G = Green component of the selected color
SelB       = B = Blue component of the selected color
RepU       = -U = Undo Cut the Upper Edge by 1
CutU       = U = Cut the Upper Edge by 1
CutU3      = U3 = Cut the Upper Edge by 3
RepL       = -L = Undo Cut the Left Edge by 1
CutL       = L = Cut the Left Edge by 1
CutL3      = L3 = Cut the Left Edge by 3
Auto       = Auto = Automatic Cut Edge after image has been converted to black and white
RepR       = -R = Undo Cut the Right Edge by 1
CutR       = R = Cut the Right Edge by 1
CutR3      = R3 = Cut the Right Edge by 3
RepD       = -D = Undo Cut the Lower Edge by 1
CutD       = D = Cut the Lower Edge by 1
CutD3      = D3 = Cut the Lower Edge by 3
Modify     = Modify = Allows Modify the Black and White Image
Comment    = Comment = Optional Comment used to Label Code ( Within <> )
Threshold  = Gray Threshold = Gray Threshold which Determines Black or White Pixel Conversion (0-255)
GrayDiff   = Gray Difference = Gray Difference which Determines Black or White Pixel Conversion (0-255)
Similar1   = Similarity = Adjust color similarity as Equivalent to The Selected Color
Similar2   = Similarity = Adjust color similarity as Equivalent to The Selected Color
DiffR      = R = Red Difference which Determines Black or White Pixel Conversion (0-255)
DiffG      = G = Green Difference which Determines Black or White Pixel Conversion (0-255)
DiffB      = B = Blue Difference which Determines Black or White Pixel Conversion (0-255)
Bind0      = BindWindow1 = Bind the window and Use GetDCEx() to get the image of background window
Bind1      = BindWindow1+ = Bind the window Use GetDCEx() and Modify the window to support transparency
Bind2      = BindWindow2 = Bind the window and Use PrintWindow() to get the image of background window
Bind3      = BindWindow2+ = Bind the window Use PrintWindow() and Modify the window to support transparency
Bind4      = BindWindow3 = Bind the window and Use PrintWindow(,,3) to get the image of background window
1  = FindText
2  = Gray|GrayDiff|Color|ColorPos|ColorDiff
3  = Capture Image To Text
4  = Capture Image To Text And Find Text Tool
5  = Position|First click RButton\nMove the mouse away\nSecond click RButton
6  = Unbind Window using
7  = Please drag a range with the LButton\nCoordinates are copied to clipboard
8  = Found|Time|ms|Pos|Result|Success|Failed
9  = Success
10 = The Capture Position|Perspective binding window\nRight click to finish capture
11 = Please Set Gray Difference First
12 = Please select the core color first
13 = Please convert the image to black or white first
14 = Can't be used in ColorPos mode, because it can cause position errors
    )
    Lang:=[], Tip_Text:=[]
    Loop, Parse, s, `n, `r
      if InStr(v:=A_LoopField, "=")
        r:=StrSplit(StrReplace(v,"\n","`n"), "=", "`t ")
        , Lang[r.1 ""]:=r.2, Tip_Text[r.1 ""]:=r.3
    return
  }
}

}  ;// Class End

;================= The End =================

;