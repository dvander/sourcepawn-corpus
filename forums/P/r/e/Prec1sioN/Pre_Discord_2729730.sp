#include <sourcemod>
#include <multicolors>


/* Default Define */
#define PLUGIN_VERSION "0.1"


/* Plugin Details */
public Plugin myinfo =
{
	name = "Pre",
	author = "Prec1sioN",
	description = "Prec1sioN#0001",
	version = PLUGIN_VERSION,
	url = "https://desolate.vip/"
};

public void OnPluginStart()
{
	CreateConVar("pre_discord_version", PLUGIN_VERSION, "Prec1sioNs Discord Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	LoadTranslations("discord.phrases");
	RegConsoleCmd("discord", Prec1Plugin);
	RegConsoleCmd("dc", Prec1Plugin);
	RegConsoleCmd("sm_discord", Prec1Plugin);
	RegConsoleCmd("sm_dc", Prec1Plugin);
	RegConsoleCmd("pre_discord", Prec1Plugin);
	RegConsoleCmd("sm_pre_discord", Prec1Plugin);
}

public Action Prec1Plugin(int client, int args)
{

	CPrintToChat(client, "%t", "Discord");
	
	return Plugin_Handled;

}