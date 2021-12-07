#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.5.2"

//use QueryClientConVar somehow?

public Plugin:myinfo = 
{
	name = "No Spam",
	author = "DarthNinja",
	description = "Prevents a specified client from using HLDJ/HLSS",
	version = PLUGIN_VERSION,
	url = "AlliedMods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_nospam_version", PLUGIN_VERSION, "Nospam Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegAdminCmd("sm_nospam_on", Command_NospamON, ADMFLAG_GENERIC, "Usage: sm_nospam_on <Username/#ID>");
	RegAdminCmd("sm_nospam_off", Command_NospamOFF, ADMFLAG_GENERIC, "Usage: sm_nospam_off <Username/#ID>");
}
	
public Action:Command_NospamON(client, args)
{
	new String:target[32];
	GetCmdArg(1, target, sizeof(target));
	new i = FindTarget(client, target);
	SendConVarValue(i, FindConVar("sv_allow_voice_from_file"), "0");
	//Log
	LogAction(client, i, "\"%L\" enabled nospam on \"%L\"", client, i);
	//Reply to user
	PrintToChat(client,"[SM] Now preventing %N from using HLDJ/HLSS.", i);
	//new ismuted = 1
}
	
public Action:Command_NospamOFF(client, args)
{
	new String:target[32];
	GetCmdArg(1, target, sizeof(target));
	new i = FindTarget(client, target);
	SendConVarValue(i, FindConVar("sv_allow_voice_from_file"), "1");
	//Log
	LogAction(client, i, "\"%L\" disabled nospam on \"%L\"", client, i);
	//Reply to user
	PrintToChat(client,"[SM] Now allowing %N to use HLDJ/HLSS.", i);
}

