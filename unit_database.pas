unit unit_database;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Graphics, SQLite3Conn, SQLDB, DB;

type
  TAppSettings = record
    FontName: string;
    FontSize: Integer;
    FontColor: Integer;
    FontBold: Boolean;
    FontItalic: Boolean;
    BackgroundColor: Integer;
    InfoWidth: Integer;
    InfoHeight: Integer;
    InfoTop: Integer;
    InfoLeft: Integer;
  end;

  { TAppDatabase }

  TAppDatabase = class
  private
    FConnection: TSQLite3Connection;
    FTransaction: TSQLTransaction;
    FQuery: TSQLQuery;
    FStatisticsQuery: TSQLQuery;
    procedure PrepareWrite;
    procedure FinishWrite;
    procedure FinishRead;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Initialize;
    procedure Close;
    procedure SaveTiming(const ProjectName, Day, StartText, EndText: string;
      StartTime, EndTime: TDateTime; Duration: Integer);
    function LoadSettings(out Settings: TAppSettings): Boolean;
    procedure SaveSettings(const Settings: TAppSettings);
    procedure LoadProjects(AItems: TStrings);
    function ProjectExists(const ProjectName: string): Boolean;
    procedure AddProject(const ProjectName: string; SortOrder: Integer);
    procedure DeleteProject(const ProjectName: string);
    procedure OpenDayStatistics(const Day, ProjectName: string;
      OrderByDuration: Boolean);
    procedure OpenMonthStatistics(const YearMonth, ProjectName: string;
      OrderByDuration: Boolean);
    property StatisticsQuery: TSQLQuery read FStatisticsQuery;
  end;

var
  AppDatabase: TAppDatabase;

implementation

uses
  FileUtil, sqlite3dyn;

constructor TAppDatabase.Create;
begin
  inherited Create;
  FConnection := TSQLite3Connection.Create(nil);
  FTransaction := TSQLTransaction.Create(nil);
  FQuery := TSQLQuery.Create(nil);
  FStatisticsQuery := TSQLQuery.Create(nil);

  FConnection.Transaction := FTransaction;
  FTransaction.Database := FConnection;
  FQuery.Database := FConnection;
  FQuery.Transaction := FTransaction;
  FStatisticsQuery.Database := FConnection;
  FStatisticsQuery.Transaction := FTransaction;
end;

destructor TAppDatabase.Destroy;
begin
  Close;
  FStatisticsQuery.Free;
  FQuery.Free;
  FTransaction.Free;
  FConnection.Free;
  inherited Destroy;
end;

procedure TAppDatabase.Initialize;
begin
  {$IFDEF UNIX}
  {$IFNDEF DARWIN}
  SQLiteDefaultLibrary := ProgramDirectory + 'libsqlite3.so';
  {$ENDIF}
  {$IFDEF DARWIN}
  SQLiteDefaultLibrary := '/usr/lib/libsqlite3.dylib';
  {$ENDIF}
  {$ENDIF}

  {$IFDEF WINDOWS}
  SQLiteDefaultLibrary := ProgramDirectory + 'sqlite3.dll';
  {$ENDIF}

  FConnection.DatabaseName := ProgramDirectory + 'ptime.sqlite3';
  FConnection.Open;

  try
    FTransaction.Active := True;
    FConnection.ExecuteDirect(
      'CREATE TABLE IF NOT EXISTS "timing" (' +
      '"project" TEXT NOT NULL, "day" TEXT NOT NULL, ' +
      '"dt_start" DateTime NOT NULL, "dt_start_str" TEXT NOT NULL, ' +
      '"dt_end" DateTime NOT NULL, "dt_end_str" TEXT NOT NULL, ' +
      '"duration" INTEGER NOT NULL);');
    FConnection.ExecuteDirect(
      'CREATE INDEX IF NOT EXISTS "project_idx" ON "timing" ("project");');
    FConnection.ExecuteDirect(
      'CREATE INDEX IF NOT EXISTS "day_idx" ON "timing" ("day");');
    FConnection.ExecuteDirect(
      'CREATE TABLE IF NOT EXISTS "projects" (' +
      '"id" INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      '"name" TEXT NOT NULL UNIQUE, ' +
      '"sort_order" INTEGER NOT NULL DEFAULT 0);');
    FConnection.ExecuteDirect(
      'CREATE INDEX IF NOT EXISTS "project_name_idx" ON "projects" ("name");');
    FConnection.ExecuteDirect(
      'CREATE TABLE IF NOT EXISTS "settings" (' +
      '"id" INTEGER PRIMARY KEY CHECK ("id" = 1), ' +
      '"font_name" TEXT NOT NULL, "font_size" INTEGER NOT NULL, ' +
      '"font_color" INTEGER NOT NULL, "font_bold" INTEGER NOT NULL DEFAULT 0, ' +
      '"font_italic" INTEGER NOT NULL DEFAULT 0, ' +
      '"background_color" INTEGER NOT NULL, "info_width" INTEGER NOT NULL, ' +
      '"info_height" INTEGER NOT NULL, "info_top" INTEGER NOT NULL, ' +
      '"info_left" INTEGER NOT NULL);');
    FConnection.ExecuteDirect(
      'INSERT OR IGNORE INTO settings (' +
      'id, font_name, font_size, font_color, font_bold, font_italic, ' +
      'background_color, info_width, info_height, info_top, info_left) ' +
      'VALUES (1, ''Verdana'', 8, ' + IntToStr(clRed) + ', 0, 0, ' +
      IntToStr(clYellow) + ', 300, 25, 0, 0);');
    FTransaction.Commit;
  except
    if FTransaction.Active then
      FTransaction.Rollback;
    Close;
    raise;
  end;
end;

procedure TAppDatabase.Close;
begin
  if FStatisticsQuery.Active then
    FStatisticsQuery.Close;
  if FQuery.Active then
    FQuery.Close;
  if FTransaction.Active then
    FTransaction.Rollback;
  if FConnection.Connected then
    FConnection.Close;
end;

procedure TAppDatabase.PrepareWrite;
begin
  if FStatisticsQuery.Active then
    FStatisticsQuery.Close;
  if FQuery.Active then
    FQuery.Close;
  if FTransaction.Active then
    FTransaction.Commit;
  FTransaction.Active := True;
end;

procedure TAppDatabase.FinishWrite;
begin
  FTransaction.Commit;
end;

procedure TAppDatabase.FinishRead;
begin
  if FQuery.Active then
    FQuery.Close;
  if FTransaction.Active then
    FTransaction.Commit;
end;

procedure TAppDatabase.SaveTiming(const ProjectName, Day, StartText,
  EndText: string; StartTime, EndTime: TDateTime; Duration: Integer);
begin
  PrepareWrite;
  try
    FQuery.SQL.Text :=
      'INSERT INTO timing ' +
      '(project, day, dt_start, dt_start_str, dt_end, dt_end_str, duration) ' +
      'VALUES (:project, :day, :dt_start, :dt_start_str, ' +
      ':dt_end, :dt_end_str, :duration)';
    FQuery.Params.ParamByName('project').AsString := ProjectName;
    FQuery.Params.ParamByName('day').AsString := Day;
    FQuery.Params.ParamByName('dt_start').AsDateTime := StartTime;
    FQuery.Params.ParamByName('dt_start_str').AsString := StartText;
    FQuery.Params.ParamByName('dt_end').AsDateTime := EndTime;
    FQuery.Params.ParamByName('dt_end_str').AsString := EndText;
    FQuery.Params.ParamByName('duration').AsInteger := Duration;
    FQuery.ExecSQL;
    FinishWrite;
  except
    if FTransaction.Active then
      FTransaction.Rollback;
    raise;
  end;
end;

function TAppDatabase.LoadSettings(out Settings: TAppSettings): Boolean;
begin
  Result := False;
  PrepareWrite;
  FQuery.SQL.Text :=
    'SELECT font_name, font_size, font_color, font_bold, font_italic, ' +
    'background_color, info_width, info_height, info_top, info_left ' +
    'FROM settings WHERE id=1';
  FQuery.Open;
  if not FQuery.EOF then
  begin
    Settings.FontName := FQuery.FieldByName('font_name').AsString;
    Settings.FontSize := FQuery.FieldByName('font_size').AsInteger;
    Settings.FontColor := FQuery.FieldByName('font_color').AsInteger;
    Settings.FontBold := FQuery.FieldByName('font_bold').AsInteger <> 0;
    Settings.FontItalic := FQuery.FieldByName('font_italic').AsInteger <> 0;
    Settings.BackgroundColor := FQuery.FieldByName('background_color').AsInteger;
    Settings.InfoWidth := FQuery.FieldByName('info_width').AsInteger;
    Settings.InfoHeight := FQuery.FieldByName('info_height').AsInteger;
    Settings.InfoTop := FQuery.FieldByName('info_top').AsInteger;
    Settings.InfoLeft := FQuery.FieldByName('info_left').AsInteger;
    Result := True;
  end;
  FinishRead;
end;

procedure TAppDatabase.SaveSettings(const Settings: TAppSettings);
begin
  PrepareWrite;
  try
    FQuery.SQL.Text :=
      'UPDATE settings SET font_name=:font_name, font_size=:font_size, ' +
      'font_color=:font_color, font_bold=:font_bold, font_italic=:font_italic, ' +
      'background_color=:background_color, info_width=:info_width, ' +
      'info_height=:info_height, info_top=:info_top, info_left=:info_left ' +
      'WHERE id=1';
    FQuery.Params.ParamByName('font_name').AsString := Settings.FontName;
    FQuery.Params.ParamByName('font_size').AsInteger := Settings.FontSize;
    FQuery.Params.ParamByName('font_color').AsInteger := Settings.FontColor;
    FQuery.Params.ParamByName('font_bold').AsInteger := Ord(Settings.FontBold);
    FQuery.Params.ParamByName('font_italic').AsInteger := Ord(Settings.FontItalic);
    FQuery.Params.ParamByName('background_color').AsInteger := Settings.BackgroundColor;
    FQuery.Params.ParamByName('info_width').AsInteger := Settings.InfoWidth;
    FQuery.Params.ParamByName('info_height').AsInteger := Settings.InfoHeight;
    FQuery.Params.ParamByName('info_top').AsInteger := Settings.InfoTop;
    FQuery.Params.ParamByName('info_left').AsInteger := Settings.InfoLeft;
    FQuery.ExecSQL;
    FinishWrite;
  except
    if FTransaction.Active then
      FTransaction.Rollback;
    raise;
  end;
end;

procedure TAppDatabase.LoadProjects(AItems: TStrings);
begin
  AItems.Clear;
  PrepareWrite;
  FQuery.SQL.Text := 'SELECT name FROM projects ORDER BY sort_order, id';
  FQuery.Open;
  while not FQuery.EOF do
  begin
    AItems.Add(FQuery.FieldByName('name').AsString);
    FQuery.Next;
  end;
  FinishRead;
end;

function TAppDatabase.ProjectExists(const ProjectName: string): Boolean;
begin
  PrepareWrite;
  FQuery.SQL.Text := 'SELECT 1 FROM projects WHERE name=:name LIMIT 1';
  FQuery.Params.ParamByName('name').AsString := ProjectName;
  FQuery.Open;
  Result := not FQuery.EOF;
  FinishRead;
end;

procedure TAppDatabase.AddProject(const ProjectName: string; SortOrder: Integer);
begin
  PrepareWrite;
  try
    FQuery.SQL.Text :=
      'INSERT INTO projects (name, sort_order) VALUES (:name, :sort_order)';
    FQuery.Params.ParamByName('name').AsString := ProjectName;
    FQuery.Params.ParamByName('sort_order').AsInteger := SortOrder;
    FQuery.ExecSQL;
    FinishWrite;
  except
    if FTransaction.Active then
      FTransaction.Rollback;
    raise;
  end;
end;

procedure TAppDatabase.DeleteProject(const ProjectName: string);
begin
  PrepareWrite;
  try
    FQuery.SQL.Text := 'DELETE FROM projects WHERE name=:name';
    FQuery.Params.ParamByName('name').AsString := ProjectName;
    FQuery.ExecSQL;
    FinishWrite;
  except
    if FTransaction.Active then
      FTransaction.Rollback;
    raise;
  end;
end;

procedure TAppDatabase.OpenDayStatistics(const Day, ProjectName: string;
  OrderByDuration: Boolean);
begin
  if FStatisticsQuery.Active then
    FStatisticsQuery.Close;
  if FTransaction.Active then
    FTransaction.Commit;
  if OrderByDuration then
    FStatisticsQuery.SQL.Text :=
      'SELECT day AS Period, project AS Project, sum(duration) AS Duration ' +
      'FROM timing WHERE day=:day'
  else
    FStatisticsQuery.SQL.Text :=
      'SELECT day AS Period, project AS Project, sum(duration) AS Duration ' +
      'FROM timing WHERE day=:day';
  if ProjectName <> '' then
    FStatisticsQuery.SQL.Text := FStatisticsQuery.SQL.Text +
      ' AND project=:project_name';
  FStatisticsQuery.SQL.Text := FStatisticsQuery.SQL.Text +
    ' GROUP BY day, project';
  if OrderByDuration then
    FStatisticsQuery.SQL.Text := FStatisticsQuery.SQL.Text +
      ' ORDER BY Duration DESC'
  else
    FStatisticsQuery.SQL.Text := FStatisticsQuery.SQL.Text +
      ' ORDER BY project';
  FStatisticsQuery.Params.ParamByName('day').AsString := Day;
  if ProjectName <> '' then
    FStatisticsQuery.Params.ParamByName('project_name').AsString := ProjectName;
  FStatisticsQuery.Open;
end;

procedure TAppDatabase.OpenMonthStatistics(const YearMonth, ProjectName: string;
  OrderByDuration: Boolean);
begin
  if FStatisticsQuery.Active then
    FStatisticsQuery.Close;
  if FTransaction.Active then
    FTransaction.Commit;
  if OrderByDuration then
    FStatisticsQuery.SQL.Text :=
      'SELECT day AS Period, project AS Project, sum(duration) AS Duration ' +
      'FROM timing WHERE SUBSTR(day,1,7)=:year_month'
  else
    FStatisticsQuery.SQL.Text :=
      'SELECT day AS Period, project AS Project, sum(duration) AS Duration ' +
      'FROM timing WHERE SUBSTR(day,1,7)=:year_month';
  if ProjectName <> '' then
    FStatisticsQuery.SQL.Text := FStatisticsQuery.SQL.Text +
      ' AND project=:project_name';
  FStatisticsQuery.SQL.Text := FStatisticsQuery.SQL.Text +
    ' GROUP BY day, project';
  if OrderByDuration then
    FStatisticsQuery.SQL.Text := FStatisticsQuery.SQL.Text +
      ' ORDER BY Duration DESC'
  else
    FStatisticsQuery.SQL.Text := FStatisticsQuery.SQL.Text +
      ' ORDER BY Period, project';
  FStatisticsQuery.Params.ParamByName('year_month').AsString := YearMonth;
  if ProjectName <> '' then
    FStatisticsQuery.Params.ParamByName('project_name').AsString := ProjectName;
  FStatisticsQuery.Open;
end;

initialization
  AppDatabase := TAppDatabase.Create;

finalization
  AppDatabase.Free;

end.
