#pragma semicolon 1

#include <sourcemod>
#define PLUGIN_VERSION "1.2.1"

new Handle:g_mode = INVALID_HANDLE;
new Handle:DonateURL;

public Plugin:myinfo =
{
	name = "Donate",
	author = "FreakyLike & Maxximou5",
	description = "CS:GO - Simple plugin that allows players to donate ingame via PayPal.",
	version = PLUGIN_VERSION,
	url = "http://fragworks.net"
};

public OnPluginStart()
{
	g_mode = CreateConVar("sm_donate_command", "donate", "Donate Command \nChoose your command for the donations here.");
	DonateURL = CreateConVar("sm_donate_url","http://yourdomain.com/donate.html","Set this to the URL of your routing donate.");
	CreateConVar("sm_donate_version", PLUGIN_VERSION, "Donations Version - don't change this!", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "plugin.donate");
	
	new String:Command[32];
	new String:buffer[32];
	GetConVarString(g_mode, Command, sizeof(Command));
	Format(buffer, sizeof(buffer), "sm_%s", Command);
	RegConsoleCmd(buffer, command_donate, "Donate URL");
}

public Action:donate(i, args)
{
	new String:MOTDURL[128];
	GetConVarString(DonateURL, MOTDURL, sizeof(MOTDURL));
	
	ShowMOTDPanel(i, "Donate", MOTDURL, MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}

public Action:command_donate(i, args)
{
	if (i > 0 && i < MaxClients && IsClientConnected(i) && IsClientInGame(i))
	{
		if(args == 1)
		{
			new String:MOTDURL[128];
			GetConVarString(DonateURL, MOTDURL, sizeof(MOTDURL));
			ShowMOTDPanel(i, "PayPal Donation", MOTDURL, MOTDPANEL_TYPE_URL);
		}
		else
		{
			new String:Command[32];
			GetConVarString(g_mode, Command, sizeof(Command));
			PrintToChat(i, "\x01Usage: !%s <amount>",Command);
			PrintToConsole(i,"Usage: sm_%s <amount>",Command);
		}
	}
	return Plugin_Handled;
}