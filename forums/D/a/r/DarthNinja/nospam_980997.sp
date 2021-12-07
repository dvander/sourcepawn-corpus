#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0.1.0"

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
	RegAdminCmd("sm_nospam", Command_Nospam, ADMFLAG_CHAT, "Usage: sm_nospam <Username/#ID> <1/0>");
}
	
public Action:Command_Nospam(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_nospam <Username/#ID> <1/0>");
		return Plugin_Handled;
	}
	
	new String:tog[32];
	new String:target[32];
	GetCmdArg(2, tog, sizeof(tog));
	GetCmdArg(1, target, sizeof(target));
	new i = FindTarget(client, target);
	new toggle = StringToInt(tog)
	
	if (toggle == 1)
		{
			SendConVarValue(i, FindConVar("sv_allow_voice_from_file"), "0");
			//Log
			LogAction(client, i, "\"%L\" enabled nospam on \"%L\"", client, i);		
			//Reply to user
			ShowActivity2(client, "[SM] ","Now preventing %N from using HLDJ/HLSS.", i);
			return Plugin_Handled;
		}
	else if (toggle == 0)
		{
			SendConVarValue(i, FindConVar("sv_allow_voice_from_file"), "1");
			//Log
			LogAction(client, i, "\"%L\" disabled nospam on \"%L\"", client, i);
			//Reply to user
			ShowActivity2(client, "[SM] ","Now allowing %N to use use HLDJ/HLSS.", i);
			return Plugin_Handled;
		}	
	else
		{
			PrintToChat(client,"Invalid toggle");
			return Plugin_Handled;
		}

}

