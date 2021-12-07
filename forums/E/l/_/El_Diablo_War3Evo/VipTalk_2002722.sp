/*
*
* Part of the Credit should go to Ratty of http://www.nom-nom-nom.us
* for creating Team Talk while having All Talk.
* 
* The problem I came across was his program was outdated using
* SetClientListening(i,client,true); and it just didn't work.
* 
* So I've revised it and made it useable again.
* 
* Only been tested in TF2, but should work for all games.
*/



#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.0.0.0"

public Plugin:myinfo =
{
	name = "Vip Talk",
	author = "El Diablo",
	description = "Vip Talk, Team Talk, and Admin Over-Ride Talk.",
	version = PLUGIN_VERSION,
	url = "http://www.war3evo.info"
}

public OnPluginStart()
{
	CreateConVar("w3e_viptalk",PLUGIN_VERSION,"W3E VipTalk",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);

	RegConsoleCmd("+teamtalk", teamtalkon,	"use in conjunction with +voicerecord", FCVAR_GAMEDLL);
	RegConsoleCmd("-teamtalk", teamtalkoff, "use in conjunction with +voicerecord", FCVAR_GAMEDLL);
	RegConsoleCmd("+viptalk", viptalkon,	"use in conjunction with +voicerecord", FCVAR_GAMEDLL);
	RegConsoleCmd("-viptalk", viptalkoff, "use in conjunction with +voicerecord", FCVAR_GAMEDLL);
	RegConsoleCmd("+admintalk", admintalkon,	"use in conjunction with +voicerecord", FCVAR_GAMEDLL);
	RegConsoleCmd("-admintalk", admintalkoff, "use in conjunction with +voicerecord", FCVAR_GAMEDLL);
}

public OnMapStart()
{
	PrecacheSound("buttons/button9.wav");
	PrecacheSound("buttons/button19.wav");
}

public Action:admintalkon(client, args) {
	if(GetAdminFlag(GetUserAdmin(client), Admin_Ban))
	{
		for (new i = 1; i <= GetMaxClients(); i++) {
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && !GetAdminFlag(GetUserAdmin(i), Admin_Ban))
			{
				SetClientListeningFlags(i,VOICE_MUTED);
				EmitSoundToClient(i,"buttons/button9.wav");
				EmitSoundToClient(i,"buttons/button9.wav");
			}
		}
		EmitSoundToClient(client,"buttons/button9.wav");
	}
	return Plugin_Handled;
}

public Action:admintalkoff(client, args) {
	if(GetAdminFlag(GetUserAdmin(client), Admin_Ban))
	{
		for (new i = 1; i <= GetMaxClients(); i++) {
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
				SetClientListeningFlags(i,VOICE_NORMAL);
				EmitSoundToClient(i,"buttons/button19.wav");
				EmitSoundToClient(i,"buttons/button19.wav");
			}
		}
		EmitSoundToClient(client,"buttons/button19.wav");
	}
	return Plugin_Handled;
}



public Action:viptalkon(client, args) {
	if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
	{
		for (new i = 1; i <= GetMaxClients(); i++) {
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && !GetAdminFlag(GetUserAdmin(i), Admin_Reservation))
			{
				SetListenOverride(i,client,Listen_No);
			}
			else if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetAdminFlag(GetUserAdmin(i), Admin_Reservation))
			{
				EmitSoundToClient(i,"buttons/button9.wav");
				EmitSoundToClient(i,"buttons/button9.wav");
			}
		}
		EmitSoundToClient(client,"buttons/button9.wav");
	}
	return Plugin_Handled;
}

public Action:viptalkoff(client, args) {
	if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
	{
		for (new i = 1; i <= GetMaxClients(); i++) {
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
				SetListenOverride(i,client,Listen_Yes);
			}
			else if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetAdminFlag(GetUserAdmin(i), Admin_Reservation))
			{
				EmitSoundToClient(i,"buttons/button19.wav");
				EmitSoundToClient(i,"buttons/button19.wav");
			}
		}
		EmitSoundToClient(client,"buttons/button19.wav");
	}
	return Plugin_Handled;
}


public Action:teamtalkon(client, args) {
	new myteam = GetClientTeam(client);

	switch (myteam) {
		case 2:
			DoTeamTalk(client,3);
		case 3:
			DoTeamTalk(client,2);
		default:
			PrintToChat(client, "You must be on a team to use team chat. Spectators hear and talk to everybody.");
	}

	return Plugin_Handled;
}

DoTeamTalk(client,team){
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			SetListenOverride(i,client,Listen_No);
		}
	}
	EmitSoundToClient(client,"buttons/button9.wav");
}

public Action:teamtalkoff(client, args) {
	for (new i = 1; i <= GetMaxClients(); i++) {
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			SetListenOverride(i,client,Listen_Yes);
		}
	}
	EmitSoundToClient(client,"buttons/button19.wav");
	return Plugin_Handled;
}
