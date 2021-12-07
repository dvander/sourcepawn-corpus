#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define DEBUG 0

#define PLUGIN_VERSION "1.0.2"

new VomitSound = 1;

public Plugin:myinfo = 
{
	name = "L4D Silent Vomit Fix",
	author = "AtomicStryker",
	description = " Hear Boomers Vomit, finally ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=956475"
}

public OnPluginStart()
{
	CreateConVar("l4d_silentvomitfix_version", PLUGIN_VERSION, " Version of L4D Silent Vomit Fix on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("ability_use", Event_Ability, EventHookMode_Pre);
	
	HookEvent("player_death", Event_BileStop);
	HookEvent("player_shoved", Event_BileStop);	
}

public Event_Ability(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return; //disregard 0 clients.
	
	decl String:ability[24];
	GetEventString(event, "ability", ability, sizeof(ability));
	if (!StrEqual(ability, "ability_vomit", false)) return; //unless its Boomer Vomit i dont bother
	
	#if DEBUG
	PrintToChatAll("Biling Boomer caught: %N , id: %i", client, client);
	#endif
	
	decl String:soundpath[256];
	new luckynumber = GetRandomInt(1,5);
	
	VomitSound = luckynumber;
	
	switch(luckynumber)
	{
		case 1: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_01.wav");	}
		case 2: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_02.wav");	}
		case 3: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_03.wav");	}
		case 4: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_04.wav");	}
		case 5: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_09.wav");	}
	}
	
	for (new i=1; i <= MaxClients; i++)
	{
		// If it's not the boomer himself, emit the sound to the client (it will appear to come from the boomer)
		if (IsClientInGame(i) && !IsFakeClient(i) && i != client)
			EmitSoundToClient(i, soundpath, client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	}
}

public Event_BileStop(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return;
	if (GetClientTeam(client) != 3) return;
	
	decl String:class[96];
	GetClientModel(client, class, sizeof(class));
	if (StrContains(class, "boomer", false) == -1) return;

	decl String:soundpath[256];	
	switch(VomitSound)
	{
		case 1: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_01.wav");	}
		case 2: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_02.wav");	}
		case 3: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_03.wav");	}
		case 4: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_04.wav");	}
		case 5: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_09.wav");	}
	}
	
	for (new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			StopSound(i, SNDCHAN_AUTO, soundpath);
	}	
}