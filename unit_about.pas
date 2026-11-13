unit unit_about;

{$MODE Delphi}

interface

uses LCLIntf, LCLType, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  TForm_about = class(TForm)
    Panel_Main: TPanel;
    ProgramIcon: TImage;
    ProductName: TLabel;
    Copyright: TLabel;
    OKButton: TButton;
    Label_Mail: TLabel;
    procedure Label_MailClick(Sender: TObject);
    procedure Label_MailMouseEnter(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form_about: TForm_about;

implementation

{$R *.lfm}

procedure TForm_about.Label_MailClick(Sender: TObject);
var
  p: PChar;
  s: string;
begin
  s := 'mailto:pablissimo77@gmail.com?Subject=' + PChar(Application.MainForm.Caption);
  p := PChar(s);
  OpenDocument(p); { *Converted from ShellExecute* }
end;

procedure TForm_about.Label_MailMouseEnter(Sender: TObject);
begin
  label_Mail.Cursor := crHandPoint;
end;

end.
