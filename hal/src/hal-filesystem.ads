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

package HAL.Filesystem is

   subtype Pathname is String;

   type File_Kind is (Regular_File, Directory);

   type File_Mode is (Read_Only, Write_Only, Read_Write);

   type Status_Kind is (Status_Ok,
                        Symbolic_Links_Loop,
                        Permission_Denied,
                        Input_Output_Error,
                        No_Such_File_Or_Directory,
                        Filename_Is_Too_Long,
                        Not_A_Directory,
                        Representation_Overflow,
                        Invalid_Argument,
                        Not_Enough_Space,
                        Not_Enough_Memory,
                        Bad_Address,
                        File_Exists,
                        Read_Only_File_System,
                        Operation_Not_Permitted,
                        No_Space_Left_On_Device,
                        Too_Many_Links,
                        Resource_Busy,
                        Buffer_Is_Too_Small,
                        Read_Would_Block,
                        Call_Was_Interrupted);

   type User_ID is new Natural;
   type Group_ID is new Natural;
   type IO_Count is new Unsigned_64;

   type FS_Driver is limited interface;
   type FS_Driver_Ref is access all FS_Driver'Class;

   type File_Handle is limited interface;
   type File_Handle_Ref is access all File_Handle'Class;

   type Directory_Handle is limited interface;
   type Directory_Handle_Ref is access all Directory_Handle'Class;

   ---------------
   -- FS_Driver --
   ---------------

   function Create_Node (This : in out FS_Driver;
                         Path : Pathname;
                         Kind : File_Kind)
                         return Status_Kind is abstract;

   function Create_Directory (This : in out FS_Driver;
                              Path : Pathname)
                              return Status_Kind is abstract;

   function Unlink (This : in out FS_Driver;
                    Path : Pathname)
                    return Status_Kind is abstract;

   function Remove_Directory (This : in out FS_Driver;
                              Path : Pathname)
                              return Status_Kind is abstract;

   function Rename (This     : in out FS_Driver;
                    Old_Path : Pathname;
                    New_Path : Pathname)
                    return Status_Kind is abstract;

   function Truncate_File (This   : in out FS_Driver;
                           Path   : Pathname;
                           Lenght : IO_Count)
                           return Status_Kind is abstract;

   function Open (This   : in out FS_Driver;
                  Path   : Pathname;
                  Mode   : File_Mode;
                  Handle : out File_Handle_Ref)
                  return Status_Kind is abstract;

   function Open_Directory (This   : in out FS_Driver;
                            Path   : Pathname;
                            Handle : out Directory_Handle_Ref)
                            return Status_Kind is abstract;

   ------------------
   --  File_Handle --
   ------------------

   function Read (This : in out File_Handle;
                  Data : out Byte_Array)
                  return Status_Kind is abstract;

   function Write (This : in out File_Handle;
                   Data : Byte_Array)
                   return Status_Kind is abstract;

   function Seek (This   : in out File_Handle;
                  Offset : IO_Count)
                  return Status_Kind is abstract;

   function Close (This : in out File_Handle)
                   return Status_Kind is abstract;

   ----------------------
   -- Directory_Handle --
   ----------------------

   type Directory_Entry is record
      Entry_Type  : File_Kind;
   end record;

   function Read_Entry (This         : in out Directory_Handle;
                        Entry_Number : Positive;
                        Dir_Entry    : out Directory_Entry)
                        return Status_Kind is abstract;

   function Entry_Name (This         : in out Directory_Handle;
                        Entry_Number : Positive)
                        return Pathname is abstract;

   function Close (This : in out Directory_Handle)
                   return Status_Kind is abstract;

end HAL.Filesystem;
