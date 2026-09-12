unit Tests.PisCofins;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestPisCofins = class
  public
    [Test]
    procedure Calcular_RegimeCumulativo_AplicaAliquotasPadrao;
    [Test]
    procedure Calcular_RegimeNaoCumulativo_AplicaAliquotasMaiores;
  end;

implementation

uses
  Tributos.Types,
  Tributos.PisCofins,
  Tests.Helpers;

procedure TTestPisCofins.Calcular_RegimeCumulativo_AplicaAliquotasPadrao;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraPisCofins;
  Pis, Cofins: TTributoBase;
begin
  Operacao := OperacaoPadrao;
  Operacao.Item.PisCofins.Regime := rpcCumulativo;
  Operacao.Item.PisCofins.AliquotaPis := 0.65;
  Operacao.Item.PisCofins.AliquotaCofins := 3;

  Calculadora := TCalculadoraPisCofins.Create;
  Pis := Calculadora.CalcularPis(Operacao);
  Cofins := Calculadora.CalcularCofins(Operacao);

  Assert.AreEqual(Currency(1000.00), Pis.Bc);
  Assert.AreEqual(Currency(6.50), Pis.Valor);
  Assert.AreEqual(Currency(30.00), Cofins.Valor);
end;

procedure TTestPisCofins.Calcular_RegimeNaoCumulativo_AplicaAliquotasMaiores;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraPisCofins;
  Pis, Cofins: TTributoBase;
begin
  Operacao := OperacaoPadrao;
  Operacao.Item.PisCofins.Regime := rpcNaoCumulativo;
  Operacao.Item.PisCofins.AliquotaPis := 1.65;
  Operacao.Item.PisCofins.AliquotaCofins := 7.6;

  Calculadora := TCalculadoraPisCofins.Create;
  Pis := Calculadora.CalcularPis(Operacao);
  Cofins := Calculadora.CalcularCofins(Operacao);

  Assert.AreEqual(Currency(16.50), Pis.Valor);
  Assert.AreEqual(Currency(76.00), Cofins.Valor);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPisCofins);

end.
