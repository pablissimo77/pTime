unit unit_options;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Spin, Menus, ExtCtrls, EditBtn, Grids, Clipbrd, DateUtils, SQLDB,
  unit_database;

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
    cb_StatProject: TComboBox;
    ColorDialogFont: TColorDialog;
    ColorDialogBackground: TColorDialog;
    DateEdit1: TDateEdit;
    ReportGrid: TStringGrid;
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
    procedure ReportGridKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure PopupMenu_Projects_Item_DeleteClick(Sender: TObject);
    procedure PopupMenu_Projects_Item_StartClick(Sender: TObject);
  private
    procedure LoadDayStatistics;
    procedure LoadStatisticsToGrid;
    function SelectedStatisticsProject: string;

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

function TForm_options.SelectedStatisticsProject: string;
begin
  if (cb_StatProject.ItemIndex <= 0) or
    (cb_StatProject.ItemIndex >= cb_StatProject.Items.Count) then
    Result := ''
  else
    Result := cb_StatProject.Items[cb_StatProject.ItemIndex];
end;

procedure TForm_options.LoadDayStatistics;
begin
  try
    AppDatabase.OpenDayStatistics(DateEdit1.Text, SelectedStatisticsProject,
      rg_OrderBy.ItemIndex <> 0);
    LoadStatisticsToGrid;

  except
    ShowMessage('Unable to query the database');
  end;
end;

procedure TForm_options.bt_ViewMonthStatClick(Sender: TObject);
var
  YearMonth: string;
begin
  try
    YearMonth := FormatDateTime('yyyy.mm', DateEdit1.Date);
    AppDatabase.OpenMonthStatistics(YearMonth, SelectedStatisticsProject,
      rg_OrderBy.ItemIndex <> 0);
    LoadStatisticsToGrid;

  except
    ShowMessage('Unable to query the database');
  end;
end;

function FormatDuration(TotalSeconds: Integer): string; forward;

procedure TForm_options.LoadStatisticsToGrid;
var
  Query: TSQLQuery;
  Row: Integer;
begin
  Query := AppDatabase.StatisticsQuery;
  ReportGrid.RowCount := 1;
  ReportGrid.ColCount := 3;
  ReportGrid.Cells[0, 0] := 'Period';
  ReportGrid.Cells[1, 0] := 'Project';
  ReportGrid.Cells[2, 0] := 'Duration';
  Row := 1;
  while not Query.EOF do
  begin
    ReportGrid.RowCount := Row + 1;
    ReportGrid.Cells[0, Row] := Query.FieldByName('Period').AsString;
    ReportGrid.Cells[1, Row] := Query.FieldByName('Project').AsString;
    ReportGrid.Cells[2, Row] :=
      FormatDuration(Query.FieldByName('Duration').AsInteger);
    Inc(Row);
    Query.Next;
  end;
  ReportGrid.ColWidths[0] := 90;
  ReportGrid.ColWidths[2] := 90;
  ReportGrid.ColWidths[1] := ReportGrid.ClientWidth -
    ReportGrid.ColWidths[0] - ReportGrid.ColWidths[2];
end;

function FormatDuration(TotalSeconds: Integer): string;
var
  Hours, Minutes, Seconds: Integer;
begin
  Hours := TotalSeconds div 3600;
  Minutes := (TotalSeconds mod 3600) div 60;
  Seconds := TotalSeconds mod 60;
  Result := Format('%.2d:%.2d:%.2d', [Hours, Minutes, Seconds]);
end;

procedure TForm_options.Button1Click(Sender: TObject);
var
  Lines: TStringList;
  Row, Col: Integer;
  Line: string;
begin
  Lines := TStringList.Create;
  try
    for Row := 0 to ReportGrid.RowCount - 1 do
    begin
      Line := '';
      for Col := 0 to ReportGrid.ColCount - 1 do
      begin
        if Col > 0 then
          Line := Line + #9;
        Line := Line + ReportGrid.Cells[Col, Row];
      end;
      Lines.Add(Line);
    end;
    Clipboard.AsText := Lines.Text;
  finally
    Lines.Free;
  end;
end;

procedure TForm_options.ReportGridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = Ord('C')) and (ssCtrl in Shift) then
    Button1Click(Sender);
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
        AppDatabase.AddProject(NewProjectEdit.Text, lb_Projects.Items.Count);
        LoadProjectsList;
        lb_Projects.ItemIndex := lb_Projects.Items.IndexOf(NewProjectEdit.Text);
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
  AppDatabase.DeleteProject(ProjectName);
  LoadProjectsList;
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

procedure TForm_options.PageControl1Change(Sender: TObject);
begin
  if Visible and (PageControl1.ActivePage = TabSheet_Stat) then
    LoadDayStatistics;
end;

procedure TForm_options.PageControl1Changing(Sender: TObject;
  var AllowChange: Boolean);
begin
  if Visible and PageControl1.CanFocus then
    PageControl1.SetFocus;
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
var
  Settings: TAppSettings;
begin
  try
    Settings.FontName := PanelExample.Font.Name;
    Settings.FontSize := PanelExample.Font.Size;
    Settings.FontColor := PanelExample.Font.Color;
    Settings.FontBold := fsBold in PanelExample.Font.Style;
    Settings.FontItalic := fsItalic in PanelExample.Font.Style;
    Settings.BackgroundColor := PanelExample.Color;
    Settings.InfoWidth := edit_InfoWidth.Value;
    Settings.InfoHeight := edit_InfoHeight.Value;
    Settings.InfoTop := edit_InfoTop.Value;
    Settings.InfoLeft := edit_InfoLeft.Value;
    AppDatabase.SaveSettings(Settings);
  except
    { Keep the previous behavior: settings errors do not terminate the app. }
  end;
end;

procedure TForm_options.LoadOptions;
var
  Settings: TAppSettings;
begin
  try
    if AppDatabase.LoadSettings(Settings) then
    begin
      PanelExample.Font.Name := Settings.FontName;
      PanelExample.Font.Size := Settings.FontSize;
      PanelExample.Font.Color := Settings.FontColor;
      PanelExample.Font.Style := [];
      if Settings.FontBold then
        PanelExample.Font.Style := PanelExample.Font.Style + [fsBold];
      if Settings.FontItalic then
        PanelExample.Font.Style := PanelExample.Font.Style + [fsItalic];
      PanelExample.Color := Settings.BackgroundColor;
      edit_InfoWidth.Value := Settings.InfoWidth;
      edit_InfoHeight.Value := Settings.InfoHeight;
      edit_InfoTop.Value := Settings.InfoTop;
      edit_InfoLeft.Value := Settings.InfoLeft;
    end;
  except
    { Keep the previous behavior: defaults remain in the controls. }
  end;
end;

procedure TForm_options.LoadProjectsList;
begin
  try
    lb_Projects.Items.Clear;
    AppDatabase.LoadProjects(lb_Projects.Items);
    cb_StatProject.Items.BeginUpdate;
    try
      cb_StatProject.Items.Clear;
      cb_StatProject.Items.Add('All projects');
      cb_StatProject.Items.AddStrings(lb_Projects.Items);
      cb_StatProject.ItemIndex := 0;
    finally
      cb_StatProject.Items.EndUpdate;
    end;
  except
    lb_Projects.Items.Clear;
    cb_StatProject.Items.Clear;
    cb_StatProject.Items.Add('All projects');
    cb_StatProject.ItemIndex := 0;
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
