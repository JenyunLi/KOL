{

       Unit: KOLMidiIn
    purpose: Midi Input
     Author: KOL translation and > 64 sysex buffering: Thaddy de Koning
             Original Author: David Churcher
  Copyright: released to the public domain
    Remarks: Well known Great components.
             Do not confuse this with my project JEDI midi translation for KOL
}
{ $Header: /MidiComp/Midiin.pas 2     10/06/97 7:33 Davec $ }

{ Written by David Churcher <dchurcher@cix.compulink.co.uk>,
  released to the public domain. }

unit KOLMIDIIN;

{
  Properties:
	DeviceID: 	Windows numeric device ID for the MIDI input device.
	Between 0 and NumDevs-1.
	Read-only while device is open, exception when changed while open

	MIDIHandle:	The input handle to the MIDI device.
	0 when device is not open
	Read-only, runtime-only

	MessageCount:	Number of input messages waiting in input buffer

	Capacity:	Number of messages input buffer can hold
	Defaults to 1024
	Limited to (64K/event size)
	Read-only when device is open (exception when changed while open)

	SysexBufferSize:	Size in bytes of each sysex buffer
	Defaults to 10K
	Minimum 0K (no buffers), Maximum 64K-1

	SysexBufferCount:	Number of sysex buffers
	Defaults to 16
	Minimum 0 (no buffers), Maximum (avail mem/SysexBufferSize)
	Check where these buffers are allocated?

	SysexOnly: True to ignore all non-sysex input events. May be changed while
	device is open. Handy for patch editors where you have lots of short MIDI
	events on the wire which you are always going to ignore anyway.

	DriverVersion: Version number of MIDI device driver. High-order byte is
	major version, low-order byte is minor version.

	ProductName: Name of product (e.g. 'MPU 401 In')

	MID and PID: Manufacturer ID and Product ID, see
	"Manufacturer and Product IDs" in MMSYSTEM.HLP for list of possible values.

  Methods:
	GetMidiEvent: Read Midi event at the head of the FIFO input buffer.
	Returns a TMyMidiEvent object containing MIDI message data, timestamp,
	and sysex data if applicable.
	This method automatically removes the event from the input buffer.
	It makes a copy of the received sysex buffer and puts the buffer back
	on the input device.
	The TMyMidiEvent object must be freed by calling MyMidiEvent.Free.

	Open: Opens device. Note no input will appear until you call the Start
	method.

	Close: Closes device. Any pending system exclusive output will be cancelled.

	Start: Starts receiving MIDI input.

	Stop: Stops receiving MIDI input.

  Events:
	OnMidiInput: Called when MIDI input data arrives. Use the GetMidiEvent to
	get the MIDI input data.

	OnOverflow: Called if the MIDI input buffer overflows. The caller must
	clear the buffer before any more MIDI input can be received.

 Notes:
	Buffering: Uses a circular buffer, separate pointers for next location
	to fill and next location to empty because a MIDI input interrupt may
	be adding data to the buffer while the buffer is being read. Buffer
	pointers wrap around from end to start of buffer automatically. If
	buffer overflows then the OnBufferOverflow event is triggered and no
	further input will be received until the buffer is emptied by calls
	to GetMidiEvent.

	Sysex buffers: There are (SysexBufferCount) buffers on the input device.
	When sysex events arrive these buffers are removed from the input device and
	added to the circular buffer by the interrupt handler in the DLL.  When the sysex events
	are removed from the circular buffer by the GetMidiEvent method the buffers are
	put back on the input. If all the buffers are used up there will be no
	more sysex input until at least one sysex event is removed from the input buffer.
	In other	words if you're expecting lots of sysex input you need to set the
	SysexBufferCount property high enough so that you won't run out of
	input buffers before you get a chance to read them with GetMidiEvent.

	If the synth sends a block of sysex that's longer than SysexBufferSize it
	will be received as separate events.
	TODO: Component derived from this one that handles >64K sysex blocks cleanly
	and can stream them to disk.

	Midi Time Code (MTC) and Active Sensing: The DLL is currently hardcoded
	to filter these short events out, so that we don't spend all our time
	processing them.
	TODO: implement a filter property to select the events that will be filtered
	out.
}

interface
{.$DEFINE USE_ERR}
uses
  Kol, windows, {$IFDEF USE_ERR}err,{$ENDIF} Messages, MMSystem, KolMidiDefs, KolMidiType,
  KolMidiCons, KolCircbuf, KolDelphmcb,objects;

type
	MidiInputState = (misOpen, misClosed, misCreating, misDestroying);
  {$IFDEF USE_ERR}
	EMidiInputError = Exception;
  {$ENDIF}
	{-------------------------------------------------------------------}
  pMidiInput = ^TMidiInput;
  TMidiInput = object(Tobj)
  private
	Handle: THandle;				{ Window handle used for callback notification }
	FDeviceID: Word;				{ MIDI device ID }
	FMIDIHandle: HMIDIIn;		{ Handle to input device }
	FState: MidiInputState;			{ Current device state }

	FError: Word;
	FSysexOnly: Boolean;

	{ Stuff from MIDIINCAPS }
	FDriverVersion: Version;
	FProductName: string;
	FMID: Word;						{ Manufacturer ID }
	FPID: Word;						{ Product ID }

	{ Queue }
   FCapacity: dWord; 		{ Buffer capacity }
   PBuffer: PCircularBuffer;	{ Low-level MIDI input buffer created by Open method }
   FNumdevs: Word;			{ Number of input devices on system }

	{ Events }
	FOnMIDIInput: TOnEvent;	{ MIDI Input arrived }
    FOnOverflow: TOnEvent;		{ Input buffer overflow }
	{ TODO: Some sort of error handling event for MIM_ERROR }

	{ Sysex }
	FSysexBufferSize:  dWord;
	FSysexBufferCount: Word;
	MidiHdrs: plist;

	PCtlInfo: PMidiCtlInfo;	{ Pointer to control info for DLL }

  protected
	procedure Prepareheaders;
	procedure UnprepareHeaders;
	procedure AddBuffers;
	procedure SetDeviceID(aDeviceID: Word);
	procedure SetProductName( NewProductName: String );
	function GetEventCount: dWord;
	procedure SetSysexBufferSize(BufferSize: dWord);
	procedure SetSysexBufferCount(BufferCount: Word);
	procedure SetSysexOnly(bSysexOnly: Boolean);
	function MidiInErrorString( WError: Word ): String;

  public
	destructor Destroy; virtual;

	property MIDIHandle: HMIDIIn read FMIDIHandle;

	property DriverVersion: Version read FDriverVersion;
	property MID: Word read FMID;						{ Manufacturer ID }
	property PID: Word read FPID;						{ Product ID }

	property Numdevs: Word read FNumdevs;

	property MessageCount: dWord read GetEventCount;
	{ TODO: property to select which incoming messages get filtered out }

	procedure Open;
	procedure Close;
	procedure Start;
	procedure Stop;
	{ Get first message in input queue }
	function GetMidiEvent: PMyMidiEvent;
	procedure MidiInput(var Message: TMessage);

   { Some functions to decode and classify incoming messages would be good }


	property ProductName: String read FProductName write SetProductName;

	property DeviceID: Word read FDeviceID write SetDeviceID default 0;
	property Capacity: dWord read FCapacity write FCapacity default 1024;
	property Error: Word read FError;
	property SysexBufferSize: dWord
		read FSysexBufferSize
		write SetSysexBufferSize
		default 10000;
	property SysexBufferCount: Word
		read FSysexBufferCount
		write SetSysexBufferCount
		default 16;
	property SysexOnly: Boolean
		read FSysexOnly
		write SetSysexOnly
		default False;

	{ Events }
	property OnMidiInput: TOnEvent read FOnMidiInput write FOnMidiInput;
	property OnOverflow: TOnEvent read FOnOverflow write FOnOverflow;

end;

function NewMidiInput(aOwner:pControl):pMidiInput;

{====================================================================}
implementation


{-------------------------------------------------------------------}
function NewMidiInput(aOwner:pControl):pMidiInput;
begin
  New(Result, Create);
  aOwner.Add2AutoFree(Result);
  with Result^ do
  begin
	FState := misCreating;

	FSysexOnly := False;
	FNumDevs := midiInGetNumDevs;
    MidiHdrs := Nil;

	{ Set defaults }
	SetDeviceID(0);
	FCapacity := 1024;
	FSysexBufferSize := 4096;
	FSysexBufferCount := 16;

	{ Create the window for callback notification }
		begin
		Handle := AllocateHwnd(MidiInput);
		end;

	FState := misClosed;
   end;
end;

{-------------------------------------------------------------------}
{ Close the device if it's open }
destructor TMidiInput.Destroy;
begin
	if (FMidiHandle <> 0) then
		begin
		Close;
		FMidiHandle := 0;
		end;

	if (PCtlInfo <> Nil) then
		GlobalSharedLockedFree( PCtlinfo^.hMem, PCtlInfo );

	DeallocateHwnd(Handle);
	inherited Destroy;
end;

{-------------------------------------------------------------------}
{ Convert the numeric return code from an MMSYSTEM function to a string
  using midiInGetErrorText. TODO: These errors aren't very helpful
  (e.g. "an invalid parameter was passed to a system function") so
  sort out some proper error strings. }
function TMidiInput.MidiInErrorString( WError: Word ): String;
var
	errorDesc: String;
begin
	try
		setlength(errorDesc,MAXERRORLENGTH);
		if midiInGetErrorText(WError, Pchar(errorDesc), MAXERRORLENGTH) = 0 then
			result := errorDesc
		else
			result := 'Specified error number is out of range';
	finally
   ;
	end;
end;

{-------------------------------------------------------------------}
{ Set the sysex buffer size, fail if device is already open }
procedure TMidiInput.SetSysexBufferSize(BufferSize: dWord);
begin
	if FState = misOpen then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}'Change to SysexBufferSize while device was open')
	else
		{ TODO: Validate the sysex buffer size. Is this necessary for WIN32? }
		FSysexBufferSize := BufferSize;
end;

{-------------------------------------------------------------------}
{ Set the sysex buffer count, fail if device is already open }
procedure TMidiInput.SetSysexBuffercount(Buffercount: Word);
begin
	if FState = misOpen then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}    'Change to SysexBuffercount while device was open')
	else
		{ TODO: Validate the sysex buffer count }
		FSysexBuffercount := Buffercount;
end;

{-------------------------------------------------------------------}
{ Set the Sysex Only flag to eliminate unwanted short MIDI input messages }
procedure TMidiInput.SetSysexOnly(bSysexOnly: Boolean);
begin
	FSysexOnly := bSysexOnly;
	{ Update the interrupt handler's copy of this property }
	if PCtlInfo <> Nil then
		PCtlInfo^.SysexOnly := bSysexOnly;
end;

{-------------------------------------------------------------------}
{ Set the Device ID to select a new MIDI input device
  Note: If no MIDI devices are installed, throws an 'Invalid Device ID' exception }
procedure TMidiInput.SetDeviceID(aDeviceID: Word);
var
	MidiInCaps: TMidiInCaps;
begin
	if FState = misOpen then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}    'Change to DeviceID while device was open')
	else
		if (aDeviceID >= midiInGetNumDevs) then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}      'Invalid device ID')
		else
			begin
			FDeviceID := aDeviceID;

			{ Set the name and other MIDIINCAPS properties to match the ID }
			FError :=
				midiInGetDevCaps(aDeviceID, @MidiInCaps, sizeof(TMidiInCaps));
			if Ferror <> MMSYSERR_NOERROR then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}        MidiInErrorString(FError));

			FProductName := MidiInCaps.szPname;
			FDriverVersion := MidiInCaps.vDriverVersion;
			FMID := MidiInCaps.wMID;
			FPID := MidiInCaps.wPID;

			end;
end;

{-------------------------------------------------------------------}
{ Set the product name and put the matching input device number in FDeviceID.
  This is handy if you want to save a configured input/output device
  by device name instead of device number, because device numbers may
  change if users add or remove MIDI devices.
  Exception if input device with matching name not found,
  or if input device is open }
procedure TMidiInput.SetProductName( NewProductName: String );
var
	MidiInCaps: TMidiInCaps;
	testDeviceID: Word;
	testProductName: String;
begin
	if FState = misOpen then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}    'Change to ProductName while device was open')
	else
  { Don't set the name if the component is reading properties because
	the saved Productname will be from the machine the application was compiled
	on, which may not be the same for the corresponding DeviceID on the user's
	machine. The FProductname property will still be set by SetDeviceID }
	begin
		begin
		for testDeviceID := 0 To (midiInGetNumDevs-1) do
			begin
			FError :=
				midiInGetDevCaps(testDeviceID, @MidiInCaps, sizeof(TMidiInCaps));
			if Ferror <> MMSYSERR_NOERROR then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}        MidiInErrorString(FError));
			testProductName := (MidiInCaps.szPname);
			if testProductName = NewProductName then
				begin
				FProductName := NewProductName;
				Break;
				end;
			end;
		if FProductName <> NewProductName then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}      'MIDI Input Device ' +
				NewProductName + ' not installed ')
		else
			SetDeviceID(testDeviceID);
		end;
	end;
end;


{-------------------------------------------------------------------}
{ Get the sysex buffers ready }
procedure TMidiInput.PrepareHeaders;
var
	ctr: Word;
	MyMidiHdr: PMyMidiHdr;
begin
	if (FSysexBufferCount > 0) And (FSysexBufferSize > 0)
		And (FMidiHandle <> 0) then
		begin
		Midihdrs := Newlist;//TList.Create;
		for ctr := 1 to FSysexBufferCount do
			begin
			{ Initialize the header and allocate buffer memory }
			MyMidiHdr := NewMidiHeader(FSysexBufferSize);

			{ Store the address of the MyMidiHdr object in the contained MIDIHDR
              structure so we can get back to the object when a pointer to the
              MIDIHDR is received.
              E.g. see TMidiOutput.Output method }
			MyMidiHdr.hdrPointer^.dwUser := DWORD(MyMidiHdr);

			{ Get MMSYSTEM's blessing for this header }
			FError := midiInPrepareHeader(FMidiHandle,MyMidiHdr.hdrPointer,
				sizeof(TMIDIHDR));
			if Ferror <> MMSYSERR_NOERROR then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}        MidiInErrorString(FError));

			{ Save it in our list }
			MidiHdrs.Add(MyMidiHdr);
			end;
		end;

end;

{-------------------------------------------------------------------}
{ Clean up from PrepareHeaders }
procedure TMidiInput.UnprepareHeaders;
var
	ctr: Word;
begin
    if (MidiHdrs<> Nil) then	{ will be Nil if 0 sysex buffers }
 	   begin
       for ctr := 0 To MidiHdrs.Count-1 do
       		begin
            FError := midiInUnprepareHeader( FMidiHandle,
            	PMyMidiHdr(MidiHdrs.Items[ctr]).hdrPointer,
                sizeof(TMIDIHDR));
            if Ferror <> MMSYSERR_NOERROR then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}              MidiInErrorString(FError));
            PMyMidiHdr(MidiHdrs.Items[ctr]).Free;
       		end;
       MidiHdrs.Free;
       MidiHdrs := Nil;
       end;
end;

{-------------------------------------------------------------------}
{ Add sysex buffers, if required, to input device }
procedure TMidiInput.AddBuffers;
var
	ctr: Word;
begin
	if MidiHdrs <> Nil then		{ will be Nil if 0 sysex buffers }
    	begin
        if MidiHdrs.Count > 0 Then
            begin
            for ctr := 0 To MidiHdrs.Count-1 do
                begin
                FError := midiInAddBuffer(FMidiHandle,
                    PMyMidiHdr(MidiHdrs.Items[ctr]).hdrPointer,
                    sizeof(TMIDIHDR));
                If FError <> MMSYSERR_NOERROR then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}                    MidiInErrorString(FError));
                end;
            end;
        end;
end;

{-------------------------------------------------------------------}
procedure TMidiInput.Open;
var
	hMem: THandle;
begin
	try
		{ Create the buffer for the MIDI input messages }
		If (PBuffer = Nil) then
			PBuffer := CircBufAlloc( FCapacity );

		{ Create the control info for the DLL }
		if (PCtlInfo = Nil) then
			begin
			PCtlInfo := GlobalSharedLockedAlloc( Sizeof(TMidiCtlInfo), hMem );
			PctlInfo^.hMem := hMem;
			end;
		PctlInfo^.pBuffer := PBuffer;
		Pctlinfo^.hWindow := Handle;	{ Control's window handle }
		PCtlInfo^.SysexOnly := FSysexOnly;
		FError := midiInOpen(@FMidiHandle, FDeviceId,
						DWORD(@midiHandler),
						DWORD(PCtlInfo),
						CALLBACK_FUNCTION);

		If (FError <> MMSYSERR_NOERROR) then
			{ TODO: use CreateFmtHelp to add MIDI device name/ID to message }
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}      MidiInErrorString(FError));

		{ Get sysex buffers ready }
		PrepareHeaders;

		{ Add them to the input }
		AddBuffers;

		FState := misOpen;

	except
		if PBuffer <> Nil then
			begin
			CircBufFree(PBuffer);
			PBuffer := Nil;
			end;

		if PCtlInfo <> Nil then
			begin
			GlobalSharedLockedFree(PCtlInfo^.hMem, PCtlInfo);
			PCtlInfo := Nil;
			end;

	end;

end;

{-------------------------------------------------------------------}
function TMidiInput.GetMidiEvent: PMyMidiEvent;
var
	thisItem: TMidiBufferItem;
begin
	if (FState = misOpen) and
		CircBufReadEvent(PBuffer, @thisItem) then
		begin
		Result := NewMidiEvent;
		with thisItem Do
			begin
			Result.Time := Timestamp;
			if (Sysex = Nil) then
				begin
				{ Short message }
				Result.MidiMessage := LoByte(LoWord(Data));
				Result.Data1 := HiByte(LoWord(Data));
				Result.Data2 := LoByte(HiWord(Data));
				Result.Sysex := Nil;
				Result.SysexLength := 0;
				end
			else
            	{ Long Sysex message }
				begin
				Result.MidiMessage := MIDI_BEGINSYSEX;
				Result.Data1 := 0;
				Result.Data2 := 0;
				Result.SysexLength := Sysex^.dwBytesRecorded;
				if Sysex^.dwBytesRecorded <> 0 then
					begin
					{ Put a copy of the sysex buffer in the object }
					GetMem(Result.Sysex, Sysex^.dwBytesRecorded);
					StrLCopy(Result.Sysex, Sysex^.lpData, Sysex^.dwBytesRecorded);
					end;

				{ Put the header back on the input buffer }
				FError := midiInPrepareHeader(FMidiHandle,Sysex,
					sizeof(TMIDIHDR));
				If Ferror = 0 then
					FError := midiInAddBuffer(FMidiHandle,
						Sysex, sizeof(TMIDIHDR));
				if Ferror <> MMSYSERR_NOERROR then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}          MidiInErrorString(FError));
				end;
			end;
		CircbufRemoveEvent(PBuffer);
		end
	else
		{ Device isn't open, return a nil event }
		Result := Nil;
end;

{-------------------------------------------------------------------}
function TMidiInput.GetEventCount: dWord;
begin
	if FState = misOpen then
		Result := PBuffer^.EventCount
	else
		Result := 0;
end;

{-------------------------------------------------------------------}
procedure TMidiInput.Close;
begin
	if FState = misOpen then
		begin
		FState := misClosed;

		{ MidiInReset cancels any pending output.
		Note that midiInReset causes an MIM_LONGDATA callback for each sysex
		buffer on the input, so the callback function and Midi input buffer
		should still be viable at this stage.
		All the resulting MIM_LONGDATA callbacks will be completed by the time
		MidiInReset returns, though. }
		FError := MidiInReset(FMidiHandle);
		if Ferror <> MMSYSERR_NOERROR then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}      MidiInErrorString(FError));

		{ Remove sysex buffers from input device and free them }
		UnPrepareHeaders;

		{ Close the device (finally!) }
		FError := MidiInClose(FMidiHandle);
		if Ferror <> MMSYSERR_NOERROR then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}      MidiInErrorString(FError));

		FMidiHandle := 0;

		If (PBuffer <> Nil) then
			begin
			CircBufFree( PBuffer );
			PBuffer := Nil;
			end;
		end;
end;

{-------------------------------------------------------------------}
procedure TMidiInput.Start;
begin
	if FState = misOpen then
		begin
		FError := MidiInStart(FMidiHandle);
		if Ferror <> MMSYSERR_NOERROR then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}      MidiInErrorString(FError));
		end;
end;

{-------------------------------------------------------------------}
procedure TMidiInput.Stop;
begin
	if FState = misOpen then
		begin
		FError := MidiInStop(FMidiHandle);
		if Ferror <> MMSYSERR_NOERROR then
  {$IFDEF USE_ERR}
		raise EMidiInputError.Create(e_Custom,
  {$ELSE}
  MsgOk(
  {$ENDIF}      MidiInErrorString(FError));
		end;
end;

{-------------------------------------------------------------------}
procedure TMidiInput.MidiInput( var Message: TMessage );
{ Triggered by incoming message from DLL.
  Note DLL has already put the message in the queue }
begin
	case Message.Msg of
	mim_data:
		{ Trigger the user's MIDI input event, if they've specified one and
		we're not in the process of closing the device. The check for
		GetEventCount > 0 prevents unnecessary event calls where the user has
		already cleared all the events from the input buffer using a GetMidiEvent
		loop in the OnMidiInput event handler }
		if Assigned(FOnMIDIInput) and (FState = misOpen)
			and (GetEventCount > 0) then
			FOnMIDIInput(@Self);

	mim_Overflow:	{ input circular buffer overflow }
		if Assigned(FOnOverflow) and (FState = misOpen) then
			FOnOverflow(@Self);
	end;
end;

{-------------------------------------------------------------------}

end.
