------------------------------------------------------------------------------
--                                                                          --
--                     Copyright (C) 2015-2016, AdaCore                     --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions are  --
--  met:                                                                    --
--     1. Redistributions of source code must retain the above copyright    --
--        notice, this list of conditions and the following disclaimer.     --
--     2. Redistributions in binary form must reproduce the above copyright --
--        notice, this list of conditions and the following disclaimer in   --
--        the documentation and/or other materials provided with the        --
--        distribution.                                                     --
--     3. Neither the name of the copyright holder nor the names of its     --
--        contributors may be used to endorse or promote products derived   --
--        from this software without specific prior written permission.     --
--                                                                          --
--   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    --
--   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      --
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  --
--   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   --
--   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, --
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       --
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  --
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  --
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    --
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  --
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   --
--                                                                          --
------------------------------------------------------------------------------

with Interfaces; use Interfaces;
with Ada.Unchecked_Conversion;

package body MCP23x08 is

   function To_Byte is
      new Ada.Unchecked_Conversion (Source => ALl_IO_Array,
                                    Target => Byte);
   function To_All_IO_Array is
      new Ada.Unchecked_Conversion (Source => Byte,
                                    Target => ALl_IO_Array);
   procedure Loc_IO_Write
     (This      : in out MCP23x08_Device;
      WriteAddr : Register_Address;
      Value     : Byte)
     with Inline_Always;

   procedure Loc_IO_Read
     (This     : MCP23x08_Device;
      ReadAddr : Register_Address;
      Value    : out Byte)
     with Inline_Always;

   procedure Set_Bit
     (This     : in out MCP23x08_Device;
      RegAddr  : Register_Address;
      Pin      : MCP23x08_Pin);

   procedure Clear_Bit
     (This     : in out MCP23x08_Device;
      RegAddr  : Register_Address;
      Pin      : MCP23x08_Pin);

   ------------------
   -- Loc_IO_Write --
   ------------------

   procedure Loc_IO_Write
     (This      : in out MCP23x08_Device;
      WriteAddr : Register_Address;
      Value     : Byte)
   is

   begin
      IO_Write (MCP23x08_Device'Class (This),
                WriteAddr,
                Value);
   end Loc_IO_Write;

   -----------------
   -- Loc_IO_Read --
   -----------------

   procedure Loc_IO_Read
     (This     : MCP23x08_Device;
      ReadAddr : Register_Address;
      Value    : out Byte)
      is
   begin
      IO_Read (MCP23x08_Device'Class (This),
               ReadAddr,
               Value);
   end Loc_IO_Read;

   -------------
   -- Set_Bit --
   -------------

   procedure Set_Bit
     (This     : in out MCP23x08_Device;
      RegAddr  : Register_Address;
      Pin      : MCP23x08_Pin)
   is
      Prev, Next : Byte;
   begin
      Loc_IO_Read (This, RegAddr, Prev);
      Next := Prev or Pin'Enum_Rep;
      if Next /= Prev then
         Loc_IO_Write (This, RegAddr, Next);
      end if;
   end Set_Bit;

   ---------------
   -- Clear_Bit --
   ---------------

   procedure Clear_Bit
     (This     : in out MCP23x08_Device;
      RegAddr : Register_Address;
      Pin      : MCP23x08_Pin)
   is
      Prev, Next : Byte;
   begin
      Loc_IO_Read (This, RegAddr, Prev);
      Next := Prev and (not  Pin'Enum_Rep);
      if Next /= Prev then
         Loc_IO_Write (This, RegAddr, Next);
      end if;
   end Clear_Bit;

   ---------------
   -- Configure --
   ---------------

   procedure Configure (This    : in out MCP23x08_Device;
                        Pin     : MCP23x08_Pin;
                        Output  : Boolean;
                        Pull_Up : Boolean)
   is
   begin
      if Output then
         Clear_Bit (This, IO_DIRECTION_REG, Pin);
      else
         Set_Bit (This, IO_DIRECTION_REG, Pin);
      end if;

      if Pull_Up then
         Set_Bit (This, PULL_UP_REG, Pin);
      else
         Clear_Bit (This, PULL_UP_REG, Pin);
      end if;
   end Configure;

   ---------
   -- Set --
   ---------

   function Set (This  : MCP23x08_Device;
                 Pin   : MCP23x08_Pin) return Boolean
   is
      Val : Byte;
   begin
      Loc_IO_Read (This, LOGIC_LEVLEL_REG, Val);
      return (Pin'Enum_Rep and Val) /= 0;
   end Set;

   ---------
   -- Set --
   ---------

   procedure Set (This  : in out MCP23x08_Device;
                  Pin   : MCP23x08_Pin)
   is
   begin
      Set_Bit (This, LOGIC_LEVLEL_REG, Pin);
   end Set;

   -----------
   -- Clear --
   -----------

   procedure Clear (This  : in out MCP23x08_Device;
                    Pin   : MCP23x08_Pin)
   is
   begin
      Clear_Bit (This, LOGIC_LEVLEL_REG, Pin);
   end Clear;

   ------------
   -- Toggle --
   ------------

   procedure Toggle (This  : in out MCP23x08_Device;
                     Pin   : MCP23x08_Pin)
   is
   begin
      if This.Set (Pin) then
         This.Clear (Pin);
      else
         This.Set (Pin);
      end if;
   end Toggle;

   ----------------
   -- Get_All_IO --
   ----------------

   function Get_All_IO (This : in out MCP23x08_Device) return ALl_IO_Array is
      Val : Byte;
   begin
      Loc_IO_Read (This, LOGIC_LEVLEL_REG, Val);
      return To_All_IO_Array (Val);
   end Get_All_IO;

   ----------------
   -- Set_All_IO --
   ----------------

   procedure Set_All_IO (This : in out MCP23x08_Device; IOs : ALl_IO_Array) is
   begin
      Loc_IO_Write (This, LOGIC_LEVLEL_REG, To_Byte (IOs));
   end Set_All_IO;

   --------------------
   -- Get_GPIO_Point --
   --------------------

   function Get_GPIO_Point (This : in out MCP23x08_Device;
                            Pin  : MCP23x08_Pin)
                            return not null HAL.GPIO.GPIO_Point_Ref
   is
   begin
      This.Points (Pin) := (Device => This'Unchecked_Access,
                            Pin    => Pin);
      return This.Points (Pin)'Unchecked_Access;
   end Get_GPIO_Point;

   ---------
   -- Set --
   ---------

   overriding
   function Set (Point : MCP23_GPIO_Point) return Boolean is
   begin
      return Point.Device.Set (Point.Pin);
   end Set;

   ---------
   -- Set --
   ---------

   overriding
   procedure Set (Point : in out MCP23_GPIO_Point) is
   begin
      Point.Device.Set (Point.Pin);
   end Set;

   -----------
   -- Clear --
   -----------

   overriding
   procedure Clear (Point : in out MCP23_GPIO_Point) is
   begin
      Point.Device.Clear (Point.Pin);
   end Clear;

   ------------
   -- Toggle --
   ------------

   overriding
   procedure Toggle (Point : in out MCP23_GPIO_Point) is
   begin
      Point.Device.Toggle (Point.Pin);
   end Toggle;

end MCP23x08;
