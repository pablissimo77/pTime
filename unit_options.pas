unit unit_options;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Spin, Menus, ExtCtrls, EditBtn, DBGrids, Clipbrd, DateUtils, SQLDB, DB,
  FileUtil;

type

  { TForm_options }

  TForm_options = class(TForm)
    btChangeColorBackground: TButton;
    btChangeFontColor: TButton;
    btChangeFont: TButton;
    btTest: TButton;
    bt_SetDefault: TButton;
    bt_ApplySizePosition: TButton;
    bt_ViewDayStat: TButton;
    bt_ViewMonthStat: TButton;
    Button1: TButton;
    ColorDialogFont: TColorDialog;
    ColorDialogBackground: TColorDialog;
    DataSource1: TDataSource;
    DateEdit1: TDateEdit;
    DBGrid1: TDBGrid;
    edit_InfoHeight: TSpinEdit;
    edit_InfoLeft: TSpinEdit;
    edit_InfoTop: TSpinEdit;
    edit_InfoWidth: TSpinEdit;
    FontDialog: TFontDialog;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    PanelExample: TPanel;
    PopupMenu_Projects_Item_Start: TMenuItem;
    PopupMenu_Projects_Item_Delete: TMenuItem;
    NewProjectEdit: TEdit;
    PopupMenu_Projects: TPopupMenu;
    lb_Projects: TListBox;
    PageControl1: TPageControl;
    rg_OrderBy: TRadioGroup;
    SQLQuery_stat: TSQLQuery;
    TabSheet_Projects: TTabSheet;
    TabSheet_Options: TTabSheet;
    TabSheet_Stat: TTabSheet;

    procedure btChangeColorBackgroundClick(Sender: TObject);
    procedure btChangeFontClick(Sender: TObject);
    procedure btChangeFontColorClick(Sender: TObject);
    procedure btTestClick(Sender: TObject);
    procedure bt_ApplySizePositionClick(Sender: TObject);
    procedure bt_SetDefaultClick(Sender: TObject);
    procedure bt_ViewDayStatClick(Sender: TObject);
    procedure bt_ViewMonthStatClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure edit_InfoHeightChange(Sender: TObject);
    procedure edit_InfoLeftChange(Sender: TObject);
    procedure edit_InfoTopChange(Sender: TObject);
    procedure edit_InfoWidthChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure NewProjectEditChange(Sender: TObject);


    procedure NewProjectEditKeyPress(Sender: TObject; var Key: char);

    procedure lb_ProjectsDblClick(Sender: TObject);
    procedure PageControl1Changing(Sender: TObject; var AllowChange: Boolean);
    procedure PageControl1Change(Sender: TObject);
    procedure PopupMenu_Projects_Item_DeleteClick(Sender: TObject);
    procedure PopupMenu_Projects_Item_StartClick(Sender: TObject);
  private
    procedure LoadDayStatistics;
    procedure LoadDayStatisticsAsync(Data: PtrInt);

  public
    function NewProjectExists(NewProjectName: string): boolean;
    procedure SaveOptions;
    procedure LoadOptions;
    procedure LoadProjectsList;
    procedure ApplyOptions;


  end;

function GetWorkingTime: string;


var
  Form_options: TForm_options;
  Clipboard: TClipboard;



implementation

{$R *.lfm}

uses unit_info;
  { TForm_options }

procedure TForm_options.ApplyOptions;
begin
  Form_info.Height := Form_options.edit_InfoHeight.Value;
  Form_info.Width := Form_options.edit_InfoWidth.Value;
  Form_info.Top := Form_options.edit_InfoTop.Value;
  Form_info.Left := Form_options.edit_InfoLeft.Value;
  Form_info.CreatePopMenu;
end;

procedure TForm_options.edit_InfoHeightChange(Sender: TObject);
begin
  //UseOptions;
end;

procedure TForm_options.edit_InfoLeftChange(Sender: TObject);
begin
  //UseOptions;
end;

procedure TForm_options.edit_InfoTopChange(Sender: TObject);
begin
  //UseOptions;
end;

procedure TForm_options.edit_InfoWidthChange(Sender: TObject);
begin
  //UseOptions;
end;

procedure TForm_options.FormCreate(Sender: TObject);
begin
  LoadOptions;
  LoadProjectsList;

  Clipboard := TClipboard.Create();


  //DateTimePicker1.TimeFormat:=;
end;

procedure TForm_options.NewProjectEditChange(Sender: TObject);
begin
  //  { #todo : Проверка на длинну и сиволы в названии проекта }
end;



procedure TForm_options.btChangeColorBackgroundClick(Sender: TObject);
begin
  ColorDialogBackground.Color := PanelExample.Color;
  if ColorDialogBackground.Execute then
  begin

    PanelExample.Color := ColorDialogBackground.Color;
    ApplyOptions;

  end;
end;

procedure TForm_options.btChangeFontClick(Sender: TObject);
begin
  FontDialog.Font := PanelExample.Font;
  if FontDialog.Execute then
  begin

    PanelExample.Font := FontDialog.Font;
    ApplyOptions;

  end;
end;

procedure TForm_options.btChangeFontColorClick(Sender: TObject);
begin
  ColorDialogFont.Color := PanelExample.Font.Color;
  if ColorDialogFont.Execute then
  begin

    PanelExample.Font.Color := ColorDialogFont.Color;
    ApplyOptions;
  end;
end;


procedure TForm_options.btTestClick(Sender: TObject);
begin

  //SQLite3Connection1.Password := txtPass.Text; // The current password

  //// Try to perform query
  //try
  //  SQLite3Connection1.Connected := True;

  //  // Set SQL text to select everything from the DATA table
  //  SQLQuery1.SQL.Clear;
  //  SQLQuery1.SQL.Text := 'Select * from DATA';
  //  SQLQuery1.Open;

  //  // Allow the DBGrid to view the results of our query
  //  DataSource1.DataSet := SQLQuery1;
  //  DBGrid1.DataSource := DataSource1;
  //  DBGrid1.AutoFillColumns := true;

  //except
  //  ShowMessage('Unable to query the database');
  //end;

end;

procedure TForm_options.bt_ApplySizePositionClick(Sender: TObject);
begin
  ApplyOptions;
end;

procedure TForm_options.bt_SetDefaultClick(Sender: TObject);
begin
  edit_InfoWidth.Value := 300;
  edit_InfoHeight.Value := 25;
  edit_InfoTop.Value := 0;
  edit_InfoLeft.Value := 0;
  ApplyOptions;
end;

procedure TForm_options.bt_ViewDayStatClick(Sender: TObject);
begin
  LoadDayStatistics;
end;

procedure TForm_options.LoadDayStatistics;
begin
  try
    if SQLQuery_stat.Active then
      SQLQuery_stat.Close;

    if rg_OrderBy.ItemIndex = 0 then
      SQLQuery_stat.SQL.Text :=
        'Select project as Project, sum(duration) as Duration from timing group by project having day=:day order by project'
    else
      SQLQuery_stat.SQL.Text :=
        'Select project as Project, sum(duration) as Duration from timing group by project having day=:day order by Duration desc';

    SQLQuery_stat.Params.ParamByName('day').AsString := DateEdit1.Text;
    SQLQuery_stat.Open;
    SQLQuery_stat.Refresh;

    DataSource1.DataSet := SQLQuery_stat;
    DBGrid1.DataSource := DataSource1;

  except
    ShowMessage('Unable to query the database');
  end;
end;

procedure TForm_options.bt_ViewMonthStatClick(Sender: TObject);
var
  YearMonth: string;
begin
  try
    if SQLQuery_stat.Active then
      SQLQuery_stat.Close;
    YearMonth := FormatDateTime('yyyy.mm', DateEdit1.Date);
    if rg_OrderBy.ItemIndex = 0 then
      SQLQuery_stat.SQL.Text :=
        'select project as Project, sum(duration) as Duration ' +
        'from timing where SUBSTR(day,1,7)=:year_month ' +
        'group by project order by project'
    else
      SQLQuery_stat.SQL.Text :=
        'select project as Project, sum(duration) as Duration ' +
        'from timing where SUBSTR(day,1,7)=:year_month ' +
        'group by project order by Duration desc';

    SQLQuery_stat.Params.ParamByName('year_month').AsString := YearMonth;
    SQLQuery_stat.Open;
    SQLQuery_stat.Refresh;

    DataSource1.DataSet := SQLQuery_stat;
    DBGrid1.DataSource := DataSource1;

  except
    ShowMessage('Unable to query the database');
  end;
end;

procedure TForm_options.Button1Click(Sender: TObject);
var
  sl: TStringList;
  iCol: integer;
  s, Delim: string;
begin
  sl := TStringList.Create;
  Delim := CHR(9);

  s := '';
  for iCol := 0 to DBGrid1.Columns.Count - 1 do
     S := S + DBGrid1.Columns[iCol].FieldName + Delim;
  sl.Append(s.Trim());

  DBGrid1.DataSource.DataSet.First;

  while not DBGrid1.DataSource.DataSet.EOF do
  begin
    s := '';
    for iCol := 0 to DBGrid1.Columns.Count - 1 do
    begin
      S := S + DBGrid1.Columns[iCol].Field.AsString + Delim;
    end;
    sl.Append(s.Trim());
    DBGrid1.DataSource.DataSet.Next();
  end;
  Clipboard.AsText := sl.Text;
  sl.Free;
  DBGrid1.DataSource.DataSet.First;
end;




procedure TForm_options.NewProjectEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    NewProjectEdit.Text := trim(NewProjectEdit.Text);
    if NewProjectEdit.Text <> '' then
    begin
      if not (NewProjectExists(NewProjectEdit.Text)) then
      begin
        Form_info.SQLQuery1.Close;
        Form_info.SQLTransaction.Active := True;
        Form_info.SQLQuery1.SQL.Text :=
          'INSERT INTO projects (name, sort_order) ' +
          'VALUES (:name, :sort_order)';
        Form_info.SQLQuery1.Params.ParamByName('name').AsString :=
          NewProjectEdit.Text;
        Form_info.SQLQuery1.Params.ParamByName('sort_order').AsInteger :=
          lb_Projects.Items.Count;
        Form_info.SQLQuery1.ExecSQL;
        Form_info.SQLTransaction.Commit;
        lb_Projects.Items.Add(NewProjectEdit.Text);
        lb_Projects.ItemIndex := lb_Projects.Items.Count - 1;
        NewProjectEdit.Text := '';
        Form_info.CreatePopMenu;
      end
      else
        MessageDlg('Error', 'Project already exists', mtError, [mbOK], 0);
    end;
  end;
end;



procedure TForm_options.lb_ProjectsDblClick(Sender: TObject);
begin
  if lb_Projects.ItemIndex < 0 then ShowMessage('Choose project!')
  else
  begin
    Form_options.ActiveControl := nil;
    Form_options.Hide;
    Form_info.StartProject(lb_Projects.Items[lb_Projects.ItemIndex]);
  end;
end;

procedure TForm_options.PopupMenu_Projects_Item_DeleteClick(Sender: TObject);
var
  ProjectName: string;
begin
  if lb_Projects.ItemIndex < 0 then
    Exit;
  ProjectName := lb_Projects.Items[lb_Projects.ItemIndex];
  Form_info.SQLQuery1.Close;
  Form_info.SQLTransaction.Active := True;
  Form_info.SQLQuery1.SQL.Text := 'DELETE FROM projects WHERE name=:name';
  Form_info.SQLQuery1.Params.ParamByName('name').AsString := ProjectName;
  Form_info.SQLQuery1.ExecSQL;
  Form_info.SQLTransaction.Commit;
  lb_Projects.DeleteSelected;
  Form_info.CreatePopMenu;
end;

procedure TForm_options.PopupMenu_Projects_Item_StartClick(Sender: TObject);
begin
  if lb_Projects.ItemIndex < 0 then
  begin
    ShowMessage('Choose project!');
  end
  else
  begin
    Form_options.ActiveControl := nil;
    Form_options.Hide;
    Form_info.StartProject(lb_Projects.Items[lb_Projects.ItemIndex]);
  end;
  ;
end;

procedure TForm_options.PageControl1Changing(Sender: TObject;
  var AllowChange: Boolean);
begin
  Form_options.ActiveControl := nil;
end;

procedure TForm_options.PageControl1Change(Sender: TObject);
begin
  if Visible and (PageControl1.ActivePage = TabSheet_Stat) then
    Application.QueueAsyncCall(@LoadDayStatisticsAsync, 0);
end;

procedure TForm_options.LoadDayStatisticsAsync(Data: PtrInt);
begin
  if Visible and (PageControl1.ActivePage = TabSheet_Stat) then
    LoadDayStatistics;
end;

function TForm_options.NewProjectExists(NewProjectName: string): boolean;
var
  k: integer;
begin
  Result := False;
  for k := 0 to lb_Projects.Items.Count - 1 do
  begin
    if NewProjectName = lb_Projects.Items[k] then Result := True;
  end;
end;



procedure TForm_options.SaveOptions;
begin
  try
    Form_info.SQLQuery1.Close;
    Form_info.SQLTransaction.Active := True;
    Form_info.SQLQuery1.SQL.Text :=
      'UPDATE settings SET font_name=:font_name, font_size=:font_size, ' +
      'font_color=:font_color, font_bold=:font_bold, font_italic=:font_italic, ' +
      'background_color=:background_color, info_width=:info_width, ' +
      'info_height=:info_height, info_top=:info_top, info_left=:info_left ' +
      'WHERE id=1';
    Form_info.SQLQuery1.Params.ParamByName('font_name').AsString := PanelExample.Font.Name;
    Form_info.SQLQuery1.Params.ParamByName('font_size').AsInteger := PanelExample.Font.Size;
    Form_info.SQLQuery1.Params.ParamByName('font_color').AsInteger := PanelExample.Font.Color;
    Form_info.SQLQuery1.Params.ParamByName('font_bold').AsInteger := Ord(fsBold in PanelExample.Font.Style);
    Form_info.SQLQuery1.Params.ParamByName('font_italic').AsInteger := Ord(fsItalic in PanelExample.Font.Style);
    Form_info.SQLQuery1.Params.ParamByName('background_color').AsInteger := PanelExample.Color;
    Form_info.SQLQuery1.Params.ParamByName('info_width').AsInteger := edit_InfoWidth.Value;
    Form_info.SQLQuery1.Params.ParamByName('info_height').AsInteger := edit_InfoHeight.Value;
    Form_info.SQLQuery1.Params.ParamByName('info_top').AsInteger := edit_InfoTop.Value;
    Form_info.SQLQuery1.Params.ParamByName('info_left').AsInteger := edit_InfoLeft.Value;
    Form_info.SQLQuery1.ExecSQL;
    Form_info.SQLTransaction.Commit;
  except
    if Form_info.SQLTransaction.Active then
      Form_info.SQLTransaction.Rollback;
  end;
end;

procedure TForm_options.LoadOptions;
begin
  try
    Form_info.SQLQuery1.Close;
    Form_info.SQLQuery1.SQL.Text :=
      'SELECT font_name, font_size, font_color, font_bold, font_italic, ' +
      'background_color, info_width, info_height, info_top, info_left ' +
      'FROM settings WHERE id=1';
    Form_info.SQLQuery1.Open;
    if not Form_info.SQLQuery1.EOF then
    begin
      PanelExample.Font.Name := Form_info.SQLQuery1.FieldByName('font_name').AsString;
      PanelExample.Font.Size := Form_info.SQLQuery1.FieldByName('font_size').AsInteger;
      PanelExample.Font.Color := Form_info.SQLQuery1.FieldByName('font_color').AsInteger;
      PanelExample.Font.Style := [];
      if Form_info.SQLQuery1.FieldByName('font_bold').AsInteger <> 0 then
        PanelExample.Font.Style := PanelExample.Font.Style + [fsBold];
      if Form_info.SQLQuery1.FieldByName('font_italic').AsInteger <> 0 then
        PanelExample.Font.Style := PanelExample.Font.Style + [fsItalic];
      PanelExample.Color := Form_info.SQLQuery1.FieldByName('background_color').AsInteger;
      edit_InfoWidth.Value := Form_info.SQLQuery1.FieldByName('info_width').AsInteger;
      edit_InfoHeight.Value := Form_info.SQLQuery1.FieldByName('info_height').AsInteger;
      edit_InfoTop.Value := Form_info.SQLQuery1.FieldByName('info_top').AsInteger;
      edit_InfoLeft.Value := Form_info.SQLQuery1.FieldByName('info_left').AsInteger;
    end;
    Form_info.SQLQuery1.Close;
  except
    Form_info.SQLQuery1.Close;
  end;
end;

procedure TForm_options.LoadProjectsList;
begin
  try
    lb_Projects.Items.Clear;
    Form_info.SQLQuery1.Close;
    Form_info.SQLQuery1.SQL.Text :=
      'SELECT name FROM projects ORDER BY sort_order, id';
    Form_info.SQLQuery1.Open;
    while not Form_info.SQLQuery1.EOF do
    begin
      lb_Projects.Items.Add(Form_info.SQLQuery1.FieldByName('name').AsString);
      Form_info.SQLQuery1.Next;
    end
    ;
    Form_info.SQLQuery1.Close;
  except
    Form_info.SQLQuery1.Close;
    lb_Projects.Items.Clear;
  end;
end;




function GetWorkingTime: string;
var
  seconds: integer;
  H, M, S: integer;
  sH, sM, sS: string;
begin

  Result := '00:00:00';
  if DateTime_End > DateTime_Begin then
  begin

    seconds := SecondsBetween(DateTime_End, DateTime_Begin);

    H := seconds div (60 * 60);
    seconds := seconds - (H * 60 * 60);
    M := seconds div (60);
    seconds := seconds - (M * 60);
    S := seconds;

    sH := IntToStr(H);
    sM := IntToStr(M);
    sS := IntToStr(S);
    if length(sH) = 1 then sH := '0' + sH;
    if length(sM) = 1 then sM := '0' + sM;
    if length(sS) = 1 then sS := '0' + sS;
    Result := sH + ':' + sM + ':' + sS;

  end;

end;



end.
