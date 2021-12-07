#include <sourcemod>
#include <colors>

#define Tag_Verison   "1.6"

new bool:ClientUseTag[MAXPLAYERS+1] = {false,...};

public OnPluginStart()
{
	RegAdminCmd("sm_tagon", tagon, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tagoff", tagoff, ADMFLAG_GENERIC);
	AddCommandListener(HookPlayerChat, "say");

	CreateConVar("sm_tag_version", Tag_Verison,  "Enable or disable the admin tag made by ZcaverZ", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN);
}

public Plugin:myinfo = {
	name = "Admin Tag",
	author = "ZcaverZ",
	description = "Admin kan välja om han vill ha tag eller inte",
	version = Tag_Verison,
	url = "ZcaverZ"
}

public OnClientPutInServer(client)
{
	ClientUseTag[client] = false;
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		ClientUseTag[client] = false;
	}
}

public Action:tagon(client, args)
{
	if (!ClientUseTag[client])
	{
		CPrintToChat(client, "{green}[Admin Tag]{default} You have now activated the tag");
		ClientUseTag[client] = true;
	}
}

public Action:tagoff(client, args)
{
	if (ClientUseTag[client])
	{
		CPrintToChat(client, "{green}[Admin Tag]{default} You have now disabled the tag");
		ClientUseTag[client] = false;
	}
}

public Action:HookPlayerChat(client, const String:command[], args)
{
	if (IsClientInGame(client) && ClientUseTag[client])
	{
		decl String:szText[256];
		szText[0] = '\0'; // <-- don't forget to clear the newly declared String so you don't end up with possible junk.
		GetCmdArg(1, szText, sizeof(szText));

		if (szText[0] != '/')
		{
			CPrintToChatAll("{red}[Admin] {green}%N:{default} %s",client, szText);
		}
		
		return Plugin_Handled; // <-- Block the normal text printing
	}
	return Plugin_Continue;
}