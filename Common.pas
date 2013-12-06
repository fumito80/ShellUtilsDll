unit Common;

interface

uses
  Windows;

procedure gpcStrToClipboard(const sWText: WideString);
function gfnsStrFromClipboard: WideString;

implementation

function gfnsStrFromClipboard: WideString;
//クリップボードの文字列を取得して返す
var
  li_Format: array[0..1] of Integer;
  li_Text: Integer;
  lh_Clip, lh_Data: THandle;
  lp_Clip, lp_Data: Pointer;
begin
  Result := '';
  li_Format[0] := CF_UNICODETEXT;
  li_Format[1] := CF_TEXT;
  li_Text := GetPriorityClipboardFormat(li_Format, 2);
  if (li_Text > 0) then begin
    if (OpenClipboard(GetActiveWindow)) then begin
      lh_Clip := GetClipboardData(li_Text);
      if (lh_Clip <> 0) then begin
        lh_Data := 0;
        if (GlobalFlags(lh_Clip) <> GMEM_INVALID_HANDLE) then begin
          try
            if (li_Text = CF_UNICODETEXT)  then begin
              //Unicode文字列を優先
              lh_Data := GlobalAlloc(GHND or GMEM_SHARE, GlobalSize(lh_Clip));
              lp_Clip := GlobalLock(lh_Clip);
              lp_Data := GlobalLock(lh_Data);
              lstrcpyW(lp_Data, lp_Clip);
              Result := WideString(PWideChar(lp_Data));
              GlobalUnlock(lh_Data);
              GlobalFree(lh_Data);
              GlobalUnlock(lh_Clip); //GlobalFreeはしてはいけない
            end else if (li_Text = CF_TEXT) then begin
              lh_Data := GlobalAlloc(GHND or GMEM_SHARE, GlobalSize(lh_Clip));
              lp_Clip := GlobalLock(lh_Clip);
              lp_Data := GlobalLock(lh_Data);
              lstrcpy(lp_Data, lp_Clip);
              Result := AnsiString(PAnsiChar(lp_Data));
              GlobalUnlock(lh_Data);
              GlobalFree(lh_Data);
              GlobalUnlock(lh_Clip); //GlobalFreeはしてはいけない
            end;
          finally
            if (lh_Data <> 0) then GlobalUnlock(lh_Data);
            CloseClipboard;
          end;
        end;
      end;
    end;
  end;
end;

procedure gpcStrToClipboard(const sWText: WideString);
//クリップボードへ文字列をセットする
//Unicode文字列としてセットすると同時に（Unicodeでない）プレーンテキストとしてもセットする
var
  li_WLen, li_Len: Integer;
  ls_Text: AnsiString;
  lh_Mem: THandle;
  lp_Data: Pointer;
begin
  li_WLen := Length(sWText) * 2 + 2;
  ls_Text := AnsiString(sWText);
  li_Len  := Length(ls_Text) + 1;
  if (OpenClipboard(GetActiveWindow)) then begin
    try
      EmptyClipboard;
      if (sWText <> '') then begin
        //CF_UNICODETEXT
        lh_Mem  := GlobalAlloc(GHND or GMEM_SHARE, li_WLen);
        lp_Data := GlobalLock(lh_Mem);
        lstrcpyW(lp_Data, PWideChar(sWText));
        GlobalUnlock(lh_Mem);
        SetClipboardData(CF_UNICODETEXT, lh_Mem);
        //CF_TEXT
        lh_Mem  := GlobalAlloc(GHND or GMEM_SHARE, li_Len);
        lp_Data := GlobalLock(lh_Mem);
        lstrcpy(lp_Data, PAnsiChar(ls_Text));
        GlobalUnlock(lh_Mem);
        SetClipboardData(CF_TEXT, lh_Mem);
      end;
    finally
      CloseClipboard;
    end;
  end;
end;

end.
