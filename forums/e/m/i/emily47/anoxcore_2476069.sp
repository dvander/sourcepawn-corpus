public PlVers:__version =
{
	version = 5,
	filevers = "1.6.3-dev+4596",
	date = "08/03/2016",
	time = "20:59:27"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_cprefs =
{
	name = "Client Preferences",
	file = "clientprefs.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_tf2 =
{
	name = "TF2 Tools",
	file = "game.tf2.ext",
	autoload = 0,
	required = 1,
};
new _pl_scp = 1208;
public Extension:__ext_topmenus =
{
	name = "TopMenus",
	file = "topmenus.ext",
	autoload = 1,
	required = 0,
};
public SharedPlugin:__pl_adminmenu =
{
	name = "adminmenu",
	file = "adminmenu.smx",
	required = 0,
};
public Extension:__ext_smsock =
{
	name = "Socket",
	file = "socket.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_SteamTools =
{
	name = "SteamTools",
	file = "steamtools.ext",
	autoload = 1,
	required = 1,
};
new Handle:S_Holiday;
new Handle:IsNoticeON;
new bool:UpdateWarningSet;
new Handle:songMenu;
new Handle:songTitles;
new Handle:songIds;
new Handle:playlistIds;
new Handle:playlistNames;
new Handle:playlistSteamIds;
new Handle:playlistSongs;
new Handle:repeatCookie;
new Handle:shuffleCookie;
new Handle:volumeCookie;
new bool:warningShown[66];
new bool:advertShown[66];
new bool:capturingPlaylistName[66];
new bool:configsExecuted;
new Handle:hudText;
new Handle:playlistArray[66];
new String:newPlaylistName[66][36];
new Handle:forwardOnStartListen;
public Plugin:myinfo =
{
	name = "[AnoX]A-Nox Core",
	description = "",
	author = "A-Nox dev.",
	version = "2.5",
	url = "http://steamcommunity.com/groups/anoxplugin"
};
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	MarkNativeAsOptional("BfWriteBool");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteChar");
	MarkNativeAsOptional("BfWriteShort");
	MarkNativeAsOptional("BfWriteWord");
	MarkNativeAsOptional("BfWriteNum");
	MarkNativeAsOptional("BfWriteFloat");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("BfWriteEntity");
	MarkNativeAsOptional("BfWriteAngle");
	MarkNativeAsOptional("BfWriteCoord");
	MarkNativeAsOptional("BfWriteVecCoord");
	MarkNativeAsOptional("BfWriteVecNormal");
	MarkNativeAsOptional("BfWriteAngles");
	MarkNativeAsOptional("BfReadBool");
	MarkNativeAsOptional("BfReadByte");
	MarkNativeAsOptional("BfReadChar");
	MarkNativeAsOptional("BfReadShort");
	MarkNativeAsOptional("BfReadWord");
	MarkNativeAsOptional("BfReadNum");
	MarkNativeAsOptional("BfReadFloat");
	MarkNativeAsOptional("BfReadString");
	MarkNativeAsOptional("BfReadEntity");
	MarkNativeAsOptional("BfReadAngle");
	MarkNativeAsOptional("BfReadCoord");
	MarkNativeAsOptional("BfReadVecCoord");
	MarkNativeAsOptional("BfReadVecNormal");
	MarkNativeAsOptional("BfReadAngles");
	MarkNativeAsOptional("BfGetNumBytesLeft");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetFloat");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbSetColor");
	MarkNativeAsOptional("PbSetAngle");
	MarkNativeAsOptional("PbSetVector");
	MarkNativeAsOptional("PbSetVector2D");
	MarkNativeAsOptional("PbAddInt");
	MarkNativeAsOptional("PbAddFloat");
	MarkNativeAsOptional("PbAddBool");
	MarkNativeAsOptional("PbAddString");
	MarkNativeAsOptional("PbAddColor");
	MarkNativeAsOptional("PbAddAngle");
	MarkNativeAsOptional("PbAddVector");
	MarkNativeAsOptional("PbAddVector2D");
	MarkNativeAsOptional("PbRemoveRepeatedFieldValue");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	VerifyCoreVersion();
	return 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

bool:WriteFileCell(Handle:hndl, data, size)
{
	new array[1];
	array[0] = data;
	return WriteFile(hndl, array, 1, size);
}

PrintToChatAll(String:format[])
{
	decl String:buffer[192];
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 192, format, 2);
			PrintToChat(i, "%s", buffer);
		}
		i++;
	}
	return 0;
}

ShowMOTDPanel(client, String:title[], String:msg[], type)
{
	decl String:num[4];
	new Handle:Kv = CreateKeyValues("data", "", "");
	IntToString(type, num, 3);
	KvSetString(Kv, "title", title);
	KvSetString(Kv, "type", num);
	KvSetString(Kv, "msg", msg);
	ShowVGUIPanel(client, "info", Kv, true);
	CloseHandle(Kv);
	return 0;
}

public _pl_scp_SetNTVOptional()
{
	MarkNativeAsOptional("GetMessageFlags");
	return 0;
}

bool:IsTeamMate(client)
{
	decl String:SteamID[64];
	GetClientAuthString(client, SteamID, 64, true);
	if (StrEqual("STEAM_0:0:64434731", SteamID, false))
	{
		return true;
	}
	if (StrEqual("STEAM_0:0:38235680", SteamID, false))
	{
		return true;
	}
	if (StrEqual("STEAM_0:1:43524116", SteamID, false))
	{
		return true;
	}
	if (StrEqual("STEAM_0:0:56109191", SteamID, false))
	{
		return true;
	}
	return false;
}

ReloadCore()
{
	ServerCommand("sm plugins reload anoxcore");
	return 0;
}

public __ext_topmenus_SetNTVOptional()
{
	MarkNativeAsOptional("CreateTopMenu");
	MarkNativeAsOptional("LoadTopMenuConfig");
	MarkNativeAsOptional("AddToTopMenu");
	MarkNativeAsOptional("RemoveFromTopMenu");
	MarkNativeAsOptional("DisplayTopMenu");
	MarkNativeAsOptional("DisplayTopMenuCategory");
	MarkNativeAsOptional("FindTopMenuCategory");
	MarkNativeAsOptional("SetTopMenuTitleCaching");
	return 0;
}

public __pl_adminmenu_SetNTVOptional()
{
	MarkNativeAsOptional("GetAdminTopMenu");
	MarkNativeAsOptional("AddTargetsToMenu");
	MarkNativeAsOptional("AddTargetsToMenu2");
	return 0;
}

public OnPluginStart()
{
	S_Holiday = CreateConVar("AnoX_Server_Holiday", "2", "서버에 할로윈 및 팀포생일을 적용할 수 있습니다.\n할로윈 활성화시 할로윈 아이템을 사용할 수 있게 됩니다.\n0 - 비활성화\n1 - 팀포생일\n2 - 할로윈", 262144, false, 0.0, false, 0.0);
	IsNoticeON = CreateConVar("AnoX_Plugin_Notice", "1", "플러그인에서 채팅창에 공지사항을 출력할지 설정합니다.\n1 = 활성화 / 0 = 비활성화", 262144, true, 0.0, true, 1.0);
	AutoExecConfig(true, "AnoX_Core_Settings", "sourcemod");
	RegConsoleCmd("sm_anox", anoxinfo, "", 0);
	RegConsoleCmd("updatewarning", P_UpdateWarnSet, "", 0);
	RegConsoleCmd("axreload", P_RELOAD2, "", 0);
	RegConsoleCmd("reloadsongs", Command_ReloadSongs, "", 0);
	RegConsoleCmd("sm_id", Check_ID, "", 0);
	RegConsoleCmd("sm_axmp", AnoX_MusicPlayerMenuOpen, "", 0);
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	ServerCommand("sv_tags anox");
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode:1);
	songTitles = CreateArray(33, 0);
	songIds = CreateArray(1, 0);
	playlistIds = CreateArray(1, 0);
	playlistNames = CreateArray(33, 0);
	playlistSteamIds = CreateArray(33, 0);
	playlistSongs = CreateArray(1024, 0);
	repeatCookie = RegClientCookie("anoxdj_repeat", "", CookieAccess:2);
	shuffleCookie = RegClientCookie("anoxdj_shuffle", "", CookieAccess:2);
	volumeCookie = RegClientCookie("anoxdj_volume", "", CookieAccess:2);
	hudText = CreateHudSynchronizer();
	forwardOnStartListen = CreateGlobalForward("ANOX_OnStartListen", ExecType:0, 2, 7);
	CreateTimer(10.0, P_UpdateWarning, any:0, 1);
	return 0;
}

public OnMapStart()
{
	CreateTimer(119.0, P_AD, any:0, 3);
	CreateTimer(3600.0, P_RELOAD, any:0, 3);
	CreateTimer(1800.0, P_ReloadSongs, any:0, 3);
	CreateTimer(10.0, Set_Holiday, any:0, 0);
	if (configsExecuted)
	{
		LoadSongs();
	}
	return 0;
}

public Action:Set_Holiday(Handle:shTimer)
{
	new Holiday = GetConVarInt(S_Holiday);
	SetConVarInt(FindConVar("tf_forced_holiday"), Holiday, false, false);
	return Action:0;
}

public Action:P_UpdateWarning(Handle:WnTimer)
{
	if (UpdateWarningSet == true)
	{
		PrintToChatAll("%s\x07FF0000[경고!] \x07FFFFFF어녹스 코어 플러그인이 최신버전이 아닙니다. 최신버전으로 업데이트 해주세요.", "\x07F55B5B[AnoX] \x07FFFFFF");
	}
	return Action:0;
}

public Action:P_ReloadSongs(Handle:rsTimer)
{
	LoadSongs();
	return Action:0;
}

public Action:P_AD(Handle:Timer)
{
	if (GetConVarBool(IsNoticeON))
	{
		static ADtimer;
		ADtimer += 1;
		switch (ADtimer)
		{
			case 1:
			{
				PrintToChatAll("%s이 서버는 어녹스팀의 지원을 받고 있습니다.", "\x07F55B5B[AnoX] \x07FFFFFF");
			}
			case 2:
			{
				PrintToChatAll("%s\x07FFFB00!anox\x07FFFFFF로 어녹스팀의 정보를 보실 수 있습니다.", "\x07F55B5B[AnoX] \x07FFFFFF");
			}
			case 3:
			{
				PrintToChatAll("%s채팅창에 \x07FFFB00!id\x07FFFFFF를 치시면 플레이어의 고유번호를 알 수 있습니다.", "\x07F55B5B[AnoX] \x07FFFFFF");
			}
			case 4:
			{
				PrintToChatAll("%s현재 코어플러그인의 버전은 %s입니다.", "\x07F55B5B[AnoX] \x07FFFFFF", "2.5");
			}
			case 5:
			{
				PrintToChatAll("%s채팅창에 \x07FFFB00!axmp\x07FFFFFF를 치시면 어녹스 뮤직플레이어 사용이 가능합니다.", "\x07F55B5B[AnoX] \x07FFFFFF");
			}
			case 6:
			{
				PrintToChatAll("%s현재 노래신청을 받고 있습니다. 도움말을 참고하세요!", "\x07FF00C3[AXMP] \x07FFFFFF");
			}
			case 7:
			{
				PrintToChatAll("%s볼륨조절에 관한 설명은 도움말에 있습니다. 제발 도움말을 읽어주세요.", "\x07FF00C3[AXMP] \x07FFFFFF");
				ADtimer = 0;
			}
			default:
			{
			}
		}
	}
	return Action:0;
}

public Action:anoxinfo(client, args)
{
	new Handle:InfoMenu = CreateMenu(InfoMenuh, MenuAction:28);
	SetMenuTitle(InfoMenu, "[AnoX]Core (Ver %s)\nLast Realese: %s\n=================", "2.5", "2016-08-03");
	AddMenuItem(InfoMenu, "m2", "어녹스 공식 그룹", 0);
	AddMenuItem(InfoMenu, "m3", "접속중인 팀원", 0);
	AddMenuItem(InfoMenu, "m4", "고유번호 확인", 0);
	AddMenuItem(InfoMenu, "m5", "뮤직 플레이어", 0);
	SetMenuExitButton(InfoMenu, true);
	DisplayMenu(InfoMenu, client, 0);
	return Action:0;
}

public InfoMenuh(Handle:InfoMenu, MenuAction:action, client, Position)
{
	if (action == MenuAction:4)
	{
		decl String:Item[20];
		GetMenuItem(InfoMenu, Position, Item, 20, 0, "", 0);
		if (StrEqual(Item, "m2", true))
		{
			ShowMOTDPanel(client, "어녹스 그룹", "http://steamcommunity.com/groups/anoxplugin", 2);
		}
		else
		{
			if (StrEqual(Item, "m3", true))
			{
				OnlineTeamMate(client);
			}
			if (StrEqual(Item, "m4", true))
			{
				DisplayIdMenu(client);
			}
			if (StrEqual(Item, "m5", true))
			{
				DisplayMusicMenu(client);
				PrintToChat(client, "%s볼륨설정 및 반복재생 설정은 도움말을 참고해주세요.", "\x07FF00C3[AXMP] \x07FFFFFF");
			}
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(InfoMenu);
		}
	}
	return 0;
}

public OnlineTeamMate(client)
{
	decl String:TMN[32];
	new Handle:OnlineMenu = CreateMenu(OnlineMenuh, MenuAction:28);
	SetMenuTitle(OnlineMenu, "접속중인 어녹스 팀원");
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientInGame(i) && IsTeamMate(i))
		{
			GetClientName(i, TMN, 32);
			AddMenuItem(OnlineMenu, TMN, TMN, 0);
		}
		i++;
	}
	SetMenuExitButton(OnlineMenu, true);
	DisplayMenu(OnlineMenu, client, 60);
	return 0;
}

public OnlineMenuh(Handle:OnlineMenu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(OnlineMenu);
	}
	return 0;
}

public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
	new String:authid[32];
	GetClientAuthString(author, authid, 32, true);
	new MaxMessageLength = 256 - strlen(name) + -5;
	if (StrEqual(authid, "STEAM_0:0:64434731", false))
	{
		Format(name, 64, "\x07FF8400%s", name);
		Format(name, 64, "\x070051FF『AnoX』%s", name);
		Format(message, MaxMessageLength, "\x0779FF4D%s", message);
	}
	else
	{
		if (StrEqual(authid, "STEAM_0:0:38235680", false))
		{
			Format(name, 64, "\x075EFFB4%s", name);
			Format(name, 64, "\x07FF0000『AnoX』%s", name);
			Format(message, MaxMessageLength, "\x0700FF08%s ♪", message);
		}
		if (StrEqual(authid, "STEAM_0:1:43524116", false))
		{
			Format(name, 64, "\x075EFFB4%s", name);
			Format(name, 64, "\x0700FFFF『AnoX』%s", name);
			Format(message, MaxMessageLength, "\x0775A5FF%s", message);
		}
		if (StrEqual(authid, "STEAM_0:0:56109191", false))
		{
			Format(name, 64, "\x075EFFB4%s", name);
			Format(name, 64, "\x0700FFFF『AnoX』%s", name);
			Format(message, MaxMessageLength, "\x0775A5FF%s", message);
		}
	}
	return Action:0;
}

public Action:Check_ID(client, args)
{
	DisplayIdMenu(client);
	return Action:0;
}

public Action:AnoX_MusicPlayerMenuOpen(client, args)
{
	DisplayMusicMenu(client);
	PrintToChat(client, "%s볼륨설정 및 반복재생 설정은 도움말을 참고해주세요.", "\x07FF00C3[AXMP] \x07FFFFFF");
	return Action:0;
}

public DisplayIdMenu(client)
{
	new Handle:idmenu = CreateMenu(idmenuh, MenuAction:28);
	SetMenuTitle(idmenu, "고유번호를 확인할 유저");
	AddTargetsToMenu(idmenu, 0, false, false);
	DisplayMenu(idmenu, client, 0);
	return 0;
}

public idmenuh(Handle:idmenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case 4:
		{
			decl String:item[32];
			new userid;
			new target;
			GetMenuItem(idmenu, param2, item, 32, 0, "", 0);
			userid = StringToInt(item, 10);
			target = GetClientOfUserId(userid);
			if (target)
			{
				decl String:name[32];
				decl String:authid[64];
				GetClientName(target, name, 32);
				GetClientAuthString(target, authid, 64, true);
				PrintToChat(param1, "%s\x07FFFF00%s\x07FFFFFF님의 고유번호는 \x0700FFFF%s\x07FFFFFF입니다.", "\x07F55B5B[AnoX] \x07FFFFFF", name, authid);
			}
			else
			{
				PrintToChat(param1, "%s해당 유저가 존재하지 않습니다.", "\x07F55B5B[AnoX] \x07FFFFFF");
			}
		}
		case 16:
		{
			CloseHandle(idmenu);
		}
		default:
		{
		}
	}
	return 0;
}

public Action:P_RELOAD(Handle:hTimer)
{
	ReloadCore();
	return Action:0;
}

public Action:P_RELOAD2(client, args)
{
	if (IsTeamMate(client))
	{
		if (args < 1)
		{
			PrintToChat(client, "%s사용법: axreload <서버커맨드>", "\x07F55B5B[AnoX] \x07FFFFFF");
			return Action:3;
		}
		decl String:arg1[264];
		GetCmdArg(1, arg1, 264);
		ServerCommand("%s", arg1);
		return Action:3;
	}
	PrintToChat(client, "%s이 커맨드에 접근하실 수 없습니다.", "\x07F55B5B[AnoX] \x07FFFFFF");
	return Action:3;
}

public Action:P_UpdateWarnSet(client, args)
{
	if (IsTeamMate(client))
	{
		if (!UpdateWarningSet)
		{
			UpdateWarningSet = true;
			PrintToChat(client, "%s업데이트 경고 활성화", "\x07F55B5B[AnoX] \x07FFFFFF");
		}
		else
		{
			UpdateWarningSet = false;
			PrintToChat(client, "%s업데이트 경고 비활성화", "\x07F55B5B[AnoX] \x07FFFFFF");
		}
	}
	else
	{
		PrintToChat(client, "%s이 커맨드에 접근하실 수 없습니다.", "\x07F55B5B[AnoX] \x07FFFFFF");
	}
	return Action:0;
}

public OnConfigsExecuted()
{
	configsExecuted = true;
	LoadSongs();
	return 0;
}

public OnClientPutInServer(client)
{
	warningShown[client] = 0;
	advertShown[client] = 0;
	capturingPlaylistName[client] = 0;
	if (playlistArray[client])
	{
		CloseHandle(playlistArray[client]);
		playlistArray[client] = 0;
	}
	return 0;
}

public OnClientCookiesCached(client)
{
	decl String:value[8];
	GetClientCookie(client, repeatCookie, value, 8);
	new var1;
	if (!StrEqual(value, "0", true) && !StrEqual(value, "1", true))
	{
		SetClientCookie(client, repeatCookie, "0");
	}
	GetClientCookie(client, shuffleCookie, value, 8);
	new var2;
	if (!StrEqual(value, "0", true) && !StrEqual(value, "1", true))
	{
		SetClientCookie(client, shuffleCookie, "1");
	}
	GetClientCookie(client, volumeCookie, value, 8);
	if (StrEqual(value, "", true))
	{
		SetClientCookie(client, volumeCookie, "30");
	}
	return 0;
}

public Event_PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new var1;
	if (advertShown[client] || !IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client))
	{
		return 0;
	}
	PrintToChat(client, "%s이 서버는 어녹스팀의 지원을 받고 있습니다. 채팅창에 \x07FFFB00!anox\x07FFFFFF를 치셔서 정보를 확인하세요.", "\x07F55B5B[AnoX] \x07FFFFFF");
	advertShown[client] = 1;
	return 0;
}

public DisplayMusicMenu(client)
{
	if (!client)
	{
		PrintToChat(client, "%s이 커맨드는 서버 내에서만 사용이 가능합니다.", "\x07FF00C3[AXMP] \x07FFFFFF");
	}
	if (!AreClientCookiesCached(client))
	{
		PrintToChat(client, "%s아직 설정이 로드되지 않았습니다. 잠시 후 다시 시도해주세요.", "\x07FF00C3[AXMP] \x07FFFFFF");
	}
	if (playlistArray[client])
	{
		NewPlaylistMenu(client, 0);
	}
	if (!songMenu)
	{
		PrintToChat(client, "%s웹서버에 노래가 없습니다.", "\x07FF00C3[AXMP] \x07FFFFFF");
	}
	decl String:value[8];
	decl String:repeat[32];
	GetClientCookie(client, repeatCookie, value, 8);
	if (StrEqual(value, "1", true))
	{
		Format(repeat, 32, "노래반복 ON");
	}
	else
	{
		Format(repeat, 32, "노래반복 OFF");
	}
	new Handle:menu = CreateMenu(MusicMenuh, MenuAction:28);
	SetMenuTitle(menu, "[AXMP] AnoX Music Player\n==================");
	AddMenuItem(menu, "help", "도움말(노래신청)", 0);
	AddMenuItem(menu, "songList", "노래 목록", 0);
	AddMenuItem(menu, "shuffleAll", "전체 셔플재생", 1);
	AddMenuItem(menu, "playlists", "내 플레이리스트", 1);
	AddMenuItem(menu, "random", "랜덤 재생", 0);
	AddMenuItem(menu, "stopMusic", "플레이어 종료", 0);
	AddMenuItem(menu, "repeat", repeat, 0);
	decl String:volume[64];
	GetClientCookie(client, volumeCookie, value, 8);
	Format(volume, 64, "볼륨: %d", StringToInt(value, 10));
	AddMenuItem(menu, "volume", volume, 0);
	SetMenuPagination(menu, 0);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public MusicMenuh(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction:4)
	{
		decl String:selection[16];
		GetMenuItem(menu, param, selection, 16, 0, "", 0);
		if (StrEqual(selection, "repeat", true))
		{
			decl String:value[8];
			GetClientCookie(client, repeatCookie, value, 8);
			if (StrEqual(value, "1", true))
			{
				SetClientCookie(client, repeatCookie, "0");
			}
			else
			{
				SetClientCookie(client, repeatCookie, "1");
			}
			DisplayMusicMenu(client);
		}
		else
		{
			if (StrEqual(selection, "volume", true))
			{
				decl String:value[8];
				GetClientCookie(client, volumeCookie, value, 8);
				new vol = StringToInt(value, 10) + 5;
				if (vol > 100)
				{
					vol = 5;
				}
				IntToString(vol, value, 8);
				SetClientCookie(client, volumeCookie, value);
				DisplayMusicMenu(client);
			}
			if (StrEqual(selection, "songList", true))
			{
				DisplayMenu(songMenu, client, 0);
			}
			if (StrEqual(selection, "playlists", true))
			{
				ShowPlaylistMenu(client);
			}
			if (StrEqual(selection, "shuffleAll", true))
			{
				PlaySong(client, -2, false, false);
			}
			if (StrEqual(selection, "stopMusic", true))
			{
				OpenURL(client, -1, 1, false, 100);
			}
			if (StrEqual(selection, "random", true))
			{
				PlaySong(client, GetArrayCell(songIds, GetRandomInt(0, GetArraySize(songIds) + -1), 0, false), false, false);
			}
			if (StrEqual(selection, "help", true))
			{
				ShowMOTDPanel(client, "Help", "http://webdj.ltmlab.net/help.php", 2);
			}
		}
	}
	if (action == MenuAction:16)
	{
		CloseHandle(menu);
	}
	return 0;
}

ShowPlaylistMenu(client)
{
	decl String:shuffle[32];
	GetClientCookie(client, shuffleCookie, shuffle, 32);
	if (StrEqual(shuffle, "0", true))
	{
		Format(shuffle, 32, "[셔플 재생 OFF]");
	}
	else
	{
		Format(shuffle, 32, "[셔플 재생 ON]");
	}
	decl String:auth[32];
	decl String:steamID[32];
	decl String:playlistID[8];
	decl String:playlistName[36];
	GetClientAuthString(client, auth, 32, true);
	new Handle:menu = CreateMenu(Handler_Playlist, MenuAction:28);
	SetMenuTitle(menu, "내 플레이리스트");
	AddMenuItem(menu, "newplaylist", "[플레이리스트 생성]", 0);
	new var1;
	if (FindStringInArray(playlistSteamIds, auth) != -1)
	{
		var1 = 0;
	}
	else
	{
		var1 = 1;
	}
	AddMenuItem(menu, "deleteplaylist", "[플레이리스트 삭제]", var1);
	AddMenuItem(menu, "shuffle", shuffle, 0);
	new i;
	while (GetArraySize(playlistSteamIds) > i)
	{
		GetArrayString(playlistSteamIds, i, steamID, 32);
		if (StrEqual(steamID, auth, true))
		{
			Format(playlistID, 8, "%i", GetArrayCell(playlistIds, i, 0, false));
			GetArrayString(playlistNames, i, playlistName, 33);
			AddMenuItem(menu, playlistID, playlistName, 0);
		}
		i++;
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public Handler_Playlist(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(menu);
	}
	if (action == MenuAction:8)
	{
		if (param == -6)
		{
			DisplayMusicMenu(client);
			return 0;
		}
	}
	if (action != MenuAction:4)
	{
		return 0;
	}
	decl String:selection[16];
	GetMenuItem(menu, param, selection, 16, 0, "", 0);
	if (StrEqual(selection, "newplaylist", true))
	{
		capturingPlaylistName[client] = 1;
		SetHudTextParams(-1.0, 0.3, 1.0E9, 0, 255, 234, 255, 0, 6.0, 0.1, 0.2);
		ShowSyncHudText(client, hudText, "생성할 플레이 리스트의 이름을 채팅창에\n입력하신 후 엔터키를 눌러주세요");
		return 0;
	}
	if (StrEqual(selection, "deleteplaylist", true))
	{
		new Handle:menu2 = CreateMenu(Handler_DeletePlaylist, MenuAction:28);
		SetMenuTitle(menu2, "삭제할 플레이리스트를 선택하세요");
		decl String:auth[32];
		decl String:steamID[32];
		decl String:playlistID[8];
		decl String:playlistName[36];
		GetClientAuthString(client, auth, 32, true);
		new i;
		while (GetArraySize(playlistSteamIds) > i)
		{
			GetArrayString(playlistSteamIds, i, steamID, 32);
			if (StrEqual(steamID, auth, true))
			{
				Format(playlistID, 8, "%i", GetArrayCell(playlistIds, i, 0, false));
				GetArrayString(playlistNames, i, playlistName, 33);
				AddMenuItem(menu2, playlistID, playlistName, 0);
			}
			i++;
		}
		SetMenuExitBackButton(menu2, true);
		DisplayMenu(menu2, client, 0);
		return 0;
	}
	if (StrEqual(selection, "shuffle", true))
	{
		decl String:shuffle[8];
		GetClientCookie(client, shuffleCookie, shuffle, 8);
		if (StrEqual(shuffle, "1", true))
		{
			SetClientCookie(client, shuffleCookie, "0");
		}
		else
		{
			SetClientCookie(client, shuffleCookie, "1");
		}
		ShowPlaylistMenu(client);
		return 0;
	}
	PlaySong(client, StringToInt(selection, 10), true, false);
	return 0;
}

public Handler_DeletePlaylist(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(menu);
	}
	if (action == MenuAction:8)
	{
		if (param == -6)
		{
			ShowPlaylistMenu(client);
			return 0;
		}
	}
	if (action != MenuAction:4)
	{
		return 0;
	}
	decl String:selection[16];
	decl String:name[36];
	GetMenuItem(menu, param, selection, 16, 0, "", 0);
	new id = FindValueInArray(playlistIds, StringToInt(selection, 10));
	GetArrayString(playlistNames, id, name, 33);
	new Handle:menu2 = CreateMenu(Handler_ConfirmDelete, MenuAction:28);
	SetMenuTitle(menu2, "플레이리스트(%s)를 정말로 지우시겠습니까?\n한번 삭제시 복구가 불가능합니다", name);
	AddMenuItem(menu2, selection, "삭제", 0);
	AddMenuItem(menu2, "no", "취소", 0);
	SetMenuExitButton(menu2, false);
	DisplayMenu(menu2, client, 0);
	return 0;
}

public Handler_ConfirmDelete(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(menu);
	}
	if (action != MenuAction:4)
	{
		return 0;
	}
	decl String:selection[16];
	GetMenuItem(menu, param, selection, 16, 0, "", 0);
	if (StrEqual(selection, "no", true))
	{
		return 0;
	}
	new Handle:socket = SocketCreate(SocketType:1, OnPostError);
	decl String:request[2048];
	decl String:postdata[2048];
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, any:2);
	Format(postdata, 2048, "auth=07194be05c94565a951d2a044b6f9162&id=%s&method=2", selection);
	Format(request, 2048, "POST http://webdj.ltmlab.net/playlist.php HTTP/1.1\r\nHost: webdj.ltmlab.net\r\nContent-Length: %i\r\nContent-Type: application/x-www-form-urlencoded\r\nConnection: close\r\n\r\n%s", strlen(postdata), postdata);
	WritePackString(pack, request);
	SocketSetArg(socket, pack);
	SocketConnect(socket, OnPostConnected, OnPostReceive, OnPostDisconnected, "webdj.ltmlab.net", 80);
	return 0;
}

public Action:Command_Say(client, String:command[], argc)
{
	new var1;
	if (!capturingPlaylistName[client] || IsChatTrigger())
	{
		return Action:0;
	}
	decl String:name[36];
	GetCmdArgString(name, 33);
	TrimString(name);
	StripQuotes(name);
	new pos = FindStringInArray(playlistNames, name);
	if (pos != -1)
	{
		decl String:auth[32];
		decl String:steamID[32];
		GetClientAuthString(client, auth, 32, true);
		GetArrayString(playlistSteamIds, pos, steamID, 32);
		if (StrEqual(auth, steamID, true))
		{
			SetHudTextParams(-1.0, 0.3, 1.0E9, 0, 255, 234, 255, 0, 6.0, 0.1, 0.2);
			ShowSyncHudText(client, hudText, "생성할 플레이 리스트의 이름을 채팅창에\n입력하신 후 엔터키를 눌러주세요\n\n\n이미 존재하는 플레이리스트 입니다");
			return Action:3;
		}
	}
	capturingPlaylistName[client] = 0;
	SetHudTextParams(0.0, 0.0, 0.1, 0, 0, 0, 0, 0, 6.0, 0.1, 0.2);
	ShowSyncHudText(client, hudText, "");
	playlistArray[client] = CreateArray(1, 0);
	strcopy(newPlaylistName[client], 33, name);
	NewPlaylistMenu(client, 0);
	return Action:3;
}

NewPlaylistMenu(client, position)
{
	new Handle:menu = CreateMenu(Handler_NewPlaylist, MenuAction:28);
	SetMenuTitle(menu, "새 플레이리스트: %s (%i곡)\n마치려면 첫 페이지로 이동하세요", newPlaylistName[client], GetArraySize(playlistArray[client]));
	new var1;
	if (GetArraySize(playlistArray[client]) > 0)
	{
		var1 = 0;
	}
	else
	{
		var1 = 1;
	}
	AddMenuItem(menu, "done", "[플레이리스트 생성]", var1);
	AddMenuItem(menu, "cancel", "[취소]", 0);
	decl String:title[36];
	decl String:id[4];
	new i;
	while (GetArraySize(songIds) > i)
	{
		Format(id, 4, "%i", GetArrayCell(songIds, i, 0, false));
		GetArrayString(songTitles, i, title, 35);
		if (FindValueInArray(playlistArray[client], GetArrayCell(songIds, i, 0, false)) != -1)
		{
			Format(title, 35, "[#%i] %s", FindValueInArray(playlistArray[client], GetArrayCell(songIds, i, 0, false)) + 1, title);
		}
		AddMenuItem(menu, id, title, 0);
		i++;
	}
	SetMenuExitButton(menu, false);
	DisplayMenuAtItem(menu, client, position, 0);
	return 0;
}

public Handler_NewPlaylist(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction:16)
	{
		CloseHandle(menu);
	}
	if (action != MenuAction:4)
	{
		return 0;
	}
	decl String:selection[8];
	GetMenuItem(menu, param, selection, 8, 0, "", 0);
	if (StrEqual(selection, "done", true))
	{
		decl String:songs[1024];
		new bool:first = 1;
		new i;
		while (GetArraySize(playlistArray[client]) > i)
		{
			if (first)
			{
				first = false;
				Format(songs, 1024, "%i", GetArrayCell(playlistArray[client], i, 0, false));
			}
			else
			{
				Format(songs, 1024, "%s,%i", songs, GetArrayCell(playlistArray[client], i, 0, false));
			}
			i++;
		}
		new Handle:socket = SocketCreate(SocketType:1, OnPostError);
		decl String:request[2048];
		decl String:postdata[2048];
		decl String:auth[32];
		GetClientAuthString(client, auth, 32, true);
		new Handle:pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackCell(pack, any:1);
		Format(postdata, 2048, "auth=07194be05c94565a951d2a044b6f9162&name=%s&steamid=%s&method=1&songs=%s", newPlaylistName[client], auth, songs);
		Format(request, 2048, "POST http://webdj.ltmlab.net/playlist.php HTTP/1.1\r\nHost: webdj.ltmlab.net\r\nContent-Length: %i\r\nContent-Type: application/x-www-form-urlencoded\r\nConnection: close\r\n\r\n%s", strlen(postdata), postdata);
		WritePackString(pack, request);
		SocketSetArg(socket, pack);
		SocketConnect(socket, OnPostConnected, OnPostReceive, OnPostDisconnected, "webdj.ltmlab.net", 80);
		CloseHandle(playlistArray[client]);
		playlistArray[client] = 0;
		return 0;
	}
	if (StrEqual(selection, "cancel", true))
	{
		CloseHandle(playlistArray[client]);
		playlistArray[client] = 0;
		PrintToChat(client, "%s플레이리스트 생성을 취소하였습니다.", "\x07FF00C3[AXMP] \x07FFFFFF");
		return 0;
	}
	if (FindValueInArray(playlistArray[client], StringToInt(selection, 10)) != -1)
	{
		RemoveFromArray(playlistArray[client], FindValueInArray(playlistArray[client], StringToInt(selection, 10)));
	}
	else
	{
		PushArrayCell(playlistArray[client], StringToInt(selection, 10));
	}
	NewPlaylistMenu(client, GetMenuSelectionPosition());
	return 0;
}

public OnPostConnected(Handle:socket, any:pack)
{
	ResetPack(pack, false);
	ReadPackCell(pack);
	ReadPackCell(pack);
	decl String:request[2048];
	ReadPackString(pack, request, 2048);
	SocketSend(socket, request, -1);
	return 0;
}

public OnPostReceive(Handle:socket, String:receiveData[], dataSize, any:pack)
{
	new var1;
	if (StrContains(receiveData, "Bad auth token", false) == -1 && StrContains(receiveData, "Invalid data", false) == -1)
	{
		ResetPack(pack, false);
		new client = ReadPackCell(pack);
		new method = ReadPackCell(pack);
		if (method == 1)
		{
			PrintToChat(client, "%s플레이리스트를 추가하는데에 에러가 발생하였습니다. 웹서버 관리자에게 문의하세요.", "\x07FF00C3[AXMP] \x07FFFFFF");
		}
		else
		{
			if (method == 2)
			{
				PrintToChat(client, "%s플레이리스트를 삭제하는데에 에러가 발생하였습니다. 웹서버 관리자에게 문의하세요.", "\x07FF00C3[AXMP] \x07FFFFFF");
			}
			PrintToChat(client, "%s플레이리스트를 수정하는데에 에러가 발생하였습니다. 웹서버 관리자에게 문의하세요.", "\x07FF00C3[AXMP] \x07FFFFFF");
		}
	}
	if (StrContains(receiveData, "Bad auth token", false) != -1)
	{
		LogError("Bad auth token");
	}
	else
	{
		if (StrContains(receiveData, "Invalid data", false) != -1)
		{
			LogError("Invalid data");
		}
	}
	return 0;
}

public OnPostDisconnected(Handle:socket, any:pack)
{
	ResetPack(pack, false);
	new client = ReadPackCell(pack);
	new method = ReadPackCell(pack);
	if (method == 1)
	{
		PrintToChat(client, "%s플레이리스트가 성공적으로 추가 되었습니다.", "\x07FF00C3[AXMP] \x07FFFFFF");
	}
	else
	{
		if (method == 2)
		{
			PrintToChat(client, "%s플레이리스트가 성공적으로 삭제 되었습니다.", "\x07FF00C3[AXMP] \x07FFFFFF");
		}
		PrintToChat(client, "%s플레이리스트가 성공적으로 수정 되었습니다.", "\x07FF00C3[AXMP] \x07FFFFFF");
	}
	LoadSongs();
	CloseHandle(socket);
	CloseHandle(pack);
	return 0;
}

public OnPostError(Handle:socket, errorType, errorNum, any:pack)
{
	ResetPack(pack, false);
	new client = ReadPackCell(pack);
	new method = ReadPackCell(pack);
	if (method == 1)
	{
		PrintToChat(client, "%s플레이리스트를 추가하는데에 에러가 발생하였습니다. 웹서버 관리자에게 문의하세요.", "\x07FF00C3[AXMP] \x07FFFFFF");
	}
	else
	{
		if (method == 2)
		{
			PrintToChat(client, "%s플레이리스트를 삭제하는데에 에러가 발생하였습니다. 웹서버 관리자에게 문의하세요.", "\x07FF00C3[AXMP] \x07FFFFFF");
		}
		PrintToChat(client, "%s플레이리스트를 수정하는데에 에러가 발생하였습니다. 웹서버 관리자에게 문의하세요.", "\x07FF00C3[AXMP] \x07FFFFFF");
	}
	CloseHandle(pack);
	CloseHandle(socket);
	LogError("Post socket error %i (error number %i)", errorType, errorNum);
	return 0;
}

public Action:Command_ReloadSongs(client, args)
{
	LoadSongs();
	ReplyToCommand(client, "%s노래 리스트가 새로고침 되었습니다.", "\x07FF00C3[AXMP] \x07FFFFFF");
	return Action:3;
}

LoadSongs()
{
	ClearArray(songTitles);
	ClearArray(songIds);
	ClearArray(playlistIds);
	ClearArray(playlistNames);
	ClearArray(playlistSteamIds);
	ClearArray(playlistSongs);
	if (songMenu)
	{
		CloseHandle(songMenu);
	}
	songMenu = MissingTAG:0;
	new Handle:socket = SocketCreate(SocketType:1, OnSocketError);
	decl String:path[128];
	decl String:request[256];
	BuildPath(PathType:0, path, 128, "data/AnoxDJ.txt");
	new Handle:pack = CreateDataPack();
	new Handle:file = OpenFile(path, "wb");
	WritePackCell(pack, file);
	Format(request, 256, "GET http://webdj.ltmlab.net/index.php?keyvalues=07194be05c94565a951d2a044b6f9162 HTTP/1.0\r\nHost: webdj.ltmlab.net\r\nConnection: close\r\nPragma: no-cache\r\nCache-Control: no-cache\r\n\r\n");
	WritePackString(pack, request);
	SocketSetArg(socket, pack);
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "webdj.ltmlab.net", 80);
	return 0;
}

public OnSocketConnected(Handle:socket, any:pack)
{
	ResetPack(pack, false);
	decl String:request[256];
	ReadPackCell(pack);
	ReadPackString(pack, request, 256);
	SocketSend(socket, request, -1);
	return 0;
}

public OnSocketReceive(Handle:socket, String:data[], size, any:pack)
{
	ResetPack(pack, false);
	new Handle:file = ReadPackCell(pack);
	new pos = StrContains(data, "\r\n\r\n", true);
	new var1;
	if (pos != -1)
	{
		var1 = pos + 4;
	}
	else
	{
		var1 = 0;
	}
	pos = var1;
	new i = pos;
	while (i < size)
	{
		WriteFileCell(file, data[i], 1);
		i++;
	}
	return 0;
}

public OnSocketDisconnected(Handle:socket, any:pack)
{
	ResetPack(pack, false);
	CloseHandle(ReadPackCell(pack));
	CloseHandle(pack);
	CloseHandle(socket);
	decl String:path[128];
	decl String:line[52];
	BuildPath(PathType:0, path, 128, "data/AnoxDJ.txt");
	new Handle:file = OpenFile(path, "r");
	ReadFileLine(file, line, 50);
	CloseHandle(file);
	if (StrEqual(line, "Bad auth token", false))
	{
		SetFailState("Invalid auth token given");
		return 0;
	}
	if (StrEqual(line, "No songs", false))
	{
		LogMessage("There were no songs to load");
		return 0;
	}
	songMenu = CreateMenu(Handler_PlaySong, MenuAction:28);
	SetMenuTitle(songMenu, "노래를 선택하세요");
	new Handle:kv = CreateKeyValues("AnoxDJ", "", "");
	if (!FileToKeyValues(kv, path))
	{
		SetFailState("An unknown error occurred.");
		return 0;
	}
	KvJumpToKey(kv, "Songs", false);
	if (!KvGotoFirstSubKey(kv, true))
	{
		LogError("There are no songs, even though the web interface said there were!");
		CloseHandle(kv);
		return 0;
	}
	decl String:songTitle[60];
	decl String:songId[8];
	decl String:index[8];
	KvGetString(kv, "title", songTitle, 60, "");
	KvGetString(kv, "id", songId, 5, "");
	PushArrayString(songTitles, songTitle);
	PushArrayCell(songIds, StringToInt(songId, 10));
	IntToString(GetArraySize(songIds) + -1, index, 5);
	AddMenuItem(songMenu, index, songTitle, 0);
	while (KvGotoNextKey(kv, true))
	{
		KvGetString(kv, "title", songTitle, 60, "");
		KvGetString(kv, "id", songId, 5, "");
		PushArrayString(songTitles, songTitle);
		PushArrayCell(songIds, StringToInt(songId, 10));
		IntToString(GetArraySize(songIds) + -1, index, 5);
		AddMenuItem(songMenu, index, songTitle, 0);
	}
	SetMenuExitBackButton(songMenu, true);
	KvRewind(kv);
	KvJumpToKey(kv, "Playlists", false);
	if (!KvGotoFirstSubKey(kv, true))
	{
		CloseHandle(kv);
		return 0;
	}
	decl String:name[36];
	decl String:steamID[36];
	decl String:songs[1024];
	do {
		PushArrayCell(playlistIds, KvGetNum(kv, "id", 0));
		KvGetString(kv, "name", name, 33, "");
		KvGetString(kv, "steamid", steamID, 33, "");
		KvGetString(kv, "songs", songs, 1024, "");
		PushArrayString(playlistNames, name);
		PushArrayString(playlistSteamIds, steamID);
		PushArrayString(playlistSongs, songs);
	} while (KvGotoNextKey(kv, true));
	CloseHandle(kv);
	return 0;
}

public OnSocketError(Handle:socket, errorType, errorNum, any:pack)
{
	ResetPack(pack, false);
	CloseHandle(ReadPackCell(pack));
	CloseHandle(pack);
	CloseHandle(socket);
	decl String:error[256];
	FormatEx(error, 256, "Socket error: %d (Error code %d)", errorType, errorNum);
	return 0;
}

public Handler_PlaySong(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction:4)
	{
		decl String:songIndex[8];
		GetMenuItem(menu, param, songIndex, 5, 0, "", 0);
		PlaySong(client, StringToInt(songIndex, 10), false, false);
	}
	if (action == MenuAction:8)
	{
		if (param == -6)
		{
			DisplayMusicMenu(client);
			return 0;
		}
	}
	return 0;
}

PlaySong(client, index, bool:playlist, bool:silent)
{
	new String:Name[64];
	GetClientName(client, Name, 64);
	if (GetClientTeam(client))
	{
		if (!warningShown[client])
		{
			PrintHintText(client, "꼭 도움말을 한번 읽어주시기 바랍니다.");
			PrintToChat(client, "%s꼭 도움말을 한번 읽어보시고 사용해주시기 바랍니다. 뮤직플레이어 메뉴에서 1번 버튼입니다.", "\x07FF00C3[AXMP] \x07FFFFFF");
			warningShown[client] = 1;
		}
		PrintToChat(client, "%s노래 종료 및 도움말 보기도 뮤직플레이어 메뉴에서 가능합니다.", "\x07FF00C3[AXMP] \x07FFFFFF");
		if (index == -2)
		{
			if (!silent)
			{
				PrintToChatAll("%s\x07FFFB00%s\x07FFFFFF님이 전체 셔플재생으로 음악을 듣고 계십니다!", "\x07FF00C3[AXMP] \x07FFFFFF", Name);
			}
			OpenURL(client, -2, 1, false, 100);
			return 0;
		}
		if (playlist)
		{
			if (!silent)
			{
				PrintToChatAll("%s\x07FFFB00%s\x07FFFFFF님이 개인 플레이리스트로 음악을 듣고 계십니다!", "\x07FF00C3[AXMP] \x07FFFFFF", Name);
			}
			decl String:shuffle[8];
			decl String:volume[8];
			GetClientCookie(client, shuffleCookie, shuffle, 8);
			GetClientCookie(client, volumeCookie, volume, 8);
			OpenURL(client, index, StringToInt(shuffle, 10), true, StringToInt(volume, 10));
			return 0;
		}
		new id = GetArrayCell(songIds, index, 0, false);
		decl String:title[60];
		GetArrayString(songTitles, index, title, 60);
		if (!silent)
		{
			PrintToChatAll("%s\x07FFFB00%s\x07FFFFFF님이 \"\x07FFB536%s\x07FFFFFF\"를 듣고 계십니다!", "\x07FF00C3[AXMP] \x07FFFFFF", Name, title);
		}
		decl String:repeat[8];
		decl String:volume[8];
		GetClientCookie(client, repeatCookie, repeat, 8);
		GetClientCookie(client, volumeCookie, volume, 8);
		OpenURL(client, id, StringToInt(repeat, 10), false, StringToInt(volume, 10));
		Call_StartForward(forwardOnStartListen);
		Call_PushCell(client);
		Call_PushString(title);
		Call_Finish(0);
		return 0;
	}
	return 0;
}

OpenURL(client, songId, repeat, bool:playlist, volume)
{
	new Handle:panel = CreateKeyValues("data", "", "");
	KvSetString(panel, "title", "AnoxDJ");
	KvSetNum(panel, "type", 2);
	if (songId == -1)
	{
		KvSetString(panel, "msg", "http://ltmlab.net");
		ShowVGUIPanel(client, "info", panel, false);
	}
	else
	{
		decl String:url[256];
		if (songId == -2)
		{
			KvSetString(panel, "msg", "http://webdj.ltmlab.net/shuffle.php");
			ShowVGUIPanel(client, "info", panel, false);
		}
		else
		{
			if (!playlist)
			{
				Format(url, 256, "http://webdj.ltmlab.net/index.php?play=%i&repeat=%i&volume=%i", songId, repeat, volume);
				KvSetString(panel, "msg", url);
				ShowVGUIPanel(client, "info", panel, false);
			}
			Format(url, 256, "http://webdj.ltmlab.net/playlist.php?id=%i&shuffle=%i&volume=%i", songId, repeat, volume);
			KvSetString(panel, "msg", url);
			ShowVGUIPanel(client, "info", panel, false);
		}
	}
	CloseHandle(panel);
	return 0;
}

