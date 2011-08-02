//
// IdeDisk.pas
//
// Drivers for IDE Disk . For the moment only detect ATA Drivers.
//
// Notes:
// - PCI-IDE Controllers was not detected.
// - Only support  drivers with LBA support.
// - In ATA Mode Supports up to 4 Disk  .
//
// Changes :
//
// 07/03/2009 Some bugs Fixed.
// 22/02/2007 First Version by Matias Vara,
//
// Copyright (c) 2003-2011 Matias Vara <matiasvara@yahoo.com>
// All Rights Reserved
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

Unit IdeDisk;
interface



{$I ..\Toro.inc}
//{$DEFINE DebugIdeDisk}

uses Console, Arch, FileSystem, Process, Debug;

implementation

const
 // PCI header identificators
 //PCI_STORAGE_CLASS = 1;
 //PCI_IDE_SUBCLASS = 1;
 //PCI_AHCI_SUBCLASS = 6;
 
 // Max number of drivers supported
 //MAX_ATA_DISK = 8;
 MAX_ATA_CONTROLLER= 4;
 MAX_SATA_DISK = 32;
 MAX_ATA_MINORS= 10;
 NOT_FILESYSTEM = $ff;
 
 // ATA Commands
 ATA_IDENTIFY= $EC;
 ATA_WRITE= $30;
 ATA_READ= $20;
 
 // ATA Driver Type
 MASTER= 0;
 SLAVE= 1;
 
 // Size of physic blocks
 BLKSIZE= 512;
 
 // Interface with User
 ATANAMES : array[0..3] of AnsiString = ('ATA0', 'ATA1', 'ATA2', 'ATA3');
 
 // ATA Ports
 ATA_DATA= 0;
 ATA_ERROR= 1;
 ATA_COUNT= 2;
 ATA_SECTOR= 3;
 ATA_CYLLOW= 4;
 ATA_CYLHIG= 5;
 ATA_DRIVHD= 6;
 ATA_CMD_STATUS= 7;
 
 
Type
 PIDEBlockDisk = ^TIDEBlockDisk;
 PIDEController = ^TIDEController;
 PPartitionEntry = ^TPartitionEntry;
 
 // IDE Block Disk structure
 TIDEBlockDisk = record
   StartSector : LongInt;
   Size: LongInt;
   FsType: LongInt;
   FileDesc: TFileBlock;
   next: PIDEBlockDisk;
 end;
 
// IDE Controller Disk
 TIDEController = record
   IOPort: LongInt;
   irq: LongInt;
   // Pool the Irq
   IrqReady: Boolean;
   IrqHandler: pointer;
   Driver:TBlockDriver;
   Minors:array[0..MAX_ATA_MINORS-1] of  TIDEBlockDisk;
 end;
 
  // ATA Identify 
 DriverId = record
  config         : word;    // General configuration (obselete)
  cyls           : word;    // Number of cylinders
  reserved2      : word;    // Specific configuration
  heads          : word;    // Number of logical heads
  track_bytes    : word;    // Obsolete
  sector_bytes   : word;    // Obsolete
  sectors        : word;    // Number of logical sectors per logical track
  vendor0        : word;    // vendor unique
  vendor1        : word;    // vendor unique
  vendor2        : word;    // vendor unique
  serial_no      : array[1..20] of XChar;    // Serial number
  buf_type       : word;    // Obsolete
  buf_size       : word;    // 512 byte increments; 0 = not_specified
  ecc_bytes      : word;    // Obsolete
  fw_rev         : array[1..8] of XChar;      // Firmware revision
  model          : array[1..40] of XChar;     // Model number
  max_mulsect    : byte;    // read/write multiple support
  vendor3        : byte;    // vendor unique
  dword_io       : word;    // 0 = not_implemented; 1 = implemented
  vendor4        : byte;    // vendor unique
  capability     : byte;    // bits 0:DMA 1:LBA 2:IORDYsw 3:IORDYsup
  reserved50     : word;    // reserved (word 50)
  vendor5        : byte;    // vendor unique
  tPIO           : byte;    // 0=slow, 1=medium, 2=fast
  vendor6        : byte;    // vendor unique
  tDMA           : byte;    // vitesse du DMA ; 0=slow, 1=medium, 2=fast }
  field_valid    : word;    // bits 0:cur_ok 1:eide_ok
  cur_cyls       : word;    // cylindres logiques
  cur_heads      : word;    // tetes logique
  cur_sectors    : word;    // secteur logique par piste
  cur_capacity0  : word;    // nombre total de secteur logique
  cur_capacity1  : word;    // 2 words, misaligned int
  multsect       : byte;    // compteur secteur multiple courrant
  multsect_valid : byte;    // quand (bit0==1) multsect is ok
  lba_capacity   : dword;   // nombre total de secteur
  dma_1word      : word;    // informations sur le DMA single-word
  dma_mword      : word;    // multiple-word dma info
  eide_pio_modes : word;    // bits 0:mode3 1:mode4
  eide_dma_min   : word;    // min mword dma cycle time (ns)
  eide_dma_time  : word;    // recommended mword dma cycle time (ns)
  eide_pio       : word;    // min cycle time (ns), no IORDY
  eide_pio_iordy : word;    // min cycle time (ns), with IORDY
  word69         : word;
  word70         : word;
  word71         : word;
  word72         : word;
  word73         : word;
  word74         : word;
  word75         : word;
  word76         : word;
  word77         : word;
  word78         : word;
  word79         : word;
  word80         : word;
  word81         : word;
  command_sets   : word;    // bits 0:Smart 1:Security 2:Removable 3:PM
  word83         : word;    // bits 14:Smart Enabled 13:0 zero
  word84         : word;
  word85         : word;
  word86         : word;
  word87         : word;
  dma_ultra      : word;
  word89         : word;
  word90         : word;
  word91         : word;
  word92         : word;
  word93         : word;
  word94         : word;
  word95         : word;
  word96         : word;
  word97         : word;
  word98         : word;
  word99         : word;
  word100        : word;
  word101        : word;
  word102        : word;
  word103        : word;
  word104        : word;
  word105        : word;
  word106        : word;
  word107        : word;
  word108        : word;
  word109        : word;
  word110        : word;
  word111        : word;
  word112        : word;
  word113        : word;
  word114        : word;
  word115        : word;
  word116        : word;
  word117        : word;
  word118        : word;
  word119        : word;
  word120        : word;
  word121        : word;
  word122        : word;
  word123        : word;
  word124        : word;
  word125        : word;
  word126        : word;
  word127        : word;
  security       : word;    // bits 0:support 1:enable 2:locked 3:frozen
  reserved       : array[1..127] of word;
 end;
 
  // entry in Partition Table.
  TPartitionEntry = record
    boot: byte;
    BeginHead: byte;
    BeginSectCyl: word;
    pType: byte;
    EndHead: byte;
    EndSecCyl: word;
    FirstSector: dword;
    Size: dword;
  end;

// All information about ATA Disk
var
  ATAControllers: array[0..MAX_ATA_CONTROLLER-1] of TIDEController;

procedure ATASelectDisk(Ctr:PIDEController;Drv:LongInt); inline;
begin
  if Drv<5 then
    Drv := $a0
  else
    Drv := $b0;
  write_portb(Drv, Ctr.IOPort+ATA_DRIVHD);
end;


procedure ATASendCommand(Ctr: PIDEController; Cmd: LongInt); inline;
begin
  write_portb(Cmd, Ctr.IOPort+ATA_CMD_STATUS);
end;

function ATAWork(Ctr:PIDEController):Boolean; inline;
begin
  Result := read_portb(Ctr.IOPort+ATA_CMD_STATUS) <> $ff;
end;

function ATABusy(Ctr:PIDEController): Boolean; inline;
var
  Temp: Byte;
begin
  Temp := read_portb(Ctr.IOPort+ATA_CMD_STATUS);
  Result := Bit_Test(@Temp, 7);
end;

function ATAError(Ctr:PIDEController): Boolean; inline;
var
  Temp: Byte;
begin
  Temp := read_portb(Ctr.IOPort+ATA_CMD_STATUS);
  Result := Bit_Test(@Temp, 0);
end;

function ATADataReady (Ctr:PIDEController): Boolean; inline;
var
  tmp: byte;
begin
  Tmp := read_portb(Ctr.IOPort+ATA_CMD_STATUS);
  Result := Bit_Test(@tmp,3);
end;

procedure ATAIn(Buffer: Pointer; IOPort: LongInt); {$IFDEF Inline} inline;{$ENDIF}
asm // RCX: Buffer, RDX: IOPort
  mov rdi, Buffer
  add rdx, ATA_DATA
  mov rcx, 256
  rep insw
end;

procedure ATAOut(Buffer: Pointer; IOPort: LongInt); {$IFDEF Inline} inline;{$ENDIF}
asm // RCX: Buffer, RDX: IOPort
  mov rsi, Buffer
  add rdx, ATA_DATA
  mov rcx, 256
  rep outsw
end;

// Prepare the Controller to Operation.
procedure ATAPrepare(Ctr:PIDEController;Drv: LongInt;Sector: LongInt;count: LongInt);
var
 lba1, lba2, lba3, lba4: Byte;
begin
{
  asm // TODO: replace this asm code with pascal code
    xor eax , eax
    mov eax, Sector
    mov lba1, al
    mov lba2, ah
    shr eax, 16
    mov lba3, al
    and ah, $0F
    mov lba4, ah
  end;
}
  lba1 := Sector and $FF;
  lba2 := (Sector shr 8) and $FF;
  lba3 := (Sector shr 16) and $FF;
  lba4 := (Sector shr 24) and $F;
  write_portb(byte(count),Ctr.IOPort+ATA_COUNT);
  write_portb(lba1,Ctr.IOPort+ATA_SECTOR);
  write_portb(lba2,Ctr.IOPort+ATA_CylLow);
  write_portb(lba3,Ctr.IOPort+ATA_CylHig);
  if Drv < 5 then
    Drv := $a0
  else
    Drv := $b0;
  write_portb(lba4 or byte(drv) or $40,Ctr.IOPort+ATA_DRIVHD);
end;

// Look for valid Partitions in Device (Device is a NOT_FILESYSTEM block type) .
procedure ATADetectPartition(Ctr:PIDEController;Minor: LongInt);
var 
  I: LongInt;
  Buff: array[0..511] of byte;
  Entry: PPartitionEntry;
begin
  ATAPrepare(Ctr,Minor,0,1);
  ATASendCommand(Ctr,ATA_READ);
  while AtaBusy(Ctr) do
    NOP;
  if not AtaError(Ctr) and ATADataReady(Ctr) then
  begin
    ATAIn(@Buff[0], Ctr.IOPort);
    if (Buff[511] = $AA) and (Buff[510] = $55) then
    begin
      Entry:= @Buff[446];
      for I := 1 to 4 do
      begin
        if Entry.pType<>0 then
        begin
          Ctr.Minors[Minor+I].StartSector:= Entry.FirstSector;
          Ctr.Minors[Minor+I].Size:= Entry.Size;
          Ctr.Minors[Minor+I].FsType:= Entry.pType;
          Ctr.Minors[Minor+I].FileDesc.BlockDriver:= @Ctr.Driver;
          Ctr.Minors[Minor+I].FileDesc.Minor:=Minor+I;
	        Ctr.Minors[Minor+I].FileDesc.BlockSize:= BLKSIZE;
          Ctr.Minors[Minor+I].FileDesc.Next:=nil;
	        WriteConsole('IdeDisk: /V', []);
          WriteConsole(ATANames[Ctr.Driver.Major], []);
	        WriteConsole('/n ,Minor: /V%d/n, Size: /V%d/n Mb, Type: /V%d/n\n',[Minor+I,Entry.Size div 2048,Entry.pType]);
	        {$IFDEF DebugIdeDisk}
            DebugTrace('IdeDisk: Controller: %q,Disk: %d --> Ok',Int64(Ctr.Driver.Major),Minor+I,0);
          {$ENDIF}
        end;
        Inc(Entry);
      end;
    end;
  end;
end;

// Look for Physical Devices
procedure ATADetectController;
var 
  I, Drv: LongInt;
  ATA_Buffer: DriverId;
begin
  for I := 0 to 1 do
  begin
    // The ATA controller is installed?
    if not ATAWork(@ATAControllers[I]) then
      Continue;
    for Drv:= MASTER to SLAVE do
    begin
      ATASelectDisk(@ATAControllers[I],Drv*5);
      ATASendCommand(@ATAControllers[I],ATA_IDENTIFY);
      // Wait for the driver
      while ATABusy(@ATAControllers[I]) do
        NOP;
      if ATADataReady(@ATAControllers[I]) and not ATAError(@ATAControllers[I]) then
      begin
        ATAIn(@ATA_Buffer, ATAControllers[I].IOPort);
        ATAControllers[I].Minors[Drv*5].StartSector:= 0;
        ATAControllers[I].Minors[Drv*5].Size:= ATA_Buffer.LBA_Capacity;
        ATAControllers[I].Minors[Drv*5].FSType:= NOT_FILESYSTEM;
        ATAControllers[I].Minors[Drv*5].FileDesc.BlockDriver:= @ATAControllers[I].Driver;
        ATAControllers[I].Minors[Drv*5].FileDesc.Minor:= Drv*5;
        ATAControllers[I].Minors[Drv*5].FileDesc.BlockSize:= BLKSIZE;
        ATAControllers[I].Minors[Drv*5].FileDesc.Next:= nil;
	      {$IFDEF DebugIdeDisk} DebugTrace('IdeDisk: Controller: %d, Disk: %d --> Ok',0,I,Drv*5); {$ENDIF}
        WriteConsole('IdeDisk: /V', []);
        WriteConsole(ATANames[ATAControllers[I].Driver.Major], []);
        WriteConsole('/n ,Minor: /V%d/n, Size: /V%d/n Mb, Type: /V%d/n\n',[Drv*5,ATA_Buffer.LBA_Capacity div 2048,NOT_FILESYSTEM]);
        ATADetectPartition(@ATAControllers[I],Drv*5);
      end
      {$IFDEF DebugIdeDisk}
      else
        DebugTrace('IdeDisk: Controller: %d, Disk: %d --> Fault',0,I,Drv)
      {$ENDIF}
    end;
    // Registering the Controller and the Resources
    RegisterBlockDriver(@ATAControllers[I].Driver);
    // Irq Handlers
    Irq_On(ATAControllers[I].Irq);
    CaptureInt(ATAControllers[I].Irq+32,ATAControllers[I].IrqHandler);
  end;
end;

// Dedicate Controller to Cpu
procedure ATADedicate(Driver:PBlockDriver;CPUID: LongInt);
var
  I: LongInt;
begin
  for I := 0 to MAX_ATA_MINORS-1 do
  begin
    // The driver responded ?
    if ATAControllers[Driver.Major].Minors[I].FsType = 0 then
      Continue;
    // The File Descriptor is enqued in Dedicate Filesystem
    DedicateBlockFile(@ATAControllers[Driver.Major].Minors[I].FileDesc,CPUID);
    {$IFDEF DebugIdeDisk}
      DebugTrace('IdeDisk: Dedicate Controller %d ,Disk: %q to CPU %d',Int64(ATAControllers[Driver.Major].Minors[I].FileDesc.Minor),Driver.Major,CPUID);
    {$ENDIF}
  end;
end;
 
// Irq Handlers only for ATA0 and ATA1 Standart Controllers.
procedure ATAHandler(Controller:LongInt);
begin
  eoi;
  ATAControllers[Controller].Driver.WaitOn.state := tsReady;
  {$IFDEF DebugIdeDisk} DebugTrace('IdeDisk: ATA0 Irq Captured , Thread Wake Up: #%q', Int64(ATAControllers[Controller].Driver.WaitOn), 0, 0); {$ENDIF}
end;

procedure ATA0IrqHandler; {$IFDEF FPC} [nostackframe]; assembler; {$ENDIF}
asm
  {$IFDEF DCC} .noframe {$ENDIF}
  // save registers
  push rbp
  push rax
  push rbx
  push rcx
  push rdx
  push rdi
  push rsi
  push r8
  push r9
  push r13
  push r14
  // protect the stack
  mov r15 , rsp
  mov rbp , r15
  sub r15 , 32
  mov  rsp , r15
  // set interruption
  sti
  {$IFDEF Win64}
  xor rcx , rcx
  {$ELSE WIN64}
  xor edi , edi
  {$ENDIF WIN64}
  // call handler
  Call ATAHandler
  mov rsp , rbp
  // restore the registers
  pop r14
  pop r13
  pop r9
  pop r8
  pop rsi
  pop rdi
  pop rdx
  pop rcx
  pop rbx
  pop rax
  pop rbp
  db $48
  db $cf
end;

procedure ATA1IrqHandler; {$IFDEF FPC} [nostackframe]; assembler; {$ENDIF}
asm
  {$IFDEF DCC} .noframe {$ENDIF}
  // save registers
  push rbp
  push rax
  push rbx
  push rcx
  push rdx
  push rdi
  push rsi
  push r8
  push r9
  push r13
  push r14
  // protect the stack
  mov r15 , rsp
  mov rbp , r15
  sub r15 , 32
  mov  rsp , r15
  // set interruption
  sti
  {$IFDEF Win64}
  mov rcx , 1
  {$ELSE WIN64}
  mov edi , 1
  {$ENDIF WIN64}
  // call handler
  Call ATAHandler
  mov rsp , rbp
  // restore the registers
  pop r14
  pop r13
  pop r9
  pop r8
  pop rsi
  pop rdi
  pop rdx
  pop rcx
  pop rbx
  pop rax
  pop rbp
  db $48
  db $cf
end;

function ATAReadBlock(FileDesc: PFileBlock; Block, Count: LongInt; Buffer: Pointer): LongInt;
var
  ncount: LongInt;
  Ctr: PIDEController;
begin
  // protection from local CPU access
  GetDevice(FileDesc.BlockDriver);
  Ctr := @ATAControllers[FileDesc.BlockDriver.Major];
  Block := Block + Ctr.Minors[FileDesc.Minor].StartSector;
  ncount:= 0;
  Ctr.Driver.WaitOn.state := tsSuspended;
  // Sending Commands
  ATAPrepare(Ctr,FileDesc.Minor,Block,Count);
  ATASendCommand(Ctr,ATA_READ);
  repeat
    SysThreadSwitch; // wait for the irq
    if not ATADataReady(Ctr) or ATAError(Ctr) then
      Break; // error in operation
    ATAIn(Buffer, Ctr.IOPort);
    Buffer := Pointer(PtrUInt(Buffer) + 512);
    Inc(ncount);
  until ncount = Count;
  // exiting with the number of blocks readed
  Result := ncount;
  FreeDevice(FileDesc.BlockDriver);
  {$IFDEF DebugIdeDisk} DebugTrace('IdeDisk: ATAReadBlock , Handle: %q, Begin Sector: %d, End Sector: %d',Int64(FileDesc),Block,Block+Ncount); {$ENDIF}
end;


function ATAWriteBlock(FileDesc: PFileBlock;Block,Count: LongInt;Buffer: pointer):LongInt;
var
 ncount: LongInt;
 Ctr: PIDEController;
begin
  // Always do That , protection from local CPU access
  GetDevice(FileDesc.BlockDriver);
  Ctr:= @ATAControllers[FileDesc.BlockDriver.Major];
  // for NOT_FILESYSTEM type that is not important because StartSector is equal to 0
  Block := Block + Ctr.Minors[FileDesc.Minor].StartSector;
  ncount := 0;
  //suspend the thread for wait an irq
  Ctr.Driver.WaitOn.state := tsSuspended;
  ATAPrepare(Ctr,FileDesc.Minor,Block,Count);
  ATASendCommand(Ctr,ATA_WRITE);
  // writing
  repeat
    FileDesc.BlockDriver.WaitOn.state := tsSuspended;
 ATAOut(Buffer, Ctr.IOPort);
    // Waiting the IRQ
    SysThreadSwitch;
    if ATAError(Ctr) then
      Break;
    Buffer:= Pointer(PtrUInt(Buffer)+512);
    Inc(ncount);
    Inc(Block);
  until ncount = Count;
  // exiting with numbers of blocks written
  Result := ncount;
  FreeDevice(FileDesc.BlockDriver);
  {$IFDEF DebugIdeDisk} DebugTrace('IdeDisk: ATAWriteBlock , Handle: %q, Begin Sector: %d, End Sector: %d',Int64(FileDesc),Block,Block+Ncount); {$ENDIF}
end;

// Detection of IDE devices.
procedure IDEInit;
begin
  WriteConsole('Looking for ATA-IDE Disk ...\n',[]);
  // Standart ATA interface
  // Master Controller
  ATAControllers[0].IOPort:= $1f0;
  ATAControllers[0].Irq:= 14;
  ATAControllers[0].IrqHandler:= @ATA0IrqHandler;
  ATAControllers[0].Driver.WaitOn:= nil;
  ATAControllers[0].Driver.Busy:= false;
  ATAControllers[0].Driver.name:= ATANAMES[0];
  ATAControllers[0].Driver.Major:= 0;
  ATAControllers[0].Driver.CPUID:= -1;
  ATAControllers[0].Driver.Dedicate:= @ATADedicate;
  ATAControllers[0].Driver.ReadBlock := @ATAReadBlock;
  ATAControllers[0].Driver.WriteBlock := @ATAWriteBlock;
  ATAControllers[0].Driver.next:= nil;
  // Slave Controller
  ATAControllers[1].IOPort:= $170;
  ATAControllers[1].Irq := 15;
  ATAControllers[1].IrqHandler:= @ATA1IrqHandler;
  ATAControllers[1].Driver.WaitOn:= nil;
  ATAControllers[1].Driver.Busy := false;
  ATAControllers[1].Driver.name := ATANAMES[1];
  ATAControllers[1].Driver.Major:= 1;
  ATAControllers[1].Driver.CPUID := -1;
  ATAControllers[1].Driver.Dedicate := @ATADedicate;
  ATAControllers[1].Driver.ReadBlock := @ATAReadBlock;
  ATAControllers[1].Driver.WriteBlock := @ATAWriteBlock;
  ATAControllers[1].Driver.next:= nil;
  ATADetectController;
end;

// Initialization of Internal Structures.
procedure IdeDiskInit;
var
  I, J: LongInt;
begin
  for I := 0 to MAX_ATA_CONTROLLER-1 do
  begin
    ATAControllers[I].IOPort := 0;
    for J := 0 to MAX_ATA_MINORS-1 do
      ATAControllers[I].Minors[J].Fstype := 0;
 end;
 IDEInit;
end;

initialization
  IdeDiskInit;

end.