#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define DEBUG 0
#define PLUGIN_VERSION "1.0.2"

int VomitSound = 1;

public Plugin myinfo = 
{
	name = "L4D Silent Vomit Fix",
	author = "AtomicStryker(Edit. by BloodyBlade)",
	description = " Hear Boomers Vomit, finally ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=956475"
}

public void OnPluginStart()
{
	CreateConVar("l4d_silentvomitfix_version", PLUGIN_VERSION, " Version of L4D Silent Vomit Fix on this server", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	HookEvent("ability_use", Event_Ability, EventHookMode_Pre);
	HookEvent("player_death", Event_BileStop);
	HookEvent("player_shoved", Event_BileStop);	
}

void Event_Ability(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client) return; //disregard 0 clients.
	if(GetEntProp(client, Prop_Send, "m_zombieClass") != 2) return;

	char ability[24];
	event.GetString("ability", ability, sizeof(ability));
	if (!StrEqual(ability, "ability_vomit", false)) return; //unless its Boomer Vomit i dont bother

	#if DEBUG
	PrintToChatAll("Biling Boomer caught: %N , id: %i", client, client);
	#endif

	char soundpath[256];
	int luckynumber = GetRandomInt(1,5);

	VomitSound = luckynumber;

	switch(luckynumber)
	{
		case 1: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_01.wav");	}
		case 2: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_02.wav");	}
		case 3: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_03.wav");	}
		case 4: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_04.wav");	}
		case 5: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_09.wav");	}
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		// If it's not the boomer himself, emit the sound to the client (it will appear to come from the boomer)
		if (IsClientInGame(i) && !IsFakeClient(i) && i != client)
		{
			EmitSoundToClient(i, soundpath, client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		}
	}
}

void Event_BileStop(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client) return;
	if (GetClientTeam(client) != 3) return;
	if(GetEntProp(client, Prop_Send, "m_zombieClass") != 2) return;

	char soundpath[256];	
	switch(VomitSound)
	{
		case 1: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_01.wav");	}
		case 2: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_02.wav");	}
		case 3: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_03.wav");	}
		case 4: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_04.wav");	}
		case 5: {	strcopy(soundpath, 256, "player/Boomer/vomit/Boomer_Vomit_09.wav");	}
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			StopSound(i, SNDCHAN_AUTO, soundpath);
		}
	}
}
