#pragma semicolon 1

#define MOTD_TITLE "Message Of The Day"
#define PLUGIN_VERSION "1.00"


#include <sourcemod>

new Handle:cvForced = INVALID_HANDLE;
new Handle:cvImmunity = INVALID_HANDLE;
new Handle:cvMotdUrl = INVALID_HANDLE;

new iVGUIForcing[MAXPLAYERS + 1] = { 0, ... };
new iVGUICaught[MAXPLAYERS + 1] = { 0, ... };

public Plugin:myinfo = 
{
	name = "MOTD FORCE",
	author = "MOTDgd",
	description = "Intercepts the MOTD and forces it to remain open",
	version = PLUGIN_VERSION,
	url = "http://motdgd.com"
};

public OnPluginStart()
{
	// Initialize our ConVars
	cvMotdUrl = CreateConVar("sm_motdgd_url", "javascript:void(0);", "Use motd.txt or motd_text.txt for your contents");
	cvForced = CreateConVar("sm_motdforce_forced", "1", "Whether eligible players are forced to see MOTD for up to 10 seconds");
	cvImmunity = CreateConVar("sm_motdforce_immunity", "0", "Whether ADMIN_RESERVATION players are immune to MOTD forcing");
	AutoExecConfig(true);
	
	CreateConVar("sm_motdforce_version", PLUGIN_VERSION, "MOTD FORCE Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// Intercept the MOTD window and show our ad instead
	new UserMsg:umVGUIMenu = GetUserMessageId("VGUIMenu");
	if (umVGUIMenu == INVALID_MESSAGE_ID)
		SetFailState("This game doesn't support VGUI menus.");
	HookUserMessage(umVGUIMenu, Hook_VGUIMenu, true);
	AddCommandListener(ClosedHTMLPage, "closed_htmlpage");
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	iVGUICaught[client] = 0;
	iVGUIForcing[client] = 0;
	
	return true;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GetUserMessageType");
}

public Action:Hook_VGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client = players[0];
	if(playersNum > 1 || !client || !IsClientInGame(client))
		return Plugin_Continue;
	
	// Skip if the player's MOTD has been intercepted
	if (iVGUICaught[client] > 0)
		return Plugin_Continue;
	
	decl String:sName[64];
	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
		PbReadString(bf, sName, "name", sizeof(sName));
	else
		BfReadString(bf, sName, sizeof(sName));

	if (strcmp(sName, "info") != 0)
		return Plugin_Continue;
	
	// Don't repeat the interception more than once
	iVGUICaught[client] = 1;
	
	// If the player has ADMIN_RESERVATION and immunity cvar is set to 1 then don't show them MOTDgd
	if (!CanViewMOTDgd(client) && GetConVarInt(cvImmunity) == 1)
		return Plugin_Continue;
	
	// Display MOTDgd
	CreateTimer(0.1, NewMOTD, client);

	return Plugin_Handled;
}

public Action:ClosedHTMLPage(client, const String:command[], argc)
{
	if (client && IsClientInGame(client))
	{
		if (GetConVarInt(cvForced) == 0 && !IsValidTeam(client))
		{
			// To ensure player can choose a team after closing the MOTD
			FakeClientCommand(client, "joingame");
		}
		else if (GetConVarInt(cvForced) == 1 && !IsValidTeam(client) && iVGUIForcing[client] == 1)
		{
			// Display MOTDgd
			CreateTimer(0.1, ReOpenMOTD, client);
		}
		else if (GetConVarInt(cvForced) == 1 && !IsValidTeam(client) && iVGUIForcing[client] == 0)
		{
			// To ensure player can choose a team after closing the MOTD
			FakeClientCommand(client, "joingame");
		}
	}
	
	return Plugin_Continue;
}

public Action:NewMOTD(Handle:timer, any:client)
{
	decl String:sURL[192];
	GetConVarString(cvMotdUrl, sURL, sizeof(sURL));
	SendMOTD(client, MOTD_TITLE, sURL);
	if (GetConVarInt(cvForced) == 1 && iVGUIForcing[client] == 0)
	{
		// If the player must be forced to see MOTDgd for a short duration
		iVGUIForcing[client] = 1;
		CreateTimer(10.0, UnlockMOTD, client);
	}
}

public Action:ReOpenMOTD(Handle:timer, any:client)
{
	SendVoidMOTD(client, MOTD_TITLE, "javascript:void(0);");
}

public Action:UnlockMOTD(Handle:timer, any:client)
{
	iVGUIForcing[client] = 0;
}

stock SendMOTD(client, const String:title[], const String:url[], bool:show=true)
{
	if (client && IsClientInGame(client))
	{
		new Handle:kv = CreateKeyValues("data");
		KvSetNum(kv, "cmd", 5);
		
		KvSetString(kv, "msg", url);
		KvSetString(kv, "title", title);
		KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);
		
		ShowVGUIPanel(client, "info", kv, show);
		CloseHandle(kv);
	}
}

stock SendVoidMOTD(client, const String:title[], const String:url[], bool:show=true)
{
	if (client && IsClientInGame(client))
	{
		new Handle:kv = CreateKeyValues("data");
		KvSetNum(kv, "cmd", 5);
		
		decl String:sURL[128];
		Format(sURL, sizeof(sURL), "%s", url);
		
		KvSetString(kv, "msg", sURL);
		KvSetString(kv, "title", title);
		KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);
		
		ShowVGUIPanel(client, "info", kv, show);
		CloseHandle(kv);
	}
}

bool:IsValidTeam(client)
{
	return (GetClientTeam(client) != 0);
}

stock bool:CanViewMOTDgd( client )
{
	new AdminId:aId = GetUserAdmin( client );
	
	if ( aId == INVALID_ADMIN_ID )
		return true;
	
	if ( GetAdminFlag( aId, Admin_Reservation ) )
		return false;
		
	return true;
}
