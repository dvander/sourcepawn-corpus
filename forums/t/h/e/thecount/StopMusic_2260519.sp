#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME 	"Stop Map Music"
#define PLUGIN_VERSION 	"1.0.0"

#define MAX_EDICTS		2048

new Float:g_fCmdTime[MAXPLAYERS+1];
new g_iSoundEnts[MAX_EDICTS];
new g_iNumSounds;
new bool:disabled[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony [Fixed by The Count]",
	description = "Allows clients to stop ambient sounds played by the map",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_stopmusic_version", PLUGIN_VERSION, "Stop Map Music", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	RegConsoleCmd("sm_music", Command_StopMusic, "Toggles map music");
	
	CreateTimer(10.0, Post_Start, _, TIMER_REPEAT);
}

public OnClientDisconnect_Post(client)
{
	g_fCmdTime[client] = 0.0;
	disabled[client] = false;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Ents are recreated every round.
	g_iNumSounds = 0;
	
	// Find all ambient sounds played by the map.
	UpdateSounds();
	CreateTimer(0.8, Post_Start);
}

public OnEntityCreated(entity, const String:classname[]){
	if(!StrEqual(classname, "ambient_generic", false)){
		return;
	}
	new String:sSound[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));	
	new len = strlen(sSound);
	if (len > 4 && (StrEqual(sSound[len-3], "mp3") || StrEqual(sSound[len-3], "wav"))){
		g_iSoundEnts[g_iNumSounds++] = EntIndexToEntRef(entity);
	}else{
		return;
	}
	new ent = -1;
	for(new i=1;i<=MaxClients;i++){
		if(!disabled[i] || !IsClientInGame(i)){ continue; }
		for (new u=0; u<g_iNumSounds; u++){
			ent = EntRefToEntIndex(g_iSoundEnts[u]);
			if (ent != INVALID_ENT_REFERENCE){
				GetEntPropString(ent, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
				Client_StopSound(i, ent, SNDCHAN_STATIC, sSound);
			}
		}
	}
}

UpdateSounds(){
	new String:sSound[PLATFORM_MAX_PATH];
	new entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, "ambient_generic")) != INVALID_ENT_REFERENCE)
	{
		GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
		
		new len = strlen(sSound);
		if (len > 4 && (StrEqual(sSound[len-3], "mp3") || StrEqual(sSound[len-3], "wav")))
		{
			g_iSoundEnts[g_iNumSounds++] = EntIndexToEntRef(entity);
		}
	}
}

public Action:Post_Start(Handle:timer){
	if(GetClientCount() <= 0){
		return Plugin_Continue;
	}
	new String:sSound[PLATFORM_MAX_PATH];
	new entity = INVALID_ENT_REFERENCE;
	for(new i=1;i<=MaxClients;i++){
		if(!disabled[i] || !IsClientInGame(i)){ continue; }
		for (new u=0; u<g_iNumSounds; u++){
			entity = EntRefToEntIndex(g_iSoundEnts[u]);
			if (entity != INVALID_ENT_REFERENCE){
				GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
				Client_StopSound(i, entity, SNDCHAN_STATIC, sSound);
			}
		}
	}
	return Plugin_Continue;
}

public Action:Command_StopMusic(client, args)
{
	// Prevent this command from being spammed.
	if (!client || g_fCmdTime[client] > GetGameTime())
		return Plugin_Handled;
	
	if(disabled[client]){
		disabled[client] = false;
		PrintToChat(client, "[SM] Map music allowed.");
		return Plugin_Handled;
	}
	
	g_fCmdTime[client] = GetGameTime() + 5.0;
	
	PrintToChat(client, "[SM] Stopping map music...");
	
	// Run StopSound on all ambient sounds in the map.
	new String:sSound[PLATFORM_MAX_PATH], entity;
	
	for (new i = 0; i < g_iNumSounds; i++)
	{
		entity = EntRefToEntIndex(g_iSoundEnts[i]);
		
		if (entity != INVALID_ENT_REFERENCE)
		{
			GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
			Client_StopSound(client, entity, SNDCHAN_STATIC, sSound);
		}
	}
	disabled[client] = true;
	return Plugin_Handled;
}

/**
 * Stops a sound for one client.
 *
 * @param client	Client index.
 * @param entity	Entity index.
 * @param channel	Channel number.
 * @param name		Sound file name relative to the "sounds" folder.
 * @noreturn
 */
stock Client_StopSound(client, entity, channel, const String:name[])
{
	EmitSoundToClient(client, name, entity, channel, SNDLEVEL_NONE, SND_STOP, 0.0, SNDPITCH_NORMAL, _, _, _, true);
}
