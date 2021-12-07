#pragma semicolon 1
#include <sourcemod>

/* Defines */
#define PLUGIN_VERSION			"1.5b"
#define PLUGIN_DESCRIPTION		"<Seta00> trie harder"

#define fClearTrieTime			12.4
#define iConnectionBanCount		6
#define iIPLength				17

/* Globals */
new Handle:g_hTrie;

/* My Info */
public Plugin:myinfo =
{
    name 		=		"Connnection Protection",	// http://www.youtube.com/watch?v=aGp2Z8tqgFc&hd=1
    author		=		"Kyle Sanderson",
    description	=		 PLUGIN_DESCRIPTION,
    version		=		 PLUGIN_VERSION,
    url			=		"http://SourceMod.net"
};

public OnPluginStart()
{
	g_hTrie = CreateTrie();
	CreateConVar("sm_cfp_version",	PLUGIN_VERSION, "Connection Flood Protection Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);	
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if (IsFakeClient(client))
	{
		return true; // Why would we want to even check these clients?
	}
	
	decl String:sIP[iIPLength];
	if (!GetClientIP(client, sIP, sizeof(sIP)))
	{
		return true; // We don't want to reject them if we can't get their IP... Although this should never happen.
	}
	
	new iConnectionCount;
	if (!GetTrieValue(g_hTrie, sIP, iConnectionCount))
	{
		new Handle:hPack = INVALID_HANDLE;
		CreateDataTimer(fClearTrieTime, ClearValueFromTrie, hPack, TIMER_DATA_HNDL_CLOSE);
		WritePackString(hPack, sIP);
		ResetPack(hPack);
		
		SetTrieValue(g_hTrie, sIP, 0);
		return true; // We don't want to call the below code if this trap works.
	}
	
	if (iConnectionCount == iConnectionBanCount)
	{
		PrintToChatAll("\x04[CFP]\x03 Banning %N (%s) for flooding connections to the server.", client, sIP);
		LogToGame("[CFP] Banning %N (%s) for flooding connections to the server.", client, sIP);
		strcopy(rejectmsg, maxlen, "Banned for Connection Flooding.");
		BanClient(client, 0, BANFLAG_IP, "Connection Flooding.", "Banned for Connection Flooding.", "sm_connectflood_protection");
		ServerCommand("sm_banip \"%s\" 0 \"Connection Flooding.\"", sIP);
		return false;
	}

	SetTrieValue(g_hTrie, sIP, (iConnectionCount + 1));
	return true;
}

public Action:ClearValueFromTrie(Handle:Timer, Handle:hPack)
{
	decl String:sIP[iIPLength];
	ReadPackString(hPack, sIP, sizeof(sIP));
	RemoveFromTrie(g_hTrie, sIP);
	return Plugin_Handled;
}