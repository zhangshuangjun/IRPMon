Unit IRPRequest;

Interface

Uses
  Windows,
  RequestListModel, IRPMonDll;

Type
  TIRPRequest = Class (TDriverRequest)
  Private
    FFileObject : Pointer;
    FArgs : TIRPArguments;
    FIRPAddress : Pointer;
    FMajorFunction : Byte;
    FMinorFunction : Byte;
    FPreviousMode : Byte;
    FRequestorMode : Byte;
    FIRPFlags : Cardinal;
    FProcessId : THandle;
    FThreadId : THandle;
  Public
    Constructor Create(Var ARequest:REQUEST_IRP); Reintroduce;

    Function GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean; Override;
    Class Function PowerStateTypeToString(AType:Cardinal):WideString;
    Class Function PowerStateToString(AType:Cardinal; AState:Cardinal):WideString;
    Class Function ShutdownTypeToString(AType:Cardinal):WideString;
    Class Function Build(Var ARequest:REQUEST_IRP):TIRPRequest;

    Property FileObject : Pointer Read FFileObject;
    Property Args : TIRPArguments Read FArgs;
    Property Address : Pointer Read FIRPAddress;
    Property MajorFunction : Byte Read FMajorFunction;
    Property MinorFunction : Byte Read FMinorFunction;
    Property RequestorMode : Byte Read FRequestorMode;
    Property PreviousMode : Byte Read FPreviousMode;
    Property IRPFlags : Cardinal Read FIRPFlags;
    Property ProcessId : THandle Read FProcessId;
    Property ThreadId : THandle Read FThreadId;
  end;

  TDeviceControlRequest = Class (TIRPRequest)
    Public
      Function GetColumnName(AColumnType:ERequestListModelColumnType):WideString; Override;
      Function GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean; Override;
    end;

  TReadWriteRequest = Class (TIRPRequest)
    Public
      Function GetColumnName(AColumnType:ERequestListModelColumnType):WideString; Override;
      Function GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean; Override;
    end;

  TQuerySetRequest = Class (TIRPRequest)
    Public
      Function GetColumnName(AColumnType:ERequestListModelColumnType):WideString; Override;
      Function GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean; Override;
    end;

  TWaitWakeRequest = Class (TIRPRequest)
    Public
      Function GetColumnName(AColumnType:ERequestListModelColumnType):WideString; Override;
      Function GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean; Override;
    end;

  TPowerSequenceRequest = Class (TIRPRequest)
    Public
      Function GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean; Override;
    end;

  TQuerySetPowerRequest = Class (TIRPRequest)
    Public
      Function GetColumnName(AColumnType:ERequestListModelColumnType):WideString; Override;
      Function GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean; Override;
    end;

  TCloseCleanupRequest = Class (TIRPRequest)
    Public
      Function GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean; Override;
    end;

Implementation

Uses
  SysUtils;

(** TIRPRequest **)

Constructor TIRPRequest.Create(Var ARequest:REQUEST_IRP);
begin
Inherited Create(ARequest.Header);
FMajorFunction := ARequest.MajorFunction;
FMinorFunction := ARequest.MinorFunction;
FPreviousMode := ARequest.PreviousMode;
FRequestorMode := ARequest.RequestorMode;
FIRPAddress := ARequest.IRPAddress;
FIRPFlags := ARequest.IrpFlags;
FFileObject := ARequest.FileObject;
FArgs := ARequest.Args;
end;


Function TIRPRequest.GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean;
begin
Result := True;
Case AColumnType Of
  rlmctSubType: AResult := Format('%s:%s', [MajorFunctionToString(FMajorFunction), MinorFunctionToString(FMajorFunction, FMinorFunction)]);
  rlmctIRPAddress: AResult := Format('0x%p', [FIRPAddress]);
  rlmctFileObject: AResult := Format('0x%p', [FFileObject]);
  rlmctIRPFlags: AResult := Format('0x%x', [FIRPFlags]);
  rlmctArg1: AResult := Format('0x%p', [FArgs.Other.Arg1]);
  rlmctArg2: AResult := Format('0x%p', [FArgs.Other.Arg2]);
  rlmctArg3: AResult := Format('0x%p', [FArgs.Other.Arg3]);
  rlmctArg4: AResult := Format('0x%p', [FArgs.Other.Arg4]);
  rlmctPreviousMode: AResult := AccessModeToString(FPreviousMode);
  rlmctRequestorMode: AResult := AccessModeToString(FRequestorMode);
  Else Result := Inherited GetColumnValue(AColumnType, AResult);
  end;
end;

Class Function TIRPRequest.PowerStateTypeToString(AType:Cardinal):WideString;
begin
Case AType Of
  0 : Result := 'System';
  1 : Result := 'Device';
  Else Result := Format('%u', [AType]);
  end;
end;

Class Function TIRPRequest.PowerStateToString(AType:Cardinal; AState:Cardinal):WideString;
begin
Result := Format('%u', [AState]);
If AType = 0 Then
  begin
  Case AState Of
    0 : Result := 'PowerSystemUnspecified';
    1 : Result := 'PowerSystemWorking';
    2 : Result := 'PowerSystemSleeping1';
    3 : Result := 'PowerSystemSleeping2';
    4 : Result := 'PowerSystemSleeping3';
    5 : Result := 'PowerSystemHibernate';
    6 : Result := 'PowerSystemShutdown';
    7 : Result := 'PowerSystemMaximum';
    end;
  end
Else If AType = 1 Then
  begin
  Case AState Of
    0 : Result := 'PowerDeviceUnspecified';
    1 : Result := 'PowerDeviceD0';
    2 : Result := 'PowerDeviceD1';
    3 : Result := 'PowerDeviceD2';
    4 : Result := 'PowerDeviceD3';
    end;
  end;
end;

Class Function TIRPRequest.ShutdownTypeToString(AType:Cardinal):WideString;
begin
Case AType Of
  0 : Result := 'PowerActionNone';
  1 : Result := ' PowerActionReserved';
  2 : Result := ' PowerActionSleep';
  3 : Result := ' PowerActionHibernate';
  4 : Result := ' PowerActionShutdown';
  5 : Result := ' PowerActionShutdownReset';
  6 : Result := ' PowerActionShutdownOff';
  7 : Result := ' PowerActionWarmEject';
  end;
end;

Class Function TIRPRequest.Build(Var ARequest:REQUEST_IRP):TIRPRequest;
begin
Result := Nil;
Case ARequest.MajorFunction Of
  2, 18 : Result := TCloseCleanupRequest.Create(ARequest);
  3, 4   : Result := TReadWriteRequest.Create(ARequest);
  5, 6   : Result := TQuerySetRequest.Create(ARequest);
  10, 11 : ; // QuerySetVolume
  12 : ;     // DirectoryControl
  13 : ;     // FsControl
  14, 15 : Result := TDeviceControlRequest.Create(ARequest);
  22 : begin
    Case ARequest.MinorFunction Of
      0 : Result := TWaitWakeRequest.Create(ARequest);
      1 : Result := TPowerSequenceRequest.Create(ARequest);
      2, 3 : Result := TQuerySetPowerRequest.Create(ARequest);
      end;
    end;
  27 : ; // PnP
  end;

If Not Assigned(Result) Then
  Result := TIRPRequest.Create(ARequest);
end;

(** TDeviceControlRequest **)

Function TDeviceControlRequest.GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean;
begin
Result := True;
Case AColumnType Of
  rlmctArg1: AResult := Format('O: %u (0x%p)', [FArgs.DeviceControl.OutputBufferLength, Pointer(Args.DeviceControl.OutputBufferLength)]);
  rlmctArg2: AResult := Format('I: %u (0x%p)', [FArgs.DeviceControl.InputBufferLength, Pointer(Args.DeviceControl.InputBufferLength)]);
  rlmctArg3: AResult := IOCTLToString(FArgs.DeviceControl.IoControlCode);
  rlmctArg4: Result := False;
  Else Result := Inherited GetColumnValue(AColumnType, AResult);
  end;
end;

Function TDeviceControlRequest.GetColumnName(AColumnType:ERequestListModelColumnType):WideString;
begin
Case AColumnType Of
  rlmctArg1 : Result := 'Output length';
  rlmctArg2 : Result := 'Input length';
  rlmctArg3 : Result := 'IOCTL';
  rlmctArg4 : Result := 'Type3 input';
  Else Result := Inherited GetColumnName(AColumnType);
  end;
end;

(** TReadWriteRequest **)

Function TReadWriteRequest.GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean;
begin
Result := True;
Case AColumnType Of
  rlmctArg1: AResult := Format('L: %u', [FArgs.ReadWrite.Length]);
  rlmctArg2: AResult := Format('K: 0x%x', [FArgs.ReadWrite.Key]);
  rlmctArg3: AResult := Format('O: 0x%x', [FArgs.ReadWrite.ByteOffset]);
  rlmctArg4: Result := False;
  Else Result := Inherited GetColumnValue(AColumnType, AResult);
  end;
end;

Function TReadWriteRequest.GetColumnName(AColumnType:ERequestListModelColumnType):WideString;
begin
Case AColumnType Of
  rlmctArg1 : Result := 'Length';
  rlmctArg2 : Result := 'Key';
  rlmctArg3 : Result := 'Offset';
  rlmctArg4 : Result := '';
  Else Result := Inherited GetColumnName(AColumnType);
  end;
end;

(** TQuerySetRequest **)

Function TQuerySetRequest.GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean;
begin
Result := True;
Case AColumnType Of
  rlmctArg1: AResult := Format('L: %u', [FArgs.QuerySetInformation.Lenth]);
  rlmctArg2: AResult := Format('I: %u', [FArgs.QuerySetInformation.FileInformationClass]);
  rlmctArg3,
  rlmctArg4: Result := False
  Else Result := Inherited GetColumnValue(AColumnType, AResult);
  end;
end;

Function TQuerySetRequest.GetColumnName(AColumnType:ERequestListModelColumnType):WideString;
begin
Case AColumnType Of
  rlmctArg1 : Result := 'Length';
  rlmctArg2 : Result := 'Information class';
  Else Result := Inherited GetColumnName(AColumnType);
  end;
end;

(** TWaitWakeRequest **)

Function TWaitWakeRequest.GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean;
begin
Result := True;
Case AColumnType Of
  rlmctArg1 : AResult := PowerStateToString(1, FArgs.WaitWake.PowerState);
  rlmctArg2,
  rlmctArg3,
  rlmctArg4 : Result := False;
  Else Result := Inherited GetColumnValue(AColumnType, AResult);
  end;
end;

Function TWaitWakeRequest.GetColumnName(AColumnType:ERequestListModelColumnType):WideString;
begin
Case AColumnType Of
  rlmctArg1 : Result := 'Power state';
  Else Result := Inherited GetColumnName(AColumnType);
  end;
end;

(** TPowerSequenceRequest **)

Function TPowerSequenceRequest.GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean;
begin
Result := True;
Case AColumnType Of
  rlmctArg1,
  rlmctArg2,
  rlmctArg3,
  rlmctArg4 : Result := False;
  Else Result := Inherited GetColumnValue(AColumnType, AResult);
  end;
end;

(** TQuerySetPowerRequest **)

Function TQuerySetPowerRequest.GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean;
begin
Result := True;
Case AColumnType Of
  rlmctArg1 : AResult := Format('%u', [FArgs.QuerySetPower.SystemContext]);
  rlmctArg2 : AResult := PowerStateTypeToString(FArgs.QuerySetPower.PowerStateType);
  rlmctArg3 : AResult := PowerStateToString(FArgs.QuerySetPower.PowerStateType, FArgs.QuerySetPower.PowerState);
  rlmctArg4 : AResult := ShutdownTypeToString(FArgs.QuerySetPower.ShutdownType);
  Else Result := Inherited GetColumnValue(AColumnType, AResult);
  end;
end;

Function TQuerySetPowerRequest.GetColumnName(AColumnType:ERequestListModelColumnType):WideString;
begin
Case AColumnType Of
  rlmctArg1 : Result := 'System context';
  rlmctArg2 : Result := 'Power state type';
  rlmctArg3 : Result := 'Power state';
  rlmctArg4 : Result := 'Shutdown type';
  end;
end;

(** TCloseCleanupRequest **)

Function TCloseCleanupRequest.GetColumnValue(AColumnType:ERequestListModelColumnType; Var AResult:WideString):Boolean;
begin
Result := True;
Case AColumnType Of
  rlmctArg1,
  rlmctArg2,
  rlmctArg3,
  rlmctArg4 : Result := False;
  Else Result := Inherited GetColumnValue(AColumnType, AResult);
  end;
end;


End.
