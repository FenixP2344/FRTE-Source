class SwatHUD extends Engine.HUD
    config(SwatGame)
    native
    dependson(AICoverFinder);

import enum EShowCoverInfoDetail from AICoverFinder;
import enum EFocusInterface from SwatGamePlayerController;

var config float CommandPositionX;  //Position on the screen in percent
var config float CommandPositionY;
var config int CommandTextureSizeX; //Dimensions of the command texture
var config int CommandTextureSizeY; //Dimensions of the command texture

var float ScaleX, ScaleY;
var bool bShowFocusDebug;           // if true, render name of player's focus

var Texture CommandClearTexture;
var Texture CommandFallInTexture;
var Texture CommandStackUpTexture;
var Texture CommandComplyTexture;

var private bool                bShowVisionCones;
var private bool				bShowAIMovementDebugInfo;
var private bool				bShowOfficerAIAssignmentsInfo;

var private bool                 bShowCoverInfo;
var private Pawn                 ShowCoverInfoPawn;
var private EShowCoverInfoDetail ShowCoverInfoDetail;

var private bool                 bShowAwarenessInfo;
var private AwarenessProxy       Awareness;

struct native DebugLine
{
    var vector EndA;
    var vector EndB;
    var color Color;
    var float Lifespan;
};
var private array<DebugLine> DebugLines;

struct native DebugCone
{
    var vector Origin;
    var vector Direction;
    var float Length;
    var float HalfAngle;
    var color Color;
    var float Lifespan;
};
var private array<DebugCone> DebugCones;

var private float LastTimeDebugShapesDrawn;

function PostBeginPlay()
{
    Super.PostBeginPlay();
}

function RenderToScale(Canvas C, Texture T)
{
    C.DrawTile(T, T.USize * ScaleX, T.VSize * ScaleY, 0, 0, T.USize, T.VSize);

    return;
}

function PostRender(Canvas C)
{
	local SwatPawn ViewPawn;

	// Tint the intensified scene before drawing the HUD so interface colors stay
	// readable. Thermal pawn skins supply luminance; the wash selects the active
	// phosphor or fused-thermal channel.
	if (PlayerOwner != None)
	{
		ViewPawn = SwatPawn(PlayerOwner.ViewTarget);
		if (ViewPawn == None)
			ViewPawn = SwatPawn(PlayerOwner.Pawn);
		if (ViewPawn != None && ViewPawn.bIsWearingNightvision)
			DrawNVGOverlay(C);
	}

	// Call the native HUD first so the thermal brackets remain visible above
	// GUI text and controls. DrawNVGOverlay already ran before this pass so it
	// tints the scene without recoloring the interface.
	Super.PostRender(C);

	if (PlayerOwner != None && ViewPawn != None && ViewPawn.bIsWearingNightvision &&
		class'SwatPlayerExtras'.default.NVGMode == 3)
		DrawThermalOutlines(C, ViewPawn);

    if (bHideHud) return;
    
    ScaleX = C.SizeX / 1024.0;
    ScaleY = C.SizeY / 768.0;

    //TMC TODO implement in-game interface
    //RenderCommand(C);

    if (bShowFocusDebug) 
		DebugRenderPlayerInterfaces(C);

    return;
}




// Mode-specific phosphor wash over the native monochrome NV pass. The native
// camera effect supplies the intensified luminance; this pass controls the
// tube character without replacing pawn materials or changing HUD geometry.
function DrawNVGOverlay(Canvas C)
{
	local byte SavedStyle;
	local byte Mode;
	local byte OverlayR;
	local byte OverlayG;
	local byte OverlayB;
	local byte OverlayAlpha;
	local color SavedColor;
	local font SavedFont;
	local float SavedSpaceX;
	local float SavedSpaceY;
	local float SavedOrgX;
	local float SavedOrgY;
	local float SavedClipX;
	local float SavedClipY;
	local float SavedCurYL;
	local float SavedZ;
	local bool SavedCenter;
	local bool SavedNoSmooth;
	local float SavedX;
	local float SavedY;

	if (C == None || C.WhiteTex == None)
		return;

	SavedStyle = C.Style;
	SavedColor = C.DrawColor;
	SavedFont = C.Font;
	SavedSpaceX = C.SpaceX;
	SavedSpaceY = C.SpaceY;
	SavedOrgX = C.OrgX;
	SavedOrgY = C.OrgY;
	SavedClipX = C.ClipX;
	SavedClipY = C.ClipY;
	SavedX = C.CurX;
	SavedY = C.CurY;
	SavedCurYL = C.CurYL;
	SavedZ = C.Z;
	SavedCenter = C.bCenter;
	SavedNoSmooth = C.bNoSmooth;
	Mode = class'SwatPlayerExtras'.default.NVGMode;
	if (Mode > 3)
		Mode = 0;

	// User mode 1 (NVGMode 0) is the native DLL image only. Do not add a
	// scripted full-screen wash on top of the native phosphor pass.
	if (Mode == 0)
		return;

	// User modes 2-4 select the scripted thermal/fusion/AI presentation.
	switch (Mode)
	{
		case 1:
			// Blue-white phosphor wash (quad goggles / GPNVGFast, RON style).
			OverlayR = 160;
			OverlayG = 190;
			OverlayB = 255;
			OverlayAlpha = class'SwatPlayerExtras'.default.NVGWhiteHotAlpha;
			break;
		case 2:
			// Mode 3 gets its green/yellow/red color from the pawn surface;
			// keep only a very light ENVG-B lift behind it.
			OverlayR = 32;
			OverlayG = 48;
			OverlayB = 24;
			OverlayAlpha = 12;
			break;
		case 3:
			OverlayR = 72;
			OverlayG = 255;
			OverlayB = 72;
			OverlayAlpha = class'SwatPlayerExtras'.default.NVGOverlayAlpha;
			break;
	}

	// STY_Alpha makes DrawRect respect DrawColor.A.
	C.Style = ERenderStyle.STY_Alpha;
	C.SetDrawColor(OverlayR, OverlayG, OverlayB, OverlayAlpha);
	C.SetPos(0, 0);
	C.DrawRect(C.WhiteTex, C.SizeX, C.SizeY);

	C.Style = SavedStyle;
	C.DrawColor = SavedColor;
	C.Font = SavedFont;
	C.SpaceX = SavedSpaceX;
	C.SpaceY = SavedSpaceY;
	C.OrgX = SavedOrgX;
	C.OrgY = SavedOrgY;
	C.ClipX = SavedClipX;
	C.ClipY = SavedClipY;
	C.CurYL = SavedCurYL;
	C.Z = SavedZ;
	C.bCenter = SavedCenter;
	C.bNoSmooth = SavedNoSmooth;
	C.SetPos(SavedX, SavedY);
}

// User mode 4: optional AI screen-space search brackets. Thermal modes 2 and
// 3 never call this function; their colors belong to the pawn surface.
function DrawThermalOutlines(Canvas C, SwatPawn LocalPawn)
{
	local SwatPawn P;
	local vector Screen;
	local vector TopScreen;
	local vector BottomScreen;
	local vector CameraLocation;
	local rotator CameraRotation;
	local Actor ViewActor;
	local float BoxWidth;
	local float BoxHeight;
	local float CenterX;
	local float TopY;
	local float BottomY;
	local float ScaleX;
	local float ScaleY;
	//local int Layer;
	//local float LayerScale;
	//local float LayerWidth;
	//local float LayerHeight;
	//local float LayerTop;
	local color LayerColor;
	//local byte LayerAlpha;
	local byte SavedStyle;
	local color SavedColor;
	local font SavedFont;
	local float SavedSpaceX;
	local float SavedSpaceY;
	local float SavedOrgX;
	local float SavedOrgY;
	local float SavedClipX;
	local float SavedClipY;
	local float SavedCurYL;
	local float SavedZ;
	local bool SavedCenter;
	local bool SavedNoSmooth;
	local float SavedX;
	local float SavedY;
	local GUIController G;
	local byte Mode;

	if (C == None || C.WhiteTex == None || LocalPawn == None || PlayerOwner == None ||
		PlayerOwner.Player == None || PlayerOwner.Player.GUIController == None)
		return;
	if (SwatGamePlayerController(PlayerOwner) == None)
		return;

	G = GUIController(PlayerOwner.Player.GUIController);
	if (G == None)
		return;
	if (G.ViewportOwner == None)
		return;
	if (G.ResolutionX <= 0 || G.ResolutionY <= 0)
		return;
	if (C.SizeX <= 0 || C.SizeY <= 0)
		return;
	Mode = class'SwatPlayerExtras'.default.NVGMode;
	if (Mode != 3)
		return;

	SwatGamePlayerController(PlayerOwner).PlayerCalcView(
		ViewActor, CameraLocation, CameraRotation);
	if (ViewActor == None)
		return;
	ScaleX = float(C.SizeX) / float(G.ResolutionX);
	ScaleY = float(C.SizeY) / float(G.ResolutionY);
	SavedStyle = C.Style;
	SavedColor = C.DrawColor;
	SavedFont = C.Font;
	SavedSpaceX = C.SpaceX;
	SavedSpaceY = C.SpaceY;
	SavedOrgX = C.OrgX;
	SavedOrgY = C.OrgY;
	SavedClipX = C.ClipX;
	SavedClipY = C.ClipY;
	SavedX = C.CurX;
	SavedY = C.CurY;
	SavedCurYL = C.CurYL;
	SavedZ = C.Z;
	SavedCenter = C.bCenter;
	SavedNoSmooth = C.bNoSmooth;
	foreach DynamicActors(class'SwatPawn', P)
	{
		if (!IsThermalVisible(P, LocalPawn, CameraLocation, CameraRotation))
			continue;

		Screen = G.WorldToScreen(P.Location, CameraLocation, CameraRotation);
		TopScreen = G.WorldToScreen(P.Location + vect(0,0,1) * P.CollisionHeight,
			CameraLocation, CameraRotation);
		BottomScreen = G.WorldToScreen(P.Location - vect(0,0,1) * P.CollisionHeight,
			CameraLocation, CameraRotation);
		if (Screen.X != Screen.X || TopScreen.Y != TopScreen.Y ||
			BottomScreen.Y != BottomScreen.Y)
			continue;
		if (Abs(Screen.X) > 100000.0 || Abs(TopScreen.Y) > 100000.0 ||
			Abs(BottomScreen.Y) > 100000.0)
			continue;
		if (Screen.X < -float(G.ResolutionX) ||
			Screen.X > float(G.ResolutionX) * 2.0 ||
			TopScreen.Y < -float(G.ResolutionY) * 2.0 ||
			TopScreen.Y > float(G.ResolutionY) * 2.0 ||
			BottomScreen.Y < -float(G.ResolutionY) * 2.0 ||
			BottomScreen.Y > float(G.ResolutionY) * 2.0)
			continue;

		CenterX = Screen.X * ScaleX;
		TopY = TopScreen.Y * ScaleY;
		BottomY = BottomScreen.Y * ScaleY;
		BoxHeight = Abs(BottomY - TopY);
		if (BoxHeight < 8.0)
			continue;
		BoxHeight = FClamp(BoxHeight, 18.0, float(C.SizeY) * 0.9);
		BoxWidth = FClamp(BoxHeight * 0.34, 8.0, float(C.SizeX) * 0.18);

		// Mode 4 = AI search brackets, one colour per faction:
		// red = suspect, yellow = hostage, green = teammate.
		C.Style = ERenderStyle.STY_Alpha;
		if (P.IsA('SwatEnemy'))
			LayerColor = class'Engine.Canvas'.Static.MakeColor(255, 64, 28);
		else if (P.IsA('SwatHostage'))
			LayerColor = class'Engine.Canvas'.Static.MakeColor(255, 214, 48);
		else
			LayerColor = class'Engine.Canvas'.Static.MakeColor(48, 224, 112);
		C.SetDrawColor(LayerColor.R, LayerColor.G, LayerColor.B, 220);
		C.SetPos(CenterX - BoxWidth * 0.5, TopY);
		C.DrawBracket(BoxWidth, BoxHeight, FClamp(BoxWidth * 0.32, 4.0, 14.0));
	}

	C.Style = SavedStyle;
	C.DrawColor = SavedColor;
	C.Font = SavedFont;
	C.SpaceX = SavedSpaceX;
	C.SpaceY = SavedSpaceY;
	C.OrgX = SavedOrgX;
	C.OrgY = SavedOrgY;
	C.ClipX = SavedClipX;
	C.ClipY = SavedClipY;
	C.CurYL = SavedCurYL;
	C.Z = SavedZ;
	C.bCenter = SavedCenter;
	C.bNoSmooth = SavedNoSmooth;
	C.SetPos(SavedX, SavedY);
}

function bool IsThermalVisible(SwatPawn P, SwatPawn LocalPawn, vector CameraLocation, rotator CameraRotation)
{
	local vector ToPawn;

	if (P == None || P == LocalPawn || P.bDeleteMe || P.Health <= 0)
		return false;
	if (P.bHidden || P.DrawType == DT_None)
		return false;

	ToPawn = P.Location - CameraLocation;
	if (VSize(ToPawn) < 32.0 || Normal(ToPawn) Dot vector(CameraRotation) <= 0.0)
		return false;

	return FastTrace(P.Location + vect(0,0,1) * P.CollisionHeight * 0.5, CameraLocation);
}

function color ThermalBracketColor(SwatPawn P, SwatPawn LocalPawn)
{
	if (P.IsA('SwatEnemy'))
		return class'Engine.Canvas'.Static.MakeColor(255, 92, 42, 220);
	if (P.IsA('SwatHostage'))
		return class'Engine.Canvas'.Static.MakeColor(255, 244, 196, 220);
	if (P.GetTeamNumber() == LocalPawn.GetTeamNumber())
		return class'Engine.Canvas'.Static.MakeColor(128, 224, 255, 220);
	return class'Engine.Canvas'.Static.MakeColor(255, 168, 64, 220);
}

simulated event WorldSpaceOverlays()
{
    //if ( log( "bShowDebugInfo: " $ bShowDebugInfo );

    if ( bShowDebugInfo && Pawn(PlayerOwner.ViewTarget) != None )
    {
        DrawRoute();
    }

    if ( bShowVisionCones )
    {
        DrawVisionCones();
    }

	if (bShowAIMovementDebugInfo)
	{
		DrawDebugAIMovement();
	}

    if (bShowCoverInfo)
    {
        DrawDebugCover();
    }

    if (bShowAwarenessInfo)
    {
        DrawDebugAwareness();
    }

	if (bShowOfficerAIAssignmentsInfo)
	{
		DrawOfficerAIAssignmentsInfo();
	}

    DrawDebugShapes(self);
}


// Show & Hide Vision Cones
exec function ShowVC()
{
    bShowVisionCones = true;
    bHideHud = false;
}


exec function HideVC()
{
    bShowVisionCones = false;
}


function DrawVisionCones()
{
    local Pawn Iter;

    for(Iter = Level.PawnList; Iter != None; Iter = Iter.nextPawn)
    {
        if (Iter.IsA('SwatAI'))
        {
            SwatAI(Iter).DrawVisionCone(self);
        }
    }
}

exec function DebugAIMovement()
{
	bShowAIMovementDebugInfo = !bShowAIMovementDebugInfo;
    bHideHud = false;
}

exec function DebugAssignments()
{
	bShowOfficerAIAssignmentsInfo = !bShowOfficerAIAssignmentsInfo;
    bHideHud = false;
}

function DrawDebugAIMovement()
{
	local Pawn Iter;

    for(Iter = Level.PawnList; Iter != None; Iter = Iter.nextPawn)
    {
        if (Iter.IsA('SwatAI'))
        {
            SwatAI(Iter).DrawDebugAIMovement(self);
        }
    }
}

function DrawOfficerAIAssignmentsInfo()
{
	local Pawn Iter;

    for(Iter = Level.PawnList; Iter != None; Iter = Iter.nextPawn)
    {
        if (Iter.IsA('SwatOfficer'))
        {
            SwatOfficer(Iter).DrawLineToAssignment(self);
        }
    }
}

exec function DebugCover(string AINameString)
{
    bHideHud = false;
    DebugCoverInternal(AINameString);
}

exec function DebugCover2(string AINameString)
{
    bHideHud = false;
    if (DebugCoverInternal(AINameString))
    {
        ShowCoverInfoDetail = kSCID_IndividualExtrusions;
    }
}

exec function DebugCover3(string AINameString)
{
    bHideHud = false;
    if (DebugCoverInternal(AINameString))
    {
        ShowCoverInfoDetail = kSCID_IndividualInverseExtrusions;
    }
}

private function bool DebugCoverInternal(string AINameString)
{
    local Pawn Pawn;

    bShowCoverInfo = false;
    ShowCoverInfoPawn = None;
    ShowCoverInfoDetail = kSCID_PlaneAndExtrusionIntersection;

    if (AINameString != "")
    {
        foreach AllActors(class 'Pawn', Pawn)
        {
            if (Pawn.Name == Name(AINameString))
            {
                bShowCoverInfo = true;
                ShowCoverInfoPawn = Pawn;
                return true;
            }
        }
    }

    return false;
}

native function DrawDebugCover();

exec function DebugAwareness(string AINameString)
{
    local Pawn Pawn;
    local SwatAI SwatAI;

    bHideHud = false;
    bShowAwarenessInfo = false;
    Awareness = None;

    if (AINameString != "")
    {
        foreach AllActors(class 'Pawn', Pawn)
        {
            if (Pawn.Name == Name(AINameString))
            {
                SwatAI = SwatAI(Pawn);
                if (SwatAI != None)
                {
                    Awareness = SwatAI.GetAwareness();
                    bShowAwarenessInfo = true;
                }
                break;
            }
        }
    }
}

exec function DebugOfficerAwareness()
{
    bHideHud = false;
    bShowAwarenessInfo = true;
    Awareness = SwatAIRepository(Level.AIRepo).GetHive().GetAwareness();
}

private function DrawDebugAwareness()
{
    if (Awareness != None)
    {
        Awareness.DrawDebugInfo(self);
    }
}

exec function ToggleGUI()
{
	local PlayerController PC;

#if IG_THIS_IS_SHIPPING_VERSION
    if (Level.NetMode != NM_StandAlone)
        return;
#endif

	PC = Level.GetLocalPlayerController();

	PC.Player.GUIController.bHackDoNotRenderGUIPages = !PC.Player.GUIController.bHackDoNotRenderGUIPages;
	if (!PC.Player.GUIController.bHackDoNotRenderGUIPages)
	{
		Log("HIDING GUI");
	}
	else
	{
		Log("SHOWING GUI");
	}
}

exec function ToggleHUD()
{
#if IG_THIS_IS_SHIPPING_VERSION
    if (Level.NetMode != NM_StandAlone)
        return;
#endif

	bHideHud = !bHideHud;

    if (bHideHud)
	{
		Log("HIDING Heads-up Display");
	}
	else
	{
		Log("SHOWING Heads-up Display");
	}
}

exec function ShowFocus()
{
    bShowFocusDebug = !bShowFocusDebug;
    
    bHideHud = false;
}

function RenderCommand(Canvas canvas)
{
    local Texture It;
    
    //TMC TODO implement

	Canvas.bNoSmooth = False;
	Canvas.SetPos(
        CommandPositionX * (Canvas.ClipX - CommandTextureSizeX),
        CommandPositionY * (Canvas.ClipY - CommandTextureSizeY));
	Canvas.Style = ERenderStyle.STY_Alpha;
	Canvas.SetDrawColor(255,255,255);
	Canvas.DrawTile(
        It,
        CommandTextureSizeX, CommandTextureSizeY,
        0, 0,
        CommandTextureSizeX, CommandTextureSizeY);
	Canvas.bNoSmooth = True;
}

simulated function DebugRenderPlayerInterfaces(canvas Canvas)
{
    local SwatGamePlayerController PC;
    local int X, Y;
    local Actor Actor;
    local vector CameraLocation;
    local rotator CameraRotation;

    PC = SwatGamePlayerController(Level.GetLocalPlayerController());
    PC.CalcViewForFocus(Actor, CameraLocation, CameraRotation );
    
    if ( bShowFocusDebug )
    {
        Canvas.SetDrawColor(255,255,255);

        X = 20; Y = 50;

        PC.GetFocusInterface(Focus_Use).DrawDebugText(CameraLocation, Canvas, X, Y);
        PC.GetFocusInterface(Focus_Fire).DrawDebugText(CameraLocation, Canvas, X, Y);
        PC.GetCommandInterface().DrawDebugText(CameraLocation, Canvas, X, Y);
        PC.GetFocusInterface(Focus_LowReady).DrawDebugText(CameraLocation, Canvas, X, Y);
        if (Level.NetMode != NM_Standalone)
            PC.GetFocusInterface(Focus_PlayerTag).DrawDebugText(CameraLocation, Canvas, X, Y);
    }
}

function DrawDebugShapes(HUD DrawTarget)
{
    local int i;

    for (i = DebugLines.length - 1; i >= 0; --i)
    {
        DrawTarget.Draw3DLine(
                DebugLines[i].EndA, 
                DebugLines[i].EndB, 
                DebugLines[i].Color);
        if (DebugLines[i].Lifespan >= 0)
            DebugLines[i].Lifespan -= Level.TimeSeconds - LastTimeDebugShapesDrawn;
        if (DebugLines[i].Lifespan <= 0)
            RemoveDebugLine(i);
    }

    for (i = DebugCones.length - 1; i >= 0; --i)
    {
        DrawTarget.Draw3DCone(
                DebugCones[i].Origin, 
                DebugCones[i].Direction, 
                DebugCones[i].Length,
                DebugCones[i].HalfAngle,
                DebugCones[i].Color);
        if (DebugCones[i].Lifespan >= 0)
            DebugCones[i].Lifespan -= Level.TimeSeconds - LastTimeDebugShapesDrawn;
        if (DebugCones[i].Lifespan <= 0)
            RemoveDebugCone(i);
    }

    LastTimeDebugShapesDrawn = Level.TimeSeconds;
}

//returns the index of the line added
function int AddDebugLine(vector EndA, vector EndB, color Color, optional float Lifespan)
{
    local DebugLine Line;
    local int Index;

	bHideHud=false;

    Line.EndA = EndA;
    Line.EndB = EndB;
    Line.Color = Color;
    if (Lifespan > 0)
        Line.Lifespan = Lifespan;
    else
        Line.Lifespan = 10000;

    Index = DebugLines.length;
    DebugLines[Index] = Line;

    return Index;
}

function RemoveDebugLine(int Index)
{
    DebugLines.Remove(Index, 1);
}

exec function ClearDebugLines()
{
	DebugLines.Remove(0, DebugLines.Length);
}

//AddDebugBox is implemented in terms of AddDebugLine()
function AddDebugBox(vector Center, float Diameter, color Color, optional float Lifespan)
{
    local float HalfSize;
    local vector PointA, PointB;

    HalfSize = Diameter / 2.0;
    
    //from - - -
    PointA = Center; PointB = Center;
    PointA.X -= HalfSize; PointA.Y -= HalfSize; PointA.Z -= HalfSize;
    PointB.X += HalfSize; PointB.Y -= HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X -= HalfSize; PointA.Y -= HalfSize; PointA.Z -= HalfSize;
    PointB.X -= HalfSize; PointB.Y += HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X -= HalfSize; PointA.Y -= HalfSize; PointA.Z -= HalfSize;
    PointB.X -= HalfSize; PointB.Y -= HalfSize; PointB.Z += HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    //from + - +

    PointA = Center; PointB = Center;
    PointA.X += HalfSize; PointA.Y -= HalfSize; PointA.Z += HalfSize;
    PointB.X -= HalfSize; PointB.Y -= HalfSize; PointB.Z += HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X += HalfSize; PointA.Y -= HalfSize; PointA.Z += HalfSize;
    PointB.X += HalfSize; PointB.Y += HalfSize; PointB.Z += HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X += HalfSize; PointA.Y -= HalfSize; PointA.Z += HalfSize;
    PointB.X += HalfSize; PointB.Y -= HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    //from + + -

    PointA = Center; PointB = Center;
    PointA.X += HalfSize; PointA.Y += HalfSize; PointA.Z -= HalfSize;
    PointB.X -= HalfSize; PointB.Y += HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X += HalfSize; PointA.Y += HalfSize; PointA.Z -= HalfSize;
    PointB.X += HalfSize; PointB.Y -= HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X += HalfSize; PointA.Y += HalfSize; PointA.Z -= HalfSize;
    PointB.X += HalfSize; PointB.Y += HalfSize; PointB.Z += HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    //from - + -

    PointA = Center; PointB = Center;
    PointA.X -= HalfSize; PointA.Y += HalfSize; PointA.Z -= HalfSize;
    PointB.X += HalfSize; PointB.Y += HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X -= HalfSize; PointA.Y += HalfSize; PointA.Z -= HalfSize;
    PointB.X -= HalfSize; PointB.Y -= HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X -= HalfSize; PointA.Y += HalfSize; PointA.Z -= HalfSize;
    PointB.X -= HalfSize; PointB.Y += HalfSize; PointB.Z += HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);
}

//see comments on Draw3DCone
simulated function int AddDebugCone(
        vector Origin, vector Direction, 
        float Length, float HalfAngle, 
        Color Color, float Lifespan)
{
    local DebugCone Cone;
    local int Index;

	bHideHud=false;

    Cone.Origin = Origin;
    Cone.Direction = Direction;
    Cone.Length = Length;
    Cone.HalfAngle = HalfAngle;
    Cone.Color = Color;
    if (Lifespan > 0)
        Cone.Lifespan = Lifespan;
    else
        Cone.Lifespan = 10000;

    Index = DebugCones.length;
    DebugCones[Index] = Cone;

    return Index;
}

function RemoveDebugCone(int Index)
{
    DebugCones.Remove(Index, 1);
}

exec function ClearDebugCones()
{
	DebugCones.Remove(0, DebugCones.Length);
}

defaultproperties
{
    bHideHud=True
}
