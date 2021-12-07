#include <sourcemod>
#include <sdktools>

bool:AfkSoundFix[MAXPLAYERS+1];
bool:DeathSoundFix[MAXPLAYERS+1];
bool:RescueSoundFix[MAXPLAYERS+1];
bool:RoundSoundStart[MAXPLAYERS+1];
bool:ThirdPerson[MAXPLAYERS+1];

static const String:SOUND_AUTOSHOTGUN[] 		= "^weapons/auto_shotgun/gunfire/auto_shotgun_fire_1.wav";
static const String:SOUND_SPASSHOTGUN[] 		= "weapons/auto_shotgun_spas/gunfire/shotgun_fire_1.wav";
static const String:SOUND_PUMPSHOTGUN[] 		= "^weapons/shotgun/gunfire/shotgun_fire_1.wav";
static const String:SOUND_CHROMESHOTGUN[] 		= "weapons/shotgun_chrome/gunfire/shotgun_fire_1.wav";

//GameMode;
L4D2Version;

public Plugin:myinfo = 
{
    name = "L4D2 Thirdpersonshoulder Shotgun sound bug fix",
    author = "DeathChaos25, MasterMind420",
    description = "Fixes the bug where shotguns make no sound when shot in thirdperson shoulder",
    version = "1.1",
    url = "https://forums.alliedmods.net/showthread.php?t=259986"
}

/*
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    decl String:s_GameFolder[32];
    GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
    if (!StrEqual(s_GameFolder, "left4dead2", false))
    {
        strcopy(error, err_max, "This plugin is for Left 4 Dead 2 Only!");
        return APLRes_Failure;
    }
    return APLRes_Success; 
}
*/

public OnPluginStart()
{
	GameCheck();

	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_death", player_death, EventHookMode_PostNoCopy);
	HookEvent("survivor_rescued", survivor_rescued, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", player_bot_replace, EventHookMode_PostNoCopy);
	
	CreateTimer(0.1, ThirdPersonCheck, INVALID_HANDLE, TIMER_REPEAT);
}

GameCheck()
{
	decl String:GameName[16];
/*
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));

	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
		GameMode = 0;
*/
	GetGameFolderName(GameName, sizeof(GameName));

	if (StrEqual(GameName, "left4dead2", false))
		L4D2Version=true;
	else
		L4D2Version=false;

	//GameMode+=0;
}

public OnMapStart()
{
	PrefetchSound(SOUND_AUTOSHOTGUN);
	PrecacheSound(SOUND_AUTOSHOTGUN, true);

	PrefetchSound(SOUND_SPASSHOTGUN);
	PrecacheSound(SOUND_SPASSHOTGUN, true);

	PrefetchSound(SOUND_CHROMESHOTGUN);
	PrecacheSound(SOUND_CHROMESHOTGUN, true);

	PrefetchSound(SOUND_PUMPSHOTGUN);
	PrecacheSound(SOUND_PUMPSHOTGUN, true);

	for (new client = 1; client <= MaxClients; client++)
		RoundSoundStart[client] = true;
}

public OnClientPutInServer(client)
{
	RoundSoundStart[client] = true;
}

public void OnClientPostAdminCheck(client)
{
	AfkSoundFix[client] = false;
	RescueSoundFix[client] = false;
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client < 0 || client > MAXPLAYERS || !IsPlayerAlive(client) || GetClientTeam(client) != 2) 
		return Plugin_Handled;

	if (StrEqual(weapon, "autoshotgun") && ThirdPerson[client] == true)
		EmitSoundToAll(SOUND_AUTOSHOTGUN, client, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
	else if (StrEqual(weapon, "shotgun_spas") && ThirdPerson[client] == true)
		EmitSoundToAll(SOUND_SPASSHOTGUN, client, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
	else if (StrEqual(weapon, "pumpshotgun") && ThirdPerson[client] == true)
		EmitSoundToAll(SOUND_PUMPSHOTGUN, client, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
	else if (StrEqual(weapon, "shotgun_chrome") && ThirdPerson[client] == true)
		EmitSoundToAll(SOUND_CHROMESHOTGUN, client, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);

	return Plugin_Continue;
}

/*THIRDPERSON CHECK*/
public Action:ThirdPersonCheck(Handle:hTimer)
{
    for (new client = 1; client <= MaxClients; client++)
    {
        if(!IsClientInGame(client) || GetClientTeam(client) != 2 || IsFakeClient(client)) { continue; }
        QueryClientConVar(client, "c_thirdpersonshoulder", QueryClientConVarCallback);
    }
}

public QueryClientConVarCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (IsClientInGame(client) && !IsClientInKickQueue(client))
	{
		if (result != ConVarQuery_Okay) { ThirdPerson[client] = true; }
		else if (!StrEqual(cvarValue, "false") && !StrEqual(cvarValue, "0")) //THIRDPERSONSHOULDER
		{
			if(RoundSoundStart[client]) { ThirdPerson[client] = false, RoundSoundStart[client] = false; }
			else if(AfkSoundFix[client]){ ThirdPerson[client] = false; }
			else if(DeathSoundFix[client]) { ThirdPerson[client] = false; }
			else if(RescueSoundFix[client]) { ThirdPerson[client] = false; }
			else { ThirdPerson[client] = true; }
		}
		else //FIRSTPERSON
		{
			if(RoundSoundStart[client]) { ThirdPerson[client] = false, RoundSoundStart[client] = false; }
			AfkSoundFix[client] = false;
			DeathSoundFix[client] = false;
			RescueSoundFix[client] = false;
			ThirdPerson[client] = false;
		}
	}
}
/*THIRDPERSON CHECK*/

/*THIRDPERSON CHECK FIXES*/
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	AfkSoundFix[client] = true;
}

public Action:survivor_rescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	RescueSoundFix[client] = true;
}

public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	DeathSoundFix[client] = true;
}
/*THIRDPERSON CHECK FIXES*/