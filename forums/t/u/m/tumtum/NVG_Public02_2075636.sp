#pragma semicolon 1
#include <sdktools>
#include <sdktools_sound>
#define VERSION "0.2"
#define AUTHOR "TummieTum (TumTum)"
#define MAX_FILE_LEN 80

// CVAR Handles
new Handle:cvarnven = INVALID_HANDLE;
new Handle:cvarnvspawn = INVALID_HANDLE;
new Handle:cvarnvonoff = INVALID_HANDLE;
new Handle:cvarnvsoundnameon = INVALID_HANDLE;
new String:g_soundNameOn[MAX_FILE_LEN];

// Basic Information (Do not change it)
public Plugin:myinfo =
{
	name = "Night Vision Goggles",
	author = AUTHOR,
	description = "CS:GO Night Vision",
	version = VERSION,
	url = "https://www.team-secretforce.com"
};

// Command
public OnPluginStart()
{
	// Default
	RegConsoleCmd("sm_nvg", Command_nightvision);
	
	// Events
	HookEvent("player_spawn", PlayerSpawn);
	
	//Cvars
	cvarnvspawn = CreateConVar("nv_spawnmsg", "1", "Enable or Disable Spawnmessages");
	cvarnvonoff = CreateConVar("nv_onoff", "1", "Disable Enable / Disable Messages");
	cvarnven = CreateConVar("nv_command", "1", "Enable or Disable !NVG");
	cvarnvsoundnameon = CreateConVar("nv_sound", "music/nightvision/nvon.mp3", "Turn on sound");
	
	// Version
	CreateConVar("sm_nightvision_version", VERSION, "Plugin info", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	//Generate
	AutoExecConfig(true, "Night_Vision_TummieTum");
	 	
}

public OnConfigsExecuted()
{
	// Get Convars
	GetConVarString(cvarnvsoundnameon, g_soundNameOn, MAX_FILE_LEN);
	// Buffer
	decl String:bufferOn[MAX_FILE_LEN];
	// Precache Sounds
	PrecacheSound(g_soundNameOn, true);
	// Format
	Format(bufferOn, sizeof(bufferOn),"sound/%s", g_soundNameOn);
	// Add to Downloadstable
	AddFileToDownloadsTable(bufferOn); 
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Get Client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(client) == 1 && !IsPlayerAlive(client))
	{
	return;
	}
	
	// Check Convar & Spawnmsg
	if (GetConVarInt(cvarnvspawn) == 1)
	{	
		PrintToChat(client,"[Night Vision] Type \x03!nvg \x01to enable NV.");
	}
	
}

// Enable
public Action:Command_nightvision(client, args)
{
 	if (GetConVarInt(cvarnven) == 1)
	{
		if (IsPlayerAlive(client)) 
    	{
			if(GetEntProp(client, Prop_Send, "m_bNightVisionOn") == 0)
			{
    			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
    			if (GetConVarInt(cvarnvonoff) == 1)
    			{
    			PrintToChat(client,"[Night Vision] \x03NV is Enabled!");
    			}
    			EmitSoundToClient(client,g_soundNameOn);
				}
			else
			{
    			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
    			if (GetConVarInt(cvarnvonoff) == 1)
    			{
    			PrintToChat(client,"[Night Vision] \x03NV is Disabled!");
    			}
    		}
    	}
	}
	return Plugin_Handled;
}