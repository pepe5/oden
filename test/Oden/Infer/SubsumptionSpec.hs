module Oden.Infer.SubsumptionSpec where

import           Data.Map
import           Test.Hspec

import           Oden.Infer.Subsumption
import           Oden.Infer.Substitution
import           Oden.SourceInfo
import           Oden.Core
import           Oden.Identifier
import           Oden.Type.Basic
import           Oden.Type.Polymorphic

import           Oden.Assertions


tvarA :: Type
tvarA = TVar Predefined (TV "a")

tvarB :: Type
tvarB = TVar Predefined (TV "b")

tvarC :: Type
tvarC = TVar Predefined (TV "c")

scheme:: Type -> Scheme
scheme= Forall Predefined []

typeUnit, typeAny, typeInt, typeString :: Type
typeUnit = TUnit Predefined
typeAny = TAny Predefined
typeInt = TBasic Predefined TInt
typeString = TBasic Predefined TString

typeFn :: Type -> Type -> Type
typeFn = TFn Missing

spec :: Spec
spec = do

  describe "subsume" $ do

    it "any subsume any" $
      scheme typeAny `subsume` Literal Predefined Unit typeAny
      `shouldSucceedWith`
      (scheme typeAny, Literal Predefined Unit typeAny)

    it "any subsume int" $
      scheme typeAny `subsume` Literal Predefined Unit typeUnit
      `shouldSucceedWith`
      (scheme typeAny, Literal Predefined Unit typeUnit)

    it "int does not subsume any" $
      shouldFail (scheme typeInt `subsume` Literal Predefined Unit typeAny)

    it "tvar does not subsume any" $
      shouldFail (scheme tvarA `subsume` Literal Predefined Unit typeAny)

    it "any subsume tvar" $
      scheme typeAny `subsume` Literal Predefined Unit tvarA
      `shouldSucceedWith`
      (scheme typeAny, Literal Predefined Unit typeAny)

    it "tvar subsume same tvar" $
      scheme tvarA `subsume` Literal Predefined Unit tvarA
      `shouldSucceedWith`
      (scheme tvarA, Literal Predefined Unit tvarA)

    it "tvar subsumes and substitutes other tvars" $
      scheme tvarB `subsume` Literal Predefined Unit tvarA
      `shouldSucceedWith`
      (scheme tvarB, Literal Predefined Unit tvarB)

    it "int subsumes same int" $
      scheme typeInt `subsume` Literal Predefined (Int 1) typeInt
      `shouldSucceedWith`
      (scheme typeInt, Literal Predefined (Int 1) typeInt)

    it "string subsumes same string" $
      scheme typeString `subsume` Literal Predefined (String "foo") typeString
      `shouldSucceedWith`
      (scheme typeString, Literal Predefined (String "foo") typeString)

    it "string does not subsume int" $
      shouldFail (scheme typeString `subsume` Literal Predefined (Int 1) typeInt)

    it "int does not subsume string" $
      shouldFail (scheme typeInt `subsume` Literal Predefined (String "foo") typeString)

    it "tcon subsume same tcon" $
      let foo = TCon Missing "foo" in do
        scheme foo `subsume` Literal Predefined (String "foo") foo
        `shouldSucceedWith`
        (scheme foo, Literal Predefined (String "foo") foo)

    it "tcon does not subsume other tcons" $
      let foo = TCon Missing "foo"
          bar = TCon Missing "bar"
      in shouldFail (scheme foo `subsume` Literal Predefined Unit bar)

    it "TFn of TVars subsume same TFn" $
      let expr tv = Fn Predefined
                    (Binding Missing "x")
                    (Symbol Missing (Unqualified "x") tv) (typeFn tv tv) in do
        scheme (typeFn tvarA tvarA) `subsume` expr tvarB
        `shouldSucceedWith`
        (scheme (typeFn tvarA tvarA), expr tvarA)

    it "TFn of different types does not subsume" $
      let expr = Fn Predefined
                    (Binding Missing "x")
                    (Symbol Missing (Unqualified "x") tvarA) (typeFn tvarA tvarA)
      in shouldFail (scheme (typeFn typeString typeInt) `subsume` expr)

    {-it "TVar does not subsume TFn" $-}
      {-shouldFail (tvarA `subsume` TFn Predefined tvarB tvarB)-}

    {-it "tuple of tvars subsumes tuple of same tvars" $-}
      {-TTuple Predefined tvarA tvarA [] `subsume` TTuple Predefined tvarA tvarA []-}
      {-`shouldSucceedWith`-}
      {-TTuple Predefined tvarA tvarA []-}

    {-it "tvar slice subsumes same tvar slice" $-}
      {-TSlice Predefined tvarA `subsume` TSlice Predefined tvarA-}
      {-`shouldSucceedWith`-}
      {-TSlice Predefined tvarA-}
