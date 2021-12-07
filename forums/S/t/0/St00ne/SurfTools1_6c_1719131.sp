// (v1.6c) for .:€S C 90:. servers - 11/2014.

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

new Handle:Enabled;
new Handle:RespawnEnabled;
new Handle:RespawnTime;
new Handle:NoBlock;
new Handle:SpawnProtectionEnabled;
new Handle:SpawnProtectionTime;
new Handle:SpawnWeapon;
new Handle:SpawnWeaponDelay;
new Handle:SpawnWeaponEnabled;
new Handle:MsgEnabled;

new CollOff;

new bool:EventsHooked;

public Plugin:myinfo = 
{
	name = "Surf Tools",
	author = "Fredd, St00ne",
	description = "Adds Fun to Surf Servers",
	version = "1.6c",
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	new Handle:version_cvar = CreateConVar("st_version", "1.6c", "Surf Tools version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	SetConVarString(version_cvar, "1.6c", false, false);
	
	Enabled					=	CreateConVar("st_enabled",				"1",				"0 = Plugin Disabled, 1 = Plugin Enabled");
	RespawnEnabled			=	CreateConVar("st_respawn",				"1",				"Enables/disables respawn");
	RespawnTime				=	CreateConVar("st_respawntime",			"5",				"Respawn delay");
	NoBlock					=	CreateConVar("st_noblock",				"1",				"Toggles noblock on and off");
	SpawnProtectionTime		=	CreateConVar("st_sptime",				"5",				"Spawn protection time");
	SpawnProtectionEnabled	=	CreateConVar("st_sp_enabled",			"1",				"Spawn protection on, off");
	SpawnWeapon				=	CreateConVar("st_spawnweapon",			"weapon_knife",		"Weapon given at respawn");
	SpawnWeaponDelay		=	CreateConVar("st_spawnweapon_delay",	"0",				"Delay before spawn weapon shows up - helps overriding spawn weapon on some maps");
	SpawnWeaponEnabled		=	CreateConVar("st_spawnweapon_enabled",	"0",				"Spawn weapon on/off");
	MsgEnabled				=	CreateConVar("st_msg_enabled",			"0",				"Advert enabled/disabled");
	
	CollOff					=	FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	
	EventsHooked = true;
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	HookConVarChange(Enabled, OnConVarChange);
	
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_spawn", PlayerSpawn);
	
	CreateTimer(90.0, PrintMsg, _, TIMER_REPEAT);
}

public Action:PrintMsg(Handle:timer)
{
	if(GetConVarInt(Enabled) == 1 && GetConVarInt(RespawnEnabled) == 1 && GetConVarInt(MsgEnabled) == 1)
		PrintToChatAll("\x04[SurfTools] \x01This server is running \x04SurfTools\x01. To respawn, please type: \x04/respawn\x01 or \x04respawn\x01.");
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new value = !!StringToInt(newValue);
	if (value == 0)
	{
		if (EventsHooked == true)
		{
			EventsHooked = false;
			
			UnhookEvent("player_death", PlayerDeath);
			UnhookEvent("player_spawn", PlayerSpawn);
		}
	}
	else
	{
		EventsHooked = true;
		
		HookEvent("player_death", PlayerDeath);
		HookEvent("player_spawn", PlayerSpawn);
	}
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(RespawnEnabled) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client && client != 0 && IsClientConnected(client))
		{
			if (IsClientInGame(client))
			{
				RespawnClient(client);
			}
		}
	}
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client && IsClientConnected(client) && client != 0)
	{
		if(IsClientInGame(client))
		{
			new Team = GetClientTeam(client);
			
			if(IsPlayerAlive(client) && (Team == 2 || Team == 3))
			{
				if(GetConVarInt(SpawnProtectionEnabled) == 1)
					SpawnProtctClient(client);
				
				if(GetConVarInt(NoBlock) == 1)
					SetEntData(client, CollOff, 2, 4, true);
				
				if(GetConVarInt(SpawnWeaponEnabled) == 1 && GetConVarInt(SpawnWeaponDelay) == 0)
				{
					decl String:WpnName[33];
					GetConVarString(SpawnWeapon, WpnName, sizeof(WpnName));
					
					if(StrContains(WpnName, "weapon_") != -1)
						GivePlayerItem(client, WpnName);
					else
						LogError("st_spawnweapon is not set to a valid weapon name...");
					
					RemoveModels();
				}
				
				else if(GetConVarInt(SpawnWeaponEnabled) == 1 && GetConVarInt(SpawnWeaponDelay) != 0)
					GiveAWeapon(client);
			}
		}
	}
}

public Action:Command_Say(client, args)
{
	if (client && IsClientConnected(client) && client != 0)
	{
		if(IsClientInGame(client))
		{
			if(GetConVarInt(RespawnEnabled) == 0)
				return Plugin_Continue;
			
			if(GetConVarInt(Enabled) == 1)
			{   
				decl String:text[192];
				GetCmdArgString(text, sizeof(text));
				
				new startidx = 0;
				if (text[0] == '"')
				{
					startidx = 1;
					
					new len = strlen(text);
					if (text[len-1] == '"')
					{
						text[len-1] = '\0';
					}
				}
				if(StrEqual(text[startidx], "/respawn") || StrEqual(text[startidx], "respawn") || StrEqual(text[startidx], "!respawn"))
					RespawnClient(client);
			}
		}
	}
	
	return Plugin_Continue;
}

stock RespawnClient(client)
{
	if (client && IsClientConnected(client) && client != 0)
	{	
		if (IsClientInGame(client))
		{
			new Team = GetClientTeam(client);
			
			if(Team == 0 || Team == 1)
			{
				PrintToChat(client, "\x04[SurfTools] \x01You must be in a team first.");
				return;
			}
			if(IsPlayerAlive(client))
			{
				PrintToChat(client, "\x04[SurfTools] \x01You must be dead to use this command.");
				return;
			}
			if (!IsPlayerAlive(client) && Team > 1)
			{
				new Float:Timer = float(GetConVarInt(RespawnTime));
				
				PrintToChat(client, "\x04[SurfTools] \x01You will be respawned in \x04%i \x01seconds.", RoundToNearest(Timer));
				CreateTimer(Timer, Respawn, GetClientSerial(client));
				
				return;
			}
		}
	}
}

stock SpawnProtctClient(client)
{
	if (client && IsClientConnected(client) && client != 0)
	{
		if(IsClientInGame(client))
		{
			new Float:Timer = float(GetConVarInt(SpawnProtectionTime));
			
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			PrintToChat(client, "\x04[SurfTools] \x01You will be spawn protected for \x04%i \x01seconds...", RoundToNearest(Timer));
			CreateTimer(Timer, RemoveSpawnProtection, GetClientSerial(client));
			
			return;
		}
	}
}

public Action:RemoveSpawnProtection(Handle:Timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client && IsClientConnected(client) && client != 0)
	{
		if(IsClientInGame(client))
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			PrintToChat(client, "\x04[SurfTools] \x01Spawn protection is now off.");
		}
	}
}

public Action:Respawn(Handle:Timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client && IsClientConnected(client) && client != 0)
	{
		if(IsClientInGame(client) && !IsPlayerAlive(client))
		{
			new Team = GetClientTeam(client);
			if (Team > 1)
			{
				CS_RespawnPlayer(client);
			}
		}
	}
}

stock GiveAWeapon(client)
{
	new Float:Timer = float(GetConVarInt(SpawnWeaponDelay));
	CreateTimer(Timer, GiveThatWeapon, GetClientSerial(client));
	
	return;
}

public Action:GiveThatWeapon(Handle:Timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client && IsClientConnected(client) && client != 0)
	{
		if(IsClientInGame(client))
		{
			new Team = GetClientTeam(client);
			if(IsPlayerAlive(client) && (Team == 2 || Team == 3))
			{
				decl String:WpnName[33];
				GetConVarString(SpawnWeapon, WpnName, sizeof(WpnName));
				
				if(StrContains(WpnName, "weapon_") != -1)
					GivePlayerItem(client, WpnName);
				else
					LogError("st_spawnweapon is not set to a valid weapon name...");
				
				RemoveModels();
			}
		}
	}
}

stock RemoveModels()
{
	new start = GetMaxClients();
	for(new i = start+1; i <= GetMaxEntities(); i++)
	{
		if(IsValidEntity(i))
		{
			new String:EntModel[128];
			GetEntPropString(i, Prop_Data, "m_ModelName", EntModel, sizeof(EntModel));
			
			if ((StrContains(EntModel, "models/weapons/w_knife.mdl") != -1)
			|| (StrContains(EntModel, "models/weapons/w_knife_t.mdl") != -1)
			|| (StrContains(EntModel, "models/weapons/w_knife_ct.mdl") != -1))
			{
				RemoveEdict(i);
			}
		}
	}
}

//***END***//