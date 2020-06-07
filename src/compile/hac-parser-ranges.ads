with HAC.Defs;

private package HAC.Parser.Ranges is

  --  This package has two variants (Static_Range, Dynamic_Range) of
  --  discrete_subtype_definition RM 3.6 (6). In a distant future we could
  --  have a variant of Dynamic_Range which detects that the bounds are static
  --  and optimizes the code accordingly.

  --      which is either:
  --        a subtype_indication 3.2.2 (3) : name [constraint]
  --        like "Color [range red .. blue]"
  --      or
  --        a range 3.5 (3)
  --        which is either:
  --          simple_expression .. simple_expression : "low .. high"
  --        or
  --          range_attribute_reference 4.1.4 (4): A'Range[(2)]

  ------------------
  -- Static_Range --
  ------------------
  --
  --  A range with static bounds is parsed.
  --  The bounds are known at compile-time.
  --  At least, HAC is expecting the bounds to be static...
  --
  --    Examples of static bounds:
  --      type T is range 1 .. 10;              --  Must be static
  --      type T is new Integer range 1 .. 10;  --  Could be dynamic as well
  --      subtype S is T range 2 .. 9;          --  Could be dynamic as well
  --
  --  As long as HAC has static-only arrays, this is also used for:
  --      type A is array (1 .. 5);
  --
  --  Purely static discrete_subtype_definition in "full" Ada seem
  --  to be restricted to:
  --    - range types
  --    - case statements
  --    - record type declarations with variant parts.
  --  CF answer by Niklas Holsti to
  --    "Q: discrete_subtype_definition: static only cases?"
  --    on comp.lang.ada, 2020-06-07.
  --
  procedure Static_Range (
    CD             : in out Compiler_Data;
    Level          : in     PCode.Nesting_level;
    FSys           : in     Defs.Symset;
    Specific_Error : in     Defs.Compile_Error;
    Lower_Bound    :    out Constant_Rec;
    Higher_Bound   :    out Constant_Rec
  );

  -------------------
  -- Dynamic_Range --
  -------------------
  --
  --  A range with dynamic bounds is parsed.
  --  The bounds are pushed on the stack.
  --    Example:
  --      --  FOR statement (RM 5.5 (4)).
  --      for I in J .. N loop

  procedure Dynamic_Range (
    CD                 : in out Compiler_Data;
    Level              : in     PCode.Nesting_level;
    FSys               : in     Defs.Symset;
    Non_Discrete_Error : in     Defs.Compile_Error;
    Range_Typ          :    out Exact_Typ
  );

end HAC.Parser.Ranges;
