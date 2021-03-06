with HAL; use HAL;
with HAL.Block_Drivers; use HAL.Block_Drivers;
with Interfaces; use Interfaces;

package Partitions is

   type Partition_Kind is new Unsigned_8;

   Empty_Partition       : constant Partition_Kind := 16#00#;
   Fat12_Parition        : constant Partition_Kind := 16#01#;
   Fat16_Parition        : constant Partition_Kind := 16#04#;
   Extended_Parition     : constant Partition_Kind := 16#05#;
   Fat16B_Parition       : constant Partition_Kind := 16#06#;
   NTFS_Partition        : constant Partition_Kind := 16#07#;
   Fat32_CHS_Parition    : constant Partition_Kind := 16#0B#;
   Fat32_LBA_Parition    : constant Partition_Kind := 16#0C#;
   Fat16B_LBA_Parition   : constant Partition_Kind := 16#0E#;
   Extended_LBA_Parition : constant Partition_Kind := 16#0F#;
   Linux_Swap_Partition  : constant Partition_Kind := 16#82#;
   Linux_Partition       : constant Partition_Kind := 16#83#;

   subtype Logical_Block_Address is Unsigned_32;

   type CHS_Address is record
      C : UInt10;
      H : Byte;
      S : UInt6;
   end record with Pack, Size => 24;

   type Partition_Entry is record
      Status            : Byte;
      First_Sector_CHS  : CHS_Address;
      Kind              : Partition_Kind;
      Last_Sector_CHS   : CHS_Address;
      First_Sector_LBA  : Logical_Block_Address;
      Number_Of_Sectors : Unsigned_32;
   end record with Pack, Size => 16 * 8;

   type Status_Code is (Status_Ok, Disk_Error, Invalid_Parition);

   function Get_Partition_Entry (Disk         : not null Block_Driver_Ref;
                                 Entry_Number : Positive;
                                 P_Entry      : out Partition_Entry)
                                 return Status_Code;

   function Number_Of_Partitions (Disk : Block_Driver_Ref) return Natural;

   function Is_Valid (P_Entry : Partition_Entry) return Boolean is
     (P_Entry.Status = 16#00# or else P_Entry.Status = 16#80#);
end Partitions;
