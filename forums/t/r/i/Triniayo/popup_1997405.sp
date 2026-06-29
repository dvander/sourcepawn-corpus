#pragma semicolon 1

#include <sourcemod>
#define PLUGIN_VERSION "1.2"

new Handle:g_url = INVALID_HANDLE;
new Handle:g_mode = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "MOTD Popup",
	author = "FreakyLike & Tooti",
	description = "Simple plugin that popups a custom URL for a player.",
	version = PLUGIN_VERSION,
	url = "http://nastygaming.de & http://fractial-gaming.de"
};

public OnPluginStart()
{
	g_url = CreateConVar("sm_popup_url", "http://google.com", "Popup URL \nYou can put your URL that you want to let popup here.");
	g_mode = CreateConVar("sm_popup_command", "popup", "Popup Command \nYou can choose your own command for the Popup here.");
	CreateConVar("sm_popup_version", PLUGIN_VERSION, "MOTD Popup Version - don't change this!", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "plugin.popup");
	
	new String:Command[32];
	new String:buffer[32];
	GetConVarString(g_mode, Command, sizeof(Command));
	Format(buffer, sizeof(buffer), "sm_%s", Command);
	RegConsoleCmd(buffer, command_popup, "Popup URL");
}

public Action:command_popup(i, args)
{
	if (IsClientConnected(i) && IsClientAdmin(i) && !IsFakeClient(i))
	{
		if(GetCmdArgs() > 0 && GetCmdArgs() <= 2)
		{
			decl MaxPlayers, Player;
			decl String:PlayerName[32];
			decl String:Name[32];
			
			Player = -1;
			GetCmdArg(1, PlayerName, sizeof(PlayerName));
			MaxPlayers = GetMaxClients();
			for(new X = 1; X <= MaxPlayers; X++)
			{
				if(!IsClientConnected(X)) continue;
				GetClientName(X, Name, sizeof(Name));
				if(StrContains(Name, PlayerName, false) != -1) Player = X;
			}
			if(Player == -1)
			{
				PrintToConsole(i, "Could not find client \x04%s", PlayerName);
				return Plugin_Handled;
			}
			
			if(GetCmdArgs() == 2)
			{
				new String:custom_url[192];
				GetCmdArg(2, custom_url, sizeof(custom_url));
				ShowMOTDPanel(i, "Message Of The Day", custom_url, MOTDPANEL_TYPE_URL);
			}
			else
			{
				new String:motdurl[500];
				GetConVarString(g_url, motdurl, sizeof(motdurl));
				ShowMOTDPanel(Player, "Message Of The Day", motdurl, MOTDPANEL_TYPE_URL);
			}	
		}
		else
		{
					new String:Command[32];
					GetConVarString(g_mode, Command, sizeof(Command));
					PrintToChat(i, "\x01Usage: !%s <playername> <url (optional)>",Command);
					PrintToConsole(i,"Usage: sm_%s <playername> <url (optional)>",Command);
		}
	}
	else
	{
		PrintToChat(i, "\x01[SM] You do not have access to this command.");
	}	
	return Plugin_Handled;
}

stock bool:IsClientAdmin(a_id)
{
	new AdminId:adminId = GetUserAdmin(a_id);
	if(adminId != INVALID_ADMIN_ID && GetAdminFlag(adminId, Admin_Generic))
    {
		return true;
    }
	return false;
}