#include <sourcemod>

#define PLUGIN_VERSION	"1.0"

new Handle:h_Enable = INVALID_HANDLE;
new Handle:h_Message = INVALID_HANDLE;


public Plugin:myinfo = 
{
	name = "Welcome Player Message // WPM",
	author = "RaT3D - Martin J.Berthelsen",
	description = "A simple plugin, which welcomes a player to your server with a custom message.",
	version = PLUGIN_VERSION,
	url = "http://royalgaming.net23.net"
}

public OnPluginStart()
{
	CreateConVar("sm_wpm_version", PLUGIN_VERSION, "WPM plugin version" , FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_Enable = CreateConVar("sm_wpm", "1", "Enables WPM plugin when client join server. 1 = Enabled, 0 = Disabled.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_Message = CreateConVar("sm_wpm_message", "NONE", "Set a message for client join.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "wpmConfig.cfg");
}

public OnClientPutInServer(client)
{
	new IsEnabled = GetConVarInt(h_Enable);
	if(IsEnabled == 1)
	{
		new String:SMsg[99];
		GetConVarString(h_Message, SMsg, sizeof (SMsg));
		
		if(StrEqual(SMsg, "NONE") || StrEqual(SMsg, ""))
		{
			PrintToServer("[WPM] Join message not found!")
		} else{
			for(new i = 1;i < GetMaxClients();i++)
			{
				if(IsClientInGame(i) && IsClientConnected(i))
				{
					PrintToChat(client, "\x04[WPM]\x03 %s", SMsg)
				}
			}
		}
	}
}