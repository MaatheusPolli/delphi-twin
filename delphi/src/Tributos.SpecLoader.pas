unit Tributos.SpecLoader;

{
  Le os casos de teste de spec/cases/*.json (formato descrito em
  spec/schema/case.schema.json) e converte para os records de
  Tributos.Types, e vice-versa para serializar um TResultadoTributos.

  Usa apenas System.JSON (biblioteca padrao do Delphi) - sem dependencias
  externas, conforme requisito nao funcional do projeto. Todo valor
  decimal trafega como string no JSON (nunca number), para preservar
  precisao exata ao converter para Currency.
}

interface

uses
  System.JSON,
  System.SysUtils,
  System.IOUtils,
  Tributos.Types;

type
  TCasoDeTeste = record
    Id: string;
    Descricao: string;
    Entrada: TOperacaoFiscal;
    TemEsperado: Boolean;
    Esperado: TResultadoTributos;
  end;

function CarregarCasoDeArquivo(const ACaminhoArquivo: string): TCasoDeTeste;
function CarregarCasoDeJson(const AJson: TJSONObject): TCasoDeTeste;
function ListarArquivosDeCasos(const APastaCases: string): TArray<string>;
function ResultadoParaJson(const AResultado: TResultadoTributos): TJSONObject;

implementation

function StrDecimalParaCurrency(const AObjeto: TJSONObject; const ACampo: string): Currency;
var
  Valor: string;
begin
  Valor := AObjeto.GetValue<string>(ACampo);
  Result := StrToCurr(Valor, TFormatSettings.Invariant);
end;

function StrDecimalOpcionalParaCurrency(const AObjeto: TJSONObject; const ACampo: string; out ATemValor: Boolean): Currency;
var
  Membro: TJSONValue;
begin
  ATemValor := AObjeto.TryGetValue<TJSONValue>(ACampo, Membro);
  if ATemValor then
    Result := StrToCurr(Membro.Value, TFormatSettings.Invariant)
  else
    Result := 0;
end;

function CurrencyParaStrDecimal(const AValor: Currency): string;
begin
  Result := CurrToStr(AValor, TFormatSettings.Invariant);
end;

function CarregarItemIpi(const AObjeto: TJSONObject): TItemIpi;
var
  Flag: TJSONValue;
begin
  Result.Aliquota := StrDecimalParaCurrency(AObjeto, 'aliquota');
  Result.Cst := AObjeto.GetValue<string>('cst');
  if AObjeto.TryGetValue<TJSONValue>('incluirNaBaseIcms', Flag) then
    Result.IncluirNaBaseIcms := (Flag as TJSONBool).AsBoolean
  else
    Result.IncluirNaBaseIcms := False;
end;

function CarregarItemIcms(const AObjeto: TJSONObject): TItemIcms;
begin
  Result.Cst := AObjeto.GetValue<string>('cst');
  Result.AliquotaInterna := StrDecimalParaCurrency(AObjeto, 'aliquotaInterna');
  Result.AliquotaInterestadual := StrDecimalParaCurrency(AObjeto, 'aliquotaInterestadual');
  Result.ReducaoBC := StrDecimalOpcionalParaCurrency(AObjeto, 'reducaoBC', Result.TemReducaoBC);
  Result.Mva := StrDecimalOpcionalParaCurrency(AObjeto, 'mva', Result.TemMva);
  Result.ReducaoBCST := StrDecimalOpcionalParaCurrency(AObjeto, 'reducaoBCST', Result.TemReducaoBCST);
  Result.Fcp := StrDecimalOpcionalParaCurrency(AObjeto, 'fcp', Result.TemFcp);
end;

function CarregarItemPisCofins(const AObjeto: TJSONObject): TItemPisCofins;
var
  RegimeStr: string;
begin
  RegimeStr := AObjeto.GetValue<string>('regime');
  if RegimeStr = 'nao-cumulativo' then
    Result.Regime := rpcNaoCumulativo
  else
    Result.Regime := rpcCumulativo;
  Result.CstPis := AObjeto.GetValue<string>('cstPis');
  Result.CstCofins := AObjeto.GetValue<string>('cstCofins');
  Result.AliquotaPis := StrDecimalParaCurrency(AObjeto, 'aliquotaPis');
  Result.AliquotaCofins := StrDecimalParaCurrency(AObjeto, 'aliquotaCofins');
end;

function CarregarItemOperacao(const AObjeto: TJSONObject): TItemOperacao;
begin
  Result.ValorProduto := StrDecimalParaCurrency(AObjeto, 'valorProduto');
  Result.Quantidade := StrDecimalParaCurrency(AObjeto, 'quantidade');
  Result.Frete := StrDecimalParaCurrency(AObjeto, 'frete');
  Result.Seguro := StrDecimalParaCurrency(AObjeto, 'seguro');
  Result.Desconto := StrDecimalParaCurrency(AObjeto, 'desconto');
  Result.Outras := StrDecimalParaCurrency(AObjeto, 'outras');
  Result.Ipi := CarregarItemIpi(AObjeto.GetValue<TJSONObject>('ipi'));
  Result.Icms := CarregarItemIcms(AObjeto.GetValue<TJSONObject>('icms'));
  Result.PisCofins := CarregarItemPisCofins(AObjeto.GetValue<TJSONObject>('pisCofins'));
end;

function CarregarOperacao(const AObjeto: TJSONObject): TOperacaoFiscal;
begin
  Result.UfOrigem := AObjeto.GetValue<string>('ufOrigem');
  Result.UfDestino := AObjeto.GetValue<string>('ufDestino');
  Result.DestinatarioContribuinte := (AObjeto.GetValue('destinatarioContribuinte') as TJSONBool).AsBoolean;
  if AObjeto.GetValue<string>('regimeEmitente') = 'simples' then
    Result.RegimeEmitente := reSimples
  else
    Result.RegimeEmitente := reNormal;
  Result.Item := CarregarItemOperacao(AObjeto.GetValue<TJSONObject>('item'));
end;

function CarregarTributoBase(const AObjeto: TJSONObject): TTributoBase;
begin
  Result.Bc := StrDecimalParaCurrency(AObjeto, 'bc');
  Result.Aliquota := StrDecimalParaCurrency(AObjeto, 'aliquota');
  Result.Valor := StrDecimalParaCurrency(AObjeto, 'valor');
end;

function CarregarResultado(const AObjeto: TJSONObject): TResultadoTributos;
var
  IcmsStObj, DifalObj: TJSONValue;
begin
  Result := Default(TResultadoTributos);
  Result.Icms := CarregarTributoBase(AObjeto.GetValue<TJSONObject>('icms'));
  Result.Ipi := CarregarTributoBase(AObjeto.GetValue<TJSONObject>('ipi'));
  Result.Pis := CarregarTributoBase(AObjeto.GetValue<TJSONObject>('pis'));
  Result.Cofins := CarregarTributoBase(AObjeto.GetValue<TJSONObject>('cofins'));
  Result.TotalTributos := StrDecimalParaCurrency(AObjeto, 'totalTributos');

  Result.TemIcmsSt := AObjeto.TryGetValue<TJSONValue>('icmsSt', IcmsStObj);
  if Result.TemIcmsSt then
  begin
    Result.IcmsSt.Bc := StrDecimalParaCurrency(IcmsStObj as TJSONObject, 'bc');
    Result.IcmsSt.Aliquota := StrDecimalParaCurrency(IcmsStObj as TJSONObject, 'aliquota');
    Result.IcmsSt.Valor := StrDecimalParaCurrency(IcmsStObj as TJSONObject, 'valor');
    Result.IcmsSt.MvaAplicada := StrDecimalParaCurrency(IcmsStObj as TJSONObject, 'mvaAplicada');
  end;

  Result.TemDifal := AObjeto.TryGetValue<TJSONValue>('difal', DifalObj);
  if Result.TemDifal then
  begin
    Result.Difal.ValorOrigem := StrDecimalParaCurrency(DifalObj as TJSONObject, 'valorOrigem');
    Result.Difal.ValorDestino := StrDecimalParaCurrency(DifalObj as TJSONObject, 'valorDestino');
    Result.Difal.Fcp := StrDecimalParaCurrency(DifalObj as TJSONObject, 'fcp');
  end;
end;

function CarregarCasoDeJson(const AJson: TJSONObject): TCasoDeTeste;
var
  EsperadoObj: TJSONValue;
begin
  Result.Id := AJson.GetValue<string>('id');
  Result.Descricao := AJson.GetValue<string>('descricao');
  Result.Entrada := CarregarOperacao(AJson.GetValue<TJSONObject>('entrada'));

  Result.TemEsperado := AJson.TryGetValue<TJSONValue>('esperado', EsperadoObj);
  if Result.TemEsperado then
    Result.Esperado := CarregarResultado(EsperadoObj as TJSONObject)
  else
    Result.Esperado := Default(TResultadoTributos);
end;

function CarregarCasoDeArquivo(const ACaminhoArquivo: string): TCasoDeTeste;
var
  Texto: string;
  Json: TJSONValue;
begin
  Texto := TFile.ReadAllText(ACaminhoArquivo, TEncoding.UTF8);
  Json := TJSONObject.ParseJSONValue(Texto);
  try
    Result := CarregarCasoDeJson(Json as TJSONObject);
  finally
    Json.Free;
  end;
end;

function ListarArquivosDeCasos(const APastaCases: string): TArray<string>;
begin
  Result := TDirectory.GetFiles(APastaCases, '*.json');
  TArray.Sort<string>(Result);
end;

function TributoBaseParaJson(const ATributo: TTributoBase): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('bc', CurrencyParaStrDecimal(ATributo.Bc));
  Result.AddPair('aliquota', CurrencyParaStrDecimal(ATributo.Aliquota));
  Result.AddPair('valor', CurrencyParaStrDecimal(ATributo.Valor));
end;

function ResultadoParaJson(const AResultado: TResultadoTributos): TJSONObject;
var
  IcmsStObj, DifalObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('icms', TributoBaseParaJson(AResultado.Icms));
  Result.AddPair('ipi', TributoBaseParaJson(AResultado.Ipi));
  Result.AddPair('pis', TributoBaseParaJson(AResultado.Pis));
  Result.AddPair('cofins', TributoBaseParaJson(AResultado.Cofins));
  Result.AddPair('totalTributos', CurrencyParaStrDecimal(AResultado.TotalTributos));

  if AResultado.TemIcmsSt then
  begin
    IcmsStObj := TJSONObject.Create;
    IcmsStObj.AddPair('bc', CurrencyParaStrDecimal(AResultado.IcmsSt.Bc));
    IcmsStObj.AddPair('aliquota', CurrencyParaStrDecimal(AResultado.IcmsSt.Aliquota));
    IcmsStObj.AddPair('valor', CurrencyParaStrDecimal(AResultado.IcmsSt.Valor));
    IcmsStObj.AddPair('mvaAplicada', CurrencyParaStrDecimal(AResultado.IcmsSt.MvaAplicada));
    Result.AddPair('icmsSt', IcmsStObj);
  end;

  if AResultado.TemDifal then
  begin
    DifalObj := TJSONObject.Create;
    DifalObj.AddPair('valorOrigem', CurrencyParaStrDecimal(AResultado.Difal.ValorOrigem));
    DifalObj.AddPair('valorDestino', CurrencyParaStrDecimal(AResultado.Difal.ValorDestino));
    DifalObj.AddPair('fcp', CurrencyParaStrDecimal(AResultado.Difal.Fcp));
    Result.AddPair('difal', DifalObj);
  end;
end;

end.
