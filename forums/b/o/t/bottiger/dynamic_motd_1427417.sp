#pragma semicolon 1

#include <sourcemod>

#tryinclude <steamtools>
#if !defined _steamtools_included
	#undef REQUIRE_EXTENSIONS
	#tryinclude <csteamid>
	#if !defined _csteamid_included
		native bool:GetClientCSteamID(client, String:buffer[], maxlength);
	#endif
#endif
#define REQUIRE_EXTENSIONS

#define VERSION "2.0.1"

public Plugin:myinfo = 
{
	name = "Dynamic MOTD Replacer",
	author = "psychonic",
	description = "Allows dynamicly generated MOTD urls",
	version = VERSION,
	url = "http://www.nicholashastings.com/"
};

new Handle:g_CvarVersion;

new UserMsg:vgui;

// Cached values
new String:g_szServerIp[16];
new String:g_szServerPort[6];
new String:g_szServerName[1024];
new String:g_szServerCustom[1024];
new String:g_szL4DGameMode[1024];
new String:g_szCurrentMap[PLATFORM_MAX_PATH];
new String:g_szGameDir[64];

new String:g_szTitle[256];
new String:g_szUrl[256];
new bool:g_bBIG;
new g_UrlBits = 0;
new g_TitleBits = 0;

new g_SDKVersion = SOURCE_SDK_UNKNOWN;
new bool:g_bIsL4D = false;
new bool:g_bIsTF = false;
new g_MOTDOnTwo[MAXPLAYERS+1];

enum TempData {
	String:t_title[256],
	String:t_type[16],
	String:t_cmd[64]
}
new g_TempData[MAXPLAYERS+1][TempData];

enum VGUIKVState {
	STATE_MSG,
	STATE_TITLE,
	STATE_CMD,
	STATE_TYPE,
	STATE_DONTCARE
}

new VGUIKVState:g_State = STATE_DONTCARE;

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
	
#if defined _steamtools_included
#define FLAG_VACSTATUS        (1<<17)
#define FLAG_SERVER_PUB_IP    (1<<18)
#define FLAG_STEAM_CONNSTATUS (1<<19)
#endif  // _steamtools_included	


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

#if defined _steamtools_included
#define TOKEN_VACSTATUS		   "{VAC_STATUS}"
#define TOKEN_SERVER_PUB_IP    "{SERVER_PUB_IP}"
#define TOKEN_STEAM_CONNSTATUS "{STEAM_CONNSTATUS}"	
#endif  // _steamtools_included


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GetClientCSteamID");
	
	return APLRes_Success;
}

public OnPluginStart()
{
	vgui = GetUserMessageId("VGUIMenu");
	HookUserMessage(vgui, OnMsgVGUIMenu, true);
	
	g_CvarVersion = CreateConVar("dynamicmotd_version", VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY);
	new Handle:cvarTitle = CreateConVar("dynamicmotd_title", "", "Title to use for the MOTD window.", FCVAR_PLUGIN);
	new Handle:cvarUrl   = CreateConVar("dynamicmotd_url",   "", "Url to use for the MOTD window.", FCVAR_PLUGIN);
	new Handle:cvarBig   = CreateConVar("dynamicmotd_big",   "0","If enabled, uses a larger MOTD window (TF2-only!). 0 - Disabled (default), 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	new Handle:cvarCustom   = CreateConVar("dynamicmotd_custom",   "", "The value here will be used when replacing the {SERVER_CUSTOM} token.", FCVAR_PLUGIN);
	
	// On a reload, these will already be registered and could be set to non-default
	GetConVarString(cvarTitle, g_szTitle, sizeof(g_szTitle));
	GetConVarString(cvarUrl,   g_szUrl,   sizeof(g_szUrl));
	
	CalcBits(g_szTitle, g_TitleBits);
	CalcBits(g_szUrl, g_UrlBits);
	
	HookConVarChange(cvarTitle, OnCvarTitleChange);
	HookConVarChange(cvarUrl,   OnCvarUrlChange);
	HookConVarChange(cvarBig,   OnCvarBigChange);
	
	LongIPToString(GetConVarInt(FindConVar("hostip")), g_szServerIp);	
	GetConVarString(FindConVar("hostport"), g_szServerPort, sizeof(g_szServerPort));
	
	new Handle:hostname = FindConVar("hostname");
	decl String:szHostname[256];
	GetConVarString(hostname, szHostname, sizeof(szHostname));
	UrlEncodeString(g_szServerName, sizeof(g_szServerName), szHostname);
	HookConVarChange(hostname, OnCvarHostnameChange);
	
	decl String:gamedir[64];
	GetGameFolderName(gamedir, sizeof(gamedir));
	
	g_SDKVersion = GuessSDKVersion();
	if (g_SDKVersion == SOURCE_SDK_LEFT4DEAD || g_SDKVersion == SOURCE_SDK_LEFT4DEAD2)
	{
		g_bIsL4D = true;
		new Handle:gamemode = FindConVar("mp_gamemode");
		decl String:szGamemode[256];
		GetConVarString(gamemode, szGamemode, sizeof(szGamemode));
		UrlEncodeString(g_szL4DGameMode, sizeof(g_szL4DGameMode), szGamemode);
		HookConVarChange(gamemode, OnCvarGamemodeChange);
	}
	else
	{
		if (!strcmp(gamedir, "tf", false) || !strcmp(gamedir, "tf_beta", false))
		{
			g_bIsTF = true;
		}
	}
	g_bBIG = (g_bIsTF && GetConVarBool(cvarBig));
	UrlEncodeString(g_szGameDir, sizeof(g_szGameDir), gamedir);
	
	decl String:szCustom[256];
	GetConVarString(cvarCustom, szCustom, sizeof(szCustom));
	UrlEncodeString(g_szServerCustom, sizeof(g_szServerCustom), szCustom);
	HookConVarChange(cvarCustom, OnCvarCustomChange);
	
	HookEvent("player_spawn", OnPlayerSpawnEvent);
	HookEvent("player_team", OnPlayerSpawnEvent);
}

public OnMapStart()
{
	// valvefail
	if (g_SDKVersion == SOURCE_SDK_EPISODE2VALVE)
	{
		SetConVarFlags(g_CvarVersion, FCVAR_PLUGIN);
		SetConVarString(g_CvarVersion, VERSION);
		SetConVarFlags(g_CvarVersion, FCVAR_PLUGIN|FCVAR_NOTIFY);
	}
	
	GetCurrentMap(g_szCurrentMap, sizeof(g_szCurrentMap));
}

public OnCvarTitleChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_szTitle, sizeof(g_szTitle), newValue);
	CalcBits(g_szTitle, g_TitleBits);
}

public OnCvarUrlChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_szUrl, sizeof(g_szUrl), newValue);
	CalcBits(g_szUrl, g_UrlBits);
}

public OnCvarBigChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new intval = StringToInt(newValue);
	if (intval == 0)
	{
		g_bBIG = false;
	}
	else
	{
		g_bBIG = g_bIsTF;
	}
}

public OnCvarHostnameChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UrlEncodeString(g_szServerName, sizeof(g_szServerName), newValue);
}

public OnCvarGamemodeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UrlEncodeString(g_szL4DGameMode, sizeof(g_szL4DGameMode), newValue);
}

public OnCvarCustomChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UrlEncodeString(g_szServerCustom, sizeof(g_szServerCustom), newValue);
}

public OnClientConnected(client)
{
	g_MOTDOnTwo[client] = 0;
}

public Action:DoMOTD(Handle:hTimer, Handle:packhead)
{
	ResetPack(packhead);
	new client = GetClientOfUserId(ReadPackCell(packhead));
	if (client == 0)
		return Plugin_Stop;
	
	decl String:title[sizeof(g_szTitle)];
	strcopy(title, sizeof(title), g_szTitle);
	
	decl String:url[sizeof(g_szUrl)];
	strcopy(url, sizeof(url), g_szUrl);
	
	DoReplacements(client, title, url);
	
	decl recipients[1];
	recipients[0] = client;
	
	new Handle:msg = StartMessageEx(vgui, recipients, sizeof(recipients), USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWriteString(msg, "info");
	BfWriteByte(msg, 1);  // 1 show, 0 hidden
	
	// count of string pairs below
	if (g_bBIG)
	{
		BfWriteByte(msg, 6);
	}
	else
	{
		BfWriteByte(msg, 5);
	}
	
	BfWriteString(msg, "title");
	
	decl String:packtitle[256];
	ReadPackString(packhead, packtitle, sizeof(packtitle));
	if (title[0] == '\0')
	{
		BfWriteString(msg, packtitle);	
	}
	else
	{
		BfWriteString(msg, title);
	}
	
	BfWriteString(msg, "type");
	
	decl String:packtype[16];
	ReadPackString(packhead, packtype, sizeof(packtype));
	if (url[0] == '\0')
	{
		BfWriteString(msg, packtype);
	}
	else
	{
		BfWriteString(msg, "2");
	}
	
	BfWriteString(msg, "msg");
	
	if (url[0] == '\0')
	{
		BfWriteString(msg, "motd");
	}
	else
	{
		BfWriteString(msg, url);
	}
	
	// this might just be for tf2, maybe all ep2v, too lazy to check
	// one extra kv pair shouldn't hurt on others
	BfWriteString(msg, "msg_fallback");
	BfWriteString(msg, "motd_text");
	//
	
	BfWriteString(msg, "cmd");
	
	decl String:packcmd[64];
	ReadPackString(packhead, packcmd, sizeof(packcmd));
	BfWriteString(msg, packcmd);
	
	if (g_bBIG)
	{
		BfWriteString(msg, "customsvr");
		BfWriteString(msg, "1");
	}
	
	EndMessage();
	
	return Plugin_Stop;
}

DoReplacements(client, String:motdtitle[256], String:motdurl[256])
{
	if (g_UrlBits & FLAG_STEAM_ID || g_TitleBits & FLAG_STEAM_ID)
	{
		decl String:steamId[64];
		if (GetClientAuthString(client, steamId, sizeof(steamId)))
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
				ReplaceString(motdtitle,   sizeof(motdtitle),   TOKEN_STEAM_ID, "");
			if (g_UrlBits & FLAG_STEAM_ID)
				ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_STEAM_ID, "");
		}
	}
	
	if (g_UrlBits & FLAG_USER_ID || g_TitleBits & FLAG_USER_ID)
	{
		decl String:userId[16];
		IntToString(GetClientUserId(client), userId, sizeof(userId));
		if (g_TitleBits & FLAG_USER_ID)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_USER_ID, userId);
		if (g_UrlBits & FLAG_USER_ID)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_USER_ID, userId);
	}
	
	if (g_UrlBits & FLAG_FRIEND_ID || g_TitleBits & FLAG_FRIEND_ID)
	{
		decl String:friendId[64];
		if (GetClientFriendID(client, friendId, sizeof(friendId)))
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
	
	if (g_UrlBits & FLAG_NAME || g_TitleBits & FLAG_NAME)
	{
		decl String:name[MAX_NAME_LENGTH];
		if (GetClientName(client, name, sizeof(name)))
		{
			decl String:encName[sizeof(name)*3];
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
		decl String:clientIp[32];
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
		decl String:language[32];
		if (GetClientInfo(client, "cl_language", language, sizeof(language)))
		{
			decl String:encLanguage[sizeof(language)*3];
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
		decl String:rate[16];
		if (GetClientInfo(client, "rate", rate, sizeof(rate)))
		{
			// due to client's being silly, this won't necessarily be all digits
			decl String:encRate[sizeof(rate)*3];
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
	
	if (g_UrlBits & FLAG_SERVER_IP || g_TitleBits & FLAG_SERVER_IP)
	{
		if (g_TitleBits & FLAG_SERVER_IP)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_IP, g_szServerIp);
		if (g_UrlBits & FLAG_SERVER_IP)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_IP, g_szServerIp);
	}
	
	if (g_UrlBits & FLAG_SERVER_PORT || g_TitleBits & FLAG_SERVER_PORT)
	{
		if (g_TitleBits & FLAG_SERVER_PORT)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_PORT, g_szServerPort);
		if (g_UrlBits & FLAG_SERVER_PORT)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_PORT, g_szServerPort);
	}
	
	if (g_UrlBits & FLAG_SERVER_NAME || g_TitleBits & FLAG_SERVER_NAME)
	{
		if (g_TitleBits & FLAG_SERVER_NAME)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_NAME, g_szServerName);
		if (g_UrlBits & FLAG_SERVER_NAME)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_NAME, g_szServerName);	
	}
	
	if (g_UrlBits & FLAG_SERVER_CUSTOM || g_TitleBits & FLAG_SERVER_CUSTOM)
	{
		if (g_TitleBits & FLAG_SERVER_CUSTOM)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_CUSTOM, g_szServerCustom);
		if (g_UrlBits & FLAG_SERVER_CUSTOM)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_CUSTOM, g_szServerCustom);
	}
	
	if (g_bIsL4D && ((g_UrlBits & FLAG_L4D_GAMEMODE) || (g_TitleBits & FLAG_L4D_GAMEMODE)))
	{
		if (g_TitleBits & FLAG_L4D_GAMEMODE)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_L4D_GAMEMODE, g_szL4DGameMode);
		if (g_UrlBits & FLAG_L4D_GAMEMODE)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_L4D_GAMEMODE, g_szL4DGameMode);
	}
	
	if (g_UrlBits & FLAG_CURRENT_MAP || g_TitleBits & FLAG_CURRENT_MAP)
	{
		if (g_TitleBits & FLAG_CURRENT_MAP)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_CURRENT_MAP, g_szCurrentMap);
		if (g_UrlBits & FLAG_CURRENT_MAP)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_CURRENT_MAP, g_szCurrentMap);
	}
	
	if (g_UrlBits & FLAG_NEXT_MAP || g_TitleBits & FLAG_NEXT_MAP)
	{
		decl String:szNextMap[PLATFORM_MAX_PATH];
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
	
	if (g_UrlBits & FLAG_GAMEDIR || g_TitleBits & FLAG_GAMEDIR)
	{
		if (g_TitleBits & FLAG_GAMEDIR)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_GAMEDIR, g_szGameDir);
		if (g_UrlBits & FLAG_GAMEDIR)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_GAMEDIR, g_szGameDir);
	}
	
	if (g_UrlBits & FLAG_CURPLAYERS || g_TitleBits & FLAG_CURPLAYERS)
	{
		decl String:curplayers[10];
		IntToString(GetClientCount(false), curplayers, sizeof(curplayers));
		if (g_TitleBits & FLAG_CURPLAYERS)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_CURPLAYERS, curplayers);
		if (g_UrlBits & FLAG_CURPLAYERS)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_CURPLAYERS, curplayers);
	}
	
	if (g_UrlBits & FLAG_MAXPLAYERS || g_UrlBits & FLAG_MAXPLAYERS)
	{
		decl String:maxplayers[10];
		IntToString(MaxClients, maxplayers, sizeof(maxplayers));
		if (g_TitleBits & FLAG_MAXPLAYERS)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_MAXPLAYERS, maxplayers);
		if (g_UrlBits & FLAG_MAXPLAYERS)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_MAXPLAYERS, maxplayers);
	}
	
#if defined _steamtools_included
	if (g_UrlBits & FLAG_VACSTATUS || g_TitleBits & FLAG_VACSTATUS)
	{
		if (Steam_IsVACEnabled())
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
		decl ip[4];
		decl String:ipstring[16];
		Steam_GetPublicIP(ip);
		Format(ipstring, sizeof(ipstring), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
		
		if (g_TitleBits & FLAG_SERVER_PUB_IP)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_SERVER_PUB_IP, ipstring);
		if (g_UrlBits & FLAG_SERVER_PUB_IP)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_SERVER_PUB_IP, ipstring);
	}
	
	if (g_UrlBits & FLAG_STEAM_CONNSTATUS || g_TitleBits & FLAG_STEAM_CONNSTATUS)
	{
		if (Steam_IsConnected())
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
#endif  // _steamtools_included
}

bool:GetClientFriendID(client, String:FriendID[], size) 
{
#if defined _steamtools_included
	Steam_GetCSteamIDForClient(client, FriendID, size);
#else
	if (FeatureStatus_Available == GetFeatureStatus(FeatureType_Native, "GetClientCSteamID")
		&& GetClientCSteamID(client, FriendID, size))
	{
		return true;
	}
	
	decl String:SteamID[32];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	ReplaceString(SteamID, strlen(SteamID), "STEAM_", "");
	if (StrEqual(SteamID, "ID_LAN"))
	{
		FriendID[0] = '\0';
		return false;
	}
	
	decl String:toks[3][16];
	ExplodeString(SteamID, ":", toks, sizeof(toks), sizeof(toks[]));
	
	new iServer = StringToInt(toks[1]);
	new iAuthID = StringToInt(toks[2]);
	new iFriendID = (iAuthID*2) + 60265728 + iServer;
	
	if (iFriendID >= 100000000)
	{
		decl String:temp[12], String:carry[12];
		Format(temp, sizeof(temp), "%d", iFriendID);
		Format(carry, 2, "%s", temp);
		new icarry = StringToInt(carry[0]);
		new upper = 765611979 + icarry;
		
		Format(temp, sizeof(temp), "%d", iFriendID);
		Format(FriendID, size, "%d%s", upper, temp[1]);
	}
	else
	{
		Format(FriendID, size, "765611979%d", iFriendID);
	}
#endif  // _steamtools_included
	
	return true;
}


public Action:OnMsgVGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (g_szTitle[0] == '\0' && g_szUrl[0] == '\0')
		return Plugin_Continue;
	
	decl String:buffer[256];
	BfReadString(bf, buffer, sizeof(buffer)); //menuname
	if (strcmp(buffer, "specgui") == 0 && IsClientInGame(players[0]) && GetClientTeam(players[0]) == 0) {
		return Plugin_Handled;
	} 
	if (strcmp(buffer, "info") != 0) {
		return Plugin_Continue;
	}
	if (BfReadByte(bf) != 1) {
		return Plugin_Continue;
	}
	
	new count = BfReadByte(bf);
	new equal4andBugOut = 0;
	decl String:title[256];
	title[0] = '\0';
	decl String:type[16];
	type[0] = '\0';
	decl String:cmd[64];
	cmd[0] = '\0';    

	for (new i = 0; i < count; i++)
	{
		g_State = STATE_DONTCARE;
		
		BfReadString(bf, buffer, sizeof(buffer));
		if (!strcmp(buffer, "title"))
		{
			g_State = STATE_TITLE;
		}
		else if (!strcmp(buffer, "type"))
		{
			g_State = STATE_TYPE;
		}
		else if (!strcmp(buffer, "msg"))
		{
			g_State = STATE_MSG;
		}
		else if (!strcmp(buffer, "cmd"))
		{
			g_State = STATE_CMD;
		}
		
		BfReadString(bf, buffer, sizeof(buffer));
		switch (g_State)
		{
			case STATE_TITLE:
			{
				strcopy(title, sizeof(title), buffer);
				equal4andBugOut++;
			}
			case STATE_TYPE:
			{
				strcopy(type, sizeof(type), buffer);
				equal4andBugOut++;
			}
			case STATE_MSG:
			{
				if (strcmp(buffer, "motd") != 0)
				{
					return Plugin_Continue;
				}
				
				equal4andBugOut++;
			}
			case STATE_CMD:
			{
				strcopy(cmd, sizeof(cmd), buffer);
				equal4andBugOut++;
			}
		}
		
		if (equal4andBugOut == 4)
		{
			new client = players[0];
			if (g_bBIG)
			{
				g_MOTDOnTwo[client] = 1;
				strcopy(g_TempData[client][t_title], 256, title);
				strcopy(g_TempData[client][t_type], 16, type);
				strcopy(g_TempData[client][t_cmd], 64, cmd);
				CreateTimer(1.0, DoTFTeamSelect, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				new Handle:packhead;
				CreateDataTimer(0.001, DoMOTD, packhead, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
				WritePackCell(packhead, GetClientUserId(client));
				WritePackString(packhead, title);
				WritePackString(packhead, type);
				WritePackString(packhead, cmd);
			}
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:DoTFTeamSelect(Handle:hTimer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0)
		return Plugin_Stop;
	
	ShowVGUIPanel(client, "team", _, true);
	return Plugin_Stop;
}

public OnPlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}
	
	switch (g_MOTDOnTwo[client])
	{
		case 1:
		{
			g_MOTDOnTwo[client]++;
			return;
		}
		case 2:
		{
			new Handle:packhead = CreateDataPack();
			WritePackCell(packhead, userid);
			WritePackString(packhead, g_TempData[client][t_title]);
			WritePackString(packhead, g_TempData[client][t_type]);
			WritePackString(packhead, g_TempData[client][t_cmd]);
			
			DoMOTD(INVALID_HANDLE, packhead);
			
			g_MOTDOnTwo[client] = 0;
		}
	}
}

CalcBits(const String:source[], &field)
{
	field = 0;
	if (StrContains(source, TOKEN_STEAM_ID) != -1)
	{
		field |= FLAG_STEAM_ID;
	}
	if (StrContains(source, TOKEN_USER_ID) != -1)
	{
		field |= FLAG_USER_ID;
	}
	if (StrContains(source, TOKEN_FRIEND_ID) != -1)
	{
		field |= FLAG_FRIEND_ID;
	}
	if (StrContains(source, TOKEN_NAME) != -1)
	{
		field |= FLAG_NAME;
	}
	if (StrContains(source, TOKEN_IP) != -1)
	{
		field |= FLAG_IP;
	}
	if (StrContains(source, TOKEN_LANGUAGE) != -1)
	{
		field |= FLAG_LANGUAGE;
	}
	if (StrContains(source, TOKEN_RATE) != -1)
	{
		field |= FLAG_RATE;
	}
	if (StrContains(source, TOKEN_SERVER_IP) != -1)
	{
		field |= FLAG_SERVER_IP;
	}
	if (StrContains(source, TOKEN_SERVER_PORT) != -1)
	{
		field |= FLAG_SERVER_PORT;
	}
	if (StrContains(source, TOKEN_SERVER_NAME) != -1)
	{
		field |= FLAG_SERVER_NAME;
	}
	if (StrContains(source, TOKEN_SERVER_CUSTOM) != -1)
	{
		field |= FLAG_SERVER_CUSTOM;
	}
	if (StrContains(source, TOKEN_L4D_GAMEMODE) != -1
		&& (g_SDKVersion == SOURCE_SDK_LEFT4DEAD || g_SDKVersion == SOURCE_SDK_LEFT4DEAD2))
	{
		field |= FLAG_L4D_GAMEMODE;
	}
	if (StrContains(source, TOKEN_CURRENT_MAP) != -1)
	{
		field |= FLAG_CURRENT_MAP;
	}
	if (StrContains(source, TOKEN_NEXT_MAP) != -1)
	{
		field |= FLAG_NEXT_MAP;
	}
	if (StrContains(source, TOKEN_GAMEDIR) != -1)
	{
		field |= FLAG_GAMEDIR;
	}
	if (StrContains(source, TOKEN_CURPLAYERS) != -1)
	{
		field |= FLAG_CURPLAYERS;
	}
	if (StrContains(source, TOKEN_MAXPLAYERS) != -1)
	{
		field |= FLAG_MAXPLAYERS;
	}
	
#if defined _steamtools_included
	if (StrContains(source, TOKEN_VACSTATUS) != -1)
	{
		field |= FLAG_VACSTATUS;
	}
	if (StrContains(source, TOKEN_SERVER_PUB_IP) != -1)
	{
		field |= FLAG_SERVER_PUB_IP;
	}
	if (StrContains(source, TOKEN_STEAM_CONNSTATUS) != -1)
	{
		field |= FLAG_STEAM_CONNSTATUS;
	}
#endif  // _steamtools_included
}

// Courtesy of Mr. Asher Baker
stock LongIPToString(ip, String:szBuffer[16])
{
	decl octets[4];	
	octets[0] = ((ip & 0xFF000000) >> 24) & 0xFF;
	octets[1] = ((ip & 0x00FF0000) >> 16) & 0xFF;
	octets[2] = ((ip & 0x0000FF00) >>  8) & 0xFF;
	octets[3] = ((ip & 0x000000FF) >>  0) & 0xFF;
	
	Format(szBuffer, sizeof(szBuffer), "%i.%i.%i.%i", octets[0], octets[1], octets[2], octets[3]);
}

// loosely based off of PHP's urlencode
stock UrlEncodeString(String:output[], size, const String:input[])
{
	new icnt = 0;
	new ocnt = 0;
	
	for(;;)
	{
		if (ocnt == size)
		{
			output[ocnt-1] = '\0';
			return;
		}
		
		new c = input[icnt];
		if (c == '\0')
		{
			output[ocnt] = '\0';
			return;
		}
		
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
