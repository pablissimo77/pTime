unit unit_single_instance;

{$mode objfpc}{$H+}

interface

function AcquireSingleInstance: Boolean;
procedure ReleaseSingleInstance;

implementation

uses
  SysUtils
  {$IFDEF WINDOWS}
  , Windows
  {$ENDIF}
  {$IFDEF UNIX}
  , BaseUnix
  {$ENDIF}
  ;

{$IFDEF WINDOWS}
var
  InstanceMutex: THandle = 0;
{$ENDIF}

{$IFDEF UNIX}
var
  InstanceLockFile: cint = -1;

function PosixFlock(FileDescriptor, Operation: cint): cint; cdecl;
  external 'c' name 'flock';

const
  LockExclusive = 2;
  LockNonBlocking = 4;
{$ENDIF}

function AcquireSingleInstance: Boolean;
{$IFDEF UNIX}
var
  LockPath: string;
{$ENDIF}
begin
  Result := False;

  {$IFDEF WINDOWS}
  InstanceMutex := CreateMutex(nil, True, 'pTime_SingleInstance');
  if InstanceMutex = 0 then
    Exit;

  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    CloseHandle(InstanceMutex);
    InstanceMutex := 0;
    Exit;
  end;

  Result := True;
  {$ENDIF}

  {$IFDEF UNIX}
  LockPath := IncludeTrailingPathDelimiter(
    ExtractFilePath(ExpandFileName(ParamStr(0)))) + 'ptime.lock';
  InstanceLockFile := fpOpen(PChar(LockPath), O_RDWR or O_CREAT, &600);
  if InstanceLockFile < 0 then
    Exit;

  if PosixFlock(InstanceLockFile, LockExclusive or LockNonBlocking) <> 0 then
  begin
    fpClose(InstanceLockFile);
    InstanceLockFile := -1;
    Exit;
  end;

  Result := True;
  {$ENDIF}
end;

procedure ReleaseSingleInstance;
begin
  {$IFDEF WINDOWS}
  if InstanceMutex <> 0 then
  begin
    CloseHandle(InstanceMutex);
    InstanceMutex := 0;
  end;
  {$ENDIF}

  {$IFDEF UNIX}
  if InstanceLockFile >= 0 then
  begin
    fpClose(InstanceLockFile);
    InstanceLockFile := -1;
  end;
  {$ENDIF}
end;

finalization
  ReleaseSingleInstance;

end.
