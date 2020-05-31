with HAC.PCode.Interpreter.Calls,
     HAC.PCode.Interpreter.Composite_Data,
     HAC.PCode.Interpreter.In_Defs,
     HAC.PCode.Interpreter.Multi_Statement,
     HAC.PCode.Interpreter.Operators,
     HAC.PCode.Interpreter.Tasking;

with HAC_Pack;

with Ada.Calendar,
     Ada.Command_Line,
     Ada.Environment_Variables;

package body HAC.PCode.Interpreter is

  procedure Interpret (CD: Compiler_Data; Unhandled : out Exception_Propagation_Data)
  is
    use In_Defs;
    ND : Interpreter_Data;
    H3 : Defs.HAC_Integer;  --  Internal integer register

    --  $I sched.pas
    --  This file contains the different scheduling strategies

    procedure ShowTime is null;
    procedure SnapShot is null;

    procedure Pop (Amount : Positive := 1) is  begin Pop (ND, Amount); end;
    procedure Push (Amount : Positive := 1) is begin Push (ND, Amount); end;

    procedure Do_Standard_Function is
      Curr_TCB : Task_Control_Block renames ND.TCB (ND.CurTask);
      Top_Item : GRegister renames ND.S (Curr_TCB.T);
      Arg : Integer;
      Code : constant SF_Code := SF_Code'Val (ND.IR.Y);
      use Defs;
    begin
      case Code is
        when SF_File_Information =>
          if ND.IR.X = 0 then  --  Niladic File info function -> abstract console
            Push;
            case SF_File_Information (Code) is
              when SF_EOF  => ND.S (Curr_TCB.T).I := Boolean'Pos (End_Of_File_Console);
              when SF_EOLN => ND.S (Curr_TCB.T).I := Boolean'Pos (End_Of_Line_Console);
            end case;
          else
            case SF_File_Information (Code) is
              when SF_EOF =>
                ND.S (Curr_TCB.T).I := Boolean'Pos (Ada.Text_IO.End_Of_File (ND.S (Curr_TCB.T).Txt.all));
              when SF_EOLN =>
                ND.S (Curr_TCB.T).I := Boolean'Pos (Ada.Text_IO.End_Of_Line (ND.S (Curr_TCB.T).Txt.all));
            end case;
          end if;
        when SF_Argument =>
          Arg := Top_Item.I;
          --  The stack top item may change its type here (if register has discriminant).
          Top_Item.V := To_VString (Argument (Arg));
        when SF_Shell_Execute =>
          Top_Item.I := Shell_Execute (To_String (Top_Item.V));
        when SF_Argument_Count =>
          Push;  --  Niladic function, needs to push a new item (their own result).
          ND.S (Curr_TCB.T).I := Argument_Count;
        when SF_Directory_Separator =>
          Push;  --  Niladic function, needs to push a new item (their own result).
          ND.S (Curr_TCB.T).I := Character'Pos (Directory_Separator);
        when SF_Get_Needs_Skip_Line =>
          Push;  --  Niladic function, needs to push a new item (their own result).
          ND.S (Curr_TCB.T).I := Boolean'Pos (Get_Needs_Skip_Line);
        when others =>
          Operators.Do_SF_Operator (CD, ND);  --  Doesn't need generic stuff.
      end case;
    end Do_Standard_Function;

    procedure Do_Text_Read (Code : SP_Code) is
      CH : Character;
      Curr_TCB : Task_Control_Block renames ND.TCB (ND.CurTask);
      use Defs;
      Out_Param : Index renames ND.S (Curr_TCB.T).I;
      Typ : constant Typen := Typen'Val (ND.IR.Y);
      Immediate : constant Boolean := Code = SP_Get_Immediate;
      FP : File_Ptr;
    begin
      if Code in SP_Get .. SP_Get_Line then
        --  The End_Of_File_Console check is skipped here (disturbs GNAT's run-time).
        case Typ is
          when Ints     => Get_Console (ND.S (Out_Param).I);
          when Floats   => Get_Console (ND.S (Out_Param).R);
          when VStrings => ND.S (Out_Param).V := To_VString (Get_Line_Console);
          when Chars    =>
            if Immediate then
              Get_Immediate_Console (CH);
            else
              Get_Console (CH);
            end if;
            ND.S (Out_Param).I := Character'Pos (CH);
          when others =>
            null;
        end case;
        if Code = SP_Get_Line and Typ /= VStrings then
          Skip_Line_Console;
        end if;
        Pop;
      else
        FP := ND.S (Curr_TCB.T - 1).Txt;
        if Ada.Text_IO.End_Of_File (FP.all) then
          raise VM_End_Error;
        else
          case Typ is
            when Ints =>
              Defs.IIO.Get (FP.all, ND.S (Out_Param).I);
            when Floats =>
              Defs.RIO.Get (FP.all, ND.S (Out_Param).R);
            when Chars =>
              Ada.Text_IO.Get (FP.all, CH);
              ND.S (Out_Param).I := Character'Pos (CH);
            when VStrings =>
              ND.S (Out_Param).V := To_VString (Ada.Text_IO.Get_Line (FP.all));
            when others =>
              null;
          end case;
        end if;
        if Code = SP_Get_Line_F and Typ /= VStrings then
          Ada.Text_IO.Skip_Line (FP.all);
        end if;
        Pop (2);
      end if;
      ND.SWITCH := True;  --  give up control when doing I/O
    end Do_Text_Read;

    procedure Do_Write_Formatted (Code : SP_Code) is
      Curr_TCB : Task_Control_Block renames   ND.TCB (ND.CurTask);
      FP       : File_Ptr;
      Item     : GRegister renames            ND.S (Curr_TCB.T - 3);
      Format_1 : constant Defs.HAC_Integer := ND.S (Curr_TCB.T - 2).I;
      Format_2 : constant Defs.HAC_Integer := ND.S (Curr_TCB.T - 1).I;
      Format_3 : constant Defs.HAC_Integer := ND.S (Curr_TCB.T    ).I;
      --  Valid parameters used: see def_param in HAC.Parser.Standard_Procedures.
      use Defs;
    begin
      if Code in SP_Put .. SP_Put_Line then
        case Typen'Val (ND.IR.Y) is
          when Ints            => Put_Console (Item.I, Format_1, Format_2);
          when Floats          => Put_Console (Item.R, Format_1, Format_2, Format_3);
          when Bools           => Put_Console (Boolean'Val (Item.I), Format_1);
          when Chars           => Put_Console (Character'Val (Item.I));
          when VStrings        => Put_Console (To_String (Item.V));
          when String_Literals => Put_Console (
              CD.Strings_Constants_Table (Format_1 .. Format_1 + Item.I - 1)
            );
          when Arrays          => Put_Console (Get_String_from_Stack (ND, Item.I, Format_1));
          when others =>
            null;
        end case;
        if Code = SP_Put_Line then
          New_Line_Console;
        end if;
        Pop (4);
      else
        FP := ND.S (Curr_TCB.T - 4).Txt;
        case Typen'Val (ND.IR.Y) is
          when Ints            => IIO.Put         (FP.all, Item.I, Format_1, Format_2);
          when Floats          => RIO.Put         (FP.all, Item.R, Format_1, Format_2, Format_3);
          when Bools           => BIO.Put         (FP.all, Boolean'Val (Item.I), Format_1);
          when Chars           => Ada.Text_IO.Put (FP.all, Character'Val (Item.I));
          when VStrings        => Ada.Text_IO.Put (FP.all, To_String (Item.V));
          when String_Literals => Ada.Text_IO.Put (FP.all,
              CD.Strings_Constants_Table (Format_1 .. Format_1 + Item.I - 1)
            );
          when Arrays          => Ada.Text_IO.Put (FP.all,
              Get_String_from_Stack (ND, Item.I, Format_1));
          when others =>
            null;
        end case;
        if Code = SP_Put_Line_F then
          Ada.Text_IO.New_Line (FP.all);
        end if;
        Pop (5);
      end if;
      ND.SWITCH := True;  --  give up control when doing I/O
    end Do_Write_Formatted;

    procedure Do_Code_for_Automatic_Initialization is
      Curr_TCB : Task_Control_Block renames ND.TCB (ND.CurTask);
      use Defs;
      Var_Addr : constant HAC_Integer := ND.S (Curr_TCB.T).I;
    begin
      case Typen'Val (ND.IR.Y) is
        when VStrings   => ND.S (Var_Addr).V := Null_VString;
        when Text_Files => Allocate_Text_File (ND, ND.S (Var_Addr));
        when others     => null;
      end case;
      Pop;
    end Do_Code_for_Automatic_Initialization;

    procedure Do_Update_Display_Vector is
      --  Emitted at the end of Subprogram_or_Entry_Call, when the
      --  called subprogram's nesting level is *lower* than the caller's.
      Low_Level  : constant Nesting_level := Nesting_level (ND.IR.X);  --  Called.
      High_Level : constant Nesting_level := Nesting_level (ND.IR.Y);  --  Caller.
      Curr_TCB : Task_Control_Block renames ND.TCB (ND.CurTask);
    begin
      H3 := Curr_TCB.B;
      for L in reverse Low_Level + 1 .. High_Level loop
        Curr_TCB.DISPLAY (L) := H3;
        H3 := ND.S (H3 + 2).I;
      end loop;
    end Do_Update_Display_Vector;

    procedure Do_File_IO is
      Code : constant SP_Code := SP_Code'Val (ND.IR.X);
      Curr_TCB : Task_Control_Block renames ND.TCB (ND.CurTask);
    begin
      case Code is
        when SP_Open =>
          Ada.Text_IO.Open (
            ND.S (Curr_TCB.T - 1).Txt.all,
            Ada.Text_IO.In_File,
            Defs.VStrings_Pkg.To_String (ND.S (Curr_TCB.T).V)
          );
          Pop (2);
        when SP_Create =>
          Ada.Text_IO.Create (
            ND.S (Curr_TCB.T - 1).Txt.all,
            Ada.Text_IO.Out_File,
            Defs.VStrings_Pkg.To_String (ND.S (Curr_TCB.T).V)
          );
          Pop (2);
        when SP_Close =>
          Ada.Text_IO.Close (ND.S (Curr_TCB.T).Txt.all);
          Pop;
        when SP_Set_Env =>
          Ada.Environment_Variables.Set (
            Defs.VStrings_Pkg.To_String (ND.S (Curr_TCB.T - 1).V),
            Defs.VStrings_Pkg.To_String (ND.S (Curr_TCB.T).V)
          );
          Pop (2);
        when SP_Push_Abstract_Console =>
          Push;
          ND.S (Curr_TCB.T).Txt := Abstract_Console;
        when SP_Get | SP_Get_Immediate | SP_Get_Line | SP_Get_F | SP_Get_Line_F =>
          Do_Text_Read (Code);
        when SP_Put |SP_Put_Line | SP_Put_F | SP_Put_Line_F =>
          Do_Write_Formatted (Code);
        when SP_New_Line =>
          if ND.S (Curr_TCB.T).Txt = Abstract_Console then
            New_Line_Console;
          else
            Ada.Text_IO.New_Line (ND.S (Curr_TCB.T).Txt.all);
          end if;
          Pop;
        when SP_Skip_Line =>
          if ND.S (Curr_TCB.T).Txt = Abstract_Console then
            --  The End_Of_File_Console check is skipped here (disturbs GNAT's run-time).
            Skip_Line_Console;
          elsif Ada.Text_IO.End_Of_File (ND.S (Curr_TCB.T).Txt.all) then
            raise VM_End_Error;
          else
            Ada.Text_IO.Skip_Line (ND.S (Curr_TCB.T).Txt.all);
          end if;
          Pop;
        when others =>
          null;
      end case;
      ND.SWITCH := True;  --  give up control when doing I/O
    end Do_File_IO;

    procedure Fetch_Instruction is
      Curr_TCB : Task_Control_Block renames ND.TCB (ND.CurTask);
    begin
      ND.IR := CD.ObjCode (Curr_TCB.PC);
      Curr_TCB.PC := Curr_TCB.PC + 1;
    end Fetch_Instruction;

    procedure Execute_Current_Instruction is
      Curr_TCB : Task_Control_Block renames ND.TCB (ND.CurTask);
      IR : Order renames ND.IR;
      --
      procedure Do_Atomic_Data_Push_Operation is
      begin
        Push;
        case Atomic_Data_Push_Opcode (ND.IR.F) is
          when k_Push_Address =>           --  Push "v'Access" of variable v
            ND.S (Curr_TCB.T).I := Curr_TCB.DISPLAY (Nesting_level (IR.X)) + IR.Y;
          when k_Push_Value =>             --  Push variable v's value.
            ND.S (Curr_TCB.T) := ND.S (Curr_TCB.DISPLAY (Nesting_level (IR.X)) + IR.Y);
          when k_Push_Indirect_Value =>    --  Push "v.all" (v is an access).
            ND.S (Curr_TCB.T) := ND.S (ND.S (Curr_TCB.DISPLAY (Nesting_level (IR.X)) + IR.Y).I);
          when k_Push_Discrete_Literal =>  --  Literal: discrete value (Integer, Character, Boolean, Enum)
            ND.S (Curr_TCB.T).I := IR.Y;
          when k_Push_Float_Literal =>
            ND.S (Curr_TCB.T).R := CD.Float_Constants_Table (IR.Y);
        end case;
      end Do_Atomic_Data_Push_Operation;
      --
    begin
      case ND.IR.F is
        when k_Jump => Curr_TCB.PC := IR.Y;
        when k_Conditional_Jump =>
          if ND.S (Curr_TCB.T).I = 0 then  --  if False, then ...
            Curr_TCB.PC := IR.Y;           --  ... Jump.
          end if;
          Pop;
        when k_Store =>  --  [T-1].all := [T]
          ND.S (ND.S (Curr_TCB.T - 1).I) := ND.S (Curr_TCB.T);
          Pop (2);
        --
        when k_Variable_Initialization => Do_Code_for_Automatic_Initialization;
        when k_Update_Display_Vector   => Do_Update_Display_Vector;
        when k_File_I_O                => Do_File_IO;
        when k_Standard_Functions      => Do_Standard_Function;
        --
        when Multi_Statement_Opcode  => Multi_Statement.Do_Multi_Statement_Operation (CD, ND);
        when Atomic_Data_Push_Opcode => Do_Atomic_Data_Push_Operation;
        when Composite_Data_Opcode   => Composite_Data.Do_Composite_Data_Operation (CD, ND);
        when Unary_Operator_Opcode   => Operators.Do_Unary_Operator (ND);
        when Binary_Operator_Opcode  => Operators.Do_Binary_Operator (ND);
        when Calling_Opcode          => Calls.Do_Calling_Operation (CD, ND);
        when Tasking_Opcode          => Tasking.Do_Tasking_Operation (CD, ND);
      end case;
    exception
      when others =>
        ND.PS := Exception_Raised;
        raise;
    end Execute_Current_Instruction;

    Result_Tasks_to_wake : Boolean;
    use Ada.Calendar;

  begin  --  Interpret
    ND.PS := Running;
    ND.Start_Time := Clock;
    ND.Snap     := False;
    ND.SWITCH   := False;           --  invoke scheduler on next cycle flag
    ND.SYSCLOCK := ND.Start_Time;
    ND.TIMER    := ND.SYSCLOCK;     --  set to end of current task's time slice
    HAC.PCode.Interpreter.Tasking.Init_main_task (CD, ND);
    HAC.PCode.Interpreter.Tasking.Init_other_tasks (CD, ND);

    Running_State:
    loop  --  until Processor state /= Running or Exception_Raised
      ND.SYSCLOCK := GetClock;
      if ND.Snap then
        ShowTime;
      end if;
      if ND.TCB (ND.CurTask).TS = Critical then
        if ND.Snap then
          SnapShot;
        end if;
      else
        HAC.PCode.Interpreter.Tasking.Tasks_to_wake (CD, ND, Result_Tasks_to_wake);
        if ND.SWITCH or  --  ------------> Voluntary release of control
           ND.SYSCLOCK >= ND.TIMER or   --  ---> Time slice exceeded
           Result_Tasks_to_wake
        then --  ------> Awakened task causes switch
          if ND.CurTask >= 0 then
            ND.TCB (ND.CurTask).LASTRUN := ND.SYSCLOCK;
            if ND.TCB (ND.CurTask).TS = Running then
              ND.TCB (ND.CurTask).TS := Ready;
              --  SWITCH PROCCESS
            end if;
          end if;
          loop --  Call Main Scheduler
            --  Schedule(Scheduler,CurTask, PS);
            ND.PS := Running;  --  !! Should call the task scheduler instead !!
            ND.SYSCLOCK := GetClock;
            if ND.Snap then
              ShowTime;
            end if;
            if ND.Snap then
              SnapShot;
            end if;
            exit when ND.PS /= WAIT;
          end loop;
          --
          exit Running_State when ND.PS = DEADLOCK or ND.PS = FIN;
          --
          ND.TIMER:= ND.SYSCLOCK + ND.TCB (ND.CurTask).QUANTUM;
          ND.TCB (ND.CurTask).TS := Running;
          ND.SWITCH := False;
          if ND.Snap then
            SnapShot;
          end if;
        end if;
      end if;

      Fetch_Instruction;

      --  HERE IS THE POINT WHERE THE TASK MONITORING IS CALLED
      --  (removed)

      declare
        EI : Exception_Propagation_Data renames ND.TCB (ND.CurTask).Exception_Info;
      begin
        Execute_Current_Instruction;
      exception
        when VM_Case_Check_Error =>
          EI.Currently_Raised  := (VME_Program_Error, 0);
          EI.Exception_Message := Defs.To_VString ("CASE Statement doesn't cover all cases");
        when VM_Division_by_0 =>
          EI.Currently_Raised  := (VME_Constraint_Error, 0);
          EI.Exception_Message := Defs.To_VString ("Division by 0");
        when VM_End_Error =>
          EI.Currently_Raised  := (VME_End_Error, 0);
        when VM_Function_End_without_Return =>
          EI.Currently_Raised  := (VME_Program_Error, 0);
          EI.Exception_Message := Defs.To_VString ("Function's end reached without ""return"" statement");
        when VM_Out_of_Range  =>
          EI.Currently_Raised  := (VME_Constraint_Error, 0);
          EI.Exception_Message := Defs.To_VString ("Out of range");
        when VM_Stack_Overflow  =>
          EI.Currently_Raised  := (VME_Storage_Error, 0);
          EI.Exception_Message := Defs.To_VString ("Stack overflow");
        when VM_Stack_Underflow =>
          EI.Currently_Raised  := (VME_Storage_Error, 0);
          EI.Exception_Message := Defs.To_VString ("Stack underflow");
      end;

      exit when ND.PS not in Running .. Running;
      --  !!  not in Running .. Exception_Raised when exception handling is programmed.
    end loop Running_State;
    --
    if ND.PS not in Exception_Raised .. FIN then
      Post_Mortem_Dump (CD, ND);
    end if;
    --
    Free_Allocated_Contents (ND);
    --
    Unhandled := ND.TCB (ND.CurTask).Exception_Info;
    --  Use Is_in_Exception to check whether an exception was unhandled
    --  when leaving the interpreter.
    case ND.PS is
      when FIN              => null;  --  All good, end reached.
      when Running          => null;  --  Should not happen here.
      when Exception_Raised => null;  --  Unhandled exception information stored in Unhandled.
      when DEADLOCK         => raise Abnormal_Termination with "Tasking: Deadlock";
      when WAIT             => raise Abnormal_Termination with "Tasking: Wait";
    end case;
  end Interpret;

  procedure Interpret_on_Current_IO (
    CD_CIO         :     Compiler_Data;
    Argument_Shift :     Natural := 0;    --  Number of arguments to be skipped
    Unhandled      : out Exception_Propagation_Data
  )
  is
    function Shifted_Argument_Count return Natural is
    begin
      return Ada.Command_Line.Argument_Count - Argument_Shift;
    end;

    function Shifted_Argument (Number : Positive) return String is
    begin
      return Ada.Command_Line.Argument (Number + Argument_Shift);
    end;

    function Get_Needs_Skip_Line return Boolean is
    begin
      return True;  --  The input is buffered with Ada.Text_IO.Get (not Get_Immediate).
    end Get_Needs_Skip_Line;

    procedure Interpret_on_Current_IO_Instance is new Interpret
      ( Ada.Text_IO.End_Of_File,
        Ada.Text_IO.End_Of_Line,
        Get_Needs_Skip_Line,
        Defs.IIO.Get,
        Defs.RIO.Get,
        Ada.Text_IO.Get,
        Ada.Text_IO.Get_Immediate,
        Ada.Text_IO.Get_Line,
        Ada.Text_IO.Skip_Line,
        Defs.IIO.Put,
        Defs.RIO.Put,
        Defs.BIO.Put,
        Ada.Text_IO.Put,
        Ada.Text_IO.Put,
        Ada.Text_IO.New_Line,
        Shifted_Argument_Count,
        Shifted_Argument,
        HAC_Pack.Shell_Execute,
        HAC_Pack.Directory_Separator
      );

  begin
    Interpret_on_Current_IO_Instance (CD_CIO, Unhandled);
  end Interpret_on_Current_IO;

  function Image (E: Exception_Identity) return String is
  begin
    case E.Ex_Typ is
      when No_Exception         => return "";
      when VME_Constraint_Error => return "Constraint_Error";
      when VME_Program_Error    => return "Program_Error";
      when VME_End_Error        => return "End_Error";
      when VME_Storage_Error    => return "Storage_Error";
      when VME_Custom           => return "(custom)";  --  needs to use details
    end case;
  end Image;

  function Is_in_Exception (E: Exception_Identity) return Boolean is
  begin
    return E.Ex_Typ /= No_Exception;
  end Is_in_Exception;

end HAC.PCode.Interpreter;
