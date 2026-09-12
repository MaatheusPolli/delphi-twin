unit Tests.Icms;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestIcms = class
  public
    [Test]
    procedure Calcular_OperacaoSimples_AplicaAliquotaInternaSobreValorProduto;
    [Test]
    procedure Calcular_ComReducaoBC_ReduzABaseAntesDoImposto;
    [Test]
    procedure Calcular_OperacaoInterestadual_UsaAliquotaInterestadual;
    [Test]
    procedure Calcular_IpiComposBaseIcms_QuandoSinalizado;
    [Test]
    procedure Calcular_AliquotaZero_ResultaEmImpostoZero;
  end;

implementation

uses
  Tributos.Types,
  Tributos.Icms,
  Tests.Helpers;

procedure TTestIcms.Calcular_OperacaoSimples_AplicaAliquotaInternaSobreValorProduto;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraIcms;
  Resultado: TTributoBase;
begin
  Operacao := OperacaoPadrao;
  Calculadora := TCalculadoraIcms.Create;
  Resultado := Calculadora.Calcular(Operacao, 0);

  Assert.AreEqual(Currency(1000.00), Resultado.Bc);
  Assert.AreEqual(Currency(18.00), Resultado.Aliquota);
  Assert.AreEqual(Currency(180.00), Resultado.Valor);
end;

procedure TTestIcms.Calcular_ComReducaoBC_ReduzABaseAntesDoImposto;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraIcms;
  Resultado: TTributoBase;
begin
  Operacao := OperacaoPadrao;
  Operacao.Item.Icms.TemReducaoBC := True;
  Operacao.Item.Icms.ReducaoBC := 33.33;

  Calculadora := TCalculadoraIcms.Create;
  Resultado := Calculadora.Calcular(Operacao, 0);

  Assert.AreEqual(Currency(666.70), Resultado.Bc);
  Assert.AreEqual(Currency(120.01), Resultado.Valor);
end;

procedure TTestIcms.Calcular_OperacaoInterestadual_UsaAliquotaInterestadual;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraIcms;
  Resultado: TTributoBase;
begin
  Operacao := OperacaoPadrao;
  Operacao.UfDestino := 'MG';
  Operacao.Item.Icms.AliquotaInterna := 18;
  Operacao.Item.Icms.AliquotaInterestadual := 12;

  Calculadora := TCalculadoraIcms.Create;
  Resultado := Calculadora.Calcular(Operacao, 0);

  Assert.AreEqual(Currency(12.00), Resultado.Aliquota);
  Assert.AreEqual(Currency(120.00), Resultado.Valor);
end;

procedure TTestIcms.Calcular_IpiComposBaseIcms_QuandoSinalizado;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraIcms;
  Resultado: TTributoBase;
begin
  Operacao := OperacaoPadrao;
  Operacao.UfDestino := 'RJ';
  Operacao.DestinatarioContribuinte := False;
  Operacao.Item.Icms.AliquotaInterna := 20;
  Operacao.Item.Icms.AliquotaInterestadual := 12;
  Operacao.Item.Ipi.Aliquota := 10;
  Operacao.Item.Ipi.IncluirNaBaseIcms := True;

  Calculadora := TCalculadoraIcms.Create;
  Resultado := Calculadora.Calcular(Operacao, 100.00);

  Assert.AreEqual(Currency(1100.00), Resultado.Bc);
  Assert.AreEqual(Currency(132.00), Resultado.Valor);
end;

procedure TTestIcms.Calcular_AliquotaZero_ResultaEmImpostoZero;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraIcms;
  Resultado: TTributoBase;
begin
  Operacao := OperacaoPadrao;
  Operacao.Item.Icms.Cst := '40';
  Operacao.Item.Icms.AliquotaInterna := 0;
  Operacao.Item.Icms.AliquotaInterestadual := 0;

  Calculadora := TCalculadoraIcms.Create;
  Resultado := Calculadora.Calcular(Operacao, 0);

  Assert.AreEqual(Currency(0.00), Resultado.Valor);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestIcms);

end.
