module Oden.Compiler.LiteralEvalSpec where

import           Test.Hspec

import           Oden.Compiler.LiteralEval

import           Oden.Core.Expr
import           Oden.Core.Typed

import           Oden.Identifier
import           Oden.Metadata
import           Oden.Predefined
import           Oden.QualifiedName
import           Oden.SourceInfo
import           Oden.Type.Polymorphic

missing :: Metadata SourceInfo
missing = Metadata Missing

int :: Integer -> TypedExpr
int n = Literal missing (Int n) typeInt

true :: TypedExpr
true = Literal missing (Bool True) typeBool

false :: TypedExpr
false = Literal missing (Bool False) typeBool

binaryOp :: TypedExpr -> TypedExpr -> TypedExpr -> TypedExpr
binaryOp f lhs rhs =
  case typeOf f of
    TFn _ _ (TFn _ rhsType range) ->
      Application missing (Application missing f lhs (TFn missing rhsType range)) rhs range
    _ -> error "Cannot use non-function type as function in binary application"

binaryMethodReference protocol method opType rangeType =
  MethodReference
  missing
  (Unresolved
   (nameInUniverse protocol)
   (Identifier method)
   (ProtocolConstraint missing (nameInUniverse protocol) opType))
  (TFn missing opType (TFn missing opType rangeType))


add = binaryMethodReference "Num" "Add" typeInt typeInt
subtract' = binaryMethodReference "Num" "Subtract" typeInt typeInt
multiply = binaryMethodReference "Num" "Multiply" typeInt typeInt
divide = binaryMethodReference "Num" "Divide" typeInt typeInt
or' = binaryMethodReference "Logical" "Disjunction" typeBool typeBool
and' = binaryMethodReference "Logical" "Conjunction" typeBool typeBool
lessThan = binaryMethodReference "Ordered" "LessThan" typeInt typeBool
greaterThan = binaryMethodReference "Ordered" "GreaterThan" typeInt typeBool
equals = binaryMethodReference "Equality" "EqualTo" typeInt typeInt

spec :: Spec
spec =
  describe "evaluate" $ do

    it "evaluates integer literals" $
      evaluate (int 5) `shouldBe` Just (Int 5)

    it "evaluates addition" $
      evaluate (binaryOp add (int 2) (int 3)) `shouldBe` Just (Int 5)

    it "evaluates nested binary expressions: (3-2)*4 + 10/2" $
      evaluate (binaryOp
                add
                (binaryOp
                 multiply
                 (binaryOp
                  subtract'
                  (int 3)
                  (int 2))
                 (int 4))
                (binaryOp divide (int 10) (int 2)))
      `shouldBe`
      Just (Int 9)

    it "evaluates boolean literals" $
      evaluate true `shouldBe` Just (Bool True)

    it "evaluates boolean expression: (true || false) && true" $
      evaluate (binaryOp
                and'
                (binaryOp
                 or'
                 true
                 false)
                true)
      `shouldBe`
      Just (Bool True)

    it "evaluates single integer comparison: (3 < 5)" $
      evaluate (binaryOp lessThan (int 3) (int 5))
      `shouldBe`
      Just (Bool True)

    it "evaluates integer comparison: (3 < 5) && (10 > 8)" $
      evaluate (binaryOp
                and'
                 (binaryOp lessThan (int 3) (int 5))
                 (binaryOp greaterThan (int 10) (int 8)))
      `shouldBe`
      Just (Bool True)

    it "evaluates if-expressions: if 2 == 3 then 1 else 2" $
      evaluate (If missing (binaryOp equals (int 2) (int 3))
                           (int 1)
                           (int 2)
                   typeInt)
      `shouldBe`
      Just (Int 2)

    it "evaluates expressions with variables to Nothing" $
      evaluate (binaryOp
                add
                (int 5)
                (Symbol missing (Identifier "x") typeInt))
      `shouldBe`
      Nothing
