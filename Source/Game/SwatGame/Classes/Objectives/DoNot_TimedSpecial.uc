class DoNot_TimedSpecial extends DoNot_Special;

var config bool bFreezeTimerOnFailure;

var private Timer TimedSpecialTimer;
var private bool bFreezeTimerOnNextStop;

function Initialize()
{
    Super.Initialize();

    assertWithDescription(Time > 0,
        "[DoNot_TimedSpecial] Timed special objective "$name$" has Time=0. Set Time in ObjectiveSpecs to show the timer.");
}

function OnSpecialGameEvent(name SpecialGameEvent)
{
    bFreezeTimerOnNextStop = bFreezeTimerOnFailure;
    SetStatus(ObjectiveStatus_Failed);
    bFreezeTimerOnNextStop = false;
}

function StartTimer()
{
    local SwatGameReplicationInfo SGRI;
    local SwatRepo Repo;
    local int i;

    SGRI = SwatGameReplicationInfo(Game.GameReplicationInfo);
    Repo = SwatRepo(Game.Level.GetRepo());

    SGRI.SpecialTime = Time;

    for( i = 0; i < Repo.MissionObjectives.Objectives.Length; i++ )
    {
        if( Repo.MissionObjectives.Objectives[i] == self )
        {
            SGRI.TimedObjectiveIndex = i;
            break;
        }
    }

    if( TimedSpecialTimer != None )
    {
        TimedSpecialTimer.Destroy();
        TimedSpecialTimer = None;
    }

    TimedSpecialTimer = Game.Spawn(class'Timer');
    assert(TimedSpecialTimer != None);

    TimedSpecialTimer.TimerDelegate = UpdateTimedSpecialObjective;
    TimedSpecialTimer.StartTimer(1.0, true);
}

function StopTimer()
{
    if( TimedSpecialTimer != None )
    {
        TimedSpecialTimer.TimerDelegate = None;
        TimedSpecialTimer.Destroy();
        TimedSpecialTimer = None;
    }

    if( bFreezeTimerOnNextStop )
    {
        return;
    }

    ClearTimedSpecialObjective();
}

function ClearTimedSpecialObjective()
{
    local SwatGameReplicationInfo SGRI;

    SGRI = SwatGameReplicationInfo(Game.GameReplicationInfo);

    SGRI.SpecialTime = 0;
    SGRI.TimedObjectiveIndex = -1;
}

function UpdateTimedSpecialObjective()
{
    local SwatGameReplicationInfo SGRI;

    if( GetStatus() != ObjectiveStatus_InProgress )
        return;

    SGRI = SwatGameReplicationInfo(Game.GameReplicationInfo);

    SGRI.SpecialTime--;

    if( SGRI.SpecialTime <= 0 )
    {
        bFreezeTimerOnNextStop = false;
        SetStatus(ObjectiveStatus_Completed);
    }
}





// Decompiled with UE Explorer.
defaultproperties
{
    bFreezeTimerOnFailure=true
}