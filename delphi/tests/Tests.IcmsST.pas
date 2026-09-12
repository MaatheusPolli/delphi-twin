unit Tests.IcmsST;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestIcmsST = class
  public
    [Test]
    procedure Calcular_OperacaoInterna_NaoAjustaMva;
    [Test]
    procedure Calcular_OperacaoInterestadual_AjustaMvaPelaFormulaDoConvenio52;
    [Test]
    procedure Calcular_ValorST_SubtraiIcmsProprioDaBaseXAliquota;
    [Test]
    procedure Calcular_AliquotaInternaCemPorCento_LancaExcecao;
  end;

implementation

uses
  SysUtils,
  Tributos.Types,
  Tributos.IcmsST,
  Tests.Helpers;

procedure TTestIcmsST.Calcular_OperacaoInterna_NaoAjustaMva;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraIcmsST;
  Resultado: TResultadoIcmsSt;
begin
  Operacao := OperacaoPadrao;
  Operacao.Item.Icms.TemMva := True;
  Operacao.Item.Icms.Mva := 40;
  Operacao.Item.Frete := 50;

  Calculadora := TCalculadoraIcmsST.Create;
  Resultado := Calculadora.Calcular(Operacao, 0, 189.00);

  Assert.AreEqual(Currency(40.00), Resultado.MvaAplicada);
  Assert.AreEqual(Currency(1470.00), Resultado.Bc);
end;

procedure TTestIcmsST.Calcular_OperacaoInterestadual_AjustaMvaPelaFormulaDoConvenio52;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraIcmsST;
  Resultado: TResultadoIcmsSt;
begin
  { Exemplo classico de literatura tributaria: MVA original 40%, aliquota
    interna do destino 18%, aliquota interestadual 12% => MVA ajustada 50.24%. }
  Operacao := OperacaoPadrao;
  Operacao.UfDestino := 'MG';
  Operacao.Item.Icms.TemMva := True;
  Operacao.Item.Icms.Mva := 40;
  Operacao.Item.Icms.AliquotaInterna := 18;
  Operacao.Item.Icms.AliquotaInterestadual := 12;
  Operacao.Item.Frete := 50;

  Calculadora := TCalculadoraIcmsST.Create;
  Resultado := Calculadora.Calcular(Operacao, 0, 126.00);

  Assert.AreEqual(Currency(50.24), Resultado.MvaAplicada);
  Assert.AreEqual(Currency(1577.52), Resultado.Bc);
end;

procedure TTestIcmsST.Calcular_ValorST_SubtraiIcmsProprioDaBaseXAliquota;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraIcmsST;
  Resultado: TResultadoIcmsSt;
begin
  Operacao := OperacaoPadrao;
  Operacao.UfDestino := 'MG';
  Operacao.Item.Icms.TemMva := True;
  Operacao.Item.Icms.Mva := 40;
  Operacao.Item.Icms.AliquotaInterna := 18;
  Operacao.Item.Icms.AliquotaInterestadual := 12;
  Operacao.Item.Frete := 50;

  Calculadora := TCalculadoraIcmsST.Create;
  Resultado := Calculadora.Calcular(Operacao, 0, 126.00);

  Assert.AreEqual(Currency(157.95), Resultado.Valor);
end;

procedure TTestIcmsST.Calcular_AliquotaInternaCemPorCento_LancaExcecao;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraIcmsST;
begin
  { Aliquota interna >= 100% zeraria o denominador da formula de MVA
    ajustada. Deve lancar um erro claro em vez de EZeroDivide sem contexto
    (ou, no lado TypeScript, propagar Infinity silenciosamente - ver
    icms-st.ts). }
  Operacao := OperacaoPadrao;
  Operacao.UfDestino := 'MG';
  Operacao.Item.Icms.TemMva := True;
  Operacao.Item.Icms.Mva := 40;
  Operacao.Item.Icms.AliquotaInterna := 100;
  Operacao.Item.Icms.AliquotaInterestadual := 12;

  Calculadora := TCalculadoraIcmsST.Create;
  Assert.WillRaise(
    procedure
    begin
      Calculadora.Calcular(Operacao, 0, 126.00);
    end,
    Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestIcmsST);

end.
