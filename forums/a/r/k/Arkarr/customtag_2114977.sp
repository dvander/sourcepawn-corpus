#include <sourcemod>
#include <scp>
#include <morecolors>
#include <clientprefs>

new String:player_tag[MAXPLAYERS+1][200];
new bool:player_havetag[MAXPLAYERS+1] = false;

new Handle:Cookie_PlayerTag;
new Handle:Cvar_maxtaglength;

public Plugin:myinfo = 
{
	name = "Custom Tag",
	author = "Arkarr",
	description = "Allow you to create a simple custom tag.",
	version = "1.0",
	url = "forums.alliedmodders.com"
}

public OnPluginStart()
{	
	RegConsoleCmd("sm_customtag", CMD_SetCustomTag, "Set custom tag on your self.");
	RegConsoleCmd("sm_removetag", CMD_RemoveCustomTag, "Set custom tag on your self.");
	
	Cvar_maxtaglength = CreateConVar("sm_customtag_length", "10", "Maxium length of tag. Warning, player who already have tag and is higer then this value, won't be affected.");
	
	Cookie_PlayerTag = RegClientCookie("CustomTag_ptag", "Store the player tag.", CookieAccess_Protected);
	
	for (new i = MaxClients; i > 0; --i)
    {
		if(IsValidClient(i))
		{
			if (!AreClientCookiesCached(i))
			{
				continue;
			}
			OnClientCookiesCached(i);
		}
    }
}

public OnClientCookiesCached(client)
{
	GetClientCookie(client, Cookie_PlayerTag, player_tag[client], 200);
	if(strlen(player_tag[client]) > 0 && !StrEqual(player_tag[client],"%REMOVED%",true))
	{
		player_havetag[client] = true;
	}
}

public OnClientDisconnect(client)
{
	if(player_havetag[client])
	{
		SetClientCookie(client, Cookie_PlayerTag, player_tag[client]);
		player_havetag[client] = false;
	}
}

public Action:CMD_SetCustomTag(client, args)
{
	if(args < 1)
	{
		CPrintToChat(client, "{green}[Custom Tag]{default} Usage : sm_customtag [MY TAG NAME]");
		return Plugin_Handled;
	}
	
	new String:tag[900];
	
	GetCmdArgString(tag, sizeof(tag));
	
	if(strlen(tag) > GetConVarInt(Cvar_maxtaglength))
	{
		CPrintToChat(client, "{green}[Custom Tag]{default} Your tag length can't be higer then %i !", GetConVarInt(Cvar_maxtaglength));
		return Plugin_Handled;
	}
	
	if(StrEqual(tag, "%REMOVED%", true))
	{
		CPrintToChat(client, "{green}[Custom Tag]{default} This tag is reserved. Choose another one !");
		return Plugin_Handled;
	}
	
	Format(player_tag[client], 200, "%s", tag);
	
	CPrintToChat(client, "{green}[Custom Tag]{default} Tag set ! Use sm_removetag to remove your tag !");
	
	player_havetag[client] = true;
	
	return Plugin_Handled;
}

public Action:CMD_RemoveCustomTag(client, args)
{
	player_havetag[client] = false;
	SetClientCookie(client, Cookie_PlayerTag, "%REMOVED%");
	CPrintToChat(client, "{green}[Custom Tag]{default} Tag removed ! Use sm_customtag to set your tag !");
	
	return Plugin_Handled;
}

public Action:OnChatMessage(&author, Handle:recepients, String:name[], String:message[]) 
{
	if (author > 0 && IsClientInGame(author))
	{
		if(player_havetag[author])
		{
			Format(name, MAXLENGTH_INPUT, "[%s] %s", player_tag[author], name);
		}
		
		return Plugin_Changed;
	}
	return Plugin_Handled;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}