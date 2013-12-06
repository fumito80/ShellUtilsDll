library ShellUtils;

{$R 'version.res' 'version.rc'}

uses
  Classes,
  Windows,
  NPPlugin,
  Common in 'Common.pas',
  ShellApi;

type
  TMyClass = class(TPlugin)
  private
    browser: IBrowserObject;
  public
    constructor Create( AInstance         : PNPP ;
                        AExtraInfo        : TObject ;
                        const APluginType : string ;
                        AMode             : word ;
                        AParamNames       : TStrings ;
                        AParamValues      : TStrings ;
                        const ASaved      : TNPSavedData ) ; override;
    destructor Destroy; override;
  published
    procedure SetClipboard(const params: array of Variant);
    function GetClipboard(const params: array of Variant): Variant;
    procedure Sleep(const params: array of Variant);
    procedure ExecShell(const params: array of Variant);
  end;

constructor TMyClass.Create( AInstance         : PNPP ;
                             AExtraInfo        : TObject ;
                             const APluginType : string ;
                             AMode             : word ;
                             AParamNames       : TStrings ;
                             AParamValues      : TStrings ;
                             const ASaved      : TNPSavedData );
begin
  inherited;
  browser:= GetBrowserWindowObject;
  //Write2EventLog('FlexKbd', 'Start Shortcuts Remapper', EVENTLOG_INFORMATION_TYPE);
end;

destructor TMyClass.Destroy;
begin
  inherited Destroy;
  //Write2EventLog('FlexKbd', 'Terminated Shortcuts Remapper', EVENTLOG_INFORMATION_TYPE);
end;

procedure TMyClass.SetClipboard(const params: array of Variant);
begin
  gpcStrToClipboard(params[0]);
end;

function TMyClass.GetClipboard(const params: array of Variant): Variant;
begin
  try
    Result:= gfnsStrFromClipboard;
  except
    Result:= '';
  end;
end;

procedure TMyClass.Sleep(const params: array of Variant);
begin
  Windows.Sleep(params[0]);
end;

procedure TMyClass.ExecShell(const params: array of Variant);
var
  prog, url: string;
begin
  prog:= params[0];
  url:= params[1];
  if (prog <> '') then begin
    ShellExecute(0, PChar('open'), PChar(prog), PChar(url), nil, SW_SHOWNORMAL);
  end;
end;

begin
  TMyClass.Register('application/x-shellutils', nil);

end.

