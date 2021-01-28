program Test;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {fMain},
  uThumbnail in 'uThumbnail.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
