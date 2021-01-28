unit uThumbnail;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Types, System.IOUtils, System.StrUtils, Vcl.Graphics, Vcl.Imaging.jpeg,
  Vcl.Imaging.pngimage, System.Generics.Collections, System.SyncObjs, Math
  {$IFDEF DEBUG}
  //, DbugIntf
  {$ENDIF}
  ;
Type

  TImageContainer = class (TObject)
  public
    FPath: String;
    FImage: TBitmap;
    Floaded: Boolean;
    Fx, Fy, Fw, Fh: Integer;
    constructor Create;
    destructor destroy; override;
 end;

  TImageThread = class(TThread)
  private
    FFileList: TStringList;
    FPaused:Boolean;
    FFirstImage: integer;
    FImageCount: integer;
    FRunEvent, FTermEvent: TEvent;
    FWaitEvents: THandleObjectArray;
    procedure CheckPause;
  protected
    procedure Execute; override;
    procedure TerminatedSet; override;
    function GetThumbnail(aW, aH:Integer; aPath:String): TBitmap;
  public
    property Terminated;
    property Paused: Boolean read FPaused;
    constructor Create(aFileslist: TStringList); reintroduce;
    procedure SynkPainBox;
    procedure Pause;
    procedure Unpause;
    destructor Destroy; override;
  end;

implementation

uses
  uMain;
{ TImageContainer }

constructor TImageContainer.Create;
begin
 inherited;
 FPath:= '';
 FImage:= TBitmap.Create;
end;

destructor TImageContainer.destroy;
begin
  if Assigned(FImage) then
    FImage.Destroy;
  inherited;
end;

{ TImageThread }

procedure TImageThread.CheckPause;
var
  SignaledEvent: THandleObject;
begin
  while not Terminated do
  begin
    case TEvent.WaitForMultiple(FWaitEvents, INFINITE, False, SignaledEvent) of
      wrSignaled:
      begin
        if SignaledEvent = FRunEvent then
        Exit;
        Break;
      end;
      wrIOCompletion:
      begin
        // retry
      end;
      wrError:
        RaiseLastOSError;
    end;
  end;
  System.SysUtils.Abort;
end;

constructor TImageThread.Create(aFileslist: TStringList);
begin
  inherited Create(False);//Create(True);

  FPaused:= False;
  FRunEvent := TEvent.Create(nil, True, True, '');
  FTermEvent := TEvent.Create(nil, True, False, '');

  SetLength(FWaitEvents, 2);
  FWaitEvents[0] := FRunEvent;
  FWaitEvents[1] := FTermEvent;

  FFileList:= aFileslist;
end;

destructor TImageThread.Destroy;
begin
  Terminate;
  FRunEvent.Free;
  FTermEvent.Free;
  inherited;
end;

procedure TImageThread.Execute;
var
  Events: array[0..1] of THandle;
  WaitResult: DWORD;
  lImageContainer: TImageContainer;
  i:Integer;
begin
  while not Terminated do
  begin
    try
    //SendMethodEnter('TImageThread.Execute');
    lImageContainer := nil;
    CheckPause;
    begin
      if Assigned(FFileList) then
      begin

        FFirstImage := max((fMain.FPageNum)*fMain.FImagePerPage, 0);
        FImageCount := min((fMain.FPageNum+1)*fMain.FImagePerPage, FFileList.Count);

        //SendDebug('Thread Execute Start '+IntToStr(FFileList.Count)+' FFirstImage='+IntToStr(FFirstImage)+' FImageCount='+IntToStr(FImageCount));
        for i := FFirstImage to FImageCount - 1 do
        begin
          try
          lImageContainer:= TImageContainer(FFileList.Objects[i]);
          lImageContainer.FImage := GetThumbnail(100, 100, lImageContainer.FPath);
          if lImageContainer.FImage <> nil then
            lImageContainer.Floaded:= True;
          except
            on E : Exception do
            begin
              lImageContainer.Floaded:= False;
              //SendDebug(E.ClassName+' error raised (TImageThread.Execute), with message : '+E.Message);
            end;
          end;
        end;
      end;

      CheckPause;
      if (FFileList <> nil) and (FFileList.Count > 0) then
        Self.Synchronize(Self, SynkPainBox);
    end;
    finally
    //SendIndent;
    //SendMethodExit('TImageThread.Execute Finally Terminate');
    //SendUnIndent;
    Terminate;
    end;
  end;
end;

function TImageThread.GetThumbnail(aW, aH: Integer; aPath: String): TBitmap;
var
  lPic: TPicture;
  lResult: TBitmap;
begin
  //EnterCriticalSection(FCriticalSection);

  lPic := TPicture.Create;
  Result := nil;
  try
    try
    lPic.LoadFromFile(aPath);
    except
      //SendDebug('LoadFromFile Exception');
      exit;
    end;
    lResult := TBitmap.Create;

    if lPic.Graphic is TBitmap then
    begin
      if TBitmap(lPic.Graphic).PixelFormat = pfCustom then
      begin
        //SendDebug('PixelFormat = pfCustom');
        exit;
      end
      else
        lResult.PixelFormat := TBitmap(lPic.Graphic).PixelFormat;
    end
    else
      lResult.PixelFormat := pf32Bit;

    lResult.Width := 100;
    lResult.Height := 100;

    lResult.Canvas.Lock;
    lResult.Canvas.StretchDraw(Rect(0, 0, lResult.Width, lResult.Height), lPic.Graphic);
    lResult.Canvas.Unlock;

    Result := lResult;
    //LeaveCriticalSection(FCriticalSection);
  finally
    lPic.Destroy;
  end;
end;

procedure TImageThread.Pause;
begin
  if FRunEvent <> nil then
  begin
    FPaused := True;
    FRunEvent.ResetEvent;
  end;
end;

procedure TImageThread.SynkPainBox;
begin
//SendIndent;
//SendDebug('Thread SynkPainBox');
//SendUnIndent;
  fMain.pnbMain.Invalidate;
end;

procedure TImageThread.TerminatedSet;
begin
  FTermEvent.SetEvent;
end;

procedure TImageThread.Unpause;
begin
  FPaused := False;
  FRunEvent.SetEvent;
end;


end.
