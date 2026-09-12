unit Tests.Difal;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDifal = class
  public
    [Test]
    procedure Aplicavel_InterestadualNaoContribuinte_RetornaTrue;
    [Test]
    procedure Aplicavel_Interna_RetornaFalse;
    [Test]
    procedure Aplicavel_InterestadualContribuinte_RetornaFalse;
    [Test]
    procedure Calcular_ValorDestinoIntegral_ComFcp;
  end;

implementation

uses
  Tributos.Types,
  Tributos.Difal,
  Tests.Helpers;

procedure TTestDifal.Aplicavel_InterestadualNaoContribuinte_RetornaTrue;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraDifal;
begin
  Operacao := OperacaoPadrao;
  Operacao.UfDestino := 'RJ';
  Operacao.DestinatarioContribuinte := False;

  Calculadora := TCalculadoraDifal.Create;
  Assert.IsTrue(Calculadora.Aplicavel(Operacao));
end;

procedure TTestDifal.Aplicavel_Interna_RetornaFalse;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraDifal;
begin
  Operacao := OperacaoPadrao;
  Operacao.DestinatarioContribuinte := False;

  Calculadora := TCalculadoraDifal.Create;
  Assert.IsFalse(Calculadora.Aplicavel(Operacao));
end;

procedure TTestDifal.Aplicavel_InterestadualContribuinte_RetornaFalse;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraDifal;
begin
  Operacao := OperacaoPadrao;
  Operacao.UfDestino := 'RJ';
  Operacao.DestinatarioContribuinte := True;

  Calculadora := TCalculadoraDifal.Create;
  Assert.IsFalse(Calculadora.Aplicavel(Operacao));
end;

procedure TTestDifal.Calcular_ValorDestinoIntegral_ComFcp;
var
  Operacao: TOperacaoFiscal;
  Calculadora: ICalculadoraDifal;
  Resultado: TResultadoDifal;
begin
  Operacao := OperacaoPadrao;
  Operacao.UfDestino := 'RJ';
  Operacao.DestinatarioContribuinte := False;
  Operacao.Item.Icms.AliquotaInterna := 20;
  Operacao.Item.Icms.AliquotaInterestadual := 12;
  Operacao.Item.Icms.TemFcp := True;
  Operacao.Item.Icms.Fcp := 2;

  Calculadora := TCalculadoraDifal.Create;
  Resultado := Calculadora.Calcular(Operacao, 1000.00);

  Assert.AreEqual(Currency(0.00), Resultado.ValorOrigem);
  Assert.AreEqual(Currency(80.00), Resultado.ValorDestino);
  Assert.AreEqual(Currency(20.00), Resultado.Fcp);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDifal);

end.
