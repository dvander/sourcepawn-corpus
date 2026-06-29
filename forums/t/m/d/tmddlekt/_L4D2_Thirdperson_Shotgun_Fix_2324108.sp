#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
    name = "L4D2 Thirdperson Shotgun sound Fix",
    author = "DeathChaos25 ( ver.tmddlekt )",
    description = "Fixes the bug where shotguns make no sound when shot in thirdperson shoulder",
    version = "1.1",
    url = "https://forums.alliedmods.net/showthread.php?t=259986"
}

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

static const String:SOUND_AUTOSHOTGUN[]   = "weapons/auto_shotgun/gunfire/auto_shotgun_fire_1.wav";
static const String:SOUND_SPASSHOTGUN[]   = "weapons/auto_shotgun_spas/gunfire/shotgun_fire_1.wav";
static const String:SOUND_PUMPSHOTGUN[]   = "weapons/shotgun/gunfire/shotgun_fire_1.wav";
static const String:SOUND_CHROMESHOTGUN[] = "weapons/shotgun_chrome/gunfire/shotgun_fire_1.wav";

new Handle:tMessage_Enable 			 = INVALID_HANDLE;
new Handle:tMessage_Time 			 = INVALID_HANDLE;
new Handle:Timer_MSG[MAXPLAYERS+1] 	 = INVALID_HANDLE;
new Handle:Timer_Check[MAXPLAYERS+1] = INVALID_HANDLE;
new bool:Thirdperson[MAXPLAYERS+1];
new bool:Fix_Disable[MAXPLAYERS+1];
new cWeapon[MAXPLAYERS+1];

public OnPluginStart()
{
	tMessage_Enable = CreateConVar("ssf_message", "1",_, FCVAR_PLUGIN);
	tMessage_Time	= CreateConVar("ssf_message_time", "60.0",_, FCVAR_PLUGIN);
	RegConsoleCmd("sm_ssf", cmd_ssf);
	HookEvent("weapon_fire", Event_WeaponFire);
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
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
	{
		if(Timer_Check[client] != INVALID_HANDLE)
		{
			KillTimer(Timer_Check[client]);
			Timer_Check[client] = INVALID_HANDLE;
		}
		
		if(Timer_MSG[client] != INVALID_HANDLE)
		{
			KillTimer(Timer_MSG[client]);
			Timer_MSG[client] = INVALID_HANDLE;
		}
		
		if(!Fix_Disable[client])
			Timer_Check[client] = CreateTimer(0.1, Third_Check, client, TIMER_REPEAT);
		Timer_MSG[client] = CreateTimer(GetConVarFloat(tMessage_Time), Timer_Message, client, TIMER_REPEAT);
	}
	Fix_Disable[client] = false;
	cWeapon[client] = 0;
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{
		if(Timer_Check[client] != INVALID_HANDLE)
		{
			KillTimer(Timer_Check[client]);
			Timer_Check[client] = INVALID_HANDLE;
		}
		else
		{
			Fix_Disable[client] = true;
		}	
		
		if(Timer_MSG[client] != INVALID_HANDLE)
		{
			KillTimer(Timer_MSG[client]);
			Timer_MSG[client] = INVALID_HANDLE;
		}
		Thirdperson[client] = false;
		cWeapon[client] = 0;
	}
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Thirdperson[client])
	{
		if (cWeapon[client] == 1)		EmitSoundToClient(client, SOUND_AUTOSHOTGUN, client, SNDCHAN_WEAPON);
		else if(cWeapon[client] == 2)	EmitSoundToClient(client, SOUND_SPASSHOTGUN, client, SNDCHAN_WEAPON);
		else if(cWeapon[client] == 3)	EmitSoundToClient(client, SOUND_PUMPSHOTGUN, client, SNDCHAN_WEAPON);
		else if(cWeapon[client] == 4)	EmitSoundToClient(client, SOUND_CHROMESHOTGUN, client, SNDCHAN_WEAPON);
	}
}  

public Action:cmd_ssf(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "\x01[SM] sm_ssf < \x03on \x01/ \x04off \x01>");
		return;
	}

	new String:aString[4];
	GetCmdArg(1, aString, sizeof(aString));
	
	if(StrEqual(aString, "on"))
	{
		if(Timer_Check[client] != INVALID_HANDLE)
		{
			PrintToChat(client, "\x01[SM] \x03Already \x01Shotgun Sound Fix \x03Enabled\x01.");
		}
		else
		{
			Timer_Check[client] = CreateTimer(0.1, Third_Check, client, TIMER_REPEAT);
			PrintToChat(client, "\x01[SM] Shotgun Sound Fix is \x03Enable\x01!");	
		}
	}
	else if(StrEqual(aString, "off"))
	{
		if(Timer_Check[client] == INVALID_HANDLE)
		{
			PrintToChat(client, "\x01[SM] \x03Already \x01Shotgun Sound Fix \x04Disabled\x01.");
		}
		else
		{	
			KillTimer(Timer_Check[client]);
			Timer_Check[client] = INVALID_HANDLE;
			CreateTimer(0.1, Timer_Disable, client);
			PrintToChat(client, "\x01[SM] Shotgun Sound Fix is \x04Disable\x01!");	
		}	
	}
	else
	{
		PrintToChat(client, "\x01[SM] sm_ssf \x01( \x03on \x01/ \x04off \x01)");
	}	
}

public Action:Timer_Message(Handle:timer, any:client)
{
	if(IsClientConnected(client) && IsClientInGame(client)&& GetClientTeam(client) == 2 && !IsFakeClient(client))
	{
		if(GetConVarBool(tMessage_Enable))
		{
			if(Timer_Check[client] != INVALID_HANDLE)
				PrintToChat(client, "\x01[SM] Shotgun Sound Fix :  \x03Enabled  \x01( !ssf  \x03on\x01/\x04off \x01)");
			else
				PrintToChat(client, "\x01[SM] Shotgun Sound Fix :  \x04Disabled  \x01( !ssf  \x03on\x01/\x04off \x01)");
		}
	}
}

public Action:Timer_Disable(Handle:timer, any:client)
{
	Thirdperson[client] = false;
}

public Action:Third_Check(Handle:timer, any:client)
{
	QueryClientConVar(client, "c_thirdpersonshoulder", ConVarQueryFinished:Client_Thirdperson, client);
	
	new String:weapon[24];
	GetClientWeapon(client, weapon, sizeof(weapon));
	
	if(StrEqual(weapon, "weapon_autoshotgun"))				cWeapon[client] = 1;		
	else if (StrEqual(weapon, "weapon_shotgun_spas"))		cWeapon[client] = 2;
	else if (StrEqual(weapon, "weapon_pumpshotgun"))		cWeapon[client] = 3;
	else if (StrEqual(weapon, "weapon_shotgun_chrome"))		cWeapon[client] = 4;
	else													cWeapon[client] = 0;
}

public Client_Thirdperson(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if(StringToInt(cvarValue) == 1)
		Thirdperson[client] = true;
	else
		Thirdperson[client] = false;
}
