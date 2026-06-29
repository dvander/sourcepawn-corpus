#include <sourcemod>

#undef REQUIRE_EXTENSIONS
#include <steamtools>
#include <SteamWorks>

#define VERSION "3.0.0"

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Dynamic MotD Replacer",
	author = "psychonic",
	description = "Allows dynamicly generated MotD urls",
	version = VERSION,
	url = "https://scamm.in/"
};

enum /* Ep2vMOTDCmd */ {
	Cmd_None,
	Cmd_JoinGame,
	Cmd_ChangeTeam,
	Cmd_Impulse101,
	Cmd_MapInfo,
	Cmd_ClosedHTMLPage,
	Cmd_ChooseTeam,
};

ConVar sv_visiblemaxplayers = null;

// Cached values
char g_szServerIp[16];
char g_szServerPort[6];
// These can all be larger but whole buffer holds < 128
char g_szServerName[128];
char g_szServerCustom[128];
char g_szL4DGameMode[128];
char g_szCurrentMap[128];
char g_szGameDir[64];

// config values
char g_szTitle[128];
char g_szUrl[256];
bool g_bBIG;
int g_UrlBits = 0;
int g_TitleBits = 0;

// For the "big" motd.
bool g_bFirstMOTDNext[MAXPLAYERS+1] = { false, ... };
ArrayList g_cmdQueue[MAXPLAYERS+1];

// tracking
bool g_bIgnoreNextVGUI;

EngineVersion g_Engine = Engine_Unknown;
bool g_bIsL4D = false;

bool g_bHaveSteamWorks;
bool g_bHaveSteamTools;

#define FLAG_STEAM_ID      (1<<0)
#define FLAG_USER_ID       (1<<1)
#define FLAG_FRIEND_ID     (1<<2)
#define FLAG_NAME          (1<<3)
#define FLAG_IP            (1<<4)
#define FLAG_LANGUAGE      (1<<5)
#define FLAG_RATE          (1<<6)
#define FLAG_SERVER_IP     (1<<7)
#define FLAG_SERVER_PORT   (1<<8)
#define FLAG_SERVER_NAME   (1<<9)
#define FLAG_SERVER_CUSTOM (1<<10)
#define FLAG_L4D_GAMEMODE  (1<<11)
#define FLAG_CURRENT_MAP   (1<<12)
#define FLAG_NEXT_MAP      (1<<13)
#define FLAG_GAMEDIR       (1<<14)
#define FLAG_CURPLAYERS    (1<<15)
#define FLAG_MAXPLAYERS    (1<<16)

// These three require SteamWorks or SteamTools to be loaded
#define FLAG_VACSTATUS        (1<<17)
#define FLAG_SERVER_PUB_IP    (1<<18)
#define FLAG_STEAM_CONNSTATUS (1<<19)

#define FLAG_BOTPLAYERS       (1<<20)
#define FLAG_STEAM2_ID        (1<<21)
#define FLAG_STEAM3_ID        (1<<22)
#define FLAG_ACCT_ID          (1<<23)
#define FLAG_SERVER_STEAM_ID  (1<<24)
#define FLAG_SERVER_STEAM3_ID (1<<25)
#define FLAG_SERVER_ACCT_ID   (1<<26)

#define TOKEN_STEAM_ID         "{STEAM_ID}"
#define TOKEN_USER_ID          "{USER_ID}"
#define TOKEN_FRIEND_ID        "{FRIEND_ID}"
#define TOKEN_NAME             "{NAME}"
#define TOKEN_IP               "{IP}"
#define TOKEN_LANGUAGE         "{LANGUAGE}"
#define TOKEN_RATE             "{RATE}"
#define TOKEN_SERVER_IP        "{SERVER_IP}"
#define TOKEN_SERVER_PORT      "{SERVER_PORT}"
#define TOKEN_SERVER_NAME      "{SERVER_NAME}"
#define TOKEN_SERVER_CUSTOM    "{SERVER_CUSTOM}"
#define TOKEN_L4D_GAMEMODE     "{L4D_GAMEMODE}"
#define TOKEN_CURRENT_MAP      "{CURRENT_MAP}"
#define TOKEN_NEXT_MAP         "{NEXT_MAP}"
#define TOKEN_GAMEDIR          "{GAMEDIR}"
#define TOKEN_CURPLAYERS       "{CURPLAYERS}"
#define TOKEN_MAXPLAYERS       "{MAXPLAYERS}"
#define TOKEN_BOTPLAYERS       "{BOTPLAYERS}"
#define TOKEN_STEAM2_ID        "{STEAM2_ID}"
#define TOKEN_STEAM3_ID        "{STEAM3_ID}"
#define TOKEN_ACCT_ID          "{STEAM_ACCTID}"
#define TOKEN_SERVER_STEAM_ID  "{SERVER_STEAM_ID}"
#define TOKEN_SERVER_STEAM3_ID "{SERVER_STEAM3_ID}"
#define TOKEN_SERVER_ACCT_ID   "{SERVER_ACCT_ID}"
#define TOKEN_VACSTATUS		   "{VAC_STATUS}"
#define TOKEN_SERVER_PUB_IP    "{SERVER_PUB_IP}"
#define TOKEN_STEAM_CONNSTATUS "{STEAM_CONNSTATUS}"	

public Action closed_htmlpage(int client, const char[] command, int argc)
{
	if (!g_cmdQueue[client].Length)
	{
		// this one isn't for us i guess
		return Plugin_Continue;
	}
	int cmd = g_cmdQueue[client].Get(0);
	g_cmdQueue[client].Erase(0);
	
	switch (cmd)
	{
		// TF2 doesn't have joingame or chooseteam
		case Cmd_ChangeTeam:
			ShowVGUIPanel(client, "team");
		case Cmd_MapInfo:		// no server cmd equiv
			ShowVGUIPanel(client, "mapinfo");
	}
	
	return Plugin_Continue;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// SteamTools does not currently mark these as optional in inc when ext is optional. 
	MarkNativeAsOptional("Steam_IsVACEnabled");
	MarkNativeAsOptional("Steam_GetPublicIP");
	MarkNativeAsOptional("Steam_IsConnected");
}

public void OnPluginStart()
{
	g_Engine = GetEngineVersion();
	
	if (g_Engine == Engine_CSGO)
	{
		HookUserMessage(GetUserMessageId("VGUIMenu"), OnMsgVGUIMenu_Pb, true);
	}
	else
	{
		HookUserMessage(GetUserMessageId("VGUIMenu"), OnMsgVGUIMenu_Bf, true);
	}
	
	ConVar dynamicmotd_version = CreateConVar("dynamicmotd_version", VERSION, _, FCVAR_NOTIFY);
	ConVar dynamicmotd_title   = CreateConVar("dynamicmotd_title",   "", "Title to use for the MOTD window.");
	ConVar dynamicmotd_url     = CreateConVar("dynamicmotd_url",     "", "Url to use for the MOTD window.");
	ConVar dynamicmotd_custom  = CreateConVar("dynamicmotd_custom",  "",
		"The value here will be used when replacing the {SERVER_CUSTOM} token.");
	
	// On a reload, this will be set to the old version. Let's update it.
	dynamicmotd_version.SetString(VERSION);
	
	sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");
	
	// On a reload, these will already be registered and could be set to non-default
	dynamicmotd_title.GetString(g_szTitle, sizeof(g_szTitle));
	dynamicmotd_url.GetString(g_szUrl, sizeof(g_szUrl));
	
	CalcBits(g_szTitle, g_TitleBits);
	CalcBits(g_szUrl, g_UrlBits);
	
	dynamicmotd_title.AddChangeHook(OnCvarTitleChange);
	dynamicmotd_url.AddChangeHook(OnCvarUrlChange);
	
	ConVar dynamicmotd_big;
	if (g_Engine == Engine_TF2)
	{
		dynamicmotd_big = CreateConVar("dynamicmotd_big", "0",
			"If enabled, uses a larger MOTD window (TF2-only!). 0 - Disabled (default), 1 - Enabled",
			FCVAR_NONE, true, 0.0, true, 1.0);
		
		dynamicmotd_big.AddChangeHook(OnCvarBigChange);
		AddCommandListener(closed_htmlpage, "closed_htmlpage");
	}	
	
	LongIPToString(FindConVar("hostip").IntValue, g_szServerIp);	
	FindConVar("hostport").GetString(g_szServerPort, sizeof(g_szServerPort));
	
	ConVar hostname = FindConVar("hostname");
	char szHostname[256];
	hostname.GetString(szHostname, sizeof(szHostname));
	UrlEncodeString(g_szServerName, sizeof(g_szServerName), szHostname);
	HookConVarChange(hostname, OnCvarHostnameChange);
	
	char szCustom[256];
	dynamicmotd_custom.GetString(szCustom, sizeof(szCustom));
	UrlEncodeString(g_szServerCustom, sizeof(g_szServerCustom), szCustom);
	dynamicmotd_custom.AddChangeHook(OnCvarCustomChange);
	
	if (g_Engine == Engine_Left4Dead || g_Engine == Engine_Left4Dead2)
	{
		g_bIsL4D = true;
		ConVar mp_gamemode = FindConVar("mp_gamemode");
		char szGamemode[256];
		mp_gamemode.GetString(szGamemode, sizeof(szGamemode));
		UrlEncodeString(g_szL4DGameMode, sizeof(g_szL4DGameMode), szGamemode);
		mp_gamemode.AddChangeHook(OnCvarGamemodeChange);
	}
	
	char szGameDir[128];
	GetGameFolderName(szGameDir, sizeof(szGameDir));
	UrlEncodeString(g_szGameDir, sizeof(g_szGameDir), szGameDir);
	
	if (g_Engine == Engine_TF2)
	{
		g_bBIG = dynamicmotd_big.BoolValue;
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientConnected(i))
				g_cmdQueue[i] = new ArrayList();
		}
	}
}

public void OnAllPluginsLoaded()
{
	g_bHaveSteamWorks = LibraryExists("SteamWorks");
	g_bHaveSteamTools = LibraryExists("SteamTools");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "SteamWorks"))
	{
		g_bHaveSteamWorks = true;
	}
	else if (StrEqual(name, "SteamTools"))
	{
		g_bHaveSteamTools = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "SteamWorks"))
	{
		g_bHaveSteamWorks = false;
	}
	else if (StrEqual(name, "SteamTools"))
	{
		g_bHaveSteamTools = false;
	}
}

public void OnMapStart()
{
	GetCurrentMap(g_szCurrentMap, sizeof(g_szCurrentMap));
}

public void OnClientConnected(int client)
{
	if (g_Engine == Engine_TF2)
	{
		g_bFirstMOTDNext[client] = true;
		g_cmdQueue[client] = new ArrayList();
	}
}

public void OnClientDisconnect(int client)
{
	if (g_Engine == Engine_TF2)
	{
		delete g_cmdQueue[client];
	}
}

public void OnCvarTitleChange(ConVar cv, const char[] oldValue, const char[] newValue)
{
	strcopy(g_szTitle, sizeof(g_szTitle), newValue);
	CalcBits(g_szTitle, g_TitleBits);
}

public void OnCvarUrlChange(ConVar cv, const char[] oldValue, const char[] newValue)
{
	strcopy(g_szUrl, sizeof(g_szUrl), newValue);
	CalcBits(g_szUrl, g_UrlBits);
}

public void OnCvarBigChange(ConVar cv, const char[] oldValue, const char[] newValue)
{
	g_bBIG = cv.BoolValue;
}

public void OnCvarHostnameChange(ConVar cv, const char[] oldValue, const char[] newValue)
{
	UrlEncodeString(g_szServerName, sizeof(g_szServerName), newValue);
}

public void OnCvarGamemodeChange(ConVar cv, const char[] oldValue, const char[] newValue)
{
	UrlEncodeString(g_szL4DGameMode, sizeof(g_szL4DGameMode), newValue);
}

public void OnCvarCustomChange(ConVar cv, const char[] oldValue, const char[] newValue)
{
	UrlEncodeString(g_szServerCustom, sizeof(g_szServerCustom), newValue);
}

public void DoMOTD(any data)
{
	DataPack pack = view_as<DataPack>(data);
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	KeyValues kv = view_as<KeyValues>(pack.ReadCell());
	
	if (client == 0)
	{
		delete pack;
		delete kv;
		return;
	}
	
	if (g_bBIG)
	{
		kv.SetNum("customsvr", 1);
		int cmd;
		// tf2 doesn't send the cmd on the first one. it displays the mapinfo and team choice first, behind motd (so cmd is 0).
		// we can't rely on that since closing bigmotd clobbers all vgui panels, 
		if ((cmd = kv.GetNum("cmd")) != Cmd_None)
		{
			g_cmdQueue[client].Push(cmd);
			kv.SetNum("cmd", Cmd_ClosedHTMLPage);
		}
		else if (g_bFirstMOTDNext[client])
		{
			g_cmdQueue[client].Push(Cmd_ChangeTeam);
			kv.SetNum("cmd", Cmd_ClosedHTMLPage);
		}
	}
	
	kv.SetNum("type", MOTDPANEL_TYPE_URL);
	
	char title[sizeof(g_szTitle)];
	strcopy(title, sizeof(title), g_szTitle);
	
	char url[sizeof(g_szUrl)];
	strcopy(url, sizeof(url), g_szUrl);
	
	DoReplacements(client, title, url);
	
	if (title[0] != '\0')
	{
		kv.SetString("title", title);	
	}
	
	if (url[0] != '\0')
	{
		kv.SetString("msg", url);
	}
	
	g_bIgnoreNextVGUI = true;
	ShowVGUIPanel(client, "info", kv, true);
	
	delete pack;
	delete kv;
}

public Action OnMsgVGUIMenu_Pb(UserMsg msg_id, Protobuf pb, const int[] players, int playersNum, bool reliable, bool init)
{
	if (g_bIgnoreNextVGUI)
	{
		g_bIgnoreNextVGUI = false;
		return Plugin_Continue;
	}
	
	// we have no plans to replace MOTDs, skip it
	if (g_szTitle[0] == '\0' && g_szUrl[0] == '\0')
		return Plugin_Continue;
	
	char buffer1[64];
	char buffer2[256];
	
	// check menu name
	pb.ReadString("name", buffer1, sizeof(buffer1));
	if (strcmp(buffer1, "info") != 0)
		return Plugin_Continue;
	
	// make sure it's not a hidden one
	if (!pb.ReadBool("show"))
		return Plugin_Continue;
	
	int count = pb.GetRepeatedFieldCount("subkeys");
	
	// we don't one ones with no kv pairs.
	// ones with odd amount are invalid anyway
	if (count == 0)
		return Plugin_Continue;
	
	KeyValues kv = new KeyValues("data");
	for (int i = 0; i < count; ++i)
	{
		Protobuf sk = pb.ReadRepeatedMessage("subkeys", i);
		sk.ReadString("name", buffer1, sizeof(buffer1));
		sk.ReadString("str", buffer2, sizeof(buffer2));
		
		if (strcmp(buffer1, "msg") == 0 && strcmp(buffer2, "motd") != 0)
		{
			// not pulling motd from stringtable. must be a custom
			delete kv;
			return Plugin_Continue;
		}
		
		kv.SetString(buffer1, buffer2);
	}
	
	DataPack pack = new DataPack();
	RequestFrame(DoMOTD, pack);
	pack.WriteCell(GetClientUserId(players[0]));
	pack.WriteCell(kv);
	
	return Plugin_Handled;
}

public Action OnMsgVGUIMenu_Bf(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	if (g_bIgnoreNextVGUI)
	{
		g_bIgnoreNextVGUI = false;
		return Plugin_Continue;
	}
	
	// we have no plans to replace MOTDs, skip it
	if (g_szTitle[0] == '\0' && g_szUrl[0] == '\0')
		return Plugin_Continue;
	
	char buffer1[64];
	char buffer2[256];
	
	// check menu name
	bf.ReadString(buffer1, sizeof(buffer1));
	if (strcmp(buffer1, "info") != 0)
		return Plugin_Continue;
	
	// make sure it's not a hidden one
	if (bf.ReadByte() != 1)
		return Plugin_Continue;
	
	int count = bf.ReadByte();
	
	// we don't one ones with no kv pairs.
	// ones with odd amount are invalid anyway
	if (count == 0)
		return Plugin_Continue;
	
	KeyValues kv = new KeyValues("data");
	for (int i = 0; i < count; ++i)
	{
		bf.ReadString(buffer1, sizeof(buffer1));
		bf.ReadString(buffer2, sizeof(buffer2));
		
		if (strcmp(buffer1, "customsvr") == 0
			|| (strcmp(buffer1, "msg") == 0 && strcmp(buffer2, "motd") != 0)
			)
		{
			// not pulling motd from stringtable. must be a custom
			delete kv;
			return Plugin_Continue;
		}
		
		kv.SetString(buffer1, buffer2);
	}
	
	DataPack pack = new DataPack();
	RequestFrame(DoMOTD, pack);
	pack.WriteCell(GetClientUserId(players[0]));
	pack.WriteCell(kv);
	
	return Plugin_Handled;
}

void DoReplacements(int client, char motdtitle[128], char motdurl[256])
{
	if (g_UrlBits & FLAG_STEAM_ID || g_TitleBits & FLAG_STEAM_ID)
	{
		char steamId[64];
		if (GetClientAuthId(client, AuthId_Engine, steamId, sizeof(steamId)))
		{
			ReplaceString(steamId, sizeof(steamId), ":", "%3a");
			if (g_TitleBits & FLAG_STEAM_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_STEAM_ID, steamId);
			if (g_UrlBits & FLAG_STEAM_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_STEAM_ID, steamId);
		}
		else
		{
			if (g_TitleBits & FLAG_STEAM_ID)
				ReplaceString(motdtitle,   sizeof(motdtitle), TOKEN_STEAM_ID, "");
			if (g_UrlBits & FLAG_STEAM_ID)
				ReplaceString(motdurl,     sizeof(motdurl),   TOKEN_STEAM_ID, "");
		}
	}
	
	if (g_UrlBits & FLAG_STEAM2_ID || g_TitleBits & FLAG_STEAM2_ID)
	{
		char steamId[64];
		if (GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
		{
			ReplaceString(steamId, sizeof(steamId), ":", "%3a");
			if (g_TitleBits & FLAG_STEAM2_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_STEAM2_ID, steamId);
			if (g_UrlBits & FLAG_STEAM2_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_STEAM2_ID, steamId);
		}
		else
		{
			if (g_TitleBits & FLAG_STEAM2_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_STEAM2_ID, "");
			if (g_UrlBits & FLAG_STEAM2_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_STEAM2_ID, "");
		}
	}
	
	if (g_UrlBits & FLAG_STEAM3_ID || g_TitleBits & FLAG_STEAM3_ID)
	{
		char steamId[64];
		if (GetClientAuthId(client, AuthId_Steam3, steamId, sizeof(steamId)))
		{
			ReplaceString(steamId, sizeof(steamId), ":", "%3a");
			ReplaceString(steamId, sizeof(steamId), "[", "%5b");
			ReplaceString(steamId, sizeof(steamId), "]", "%5d");
			if (g_TitleBits & FLAG_STEAM3_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_STEAM3_ID, steamId);
			if (g_UrlBits & FLAG_STEAM3_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_STEAM3_ID, steamId);
		}
		else
		{
			if (g_TitleBits & FLAG_STEAM3_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_STEAM3_ID, "");
			if (g_UrlBits & FLAG_STEAM3_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_STEAM3_ID, "");
		}
	}
	
	if (g_UrlBits & FLAG_SERVER_STEAM3_ID || g_TitleBits & FLAG_SERVER_STEAM3_ID)
	{
		char steamId[64];
		if (GetServerAuthId(AuthId_Steam3, steamId, sizeof(steamId)))
		{
			ReplaceString(steamId, sizeof(steamId), ":", "%3a");
			ReplaceString(steamId, sizeof(steamId), "[", "%5b");
			ReplaceString(steamId, sizeof(steamId), "]", "%5d");
			if (g_TitleBits & FLAG_SERVER_STEAM3_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_STEAM3_ID, steamId);
			if (g_UrlBits & FLAG_SERVER_STEAM3_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_STEAM3_ID, steamId);
		}
		else
		{
			if (g_TitleBits & FLAG_SERVER_STEAM3_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_STEAM3_ID, "");
			if (g_UrlBits & FLAG_SERVER_STEAM3_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_STEAM3_ID, "");
		}
	}
	
	if (g_UrlBits & FLAG_ACCT_ID || g_TitleBits & FLAG_ACCT_ID)
	{
		int accountId = GetSteamAccountID(client);
		if (accountId)
		{
			char szAccountId[16];
			Format(szAccountId, sizeof(szAccountId), "%u", accountId);
			if (g_TitleBits & FLAG_ACCT_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_ACCT_ID, szAccountId);
			if (g_UrlBits & FLAG_ACCT_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_ACCT_ID, szAccountId);
		}
		else
		{
			if (g_TitleBits & FLAG_ACCT_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_ACCT_ID, "");
			if (g_UrlBits & FLAG_ACCT_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_ACCT_ID, "");
		}
	}
	
	if (g_UrlBits & FLAG_SERVER_ACCT_ID || g_TitleBits & FLAG_SERVER_ACCT_ID)
	{
		int accountId = GetServerSteamAccountId();
		if (accountId)
		{
			char szAccountId[16];
			Format(szAccountId, sizeof(szAccountId), "%u", accountId);
			if (g_TitleBits & FLAG_SERVER_ACCT_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_ACCT_ID, szAccountId);
			if (g_UrlBits & FLAG_SERVER_ACCT_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_ACCT_ID, szAccountId);
		}
		else
		{
			if (g_TitleBits & FLAG_SERVER_ACCT_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_ACCT_ID, "");
			if (g_UrlBits & FLAG_SERVER_ACCT_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_ACCT_ID, "");
		}
	}
	
	if (g_UrlBits & FLAG_USER_ID || g_TitleBits & FLAG_USER_ID)
	{
		char userId[16];
		IntToString(GetClientUserId(client), userId, sizeof(userId));
		if (g_TitleBits & FLAG_USER_ID)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_USER_ID, userId);
		if (g_UrlBits & FLAG_USER_ID)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_USER_ID, userId);
	}
	
	if (g_UrlBits & FLAG_FRIEND_ID || g_TitleBits & FLAG_FRIEND_ID)
	{
		char friendId[64];
		if (GetClientAuthId(client, AuthId_SteamID64, friendId, sizeof(friendId)))
		{
			if (g_TitleBits & FLAG_FRIEND_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_FRIEND_ID, friendId);
			if (g_UrlBits & FLAG_FRIEND_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_FRIEND_ID, friendId);
		}
		else
		{
			if (g_TitleBits & FLAG_FRIEND_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_FRIEND_ID, "");
			if (g_UrlBits & FLAG_FRIEND_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_FRIEND_ID, "");
		}
	}
	
	if (g_UrlBits & FLAG_SERVER_STEAM_ID || g_TitleBits & FLAG_SERVER_STEAM_ID)
	{
		char sid[64];
		if (GetServerAuthId(AuthId_SteamID64, sid, sizeof(sid)))
		{
			if (g_TitleBits & FLAG_SERVER_STEAM_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_STEAM_ID, sid);
			if (g_UrlBits & FLAG_SERVER_STEAM_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_STEAM_ID, sid);
		}
		else
		{
			if (g_TitleBits & FLAG_SERVER_STEAM_ID)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_STEAM_ID, "");
			if (g_UrlBits & FLAG_SERVER_STEAM_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_STEAM_ID, "");
		}
	}
	
	if (g_UrlBits & FLAG_NAME || g_TitleBits & FLAG_NAME)
	{
		char name[MAX_NAME_LENGTH];
		if (GetClientName(client, name, sizeof(name)))
		{
			char encName[sizeof(name)*3];
			UrlEncodeString(encName, sizeof(encName), name);
			if (g_TitleBits & FLAG_NAME)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_NAME, encName);
			if (g_UrlBits & FLAG_NAME)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_NAME, encName);
		}
		else
		{
			if (g_TitleBits & FLAG_NAME)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_NAME, "");
			if (g_UrlBits & FLAG_NAME)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_NAME, "");
		}
	}
	
	if (g_UrlBits & FLAG_IP || g_TitleBits & FLAG_IP)
	{
		char clientIp[32];
		if (GetClientIP(client, clientIp, sizeof(clientIp)))
		{
			if (g_TitleBits & FLAG_IP)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_IP, clientIp);
			if (g_UrlBits & FLAG_IP)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_IP, clientIp);
		}
		else
		{
			if (g_TitleBits & FLAG_IP)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_IP, "");
			if (g_UrlBits & FLAG_IP)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_IP, "");
		}
	}
	
	if (g_UrlBits & FLAG_LANGUAGE || g_TitleBits & FLAG_LANGUAGE)
	{
		char language[32];
		if (GetClientInfo(client, "cl_language", language, sizeof(language)))
		{
			char encLanguage[sizeof(language)*3];
			UrlEncodeString(encLanguage, sizeof(encLanguage), language);
			if (g_TitleBits & FLAG_LANGUAGE)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_LANGUAGE, encLanguage);
			if (g_UrlBits & FLAG_LANGUAGE)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_LANGUAGE, encLanguage);
		}
		else
		{
			if (g_TitleBits & FLAG_LANGUAGE)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_LANGUAGE, "");
			if (g_UrlBits & FLAG_LANGUAGE)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_LANGUAGE, "");
		}
	}
	
	if (g_UrlBits & FLAG_RATE || g_TitleBits & FLAG_RATE)
	{
		char rate[16];
		if (GetClientInfo(client, "rate", rate, sizeof(rate)))
		{
			// due to client's being silly, this won't necessarily be all digits
			char encRate[sizeof(rate)*3];
			UrlEncodeString(encRate, sizeof(encRate), rate);
			if (g_TitleBits & FLAG_RATE)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_RATE, encRate);
			if (g_UrlBits & FLAG_RATE)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_RATE, encRate);
		}
		else
		{
			if (g_TitleBits & FLAG_RATE)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_RATE, "");
			if (g_UrlBits & FLAG_RATE)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_RATE, "");
		}
	}
	
	if (g_TitleBits & FLAG_SERVER_IP)
		ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_IP, g_szServerIp);
	if (g_UrlBits & FLAG_SERVER_IP)
		ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_IP, g_szServerIp);
	
	if (g_TitleBits & FLAG_SERVER_PORT)
		ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_PORT, g_szServerPort);
	if (g_UrlBits & FLAG_SERVER_PORT)
		ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_PORT, g_szServerPort);
	
	if (g_TitleBits & FLAG_SERVER_NAME)
		ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_NAME, g_szServerName);
	if (g_UrlBits & FLAG_SERVER_NAME)
		ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_NAME, g_szServerName);	
	
	if (g_TitleBits & FLAG_SERVER_CUSTOM)
		ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_CUSTOM, g_szServerCustom);
	if (g_UrlBits & FLAG_SERVER_CUSTOM)
		ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_CUSTOM, g_szServerCustom);
	
	if (g_bIsL4D && ((g_UrlBits & FLAG_L4D_GAMEMODE) || (g_TitleBits & FLAG_L4D_GAMEMODE)))
	{
		if (g_TitleBits & FLAG_L4D_GAMEMODE)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_L4D_GAMEMODE, g_szL4DGameMode);
		if (g_UrlBits & FLAG_L4D_GAMEMODE)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_L4D_GAMEMODE, g_szL4DGameMode);
	}
	
	if (g_TitleBits & FLAG_CURRENT_MAP)
		ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_CURRENT_MAP, g_szCurrentMap);
	if (g_UrlBits & FLAG_CURRENT_MAP)
		ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_CURRENT_MAP, g_szCurrentMap);
	
	if (g_UrlBits & FLAG_NEXT_MAP || g_TitleBits & FLAG_NEXT_MAP)
	{
		char szNextMap[PLATFORM_MAX_PATH];
		if (GetNextMap(szNextMap, sizeof(szNextMap)))
		{
			if (g_TitleBits & FLAG_NEXT_MAP)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_NEXT_MAP, szNextMap);
			if (g_UrlBits & FLAG_NEXT_MAP)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_NEXT_MAP, szNextMap);
		}
		else
		{
			if (g_TitleBits & FLAG_NEXT_MAP)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_NEXT_MAP, "");
			if (g_UrlBits & FLAG_NEXT_MAP)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_NEXT_MAP, "");
		}
	}
	
	if (g_TitleBits & FLAG_GAMEDIR)
		ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_GAMEDIR, g_szGameDir);
	if (g_UrlBits & FLAG_GAMEDIR)
		ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_GAMEDIR, g_szGameDir);
	
	if (g_UrlBits & FLAG_CURPLAYERS || g_TitleBits & FLAG_CURPLAYERS)
	{
		char curplayers[10];
		IntToString(GetClientCount(false), curplayers, sizeof(curplayers));
		if (g_TitleBits & FLAG_CURPLAYERS)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_CURPLAYERS, curplayers);
		if (g_UrlBits & FLAG_CURPLAYERS)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_CURPLAYERS, curplayers);
	}
	
	if (g_UrlBits & FLAG_BOTPLAYERS || g_TitleBits & FLAG_BOTPLAYERS)
	{
		int bots = 0;
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i) && IsFakeClient(i))
				bots++;
		}	
		char botplayers[10];
		IntToString(bots, botplayers, sizeof(botplayers));
		if (g_TitleBits & FLAG_BOTPLAYERS)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_BOTPLAYERS, botplayers);
		if (g_UrlBits & FLAG_BOTPLAYERS)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_BOTPLAYERS, botplayers);
	}
	
	if (g_UrlBits & FLAG_MAXPLAYERS || g_TitleBits & FLAG_MAXPLAYERS)
	{
		char maxplayers[10];
		if (sv_visiblemaxplayers != INVALID_HANDLE && GetConVarInt(sv_visiblemaxplayers) != -1)	// -1 = default value for cvar
			IntToString(GetConVarInt(sv_visiblemaxplayers), maxplayers, sizeof(maxplayers));
		else
			IntToString(MaxClients, maxplayers, sizeof(maxplayers));
		if (g_TitleBits & FLAG_MAXPLAYERS)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_MAXPLAYERS, maxplayers);
		if (g_UrlBits & FLAG_MAXPLAYERS)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_MAXPLAYERS, maxplayers);
	}
	
	if (g_bHaveSteamWorks || g_bHaveSteamTools)
	{
		if (g_UrlBits & FLAG_VACSTATUS || g_TitleBits & FLAG_VACSTATUS)
		{
			bool bVACEnabled;
			if (g_bHaveSteamWorks)
			{
				bVACEnabled = SteamWorks_IsVACEnabled();
			}
			else
			{
				bVACEnabled = Steam_IsVACEnabled();
			}
			
			if (bVACEnabled)
			{
				if (g_TitleBits & FLAG_VACSTATUS)
					ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_VACSTATUS, "1");
				if (g_UrlBits & FLAG_VACSTATUS)
					ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_VACSTATUS, "1");
			}
			else
			{
				if (g_TitleBits & FLAG_VACSTATUS)
					ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_VACSTATUS, "0");
				if (g_UrlBits & FLAG_VACSTATUS)
					ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_VACSTATUS, "0");
			}
		}
	
		if (g_UrlBits & FLAG_SERVER_PUB_IP || g_TitleBits & FLAG_SERVER_PUB_IP)
		{
			int ip[4];
			char ipstring[16];
			if (g_bHaveSteamWorks)
			{
				SteamWorks_GetPublicIP(ip);
			}
			else
			{
				Steam_GetPublicIP(ip);
			}

			Format(ipstring, sizeof(ipstring), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
		
			if (g_TitleBits & FLAG_SERVER_PUB_IP)
				ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_PUB_IP, ipstring);
			if (g_UrlBits & FLAG_SERVER_PUB_IP)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_PUB_IP, ipstring);
		}
	
		if (g_UrlBits & FLAG_STEAM_CONNSTATUS || g_TitleBits & FLAG_STEAM_CONNSTATUS)
		{
			bool bConnected;
			if (g_bHaveSteamWorks)
			{
				bConnected = SteamWorks_IsConnected();
			}
			else
			{
				bConnected = Steam_IsConnected();
			}
			
			if (bConnected)
			{
				if (g_TitleBits & FLAG_STEAM_CONNSTATUS)
					ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_STEAM_CONNSTATUS, "1");
				if (g_UrlBits & FLAG_STEAM_CONNSTATUS)
					ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_STEAM_CONNSTATUS, "1");
			}
			else
			{
				if (g_TitleBits & FLAG_STEAM_CONNSTATUS)
					ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_STEAM_CONNSTATUS, "0");
				if (g_UrlBits & FLAG_STEAM_CONNSTATUS)
					ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_STEAM_CONNSTATUS, "0");
			}
		}
	}   // g_bHaveSteamWorks || g_bHaveSteamTools
}

#define FIELD_CHECK(%1,%2);\
if (StrContains(source, %1) != -1) { field |= %2; }

void CalcBits(const char[] source, int &field)
{
	field = 0;
	
	FIELD_CHECK(TOKEN_STEAM_ID,    FLAG_STEAM_ID);
	FIELD_CHECK(TOKEN_USER_ID,     FLAG_USER_ID);
	FIELD_CHECK(TOKEN_FRIEND_ID,   FLAG_FRIEND_ID);
	FIELD_CHECK(TOKEN_NAME,        FLAG_NAME);
	FIELD_CHECK(TOKEN_IP,          FLAG_IP);
	FIELD_CHECK(TOKEN_LANGUAGE,    FLAG_LANGUAGE);
	FIELD_CHECK(TOKEN_RATE,        FLAG_RATE);
	FIELD_CHECK(TOKEN_SERVER_IP,   FLAG_SERVER_IP);
	FIELD_CHECK(TOKEN_SERVER_PORT, FLAG_SERVER_PORT);
	FIELD_CHECK(TOKEN_SERVER_NAME, FLAG_SERVER_NAME);
	FIELD_CHECK(TOKEN_SERVER_CUSTOM, FLAG_SERVER_CUSTOM);
	
	if (g_Engine == Engine_Left4Dead || g_Engine == Engine_Left4Dead2)
	{
		FIELD_CHECK(TOKEN_L4D_GAMEMODE, FLAG_L4D_GAMEMODE);
	}
	
	FIELD_CHECK(TOKEN_CURRENT_MAP, FLAG_CURRENT_MAP);
	FIELD_CHECK(TOKEN_NEXT_MAP,    FLAG_NEXT_MAP);
	FIELD_CHECK(TOKEN_GAMEDIR,     FLAG_GAMEDIR);
	FIELD_CHECK(TOKEN_CURPLAYERS,  FLAG_CURPLAYERS);
	FIELD_CHECK(TOKEN_MAXPLAYERS,  FLAG_MAXPLAYERS);
	FIELD_CHECK(TOKEN_VACSTATUS,        FLAG_VACSTATUS);
	FIELD_CHECK(TOKEN_SERVER_PUB_IP,    FLAG_SERVER_PUB_IP);
	FIELD_CHECK(TOKEN_STEAM_CONNSTATUS, FLAG_STEAM_CONNSTATUS);
	FIELD_CHECK(TOKEN_BOTPLAYERS,  FLAG_BOTPLAYERS);
}

void LongIPToString(int ip, char szBuffer[16])
{
	int octets[4];	
	octets[0] = ((ip & 0xFF000000) >> 24) & 0xFF;
	octets[1] = ((ip & 0x00FF0000) >> 16) & 0xFF;
	octets[2] = ((ip & 0x0000FF00) >>  8) & 0xFF;
	octets[3] = ((ip & 0x000000FF) >>  0) & 0xFF;
	
	Format(szBuffer, sizeof(szBuffer), "%i.%i.%i.%i", octets[0], octets[1], octets[2], octets[3]);
}

// loosely based off of PHP's urlencode
void UrlEncodeString(char[] output, int size, const char[] input)
{
	int icnt = 0;
	int ocnt = 0;
	
	for(;;)
	{
		if (ocnt == size)
		{
			output[ocnt-1] = '\0';
			return;
		}
		
		int c = input[icnt];
		if (c == '\0')
		{
			output[ocnt] = '\0';
			return;
		}
		
		// Use '+' instead of '%20'.
		// Still follows spec and takes up less of our limited buffer.
		if (c == ' ')
		{
			output[ocnt++] = '+';
		}
		else if ((c < '0' && c != '-' && c != '.') ||
			(c < 'A' && c > '9') ||
			(c > 'Z' && c < 'a' && c != '_') ||
			(c > 'z' && c != '~')) 
		{
			output[ocnt++] = '%';
			Format(output[ocnt], size-strlen(output[ocnt]), "%x", c);
			ocnt += 2;
		}
		else
		{
			output[ocnt++] = c;
		}
		
		icnt++;
	}
}
