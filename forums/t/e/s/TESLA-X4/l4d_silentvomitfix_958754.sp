#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define DEBUG 0

#define PLUGIN_VERSION "1.0.0"

new const String:pukeSounds[][] = {"player/Boomer/vomit/Boomer_Vomit_01.wav", "player/Boomer/vomit/Boomer_Vomit_02.wav", "player/Boomer/vomit/Boomer_Vomit_03.wav", "player/Boomer/vomit/Boomer_Vomit_04.wav", "player/Boomer/vomit/Boomer_Vomit_09.wav"};

public Plugin:myinfo = 
{
	name = "L4D Silent Vomit Fix",
	author = "AtomicStryker",
	description = "Hear Boomers Vomit, finally",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=956475"
};

public OnPluginStart()
{
	CreateConVar("l4d_silentvomitfix_version", PLUGIN_VERSION, "Version of L4D Silent Vomit Fix on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// Not really necessary to hook in Pre mode - we aren't changing anything
	HookEvent("ability_use", Event_Ability);
}

public OnMapStart()
{
	for (new i = 0; i < sizeof(pukeSounds); i++)
	{
		PrecacheSound(pukeSounds[i], true);
	}
}

public Event_Ability(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return; //disregard 0 clients.
	
	decl String:ability[24];
	GetEventString(event, "ability", ability, 24);
	if (strcmp(ability, "ability_vomit", false)) return; //unless its Boomer Vomit i dont bother
	
	#if DEBUG
	PrintToChatAll("Biling Boomer caught: %N , id: %i", client, client);
	#endif
	
	// This line should stay outside the loop to make all clients (sans the boomer) hear the same sound
	new luckynumber = GetRandomInt(0, (sizeof(pukeSounds) - 1));
	for (new i = 1; i <= MaxClients; i++)
	{
		// If it's not the boomer himself, emit the sound to the client (it will appear to come from the boomer)
		if (IsClientInGame(i) && i != client)
			EmitSoundToClient(i, pukeSounds[luckynumber], client, SNDCHAN_STATIC, SNDLEVEL_GUNFIRE);
	}
}
