#pragma semicolon 1
#include <sourcemod>
#include <morecolors>


/* Default Define */
#define PLUGIN_VERSION "0.1"


/* Plugin Details */
public Plugin myinfo =
{
	name = "Hammer Drill Team Discord",
	author = "BASKIN",
	description = "Hammer Drill Team Discord",
	version = PLUGIN_VERSION,
	url = "185.126.177.130:27047"
};

public void OnPluginStart()
{
	CreateConVar("hdt_discord_version", PLUGIN_VERSION, "Hammer Drill Team Discord Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	LoadTranslations("discord.phrases");
	RegConsoleCmd("discord", HDTDiscord);
	RegConsoleCmd("dc", HDTDiscord);
	RegConsoleCmd("sm_discord", HDTDiscord);
	RegConsoleCmd("sm_dc", HDTDiscord);
	RegConsoleCmd("hdt_discord", HDTDiscord);
	RegConsoleCmd("sm_hdt_discord", HDTDiscord);
}

public Action HDTDiscord(int client, int args)
{

	CPrintToChatAll("%T", "Discord", client);
	
	return Plugin_Handled;

}