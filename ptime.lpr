program ptime;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Dialogs, datetimectrls, unit_options, unit_info, unit_about,
  unit_single_instance
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  if not AcquireSingleInstance then
  begin
    ShowMessage('pTime is already running.');
    Halt(1);
  end;

  try
    Application.CreateForm(TForm_info, Form_info);
    Application.CreateForm(TForm_options, Form_options);
    Application.CreateForm(TForm_about, Form_about);
    //Form_main.ShowTrayIcon;
    //Form_info.Show;
    Application.Run;
  finally
    ReleaseSingleInstance;
  end;

end.

