#include <sourcemod>
#include <morecolors>

#define PREFIX "Docteur Love"

new Handle:g_hCvar = INVALID_HANDLE;
new String:g_sLove[64];
new bool:g_bBusy = false;

public Plugin:myinfo = 
{
	name = "Doctor Love",
	author = "Kriax",
	version = "1.2",
};

public OnPluginStart()
{
	RegConsoleCmd("sm_love", CMD_Love);
	
	g_hCvar = CreateConVar("time_compute", "10.0", "Time to compute");
	AutoExecConfig(true);
}

public Action:CMD_Love(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Use : /love <name>");
		return Plugin_Handled;
	}
	if(g_bBusy)
	{
		CPrintToChat(client, "{deeppink}%s : I'm already busy !", PREFIX);
		return Plugin_Handled;
	}
	
	GetCmdArgString(g_sLove, sizeof(g_sLove));
	
	g_bBusy = true;
	
	CPrintToChatAll("{deeppink}%s calculates the level of love between {hotpink}%N and %s {deeppink}...", PREFIX, client, g_sLove);
	CreateTimer(GetConVarFloat(g_hCvar), Timer_Love, client);
	
	return Plugin_Handled;
}

public Action:Timer_Love(Handle:timer, any:client)
{
	CPrintToChatAll("{deeppink}%s : The level of love between {hotpink}%N and %s {deeppink}is {hotpink}%i%", PREFIX, client, g_sLove, GetRandomInt(0, 100));
	
	g_bBusy = false;
}