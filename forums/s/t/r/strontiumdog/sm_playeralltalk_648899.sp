// Developed by <eVa>Dog
// July 2008
// http://www.theville.org
//
// DESCRIPTION:
// This plugin lets players talk to the other side even if all talk is not on
//
// CHANGELOG:
// - 7.5.2008 Version 1.0.100
//   Initial Release'
// - 7.25.2008 Version 1.0.101
//   Add cvar to remove messages
// - 8.25.2008 Version 1.0.102
//   Add cvar to define default status (courtesy of RM Hamster)

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.0.102"
#define SPEAK_NORMAL		0
#define SPEAK_ALL		2

new Handle:Cvar_Perms = INVALID_HANDLE
new Handle:Cvar_Msgs = INVALID_HANDLE
new Handle:Cvar_Def = INVALID_HANDLE

new g_PlayerAllTalk[65]

new lines = 0
new String:permitted[65]

public Plugin:myinfo = 
{
	name = "Player All-Talk",
	author = "<eVa>StrontiumDog",
	description = "Lets players talk to the other side even if all talk is not on",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_playeralltalk_version", PLUGIN_VERSION, "Player AllTalk Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	Cvar_Perms = CreateConVar("sm_alltalk_tags", "0", "When enabled, only certain clan tags can use server all talk", FCVAR_PLUGIN)
	Cvar_Msgs = CreateConVar("sm_alltalk_messages", "1", " 0 - disables messages, 1 - chat text message", FCVAR_PLUGIN)
	Cvar_Def = CreateConVar("sm_alltalk_default", "0", "Sets whether the default for the client is teamtalk or alltalk.", FCVAR_PLUGIN)
	RegConsoleCmd("voiceall", admin_talktoserver, " - Lets players talk to the other side even if all talk is not on")
}

public OnMapStart()
{
	for(new i = 0; i < lines; i++)
	{
		strcopy(permitted[i], sizeof(permitted[]), "")
	}
	lines = 0
	ReadConfig()
}

public OnClientPutInServer(client)
{
	if ((GetConVarInt(Cvar_Def) && GetConVarInt(Cvar_Perms) && CheckName(client)) || (GetConVarInt(Cvar_Def) && !GetConVarInt(Cvar_Perms)))
	{
		g_PlayerAllTalk[client] = 1
		SetClientListeningFlags(client, SPEAK_ALL)
	}
}

public Action:admin_talktoserver(client, args)
{	
	if ((GetConVarInt(Cvar_Perms) && CheckName(client)) || !GetConVarInt(Cvar_Perms))
	if(g_PlayerAllTalk[client] == 1)
	{
		g_PlayerAllTalk[client] = 0
		SetClientListeningFlags(client, SPEAK_NORMAL)
		if (GetConVarInt(Cvar_Msgs) == 1)
		{
			PrintToChat(client,"\x01\x04[SM] Talking to the server disabled.")
		}
		return Plugin_Handled
	}
	else if(g_PlayerAllTalk[client] == 0)
	{
		g_PlayerAllTalk[client] = 1
		SetClientListeningFlags(client, SPEAK_ALL)
		if (GetConVarInt(Cvar_Msgs) == 1)
		{
			PrintToChat(client,"\x01\x04[SM] Talking to the server enabled.")
		}
		return Plugin_Handled
	}
	return Plugin_Continue
}

public bool:CheckName(client)
{
	for (new i = 0; i < lines; i++)
	{
		new String:clientName[64]
		GetClientName(client,clientName,64)
		if(StrContains(clientName, permitted[i], false) != -1)
		{
			return true
		}	
	}
	return false
}

public bool:ReadConfig()
{
	new String:fileName[128]
	
	BuildPath(Path_SM, fileName, sizeof(fileName), "configs/sm_playeralltalk_data.txt")
	new Handle:file = OpenFile(fileName, "rt")
	if (file == INVALID_HANDLE)
	{
		LogError("Could not open config file: %s", fileName)
		return false
	}
	while (!IsEndOfFile(file))
	{
		decl String:line[64]
		if (!ReadFileLine(file, line, sizeof(line)))
		{
			break
		}
		TrimString(line)
		ReplaceString(line, 64, " ", "")
		if (strlen(line) == 0 || (line[0] == '/' && line[1] == '/'))
		{
			continue
		}
		strcopy(permitted[lines], sizeof(permitted[]), line)
		lines++
	}
	CloseHandle(file)
	return true
}
