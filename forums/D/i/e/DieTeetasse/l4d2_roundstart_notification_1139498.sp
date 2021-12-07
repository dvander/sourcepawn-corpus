#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

new bool:isFirst = true;
new Handle:cvar_msg;
new Handle:cvar_msg_type;
new Handle:cvar_soundfile;
new String:soundfilepath[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	cvar_msg = CreateConVar("l4d2_roundstart_message", "!ROUND START!", "Round start message (empty to disable)", CVAR_FLAGS);
	cvar_msg_type = CreateConVar("l4d2_roundstart_message_type", "0", "Round start message type: 0 = chat, else = hint", CVAR_FLAGS);
	cvar_soundfile = CreateConVar("l4d2_roundstart_soundfile", "./ambient/random_amb_sfx/foghorn_close.wav", "Round start sound file (empty to disable)", CVAR_FLAGS);
	
	HookEvent("round_start", Round_Start);
	HookEvent("player_left_start_area", Player_Left);
}

public OnMapStart()
{
	//get string
	GetConVarString(cvar_soundfile, soundfilepath, sizeof(soundfilepath));

	//trim string
	TrimString(soundfilepath);
	
	//is string empty?
	if (strlen(soundfilepath) == 0) soundfilepath = "";
	//building sound path
	else
	{
		PrintToServer("Soundfile: %s", soundfilepath);
	
		//precatching sound
		PrefetchSound(soundfilepath);
		PrecacheSound(soundfilepath);
	}
}

public Action:Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	isFirst = true;
}

public Action:Player_Left(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isFirst && strlen(soundfilepath) > 0)
	{
		EmitSoundToAll(soundfilepath, GetClientOfUserId(GetEventInt(event, "userid"))); 
		
		decl String:str[256];
		GetConVarString(cvar_msg, str, sizeof(str));
		
		if (GetConVarInt(cvar_msg_type) == 0) PrintToChatAll(str);
		else PrintHintTextToAll(str);
	}
	isFirst = false;
}