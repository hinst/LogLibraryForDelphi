unit PlainLogTextFormat;

interface

uses
  SysUtils,
  StrUtils,

  UEnhancedObject,

  CustomLogMessage,
  CustomLogTextFormat;

type
  // EHNANCED
  TPlainLogTextFormat = class(TCustomLogTextFormat)
  protected
    FFormatString: string;
    FDateFormat: string;
    FTimeFormat: string;
    procedure PutDateTime(var s: string; const aMessage: TCustomLogMessage;
      const aReplaceWord, aFormat: string);
    procedure PutThis(var s: string; const aReplaceWord, aThis: string);
  public const
    DATE_HERE = '%DATE%';
    TIME_HERE = '%TIME%';
    NAME_HERE = '%NAME%';
    TAG_HERE = '%TAG%';
    TEXT_HERE = '%TEXT%';
  public
    property FormatString: string read FFormatString write FFormatString;
    property DateFormat: string read FDateFormat write FDateFormat;
    property TimeFormat: string read FTimeFormat write FTimeFormat;
    class function CreateDefault: TPlainLogTextFormat;
    class function CreateShort: TPlainLogTextFormat;
    function Format(const aMessage: TCustomLogMessage): string; override;
  end;

implementation

procedure TPlainLogTextFormat.PutDateTime(var s: string; const aMessage: TCustomLogMessage;
  const aReplaceWord, aFormat: string);
var
  date: string;
begin
  if Pos(DATE_HERE, FormatString) > 0 then
  begin
    date := '';
    DateTimeToString(date, aFormat, aMessage.Time);
    s := ReplaceStr(s, aReplaceWord, date);
  end;
end;

procedure TPlainLogTextFormat.PutThis(var s: string; const aReplaceWord, aThis: string);
begin
  s := ReplaceStr(s, aReplaceWord, aThis);
end;

function TPlainLogTextFormat.Format(const aMessage: TCustomLogMessage): string;
begin
  result := FormatString;
  PutDateTime(result, aMessage, DATE_HERE, DateFormat);
  PutDateTime(result, aMessage, TIME_HERE, TimeFormat);
  PutThis(result, TAG_HERE, aMessage.Tag);
  Putthis(result, NAME_HERE, aMessage.Name);
  PutThis(result, TEXT_HERE, aMessage.Text);
end;

class function TPlainLogTextFormat.CreateDefault: TPlainLogTextFormat;
begin
  result := TPlainLogTextFormat.Create;
  result.FormatString := '%DATE% %TIME% [%TAG%] %NAME%: %TEXT%';
  result.DateFormat := 'yyyy.mm.dd';
  result.TimeFormat := 'hh:mm:ss.zzz';
end;

class function TPlainLogTextFormat.CreateShort: TPlainLogTextFormat;
begin
  result := TPlainLogTextFormat.Create;
  result.FormatString := '[%TAG%] %NAME%: %TEXT%';
end;

end.
