with Ada.Numerics.Float_Random;         use Ada.Numerics.Float_Random;
with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Text_IO;

package body HAC_Pack is

  package REF is new Ada.Numerics.Generic_Elementary_Functions(Real);

  function "**" (f1, f2 : Real) return Real is
  begin
    return REF."**" (f1, f2);
  end;

  function Sqrt (I : Integer) return Real is
  begin
    return REF.Sqrt(Real(I));
  end Sqrt;

  function Sqrt (F : Real) return Real is
  begin
    return REF.Sqrt(F);
  end Sqrt;

  function Odd (I : Integer) return Boolean is
  begin
    return I mod 2 = 1;
  end Odd;

  function ASCII (I : Integer) return Character is
  begin
    return Character'Val(I);
  end ASCII;

  function Ord (C : Character) return Integer is
  begin
    return Character'Pos(C);
  end Ord;

  function Succ (C : Character) return Character is
  begin
    return Character'Succ (C);
  end Succ;

  function Pred (C : Character) return Character is
  begin
    return Character'Pred (C);
  end Pred;

  function Round (F : Real) return Integer is
  begin
    return Integer(F);
  end Round;

  function Trunc (F : Real) return Integer is
  begin
    return Integer(Real'Floor(F));
  end Trunc;

  function Sin (F : Real) return Real is
  begin
    return REF.Sin(F);
  end Sin;

  function Cos (F : Real) return Real is
  begin
    return REF.Cos(F);
  end Cos;

  function Arctan (F : Real) return Real is
  begin
    return REF.Arctan(F);
  end Arctan;

  function Log (F : Real) return Real is
  begin
    return REF.Log(F);
  end Log;

  function Exp (F : Real) return Real is
  begin
    return REF.Exp(F);
  end Exp;

  function Rand (I : Integer) return Integer is
  begin
    return Trunc (Rnd * Real(I + 1));
  end Rand;

  gen: Generator;

  function Rnd return Real is
  begin
    return Real (Random (gen));
  end Rnd;

  package IIO is new Ada.Text_IO.Integer_IO(Integer);
  package RIO is new Ada.Text_IO.Float_IO(Real);
  package BIO is new Ada.Text_IO.Enumeration_IO(Boolean);

   ---------
   -- GET --
   ---------

  procedure Get (C : out Character) is
  begin
    Ada.Text_IO.Get(C);
  end Get;

   ---------
   -- GET --
   ---------

  procedure Get (I : out Integer) is
  pragma Unreferenced (I);
  begin
      --  Generated stub: replace with real body!
    pragma Compile_Time_Warning (Standard.True, "GET unimplemented");
    raise Program_Error;
  end Get;

   ---------
   -- GET --
   ---------

  procedure Get (F : out Real) is
  pragma Unreferenced (F);
  begin
      --  Generated stub: replace with real body!
    pragma Compile_Time_Warning (Standard.True, "GET unimplemented");
    raise Program_Error;
  end Get;

   ---------
   -- GET --
   ---------

  procedure Get (B : out Boolean) is
  pragma Unreferenced (B);
  begin
      --  Generated stub: replace with real body!
    pragma Compile_Time_Warning (Standard.True, "GET unimplemented");
    raise Program_Error;
  end Get;

   --------------
   -- GET_LINE --
   --------------

  procedure Get_Line (C : out Character) is
  pragma Unreferenced (C);
  begin
      --  Generated stub: replace with real body!
    pragma Compile_Time_Warning (Standard.True, "GET_LINE unimplemented");
    raise Program_Error;
  end Get_Line;

   --------------
   -- GET_LINE --
   --------------

  procedure Get_Line (I : out Integer) is
  pragma Unreferenced (I);
  begin
      --  Generated stub: replace with real body!
    pragma Compile_Time_Warning (Standard.True, "GET_LINE unimplemented");
    raise Program_Error;
  end Get_Line;

   --------------
   -- GET_LINE --
   --------------

  procedure Get_Line (F : out Real) is
  pragma Unreferenced (F);
  begin
      --  Generated stub: replace with real body!
    pragma Compile_Time_Warning (Standard.True, "GET_LINE unimplemented");
    raise Program_Error;
  end Get_Line;

   --------------
   -- GET_LINE --
   --------------

  procedure Get_Line (B : out Boolean) is
  pragma Unreferenced (B);
  begin
      --  Generated stub: replace with real body!
    pragma Compile_Time_Warning (Standard.True, "GET_LINE unimplemented");
    raise Program_Error;
  end Get_Line;

   ---------
   -- PUT --
   ---------

  procedure Put (C : in  Character) is
  begin
    Ada.Text_IO.Put(C);
  end Put;

  procedure Put (I : in  Integer) is
  begin
    IIO.Put(I);
  end Put;

  procedure Put (I : in  Integer; W:  Width) is
  begin
    IIO.Put(I, W);
  end Put;

  procedure Put (F : in  Real) is
  begin
    RIO.Put(F);
  end Put;

  procedure Put (F : in  Real; W:  Width; D : Decimals) is
  begin
    RIO.Put(F,W,D);
  end Put;

  procedure Put (B : in  Boolean) is
  begin
    BIO.Put(B);
  end Put;

  procedure Put (S : in  String) is
  begin
    Ada.Text_IO.Put(S);
  end Put;

  procedure Put (V : in  VString) is
  begin
    Put (Ada.Strings.Unbounded.To_String (V));
  end Put;

   --------------
   -- PUT_LINE --
   --------------

  procedure Put_Line (C : in  Character) is
  begin
    Put(C); New_Line;
  end Put_Line;

  procedure Put_Line (I : in  Integer) is
  begin
    Put(I); New_Line;
  end Put_Line;

  procedure Put_Line (I : in  Integer; W:  Width) is
  begin
    Put(I,W); New_Line;
  end Put_Line;

  procedure Put_Line (F : in  Real) is
  begin
    Put(F); New_Line;
  end Put_Line;

  procedure Put_Line (F : in  Real; W:  Width; D : Decimals) is
  begin
    Put(F,W,D); New_Line;
  end Put_Line;

  procedure Put_Line (B : in  Boolean) is
  begin
    Put(B); New_Line;
  end Put_Line;

  procedure Put_Line (S : in  String) is
  begin
    Ada.Text_IO.Put_Line(S);
  end Put_Line;

  procedure Put_Line (V : in  VString) is
  begin
    Put_Line (Ada.Strings.Unbounded.To_String (V));
  end Put_Line;

   --------------
   -- NEW_LINE --
   --------------

  procedure New_Line is
  begin
    Ada.Text_IO.New_Line;
  end New_Line;

  procedure  CursorAt (X, Y: Integer) is
  begin
    null; -- !!
  end;

   ----------
   -- WAIT --
   ----------

  procedure Wait (S : Semaphore) is
  pragma Unreferenced (S);
  begin
      --  Generated stub: replace with real body!
    pragma Compile_Time_Warning (Standard.True, "WAIT unimplemented");
    raise Program_Error;
  end Wait;

   ------------
   -- SIGNAL --
   ------------

  procedure Signal (S : Semaphore) is
  pragma Unreferenced (S);
  begin
      --  Generated stub: replace with real body!
    pragma Compile_Time_Warning (Standard.True, "SIGNAL unimplemented");
    raise Program_Error;
  end Signal;

begin
  Reset (gen);  --  Randomize.
end HAC_Pack;
