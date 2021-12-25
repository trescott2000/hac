with HAL;

procedure Attributes is
  use HAL;

  subtype Some_Range is Integer range -123 .. 456;
  type Enum is (a, b, c, d);
  subtype Sub_Enum is Enum range b .. c;

  --  VImage Will be added soon as attribute...
  function VImage (e : Enum) return VString is
  begin
    case e is
      when a => return +"A";
      when b => return +"B";
      when c => return +"C";
      when d => return +"D";
    end case;
  end VImage;

begin
  Put_Line (+"Integer's bounds    : " & Integer'First           & " .. " & Integer'Last);
  Put_Line (+"Natural's bounds    : " & Natural'First           & " .. " & Natural'Last);
  Put_Line (+"Positive's bounds   : " & Positive'First          & " .. " & Positive'Last);
  Put_Line (+"Some_Range's bounds : " & Some_Range'First        & " .. " & Some_Range'Last);
  Put_Line (+"Boolean's bounds    : " & Boolean'First           & " .. " & Boolean'Last);
  Put_Line (+"Enum's bounds       : " & VImage (Enum'First)     & " .. " & VImage (Enum'Last));
  Put_Line (+"Sub_Enum's bounds   : " & VImage (Sub_Enum'First) & " .. " & VImage (Sub_Enum'Last));
end Attributes;
