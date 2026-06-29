#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION      "1.0.0"

#define SF_DOOR_LOCKED      2048
#define	SF_DOOR_USE_CLOSES  8192
#define SF_DOOR_IGNORE_USE  32768

int SafeRoomDoorCode = -1;
int CodeAttempts = 0;

float flMaxFlowDistance = -1.0;

static int iMaxCodeAttempts = 3;

int iGlobalDistance = 25;

char szRoomDoorCode[5];
bool bShownCode[4];

bool bShouldStopTimer = false;

ConVar mp_gamemode = null;
ConVar director_panic_forever = null;

Handle ghDistanceTimer = null;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Saferoom Password",
	author = "XeroX",
	description = "Locks the saferoom door until the password is entered",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2824719"
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_code", Command_Code, "Enter the saferoom door password");

    mp_gamemode = FindConVar("mp_gamemode");
    director_panic_forever = FindConVar("director_panic_forever");

    CreateConVar("sm_saferoom_password_version", PLUGIN_VERSION, "Version of the Saferoom Password Plugin");

    HookEvent("round_end", Event_RoundEnd);
}

public void OnMapStart()
{
    SetDefaultValues();
}

public void Event_RoundEnd(Event event, const char[] szName, bool dontBroadcast)
{
    SetDefaultValues();
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
    if(L4D_IsMissionFinalMap())
    {
        // Do not set a code on finale maps
        return;
    }

    PrintToChatAll("\x05[DOOR-LOCK]: \x04Safe Room door has been locked!");
    PrintToChatAll("\x05[DOOR-LOCK]: \x01Enter the correct code using \x04!code <code>\x01 to unlock the safe room door");
    
    ghDistanceTimer = CreateTimer(1.0, t_CheckFlowDistance, .flags=TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    CodeAttempts = 0;
    iGlobalDistance = 25;
    bShouldStopTimer = false;

    int door = L4D_GetCheckpointLast();
    if(IsValidEntity(door))
    {
        LockSafeRoomDoor();

        SafeRoomDoorCode = GetRandomInt(1000, 9999);

        PrintToServer("[DOOR-LOCK]: Locked safe room door with code %d", SafeRoomDoorCode);

        IntToString(SafeRoomDoorCode, szRoomDoorCode, sizeof(szRoomDoorCode));
    }
    flMaxFlowDistance = L4D2Direct_GetMapMaxFlowDistance();
}

public Action Command_Code(int client, int args)
{
    if(!L4D_HasAnySurvivorLeftSafeArea())
    {
        ReplyToCommand(client, "[SM]: Cannot use this command until the round starts");
        return Plugin_Handled;
    }
    if(args < 1)
    {
        ReplyToCommand(client, "[SM]: Usage: sm_code <code>");
        return Plugin_Handled;
    }
    char buffer[5];
    GetCmdArg(1, buffer, sizeof(buffer));
    int code = StringToInt(buffer);
    if(SafeRoomDoorCode == code)
    {
        OpenSafeRoomDoor();
        PrintToChatAll("\x05[DOOR-LOCK]: %N has entered the correct code. Safe Room door has been unlocked!", client);
    }
    else
    {
        CodeAttempts++;
        PrintToChatAll("\x05[DOOR-LOCK]: \x04%N \x01has entered an incorrect code. (\x05%d \x01/\x05 %d\x01)", client, CodeAttempts, iMaxCodeAttempts);
        if(CodeAttempts >= iMaxCodeAttempts)
        {
            L4D_ResetMobTimer();
            L4D_ForcePanicEvent();
            
            director_panic_forever.SetBool(true, false, false);
            CreateTimer(60.0, t_OpenSafeRoomDoor, .flags=TIMER_FLAG_NO_MAPCHANGE);

            PrintToChatAll("\x05[DOOR-LOCK]:\x04 Too many incorrect attempts. Endless hordes incoming!");
        }
    }
    return Plugin_Handled;
}

public Action t_OpenSafeRoomDoor(Handle timer)
{
    director_panic_forever.SetBool(false, false, false);
    
    PrintToChatAll("\x05[DOOR-LOCK]:\x04 Safe Room Doors are open for 20 seconds");
    OpenSafeRoomDoor();

    CreateTimer(20.0, t_CloseSafeRoomDoor, .flags=TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}
public Action t_CloseSafeRoomDoor(Handle timer)
{
    LockSafeRoomDoor();

    for(int i = 1; i<= MaxClients; i++)
    {
        if(!IsClientInGame(i)) continue;
        if(L4D_IsInLastCheckpoint(i)) continue;
        ForcePlayerSuicide(i);
    }

    PrintToChatAll("\x05[DOOR-LOCK]:\x04 All survivors outside the last saferoom have been killed!");
    return Plugin_Continue;
}
public Action t_CheckFlowDistance(Handle timer)
{
    if(bShouldStopTimer)
    {
        ghDistanceTimer = null;
        bShouldStopTimer = false;
        return Plugin_Stop;
    }
    int highestFlowSurvivor = L4D_GetHighestFlowSurvivor();
    if(!IsValidEntity(highestFlowSurvivor)) return Plugin_Continue;
    if(!IsClientInGame(highestFlowSurvivor)) return Plugin_Continue;
    if(!IsPlayerAlive(highestFlowSurvivor)) return Plugin_Continue;


    // Flow Distance Calculation by Silvers
    // found here: https://forums.alliedmods.net/showthread.php?t=321288
    float flowDistance = L4D2Direct_GetFlowDistance(highestFlowSurvivor);

    int range = RoundToCeil(flowDistance / flMaxFlowDistance * 100);

    if((range + 3) >= (iGlobalDistance))
    {        
        PrintSafeRoomDoorCode();
    }
    return Plugin_Continue;
}

void PrintSafeRoomDoorCode()
{
    if((iGlobalDistance >= 95 && iGlobalDistance <= 105) && bShownCode[3] == false)
    {
        PrintHintTextToAll("Last number of the door code: %c", szRoomDoorCode[3]);
        KillTimer(ghDistanceTimer);
        ghDistanceTimer = null;
        bShouldStopTimer = true;
        SendDistanceNotification();
        bShownCode[3] = true;
    }
    else if(iGlobalDistance == 75 && bShownCode[2] == false)
    {
        PrintHintTextToAll("Third number of the door code: %c", szRoomDoorCode[2]);
        SendDistanceNotification();
        iGlobalDistance += 25;
        bShownCode[2] = true;
    }   
    else if(iGlobalDistance == 50 && bShownCode[1] == false)
    {
        PrintHintTextToAll("Second number of the door code: %c", szRoomDoorCode[1]);
        SendDistanceNotification();
        iGlobalDistance += 25;
        bShownCode[1] = true;
    }
    else if(iGlobalDistance == 25 && bShownCode[0] == false)
    {
        PrintHintTextToAll("First number of the door code: %c", szRoomDoorCode[0]);
        SendDistanceNotification();
        iGlobalDistance += 25;
        bShownCode[0] = true;
    }
}

void OpenSafeRoomDoor()
{
    int door = L4D_GetCheckpointLast();
    if(IsValidEntity(door))
    {
        AcceptEntityInput(door, "Unlock");
        AcceptEntityInput(door, "Open");
        AcceptEntityInput(door, "StartGlowing");
            
        SetEntProp(door, Prop_Data, "m_spawnflags", SF_DOOR_USE_CLOSES);
    }
}

void LockSafeRoomDoor()
{
    int door = L4D_GetCheckpointLast();
    if(IsValidEntity(door))
    {
        AcceptEntityInput(door, "Close");
        AcceptEntityInput(door, "Lock");
        AcceptEntityInput(door, "StopGlowing");

        SetEntProp(door, Prop_Data, "m_bForceClosed", 1);
        SetEntProp(door, Prop_Data, "m_bLocked", 1);
        SetEntProp(door, Prop_Data, "m_spawnflags", SF_DOOR_LOCKED | SF_DOOR_IGNORE_USE);
    }
}

void SendDistanceNotification()
{
    char szGameMode[32];
    mp_gamemode.GetString(szGameMode, sizeof(szGameMode));

    for(int i = 1; i<= MaxClients; i++)
    {
        if(!IsClientInGame(i)) continue;
        if(IsFakeClient(i)) continue;
        mp_gamemode.ReplicateToClient(i, "versus");
    }

    Event event = CreateEvent("versus_marker_reached", true);
    event.SetInt("userid", GetClientUserId(L4D_GetHighestFlowSurvivor()));
    event.SetInt("marker", iGlobalDistance);
    event.Fire();

    for(int i = 1; i<= MaxClients; i++)
    {
        if(!IsClientInGame(i)) continue;
        if(IsFakeClient(i)) continue;
        mp_gamemode.ReplicateToClient(i, szGameMode);
    }
}


void SetDefaultValues()
{
    iGlobalDistance = 25;
    CodeAttempts = 0;
    bShouldStopTimer = false;    
    if(ghDistanceTimer != null)
    {
        KillTimer(ghDistanceTimer);
        ghDistanceTimer = null;
    }
    for(int i = 0; i< 4; i++)
    {
        bShownCode[i] = false;
    }
}