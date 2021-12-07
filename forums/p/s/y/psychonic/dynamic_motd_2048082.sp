#pragma semicolon 1

#include <sourcemod>
#tryinclude <steamtools>

#if defined _steamtools_included
#define VERSION "2.2.4s"
#else
#define VERSION "2.2.4"
#endif

public Plugin:myinfo = 
{
	name = "Dynamic MOTD Replacer",
	author = "psychonic",
	description = "Allows dynamicly generated MOTD urls",
	version = VERSION,
	url = "http://www.nicholashastings.com/"
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

new Handle:v_VisPlayers = INVALID_HANDLE;

// Cached values
new String:g_szServerIp[16];
new String:g_szServerPort[6];
// These can all be larger but whole buffer holds < 128
new String:g_szServerName[128];
new String:g_szServerCustom[128];
new String:g_szL4DGameMode[128];
new String:g_szCurrentMap[128];
new String:g_szGameDir[64];

// config values
new String:g_szTitle[128];
new String:g_szUrl[256];
new bool:g_bBIG;
new g_UrlBits = 0;
new g_TitleBits = 0;

// For the "big" motd.
new bool:g_bFirstMOTDNext[MAXPLAYERS+1] = { false, ... };
new Handle:g_cmdQueue[MAXPLAYERS+1];

// tracking
new bool:g_bIgnoreNextVGUI;

new g_SDKVersion = SOURCE_SDK_UNKNOWN;
new bool:g_bIsL4D = false;
new bool:g_bIsTF = false;

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

#define FLAG_BOTPLAYERS    (1<<20)

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

#if defined _steamtools_included
#define TOKEN_VACSTATUS		   "{VAC_STATUS}"
#define TOKEN_SERVER_PUB_IP    "{SERVER_PUB_IP}"
#define TOKEN_STEAM_CONNSTATUS "{STEAM_CONNSTATUS}"	
#endif  // _steamtools_included

#define CAN_GO_BIG() (g_bIsTF)

public Action:OnClose(client, const String:command[], argc)
{
	if (!GetArraySize(g_cmdQueue[client]))
	{
		// this one isn't for us i guess
			return Plugin_Continue;
	}
	new cmd = GetArrayCell(g_cmdQueue[client], 0);
	RemoveFromArray(g_cmdQueue[client], 0);
	
	if (g_bIsTF)
	{
		switch (cmd)
		{
			// TF2 doesn't have joingame or chooseteam
			case Cmd_ChangeTeam:
				ShowVGUIPanel(client, "team");
			case Cmd_MapInfo:		// no server cmd equiv
				ShowVGUIPanel(client, "mapinfo");
		}
	}
	else
	{
		switch (cmd)
		{
			case Cmd_JoinGame:
				FakeClientCommand(client, "joingame");
			case Cmd_ChangeTeam:	// changeteam is a clientcmd and restricted
				FakeClientCommand(client, "chooseteam");
			case Cmd_MapInfo:		// no server cmd equiv
				ShowVGUIPanel(client, "mapinfo");
			case Cmd_ChooseTeam:
				FakeClientCommand(client, "chooseteam");
		}
	}	
	
	return Plugin_Continue;
}

public OnPluginStart()
{
	decl String:gamedir[64];
	GetGameFolderName(gamedir, sizeof(gamedir));
	if (!strcmp(gamedir, "tf", false) || !strcmp(gamedir, "tf_beta", false))
	{
		g_bIsTF = true;
	}
	
	HookUserMessage(GetUserMessageId("VGUIMenu"), OnMsgVGUIMenu, true);
	
	new Handle:cvarVersion = CreateConVar("dynamicmotd_version", VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY);
	new Handle:cvarTitle   = CreateConVar("dynamicmotd_title",   "", "Title to use for the MOTD window.", FCVAR_PLUGIN);
	new Handle:cvarUrl     = CreateConVar("dynamicmotd_url",     "", "Url to use for the MOTD window.", FCVAR_PLUGIN);	
	new Handle:cvarCustom  = CreateConVar("dynamicmotd_custom",  "",
		"The value here will be used when replacing the {SERVER_CUSTOM} token.", FCVAR_PLUGIN);
	
	// On a reload, this will be set to the old version. Let's update it.
	SetConVarString(cvarVersion, VERSION);
	
	v_VisPlayers = FindConVar("sv_visiblemaxplayers");
	
	// On a reload, these will already be registered and could be set to non-default
	GetConVarString(cvarTitle, g_szTitle, sizeof(g_szTitle));
	GetConVarString(cvarUrl,   g_szUrl,   sizeof(g_szUrl));
	
	CalcBits(g_szTitle, g_TitleBits);
	CalcBits(g_szUrl, g_UrlBits);
	
	HookConVarChange(cvarTitle, OnCvarTitleChange);
	HookConVarChange(cvarUrl,   OnCvarUrlChange);
	
	new Handle:cvarBig;
	if (CAN_GO_BIG())
	{
		cvarBig = CreateConVar("dynamicmotd_big", "0",
			"If enabled, uses a larger MOTD window (TF2-only!). 0 - Disabled (default), 1 - Enabled",
			FCVAR_PLUGIN, true, 0.0, true, 1.0);
		
		HookConVarChange(cvarBig,   OnCvarBigChange);
		AddCommandListener(OnClose, "closed_htmlpage");
	}	
	
	LongIPToString(GetConVarInt(FindConVar("hostip")), g_szServerIp);	
	GetConVarString(FindConVar("hostport"), g_szServerPort, sizeof(g_szServerPort));
	
	new Handle:hostname = FindConVar("hostname");
	decl String:szHostname[256];
	GetConVarString(hostname, szHostname, sizeof(szHostname));
	UrlEncodeString(g_szServerName, sizeof(g_szServerName), szHostname);
	HookConVarChange(hostname, OnCvarHostnameChange);
	
	decl String:szCustom[256];
	GetConVarString(cvarCustom, szCustom, sizeof(szCustom));
	UrlEncodeString(g_szServerCustom, sizeof(g_szServerCustom), szCustom);
	HookConVarChange(cvarCustom, OnCvarCustomChange);
	
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
	
	UrlEncodeString(g_szGameDir, sizeof(g_szGameDir), gamedir);
	
	if (CAN_GO_BIG())
	{
		g_bBIG = GetConVarBool(cvarBig);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i))
				g_cmdQueue[i] = CreateArray();
		}
	}
}

public OnMapStart()
{
	GetCurrentMap(g_szCurrentMap, sizeof(g_szCurrentMap));
}

public OnClientConnected(client)
{
	if (CAN_GO_BIG())
	{
		if (g_bIsTF)
		{
			g_bFirstMOTDNext[client] = true;
		}
		g_cmdQueue[client] = CreateArray();
	}
}

public OnClientDisconnect(client)
{
	if (CAN_GO_BIG())
	{
		CloseHandle(g_cmdQueue[client]);
		g_cmdQueue[client] = INVALID_HANDLE;
	}
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
	g_bBIG = (StringToInt(newValue) == 0) ? false : true;
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

public Action:DoMOTD(Handle:hTimer, Handle:pack)
{
	ResetPack(pack);
	new client = GetClientOfUserId(ReadPackCell(pack));
	new Handle:kv = Handle:ReadPackCell(pack);
	
	if (client == 0)
	{
		CloseHandle(kv);
		return Plugin_Stop;
	}
	
	if (g_bBIG)
	{
		KvSetNum(kv, "customsvr", 1);
		new cmd;
		// tf2 doesn't send the cmd on the first one. it displays the mapinfo and team choice first, behind motd (so cmd is 0).
		// we can't rely on that since closing bigmotd clobbers all vgui panels, 
		if ((cmd = KvGetNum(kv, "cmd")) != Cmd_None)
		{
			PushArrayCell(g_cmdQueue[client], cmd);
			KvSetNum(kv, "cmd", Cmd_ClosedHTMLPage);
		}
		else if (g_bIsTF && g_bFirstMOTDNext[client] == true)
		{
			PushArrayCell(g_cmdQueue[client], Cmd_ChangeTeam);
			KvSetNum(kv, "cmd", Cmd_ClosedHTMLPage);
		}
	}
	
	KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);
	
	decl String:title[sizeof(g_szTitle)];
	strcopy(title, sizeof(title), g_szTitle);
	
	decl String:url[sizeof(g_szUrl)];
	strcopy(url, sizeof(url), g_szUrl);
	
	DoReplacements(client, title, url);
	
	if (title[0] != '\0')
	{
		KvSetString(kv, "title", title);	
	}
	
	if (url[0] != '\0')
	{
		KvSetString(kv, "msg", url);
	}
	
	g_bIgnoreNextVGUI = true;
	ShowVGUIPanel(client, "info", kv, true);
	
	CloseHandle(kv);
	
	return Plugin_Stop;
}

public Action:OnMsgVGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (g_bIgnoreNextVGUI)
	{
		g_bIgnoreNextVGUI = false;
		return Plugin_Continue;
	}
	
	// we have no plans to replace MOTDs, skip it
	if (g_szTitle[0] == '\0' && g_szUrl[0] == '\0')
		return Plugin_Continue;
	
	decl String:buffer1[64];
	decl String:buffer2[256];
	
	// check menu name
	BfReadString(bf, buffer1, sizeof(buffer1));
	if (strcmp(buffer1, "info") != 0)
		return Plugin_Continue;
	
	// make sure it's not a hidden one
	if (BfReadByte(bf) != 1)
		return Plugin_Continue;
	
	new count = BfReadByte(bf);
	
	// we don't one ones with no kv pairs.
	// ones with odd amount are invalid anyway
	if (count == 0)
		return Plugin_Continue;
	
	new Handle:kv = CreateKeyValues("data");
	for (new i = 0; i < count; i++)
	{
		BfReadString(bf, buffer1, sizeof(buffer1));
		BfReadString(bf, buffer2, sizeof(buffer2));
		
		if (strcmp(buffer1, "customsvr") == 0
			|| (strcmp(buffer1, "msg") == 0 && strcmp(buffer2, "motd") != 0)
			)
		{
			// not pulling motd from stringtable. must be a custom
			CloseHandle(kv);
			return Plugin_Continue;
		}
		
		KvSetString(kv, buffer1, buffer2);
	}
	
	new Handle:pack;
	CreateDataTimer(0.001, DoMOTD, pack, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(pack, GetClientUserId(players[0]));
	WritePackCell(pack, _:kv);
	
	return Plugin_Handled;
}

DoReplacements(client, String:motdtitle[128], String:motdurl[256])
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
	
	if (g_TitleBits & FLAG_GAMEDIR)
		ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_GAMEDIR, g_szGameDir);
	if (g_UrlBits & FLAG_GAMEDIR)
		ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_GAMEDIR, g_szGameDir);
	
	if (g_UrlBits & FLAG_CURPLAYERS || g_TitleBits & FLAG_CURPLAYERS)
	{
		decl String:curplayers[10];
		IntToString(GetClientCount(false), curplayers, sizeof(curplayers));
		if (g_TitleBits & FLAG_CURPLAYERS)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_CURPLAYERS, curplayers);
		if (g_UrlBits & FLAG_CURPLAYERS)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_CURPLAYERS, curplayers);
	}
	
	if (g_UrlBits & FLAG_BOTPLAYERS || g_TitleBits & FLAG_BOTPLAYERS)
	{
		new bots = 0;
		for (new i = 1; i < MaxClients; i ++)
		{
			if (IsClientInGame(i) && IsFakeClient(i))
				bots++;
		}	
		decl String:botplayers[10];
		IntToString(bots, botplayers, sizeof(botplayers));
		if (g_TitleBits & FLAG_BOTPLAYERS)
			ReplaceString(motdtitle, sizeof(motdtitle), TOKEN_BOTPLAYERS, botplayers);
		if (g_UrlBits & FLAG_BOTPLAYERS)
			ReplaceString(motdurl,   sizeof(motdurl),   TOKEN_BOTPLAYERS, botplayers);
	}
	
	if (g_UrlBits & FLAG_MAXPLAYERS || g_TitleBits & FLAG_MAXPLAYERS)
	{
		decl String:maxplayers[10];
		if (v_VisPlayers != INVALID_HANDLE && GetConVarInt(v_VisPlayers) != -1)	// -1 = default value for cvar
			IntToString(GetConVarInt(v_VisPlayers), maxplayers, sizeof(maxplayers));
		else
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

#define FIELD_CHECK(%1,%2);\
if (StrContains(source, %1) != -1) { field |= %2; }

CalcBits(const String:source[], &field)
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
	
	if (g_SDKVersion == SOURCE_SDK_LEFT4DEAD || g_SDKVersion == SOURCE_SDK_LEFT4DEAD2)
	{
		FIELD_CHECK(TOKEN_L4D_GAMEMODE, FLAG_L4D_GAMEMODE);
	}
	
	FIELD_CHECK(TOKEN_CURRENT_MAP, FLAG_CURRENT_MAP);
	FIELD_CHECK(TOKEN_NEXT_MAP,    FLAG_NEXT_MAP);
	FIELD_CHECK(TOKEN_GAMEDIR,     FLAG_GAMEDIR);
	FIELD_CHECK(TOKEN_CURPLAYERS,  FLAG_CURPLAYERS);
	FIELD_CHECK(TOKEN_MAXPLAYERS,  FLAG_MAXPLAYERS);

#if defined _steamtools_included
	FIELD_CHECK(TOKEN_VACSTATUS,        FLAG_VACSTATUS);
	FIELD_CHECK(TOKEN_SERVER_PUB_IP,    FLAG_SERVER_PUB_IP);
	FIELD_CHECK(TOKEN_STEAM_CONNSTATUS, FLAG_STEAM_CONNSTATUS);
#endif
	FIELD_CHECK(TOKEN_BOTPLAYERS,  FLAG_BOTPLAYERS);
}

bool:GetClientFriendID(client, String:CommunityID[], CommunityIDSize) 
{
#if defined _steamtools_included
	Steam_GetCSteamIDForClient(client, CommunityID, CommunityIDSize);
#else
	decl String:SteamID[32];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	new Identifier[17] = {7, 6, 5, 6, 1, 1, 9, 7, 9, 6, 0, 2, 6, 5, 7, 2, 8};
	decl String:SteamIDParts[3][11];
	
	if (ExplodeString(SteamID, ":", SteamIDParts, sizeof(SteamIDParts), sizeof(SteamIDParts[])) != 3)
	{
		strcopy(CommunityID, CommunityIDSize, "");
		return false;
	}
	
	new SteamIDNumber[CommunityIDSize - 1];
	for (new i = 0; i < strlen(SteamIDParts[2]); i++)
	{
		SteamIDNumber[CommunityIDSize - 2 - i] = SteamIDParts[2][strlen(SteamIDParts[2]) - 1 - i] - 48;
	}

	new Current, CarryOver;
	for (new i = (sizeof(Identifier) - 1); i > -1 ; i--)
	{
		Current = Identifier[i] + (2 * SteamIDNumber[i]) + CarryOver;
		if (i == sizeof(Identifier) - 1 && strcmp(SteamIDParts[1], "1") == 0)
		{
			Current++;
		}

		CarryOver = Current/10;
		Current %= 10;

		SteamIDNumber[i] = Current;
		CommunityID[i] = SteamIDNumber[i] + 48;
	}
	CommunityID[CommunityIDSize - 1] = '\0';
#endif  // _steamtools_included
	
	return true;
}

LongIPToString(ip, String:szBuffer[16])
{
	decl octets[4];	
	octets[0] = ((ip & 0xFF000000) >> 24) & 0xFF;
	octets[1] = ((ip & 0x00FF0000) >> 16) & 0xFF;
	octets[2] = ((ip & 0x0000FF00) >>  8) & 0xFF;
	octets[3] = ((ip & 0x000000FF) >>  0) & 0xFF;
	
	Format(szBuffer, sizeof(szBuffer), "%i.%i.%i.%i", octets[0], octets[1], octets[2], octets[3]);
}

// loosely based off of PHP's urlencode
UrlEncodeString(String:output[], size, const String:input[])
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
