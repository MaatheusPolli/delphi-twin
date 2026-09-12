unit Tests.Ipi;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestIpi = class
  public
    [Test]
    procedure Calcular_AplicaAliquotaSobreValorProdutoMaisDespesas;
    [Test]
    procedure Calcular_AliquotaZero_ResultaEmImpostoZero;
    [Test]
    procedure Calcular_DescontaValorDoDescontoIncondicional;
  end;

implementation

uses
  Tributos.Types,
  Tributos.Ipi,
  Tests.Helpers;

procedure TTestIpi.Calcular_AplicaAliquotaSobreValorProdutoMaisDespesas;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraIpi;
  Resultado: TTributoBase;
begin
  Operacao := OperacaoPadrao;
  Operacao.Item.Frete := 100;
  Operacao.Item.Ipi.Aliquota := 10;

  Calculadora := TCalculadoraIpi.Create;
  Resultado := Calculadora.Calcular(Operacao);

  Assert.AreEqual(Currency(1100.00), Resultado.Bc);
  Assert.AreEqual(Currency(110.00), Resultado.Valor);
end;

procedure TTestIpi.Calcular_AliquotaZero_ResultaEmImpostoZero;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraIpi;
  Resultado: TTributoBase;
begin
  Operacao := OperacaoPadrao;

  Calculadora := TCalculadoraIpi.Create;
  Resultado := Calculadora.Calcular(Operacao);

  Assert.AreEqual(Currency(0.00), Resultado.Valor);
end;

procedure TTestIpi.Calcular_DescontaValorDoDescontoIncondicional;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraIpi;
  Resultado: TTributoBase;
begin
  Operacao := OperacaoPadrao;
  Operacao.Item.Desconto := 100;
  Operacao.Item.Ipi.Aliquota := 10;

  Calculadora := TCalculadoraIpi.Create;
  Resultado := Calculadora.Calcular(Operacao);

  Assert.AreEqual(Currency(900.00), Resultado.Bc);
  Assert.AreEqual(Currency(90.00), Resultado.Valor);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestIpi);

end.
