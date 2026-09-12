unit Tests.Decimal;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDecimal = class
  public
    [Test]
    procedure RoundHalfEven2_ArredondaParaBaixoQuandoAbaixoDoMeio;
    [Test]
    procedure RoundHalfEven2_ArredondaParaCimaQuandoAcimaDoMeio;
    [Test]
    [TestCase('4.995 -> 5.00 (par)', '4.995,5.00')]
    [TestCase('4.985 -> 4.98 (par)', '4.985,4.98')]
    [TestCase('0.005 -> 0.00 (par)', '0.005,0.00')]
    [TestCase('0.015 -> 0.02 (par)', '0.015,0.02')]
    [TestCase('1.025 -> 1.02 (par)', '1.025,1.02')]
    procedure RoundHalfEven2_EmpateExatoVaiParaOVizinhoPar(const AEntrada, AEsperado: string);
    [Test]
    procedure AplicarPercentual_CalculaProporcaoSimples;
    [Test]
    procedure AplicarPercentual_ZeroPorCentoResultaEmZero;
  end;

implementation

uses
  System.SysUtils,
  Tributos.Decimal;

procedure TTestDecimal.RoundHalfEven2_ArredondaParaBaixoQuandoAbaixoDoMeio;
begin
  Assert.AreEqual(Currency(10.12), RoundHalfEven2(10.124));
end;

procedure TTestDecimal.RoundHalfEven2_ArredondaParaCimaQuandoAcimaDoMeio;
begin
  Assert.AreEqual(Currency(10.13), RoundHalfEven2(10.126));
end;

procedure TTestDecimal.RoundHalfEven2_EmpateExatoVaiParaOVizinhoPar(const AEntrada, AEsperado: string);
var
  Entrada, Esperado: Currency;
begin
  Entrada := StrToCurr(AEntrada, TFormatSettings.Invariant);
  Esperado := StrToCurr(AEsperado, TFormatSettings.Invariant);
  Assert.AreEqual(Esperado, RoundHalfEven2(Entrada));
end;

procedure TTestDecimal.AplicarPercentual_CalculaProporcaoSimples;
begin
  Assert.AreEqual(Currency(18), AplicarPercentual(100, 18));
end;

procedure TTestDecimal.AplicarPercentual_ZeroPorCentoResultaEmZero;
begin
  Assert.AreEqual(Currency(0), AplicarPercentual(1000, 0));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDecimal);

end.
