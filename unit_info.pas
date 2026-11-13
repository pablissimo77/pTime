unit unit_info;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Menus, unit_options, DateUtils, unit_about, SQLite3Conn, SQLDB, FileUtil;

const

  Caption_Pause = 'PAUSE';
  Caption_Options = 'Options';
  Caption_Exit = 'Exit';
  Caption_About = 'About...';
  Project_Pause = Caption_Pause;
  DateFormatChars = 'yyyy"."mm"."dd';
  DateFormatCharsISO = 'yyyy"-"mm"-"dd"T"hh":"mm":"ss';

type

  { TForm_info }

  TForm_info = class(TForm)
    InformPanel: TPanel;
    PopupMenu_info: TPopupMenu;
    SQLite3Connection: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLTransaction: TSQLTransaction;
    Timer1000: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure FormShow(Sender: TObject);
    procedure Timer1000Timer(Sender: TObject);

  private

  public
    //procedure ShowTrayIcon;
    procedure MenuItemInfoOnClick(Sender: TObject);
    procedure CreatePopMenu;
    procedure StartProject(ProjectName: string);
    procedure InitSQLiteDatabase;
    procedure SaveProjectInfo;


  end;

var
  Form_info: TForm_info;
  MouseIsDown: boolean;
  PX, PY: integer;
  CurrentProjectName: string;
  DateTime_Begin: TDateTime;
  DateTime_End: TDateTime;

implementation

{$R *.lfm}




{ TForm_info }

//procedure TForm_info.ShowTrayIcon;
//var
//ico_file_path: string;
//begin
//ico_file_path := ProgramDirectory + PathDelim + 'ptiming.ico';
//SystrayIcon.Icon.LoadFromFile(ico_file_path);
//SystrayIcon.Hint := Form_options.Caption;
//Form_info.CreatePopMenu;
//SystrayIcon.Show;
//end;

procedure TForm_info.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  if Button = mbLeft then
  begin
    MouseIsDown := True;
    PX := X;
    PY := Y;
  end;
end;

procedure TForm_info.InitSQLiteDatabase;
begin
  {$IFDEF UNIX}
  // Linux
  {$IFNDEF DARWIN}
  SQLiteLibraryName := ProgramDirectory+'libsqlite3.so';
  //SQLiteLibraryName := '/usr/lib/libsqlite3.so';
  {$ENDIF}
  {$IFDEF DARWIN}
    SQLiteLibraryName := '/usr/lib/libsqlite3.dylib';
  {$ENDIF}
  {$ENDIF}

  {$IFDEF WINDOWS}
  // Windows
  SQLiteLibraryName := ProgramDirectory+'sqlite3.dll';
  {$ENDIF}

  SQLite3Connection.DatabaseName := ProgramDirectory + 'ptime.sqlite3';

  try
    SQLite3Connection.Open;
    SQLTransaction.Active := True;

    SQLite3Connection.ExecuteDirect(
      'CREATE TABLE IF NOT EXISTS "timing" (' +
      '"project" TEXT NOT NULL, "day" TEXT NOT NULL, ' +
      '"dt_start" DateTime NOT NULL, "dt_start_str" TEXT NOT NULL, ' +
      '"dt_end" DateTime NOT NULL, "dt_end_str" TEXT NOT NULL, ' +
      '"duration" INTEGER NOT NULL);');
    SQLite3Connection.ExecuteDirect(
      'CREATE INDEX IF NOT EXISTS "project_idx" ON "timing" ("project");');
    SQLite3Connection.ExecuteDirect(
      'CREATE INDEX IF NOT EXISTS "day_idx" ON "timing" ("day");');
    SQLite3Connection.ExecuteDirect(
      'CREATE TABLE IF NOT EXISTS "projects" (' +
      '"id" INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      '"name" TEXT NOT NULL UNIQUE, ' +
      '"sort_order" INTEGER NOT NULL DEFAULT 0);');
    SQLite3Connection.ExecuteDirect(
      'CREATE INDEX IF NOT EXISTS "project_name_idx" ON "projects" ("name");');
    SQLite3Connection.ExecuteDirect(
      'CREATE TABLE IF NOT EXISTS "settings" (' +
      '"id" INTEGER PRIMARY KEY CHECK ("id" = 1), ' +
      '"font_name" TEXT NOT NULL, "font_size" INTEGER NOT NULL, ' +
      '"font_color" INTEGER NOT NULL, "font_bold" INTEGER NOT NULL DEFAULT 0, ' +
      '"font_italic" INTEGER NOT NULL DEFAULT 0, ' +
      '"background_color" INTEGER NOT NULL, "info_width" INTEGER NOT NULL, ' +
      '"info_height" INTEGER NOT NULL, "info_top" INTEGER NOT NULL, ' +
      '"info_left" INTEGER NOT NULL);');
    SQLite3Connection.ExecuteDirect(
      'INSERT OR IGNORE INTO settings (' +
      'id, font_name, font_size, font_color, font_bold, font_italic, ' +
      'background_color, info_width, info_height, info_top, info_left) ' +
      'VALUES (1, ''Verdana'', 8, ' + IntToStr(clRed) + ', 0, 0, ' +
      IntToStr(clYellow) + ', 300, 25, 0, 0);');

    SQLQuery1.Close;
    SQLTransaction.Commit;
  except
    if SQLTransaction.Active then
      SQLTransaction.Rollback;
    ShowMessage('Unable to initialize SQLite database');
  end;

end;

procedure TForm_info.SaveProjectInfo;
begin
  try
    SQLite3Connection.Open;
    SQLTransaction.Active := True;

    SQLQuery1.SQL.Text :=
      'Insert into timing (project,day,dt_start,dt_start_str,dt_end,dt_end_str,duration) ' +
      'values (:project,:day,:dt_start,:dt_start_str,:dt_end,:dt_end_str,:duration)';
    SQLQuery1.Params.ParamByName('project').AsString :=
      CurrentProjectName;
    SQLQuery1.Params.ParamByName('dt_start').AsDateTime := DateTime_Begin;
    SQLQuery1.Params.ParamByName('day').AsString :=
      FormatDateTime(DateFormatChars, DateTime_Begin);
    SQLQuery1.Params.ParamByName('dt_start_str').AsString :=
      FormatDateTime(DateFormatCharsISO, DateTime_Begin);
    SQLQuery1.Params.ParamByName('dt_end').AsDateTime := DateTime_End;
    SQLQuery1.Params.ParamByName('dt_end_str').AsString :=
      FormatDateTime(DateFormatCharsISO, DateTime_End);
    ;
    SQLQuery1.Params.ParamByName('duration').AsInteger :=
      SecondsBetween(DateTime_End, DateTime_Begin);
    SQLQuery1.ExecSQL;
    SQLTransaction.Commit;
  except
    MessageDlg('Error', 'Erro on insert data for ' + CurrentProjectName,
      mtError, [mbOK], 0);
  end;

end;

procedure TForm_info.FormCreate(Sender: TObject);
begin
  InitSQLiteDatabase;
  DateTime_Begin := Now;
  DateTime_End := Now;
  CurrentProjectName := Project_Pause;
end;

procedure TForm_info.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Form_options.SaveOptions;
  SaveProjectInfo;
  SQLite3Connection.Open;
end;

procedure TForm_info.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
begin
  if MouseIsDown then
  begin
    SetBounds(Left + (X - PX), Top + (Y - PY), Width, Height);
  end;
end;

procedure TForm_info.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  MouseIsDown := False;
  Form_options.edit_InfoLeft.Value := Form_info.Left;
  Form_options.edit_InfoTop.Value := Form_info.Top;
end;

procedure TForm_info.FormShow(Sender: TObject);
begin
  InformPanel.Font := Form_options.PanelExample.Font;
  InformPanel.Color := Form_options.PanelExample.Color;
  Form_info.Width := Form_options.edit_InfoWidth.Value;
  Form_info.Height := Form_options.edit_InfoHeight.Value;
  Form_info.Top := Form_options.edit_InfoTop.Value;
  Form_info.Left := Form_options.edit_InfoLeft.Value;
  CreatePopMenu;

  //ShowMEssage('FormShow');

end;

procedure TForm_info.Timer1000Timer(Sender: TObject);
var
  i: integer;
begin
  DateTime_End := Now;
  InformPanel.Caption := CurrentProjectName + ' [' + GetWorkingTime + ']';

  if FormatDateTime('hhnnss', Now) = '235959' then
    for i := 0 to PopupMenu_info.Items.Count - 1 do
      if PopupMenu_info.Items[i].Tag = 1 then
        PopupMenu_info.Items[i].Click;
  if FormatDateTime('hhnnss', Now) = '000000' then
    for i := 0 to PopupMenu_info.Items.Count - 1 do
      if PopupMenu_info.Items[i].Tag = 1 then
        PopupMenu_info.Items[i].Click;

end;

procedure TForm_info.CreatePopMenu;
var
  item: TMenuItem;
  i: integer;
begin

  PopupMenu_info.Items.Clear;

  // PAUSE
  item := TMenuItem.Create(PopupMenu_info);
  item.Caption := Caption_Pause;
  item.Tag := 1;
  item.OnClick := @MenuItemInfoOnClick;
  PopupMenu_info.Items.Add(item);

  // ------
  item := TMenuItem.Create(InformPanel);
  item.Caption := '-';
  item.Tag := -1;
  PopupMenu_info.Items.Add(item);

  for i := 0 to Form_options.lb_Projects.Items.Count - 1 do
  begin
    item := TMenuItem.Create(PopupMenu_info);
    item.Caption := Form_options.lb_Projects.Items[i];
    item.OnClick := @MenuItemInfoOnClick;
    item.Tag := 1;
    PopupMenu_info.Items.Add(item);
  end;

  // ------
  item := TMenuItem.Create(InformPanel);
  item.Caption := '-';
  item.Tag := -1;
  PopupMenu_info.Items.Add(item);


  // Options
  item := TMenuItem.Create(PopupMenu_info);
  item.Caption := Caption_Options;
  item.Tag := -1;
  item.OnClick := @MenuItemInfoOnClick;
  PopupMenu_info.Items.Add(item);

  // About
  item := TMenuItem.Create(InformPanel);
  item.Caption := Caption_About;
  item.Tag := -1;
  item.OnClick := @MenuItemInfoOnClick;
  PopupMenu_info.Items.Add(item);


  // Exit
  item := TMenuItem.Create(InformPanel);
  item.Caption := Caption_Exit;
  item.Tag := -1;
  item.OnClick := @MenuItemInfoOnClick;
  PopupMenu_info.Items.Add(item);

end;

procedure TForm_info.StartProject(ProjectName: string);
begin

  SaveProjectInfo;

  CurrentProjectName := ProjectName;

  DateTime_Begin := now;
  DateTime_End := now;
  InformPanel.Caption := CurrentProjectName + ' [' + GetWorkingTime + ']';

end;

procedure TForm_info.MenuItemInfoOnClick(Sender: TObject);
var
  mi: TMenuItem;
begin

  mi := Sender as TMenuItem;

  case mi.Caption of
    Caption_Options: begin
      Form_options.PageControl1.PageIndex := 1;
      Form_options.ActiveControl := Form_options.btChangeColorBackground;
      Form_options.Show;
    end;
    Caption_Exit: Form_info.Close;
    Caption_About: Form_about.ShowModal;
    Caption_Pause: begin
      StartProject(Project_Pause);
    end;
    else
    begin
      StartProject(mi.Caption);
    end;

  end;

end;



end.
