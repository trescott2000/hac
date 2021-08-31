package body HAC_Sys.PCode.Interpreter.In_Defs is

  procedure Allocate_Text_File (
    ND : in out Interpreter_Data;
    R  : in out General_Register
  )
  is
    use Defs;
  begin
    if R.Special /= Text_Files then
      R := GR_Abstract_Console;
    end if;
    if R.Txt = null
      or else Ada.Text_IO.Is_Open (R.Txt.all)
      --  ^ Uh oh, someone somewhere in the HAC program forgot to close
      --    a file at the same VM address.
    then
      R.Txt := new Ada.Text_IO.File_Type;
      ND.Files.Append (R.Txt);
    end if;
  end Allocate_Text_File;

  procedure Free_Allocated_Contents (
    ND         : in out Interpreter_Data;
    Open_Files :    out Open_Files_Vectors.Vector
  )
  is
    procedure Free is new Ada.Unchecked_Deallocation (Ada.Text_IO.File_Type, File_Ptr);
    procedure Free is new Ada.Unchecked_Deallocation (Stack_Type, Stack_Type_Access);
    open_file : Open_File_Data;
    use Ada.Text_IO;
  begin
    for F of ND.Files loop
      if F /= null then
        if Is_Open (F.all) then
          --  We close for the distracted programmer
          --  all files that are still open.
          --  In that respect, we do more than required by the RM (A.7(6)):
          --     "The language does not define what happens to external files
          --      after the completion of the main program and all the library
          --      tasks (in particular, if corresponding files have
          --      not been closed)."
          open_file.Name := HAL.To_VString (Name (F.all));
          open_file.Mode := Mode (F.all);
          Open_Files.Append (open_file);
          Ada.Text_IO.Close (F.all);
        end if;
        Free (F);
      end if;
    end loop;
    Free (ND.S);
  end Free_Allocated_Contents;

  function Get_String_from_Stack (ND : Interpreter_Data; Idx, Size : Integer) return String is
    Res : String (1 .. Size);
  begin
    for i in Res'Range loop
      Res (i) := Character'Val (ND.S (Idx + i - 1).I);
    end loop;
    return Res;
  end Get_String_from_Stack;

  function GR_Real (R : Defs.HAC_Float) return General_Register is
  begin
    return (Special => Defs.Floats, I => 0, R => R);
  end GR_Real;

  function GR_Time (T : Ada.Calendar.Time) return General_Register is
  begin
    return (Special => Defs.Times, I => 0, Tim => T);
  end GR_Time;

  function GR_Duration (D : Duration) return General_Register is
  begin
    return (Special => Defs.Durations, I => 0, Dur => D);
  end GR_Duration;

  function GR_VString (S : String) return General_Register is
  begin
    return (Special => Defs.VStrings, I => 0, V => HAL.To_VString (S));
  end GR_VString;

  function GR_VString (V : HAL.VString) return General_Register is
  begin
    return (Special => Defs.VStrings, I => 0, V => V);
  end GR_VString;

  procedure Pop (ND : in out Interpreter_Data; Amount : Positive := 1) is
    Curr_TCB_Top : Integer renames ND.TCB (ND.CurTask).T;
  begin
    Curr_TCB_Top := Curr_TCB_Top - Amount;
    if Curr_TCB_Top < ND.S'First then
      raise VM_Stack_Underflow;
    end if;
  end Pop;

  procedure Push (ND : in out Interpreter_Data; Amount : Positive := 1) is
    Curr_TCB : Task_Control_Block renames ND.TCB (ND.CurTask);
  begin
    Curr_TCB.T := Curr_TCB.T + Amount;
    if Curr_TCB.T > Curr_TCB.STACKSIZE then
      raise VM_Stack_Overflow;
    end if;
  end Push;

  procedure Post_Mortem_Dump (CD : Co_Defs.Compiler_Data; ND : In_Defs.Interpreter_Data) is
    use Ada.Text_IO, Co_Defs, Defs.IIO, Defs.RIO;
    BLKCNT : Integer;
    H1, H2, H3 : Integer;
    --  !! Should use a file for dump !!
  begin
    New_Line;
    Put_Line ("HAC - PCode - Post Mortem Dump");
    New_Line;
    Put_Line ("Processor state: " & Processor_State'Image (ND.PS));
    New_Line;
    Put_Line (
      "Stack Variables of Task " &
      Defs.To_String (CD.IdTab (CD.Tasks_Definitions_Table (ND.CurTask)).Name)
    );
    H1 := ND.TCB (ND.CurTask).B;   --  current bottom of stack
    BLKCNT := 10;
    loop
      New_Line;
      BLKCNT := BLKCNT - 1;
      if BLKCNT = 0 then
        H1 := 0;
      end if;
      H2 := Integer (ND.S (H1 + 4).I);  --  index into HAC.Data.IdTab for this process
      if H1 = 0 then
        Put_Line ("Task Variables");
      else
        Put (Defs.To_String (CD.IdTab (H2).Name));
        Put (" CALLED AT");
        Put (ND.S (H1 + 1).I, 5);
        New_Line;
      end if;
      H2 := CD.Blocks_Table (CD.IdTab (H2).Block_Ref).Last_Id_Idx;
      while H2 /= 0 loop
        --  [P2Ada]: WITH instruction
        declare
          P2Ada_Var_7 : IdTabEntry renames CD.IdTab (H2);
          use Defs;
        begin
          if P2Ada_Var_7.Entity = Variable then
            if Defs.Standard_or_Enum_Typ (P2Ada_Var_7.xTyp.TYP) then
              if P2Ada_Var_7.Normal then
                H3 := H1 + P2Ada_Var_7.Adr_or_Sz;
              else
                H3 := Integer (ND.S (H1 + P2Ada_Var_7.Adr_or_Sz).I);
              end if;
              Put ("  " & To_String (P2Ada_Var_7.Name) & " = ");
              case P2Ada_Var_7.xTyp.TYP is
                when Defs.Enums | Defs.Ints =>
                  Put (ND.S (H3).I);
                  New_Line;
                when Defs.Bools =>
                  BIO.Put (Boolean'Val (ND.S (H3).I));
                  New_Line;
                when Defs.Floats =>
                  Put (ND.S (H3).R);
                  New_Line;
                when Defs.Chars =>
                  Put (ND.S (H3).I);
                  Put_Line (" (ASCII)");
                when others =>
                  null;  -- [P2Ada]: no otherwise / else in Pascal
              end case;
            end if;
          end if;
          H2 := P2Ada_Var_7.Link;
        end; -- [P2Ada]: end of WITH

      end loop;
      H1 := Integer (ND.S (H1 + 3).I);
      exit when H1 < 0;
    end loop;
  end Post_Mortem_Dump;

end HAC_Sys.PCode.Interpreter.In_Defs;
