#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"

/*CoMmAnDs*/
// !donate - displays donate panel
// !apply - displays apply panel

/*CvArs*/
// sm_donate_href - link to donate link
// sm_apply_href - link to apply link
// donate_version - version of the plugin

public Plugin:myinfo = 
{
	name = "Clan Donations",
	author = "{7~11} TROLL",
	description = "Donate Plugin Requested By Cook1eMan",
	version = PLUGIN_VERSION,
	url = "www.SimpleSourceModz.com"
}
/*Handles*/
//donate handle
new Handle:g_donate = INVALID_HANDLE;
//apply handle
new Handle:g_apply = INVALID_HANDLE;


public OnPluginStart()
{
	//donate command
	RegConsoleCmd("donate", DonateOn);
	//apply command
	RegConsoleCmd("apply" , ApplyOn);
	//donate motd panel
	g_donate = CreateConVar("sm_donate_href","www.simplesourcemodz.com","link to donate panel");
	//apply motd panel
	g_apply = CreateConVar("sm_apply_href","www.simplesourcemodz.com","link to apply pane;");
	//version cvar
	CreateConVar("donate_version", PLUGIN_VERSION, "donate_version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public Action:DonateOn(client,args)
{
	decl String:href[255];
	GetConVarString(g_donate, href, sizeof(href));
	ShowMOTDPanel(client, "Donations", href, MOTDPANEL_TYPE_URL);
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		ReplyToCommand(client, "[Clan Donations] You Are Now Viewing Donations Page");
	}
	return Plugin_Continue;
}
public Action:ApplyOn(client,args)
{
	decl String:href[255];
	GetConVarString(g_apply, href, sizeof(href));
	ShowMOTDPanel(client, "Apply", href, MOTDPANEL_TYPE_URL);
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		ReplyToCommand(client, "[Clan Donations] You Are Now Viewing Apply Page");
	}
	return Plugin_Continue;
}