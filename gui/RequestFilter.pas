Unit RequestFilter;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

Interface

Uses
  Generics.Collections,
  RequestListModel, IRPMonDll;

Type
  ERequestFilterOperator = (
    rfoEquals,
    rfoNotEquals,
    rfoLowerEquals,
    rfoGreaterEquals,
    rfoLower,
    rfoGreater,
    rfoContains,
    rfoDoesNotContain,
    rfoBegins,
    rfoDoesNotBegin,
    rfoEnds,
    rfoDoesNotEnd,
    rfoAlwaysTrue
  );

  EFilterAction = (
    ffaUndefined,
    ffaInclude,
    ffaNoExclude,
    ffaHighlight,
    ffaPassToFilter
  );

  TRequestFilter = Class
  Private
    FHighlightColor : Cardinal;
    FNextFilter : TRequestFilter;
    FPreviousFilter : TRequestFilter;
    FName : WideString;
    FField : ERequestListModelColumnType;
    FOp : ERequestFilterOperator;
    FStringValue : WideString;
    FIntValue : UInt64;
    FRequestType : ERequestType;
    FEnabled : Boolean;
    FAction : EFilterAction;
  Protected
    Procedure SetEnable(AValue:Boolean);
    Function AddNext(AFilter:TRequestFilter):Cardinal;
    Procedure RemoveFromChain;
  Public
    Constructor Create(AName:WideString; ARequestType:ERequestType = ertUndefined); Reintroduce;

    Procedure GetPossibleValues(AValues:TDictionary<UInt64, WideString>); Virtual; Abstract;

    Function Match(ARequest:TDriverRequest; AChainStart:Boolean = True):TRequestFilter;
    Function SetAction(AAction:EFilterAction; AHighlightColor:Cardinal = 0; ANextFilter:TRequestFilter = Nil):Cardinal;

    Property Name : WideString Read FName Write FName;
    Property Field : ERequestListModelColumnType Read FField;
    Property Op : ERequestFilterOperator Read FOp;
    Property StringValue : WideString Read FStringValue;
    Property IntValue : UInt64 Read FIntValue;
    Property RequestType : ERequesttype Read FRequestType;
    Property Enabled : Boolean Read FEnabled Write SetEnable;
    Property Action : EFilterAction Read FAction;
    Property HighlightColor : Cardinal Read FHighlightColor;
  end;


Implementation

Uses
  SysUtils;

Constructor TRequestFilter.Create(AName:WideString; ARequestType:ERequestType = ertUndefined);
begin
Inherited Create;
FName := AName;
FRequestType := ARequestType;
FOp := rfoAlwaysTrue;
FAction := ffaInclude;
FNextFilter := Nil;
FPreviousFilter := Nil;
end;

Function TRequestFilter.Match(ARequest:TDriverRequest; AChainStart:Boolean = True):TRequestFilter;
Var
  ret : Boolean;
  d : Pointer;
  l : Cardinal;
  iValue : UInt64;
  sValue : WideString;
begin
Result := Nil;
If (FEnabled) And
    ((Not AChainStart) Or (Not Assigned(FPreviousFIlter))) And
   ((FRequestType = ertUndefined) Or (ARequest.RequestType = FRequestType)) Then
  begin
  ret := ARequest.GetColumnValueRaw(FField, d, l);
  If ret Then
    begin
    iValue := 0;
    sValue := '';
    ret := False;
    Case RequestListModelColumnValueTypes[Ord(FField)] Of
      rlmcvtInteger,
      rlmcvtTime,
      rlmcvtMajorFunction,
      rlmcvtMinorFunction,
      rlmcvtProcessorMode,
      rlmcvtIRQL : begin
        Move(d^, iValue, l);
        Case FOp Of
          rfoEquals: ret := (iValue = FIntValue);
          rfoNotEquals: ret := (iValue <> FIntValue);
          rfoLowerEquals: ret := (iValue <= FIntValue);
          rfoGreaterEquals: ret := (iValue >= FIntValue);
          rfoLower: ret := (iValue < FIntValue);
          rfoGreater: ret := (iValue > FIntValue);
          rfoAlwaysTrue: ret := True;
          end;
        end;
      rlmcvtString : begin
        sValue := WideCharToString(d);
        Case FOp Of
          rfoEquals: ret := (WideCompareText(sValue, FStringValue) = 0);
          rfoNotEquals: ret := (WideCompareText(sValue, FStringValue) <> 0);
          rfoLowerEquals: ret := (WideCompareText(sValue, FStringValue) <= 0);
          rfoGreaterEquals: ret := (WideCompareText(sValue, FStringValue) >= 0);
          rfoLower: ret := (WideCompareText(sValue, FStringValue) < 0);
          rfoGreater: ret := (WideCompareText(sValue, FStringValue) > 0);
          rfoContains: ret := (Pos(sValue, FStringValue) > 0);
          rfoDoesNotContain: ret := (Pos(sValue, FStringValue) <= 0);
          rfoBegins: ret := (Pos(sValue, FStringValue) = 1);
          rfoDoesNotBegin: ret := Pos(sValue, FStringValue) <> 1;
          rfoEnds: ret := (Pos(sValue, FStringValue) = Length(FStringValue) - Length(sValue) + 1);
          rfoDoesNotEnd: ret := (Pos(sValue, FStringValue) <> Length(FStringValue) - Length(sValue) + 1);
          rfoAlwaysTrue: ret := True;
          end;
        end;
      end;

    If ret Then
      begin
      Result := Self;
      If (FAction = ffaPassToFilter) And (Assigned(FNextFilter)) Then
        Result := FNextFilter.Match(ARequest, False);
      end;
    end;
  end;
end;


Procedure TRequestFilter.SetEnable(AValue:Boolean);
Var
  tmp : TRequestFilter;
begin
FEnabled := AValue;
tmp := FPreviousFilter;
While Assigned(tmp) Do
  begin
  tmp.FEnabled := AValue;
  tmp := tmp.FPreviousFilter;
  end;

tmp := FNextFilter;
While Assigned(tmp) Do
  begin
  tmp.FEnabled := AValue;
  tmp := tmp.FNextFilter;
  end;
end;

Function TRequestFilter.AddNext(AFilter:TRequestFilter):Cardinal;
begin
Result := 0;
If (FRequestType = ertUndefined) Or (FRequestType = AFilter.FRequestType) Then
  begin
  If (Not Assigned(AFilter.FNextFilter)) And
     (Not Assigned(AFilter.FPreviousFilter)) Then
    begin
    FAction := ffaPassToFilter;
    AFilter.FNextFilter := FNextFilter;
    AFilter.FPreviousFilter := Self;
    FNextFilter := AFIlter;
    end
  Else Result := 2;
  end
Else Result := 1;
end;

Procedure TRequestFilter.RemoveFromChain;
begin
If (Assigned(FNextFilter)) Or (Assigned(FPreviousFilter)) Then
  begin
  FAction := ffaInclude;
  If Assigned(FPreviousFilter) Then
    FPreviousFilter.FNextFilter := FNextFilter;

  If Assigned(FNextFilter) Then
    FNextFilter.FPreviousFilter := FPreviousFilter;

  FNextFilter := Nil;
  FPreviousFilter := Nil;
  end;
end;


Function TRequestFilter.SetAction(AAction:EFilterAction; AHighlightColor:Cardinal = 0; ANextFilter:TRequestFilter = Nil):Cardinal;
begin
Result := 0;
If FAction <> AAction Then
  begin
  If AAction = ffaPassToFilter Then
    begin
    If Assigned(ANextFilter) Then
      Result := AddNext(ANextFilter)
    Else Result := 3;
    end
  Else begin
    FAction := AAction;
    If FAction = ffaHighlight Then
      FHighlightColor := AHighlightColor;
    end;
  end
Else If (FAction = ffaHighlight) Then
  FHighlightColor := AHighlightColor;
end;


End.

