program RunSpecFPC;

{$mode delphi}

{
  Runner standalone (sem DUnitX, que nao existe no Free Pascal) para validar
  de verdade, em tempo de execucao, o nucleo puro do motor tributario
  compilado com FPC em modo Delphi. Os 11 casos abaixo replicam
  spec/cases/*.json como literais Pascal (o FPC nao tem um equivalente
  pronto de System.JSON para ler os arquivos direto).

  Alem de validar as formulas, este runner e a prova em tempo de execucao
  de que Round() sobre Currency se comporta como ROUND_HALF_EVEN (banker's
  rounding) tambem no FPC/Win32 - a mesma suposicao documentada em
  Tributos.Decimal.pas para o Delphi.
}

uses
  SysUtils,
  Classes,
  Tributos.Types in '..\..\src\Tributos.Types.pas',
  Tributos.Decimal in '..\..\src\Tributos.Decimal.pas',
  Tributos.Icms in '..\..\src\Tributos.Icms.pas',
  Tributos.IcmsST in '..\..\src\Tributos.IcmsST.pas',
  Tributos.Ipi in '..\..\src\Tributos.Ipi.pas',
  Tributos.PisCofins in '..\..\src\Tributos.PisCofins.pas',
  Tributos.Difal in '..\..\src\Tributos.Difal.pas',
  Tributos.Motor in '..\..\src\Tributos.Motor.pas';

var
  TotalOK, TotalFalha: Integer;
  FormatoInvariante: TFormatSettings;

function CurrToStrInvariante(const AValor: Currency): string;
begin
  Result := CurrToStr(AValor, FormatoInvariante);
end;

function OperacaoBase: TOperacaoFiscal;
begin
  Result := Default(TOperacaoFiscal);
  Result.UfOrigem := 'SP';
  Result.UfDestino := 'SP';
  Result.DestinatarioContribuinte := True;
  Result.RegimeEmitente := reNormal;
  Result.Item.ValorProduto := 1000;
  Result.Item.Quantidade := 1;
  Result.Item.Ipi.Cst := '53';
  Result.Item.Icms.Cst := '00';
  Result.Item.Icms.AliquotaInterna := 18;
  Result.Item.Icms.AliquotaInterestadual := 18;
  Result.Item.PisCofins.Regime := rpcCumulativo;
  Result.Item.PisCofins.CstPis := '01';
  Result.Item.PisCofins.CstCofins := '01';
  Result.Item.PisCofins.AliquotaPis := 0.65;
  Result.Item.PisCofins.AliquotaCofins := 3;
end;

procedure Checar(const ACaso, ACampo: string; const AEsperado, AObtido: Currency);
begin
  if AEsperado = AObtido then
    Inc(TotalOK)
  else
  begin
    Inc(TotalFalha);
    Writeln(Format('FALHA [%s] %s: esperado=%s obtido=%s', [ACaso, ACampo, CurrToStr(AEsperado), CurrToStr(AObtido)]));
  end;
end;

function TributoBaseParaJson(const ABc, AAliquota, AValor: Currency): string;
begin
  Result :=
    '    "bc": "' + CurrToStrInvariante(ABc) + '",' + sLineBreak +
    '    "aliquota": "' + CurrToStrInvariante(AAliquota) + '",' + sLineBreak +
    '    "valor": "' + CurrToStrInvariante(AValor) + '"' + sLineBreak +
    '  }';
end;

function ResultadoParaJson(const AResultado: TResultadoTributos): string;
begin
  Result := '{' + sLineBreak;
  Result := Result + '  "icms": {' + sLineBreak + TributoBaseParaJson(AResultado.Icms.Bc, AResultado.Icms.Aliquota, AResultado.Icms.Valor) + ',' + sLineBreak;
  Result := Result + '  "ipi": {' + sLineBreak + TributoBaseParaJson(AResultado.Ipi.Bc, AResultado.Ipi.Aliquota, AResultado.Ipi.Valor) + ',' + sLineBreak;
  Result := Result + '  "pis": {' + sLineBreak + TributoBaseParaJson(AResultado.Pis.Bc, AResultado.Pis.Aliquota, AResultado.Pis.Valor) + ',' + sLineBreak;
  Result := Result + '  "cofins": {' + sLineBreak + TributoBaseParaJson(AResultado.Cofins.Bc, AResultado.Cofins.Aliquota, AResultado.Cofins.Valor) + ',' + sLineBreak;
  Result := Result + '  "totalTributos": "' + CurrToStrInvariante(AResultado.TotalTributos) + '"';

  if AResultado.TemIcmsSt then
  begin
    Result := Result + ',' + sLineBreak + '  "icmsSt": {' + sLineBreak +
      '    "bc": "' + CurrToStrInvariante(AResultado.IcmsSt.Bc) + '",' + sLineBreak +
      '    "aliquota": "' + CurrToStrInvariante(AResultado.IcmsSt.Aliquota) + '",' + sLineBreak +
      '    "valor": "' + CurrToStrInvariante(AResultado.IcmsSt.Valor) + '",' + sLineBreak +
      '    "mvaAplicada": "' + CurrToStrInvariante(AResultado.IcmsSt.MvaAplicada) + '"' + sLineBreak +
      '  }';
  end;

  if AResultado.TemDifal then
  begin
    Result := Result + ',' + sLineBreak + '  "difal": {' + sLineBreak +
      '    "valorOrigem": "' + CurrToStrInvariante(AResultado.Difal.ValorOrigem) + '",' + sLineBreak +
      '    "valorDestino": "' + CurrToStrInvariante(AResultado.Difal.ValorDestino) + '",' + sLineBreak +
      '    "fcp": "' + CurrToStrInvariante(AResultado.Difal.Fcp) + '"' + sLineBreak +
      '  }';
  end;

  Result := Result + sLineBreak + '}' + sLineBreak;
end;

procedure GravarResultado(const AId: string; const AResultado: TResultadoTributos);
var
  Pasta: string;
begin
  Pasta := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + '..\..\..\..\results\delphi\';
  ForceDirectories(Pasta);
  with TStringList.Create do
  try
    Text := ResultadoParaJson(AResultado);
    SaveToFile(Pasta + AId + '.json');
  finally
    Free;
  end;
end;

procedure RodarCaso(const AId: string; const AOperacao: TOperacaoFiscal; const AEsperado: TResultadoTributos);
var
  Motor: IMotorTributario;
  Obtido: TResultadoTributos;
begin
  Motor := TMotorTributario.CreatePadrao;
  Obtido := Motor.Calcular(AOperacao);
  GravarResultado(AId, Obtido);

  Checar(AId, 'icms.bc', AEsperado.Icms.Bc, Obtido.Icms.Bc);
  Checar(AId, 'icms.aliquota', AEsperado.Icms.Aliquota, Obtido.Icms.Aliquota);
  Checar(AId, 'icms.valor', AEsperado.Icms.Valor, Obtido.Icms.Valor);
  Checar(AId, 'ipi.bc', AEsperado.Ipi.Bc, Obtido.Ipi.Bc);
  Checar(AId, 'ipi.valor', AEsperado.Ipi.Valor, Obtido.Ipi.Valor);
  Checar(AId, 'pis.valor', AEsperado.Pis.Valor, Obtido.Pis.Valor);
  Checar(AId, 'cofins.valor', AEsperado.Cofins.Valor, Obtido.Cofins.Valor);
  Checar(AId, 'totalTributos', AEsperado.TotalTributos, Obtido.TotalTributos);

  if AEsperado.TemIcmsSt then
  begin
    if not Obtido.TemIcmsSt then
    begin
      Inc(TotalFalha);
      Writeln(Format('FALHA [%s] icmsSt: esperado presente, obtido ausente', [AId]));
    end
    else
    begin
      Checar(AId, 'icmsSt.bc', AEsperado.IcmsSt.Bc, Obtido.IcmsSt.Bc);
      Checar(AId, 'icmsSt.valor', AEsperado.IcmsSt.Valor, Obtido.IcmsSt.Valor);
      Checar(AId, 'icmsSt.mvaAplicada', AEsperado.IcmsSt.MvaAplicada, Obtido.IcmsSt.MvaAplicada);
    end;
  end;

  if AEsperado.TemDifal then
  begin
    if not Obtido.TemDifal then
    begin
      Inc(TotalFalha);
      Writeln(Format('FALHA [%s] difal: esperado presente, obtido ausente', [AId]));
    end
    else
    begin
      Checar(AId, 'difal.valorDestino', AEsperado.Difal.ValorDestino, Obtido.Difal.ValorDestino);
      Checar(AId, 'difal.fcp', AEsperado.Difal.Fcp, Obtido.Difal.Fcp);
    end;
  end;
end;

{ ---- caso 1: icms-00-simples ---- }
procedure TesteIcms00Simples;
var
  Op: TOperacaoFiscal;
  Esp: TResultadoTributos;
begin
  Op := OperacaoBase;
  Esp := Default(TResultadoTributos);
  Esp.Icms.Bc := 1000; Esp.Icms.Aliquota := 18; Esp.Icms.Valor := 180;
  Esp.Ipi.Bc := 1000; Esp.Ipi.Valor := 0;
  Esp.Pis.Valor := 6.50;
  Esp.Cofins.Valor := 30;
  Esp.TotalTributos := 216.50;
  RodarCaso('icms-00-simples', Op, Esp);
end;

{ ---- caso 2: icms-20-reducao-bc ---- }
procedure TesteIcms20ReducaoBc;
var
  Op: TOperacaoFiscal;
  Esp: TResultadoTributos;
begin
  Op := OperacaoBase;
  Op.Item.Icms.Cst := '20';
  Op.Item.Icms.TemReducaoBC := True;
  Op.Item.Icms.ReducaoBC := 33.33;

  Esp := Default(TResultadoTributos);
  Esp.Icms.Bc := 666.70; Esp.Icms.Aliquota := 18; Esp.Icms.Valor := 120.01;
  Esp.Ipi.Bc := 1000; Esp.Ipi.Valor := 0;
  Esp.Pis.Valor := 6.50;
  Esp.Cofins.Valor := 30;
  Esp.TotalTributos := 156.51;
  RodarCaso('icms-20-reducao-bc', Op, Esp);
end;

{ ---- caso 3: icms-st-mva ---- }
procedure TesteIcmsStMva;
var
  Op: TOperacaoFiscal;
  Esp: TResultadoTributos;
begin
  Op := OperacaoBase;
  Op.Item.Frete := 50;
  Op.Item.Icms.Cst := '10';
  Op.Item.Icms.TemMva := True;
  Op.Item.Icms.Mva := 40;

  Esp := Default(TResultadoTributos);
  Esp.Icms.Bc := 1050; Esp.Icms.Aliquota := 18; Esp.Icms.Valor := 189;
  Esp.TemIcmsSt := True;
  Esp.IcmsSt.Bc := 1470; Esp.IcmsSt.Aliquota := 18; Esp.IcmsSt.Valor := 75.60; Esp.IcmsSt.MvaAplicada := 40;
  Esp.Ipi.Bc := 1050; Esp.Ipi.Valor := 0;
  Esp.Pis.Valor := 6.82;
  Esp.Cofins.Valor := 31.50;
  Esp.TotalTributos := 302.92;
  RodarCaso('icms-st-mva', Op, Esp);
end;

{ ---- caso 4: icms-st-mva-ajustada ---- }
procedure TesteIcmsStMvaAjustada;
var
  Op: TOperacaoFiscal;
  Esp: TResultadoTributos;
begin
  Op := OperacaoBase;
  Op.UfDestino := 'MG';
  Op.Item.Frete := 50;
  Op.Item.Icms.Cst := '10';
  Op.Item.Icms.AliquotaInterna := 18;
  Op.Item.Icms.AliquotaInterestadual := 12;
  Op.Item.Icms.TemMva := True;
  Op.Item.Icms.Mva := 40;

  Esp := Default(TResultadoTributos);
  Esp.Icms.Bc := 1050; Esp.Icms.Aliquota := 12; Esp.Icms.Valor := 126;
  Esp.TemIcmsSt := True;
  Esp.IcmsSt.Bc := 1577.52; Esp.IcmsSt.Aliquota := 18; Esp.IcmsSt.Valor := 157.95; Esp.IcmsSt.MvaAplicada := 50.24;
  Esp.Ipi.Bc := 1050; Esp.Ipi.Valor := 0;
  Esp.Pis.Valor := 6.82;
  Esp.Cofins.Valor := 31.50;
  Esp.TotalTributos := 322.27;
  RodarCaso('icms-st-mva-ajustada', Op, Esp);
end;

{ ---- caso 5: ipi-na-base-icms ---- }
procedure TesteIpiNaBaseIcms;
var
  Op: TOperacaoFiscal;
  Esp: TResultadoTributos;
begin
  Op := OperacaoBase;
  Op.UfDestino := 'RJ';
  Op.DestinatarioContribuinte := False;
  Op.Item.Icms.AliquotaInterna := 20;
  Op.Item.Icms.AliquotaInterestadual := 12;
  Op.Item.Ipi.Aliquota := 10;
  Op.Item.Ipi.IncluirNaBaseIcms := True;

  Esp := Default(TResultadoTributos);
  Esp.Icms.Bc := 1100; Esp.Icms.Aliquota := 12; Esp.Icms.Valor := 132;
  Esp.Ipi.Bc := 1000; Esp.Ipi.Valor := 100;
  Esp.Pis.Valor := 6.50;
  Esp.Cofins.Valor := 30;
  Esp.TemDifal := True;
  Esp.Difal.ValorDestino := 88; Esp.Difal.Fcp := 0;
  Esp.TotalTributos := 356.50;
  RodarCaso('ipi-na-base-icms', Op, Esp);
end;

{ ---- caso 6: difal-nao-contribuinte ---- }
procedure TesteDifalNaoContribuinte;
var
  Op: TOperacaoFiscal;
  Esp: TResultadoTributos;
begin
  Op := OperacaoBase;
  Op.UfDestino := 'RJ';
  Op.DestinatarioContribuinte := False;
  Op.Item.Icms.AliquotaInterna := 20;
  Op.Item.Icms.AliquotaInterestadual := 12;
  Op.Item.Icms.TemFcp := True;
  Op.Item.Icms.Fcp := 2;

  Esp := Default(TResultadoTributos);
  Esp.Icms.Bc := 1000; Esp.Icms.Aliquota := 12; Esp.Icms.Valor := 120;
  Esp.Ipi.Bc := 1000; Esp.Ipi.Valor := 0;
  Esp.Pis.Valor := 6.50;
  Esp.Cofins.Valor := 30;
  Esp.TemDifal := True;
  Esp.Difal.ValorDestino := 80; Esp.Difal.Fcp := 20;
  Esp.TotalTributos := 256.50;
  RodarCaso('difal-nao-contribuinte', Op, Esp);
end;

{ ---- caso 7: pis-cofins-cumulativo (identico ao caso 1) ---- }
procedure TestePisCofinsCumulativo;
var
  Op: TOperacaoFiscal;
  Esp: TResultadoTributos;
begin
  Op := OperacaoBase;
  Esp := Default(TResultadoTributos);
  Esp.Icms.Bc := 1000; Esp.Icms.Aliquota := 18; Esp.Icms.Valor := 180;
  Esp.Ipi.Bc := 1000; Esp.Ipi.Valor := 0;
  Esp.Pis.Valor := 6.50;
  Esp.Cofins.Valor := 30;
  Esp.TotalTributos := 216.50;
  RodarCaso('pis-cofins-cumulativo', Op, Esp);
end;

{ ---- caso 8: pis-cofins-nao-cumulativo ---- }
procedure TestePisCofinsNaoCumulativo;
var
  Op: TOperacaoFiscal;
  Esp: TResultadoTributos;
begin
  Op := OperacaoBase;
  Op.Item.PisCofins.Regime := rpcNaoCumulativo;
  Op.Item.PisCofins.AliquotaPis := 1.65;
  Op.Item.PisCofins.AliquotaCofins := 7.60;

  Esp := Default(TResultadoTributos);
  Esp.Icms.Bc := 1000; Esp.Icms.Aliquota := 18; Esp.Icms.Valor := 180;
  Esp.Ipi.Bc := 1000; Esp.Ipi.Valor := 0;
  Esp.Pis.Valor := 16.50;
  Esp.Cofins.Valor := 76;
  Esp.TotalTributos := 272.50;
  RodarCaso('pis-cofins-nao-cumulativo', Op, Esp);
end;

{ ---- caso 9: arredondamento-limite (prova o ROUND_HALF_EVEN de verdade) ---- }
procedure TesteArredondamentoLimite;
var
  Op: TOperacaoFiscal;
  Esp: TResultadoTributos;
begin
  Op := OperacaoBase;
  Op.Item.ValorProduto := 100;
  Op.Item.Icms.AliquotaInterna := 4.995;
  Op.Item.Icms.AliquotaInterestadual := 4.995;

  Esp := Default(TResultadoTributos);
  Esp.Icms.Bc := 100; Esp.Icms.Aliquota := 4.995; Esp.Icms.Valor := 5.00;
  Esp.Ipi.Bc := 100; Esp.Ipi.Valor := 0;
  Esp.Pis.Valor := 0.65;
  Esp.Cofins.Valor := 3.00;
  Esp.TotalTributos := 8.65;
  RodarCaso('arredondamento-limite', Op, Esp);
end;

{ ---- caso 10: icms-40-isento ---- }
procedure TesteIcms40Isento;
var
  Op: TOperacaoFiscal;
  Esp: TResultadoTributos;
begin
  Op := OperacaoBase;
  Op.Item.Icms.Cst := '40';
  Op.Item.Icms.AliquotaInterna := 0;
  Op.Item.Icms.AliquotaInterestadual := 0;

  Esp := Default(TResultadoTributos);
  Esp.Icms.Bc := 1000; Esp.Icms.Aliquota := 0; Esp.Icms.Valor := 0;
  Esp.Ipi.Bc := 1000; Esp.Ipi.Valor := 0;
  Esp.Pis.Valor := 6.50;
  Esp.Cofins.Valor := 30;
  Esp.TotalTributos := 36.50;
  RodarCaso('icms-40-isento', Op, Esp);
end;

{ ---- caso 11: base-frete-seguro-desconto ---- }
procedure TesteBaseFreteSeguroDesconto;
var
  Op: TOperacaoFiscal;
  Esp: TResultadoTributos;
begin
  Op := OperacaoBase;
  Op.Item.Frete := 100;
  Op.Item.Seguro := 20;
  Op.Item.Desconto := 50;
  Op.Item.Outras := 10;

  Esp := Default(TResultadoTributos);
  Esp.Icms.Bc := 1080; Esp.Icms.Aliquota := 18; Esp.Icms.Valor := 194.40;
  Esp.Ipi.Bc := 1080; Esp.Ipi.Valor := 0;
  Esp.Pis.Valor := 7.02;
  Esp.Cofins.Valor := 32.40;
  Esp.TotalTributos := 233.82;
  RodarCaso('base-frete-seguro-desconto', Op, Esp);
end;

begin
  TotalOK := 0;
  TotalFalha := 0;
  FormatoInvariante := DefaultFormatSettings;
  FormatoInvariante.DecimalSeparator := '.';
  FormatoInvariante.ThousandSeparator := ',';

  { Prova direta do banker's rounding do Round() nativo sobre Currency,
    a suposicao central de Tributos.Decimal.pas. }
  Checar('round-half-even-sanity', '4.995->5.00', 5.00, RoundHalfEven2(4.995));
  Checar('round-half-even-sanity', '4.985->4.98', 4.98, RoundHalfEven2(4.985));
  Checar('round-half-even-sanity', '0.005->0.00', 0.00, RoundHalfEven2(0.005));
  Checar('round-half-even-sanity', '0.015->0.02', 0.02, RoundHalfEven2(0.015));
  Checar('round-half-even-sanity', '1.025->1.02', 1.02, RoundHalfEven2(1.025));

  TesteIcms00Simples;
  TesteIcms20ReducaoBc;
  TesteIcmsStMva;
  TesteIcmsStMvaAjustada;
  TesteIpiNaBaseIcms;
  TesteDifalNaoContribuinte;
  TestePisCofinsCumulativo;
  TestePisCofinsNaoCumulativo;
  TesteArredondamentoLimite;
  TesteIcms40Isento;
  TesteBaseFreteSeguroDesconto;

  Writeln;
  Writeln(Format('%d verificacoes OK, %d falha(s).', [TotalOK, TotalFalha]));
  if TotalFalha > 0 then
    ExitCode := 1;
end.
