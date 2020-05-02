-------------------------------------------------------------------------------------
--
--  HAC - HAC Ada Compiler
--
--  A compiler in Ada for an Ada subset
--
--  Copyright, license, etc. : see top package.
--
-------------------------------------------------------------------------------------
--

with HAC.Data;                          use HAC.Data;

package HAC.Parser.Helpers is

  use HAC.Compiler;

  ----------------------
  --  Symbol testing  --
  ----------------------

  --  If needed symbol S is correct, consume it;
  --  otherwise output error code E.
  --
  --  Optionally, we consume a symbol Forgive that
  --  the programmer may have written instead of S.
  --  For instance '[' instead of '('.
  --
  procedure Need (
    CD      : in out Compiler_Data;
    S       : KeyWSymbol;
    E       : Compile_Error;
    Forgive : KeyWSymbol := Dummy_Symbol
  );

  --  Issue error N, then skip all subsequent symbols
  --  that are not in the FSys set.
  --
  procedure Skip (
    CD   : in out Compiler_Data;
    FSys : Symset;
    N    : Compile_Error;
    hint : String := ""
  );

  --  Issue error N, then skip all subsequent symbols
  --  that are not equal to S.
  --
  procedure Skip (
    CD   : in out Compiler_Data;
    S    : KeyWSymbol;
    N    : Compile_Error;
    hint : String := ""
  );

  --  Test if current symbol is in the S1 set, otherwise
  --  issue error N. If stop_on_error = False, we skip
  --  subsequent symbols that are not in the union (S1 + S2).
  --
  procedure Test (
    CD            : in out Compiler_Data;
    S1, S2        : Symset;
    N             : Compile_Error;
    stop_on_error : Boolean:= False);

  procedure Test_Semicolon (CD : in out Compiler_Data; FSys : Symset);

  procedure Test_END_Symbol (CD : in out Compiler_Data);

  procedure Check_Boolean (CD : in out Compiler_Data; T: Typs);

  procedure Ignore_Extra_Semicolons (CD : in out Compiler_Data);

  type Type_Conversion_Kind is (To_Float, To_Integer, Unknown);

  procedure Argument_Type_Not_Supported (CD : in out Compiler_Data);

  --  https://en.wikipedia.org/wiki/Type_conversion#Implicit_type_conversion
  --  One of the most useful feature of Ada is the absence of type coercion.
  --
  procedure Forbid_Type_Coercion (CD : in out Compiler_Data; details: String);

  No_Id : constant := 0;

  ------------------------------------
  --  Symbol sets used for parsing  --
  ------------------------------------

  --  Singletons:

  function Singleton (s : KeyWSymbol) return Symset;
  pragma Inline (Singleton);

  --  Specific singletons:

  Colon_Set     : constant Symset := (Colon      => True, others => False);
  END_Set       : constant Symset := (END_Symbol => True, others => False);
  IDent_Set     : constant Symset := (IDent      => True, others => False);
  RParent_Set   : constant Symset := (RParent    => True, others => False);
  Semicolon_Set : constant Symset := (Semicolon  => True, others => False);

  --  Specific sets:

  Alt_Finger : constant Symset :=
    (Alt | Finger => True, others => False);

  Becomes_Comma_IDent_Semicolon : constant Symset :=
    (Semicolon | Comma | IDent | Becomes => True, others => False);

  Becomes_EQL_Semicolon : constant Symset :=
    (Becomes | EQL | Semicolon => True, others => False);

  Becomes_EQL : constant Symset :=
    (Becomes | EQL => True, others => False);

  Colon_Comma_LParent_RParent_Semicolon : constant Symset :=
    (Colon | Comma | LParent | RParent | Semicolon => True, others => False);

  Colon_Comma_RParent : constant Symset :=
    (Colon | Comma | RParent => True, others => False);

  Colon_Comma_IS_OF : constant Symset :=
    (Colon | Comma | IS_Symbol | OF_Symbol => True, others => False);

  Comma_END_IDent_Semicolon : constant Symset :=
    (Comma | END_Symbol | IDent | Semicolon => True, others => False);

  Comma_IDent_Semicolon : constant Symset :=
    (Comma | IDent | Semicolon => True, others => False);

  Comma_IDent_RParent_Semicolon : constant Symset :=
    (Comma | IDent | RParent | Semicolon => True, others => False);

  Comma_OF_RParent : constant Symset :=
    (Comma | RParent | OF_Symbol => True, others => False);

  Comma_RParent : constant Symset :=
    (Comma | RParent => True, others => False);

  DO_LOOP : constant Symset :=
    (DO_Symbol | LOOP_Symbol => True, others => False);

  DO_THEN : constant Symset :=
    (DO_Symbol | THEN_Symbol => True, others => False);

  ELSE_ELSIF_END : constant Symset :=
    (ELSE_Symbol | ELSIF_Symbol | END_Symbol => True, others => False);

  ELSE_END_OR : constant Symset :=
    (ELSE_Symbol | END_Symbol | OR_Symbol => True, others => False);

  ELSE_OR : constant Symset :=
    (ELSE_Symbol | OR_Symbol => True, others => False);

  END_IDent_Semicolon : constant Symset :=
    (END_Symbol | IDent | Semicolon => True, others => False);

  END_LOOP_RANGE_Double_Dot : constant Symset :=
    (END_Symbol | LOOP_Symbol | Range_Double_Dot_Symbol => True, others => False);

  END_LOOP_Semicolon : constant Symset :=
    (END_Symbol | LOOP_Symbol | Semicolon => True, others => False);

  END_WHEN : constant Symset :=
    (END_Symbol | WHEN_Symbol => True, others => False);

  OF_RANGE_Double_Dot_RParent : constant Symset :=
    (OF_Symbol | Range_Double_Dot_Symbol | RParent => True, others => False);

  --  Other sets, named by their context:

  After_Subprogram_Parameters : constant Symset :=
    (IS_Symbol | RETURN_Symbol | Semicolon => True, others => False);

  Block_Begin_Symbol : constant Symset :=
   (PROCEDURE_Symbol |
    FUNCTION_Symbol  |
    TASK_Symbol      |
    ENTRY_Symbol     |
    BEGIN_Symbol     |
    DECLARE_Symbol   => True,
    others => False);

  Constant_Definition_Begin_Symbol : constant Symset :=
   (Plus      |
    Minus     |
    IntCon    |
    FloatCon  |
    CharCon   |
    IDent     => True,
    others => False);

  Declaration_Symbol : constant Symset :=
    (IDent            |
     TYPE_Symbol      |
     TASK_Symbol      |
     PROCEDURE_Symbol |
     FUNCTION_Symbol  => True,
     others => False);

  Factor_Begin_Symbol : constant Symset :=
   (IntCon     |
    FloatCon   |
    CharCon    |
    IDent      |
    LParent    |
    NOT_Symbol => True,
    others => False);

  FactorZ : constant Symset :=
    (Times | Divide | MOD_Symbol | REM_Symbol | AND_Symbol => True,
     Power => True,  --  !! The ** operator has a higher precedence level 4.4 (6)
     others => False);

  Fail_after_FOR : constant Symset :=
    (IN_Symbol               |
     Range_Double_Dot_Symbol |
     LOOP_Symbol             |
     END_Symbol              => True,
     others => False);

  Comparison_Operator_Set : constant Symset :=
    (Comparison_Operator => True, others => False);

  Plus_Minus : constant Symset :=
    (Plus | Minus => True, others => False);

  Selector_Symbol : constant Symset :=
    (LParent | Period => True, others => False);

  Selector_Symbol_Loose : constant Symset :=
    (LBrack | LParent | Period => True, others => False);

  Statement_Begin_Symbol : constant Symset :=
   (IDent         |
    BEGIN_Symbol  |
    DECLARE_Symbol|
    IF_Symbol     |
    WHILE_Symbol  |
    LOOP_Symbol   |
    FOR_Symbol    |
    CASE_Symbol   |
    EXIT_Symbol   |
    NULL_Symbol   |
    RETURN_Symbol |
    SELECT_Symbol |
    ACCEPT_Symbol |
    DELAY_Symbol  => True,
    others => False);

  Symbols_after_Subprogram_Identifier : constant Symset :=
    (LParent | RETURN_Symbol | IS_Symbol | Semicolon => True,
     others => False);

  TermZ : constant Symset :=
    (Plus | Minus | OR_Symbol | XOR_Symbol => True, others => False);

  Type_Begin_Symbol : constant Symset :=
   (IDent                |
    ARRAY_Symbol         |
    RECORD_Symbol        |
    RANGE_Keyword_Symbol |
    LParent              => True,
    others         => False);

  ------------------
  --  Types sets  --
  ------------------

  Numeric_Typ_Set : constant Typ_Set := (Numeric_Typ => True, others => False);
  Atomic_Typ      : constant Typ_Set := Discrete_Typ or Numeric_Typ_Set;
  Ints_Typ        : constant Typ_Set := (Ints => True, others => False);

  -------------
  --  Misc.  --
  -------------

  --  Check if we have an "array of Character", for instance a String.
  --
  function Is_Char_Array (CD : Compiler_Data; T : Exact_Typ) return Boolean;

  type Constant_Rec is record
    TP : Exact_Typ;
    I  : Integer;
    R  : HAC_Float;
  end record;

  ------------------------------------------------------------------
  ------------------------------------------------Locate_Identifier-
  function Locate_Identifier (
    CD            : in out Compiler_Data;
    Id            : Alfa;
    Level         : Integer;
    No_Id_Fail    : Boolean := True;
    stop_on_error : Boolean := False) return Natural;

  ------------------------------------------------------------------
  -------------------------------------------------Get_File_Pointer-
  function Get_File_Pointer (CD : Compiler_Data; Id : Alfa) return Integer;  -- Schoening

  No_File_Index : constant := -1;

  ------------------------------------------------------------------
  ----------------------------------------------Enter_or_find_Float-
  procedure Enter_or_find_Float (
    CD         : in out Compiler_Data;
    X          :        HAC_Float;
    RNum_Index :    out Natural
  );

end HAC.Parser.Helpers;
