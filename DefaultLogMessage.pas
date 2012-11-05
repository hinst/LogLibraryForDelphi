unit DefaultLogMessage;

interface

uses
  CustomLogMessage;

type
  TDefaultLogMessage = class(TCustomLogMessage)
  public
    constructor Create(const aNumber: integer); reintroduce;
  protected
    fNumber: integer;
    fTag: string;
    fTime: TDateTime;
    fName: string;
    fText: string;
    function GetNumber: integer; override;
    procedure SetNumber(const aNumber: integer); override;
    function GetTag: string; override;
    procedure SetTag(const aTag: string); override;
    function GetTime: TDateTime; override;
    procedure SetTime(const aTime: TDateTime); override;
    function GetName: string; override;
    procedure SetName(const aName: string); override;
    function GetText: string; override;
    procedure SetText(const aText: string); override;
  public
    destructor Destroy; override;
  end;

implementation

constructor TDefaultLogMessage.Create(const aNumber: integer);
begin
  inherited Create;
  Number := aNumber;
  Tag := '';
end;

destructor TDefaultLogMessage.Destroy;
begin
  inherited Destroy;
end;

function TDefaultLogMessage.GetName: string;
begin
  result := fName;
end;

function TDefaultLogMessage.GetNumber: integer;
begin
  result := fNumber;
end;

function TDefaultLogMessage.GetTag: string;
begin
  result := fTag;
end;

function TDefaultLogMessage.GetText: string;
begin
  result := fText;
end;

function TDefaultLogMessage.GetTime: TDateTime;
begin
  result := fTime;
end;

procedure TDefaultLogMessage.SetName(const aName: string);
begin
  fName := aName;
end;

procedure TDefaultLogMessage.SetNumber(const aNumber: integer);
begin
  fNumber := aNumber;
end;

procedure TDefaultLogMessage.SetTag(const aTag: string);
begin
  fTag := aTag;
end;

procedure TDefaultLogMessage.SetText(const aText: string);
begin
  fText := aText;
end;

procedure TDefaultLogMessage.SetTime(const aTime: TDateTime);
begin
  fTime := aTime;
end;

end.
