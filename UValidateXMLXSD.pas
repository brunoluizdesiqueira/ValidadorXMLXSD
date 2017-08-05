unit UValidateXMLXSD;

interface

uses
  UProgressThread, Classes;
type
  TValidateXMLXSD = class (TProgressThread)
  private
    FNamespaceURI: String;
    FXMLFile: String;
    FResult: TStringList;
    FIgnoreDuplicates: Boolean;
    FPathSchema : TStrings;
    function ValidateXMLXSD(pNamespaceURI, PXMLFile: string; PathSchema: TStrings; PIgnoreDuplicates: Boolean): TStringList;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Execute; override;
    property NamespaceURI: String write FNamespaceURI;
    property XMLFile: String write FXMLFile;
    property IgnoreDuplicates: Boolean write FIgnoreDuplicates;
    property Result: TStringList read FResult;
    property PathSchema: TStrings read FPathSchema;
  end;

implementation

uses
  SysUtils, ComObj, ActiveX, MSXML2_TLB;
type
  TSaxErrorHandler = class (TInterfacedObject, IVBSAXErrorHandler)
  private
    FListaDeErros: TStringList;
    FIgnoreDuplicates: Boolean;
  public
    constructor Create(PListaDeErros: TStringList; PIgnoreDuplicates: Boolean);
    // TInterfacedObject
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
    // IVBSAXErrorHandler
    procedure Error(const oLocator: IVBSAXLocator; var strErrorMessage: WideString; nErrorCode: Integer); safecall;
    procedure FatalError(const oLocator: IVBSAXLocator; var strErrorMessage: WideString; nErrorCode: Integer); safecall;
    procedure IgnorableWarning(const oLocator: IVBSAXLocator; var strErrorMessage: WideString; nErrorCode: Integer); safecall;
  end;

  TSaxContentHandler = class (TInterfacedObject, IVBSAXContentHandler)
  protected
    FPath: TStringList;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    // TInterfacedObject
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
    // IVBSAXContentHandler
    procedure _Set_documentLocator(const Param1: IVBSAXLocator); virtual; safecall;
    procedure startDocument; virtual; safecall;
    procedure endDocument; virtual; safecall;
    procedure startPrefixMapping(var strPrefix: WideString; var strURI: WideString); virtual; safecall;
    procedure endPrefixMapping(var strPrefix: WideString); virtual; safecall;
    procedure startElement(var strNamespaceURI: WideString; var strLocalName: WideString; var strQName: WideString; const oAttributes: IVBSAXAttributes); virtual; safecall;
    procedure endElement(var strNamespaceURI: WideString; var strLocalName: WideString; var strQName: WideString); virtual; safecall;
    procedure characters(var strChars: WideString); virtual; safecall;
    procedure ignorableWhitespace(var strChars: WideString); virtual; safecall;
    procedure processingInstruction(var strTarget: WideString; var strData: WideString); virtual; safecall;
    procedure skippedEntity(var strName: WideString); virtual; safecall;
  end;
  { Eu poderia ter resolvido tudo usando apenas a classe acima, mas resolvi
  implementar uma classe filha como exemplo, pois podemos implementar várias
  classes filhas com funcionalidades distintas, e que contém uma funcionalidade
  comum (classe pai) }
  TTagReaded = class (TSaxContentHandler)
  private
    FValidateXMLXSD: TValidateXMLXSD;
  public
    constructor Create(PValidateXMLXSD: TValidateXMLXSD); reintroduce;
    procedure startElement(var strNamespaceURI: WideString; var strLocalName: WideString; var strQName: WideString; const oAttributes: IVBSAXAttributes); override; safecall;
  end;

{ TValidateXMLXSD }

constructor TValidateXMLXSD.Create;
begin
  inherited;
  FPathSchema := TStringList.Create;
end;

destructor TValidateXMLXSD.Destroy;
begin

  inherited;
  FPathSchema.Free;
end;

procedure TValidateXMLXSD.Execute;
var
  XMLDocument: Variant;
begin
  inherited;
  Max := 0;

  CoInitialize(nil);
  try
    try
      XMLDocument := CreateOLEObject('MSXML2.DOMDocument.6.0');
      XMLDocument.load(FXMLFile);
      Max := XMLDocument.documentElement.selectNodes('//*').Length;
      DoMax;
    finally
      XMLDocument := varNull;
    end;

    FResult := ValidateXMLXSD(FNamespaceURI, FXMLFile, FPathSchema, FIgnoreDuplicates);
  finally
    CoUnInitialize;
  end;
end;

function TValidateXMLXSD.ValidateXMLXSD(pNamespaceURI, PXMLFile: String; PathSchema: TStrings; PIgnoreDuplicates: Boolean): TStringList;
var
  SAXXMLReader: IVBSAXXMLReader;
  XMLSchemaCache: Variant;
  i: Integer;
  nResult : Integer;
begin

  // Criando uma coleção de esquemas (XSD)
  XMLSchemaCache := CreateOleObject('MSXML2.XMLSchemaCache.6.0');
  try
    // Criando um leitor SAX (XML)
    SAXXMLReader := CreateOleObject('MSXML2.SAXXMLReader.6.0') as IVBSAXXMLReader;

    XMLSchemaCache.validateOnLoad := false;

    try
      // Bruno: Neste ponto achei melhor receber uma lista de path para adicionar todos os arquivos XSD na coleção
      for i:= 0 to PathSchema.count -1 do
       nResult := XMLSchemaCache.Add(pNamespaceURI, PathSchema[i]);
    except
       Raise Exception.Create(IntToStr(nResult));
    end;

    // Configurando o leitor SAX para validar o documento XML que nele for carregado
    SAXXMLReader.putFeature('schema-validation', True);
    SAXXMLReader.putFeature('exhaustive-errors', True);
    SAXXMLReader.putProperty('schemas', XMLSchemaCache);

    Result := TStringList.Create;
    // Atribuindo manipuladores necessários. TSaxErrorHandler manipula apenas os erros
    // e TTagReaded manipula cada nó lido
    SAXXMLReader.errorHandler := TSaxErrorHandler.Create(Result,PIgnoreDuplicates); // Manipula apenas os erros encontrados
    SAXXMLReader.contentHandler := TTagReaded.Create(Self);       // Manipula cada um dos nós

    // Executa a validação
    try
      SAXXMLReader.ParseURL(PXMLFile);
    except
      { Evita que as exceções decorrentes de erros de validação parem um
      processamento em lote }
    end;
  finally
    XMLSchemaCache := varNull;
  end;
end;

{ TSaxErrorHandler }

constructor TSaxErrorHandler.Create(PListaDeErros: TStringList; PIgnoreDuplicates: Boolean);
begin
  FListaDeErros := PListaDeErros;
  FIgnoreDuplicates := PIgnoreDuplicates;
end;

procedure TSaxErrorHandler.Error(const oLocator: IVBSAXLocator; var strErrorMessage: WideString; nErrorCode: Integer);
var
  Erro: String;
begin
  { Quando um erro é encontrado em um nó, este evento é executado }
  Erro := '[ERRO]: ' + Trim(StringReplace(strErrorMessage,#13#10,' ',[rfReplaceAll]));
  if (not FIgnoreDuplicates) or (FListaDeErros.IndexOf(Erro) = -1) then
    FListaDeErros.Add(Erro);
  // oLocator.lineNumber, oLocator.columnNumber;
end;

procedure TSaxErrorHandler.FatalError(const oLocator: IVBSAXLocator; var strErrorMessage: WideString; nErrorCode: Integer);
begin
  { Quando um erro muito grave é encontrado, este evento é executado. O parser para imediatamentealidação falhe }
  FListaDeErros.Add('[ERRO FATAL]: ' + Trim(StringReplace(strErrorMessage,#13#10,' ',[rfReplaceAll])));
end;

function TSaxErrorHandler.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
begin
  Result := E_NOTIMPL; { Não usado }
end;

function TSaxErrorHandler.GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult;
begin
  Result := E_NOTIMPL; { Não usado }
end;

function TSaxErrorHandler.GetTypeInfoCount(out Count: Integer): HResult;
begin
  Result := E_NOTIMPL; { Não usado }
end;

procedure TSaxErrorHandler.IgnorableWarning(const oLocator: IVBSAXLocator; var strErrorMessage: WideString; nErrorCode: Integer);
var
  Erro: String;
begin
  { Quando um aviso é encontrado, este evento é executado }
  Erro := '[AVISO]: ' + Trim(StringReplace(strErrorMessage,#13#10,' ',[rfReplaceAll]));
  if (not FIgnoreDuplicates) or (FListaDeErros.IndexOf(Erro) = -1) then
    FListaDeErros.Add(Erro);
end;

function TSaxErrorHandler.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult;
begin
  Result := E_NOTIMPL; { Não usado }
end;

{ TMySaxHandler }

procedure TSaxContentHandler.characters(var strChars: WideString);
begin
  { Este método é executado para exibir o conteúdo de um tag. Normalmente o que
  acontece é <tag>strChars</tag>, logo este procedure pode ser usado para obter
  texto plano que está contido dentro de um tag }
end;

constructor TSaxContentHandler.Create;
begin
  FPath := TStringList.Create;
end;

destructor TSaxContentHandler.Destroy;
begin
  FPath.Free;
  inherited;
end;

procedure TSaxContentHandler.endDocument;
begin
  { Este método é executado após a leitura do documento chegar ao final }
end;

procedure TSaxContentHandler.endElement(var strNamespaceURI, strLocalName, strQName: WideString);
begin
  { Este método é executado quando um tag de fechamento é encontrado }
  FPath.Delete(Pred(FPath.Count));
end;

procedure TSaxContentHandler.endPrefixMapping(var strPrefix: WideString);
begin
  { Não usado }
end;

function TSaxContentHandler.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;

function TSaxContentHandler.GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult;
begin
  Result := E_NOTIMPL;
end;

function TSaxContentHandler.GetTypeInfoCount(out Count: Integer): HResult;
begin
  Result := E_NOTIMPL;
end;

procedure TSaxContentHandler.ignorableWhitespace(var strChars: WideString);
begin
  { Não usado }
end;

function TSaxContentHandler.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult;
begin
  Result := E_NOTIMPL; { Não usado }
end;

procedure TSaxContentHandler.processingInstruction(var strTarget, strData: WideString);
begin
  { Não usado }
end;

procedure TSaxContentHandler.skippedEntity(var strName: WideString);
begin
  { Não usado }
end;

procedure TSaxContentHandler.startDocument;
begin
  { Este método é executado antes da leitura do documento começar }
end;

procedure TSaxContentHandler.startElement(var strNamespaceURI, strLocalName, strQName: WideString; const oAttributes: IVBSAXAttributes);
begin
  { Este método é executado quando um tag de abertura é encontrado }
  FPath.Add(strLocalName);
end;

procedure TSaxContentHandler.startPrefixMapping(var strPrefix, strURI: WideString);
begin
  { Não usado }
end;

procedure TSaxContentHandler._Set_documentLocator(const Param1: IVBSAXLocator);
begin
  { Não usado }
end;

{ TTagReaded }

constructor TTagReaded.Create(PValidateXMLXSD: TValidateXMLXSD);
begin
  inherited Create;
  FValidateXMLXSD := PValidateXMLXSD;
end;

procedure TTagReaded.startElement(var strNamespaceURI, strLocalName, strQName: WideString; const oAttributes: IVBSAXAttributes);
begin
  inherited;
  FValidateXMLXSD.Text := strLocalName;
  FValidateXMLXSD.Number := 0;
  FValidateXMLXSD.DoProgress;
end;

end.