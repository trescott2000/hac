--  Solution to Advent of Code 2022, Day 10
-------------------------------------------
--  Cathode-Ray Tube
--
--  https://adventofcode.com/2022/day/10
--  Copy of questions in: aoc_2022_10_questions.txt

--  For building this program with "full Ada",
--  files hat*.ad* are in ../../../src
with HAT;

procedure AoC_2022_10 is
  use HAT;

  verbose : constant Boolean := True;
  T0 : constant Time := Clock;

  asm : String (1 .. 4);
  arg : Integer;
  f : File_Type;
  s : VString;

  add : array (1 .. 300) of integer;

  screen : array (0 .. 5, 0 .. 39) of character;

  sum, cycle, x, scr_i, scr_j : Integer;

begin
  for i in add'Range loop
    add (i) := 0;
  end loop;
  
  cycle := 1;
  Open (f, "aoc_2022_10.txt");
Read_Data :
  while not End_Of_File (f) loop
    Get (f, asm);
    if asm = "noop" then
      cycle := cycle + 1;
    else
      Get (f, arg);
      cycle := cycle + 2;
      add(cycle) := arg;
    end if;
  end loop Read_Data;
  Close (f);

  for i in screen'range(1) loop
    for j in screen'range(2) loop
      screen (i,j):= ' ';
    end loop;
  end loop;

  --  Here we start the virtual machine:
  x := 1;
  sum := 0;
  for cy in 1 .. cycle loop
    x := x + add (cy);
    if (cy - 20) mod 40 = 0 then
      sum:= sum + x * cy;
    end if;
    --
    scr_i := (cy - 1) / 40;
    scr_j := (cy - 1) mod 40;
    if scr_i in screen'range(1) then
      if abs (scr_j - x) <2 then
        screen (scr_i, scr_j) :='#';
      else
        screen (scr_i, scr_j) :='.';
      end if;
    end if;
  end loop;
  
  if Argument_Count >= 1 then
    --  Compiler test mode.
    if sum /= Integer'Value (To_String (Argument (1))) then
      Set_Exit_Status (1);  --  Compiler test failed.
    end if;
  else
    Put_Line (+"Done in: " & (Clock - T0) & " seconds");
    Put_Line (+"Part 1: sum of signal strengths: " & sum);
    Put_Line (+"Part 2:");
    for i in screen'range(1) loop
      for j in screen'range(2) loop
        put (screen (i, j));
      end loop;
      new_line;
    end loop;
    --  Part 1: validated by AoC: 12880
    --  Part 2: validated by AoC: FCJAPJRE
  end if;
end AoC_2022_10;
