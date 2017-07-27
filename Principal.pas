unit Principal;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  ComCtrls,
  StdCtrls,
  UValidateXMLXSD,
  ExtCtrls,
  abcfdir;

type
  TfrmValidarXML = class(TForm)
    mmoLog: TMemo;
    pbBarraProgresso: TProgressBar;
    Panel1: TPanel;
    btnValidar: TButton;
    Panel2: TPanel;
    lblArquivo: TLabel;
    lblPercentual: TLabel;
    Panel3: TPanel;
    edtXML: TEdit;
    edtXSD: TEdit;
    btnLocalizarXSD: TButton;
    btnLocalizarXML: TButton;
    lblXML: TLabel;
    lblXSD: TLabel;
    dlgOpen: TOpenDialog;
    abcDirectoryDialog: TabcDirectoryDialog;
    procedure btnValidarClick(Sender: TObject);
    procedure btnLocalizarXMLClick(Sender: TObject);
    procedure btnLocalizarXSDClick(Sender: TObject);
  private
    { Private declarations }
    FValidateXMLXSD: TValidateXMLXSD;
    procedure DoProgress (const PText: String; const PNumber: Cardinal);
    procedure DoMax(const PMax: Int64);
    procedure DoTerminate(PSender: TObject);
    function Validar: Boolean;
    procedure ListarArquivos(Path: string; Lista: TStrings);
    function Ignore(pNomeArquivo: string): Boolean;
  public
    { Public declarations }
  end;

var
  frmValidarXML: TfrmValidarXML;

Const
   NAMESPACE_URI = 'http://www.portalfiscal.inf.br/nfe';

implementation

{$R *.dfm}

procedure TfrmValidarXML.DoMax(const PMax: Int64);
begin
  pbBarraProgresso.Step := 1;
  pbBarraProgresso.Position := 0;
  pbBarraProgresso.Max := PMax;
  pbBarraProgresso.DoubleBuffered := True;
end;

procedure TfrmValidarXML.DoProgress(const PText: String;
  const PNumber: Cardinal);
begin
  pbBarraProgresso.StepIt;
  
  lblArquivo.Caption := 'Arquivo ' + IntToStr(pbBarraProgresso.Position) + ' / ' + IntToStr(pbBarraProgresso.Max) + ': ' +
    FormatFloat('(###,###,###,###,##0 bytes) ',PNumber) + PText;

  lblPercentual.Caption := FormatFloat('##0.00%',pbBarraProgresso.Position / pbBarraProgresso.Max * 100);
end;

procedure TfrmValidarXML.DoTerminate(PSender: TObject);
begin
  try
    if Assigned(FValidateXMLXSD.Result) then
      begin
        { caso haja linhas no resultado, significa que houve erros, logo, devemos mostrá-los }
        if FValidateXMLXSD.Result.Count > 0 then
        begin
          mmoLog.Lines.Add('Os seguintes erros de validação foram encontrados:'#13#10);
          mmoLog.Lines.Add(FValidateXMLXSD.Result.Text);
        end
      end
    else
      mmoLog.Lines.Add('Este arquivo não contém erros!'#13#10);
  finally
    FValidateXMLXSD.Result.Free;
  end;
  mmoLog.Lines.Add('-------------');
end;

procedure TfrmValidarXML.btnValidarClick(Sender: TObject);
begin
  Validar();

  mmoLog.Clear;
  mmoLog.Lines.Add('Validando o arquivo: ' + edtXML.Text + #13#10);

  FValidateXMLXSD := TValidateXMLXSD.Create;

  with FValidateXMLXSD do
  begin
    NamespaceURI := NAMESPACE_URI;
    XMLFile := edtXML.Text;

    // Preferi passar uma lista Path de XSD para que todos sejam adicionados,
    // pois ao tentar validar um XML já autorizado verifiquei que não foi carregado o xsd procNFe_v3.10.xsd,
    // portanto as tags referente ao protocolo de autrização não foram identificadas.
    
    ListarArquivos(edtXSD.Text, PathSchema);
    IgnoreDuplicates := False; // usar true, gera menos saída, caso haja erros
    OnMax := DoMax; // evento para configurar a barra de progresso
    OnProgress := DoProgress; // evento para incrementar a barra de progresso
    OnTerminate := DoTerminate; // evento ativado quando a thread termina
    Resume;
  end;
end;

procedure TfrmValidarXML.btnLocalizarXMLClick(Sender: TObject);
begin
  dlgOpen.FileName := '';
  dlgOpen.Title := 'Localizar XML';
  dlgOpen.InitialDir := 'C:\DadosNFeasy\Envio\RecepcaoNFe\Pendente\';
  dlgOpen.Filter := 'PDF files (*.xml)|*.XML';

  if dlgOpen.Execute then
    edtXML.Text := dlgOpen.FileName;
end;

procedure TfrmValidarXML.btnLocalizarXSDClick(Sender: TObject);
begin
  abcDirectoryDialog.Directory := 'C:\DSN\trunk\unitscompartilhadas\altnfeinterface\binding\xsd\';
  abcDirectoryDialog.Title := 'Localizar XML';

  if abcDirectoryDialog.Execute then
    edtXSD.Text := IncludeTrailingPathDelimiter(abcDirectoryDialog.Directory);
end;


function TfrmValidarXML.Validar(): Boolean;
var Ok: Boolean;
begin
  Ok := True;

  if (Trim(edtXML.Text) = '') then
  begin
    OK := False;
    edtXML.SetFocus;
    ShowMessage('Será necessário informar o XML!');
  end;

  if (Trim(edtXSD.Text) = '') then
  begin
    OK := False;
    edtXSD.SetFocus;
    ShowMessage('Será necessário informar o XSD!');
  end;

  Result := Ok;
end;

procedure TfrmValidarXML.ListarArquivos(Path: string; Lista: TStrings);
var SR: TSearchRec;
begin
  if FindFirst(Path + '*.xsd', faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr <> faDirectory) then
        if not (Ignore(SR.Name)) then
          Lista.Add(Path + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

function TfrmValidarXML.Ignore(pNomeArquivo: string): Boolean;
var
  Lista: TStringList;
  i: Integer;
begin
  Lista := TStringList.Create();

  Lista.Add('consSitNFe_v3.10.xsd');
  Lista.Add('leiauteConsSitNFe_v3.10.xsd');
  Lista.Add('retConsSitNFe_v3.10.xsd');
  Lista.Add('tmp0000.xsd');
  Lista.Add('xmldsig-core-schema_v1.01.xsd');

  try
    Result := False;
    for i := 0 to Lista.Count -1 do
    begin
      Result := pNomeArquivo = Lista[i];
      if Result then
        break;
    end;
  finally
    Lista.Free;
  end;
end;

end.
