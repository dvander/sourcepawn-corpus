#pragma semicolon 1
#include <sourcemod>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Force Round End",
	author = "The.Hardstyle.Bro",
	description = "Go to the nextround",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
    	LoadTranslations("common.phrases");
	RegAdminCmd("sm_endround", Command_FRE, ADMFLAG_KICK, "Force Round End");

}
public Action:Command_FRE(client, args)
{
	CS_TerminateRound(3.0, CSRoundEnd_Draw);
	PrintToChatAll("[SM] ","%N has ended the round.", client);
	LogAction(client, -1, "\"%L\" triggered sm_endround", client);

	return Plugin_Handled;
}
