unit VCLLogViewPainter;

interface

uses
  Graphics,

  CustomLogMessage,
  UVCLTextBoxPaint;

type
  TLogMessageTextBoxPaint = class(TTextBoxPainter)
  public
    procedure Draw(const aMessage: TCustomLogMessage);
  end;

  TLogMessageTextBoxPaintAdvanced = class(TLogMessageTextBoxPaint)
  public
  end;

implementation

procedure TLogMessageTextBoxPaint.Draw(const aMessage: TCustomLogMessage);
begin
  AppendDraw(aMessage.Text, clBlack);
end;

end.
