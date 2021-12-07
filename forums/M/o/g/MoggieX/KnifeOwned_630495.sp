// Based upon Kinfe Mug by FlyingMongoose & sslice
// When a player is stabbed they get publicly humilated in chat and HAHA or other sound in game

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#define KO_VERSION "1.1"
#define MAX_FILE_LEN 80
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

// Define author information
public Plugin:myinfo = 
{
	name = "Knife Owned",
	author = "MoggieX",
	description = "Ownd by Knife",
	version = KO_VERSION,
	url = "http://www.UKManDown.co.uk"
};

new Handle:cvarEnable;
new bool:g_isHooked;

public OnPluginStart()
{
	CreateConVar("sm_knife_Owned_version", KO_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	cvarEnable = CreateConVar("sm_knife_enable","1","Plays sound and gives chat ntoification when a player is knifed",FCVAR_PLUGIN,true,0.0,true,1.0);
	g_CvarSoundName = CreateConVar("sm_knife_sound", "misc/haha.wav", "The sound to play when a player is knifed");
	CreateTimer(3.0, OnPluginStart_Delayed);
}

// For sounds and its caching
public OnConfigsExecuted()
{
	GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(g_soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	AddFileToDownloadsTable(buffer);
}


public Action:OnPluginStart_Delayed(Handle:timer){
	if(GetConVarInt(cvarEnable) > 0)
	{
		g_isHooked = true;
		HookEvent("player_death",ev_PlayerDeath);
		
		HookConVarChange(cvarEnable,KnifeOwnedCvarChange);
		
		LogMessage("[Knife Notification] - Loaded");
	}
}

public KnifeOwnedCvarChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(GetConVarInt(cvarEnable) <= 0){
		if(g_isHooked){
		g_isHooked = false;
		UnhookEvent("player_death",ev_PlayerDeath);
		}
	}else if(!g_isHooked){
		g_isHooked = true;
		HookEvent("player_death",ev_PlayerDeath);
	}
}

public ev_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if enabled, if not bail out

	if (GetConVarInt(cvarEnable) == 0)
	{
		return;
	}

	decl String:weaponName[100];
	decl String:victimName[100];
	decl String:killerName[100];
	
	GetEventString(event,"weapon",weaponName,100);

	// if the weapon used in death was a knife it continues

	if(StrEqual(weaponName, "knife"))
	{
		new userid = GetEventInt(event, "userid");
		new userid2 = GetEventInt(event, "attacker");
		
		new victim = GetClientOfUserId(userid);
		new killer = GetClientOfUserId(userid2);
		
		if(victim != 0 && killer != 0)
		{
			new victimTeam = GetClientTeam(victim);
			new killerTeam = GetClientTeam(killer);

			if(killerTeam!=victimTeam)
			{
				GetClientName(victim,victimName,100);
				GetClientName(killer,killerName,100);

				PrintToChatAll("\x04 %s\x03 was OWND with a knife by \x04 %s",victimName,killerName);
				EmitSoundToAll(g_soundName);
			}
		}
	}
}

