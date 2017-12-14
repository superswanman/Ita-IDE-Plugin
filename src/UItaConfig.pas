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
unit UItaConfig;

interface

{$WARN SYMBOL_PLATFORM OFF}

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtDlgs, Vcl.ComCtrls;

type
  TConfigDlg = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    btnPreview: TButton;
    gbFileName: TGroupBox;
    edImagePath: TEdit;
    btnSelectImage: TButton;
    gbPosition: TGroupBox;
    rbLeftTop: TRadioButton;
    rbLeftBottom: TRadioButton;
    rbRightTop: TRadioButton;
    rbRightBottom: TRadioButton;
    lblMarginX: TLabel;
    lblMarginY: TLabel;
    edX: TEdit;
    edY: TEdit;
    udX: TUpDown;
    udY: TUpDown;
    gbAlphaBlend: TGroupBox;
    lblAlpha: TLabel;
    tbAlpha: TTrackBar;
    gbScale: TGroupBox;
    lblScale: TLabel;
    tbScale: TTrackBar;
    od: TFileOpenDialog;
    procedure btnSelectImageClick(Sender: TObject);
    procedure tbAlphaChange(Sender: TObject);
    procedure btnPreviewClick(Sender: TObject);
    procedure tbScaleChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure ApplySettings;
  end;

procedure ShowConfigDialog;

implementation

uses
  UItaMain;

{$R *.dfm}

procedure ShowConfigDialog;
var
  dlg: TConfigDlg;
  oldSettings: TImageSettings;
begin
  oldSettings := ImageSettings;
  dlg := TConfigDlg.Create(nil);
  try
    dlg.edImagePath.Text := ImageSettings.FileName;
    case ImageSettings.Align of
      iaLeftTop: dlg.rbLeftTop.Checked := True;
      iaLeftBottom: dlg.rbLeftBottom.Checked := True;
      iaRightTop: dlg.rbRightTop.Checked := True;
      iaRightBottom: dlg.rbRightBottom.Checked := True;
    end;
    dlg.udX.Position := ImageSettings.Position.X;
    dlg.udY.Position := ImageSettings.Position.Y;
    dlg.tbScale.Position := ImageSettings.Scale;
    dlg.tbAlpha.Position := ImageSettings.AlphaBlendValue;

    if dlg.ShowModal = mrOk then
    begin
      dlg.ApplySettings;
      SaveSettings;
    end
    else begin
      ImageSettings := oldSettings;
    end;

    LoadBackgroundImage;
  finally
    dlg.Free;
  end;
end;

procedure TConfigDlg.FormCreate(Sender: TObject);
begin
  if SameText(PreferredUILanguages, 'JA') then
  begin
    Caption := '痛IDE設定';
    gbFileName.Caption := 'ファイル名';
    edImagePath.TextHint := '(デフォルト)';
    gbPosition.Caption := '表示位置';
    rbLeftTop.Caption := '左上';
    rbLeftBottom.Caption := '左下';
    rbRightTop.Caption := '右上';
    rbRightBottom.Caption := '右下';
    lblMarginX.Caption := '横マージン';
    lblMarginY.Caption := '縦マージン';
    gbScale.Caption := '表示サイズ';
    gbAlphaBlend.Caption := '透過率';
    btnPreview.Caption := 'プレビュー';
    btnCancel.Caption := 'キャンセル';
    Font.Name := 'ＭＳ Ｐゴシック';
    Font.Size := 9;
  end;
end;

procedure TConfigDlg.btnSelectImageClick(Sender: TObject);
begin
  if not od.Execute(Handle) then Exit;
  edImagePath.Text := od.FileName;

  ApplySettings;
  LoadBackgroundImage;
end;

procedure TConfigDlg.tbScaleChange(Sender: TObject);
begin
  lblScale.Caption := Format('%.1f%%', [tbScale.Position / 10]);
end;

procedure TConfigDlg.tbAlphaChange(Sender: TObject);
begin
  lblAlpha.Caption := IntToStr(tbAlpha.Position);
end;

procedure TConfigDlg.btnPreviewClick(Sender: TObject);
begin
  ApplySettings;

  LoadBackgroundImage;
end;

procedure TConfigDlg.ApplySettings;
begin
  ImageSettings.FileName := edImagePath.Text;
  if rbLeftTop.Checked then
    ImageSettings.Align := iaLeftTop
  else if rbLeftBottom.Checked then
    ImageSettings.Align := iaLeftBottom
  else if rbRightTop.Checked then
    ImageSettings.Align := iaRightTop
  else if rbRightBottom.Checked then
    ImageSettings.Align := iaRightBottom;
  ImageSettings.Position.X := udX.Position;
  ImageSettings.Position.Y := udY.Position;
  ImageSettings.Scale := tbScale.Position;
  ImageSettings.AlphaBlendValue := tbAlpha.Position;
end;

end.
