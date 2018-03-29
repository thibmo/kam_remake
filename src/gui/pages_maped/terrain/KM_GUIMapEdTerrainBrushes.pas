unit KM_GUIMapEdTerrainBrushes;
{$I KaM_Remake.inc}
interface
uses
   Classes, Math, SysUtils,
   KM_Controls,
   KM_InterfaceDefaults,
   KM_Defaults, KM_Pics;


type
  //Painting on terrain with terrain brushes
  TKMMapEdTerrainBrushes = class (TKMMapEdSubMenuPage)
  private
    fLastShape: TKMMapEdShape;
    procedure BrushChange(Sender: TObject);
    procedure BrushRefresh;
  protected
    Panel_Brushes: TKMPanel;
    BrushSize: TKMTrackBar;
    BrushCircle: TKMButtonFlat;
    BrushSquare: TKMButtonFlat;
    BrushTable: array [0..6, 0..4] of TKMButtonFlat;
    BrushRandom: TKMCheckBox;
  public
    constructor Create(aParent: TKMPanel);

    procedure Show;
    procedure Hide;
    function Visible: Boolean; override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; X,Y: Integer; var aHandled: Boolean);
    procedure UpdateState;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  KM_ResFonts, KM_ResTexts, KM_Game, KM_GameCursor, KM_RenderUI, KM_ResKeys,
  KM_TerrainPainter, KM_InterfaceGame, KM_Utils;


{ TKMMapEdTerrainBrushes }
constructor TKMMapEdTerrainBrushes.Create(aParent: TKMPanel);
const
  Surfaces: array [0..6, 0..4] of TKMTerrainKind = (
    (tkGrass,       tkMoss,         tkRustyGrass1,  tkRustyGrass2,  tkCustom),
    (tkDirtGrass,   tkDirt,         tkGravel,       tkCobbleStone,  tkCustom),
    (tkGrassSand2,  tkGrassSand1,   tkSand,         tkRichSand,     tkCustom),
    (tkSwamp,       tkGrassyWater,  tkWater,        tkFastWater,    tkCustom),
    (tkShallowSnow, tkSnow,         tkDeepSnow,     tkIce,          tkCustom),
    (tkStoneMount,  tkGoldMount,    tkIronMount,    tkAbyss,        tkCustom),
    (tkCoal,        tkGold,         tkIron,         tkLava,         tkCustom));
var
  I,K: Integer;
begin
  inherited Create;

  fLastShape := hsCircle;

  Panel_Brushes := TKMPanel.Create(aParent, 0, 28, TB_WIDTH, 400);

  TKMLabel.Create(Panel_Brushes, 0, PAGE_TITLE_Y, TB_WIDTH, 0, gResTexts[TX_MAPED_TERRAIN_BRUSH], fnt_Outline, taCenter);
  BrushSize   := TKMTrackBar.Create(Panel_Brushes, 0, 30, 100, 0, 32);
  BrushSize.Position := 4;
  BrushSize.OnChange := BrushChange;
  BrushSize.Hint := GetHintWHotKey(TX_MAPED_TERRAIN_HEIGHTS_SIZE_HINT, 'Ctrl + MouseWheel');
  BrushCircle := TKMButtonFlat.Create(Panel_Brushes, 106, 28, 24, 24, 592);
  BrushCircle.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_CIRCLE, SC_MAPEDIT_SUB_MENU_ACTION_1);
  BrushCircle.OnClick := BrushChange;
  BrushSquare := TKMButtonFlat.Create(Panel_Brushes, 134, 28, 24, 24, 593);
  BrushSquare.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_HEIGHTS_SQUARE, SC_MAPEDIT_SUB_MENU_ACTION_2);
  BrushSquare.OnClick := BrushChange;

  for I := Low(Surfaces) to High(Surfaces) do
    for K := Low(Surfaces[I]) to High(Surfaces[I]) do
    if Surfaces[I,K] <> tkCustom then
    begin
      BrushTable[I,K] := TKMButtonFlat.Create(Panel_Brushes, K * 36, 60 + I * 40, 34, 34, Combo[Surfaces[I,K], Surfaces[I,K], 1] + 1, rxTiles);  // grass
      BrushTable[I,K].Tag := Byte(Surfaces[I,K]);
      BrushTable[I,K].OnClick := BrushChange;
    end;

  BrushRandom := TKMCheckBox.Create(Panel_Brushes, 0, 350, TB_WIDTH, 20, gResTexts[TX_MAPED_TERRAIN_BRUSH_RANDOM], fnt_Metal);
  BrushRandom.OnClick := BrushChange;
  BrushRandom.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_BRUSH_RANDOM, SC_MAPEDIT_SUB_MENU_ACTION_3);

  fSubMenuActionsEvents[0] := BrushChange;
  fSubMenuActionsEvents[1] := BrushChange;
  fSubMenuActionsEvents[2] := BrushChange;

  fSubMenuActionsCtrls[0] := BrushCircle;
  fSubMenuActionsCtrls[1] := BrushSquare;
  fSubMenuActionsCtrls[2] := BrushRandom;
end;


procedure TKMMapEdTerrainBrushes.BrushChange(Sender: TObject);
begin
  if gGameCursor.Mode <> cmBrush then
    gGameCursor.Mode := cmBrush;    // This will reset Tag

  gGameCursor.MapEdSize := BrushSize.Position;
  gGame.MapEditor.TerrainPainter.RandomizeTiling := BrushRandom.Checked;

  if Sender = BrushCircle then
  begin
    gGameCursor.MapEdShape := hsCircle;
    fLastShape := hsCircle;
  end
  else
  if Sender = BrushSquare then
  begin
    gGameCursor.MapEdShape := hsSquare;
    fLastShape := hsSquare;
  end
  else
  if Sender is TKMButtonFlat then
    gGameCursor.Tag1 := TKMButtonFlat(Sender).Tag;

  BrushRefresh;
end;


procedure TKMMapEdTerrainBrushes.BrushRefresh;
var
  I,K: Integer;
begin
  BrushCircle.Down := (gGameCursor.MapEdShape = hsCircle);
  BrushSquare.Down := (gGameCursor.MapEdShape = hsSquare);

  for I := Low(BrushTable) to High(BrushTable) do
  for K := Low(BrushTable[I]) to High(BrushTable[I]) do
  if BrushTable[I,K] <> nil then
    BrushTable[I,K].Down := (BrushTable[I,K].Tag = gGameCursor.Tag1);
end;


procedure TKMMapEdTerrainBrushes.Hide;
begin
  Panel_Brushes.Hide;
end;


procedure TKMMapEdTerrainBrushes.Show;
begin
  gGameCursor.MapEdShape := fLastShape;

  BrushChange(BrushTable[0,0]);

  Panel_Brushes.Show;
end;


function TKMMapEdTerrainBrushes.Visible: Boolean;
begin
  Result := Panel_Brushes.Visible;
end;


procedure TKMMapEdTerrainBrushes.MouseWheel(Shift: TShiftState; WheelDelta, X, Y: Integer; var aHandled: Boolean);
begin
  if not aHandled and Visible and (GetKeyState(VK_CONTROL) < 0) then // Do not use ssCtrl in SHift here, as it can sometimes be wrong values inside Shift (ssShift instead of ssCtrl)
  begin
    BrushSize.Position := Max(0, BrushSize.Position - (WheelDelta div 100)); //can't set negative number
    BrushChange(nil);
    aHandled := True;
  end;
end;


procedure TKMMapEdTerrainBrushes.UpdateState;
begin
  BrushRefresh;
end;


end.
