unit CustomLogMessage;

interface

uses
  UEnhancedObject;

type
  TCustomLogMessage = class(TEnhancedObject)
  protected
    function GetNumber: integer; virtual; abstract;
    procedure SetNumber(const aNumber: integer); virtual; abstract;
    function GetTag: string; virtual; abstract;
    procedure SetTag(const aTag: string); virtual; abstract;
    function GetTime: TDateTime; virtual; abstract;
    procedure SetTime(const aTime: TDateTime); virtual; abstract;
    function GetName: string; virtual; abstract;
    procedure SetName(const aName: string); virtual; abstract;
    function GetText: string; virtual; abstract;
    procedure SetText(const aText: string); virtual; abstract;
  public
    property Number: integer read GetNumber write SetNumber;
    property Time: TDateTime read GetTime write SetTime;
    property Tag: string read GetTag write SetTag;
    property Name: string read GetName write SetName;
    property Text: string read GetText write SetText;
  end;

implementation

end.
