#include <sourcemod>
#include <sdktools>

#define DEBUG 0
#define JAPANESE 0
#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define MAXLENGTH 128

#define SURVIVOR 2
#define CHARGER 6
#define TANK 8

#define UNLOCK 0
#define LOCK 1

new Handle:sm_ar_announce = INVALID_HANDLE;
new Handle:sm_ar_assault_health = INVALID_HANDLE;
new Handle:sm_ar_assault_hate = INVALID_HANDLE;
new Handle:sm_ar_lock_tankalive = INVALID_HANDLE;

/* Lock flag */
new SafetyLock;

/* Keyman's ID */
new idKeyman;

/* Goal door ID */
new idGoal;

/* Keyman's name */
new String:nmKeyman[MAXLENGTH];

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
    sm_ar_announce          = CreateConVar("sm_ar_announce","1", "Announce plugin info(0:OFF 1:ON)", CVAR_FLAGS);
    sm_ar_assault_health = CreateConVar("sm_ar_assault_health","2000", "Health of Assault door", CVAR_FLAGS);
    sm_ar_assault_hate      = CreateConVar("sm_ar_assault_hate","0", "Probability of spawning Assault door(0-100)", CVAR_FLAGS);
    sm_ar_lock_tankalive = CreateConVar("sm_ar_lock_tankalive","0", "Lock door if any Tank is alive(0:OFF 1:ON)", CVAR_FLAGS);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_use", Event_Player_Use);
	HookEvent("round_start", Event_Round_Start);
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
    
    /* Find goal door and lock */
    //InitDoor();
    
    /* Select Keyman */
    //SelectKeyman();
    #if DEBUG
    //LogMessage("[ARS][0] Keyman selected -> <%d:%s>", idKeyman, nmKeyman);
    #endif
}

public OnClientPutInServer(client)
{
    if(!IsValidEntity(client))
        return;
    if(IsFakeClient(client))
        return;
    
    /* Announce about this plugin */
    CreateTimer(20.0, TimerAnnounce, client);
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
    CreateTimer(15.0, RoundStartDelay)
}

public Action:RoundStartDelay(Handle:timer, any:client)
{
    InitDoor();
    SelectKeyman();
    #if DEBUG
    LogMessage("[ARS][3] Keyman selected -> <%d:%s>", idKeyman, nmKeyman);
    #endif
}


public InitDoor()
{
    new Entity = -1;
    while((Entity = FindEntityByClassname(Entity, "prop_door_rotating_checkpoint")) != -1)
    {
        if(GetEntProp(Entity, Prop_Data, "m_hasUnlockSequence") == UNLOCK)
        {
            idGoal = Entity;
            ControlDoor(Entity, LOCK);
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
    new Entity = GetEventInt(event, "targetid");
    
    if(IsValidEntity(Entity) && (SafetyLock == LOCK) && (Entity == idGoal))
    {
        new String:entname[MAXLENGTH];
        if(GetEdictClassname(Entity, entname, sizeof(entname)))
        {
            /* Saferoom door */
            if(StrEqual(entname, "prop_door_rotating_checkpoint"))
            {
                for (new i = 1; i <= GetMaxClients(); i++)
                {
                    /* is valid, in game, alive, and not bot */
                    if(IsValidEntity(i) && IsClientInGame(i))
                    {
                        if(GetEntProp(i, Prop_Send, "m_zombieClass") == TANK && GetConVarInt(sm_ar_lock_tankalive))
                        {
                            EmitSoundToAll(SoundNotice, Entity);
                            PrintHintText(client, "All tanks must be killed first!");
                            return Plugin_Continue;
                        }
                    }
                }
                
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
                    /* If client is Keyman, unlock */
                    EmitSoundToAll(SoundDoorOpen, Entity);
                    SafetyLock = UNLOCK;
                    ControlDoor(Entity, UNLOCK);
                    if(GetConVarInt(sm_ar_announce))
                    {
						PrintToChatAll("\x04[ARS]\x03 The keyman \x01<%s>\x03 reached the safe room!", nmKeyman);
                    }
                    
                    /* Caluculate probability */
                    new adProb = GetConVarInt(sm_ar_assault_hate);
                    //new adProb = GetConVarInt(sm_ar_assault_hate) * (DeadCount()+1);
                    if(adProb > 100) adProb = 100;
                    if(adProb > GetRandomInt(0, 99))
                    {
                        /* Spawn Assault door */
                        //PrintHintTextToAll("Porta de ASSALTO!");
                        //AssaultDoor(client, Entity);
                    }
                }
                else
                {
                    /* Notify client who is Keyman */
                    EmitSoundToAll(SoundNotice, Entity);
                    PrintHintTextToAll("Keyman is: %s.\nOnly the Keyman can open the door!", nmKeyman);
                }
            }
        }
    }
    return Plugin_Continue;
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

public AssaultDoor(client, Entity)
{
    if(!client) return;
    
    /* Spawn Charger */
    new admindata = GetUserFlagBits(client);
    SetUserFlagBits(client, ADMFLAG_ROOT);
    new spawnflags = GetCommandFlags("z_spawn");
    SetCommandFlags("z_spawn", spawnflags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "z_spawn charger");
    SetCommandFlags("z_spawn", spawnflags|FCVAR_CHEAT);
    SetUserFlagBits(client, admindata);
    
    for (new i = 1; i <= GetMaxClients(); i++)
    {
        /* is Charger */
        if(GetEntProp(i, Prop_Send, "m_zombieClass") == CHARGER)
        {
            /* Get entity position */
            decl Float:pos[3];
            GetClientAbsOrigin(client, pos);
            pos[2] += 30;
            
            /* Teleport after setting up */
            ScreenFade(client, 200, 0, 0, 200, 100, 1);
            SetEntityModel(i, ModelAssault);
            SetEntityHealth(i, GetConVarInt(sm_ar_assault_health));
            TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
            EmitSoundToAll(SoundDoorSpawn, i);
            
            return;
        }
    }
}

public DeadCount()
{
    new dCount = 0;
    
    /* See all clients */
    for (new i = 1; i <= GetMaxClients(); i++)
    {
        if(!IsValidEntity(i) || !IsClientInGame(i) || IsFakeClient(i))
            continue;
        
        /* Count DEAD player in survivor team */
        if(!IsPlayerAlive(i))
            dCount++;
    }
    return dCount;
}

public ScreenFade(target, red, green, blue, alpha, duration, type)
{
    new Handle:msg = StartMessageOne("Fade", target);
    BfWriteShort(msg, 500);
    BfWriteShort(msg, duration);
    if (type == 0)
        BfWriteShort(msg, (0x0002 | 0x0008));
    else
        BfWriteShort(msg, (0x0001 | 0x0010));
    BfWriteByte(msg, red);
    BfWriteByte(msg, green);
    BfWriteByte(msg, blue);
    BfWriteByte(msg, alpha);
    EndMessage();
}  