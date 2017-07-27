program ValidadorXMLXSD;

uses
  Forms,
  Principal in 'Principal.pas' {frmValidarXML},
  MSXML2_TLB in 'MSXML2_TLB.pas',
  UValidateXMLXSD in 'UValidateXMLXSD.pas',
  UProgressThread in 'UProgressThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmValidarXML, frmValidarXML);
  Application.Run;
end.
