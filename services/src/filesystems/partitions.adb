
package body Partitions is

   type Partition_Entry_Block_Mapping (Kind : Boolean := True) is record
      case Kind is
         when True => Data : Block (1 .. 16);
         when False => P_Entry : Partition_Entry;
      end case;
   end record with Pack, Unchecked_Union, Size => 16 * 8;

   procedure Read_Entry_In_MBR (MBR     : Block;
                                Index   : Integer;
                                P_Entry : out Partition_Entry)
     with Pre => Index <= 3;

   function Number_Of_Logical_Partitions (Disk        : not null Block_Driver_Ref;
                                          EBR_Address : Logical_Block_Address)
                                          return Natural;

   function Get_Logical_Partition_Entry (Disk         : not null Block_Driver_Ref;
                                         EBR_Address  : Logical_Block_Address;
                                         Entry_Number : Positive;
                                         Entry_Cnt    : in out Natural;
                                         P_Entry      : out Partition_Entry)
                                         return Status_Code;

   -----------------------
   -- Read_Entry_In_MBR --
   -----------------------

   procedure Read_Entry_In_MBR (MBR     : Block;
                                Index   : Integer;
                                P_Entry : out Partition_Entry)
   is
      Entry_Block_Conv : Partition_Entry_Block_Mapping;
      First            : constant Integer := MBR'First + 446 + Index * 16;
      Last             : constant Integer := First + 15;
   begin
      if MBR'Length /= 512 then
         P_Entry.Status := 16#FF#;
      end if;

      Entry_Block_Conv.Data := MBR (First .. Last);
      P_Entry := Entry_Block_Conv.P_Entry;
   end Read_Entry_In_MBR;

   ----------------------------------
   -- Number_Of_Logical_Partitions --
   ----------------------------------

   function Number_Of_Logical_Partitions (Disk        : not null Block_Driver_Ref;
                                          EBR_Address : Logical_Block_Address)
                                          return Natural
   is
      EBR       : Block (0 .. 511);
      Entry_Cnt : Natural := 0;
      Address   : Logical_Block_Address := EBR_Address;
      P_Entry   : Partition_Entry;
   begin
      loop
         if not Disk.Read (Address, EBR) or else EBR (510 .. 511) /= (16#55#, 16#AA#) then
            return Entry_Cnt;
         end if;

         Read_Entry_In_MBR (EBR, 0, P_Entry);

         if Is_Valid (P_Entry) then
            Entry_Cnt := Entry_Cnt + 1;
         end if;

         Read_Entry_In_MBR (EBR, 1, P_Entry);

         exit when P_Entry.First_Sector_LBA = 0;
         Address := EBR_Address + P_Entry.First_Sector_LBA;
      end loop;

      return Entry_Cnt;
   end Number_Of_Logical_Partitions;

   ---------------------------------
   -- Get_Logical_Partition_Entry --
   ---------------------------------

   function Get_Logical_Partition_Entry (Disk         : not null Block_Driver_Ref;
                                         EBR_Address  : Logical_Block_Address;
                                         Entry_Number : Positive;
                                         Entry_Cnt    : in out Natural;
                                         P_Entry      : out Partition_Entry)
                                         return Status_Code
   is
      EBR     : Block (0 .. 511);
      Address : Logical_Block_Address := EBR_Address;
   begin
      loop
         if not Disk.Read (Address, EBR) or else EBR (510 .. 511) /= (16#55#, 16#AA#) then
            return Invalid_Parition;
         end if;

         Read_Entry_In_MBR (EBR, 0, P_Entry);

         if Is_Valid (P_Entry) then
            Entry_Cnt := Entry_Cnt + 1;

            if Entry_Cnt = Entry_Number then
               return Status_Ok;
            end if;
         end if;

         Read_Entry_In_MBR (EBR, 1, P_Entry);

         exit when P_Entry.First_Sector_LBA = 0;
         Address := EBR_Address + P_Entry.First_Sector_LBA;
      end loop;

      return Invalid_Parition;
   end Get_Logical_Partition_Entry;

   -------------------------
   -- Get_Partition_Entry --
   -------------------------

   function Get_Partition_Entry (Disk         : not null Block_Driver_Ref;
                                 Entry_Number : Positive;
                                 P_Entry      : out Partition_Entry)
                                 return Status_Code
   is
      MBR         : Block (0 .. 511);
      Entry_Cnt   : Natural := 0;
      EBR_Address : Logical_Block_Address;
   begin
      if not Disk.Read (0, MBR) then
         return Disk_Error;
      end if;

      if MBR (510 .. 511) /= (16#55#, 16#AA#) then
         return Disk_Error;
      end if;

      for P_Index in 0 .. 3 loop
         Read_Entry_In_MBR (MBR, P_Index, P_Entry);

         if Is_Valid (P_Entry) then
            Entry_Cnt := Entry_Cnt + 1;

            --  Is is the entry we are looking for?
            if Entry_Cnt = Entry_Number then
               return Status_Ok;
            elsif P_Entry.Kind = Extended_Parition then

               EBR_Address := P_Entry.First_Sector_LBA;

               --  Look in the list of logical partitions
               if Get_Logical_Partition_Entry (Disk,
                                               EBR_Address,
                                               Entry_Number,
                                               Entry_Cnt,
                                               P_Entry) = Status_Ok
               then
                  return Status_Ok;
               end if;
            end if;
         end if;
      end loop;

      return Invalid_Parition;
   end Get_Partition_Entry;

   --------------------------
   -- Number_Of_Partitions --
   --------------------------

   function Number_Of_Partitions (Disk : Block_Driver_Ref) return Natural is
      MBR       : Block (0 .. 511);
      Entry_Cnt : Natural := 0;
      P_Entry   : Partition_Entry;
   begin
      if not Disk.Read (0, MBR) then
         return 0;
      end if;

      if MBR (510 .. 511) /= (16#55#, 16#AA#) then
         return 0;
      end if;

      for P_Index in 0 .. 3 loop
         Read_Entry_In_MBR (MBR, P_Index, P_Entry);

         if Is_Valid (P_Entry) then
            Entry_Cnt := Entry_Cnt + 1;
         end if;

         if P_Entry.Kind = Extended_Parition then
            Entry_Cnt := Entry_Cnt +
              Number_Of_Logical_Partitions (Disk, P_Entry.First_Sector_LBA);
         end if;
      end loop;

      return Entry_Cnt;
   end Number_Of_Partitions;

end Partitions;
