#include <sourcemod>
#include <sdktools>

#define DEBUG 1
#define JAPANESE 0
#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define MAXLENGTH 128

#define SURVIVOR 2
#define CHARGER 6
#define TANK 8

#define UNLOCK 0
#define LOCK 1

new Handle:sm_ar_announce 		= INVALID_HANDLE;

new Handle:timer1 = INVALID_HANDLE;
new Handle:timer2 = INVALID_HANDLE;
new Handle:timer3 = INVALID_HANDLE;
new Handle:timer4 = INVALID_HANDLE;
new Handle:timer5 = INVALID_HANDLE;
new Handle:timer6 = INVALID_HANDLE;
new Handle:timer7 = INVALID_HANDLE;
new Handle:timer8= INVALID_HANDLE;
new Handle:timer9 = INVALID_HANDLE;
new Handle:timer10 = INVALID_HANDLE;
new Handle:timer_lock = INVALID_HANDLE;

new Entity = 0;
new deadlock_time;

/* Lock flag */
new SafetyLock;

/* Keyman's ID */
new idKeyman;

/* Goal door ID */
new idGoal;

/* Keyman's name */
new String:nmKeyman[MAXLENGTH];

/* Has the goal SR door been opened */
new already_opened = 0;

/* Sound file */
new String:SoundNotice[MAXLENGTH] = "doors/latchlocked2.wav";
new String:SoundDoorOpen[MAXLENGTH] = "doors/door_squeek1.wav";
new String:SoundDoorSpawn[MAXLENGTH] = "music/gallery_music.mp3";

/* Assault door model */
new String:ModelAssault[MAXLENGTH] = "models/props_doors/checkpoint_door_02.mdl";

public Plugin:myinfo = 
{
    name = "[L4D2] Anti-Runner System feat.Assault door",
    author = "ztar",
    description = "Only Keyman can open saferoom door.",
    version = PLUGIN_VERSION,
    url = "http://ztar.blog7.fc2.com/"
}

public OnPluginStart()
{
    sm_ar_announce			= CreateConVar("sm_ar_announce","1", "Announce plugin info(0:OFF 1:ON)", CVAR_FLAGS);
	deadlock_time			= CreateConVar("l4d2_deadlock_time","15.0", "Lock door if any Tank is alive(0:OFF 1:ON)", CVAR_FLAGS,true,0.0,true,600.0);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_use", Event_Player_Use);
	HookEvent("round_start", Event_Round_Start);
	HookEvent("round_end", Event_Round_End);
	HookEvent("player_team", Event_Join_Team);
	
	AutoExecConfig(true, "l4d2_anti-runner");
}

public OnMapStart()
{
    /* Precache */
    PrecacheSound(SoundNotice, true);
    PrecacheSound(SoundDoorOpen, true);
    PrecacheSound(SoundDoorSpawn, true);
    PrecacheModel(ModelAssault, true);
}

public OnClientPutInServer(client)
{
    if(!IsValidEntity(client))
        return;
    if(IsFakeClient(client))
        return;
    
    /* Announce about this plugin */
    CreateTimer(8.0, TimerAnnounce, client);
}

public Event_Join_Team(Handle:event, String:event_name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new clientTeam = GetEventInt(event, "team");
    new bool:isBot = GetEventBool(event, "isbot");
    
    if(!IsValidEntity(client) || isBot == true)
        return;
    if(clientTeam == SURVIVOR)
    {
        SelectKeyman();
        #if DEBUG
        LogMessage("[ARS][1] Keyman selected -> <%d:%s>", idKeyman, nmKeyman);
        #endif
    }
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
    if(IsClientInGame(client) && GetConVarInt(sm_ar_announce))
        PrintToChat(client, "\x04[ARS]\x01 Goal Saferoom is closed. Keyman will be selected automatically.");
}

public OnClientDisconnect(client)
{
    if(!IsValidEntity(client))
        return;
    
    /* If Keyman disconnect, Re-select Keyman */
    if(client == idKeyman)
    {
        SelectKeyman();
        #if DEBUG
        LogMessage("[ARS][2] Keyman selected -> <%d:%s>", idKeyman, nmKeyman);
        #endif
    }
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
  	CreateTimer(5.0, RoundStartDelay)
}

public Action:RoundStartDelay(Handle:timer, any:client)
{
    InitDoor();
    SelectKeyman();
    #if DEBUG
    LogMessage("[ARS][3] Keyman selected -> <%d:%s>", idKeyman, nmKeyman);
    #endif
	if (timer1 != INVALID_HANDLE)
	{	
		KillTimer(timer1)
		timer1 = INVALID_HANDLE
	}
	if (timer2 != INVALID_HANDLE)
	{	
		KillTimer(timer2)
		timer2 = INVALID_HANDLE
	}
	if (timer3 != INVALID_HANDLE)
	{	
		KillTimer(timer3)
		timer3 = INVALID_HANDLE
	}
	if (timer4 != INVALID_HANDLE)
	{	
		KillTimer(timer4)
		timer4 = INVALID_HANDLE
	}
	if (timer5 != INVALID_HANDLE)
	{	
		KillTimer(timer5)
		timer5 = INVALID_HANDLE
	}
	if (timer6 != INVALID_HANDLE)
	{	
		KillTimer(timer6)
		timer6 = INVALID_HANDLE
	}
	if (timer7 != INVALID_HANDLE)
	{	
		KillTimer(timer7)
		timer7 = INVALID_HANDLE
	}
	if (timer8 != INVALID_HANDLE)
	{	
		KillTimer(timer8)
		timer8 = INVALID_HANDLE
	}
	if (timer9 != INVALID_HANDLE)
	{	
		KillTimer(timer9)
		timer9 = INVALID_HANDLE
	}
	if (timer10 != INVALID_HANDLE)
	{	
		KillTimer(timer10)
		timer10 = INVALID_HANDLE
	}
	if (timer_lock != INVALID_HANDLE)
	{	
		KillTimer(timer_lock)
		timer_lock = INVALID_HANDLE
	}
	already_opened = 0;
}


public InitDoor()
{
    new Entity2 = -1;
    while((Entity2 = FindEntityByClassname(Entity2, "prop_door_rotating_checkpoint")) != -1)
    {
        if(GetEntProp(Entity2, Prop_Data, "m_hasUnlockSequence") == UNLOCK)
        {
            idGoal = Entity2;
            ControlDoor(Entity2, LOCK);
        }
    }
    SafetyLock = LOCK;
}


public SelectKeyman()
{
    new count = 0;
    new idAlive[MAXPLAYERS+1];
    
    /* See all clients */
    for (new i = 1; i <= GetMaxClients(); i++)
    {
        /* is valid, in game, alive, and not bot */
        if(IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
        {
            /* Survivor team */
            if(GetClientTeam(i) == 2)
            {
                idAlive[count] = i;
                count++;
            }
        }
    }
    if(count == 0) return;
    new key = GetRandomInt(0, count-1);
    
    /* Get Keyman ID and name */
    idKeyman = idAlive[key];
    GetClientName(idKeyman, nmKeyman, sizeof(nmKeyman));
    
    return;
}


public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    
    /* If victim was Keyman, Re-select Keyman */
    if(victim == idKeyman)
    {
        SelectKeyman();
        #if DEBUG
        LogMessage("[ARS][4] Keyman selected -> <%d:%s>", idKeyman, nmKeyman);
        #endif
    }
    return Plugin_Continue;
}



public Action:Event_Player_Use(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    Entity = GetEventInt(event, "targetid");
	    
    if(IsValidEntity(Entity) && (SafetyLock == LOCK) && (Entity == idGoal))
	{
		#if DEBUG
        LogMessage("Tür wird versucht, zu öffnen");
        #endif
        new String:entname[MAXLENGTH];
        if(GetEdictClassname(Entity, entname, sizeof(entname)))
        {
            /* Saferoom door */
            if(StrEqual(entname, "prop_door_rotating_checkpoint"))
            {
                AcceptEntityInput(Entity, "Lock");
                SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", LOCK);
                
                if(!IsValidEntity(idKeyman) || !IsClientInGame(idKeyman) || !IsPlayerAlive(idKeyman) || IsFakeClient(idKeyman))
                {
                    SelectKeyman();
                    #if DEBUG
                    LogMessage("[ARS][5] Keyman selected -> <%d:%s>", idKeyman, nmKeyman);
                    #endif
                }
                
                if(client == idKeyman)
                {
                    #if DEBUG
					LogMessage("Tür wird entsperrt");
					#endif
					/* If client is Keyman, unlock */
                    EmitSoundToAll(SoundDoorOpen, Entity);
                    SafetyLock = UNLOCK;
					ControlDoor(Entity, UNLOCK);
					already_opened = 1;  //If == 1 --> door has been unlocked by keyman
					if(GetConVarInt(sm_ar_announce))
                    {
						PrintToChatAll("\x04[ARS]\x03 Keyman \x01<%s>\x03 unlocked the saferoom door!", nmKeyman);
					}
					CreateTimer(5.0, DeadLockSealInfo)
				}
                else
                {
                    /* Notify client who is Keyman */
                    EmitSoundToAll(SoundNotice, Entity);
                    PrintHintTextToAll("Keyman is: %s.\nOnly the keyman can unlock the door!", nmKeyman);
                }
            }
        }
	}
	
	if(IsValidEntity(Entity) && (SafetyLock == UNLOCK) && (Entity == idGoal) && (already_opened == 1))
    {
		#if DEBUG
		LogMessage("Bereits entsperrte Tür wurde nochmals berührt");
		#endif
		already_opened = 2;
		timer1 		= 	CreateTimer(60.0, DeadLockNotify1);
		timer2 		= 	CreateTimer(120.0, DeadLockNotify2);
		timer3 		= 	CreateTimer(180.0, DeadLockNotify3);
		timer4 		= 	CreateTimer(210.0, DeadLockNotify4);
		timer5 		= 	CreateTimer(225.0, DeadLockNotify5);
		timer6 		= 	CreateTimer(235.0, DeadLockNotify6);
		timer7 		= 	CreateTimer(236.0, DeadLockNotify7);
		timer8 		= 	CreateTimer(237.0, DeadLockNotify8);
		timer9 		= 	CreateTimer(238.0, DeadLockNotify9);
		timer10		= 	CreateTimer(239.0, DeadLockNotify10);
		timer_lock 	=	CreateTimer(240.0, LockDoorForever);
	}
	
	if(IsValidEntity(Entity) && (SafetyLock == UNLOCK) && (Entity == idGoal) && (already_opened == 3))
    {
		PrintToChatAll("[ALERT]Door has been deadlock sealed. No way in or out possible!");
	}
return Plugin_Continue;
}

public Action:DeadLockSealInfo(Handle:timer, any:client)
{
    PrintToChatAll("\x04[ALERT]\x03Saferoom door gets DEADLOCK SEALED in 4 minutes!");
}

public Action:LockDoorForever(Handle:timer, any:client)
{
    ControlDoor(Entity, LOCK);
	PrintToChatAll("\x04[ALERT]\x03Saferoom door is now DEADLOCK SEALED!");
	PrintToChatAll("\x04[ALERT]\x03NO way in - NO way out!")
	already_opened = 3;
}

public Action:DeadLockNotify1(Handle:timer, any:client)
{
    PrintToChatAll("\x04[ALERT]\x03Saferoom door gets DEADLOCK SEALED in 3 minutes!");
}
public Action:DeadLockNotify2(Handle:timer, any:client)
{
    PrintToChatAll("\x04[ALERT]\x03Saferoom door gets DEADLOCK SEALED in 2 minutes!");
}
public Action:DeadLockNotify3(Handle:timer, any:client)
{
    PrintToChatAll("\x04[ALERT]\x03Saferoom door gets DEADLOCK SEALED in 1 minute!");
}
public Action:DeadLockNotify4(Handle:timer, any:client)
{
    PrintToChatAll("\x04[ALERT]\x03Saferoom door gets DEADLOCK SEALED in 30 seconds!");
}
public Action:DeadLockNotify5(Handle:timer, any:client)
{
    PrintToChatAll("\x04[ALERT]\x03Saferoom door gets DEADLOCK SEALED in 15 seconds!");
}
public Action:DeadLockNotify6(Handle:timer, any:client)
{
    PrintToChatAll("\x04[ALERT]\x03Saferoom door gets DEADLOCK SEALED in 5 seconds!");
}
public Action:DeadLockNotify7(Handle:timer, any:client)
{
    PrintToChatAll("\x04[ALERT]\x03Saferoom door gets DEADLOCK SEALED in 4 seconds!");
}
public Action:DeadLockNotify8(Handle:timer, any:client)
{
    PrintToChatAll("\x04[ALERT]\x03Saferoom door gets DEADLOCK SEALED in 3 seconds!");
}
public Action:DeadLockNotify9(Handle:timer, any:client)
{
    PrintToChatAll("\x04[ALERT]\x03Saferoom door gets DEADLOCK SEALED in 2 seconds!");
}
public Action:DeadLockNotify10(Handle:timer, any:client)
{
    PrintToChatAll("\x04[ALERT]\x03Saferoom door gets DEADLOCK SEALED in 1 second!");
}


public Action:Event_Round_End(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (timer1 != INVALID_HANDLE)
	{	
		KillTimer(timer1)
		timer1 = INVALID_HANDLE
	}
	if (timer2 != INVALID_HANDLE)
	{	
		KillTimer(timer2)
		timer2 = INVALID_HANDLE
	}
	if (timer3 != INVALID_HANDLE)
	{	
		KillTimer(timer3)
		timer3 = INVALID_HANDLE
	}
	if (timer4 != INVALID_HANDLE)
	{	
		KillTimer(timer4)
		timer4 = INVALID_HANDLE
	}
	if (timer5 != INVALID_HANDLE)
	{	
		KillTimer(timer5)
		timer5 = INVALID_HANDLE
	}
	if (timer6 != INVALID_HANDLE)
	{	
		KillTimer(timer6)
		timer6 = INVALID_HANDLE
	}
	if (timer7 != INVALID_HANDLE)
	{	
		KillTimer(timer7)
		timer7 = INVALID_HANDLE
	}
	if (timer8 != INVALID_HANDLE)
	{	
		KillTimer(timer8)
		timer8 = INVALID_HANDLE
	}
	if (timer9 != INVALID_HANDLE)
	{	
		KillTimer(timer9)
		timer9 = INVALID_HANDLE
	}
	if (timer10 != INVALID_HANDLE)
	{	
		KillTimer(timer10)
		timer10 = INVALID_HANDLE
	}
	if (timer_lock != INVALID_HANDLE)
	{	
		KillTimer(timer_lock)
		timer_lock = INVALID_HANDLE
	}
	already_opened = 0;
} 


	
public ControlDoor(Entity, Operation)
{
    if(Operation == LOCK)
    {
        /* Close and lock */
        AcceptEntityInput(Entity, "Close");
        AcceptEntityInput(Entity, "Lock");
        AcceptEntityInput(Entity, "ForceClosed");
        SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", LOCK);
    }
    else if(Operation == UNLOCK)
    {
        /* Unlock and open */
        SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
        AcceptEntityInput(Entity, "Unlock");
        AcceptEntityInput(Entity, "ForceClosed");
        AcceptEntityInput(Entity, "Open");
    }
}