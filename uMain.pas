unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Types, System.IOUtils, System.StrUtils,
  Vcl.Graphics,  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.Grids,
  Vcl.ExtCtrls, Vcl.StdCtrls, System.Generics.Collections, uThumbnail, Vcl.Menus, Math
  {$IFDEF DEBUG}
  //, DbugIntf
  {$ENDIF}
  ;

type
  TSearchMode = (smDir, smImages);

  TfMain = class(TForm)
    trvMain: TTreeView;
    pnbMain: TPaintBox;
    MainMenu1: TMainMenu;
    mmiNextPage: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure trvMainChange(Sender: TObject; Node: TTreeNode);
    procedure FormDestroy(Sender: TObject);
    procedure pnbMainPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure mmiNextPageClick(Sender: TObject);
  private
    { Private declarations }
    FChildNames: TStringList;
    FImageContainerList: TStringList;
    FImageThread: TImageThread;
    procedure CreateFileNameList(const aParentName, aSearchPattern: string; aSearchMode: TSearchMode);
    procedure CreateThread;
    procedure ImageContainerClear;

  public
    { Public declarations }
    FDrawing: boolean;
    FPageNum: integer;
    FImageCount: integer;
    FImagePerPage: integer;
    procedure Arrange;
  end;

var
  fMain: TfMain;

implementation

{$R *.dfm}

procedure TfMain.Arrange;
var
  i, lImageCount, lY, lX, lFirstImage: Integer;
  lImageContainer, lImageContainerP: TImageContainer;
begin
//SendMethodEnter('Arrange');
  try
  lX := 10;
  lY := 10;
  FImageCount := 0;
  
  lFirstImage := (FPageNum)*FImagePerPage;

  for i:= lFirstImage to FImageContainerList.Count - 1 do
  begin
    lImageContainer:= TImageContainer(FImageContainerList.Objects[I]);

    lImageContainer.Fx:= lX;
    lImageContainer.Fy := lY;

    lX := lX + 100+10 ;

    if (lImageContainer.Fx + 100+10 > pnbMain.Width) then
    begin
      if (lImageContainer.Fy + 100+100+10 < pnbMain.Height) then
      begin
        lImageContainer.Fx:= 10;
        lImageContainer.Fy := lY + 100+10 ;
        lY := lImageContainer.Fy;
        lX := lImageContainer.Fx;
      end
      else
      begin
        break;
      end;
    end;
    inc(FImageCount);
  end;

  finally

    //SendMethodExit('Arrange');
  end;
end;

procedure TfMain.ImageContainerClear;
var
  i: Integer;
begin
  //SendMethodEnter('TfMain.ImageContainerClear');
  if FImageContainerList = nil then
    FImageContainerList := TStringList.Create;

  for i := 0 to FImageContainerList.Count - 1 do
    if FImageContainerList.Objects[i] <> nil then
    begin
      FImageContainerList.Objects[i].Free;
      FImageContainerList.Objects[i] := nil;
    end;
  FImageContainerList.Clear;
end;

procedure TfMain.CreateThread;
begin
  FImageThread := TImageThread.Create(FImageContainerList);
  FImageThread.FreeOnTerminate := True;
end;

procedure TfMain.CreateFileNameList(const aParentName, aSearchPattern: string; aSearchMode: TSearchMode);
var
  lSearchRec : TSearchRec;
  lCondSearch: boolean;
  lImageContainer: TImageContainer;
begin
  FChildNames.Clear;
  ImageContainerClear;


  try
  if FindFirst(IncludeTrailingBackslash(aParentName) + '*.*', faAnyFile, lSearchRec) = 0 then
  try
    lCondSearch := True;
    repeat
      if aSearchMode = smDir then
        lCondSearch := (MatchText(lSearchRec.Name, ['.', '..', 'Windows'])) or (pos('$', lSearchRec.Name) > 0)  or
            (lSearchRec.Attr and faDirectory = 0) or
            (lSearchRec.Attr and faNormal <> 0) or
            (lSearchRec.Attr and faHidden <> 0)
      else if aSearchMode = smImages then
        lCondSearch := (MatchText(lSearchRec.Name, ['.', '..', 'Windows'])) or (pos('$', lSearchRec.Name) > 0)  or
            (lSearchRec.Attr and faDirectory <> 0) or
            (lSearchRec.Attr and faNormal <> 0) or
            (lSearchRec.Attr and faHidden <> 0) or
            (AnsiPos(ExtractFileExt(lSearchRec.Name), aSearchPattern) = 0)
      else
        ;

      if lCondSearch then
        Continue;
      if aSearchMode = smDir then
        FChildNames.Add(lSearchRec.Name)
      else if aSearchMode = smImages then
      begin
        lImageContainer := TImageContainer.Create;
        lImageContainer.FPath:=  IncludeTrailingBackslash(aParentName) + lSearchRec.Name;
        FImageContainerList.AddObject('', lImageContainer);
      end
      else
        ;
    until FindNext(lSearchRec) > 0;
  except
    on E : Exception do
      ShowMessage(E.ClassName+' error raised, with message : '+E.Message);
  end;

  finally
    FindClose(lSearchRec);
  end;

end;


procedure TfMain.FormCreate(Sender: TObject);
var
  lDrives: TStringDynArray;
  lDrive: string;
begin
  FDrawing := False;
  CreateThread;

  FChildNames := TStringList.Create;
  lDrives := TDirectory.GetLogicalDrives;
  for lDrive in lDrives do
    trvMain.Items.AddChild(nil, lDrive);
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FChildNames) then
    FChildNames.Destroy;

  if Assigned(FImageContainerList) then
    FImageContainerList.Destroy;
end;

procedure TfMain.FormResize(Sender: TObject);
begin
  if FImageContainerList.Count > 0 then
  begin
    FImagePerPage := (((pnbMain.Width - 20) div 100)-1) * ((pnbMain.Height -20) div 100);
    //SendDebug('FormResize FormResize Invalidate '+intToStr(pnbMain.Width)+' '+intToStr(pnbMain.Height));
    Arrange;
    pnbMain.Invalidate;
  end;
end;

procedure TfMain.mmiNextPageClick(Sender: TObject);
begin
  inc(FPageNum);
  FImagePerPage := (((pnbMain.Width - 20) div 100)-1) * ((pnbMain.Height -20) div 100);
  if FImageThread.Terminated then
  begin
    CreateThread;
  end;
end;

procedure TfMain.pnbMainPaint(Sender: TObject);
var
  i, lFirstImage: integer;
  lImageContainer: TImageContainer;
begin
//SendMethodEnter('pnbMainPaint');
  //FImageThread.Pause;
  pnbMain.Canvas.Lock;
  Arrange;
  //SendBoolean('trvMain.Enabled',trvMain.Enabled);
  trvMain.Enabled := False;
  lFirstImage := max((FPageNum)*FImagePerPage, 0);
  try
  for I:= lFirstImage to FImageContainerList.Count - 1 do
  begin
    lImageContainer:= TImageContainer(FImageContainerList.Objects[I]);
    if  Assigned(lImageContainer.FImage) and lImageContainer.Floaded then
    begin
       pnbMain.Canvas.Draw(lImageContainer.Fx, lImageContainer.Fy, lImageContainer.FImage);
    end;
  end;
   //SendBoolean('trvMain.Enabled',trvMain.Enabled);
  finally
  pnbMain.Canvas.UnLock;
  //FImageThread.UnPause;
  trvMain.Enabled := True;
  //SendMethodExit('pnbMainPaint');
  end;
end;

procedure TfMain.trvMainChange(Sender: TObject; Node: TTreeNode);
var
  lFullPath : string;
  lNode: TTreeNode;
  i, lImageCount: integer;
begin
  if Assigned(Node) then
  begin
    lFullPath := IncludeTrailingBackslash(Node.Text);
    while Assigned(lNode.Parent) do
      begin
        lFullPath := IncludeTrailingBackslash(lNode.Parent.Text) + lFullPath;
        lNode := lNode.Parent;
      end;

    if Node.Count = 0 then
    begin
      lNode := Node;
      CreateFileNameList(lFullPath, '*.*', smDir);
      if Assigned(FChildNames) then
        for i := 0 to FChildNames.Count - 1 do
          trvMain.Items.AddChild(Node, FChildNames[i]);
      Node.Expand(True);
    end;



    CreateFileNameList(lFullPath, '*.bmp;*.jpg;*.png', smImages);

    pnbMain.Canvas.Brush.Color := clBtnFace;
    pnbMain.Canvas.FillRect(pnbMain.Canvas.ClipRect);
    //SendDebug('trvMainChange B4 Reset '+IntToStr(FImageContainerList.Count)+' '+lNode.Text);
    FImagePerPage := (((pnbMain.Width - 20) div 100)-1) * ((pnbMain.Height -20) div 100);
    FPageNum := 0;
    //SendDebug('trvMainChange FPageNum='+IntToStr(FPageNum));
    if FImageThread.Terminated then
    begin
      CreateThread;
    end;
  end;

end;

end.
