(*
  Ita IDE Plugin

  Copyright (c) 2014-2017 Lyna

  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
*)
unit UItaMain;

{$IF CompilerVersion >= 30.00}
  {$DEFINE HAS_BUFFERED_CANVAS}
{$IFEND}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  System.IniFiles, System.Win.Registry, System.Rtti, System.TypInfo,
  System.Types, System.UITypes, FMX.Types, FMX.Surfaces,
  {$IF FireMonkeyVersion >= 19.0}FMX.Graphics,{$IFEND}
  Vcl.Controls, Vcl.Graphics, Vcl.Menus, ToolsAPI, UItaConfig;

procedure LoadBackgroundImage;
procedure SaveSettings;

type
{$IF FireMonkeyVersion >= 19.0}
  TFmxBitmap = FMX.Graphics.TBitmap;
{$ELSE}
  TFmxBitmap = FMX.Types.TBitmap;
{$IFEND}

  TImageAlign = (iaLeftTop, iaLeftBottom, iaRightTop, iaRightBottom);

  TImageSettings = record
    FileName: string;
    Align: TImageAlign;
    Position: TPoint;
    Scale: Integer;
    AlphaBlendValue: Byte;
  end;

const
  SCALE_BASE = 1000;

var
  ImageSettings: TImageSettings = (
    FileName: '';
    Align: iaRightTop;
    Position: (X: 0; Y: 0);
    Scale: SCALE_BASE;
    AlphaBlendValue: 64;
  );

implementation

const
  sEVFillRect = '@Editorcontrol@TCustomEditControl@EVFillRect$qqrrx18System@Types@TRect';
  sEVScrollRect = '@Editorcontrol@TCustomEditControl@EVScrollRect$qqrp18System@Types@TRectt1ii';
  sEditControlList = '@Editorcontrol@EditControlList';

  EVFillRectCodes: array[0..5] of Byte = (
    $53,      // PUSH EBX
    $56,      // PUSH ESI
    $8B, $F2, // MOV ESI,EDX
    $8B, $D8  // MOV EBX,EAX
  );
  EVScrollRectCodes: array[0..5] of Byte = (
    $55,          // PUSH EBP
    $8B, $EC,     // MOV EBP,ESP
    $83, $C4, $FF // ADD ESP,-xx
  );

  CoreIdeModuleName =
    {$IFDEF VER230}'coreide160.bpl'{$ENDIF} // XE2
    {$IFDEF VER240}'coreide170.bpl'{$ENDIF} // XE3
    {$IFDEF VER250}'coreide180.bpl'{$ENDIF} // XE4
    {$IFDEF VER260}'coreide190.bpl'{$ENDIF} // XE5
    {$IFDEF VER270}'coreide200.bpl'{$ENDIF} // XE6
    {$IFDEF VER280}'coreide210.bpl'{$ENDIF} // XE7
    {$IFDEF VER290}'coreide220.bpl'{$ENDIF} // XE8
    {$IFDEF VER300}'coreide230.bpl'{$ENDIF} // 10 Seattle
    {$IFDEF VER310}'coreide240.bpl'{$ENDIF} // 10.1 Berlin
    {$IFDEF VER320}'coreide250.bpl'{$ENDIF} // 10.2 Tokyo
    ;

  HighlightRegKey =
    {$IFDEF VER230}'\Software\Embarcadero\BDS\9.0\Editor\Highlight\'{$ENDIF}  // XE2
    {$IFDEF VER240}'\Software\Embarcadero\BDS\10.0\Editor\Highlight\'{$ENDIF} // XE3
    {$IFDEF VER250}'\Software\Embarcadero\BDS\11.0\Editor\Highlight\'{$ENDIF} // XE4
    {$IFDEF VER260}'\Software\Embarcadero\BDS\12.0\Editor\Highlight\'{$ENDIF} // XE5
    {$IFDEF VER270}'\Software\Embarcadero\BDS\14.0\Editor\Highlight\'{$ENDIF} // XE6
    {$IFDEF VER280}'\Software\Embarcadero\BDS\15.0\Editor\Highlight\'{$ENDIF} // XE7
    {$IFDEF VER290}'\Software\Embarcadero\BDS\16.0\Editor\Highlight\'{$ENDIF} // XE8
    {$IFDEF VER300}'\Software\Embarcadero\BDS\17.0\Editor\Highlight\'{$ENDIF} // 10 Seattle
    {$IFDEF VER310}'\Software\Embarcadero\BDS\18.0\Editor\Highlight\'{$ENDIF} // 10.1 Berlin
    {$IFDEF VER320}'\Software\Embarcadero\BDS\19.0\Editor\Highlight\'{$ENDIF} // 10.2 Tokyo
    ;
  HighlightRegName = 'Background Color New';

var
  TCustomEditControl_EVScrollRect: Pointer;
  TCustomEditControl_EVFillRect: Pointer;
  EditControlList: ^TList;

  ImageSize: TSize;
  LeftGutterProp: PPropInfo;
  BufferDict: TObjectDictionary<TColor,TBitmap>;
  TempBuffer: TBitmap;

type
  TEditControl = class(TCustomControl)
  private
    function GetCanvas: TCanvas;
  public
    property Canvas: TCanvas read GetCanvas;
  end;

function TEditControl.GetCanvas: TCanvas;
{$IFDEF HAS_BUFFERED_CANVAS}
  external CoreIdeModuleName name '@Editorcontrol@TCustomEditControl@GetCanvas$qqrv';
{$ELSE}
begin
  Result := inherited Canvas;
end;
{$ENDIF}

procedure EditControlOnResize(Self: TObject; Sender: TEditControl);
begin
  Sender.Invalidate;
end;

const
  EditControlOnResizeEvent: TMethod = (Code: @EditControlOnResize; Data: nil);

procedure HookEVFillRect(Self: TEditControl; const R: TRect);
var
  leftGutterWidth: Integer;
  imageRect, editorRect: TRect;
  buf: TBitmap;
begin
  if not Assigned(Self.OnResize) then
    Self.OnResize := TNotifyEvent(EditControlOnResizeEvent);

  leftGutterWidth := 0;
  case ImageSettings.Align of
    iaLeftTop:
      editorRect := Bounds(ImageSettings.Position.X, ImageSettings.Position.Y, ImageSize.cx, ImageSize.cy);
    iaLeftBottom:
      editorRect := Bounds(ImageSettings.Position.X, Self.ClientHeight - ImageSettings.Position.Y - ImageSize.cy, ImageSize.cx, ImageSize.cy);
    iaRightTop:
      editorRect := Bounds(Self.ClientWidth - ImageSettings.Position.X - ImageSize.cx, ImageSettings.Position.Y, ImageSize.cx, ImageSize.cy);
    iaRightBottom:
      editorRect := Bounds(Self.ClientWidth - ImageSettings.Position.X - ImageSize.cx, Self.ClientHeight - ImageSettings.Position.Y - ImageSize.cy, ImageSize.cx, ImageSize.cy);
  end;
  if (ImageSettings.Align in [iaLeftTop, iaLeftBottom]) and (LeftGutterProp <> nil) then
  begin
    leftGutterWidth := GetOrdProp(Self, LeftGutterProp);
    editorRect.Offset(leftGutterWidth, 0);
  end;

  if not IntersectRect(editorRect, editorRect, R) then
  begin
    Self.Canvas.FillRect(R);
    Exit;
  end;

  imageRect := editorRect;
  case ImageSettings.Align of
    iaLeftTop:
      imageRect.Offset(-ImageSettings.Position.X-leftGutterWidth, -ImageSettings.Position.Y);
    iaLeftBottom:
      imageRect.Offset(-ImageSettings.Position.X-leftGutterWidth, -(Self.ClientHeight - ImageSettings.Position.Y - ImageSize.cy));
    iaRightTop:
      imageRect.Offset(-(Self.ClientWidth - ImageSettings.Position.X - ImageSize.cx), -ImageSettings.Position.Y);
    iaRightBottom:
      imageRect.Offset(-(Self.ClientWidth - ImageSettings.Position.X - ImageSize.cx), -(Self.ClientHeight - ImageSettings.Position.Y - ImageSize.cy));
  end;

{$IFDEF HAS_BUFFERED_CANVAS}
    FillRect(Self.Canvas.Handle, R, Self.Canvas.Brush.Handle);
    if BufferDict.TryGetValue(Self.Canvas.Brush.Color, buf) then
      Self.Canvas.CopyRect(editorRect, buf.Canvas, imageRect);
{$ELSE}
  if editorRect = R then
  begin
    if BufferDict.TryGetValue(Self.Canvas.Brush.Color, buf) then
      Self.Canvas.CopyRect(editorRect, buf.Canvas, imageRect)
    else
      FillRect(Self.Canvas.Handle, R, Self.Canvas.Brush.Handle);
  end
  else begin
    if (TempBuffer.Width < R.Width) or (TempBuffer.Height < R.Height) then
      TempBuffer.SetSize(R.Width, R.Height);

    TempBuffer.Canvas.Brush.Color := Self.Canvas.Brush.Color;
    TempBuffer.Canvas.FillRect(Rect(0, 0, R.Width, R.Height));

    if BufferDict.TryGetValue(Self.Canvas.Brush.Color, buf) then
    begin
      TempBuffer.Canvas.CopyRect(Bounds(editorRect.Left-R.Left, editorRect.Top-R.Top, editorRect.Width, editorRect.Height),
        buf.Canvas, imageRect);
    end;

    Self.Canvas.CopyRect(R, TempBuffer.Canvas, Bounds(0, 0, R.Width, R.Height));
  end;
{$ENDIF}
end;

procedure HookEVScrollRect(Self: TEditControl; Src, Dest: PRect; DX, DY: Integer);
const
  EmptyRect: TRect = (Left: 0; Top: 0; Right: 0; Bottom: 0);
begin
  if Dest <> nil then
    Dest^ :=  EmptyRect;
  Self.Invalidate;
end;

procedure RefreshEditors;
var
  iEditor: Integer;
begin
  if EditControlList = nil then Exit;
  if EditControlList^ = nil then Exit;

  for iEditor := 0 to EditControlList^.Count-1 do
    TWinControl(EditControlList^[iEditor]).Invalidate;
end;

function Hook: Boolean;

  function IsValidCodes(P: PByte; const Codes: array of Byte): Boolean;
  var
    i: Integer;
  begin
    if P = nil then Exit(False);
    for i := Low(Codes) to High(Codes) do
    begin
      if P^ and Codes[i] <> P^ then
        Exit(False);
      Inc(P);
    end;
    Result := True;
  end;

  procedure JmpHookProc(Target: Pointer; ReplaceProc: Pointer);
  var
    oldProtect: Cardinal;
  begin
    VirtualProtect(Target, 5, PAGE_READWRITE, oldProtect);
    PByte(Target)^ := $E9;
    PNativeInt(NativeInt(Target)+1)^ := NativeInt(ReplaceProc) - NativeInt(Target) - 5;
    VirtualProtect(Target, 5, oldProtect, oldProtect);
    FlushInstructionCache(GetCurrentProcess, Target, 5);
  end;

var
  hModule: THandle;
  ctx: TRttiContext;
  typ: TRttiType;
  prop: TRttiProperty;
begin
  Result := False;

  hModule := GetModuleHandle(CoreIdeModuleName);
  if hModule = 0 then Exit;

  TCustomEditControl_EVFillRect := GetProcAddress(hModule, sEVFillRect);
  TCustomEditControl_EVScrollRect := GetProcAddress(hModule, sEVScrollRect);
  EditControlList := GetProcAddress(hModule, sEditControlList);

  if not IsValidCodes(TCustomEditControl_EVFillRect, EVFillRectCodes) or
     not IsValidCodes(TCustomEditControl_EVScrollRect, EVScrollRectCodes) or
     (EditControlList = nil) then
  begin
    TCustomEditControl_EVFillRect := nil;
    TCustomEditControl_EVScrollRect := nil;
    EditControlList := nil;
    Exit;
  end;

  JmpHookProc(TCustomEditControl_EVFillRect, @HookEVFillRect);
  JmpHookProc(TCustomEditControl_EVScrollRect, @HookEVScrollRect);

  typ := ctx.FindType('EditorControl.TEditControl');
  if typ <> nil then
  begin
    prop := typ.GetProperty('LeftGutter');
    if prop <> nil then
      LeftGutterProp := TRttiInstanceProperty(prop).PropInfo;
  end;

  RefreshEditors;

  Result := True;
end;

procedure Unhook;

  procedure UnhookProc(Target: Pointer; Size: Integer; const OrgCodes: array of Byte);
  var
    oldProtect: Cardinal;
  begin
    VirtualProtect(Target, Size, PAGE_READWRITE, oldProtect);
    Move(OrgCodes[0], Target^, Size);
    VirtualProtect(Target, Size, oldProtect, oldProtect);
    FlushInstructionCache(GetCurrentProcess, Target, 5);
  end;

var
  i: Integer;
begin
  if TCustomEditControl_EVFillRect = nil then Exit;
  if TCustomEditControl_EVScrollRect = nil then Exit;
  if EditControlList = nil then Exit;

  if EditControlList^ <> nil then
    for i := 0 to EditControlList^.Count-1 do
      TEditControl(EditControlList^[i]).OnResize := nil;

  UnhookProc(TCustomEditControl_EVFillRect, 5, EVFillRectCodes);
  UnhookProc(TCustomEditControl_EVScrollRect, 5, EVScrollRectCodes);

  RefreshEditors;
end;

procedure LoadBackgroundImage;

  function GetBackgroundColors: TArray<TColor>;
  var
    reg: TRegistry;
    keys: TStringList;
    i: Integer;
  begin
    Result := nil;

    reg := TRegistry.Create;
    try
      reg.RootKey := HKEY_CURRENT_USER;
      if not reg.OpenKeyReadOnly(HighlightRegKey) then Exit;

      keys := TStringList.Create;
      try
        reg.GetKeyNames(keys);
        for i := 0 to keys.Count-1 do
        begin
          if not reg.OpenKeyReadOnly(HighlightRegKey + keys[i]) then Continue;
          if not reg.ValueExists(HighlightRegName) then Continue;

          SetLength(Result, Length(Result)+1);
          Result[High(Result)] := StringToColor(reg.ReadString(HighlightRegName));
        end;
      finally
        keys.Free;
      end;
    finally
      reg.Free;
    end;
  end;

  function GetBlendedImage(Image: TFmxBitmap; Color: TAlphaColor): TBitmap;
  var
    tmp: TFmxBitmap;
    r: TRectF;
    ms: TMemoryStream;
    surf: TBitmapSurface;
  begin
    Result := TBitmap.Create;
    try
      tmp := TFmxBitmap.Create(Image.Width, Image.Height);
      try
        tmp.Canvas.BeginScene;
        try
          tmp.Canvas.Clear(Color);
          r := RectF(0, 0, Image.Width, Image.Height);
          tmp.Canvas.DrawBitmap(Image, r, r, 1.0);
        finally
          tmp.Canvas.EndScene;
        end;

        ms := TMemoryStream.Create;
        try
          surf := TBitmapSurface.Create;
          try
            surf.Assign(tmp);
            TBitmapCodecManager.SaveToStream(ms, surf, '.bmp');
          finally
            surf.Free;
          end;

          ms.Position := 0;
          Result.LoadFromStream(ms);
        finally
          ms.Free;
        end;
      finally
        tmp.Free;
      end;
    except
      FreeAndNil(Result);
    end;
  end;

  function ColorToAlphaColor(Color: TColor): TAlphaColor;
  begin
    TAlphaColorRec(Result).R := TColorRec(ColorToRGB(Color)).R;
    TAlphaColorRec(Result).G := TColorRec(ColorToRGB(Color)).G;
    TAlphaColorRec(Result).B := TColorRec(ColorToRGB(Color)).B;
    TAlphaColorRec(Result).A := 255;
  end;

var
  buf: TBitmap;
  color: TColor;

  rs: TResourceStream;
  tmp, Image: TFmxBitmap;
begin
  BufferDict.Clear;
  try
    Image := TFmxBitmap.Create(0, 0);
    try
      if not FileExists(ImageSettings.FileName) then
      begin
        rs := TResourceStream.Create(HInstance, 'PNG_DEFAULT', RT_RCDATA);
        try
          tmp := TFmxBitmap.CreateFromStream(rs);
        finally
          rs.Free;
        end;
      end
      else
        tmp := TFmxBitmap.CreateFromFile(ImageSettings.FileName);
      try
        ImageSize.cx := Trunc(tmp.Width * ImageSettings.Scale / SCALE_BASE);
        ImageSize.cy := Trunc(tmp.Height * ImageSettings.Scale / SCALE_BASE);
        Image.SetSize(ImageSize.cx, ImageSize.cy);

        Image.Canvas.BeginScene;
        try
          Image.Canvas.Clear(0);
          Image.Canvas.DrawBitmap(tmp, RectF(0, 0, tmp.Width, tmp.Height), RectF(0, 0, ImageSize.cx, ImageSize.cy), ImageSettings.AlphaBlendValue / 255);
        finally
          Image.Canvas.EndScene;
        end;
      finally
        tmp.Free;
      end;

      for color in GetBackgroundColors do
      begin
        if BufferDict.ContainsKey(color) then Continue;

        buf := GetBlendedImage(Image, ColorToAlphaColor(color));
        if buf <> nil then
          BufferDict.Add(color, buf);
      end;
    finally
      Image.Free;
    end;
  except
    BufferDict.Clear;
    Exit;
  end;

  RefreshEditors;
end;

procedure LoadSettings;
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(ExtractFilePath(GetModuleName(HInstance)) + 'itaide.ini');
  try
    ImageSettings.FileName := ini.ReadString('Image', 'FileName', ImageSettings.FileName);
    ImageSettings.Align := TImageAlign(ini.ReadInteger('Image', 'Align', Ord(ImageSettings.Align)));
    ImageSettings.Position.X := ini.ReadInteger('Image', 'Left', ImageSettings.Position.X);
    ImageSettings.Position.Y := ini.ReadInteger('Image', 'Top', ImageSettings.Position.Y);
    ImageSettings.Scale := ini.ReadInteger('Image', 'Scale', ImageSettings.Scale);
    ImageSettings.AlphaBlendValue := ini.ReadInteger('Image', 'Alpha', ImageSettings.AlphaBlendValue);
  finally
    ini.Free;
  end;
end;

procedure SaveSettings;
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(ExtractFilePath(GetModuleName(HInstance)) + 'itaide.ini');
  try
    ini.WriteString('Image', 'FileName', ImageSettings.FileName);
    ini.WriteInteger('Image', 'Align', Ord(ImageSettings.Align));
    ini.WriteInteger('Image', 'Left', ImageSettings.Position.X);
    ini.WriteInteger('Image', 'Top', ImageSettings.Position.Y);
    ini.WriteInteger('Image', 'Scale', ImageSettings.Scale);
    ini.WriteInteger('Image', 'Alpha', ImageSettings.AlphaBlendValue);
    ini.UpdateFile;
  finally
    ini.Free;
  end;
end;

var
  ItaIDEMenu: TMenuItem;

procedure ItaIDEImageMenuClick(Self, Sender: TObject);
begin
  ShowConfigDialog;
end;

procedure RegisterMenu;
var
  nta: INTAServices;
  i, j: Integer;
  method: TMethod;
begin
  nta := BorlandIDEServices as INTAServices;
  for i := 0 to nta.MainMenu.Items.Count-1 do
  begin
    if nta.MainMenu.Items[i].Name <> 'ToolsMenu' then Continue;

    for j := 0 to nta.MainMenu.Items[i].Count-1 do
    begin
      if nta.MainMenu.Items[i][j].Name <> 'ToolsToolsItem' then Continue;

      ItaIDEMenu := TMenuItem.Create(nil);
      ItaIDEMenu.AutoHotkeys := maManual;
      if SameText(PreferredUILanguages, 'JA') then
        ItaIDEMenu.Caption := '痛IDE設定'
      else
        ItaIDEMenu.Caption := 'Ita IDE Options';
      method.Code := @ItaIDEImageMenuClick;
      method.Data := ItaIDEMenu;
      ItaIDEMenu.OnClick := TNotifyEvent(method);
      nta.MainMenu.Items[i].Insert(j, ItaIDEMenu);

      Break;
    end;

    Break;
  end;
end;

procedure UnregisterMenu;
begin
  ItaIDEMenu.Free;
end;

initialization
  BufferDict := TObjectDictionary<TColor,TBitmap>.Create([doOwnsValues]);
  TempBuffer := TBitmap.Create;
  LoadSettings;
  LoadBackgroundImage;
  if not Hook then Exit;
  RegisterMenu;
finalization
  UnregisterMenu;
  Unhook;
  BufferDict.Free;
  TempBuffer.Free;
end.
