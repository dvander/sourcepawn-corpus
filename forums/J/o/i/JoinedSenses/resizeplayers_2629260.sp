#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#include <tf2>
#define REQUIRE_EXTENSIONS
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.6.0"
#define SELF_ADMIN_FLAG ADMFLAG_GENERIC
#define TARGET_ADMIN_FLAG ADMFLAG_CHEATS
#define JOIN_ADMIN_FLAG ADMFLAG_CHEATS
#define CHAT_TAG "\x05[SM]\x01 "
#define CONSOLE_TAG "[SM] "
#define DEFAULT_FALLBACK "0.4"
#define DEFAULT_HEAD_FALLBACK "2.5"
#define DEFAULT_TORSO_FALLBACK "2.5"
#define DEFAULT_HANDS_FALLBACK "2.5"

public Plugin myinfo = {
	name = "Resize Players",
	author = "11530",
	description = "Tiny!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

enum {
	  ResizeType_Generic
	, ResizeType_Head
	, ResizeType_Torso
	, ResizeType_Hands
	, ResizeTypes
}

char
	  g_szDefault[ResizeTypes][8]
	, g_szBound[ResizeTypes][2][8]
	, g_szMenuItems[ResizeTypes][256]
	, g_szClientLastScale[ResizeTypes][MAXPLAYERS+1][8]
	, g_szClientCurrentScale[ResizeTypes][MAXPLAYERS+1][8];
float
	  g_fBound[ResizeTypes][2]
	, g_fDefaultResize[ResizeTypes]
	, g_fClientLastScale[ResizeTypes][MAXPLAYERS+1]
	, g_fClientCurrentScale[ResizeTypes][MAXPLAYERS+1];
Handle
	  g_hClientTimer[ResizeTypes][MAXPLAYERS+1]
	, g_hGetMaxHealth;
Menu
	  g_hMenu[ResizeTypes];
ConVar
	  g_hBound[ResizeTypes];
bool
	  g_bIsAvailable[ResizeTypes]
	, g_bIsTF2
	, g_bLateLoaded
	, g_bCustomDmgAvailable
	, g_bHitboxAvailable
	, g_bEnabled
	, g_bBackstab;
int
	  g_iLastResize[ResizeTypes][MAXPLAYERS+1]
	, g_iMenu
	, g_iUnstick
	, g_iVoicesChanged
	, g_iOnJoin
	, g_iDamage
	, g_iNotify
	, g_iLogging
	, g_iCooldown
	, g_iSteps;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoaded = late;
	return APLRes_Success;
}

public void OnPluginStart() {
	CreateConVar("sm_resize_version", PLUGIN_VERSION, "\"Resize Players\" version.", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY).SetString(PLUGIN_VERSION);

	ConVar hEnabled = CreateConVar("sm_resize_enabled", "1", "0 = Disable plugin, 1 = Enable plugin.", FCVAR_NONE);
	hEnabled.AddChangeHook(ConVarEnabledChanged);
	g_bEnabled = hEnabled.BoolValue;

	ConVar hDefaultResize = CreateConVar("sm_resize_defaultresize", "0.4", "Default scale of players when resized.", FCVAR_NONE, true, 0.0);
	hDefaultResize.AddChangeHook(ConVarScaleChanged);
	hDefaultResize.GetString(g_szDefault[ResizeType_Generic], sizeof(g_szDefault[]));
	g_fDefaultResize[ResizeType_Generic] = StringToFloat(g_szDefault[ResizeType_Generic]);

	ConVar hDefaultHeadResize = CreateConVar("sm_resize_defaultheadresize", "2.5", "Default scale of players' heads when resized.", FCVAR_NONE);
	hDefaultHeadResize.AddChangeHook(ConVarHeadScaleChanged);
	hDefaultHeadResize.GetString(g_szDefault[ResizeType_Head], sizeof(g_szDefault[]));
	g_fDefaultResize[ResizeType_Head] = StringToFloat(g_szDefault[ResizeType_Head]);

	ConVar hDefaultTorsoResize = CreateConVar("sm_resize_defaulttorsoresize", "2.5", "Default scale of players' torsos when resized.", FCVAR_NONE);
	hDefaultTorsoResize.AddChangeHook(ConVarTorsoScaleChanged);
	hDefaultTorsoResize.GetString(g_szDefault[ResizeType_Torso], sizeof(g_szDefault[]));
	g_fDefaultResize[ResizeType_Torso] = StringToFloat(g_szDefault[ResizeType_Torso]);

	ConVar hDefaultHandsResize = CreateConVar("sm_resize_defaulthandsresize", "2.5", "Default scale of players' hands when resized.", FCVAR_NONE);
	hDefaultHandsResize.AddChangeHook(ConVarHandScaleChanged);
	hDefaultHandsResize.GetString(g_szDefault[ResizeType_Hands], sizeof(g_szDefault[]));
	g_fDefaultResize[ResizeType_Hands] = StringToFloat(g_szDefault[ResizeType_Hands]);

	ConVar hOnJoin = CreateConVar("sm_resize_onjoin", "0", "Add values to alter size upon joining, 0 = Disable, 1 = Admin only, 2 = Resize body, 4 = Resize head, 8 = Resize torso, 16 = Resize hands.", FCVAR_NONE);
	hOnJoin.AddChangeHook(ConVarOnJoinChanged);
	g_iOnJoin = hOnJoin.IntValue;

	ConVar hMenu = CreateConVar("sm_resize_menu", "1", "0 = Disable menus, 1 = Enable menus when no command parameters are given, 2 = Enable for self-commands only.", FCVAR_NONE);
	hMenu.AddChangeHook(ConVarMenuChanged);
	g_iMenu = hMenu.IntValue;

	ConVar hVoices = CreateConVar("sm_resize_voices", "0", "0 = Normal voices, 1 = Voice pitch scales with size, 2 = No low-pitched voices, 3 = No high-pitched voices.", FCVAR_NONE);
	hVoices.AddChangeHook(ConVarVoicesChanged);
	g_iVoicesChanged = hVoices.IntValue;

	ConVar hDamage = CreateConVar("sm_resize_damage", "0", "0 = Normal damage, 1 = Damage given scales with size, 2 = No up-scaled damage, 3 = No down-scaled damage.", FCVAR_NONE);
	hDamage.AddChangeHook(ConVarDamageChanged);
	g_iDamage = hDamage.IntValue;

	ConVar hSteps = CreateConVar("sm_resize_steps", "0", "0 = Normal step-size, 1 = Step-size scales with size, 2 = No up-scaled steps, 3 = No down-scaled steps.", FCVAR_NONE);
	hSteps.AddChangeHook(ConVarStepsChanged);
	g_iSteps = hSteps.IntValue;

	ConVar hNotify = CreateConVar("sm_resize_notify", "0", "0 = No notifications, 1 = Respect sm_show_activity, 2 = Notify everyone.", FCVAR_NONE);
	hNotify.AddChangeHook(ConVarNotifyChanged);
	g_iNotify = hNotify.IntValue;

	ConVar hMenuItems = CreateConVar("sm_resize_menuitems", "0.1, Smallest; 0.25, Smaller; 0.50, Small; 1.00, Normal; 1.25, Large; 1.50, Larger; 2.00, Largest", "Resize menu's items.", FCVAR_NONE);
	hMenuItems.AddChangeHook(ConVarMenuItemsChanged);
	hMenuItems.GetString(g_szMenuItems[ResizeType_Generic], sizeof(g_szMenuItems[]));

	ConVar hMenuHeadItems = CreateConVar("sm_resize_headmenuitems", "0.50, Smallest; 0.75, Small; 1.00, Normal; 2.00, Large; 3.00, Largest", "Head resize menu's items.", FCVAR_NONE);
	hMenuHeadItems.AddChangeHook(ConVarMenuHeadItemsChanged);
	hMenuHeadItems.GetString(g_szMenuItems[ResizeType_Head], sizeof(g_szMenuItems[]));

	ConVar hMenuTorsoItems = CreateConVar("sm_resize_torsomenuitems", "0.50, Smallest; 0.75, Small; 1.00, Normal; 2.00, Large; 3.00, Largest", "Torso resize menu's items.", FCVAR_NONE);
	hMenuTorsoItems.AddChangeHook(ConVarMenuTorsoItemsChanged);
	hMenuTorsoItems.GetString(g_szMenuItems[ResizeType_Torso], sizeof(g_szMenuItems[]));

	ConVar hMenuHandsItems = CreateConVar("sm_resize_handsmenuitems", "0.50, Smallest; 0.75, Small; 1.00, Normal; 2.00, Large; 3.00, Largest", "Hand resize menu's items.", FCVAR_NONE);
	hMenuHandsItems.AddChangeHook(ConVarMenuHandsItemsChanged);
	hMenuHandsItems.GetString(g_szMenuItems[ResizeType_Hands], sizeof(g_szMenuItems[]));

	ConVar hLogging = CreateConVar("sm_resize_logging", "1", "0 = No logging, 1 = Log self/target resizes, 2 = Log target resizes only.", FCVAR_NONE);
	hLogging.AddChangeHook(ConVarLoggingChanged);
	g_iLogging = hLogging.IntValue;

	ConVar hBackstab = CreateConVar("sm_resize_backstab", "0", "0 = Normal backstabs, 1 = Backstab damage scales proportionally with size.", FCVAR_NONE);
	hBackstab.AddChangeHook(ConVarBackstabChanged);
	g_bBackstab = hBackstab.BoolValue;

	ConVar hUnstick = CreateConVar("sm_resize_unstick", "1", "Revert when stuck: 0 = Never, 1 = Self-resizes only, 2 = Respawns only, 3 = Self-resizes and respawns.", FCVAR_NONE);
	hUnstick.AddChangeHook(ConVarUnstickChanged);
	g_iUnstick = hUnstick.IntValue;

	ConVar hCooldown = CreateConVar("sm_resize_cooldown", "0", "Cooldown duration for those without permission to bypass (in seconds).", FCVAR_NONE, true, 0.0);
	hCooldown.AddChangeHook(ConVarCooldownChanged);
	g_iCooldown = hCooldown.IntValue;

	g_hBound[ResizeType_Generic] = CreateConVar("sm_resize_bounds", "0.1, 3.0", "Lower (optional) and upper bounds for resizing, separated with a comma.", FCVAR_NONE);
	g_hBound[ResizeType_Generic].AddChangeHook(ConVarBoundsChanged);
	ParseConVarToLimits(g_hBound[ResizeType_Generic], g_szBound[ResizeType_Generic][0], sizeof(g_szBound[][]), g_fBound[ResizeType_Generic][0], g_szBound[ResizeType_Generic][1], sizeof(g_szBound[][]), g_fBound[ResizeType_Generic][1]);

	g_hBound[ResizeType_Head] = CreateConVar("sm_resize_headbounds", "0.25, 3.0", "Lower (optional) and upper bounds for head resizing, separated with a comma.", FCVAR_NONE);
	g_hBound[ResizeType_Head].AddChangeHook(ConVarHeadBoundsChanged);
	ParseConVarToLimits(g_hBound[ResizeType_Head], g_szBound[ResizeType_Head][0], sizeof(g_szBound[][]), g_fBound[ResizeType_Head][0], g_szBound[ResizeType_Head][1], sizeof(g_szBound[][]), g_fBound[ResizeType_Head][1]);

	g_hBound[ResizeType_Torso] = CreateConVar("sm_resize_torsobounds", "0.25, 3.0", "Lower (optional) and upper bounds for torso resizing, separated with a comma.", FCVAR_NONE);
	g_hBound[ResizeType_Torso].AddChangeHook(ConVarTorsoBoundsChanged);
	ParseConVarToLimits(g_hBound[ResizeType_Torso], g_szBound[ResizeType_Torso][0], sizeof(g_szBound[][]), g_fBound[ResizeType_Torso][0], g_szBound[ResizeType_Torso][1], sizeof(g_szBound[][]), g_fBound[ResizeType_Torso][1]);

	g_hBound[ResizeType_Hands] = CreateConVar("sm_resize_handsbounds", "0.25, 3.0", "Lower (optional) and upper bounds for hand resizing, separated with a comma.", FCVAR_NONE);
	g_hBound[ResizeType_Hands].AddChangeHook(ConVarHandsBoundsChanged);
	ParseConVarToLimits(g_hBound[ResizeType_Hands], g_szBound[ResizeType_Hands][0], sizeof(g_szBound[][]), g_fBound[ResizeType_Hands][0], g_szBound[ResizeType_Hands][1], sizeof(g_szBound[][]), g_fBound[ResizeType_Hands][1]);

	char szDir[64];
	GetGameFolderName(szDir, sizeof(szDir));
	if (strcmp(szDir, "tf") == 0 || strcmp(szDir, "tf_beta") == 0) {
		g_bIsTF2 = true;
	}

	Handle hConf = LoadGameConfigFile("sdkhooks.games");
	if (hConf != null) {
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "GetMaxHealth");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hGetMaxHealth = EndPrepSDKCall();
		delete hConf;
	}

	LoadTranslations("core.phrases.txt");
	LoadTranslations("common.phrases.txt");
	AddNormalSoundHook(SoundCallback);

	g_bIsAvailable[ResizeType_Generic] = (FindSendPropInfo("CBasePlayer", "m_flModelScale") != -1);
	g_bIsAvailable[ResizeType_Head] = (FindSendPropInfo("CTFPlayer", "m_flHeadScale") != -1);
	g_bIsAvailable[ResizeType_Torso] = (FindSendPropInfo("CTFPlayer", "m_flTorsoScale") != -1);
	g_bIsAvailable[ResizeType_Hands] = (FindSendPropInfo("CTFPlayer", "m_flHandScale") != -1);
	g_bHitboxAvailable = ((FindSendPropInfo("CBasePlayer", "m_vecSpecifiedSurroundingMins") != -1) && FindSendPropInfo("CBasePlayer", "m_vecSpecifiedSurroundingMaxs") != -1);
	g_bCustomDmgAvailable = (GetFeatureStatus(FeatureType_Capability, "SDKHook_DmgCustomInOTD") == FeatureStatus_Available);

	HookEventEx("player_spawn", OnPlayerSpawn);

	RegAdminCmd("sm_resize", OnResizeCmd, TARGET_ADMIN_FLAG, "Toggles a client's size.");
	RegAdminCmd("sm_resizeme", OnResizeMeCmd, SELF_ADMIN_FLAG, "Toggles a client's size.");
	RegAdminCmd("sm_resizehead", OnResizeHeadCmd, TARGET_ADMIN_FLAG, "Toggles a client's head size.");
	RegAdminCmd("sm_resizemyhead", OnResizeMyHeadCmd, SELF_ADMIN_FLAG, "Toggles a client's head size.");

	RegAdminCmd("sm_resizetorso", OnResizeTorsoCmd, TARGET_ADMIN_FLAG, "Toggles a client's torso size.");
	RegAdminCmd("sm_resizemytorso", OnResizeMyTorsoCmd, SELF_ADMIN_FLAG, "Toggles a client's torso size.");
	RegAdminCmd("sm_resizehands", OnResizeHandsCmd, TARGET_ADMIN_FLAG, "Toggles a client's hand size.");
	RegAdminCmd("sm_resizemyhands", OnResizeMyHandsCmd, SELF_ADMIN_FLAG, "Toggles a client's hand size.");

	RegAdminCmd("sm_resizereset", OnResetCmd, TARGET_ADMIN_FLAG, "Resets a client's size.");
	RegAdminCmd("sm_resizeresetme", OnResetMeCmd, SELF_ADMIN_FLAG, "Resets a client's size.");

	AutoExecConfig();

	if (g_bLateLoaded) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsClientReplay(i) && !IsClientSourceTV(i)) {
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}

	for (int i = 0; i < sizeof(g_fClientCurrentScale); i++) {
		for (int j = 0; j < sizeof(g_fClientCurrentScale[]); j++) {
			g_fClientCurrentScale[i][j] = 1.0;
			g_fClientLastScale[i][j] = 1.0;
		}
	}
}

public void OnConfigsExecuted() {
	CheckDefaultValue(g_fDefaultResize[ResizeType_Generic], g_szDefault[ResizeType_Generic], sizeof(g_szDefault[]), "sm_resize_defaultresize", DEFAULT_FALLBACK);
	CheckDefaultValue(g_fDefaultResize[ResizeType_Head], g_szDefault[ResizeType_Head], sizeof(g_szDefault[]), "sm_resize_defaultheadresize", DEFAULT_HEAD_FALLBACK);
	CheckDefaultValue(g_fDefaultResize[ResizeType_Torso], g_szDefault[ResizeType_Torso], sizeof(g_szDefault[]), "sm_resize_defaulttorsoresize", DEFAULT_TORSO_FALLBACK);
	CheckDefaultValue(g_fDefaultResize[ResizeType_Hands], g_szDefault[ResizeType_Hands], sizeof(g_szDefault[]), "sm_resize_defaulthandsresize", DEFAULT_HANDS_FALLBACK);
	BuildMenus();

	for (int i = 1; i <= MaxClients; i++) {
		for (int j = 0; j < ResizeTypes; j++) {
			g_fClientLastScale[j][i] = g_fDefaultResize[j];
			strcopy(g_szClientCurrentScale[j][i], sizeof(g_szClientCurrentScale[][]), "1.0");
			strcopy(g_szClientLastScale[j][i], sizeof(g_szClientLastScale[][]), g_szDefault[j]);
		}

		if (IsClientInGame(i) && !IsClientReplay(i) && !IsClientSourceTV(i) && IsClientAuthorized(i)) {
			ReadjustInitialSize(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	if (!IsClientReplay(client) && !IsClientSourceTV(client)) {
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void OnClientPostAdminCheck(int client) {
	if (!IsClientReplay(client) && !IsClientSourceTV(client)) {
		ReadjustInitialSize(client);
	}
}

void ReadjustInitialSize(const int client, const bool bResetOnDisable = false) {
	if (g_bEnabled) {
		bool bAdminOnly = (g_iOnJoin & 1 == 1);
		char szOverrides[] = { "sm_resizejoinoverride","sm_resizeheadjoinoverride","sm_resizetorsojoinoverride","sm_resizehandsjoinoverride" };

		for (int i = 0; i < ResizeTypes; i++) {
		if (g_bIsAvailable[i] && (g_iOnJoin & (1 << (i + 1)) == (1 << (i + 1)))) {
			if (bAdminOnly && !CheckCommandAccess(client, szOverrides[i], JOIN_ADMIN_FLAG, true)) {
				continue;
			}
			StopTimer(client, i);
			ResizePlayer(i, client, g_szDefault[i]);
			}
		}
	}
	else if (bResetOnDisable) {
		for (int i = 0; i < ResizeTypes; i++) {
			StopTimer(client, i);
			if (g_bIsAvailable[i] && g_fClientCurrentScale[i][client] != 1.0) {
				ResizePlayer(i, client, "1.0");
			}
		}
	}
}

void BuildMenus() {
	ParseStringToMenu(g_hMenu[ResizeType_Generic], ResizeMenuHandler, "Choose a Size:", g_szMenuItems[ResizeType_Generic]);
	ParseStringToMenu(g_hMenu[ResizeType_Head], ResizeHeadMenuHandler, "Choose a Head Size:", g_szMenuItems[ResizeType_Head]);
	ParseStringToMenu(g_hMenu[ResizeType_Torso], ResizeTorsoMenuHandler, "Choose a Torso Size:", g_szMenuItems[ResizeType_Torso]);
	ParseStringToMenu(g_hMenu[ResizeType_Hands], ResizeHandsMenuHandler, "Choose a Hand Size:", g_szMenuItems[ResizeType_Hands]);
}

int ParseStringToMenu(Menu &hMenu, MenuHandler hCallback, char[] szTitle, const char[] szItems) {
	float fRatio;
	int iSplitResult;

	char szMenuItems[16][32];
	char szNum[16];
	char szItemLabel[32];

	int iExplodeResult = ExplodeString(szItems, ";", szMenuItems, sizeof(szMenuItems), sizeof(szMenuItems[]));
	hMenu = new Menu(hCallback, MENU_ACTIONS_DEFAULT);
	hMenu.SetTitle(szTitle);

	if (!szItems[0]) {
		hMenu.AddItem("1.0", "[NO ITEMS]", ITEMDRAW_DISABLED);
	}
	else {
		for (int i = 0; i < iExplodeResult && i < sizeof(szMenuItems); i++) {
			if (!szMenuItems[i][0]) {
				continue;
			}
			if ((iSplitResult = SplitString(szMenuItems[i], ",", szNum, sizeof(szNum))) == -1) {
				TrimString(szMenuItems[i]);
				if ((fRatio = StringToFloat(szMenuItems[i])) <= 0.0) {
					strcopy(szItemLabel, sizeof(szItemLabel), "Toggle");
				}
				else {
					FormatEx(szItemLabel, sizeof(szItemLabel), "%d%%", RoundToNearest(fRatio * 100.0));
				}
				hMenu.AddItem(szMenuItems[i], szItemLabel);
			}
			else {
				TrimString(szNum);
				if ((fRatio = StringToFloat(szNum)) <= 0.0) {
					strcopy(szItemLabel, sizeof(szItemLabel), "Toggle");
				}
				else {
					TrimString(szMenuItems[i][iSplitResult]);
					FormatEx(szItemLabel, sizeof(szItemLabel), "%d%% - %s", RoundToNearest(fRatio * 100.0), szMenuItems[i][iSplitResult]);
				}
				hMenu.AddItem(szNum, szItemLabel);
			}
		}
	}
	return iExplodeResult;
}

void ParseConVarToLimits(const ConVar &hConvar, char[] szMinString, const int iMinStringLength, float &fMin, char[] szMaxString, const int iMaxStringLength, float &fMax) {
	int iSplitResult;
	char szBounds[256];
	hConvar.GetString(szBounds, sizeof(szBounds));

	if ((iSplitResult = SplitString(szBounds, ",", szMinString, iMinStringLength)) != -1 && (fMin = StringToFloat(szMinString)) >= 0.0) {
		TrimString(szMinString);
		strcopy(szMaxString, iMaxStringLength, szBounds[iSplitResult]);
	}
	else {
		strcopy(szMinString, iMinStringLength, "0.0");
		fMin = 0.0;
		strcopy(szMaxString, iMaxStringLength, szBounds);
	}
	TrimString(szMaxString);
	fMax = StringToFloat(szMaxString);

	int iMarkInMin = FindCharInString(szMinString, '.'), iMarkInMax = FindCharInString(szMaxString, '.');
	Format(szMinString, iMinStringLength, "%s%s%s", (iMarkInMin == 0 ? "0" : ""), szMinString, (iMarkInMin == -1 ? ".0" : (iMarkInMin == (strlen(szMinString) - 1) ? "0" : "")));
	Format(szMaxString, iMaxStringLength, "%s%s%s", (iMarkInMax == 0 ? "0" : ""), szMaxString, (iMarkInMax == -1 ? ".0" : (iMarkInMax == (strlen(szMaxString) - 1) ? "0" : "")));

	if (fMin > fMax) {
		float fTemp = fMax;
		fMax = fMin;
		fMin = fTemp;
	}
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client < 1) {
		return Plugin_Continue;
	}

	//Resize back to specified scale on spawn.
	if (IsPlayerAlive(client) && g_bIsAvailable[ResizeType_Generic]) {
		ResizePlayer(ResizeType_Generic, client, g_szClientCurrentScale[ResizeType_Generic][client]);

		//If server wants to unstick on spawn, then check player is stuck.
		if ((g_iUnstick == 2 || g_iUnstick == 3) && g_fClientCurrentScale[ResizeType_Generic][client] != 1.0 && IsPlayerStuck(client)) {
			StopTimer(client, ResizeType_Generic);
			ResizePlayer(ResizeType_Generic, client, "1.0");
			PrintToChat(client, "%sYou were \x05resized\x01 to \x051.0\x01 to avoid being stuck.", CHAT_TAG);
		}
	}
	return Plugin_Continue;
}

void ResizeProcess(const int type, const bool bSelfCmd, const int client, const int args) {
	if (!g_bIsAvailable[type]) {
		ReplyToCommand(client, "%sCannot use command in this game.", CHAT_TAG);
		return;
	}

	int iNow = GetTime();
	if (IsClientOnCooldown(client, iNow, type)) {
		return;
	}

	if (args == 0) {
		if (client == 0) {
			PrintToServer("%s%T", CONSOLE_TAG, "Command is in-game only", LANG_SERVER);
			return;
		}

		if (g_iMenu == 1 || (bSelfCmd && g_iMenu == 2) || (!bSelfCmd && g_iMenu == 3)) {
			DisplayMenuSafely(g_hMenu[type], client);
			return;
		}
		else if (!IsClientAllowedPastBounds(client, type) && ((g_fClientCurrentScale[type][client] != g_fClientLastScale[type][client] && (g_fClientLastScale[type][client] < g_fBound[type][0] || g_fClientLastScale[type][client] > g_fBound[type][1])) || (g_fClientCurrentScale[type][client] == g_fClientLastScale[type][client] && (1.0 < g_fBound[type][0] || g_fBound[type][1] < 1.0)))) {
			ReplyToCommand(client, "%sSize must be between \x05%s\x01 and \x05%s\x01.", CHAT_TAG, g_szBound[type][0], g_szBound[type][1]);
			return;
		}
		else {
			StopTimer(client, type);
			if (ResizePlayer(type, client, _, (g_iLogging == 1 || (g_iLogging == 2 && !bSelfCmd)), _, _, (type == ResizeType_Generic && (g_iUnstick == 1 || g_iUnstick == 3)))) {
				g_iLastResize[type][client] = iNow;
				int target[1];
				target[0] = client;
				NotifyPlayers(type, client, false, target, 1, g_szClientCurrentScale[type][client]);
			}
			else if (type == ResizeType_Generic) {
				ReplyToCommand(client, "%sYou were not resized to avoid being stuck.", CHAT_TAG);
			}
		}
		return;
	}

	if (bSelfCmd) {
		switch (type) {
			case ResizeType_Generic:  ReplyToCommand(client, "%sUsage: sm_resizeme", CHAT_TAG);
			case ResizeType_Head:  ReplyToCommand(client, "%sUsage: sm_resizemyhead", CHAT_TAG);
			case ResizeType_Torso:  ReplyToCommand(client, "%sUsage: sm_resizemytorso", CHAT_TAG);
			case ResizeType_Hands:  ReplyToCommand(client, "%sUsage: sm_resizemyhands", CHAT_TAG);
		}
		return;
	}

	int target_count;
	bool tn_is_ml;
	int iTargetList[MAXPLAYERS];

	char szTargetName[MAX_TARGET_LENGTH];
	char szTarget[MAX_NAME_LENGTH];
	GetCmdArg(1, szTarget, sizeof(szTarget));
	if ((target_count = ProcessTargetString(szTarget, client, iTargetList, MAXPLAYERS, 0, szTargetName, sizeof(szTargetName), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return;
	}

	char szScale[8] = "0.0";
	char szTime[8] = "0.0";
	float fScale = 0.0;
	float fTime = 0.0;
	if (args > 1) {
		GetCmdArg(2, szScale, sizeof(szScale));
		TrimString(szScale);

		fScale = StringToFloat(szScale);
		if (type == ResizeType_Generic && fScale <= 0.0) {
			ReplyToCommand(client, "%sInvalid size specified.", CHAT_TAG);
			return;
		}
		else if (!IsClientAllowedPastBounds(client, type) && (fScale < g_fBound[type][0] || fScale > g_fBound[type][1])) {
			ReplyToCommand(client, "%sSize must be between \x05%s\x01 and \x05%s\x01.", CHAT_TAG, g_szBound[type][0], g_szBound[type][1]);
			return;
		}

		if (args > 2) {
			GetCmdArg(3, szTime, sizeof(szTime));
			TrimString(szTime);
			fTime = StringToFloat(szTime);

			if (fTime <= 0.0) {
				ReplyToCommand(client, "%sInvalid duration specified.", CHAT_TAG);
				return;
			}
		}
	}
	bool bResult;
	bool bIsSelfTarget = ((!tn_is_ml || target_count == 1) && client == iTargetList[0]);
	bool bLog = (g_iLogging == 1 || (g_iLogging == 2 && !bSelfCmd));
	bool bCheckStuck = (type == ResizeType_Generic && (bIsSelfTarget && (g_iUnstick == 1 || g_iUnstick == 3)));
	for (int i = 0; i < target_count; i++) {
		if (IsClientReplay(iTargetList[i]) || IsClientSourceTV(iTargetList[i])) {
			continue;
		}
		StopTimer(iTargetList[i], type);

		char szScaleEdited[16];
		int iMarkInScale = FindCharInString(szScale, '.');
		FormatEx(szScaleEdited, sizeof(szScaleEdited), "%s%s%s", (iMarkInScale == 0 ? "0" : ""), szScale, (iMarkInScale == -1 ? ".0" : (iMarkInScale == (strlen(szScale) - 1) ? "0" : "")));

		bResult = ResizePlayer(type, iTargetList[i], szScaleEdited, bLog, client, szTime, bCheckStuck);
	}

	if (type == ResizeType_Generic && !bResult) {
		ReplyToCommand(client, "%sYou were not resized to avoid being stuck.", CHAT_TAG);
		return;
	}
	NotifyPlayers(type, client, tn_is_ml, iTargetList, target_count, szScale, szTargetName, szTime);
	g_iLastResize[type][client] = iNow;
}

bool ResizePlayer(const int type, const int client, const char[] szScale = "0.0", bool bLog = false, const int iOrigin = -1, const char[] szTime = "0.0", bool bCheckStuck = false) {
	float fScale = StringToFloat(szScale);
	float fTime = StringToFloat(szTime);

	char szOriginalScale[8];
	strcopy(szOriginalScale, sizeof(szOriginalScale), g_szClientCurrentScale[type][client]);

	if (fScale == 0.0) {
		if (g_fClientCurrentScale[type][client] != g_fClientLastScale[type][client]) {
			g_fClientCurrentScale[type][client] = g_fClientLastScale[type][client];
			strcopy(g_szClientCurrentScale[type][client], sizeof(g_szClientCurrentScale[][]), g_szClientLastScale[type][client]);

			if (type == ResizeType_Generic) {
				SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_fClientCurrentScale[ResizeType_Generic][client]);
				if (g_iSteps == 1 || (g_iSteps == 2 && g_fClientCurrentScale[ResizeType_Generic][client] < 1.0) || (g_iSteps == 3 && g_fClientCurrentScale[ResizeType_Generic][client] > 1.0)) {
					SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * g_fClientCurrentScale[ResizeType_Generic][client]);
				}
				else {
					SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0);
				}
			}
		}
		else {
			if (type == ResizeType_Generic) {
				SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
				SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0);
			}
			g_fClientCurrentScale[type][client] = 1.0;
			strcopy(g_szClientCurrentScale[type][client], sizeof(g_szClientCurrentScale[][]), "1.0");
		}
	}
	else {
		if (fScale != 1.0) {
			g_fClientLastScale[type][client] = fScale;
			strcopy(g_szClientLastScale[type][client], sizeof(g_szClientLastScale[][]), szScale);
		}

		g_fClientCurrentScale[type][client] = fScale;
		strcopy(g_szClientCurrentScale[type][client], sizeof(g_szClientCurrentScale[][]), szScale);

		if (type == ResizeType_Generic) {
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", fScale);
			if (g_iSteps == 1 || (g_iSteps == 2 && fScale < 1.0) || (g_iSteps == 3 && fScale > 1.0)) {
				SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * fScale);
			}
			else {
				SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0);
			}
		}
	}

	if (type == ResizeType_Generic) {
		if (g_bHitboxAvailable) {
			UpdatePlayerHitbox(client);
		}

		if (bCheckStuck && IsPlayerAlive(client) && IsPlayerStuck(client)) {
			ResizePlayer(ResizeType_Generic, client, szOriginalScale);
			return false;
		}
	}

	if (fTime > 0.0) {
		DataPack hPack;
		g_hClientTimer[type][client] = CreateDataTimer(fTime, ResizeTimer, hPack);
		hPack.WriteCell(type);
		hPack.WriteCell(GetClientUserId(client));
		hPack.WriteString(szOriginalScale);
	}

	if (bLog) {
		char szPart[10];

		switch (type) {
			case ResizeType_Head:   strcopy(szPart, sizeof(szPart), "'s head");
			case ResizeType_Torso:  strcopy(szPart, sizeof(szPart), "'s torso");
			case ResizeType_Hands:  strcopy(szPart, sizeof(szPart), "'s hands");
			default:                strcopy(szPart, sizeof(szPart), "");
		}

		if (iOrigin > -1) {
			if (fTime > 0.0) {
				LogAction(iOrigin, client, "\"%L\" resized \"%L\"%s to %s for %s seconds.", iOrigin, client, szPart, g_szClientCurrentScale[type][client], szTime);
			}
			else {
				LogAction(iOrigin, client, "\"%L\" resized \"%L\"%s to %s.", iOrigin, client, szPart, g_szClientCurrentScale[type][client]);
			}
		}
		else {
			LogAction(0, client, "\"%L\"%s %s resized to %s.", client, szPart, (type == ResizeType_Hands ? "were" : "was"), g_szClientCurrentScale[type][client]);
		}
	}
	return true;
}

void UpdatePlayerHitbox(const int client) {
	static const float vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 };
	static const float vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	static const float vecGenericPlayerMin[3] = { -16.5, -16.5, 0.0 };
	static const float vecGenericPlayerMax[3] = { 16.5,  16.5, 73.0 };
	float vecScaledPlayerMin[3];
	float vecScaledPlayerMax[3];
	if (g_bIsTF2) {
		vecScaledPlayerMin = vecTF2PlayerMin;
		vecScaledPlayerMax = vecTF2PlayerMax;
	}
	else {
		vecScaledPlayerMin = vecGenericPlayerMin;
		vecScaledPlayerMax = vecGenericPlayerMax;
	}
	ScaleVector(vecScaledPlayerMin, g_fClientCurrentScale[ResizeType_Generic][client]);
	ScaleVector(vecScaledPlayerMax, g_fClientCurrentScale[ResizeType_Generic][client]);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}

bool IsPlayerStuck(const int client) {
	float vecMins[3];
	float vecMaxs[3];
	float vecOrigin[3];
	GetClientMins(client, vecMins);
	GetClientMaxs(client, vecMaxs);
	GetClientAbsOrigin(client, vecOrigin);
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceEntityFilterPlayer, client);
	return TR_DidHit();
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask) {
	return (entity < 1 || entity > MaxClients);
}

bool IsClientOnCooldown(const int client, const int now, const int type) {
	if (g_iCooldown > 0 && !CheckCommandAccess(client, "sm_resizecooldownbypass", ADMFLAG_GENERIC)) {
		int iTimeLeft = g_iCooldown - now;
		iTimeLeft += g_iLastResize[type][client];

		if (iTimeLeft > 0) {
			ReplyToCommand(client, "%sYou must wait another %d second%s.", CHAT_TAG, iTimeLeft, (iTimeLeft != 1 ? "s" : ""));
			return true;
		}
	}
	return false;
}

public Action OnResizeCmd(int client, int args) {
	if (g_bEnabled) {
		ResizeProcess(ResizeType_Generic, false, client, args);
	}
	return Plugin_Handled;
}

public Action OnResizeHeadCmd(int client, int args) {
	if (g_bEnabled) {
		ResizeProcess(ResizeType_Head, false, client, args);
	}
	return Plugin_Handled;
}

public Action OnResizeTorsoCmd(int client, int args) {
	if (g_bEnabled) {
		ResizeProcess(ResizeType_Torso, false, client, args);
	}
	return Plugin_Handled;
}

public Action OnResizeHandsCmd(int client, int args) {
	if (g_bEnabled) {
		ResizeProcess(ResizeType_Hands, false, client, args);
	}
	return Plugin_Handled;
}

public Action OnResizeMeCmd(int client, int args) {
	if (g_bEnabled) {
		ResizeProcess(ResizeType_Generic, true, client, args);
	}
	return Plugin_Handled;
}

public Action OnResizeMyHeadCmd(int client, int args) {
	if (g_bEnabled) {
		ResizeProcess(ResizeType_Head, true, client, args);
	}
	return Plugin_Handled;
}

public Action OnResizeMyTorsoCmd(int client, int args) {
	if (g_bEnabled) {
		ResizeProcess(ResizeType_Torso, true, client, args);
	}
	return Plugin_Handled;
}

public Action OnResizeMyHandsCmd(int client, int args) {
	if (g_bEnabled) {
		ResizeProcess(ResizeType_Hands, true, client, args);
	}
	return Plugin_Handled;
}

public Action OnResetCmd(int client, int args) {
	if (g_bEnabled) {
		ResetProcess(false, client, args);
	}
	return Plugin_Handled;
}

public Action OnResetMeCmd(int client, int args) {
	if (g_bEnabled) {
		ResetProcess(true, client, args);
	}
	return Plugin_Handled;
}

void ResetProcess(const bool bSelfCmd, const int client, const int args) {
	if (args == 0) {
		if (client == 0) {
			PrintToServer("%s%T", CONSOLE_TAG, "Command is in-game only", LANG_SERVER);
			return;
		}

		for (int type = 0; type < ResizeTypes; type++) {
			if (g_bIsAvailable[type]) {
				StopTimer(client, type);
				ResizePlayer(type, client, "1.0", (g_iLogging == 1 || (g_iLogging == 2 && !bSelfCmd)));
			}
		}

		if (g_iNotify == 1) {
			ShowActivity2(client, CHAT_TAG, "%N's size was \x05reset\x01!", client);
		}
		else if (g_iNotify == 2) {
			PrintToChatAll("%s%N's size was \x05reset\x01!", CHAT_TAG, client);
		}
		return;
	}
	if (bSelfCmd) {
		ReplyToCommand(client, "%sUsage: sm_resizeresetme", CHAT_TAG);
		return;
	}
	
	int target_count;
	bool tn_is_ml;
	int iTargetList[MAXPLAYERS];

	char szTargetName[MAX_TARGET_LENGTH];
	char szTarget[MAX_NAME_LENGTH];
	GetCmdArg(1, szTarget, sizeof(szTarget));
	if ((target_count = ProcessTargetString(szTarget, client, iTargetList, MAXPLAYERS, 0, szTargetName, sizeof(szTargetName), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return;
	}

	bool bLog = (g_iLogging == 1 || (g_iLogging == 2 && !bSelfCmd));

	for (int type = 0; type < ResizeTypes; type++) {
		if (g_bIsAvailable[type]) {
			for (int i = 0; i < target_count; i++) {
				if (IsClientReplay(iTargetList[i]) || IsClientSourceTV(iTargetList[i])) {
					continue;
				}
				StopTimer(iTargetList[i], type);
				ResizePlayer(type, iTargetList[i], "1.0", bLog, client);
			}
		}
	}

	if (bSelfCmd) {
		if (g_iNotify == 1) {
			ShowActivity2(client, CHAT_TAG, "%N's size was \x05reset\x01!", client);
		}
		else if (g_iNotify == 2) {
			PrintToChatAll("%s%N's size was \x05reset\x01!", CHAT_TAG, client);
		}
	}
	else {
		if (g_iNotify == 1) {
			ShowActivity2(client, CHAT_TAG, "%N \x05reset\x01 the size of %s!", client, szTargetName);
		}
		else if (g_iNotify == 2) {
			PrintToChatAll("%s%N \x05reset\x01 the size of %s!", CHAT_TAG, client, szTargetName);
		}
	}
}

bool NotifyPlayers(const int type, const int iOrigin, const bool tn_is_ml, const int[] targets, const int target_count, const char[] szScale, const char[] szTarget = "", const char[] szTime = "0.0") {
	if (g_iNotify != 1 && g_iNotify != 2) {
		return false;
	}

	char szScaleEdited[16];
	char szTimeEdited[16];
	int iMarkInScale = FindCharInString(szScale, '.'), iMarkInTime = FindCharInString(szTime, '.');
	FormatEx(szScaleEdited, sizeof(szScaleEdited), "%s%s%s", (iMarkInScale == 0 ? "0" : ""), szScale, (iMarkInScale == -1 ? ".0" : (iMarkInScale == (strlen(szScale) - 1) ? "0" : "")));
	FormatEx(szTimeEdited, sizeof(szTimeEdited), "%s%s%s", (iMarkInTime == 0 ? "0" : ""), szTime, (iMarkInTime == -1 ? ".0" : (iMarkInTime == (strlen(szTime) - 1) ? "0" : "")));

	char szPart[16];

	if (target_count == 1) {
		switch (type) {
			case ResizeType_Head:     strcopy(szPart, sizeof(szPart), "'s head was");
			case ResizeType_Torso:    strcopy(szPart, sizeof(szPart), "'s torso was");
			case ResizeType_Hands:    strcopy(szPart, sizeof(szPart), "'s hands were");
			default:                  strcopy(szPart, sizeof(szPart), " was");
		}

		switch ((view_as<int>((StringToFloat(szScale)) > 0.0) << 2) | (view_as<int>((StringToFloat(szTime)) > 0.0) << 1) | view_as<int>((g_iNotify == 1))) {
			case 0b000:  PrintToChatAll("%s%N%s \x05resized\x01 to \x05%s\x01!", CHAT_TAG, targets[0], szPart, g_szClientCurrentScale[type][targets[0]]);
			case 0b001:  ShowActivity2(iOrigin, CHAT_TAG, "%N%s \x05resized\x01 to \x05%s\x01!", targets[0], szPart, g_szClientCurrentScale[type][targets[0]]);
			case 0b010:  PrintToChatAll("%s%N%s \x05resized\x01 to \x05%s\x01 for \x05%s\x01 seconds!", CHAT_TAG, targets[0], szPart, g_szClientCurrentScale[type][targets[0]], szTimeEdited);
			case 0b011:  ShowActivity2(iOrigin, CHAT_TAG, "%N%s \x05resized\x01 to \x05%s\x01 for \x05%s\x01 seconds!", targets[0], szPart, g_szClientCurrentScale[type][targets[0]], szTimeEdited);
			case 0b100:  PrintToChatAll("%s%N%s \x05resized\x01 to \x05%s\x01!", CHAT_TAG, targets[0], szPart, szScaleEdited);
			case 0b101:  ShowActivity2(iOrigin, CHAT_TAG, "%N%s \x05resized\x01 to \x05%s\x01!", targets[0], szPart, szScaleEdited);
			case 0b110:  PrintToChatAll("%s%N%s \x05resized\x01 to \x05%s\x01 for \x05%s\x01 seconds!", CHAT_TAG, targets[0], szPart, szScaleEdited, szTimeEdited);
			case 0b111:  ShowActivity2(iOrigin, CHAT_TAG, "%N%s \x05resized\x01 to \x05%s\x01 for \x05%s\x01 seconds!", targets[0], szPart, szScaleEdited, szTimeEdited);
		}
		return true;
	}

	if (tn_is_ml) {
		switch (type) {
			case ResizeType_Head:     strcopy(szPart, sizeof(szPart), "' heads");
			case ResizeType_Torso:    strcopy(szPart, sizeof(szPart), "' torsos");
			case ResizeType_Hands:    strcopy(szPart, sizeof(szPart), "' hands");
			default:                  strcopy(szPart, sizeof(szPart), "");
		}
	}
	else {
		switch (type) {
			case ResizeType_Head:     strcopy(szPart, sizeof(szPart), "'s heads");
			case ResizeType_Torso:    strcopy(szPart, sizeof(szPart), "'s torsos");
			case ResizeType_Hands:    strcopy(szPart, sizeof(szPart), "'s hands");
			default:                  strcopy(szPart, sizeof(szPart), "");
		}
	}

	switch ((view_as<int>((StringToFloat(szScale)) > 0.0) << 2) | (view_as<int>((StringToFloat(szTime)) > 0.0) << 1) | view_as<int>((g_iNotify == 1))) {
		case 0b000:  PrintToChatAll("%s%N \x05resized\x01 %s%s!", CHAT_TAG, iOrigin, szTarget, szPart);
		case 0b001:  ShowActivity2(iOrigin, CHAT_TAG, "%N \x05resized\x01 %s%s!", iOrigin, szTarget, szPart);
		case 0b010:  PrintToChatAll("%s%N \x05resized\x01 %s%s for \x05%s\x01 seconds!", CHAT_TAG, iOrigin, szTarget, szPart, szTimeEdited);
		case 0b011:  ShowActivity2(iOrigin, CHAT_TAG, "%N \x05resized\x01 %s%s for \x05%s\x01 seconds!", iOrigin, szTarget, szPart, szTimeEdited);
		case 0b100:  PrintToChatAll("%s%N \x05resized\x01 %s%s to \x05%s\x01!", CHAT_TAG, iOrigin, szTarget, szPart, szScaleEdited);
		case 0b101:  ShowActivity2(iOrigin, CHAT_TAG, "%N \x05resized\x01 %s%s to \x05%s\x01!", iOrigin, szTarget, szPart, szScaleEdited);
		case 0b110:  PrintToChatAll("%s%N \x05resized\x01 %s%s to \x05%s\x01 for \x05%s\x01 seconds!", CHAT_TAG, iOrigin, szTarget, szPart, szScaleEdited, szTimeEdited);
		case 0b111:  ShowActivity2(iOrigin, CHAT_TAG, "%N \x05resized\x01 %s%s to \x05%s\x01 for \x05%s\x01 seconds!", iOrigin, szTarget, szPart, szScaleEdited, szTimeEdited);
	}
	return true;
}

public Action ResizeTimer(Handle timer, DataPack pack) {
	pack.Reset();

	int type = pack.ReadCell();
	int client = GetClientOfUserId(pack.ReadCell());
	char szOriginalScale[8];
	pack.ReadString(szOriginalScale, sizeof(szOriginalScale));
	if (client > 0) {
		ResizePlayer(type, client, szOriginalScale);
		g_hClientTimer[type][client] = null;
	}
}

void DestroyMenus() {
	for (int i = 0; i < ResizeTypes; i++) {
		delete g_hMenu[i];
	}
}

void ResizeMenuHandlerTyped(const int type, Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select && IsClientInGame(param1)) {
		int iNow = GetTime();
		if (IsClientOnCooldown(param1, iNow, type)) {
			return;
		}

		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		StopTimer(param1, type);
		if (ResizePlayer(type, param1, info, g_iLogging == 1, param1, _, (type == ResizeType_Generic && (g_iUnstick == 1 || g_iUnstick == 3)))) {
			g_iLastResize[type][param1] = iNow;
			int target[1];
			target[0] = param1;
			NotifyPlayers(type, param1, false, target, 1, g_szClientCurrentScale[type][param1]);
		}
		else if (type == ResizeType_Generic) {
			ReplyToCommand(param1, "%sYou were not resized to avoid being stuck.", CHAT_TAG);
		}
		menu.DisplayAt(param1, menu.Selection, MENU_TIME_FOREVER);
	}
}

int ResizeMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (g_bEnabled) {
		ResizeMenuHandlerTyped(ResizeType_Generic, menu, action, param1, param2);
	}
}

int ResizeHeadMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (g_bEnabled) {
		ResizeMenuHandlerTyped(ResizeType_Head, menu, action, param1, param2);
	}
}

int ResizeTorsoMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (g_bEnabled) {
		ResizeMenuHandlerTyped(ResizeType_Torso, menu, action, param1, param2);
	}
}

int ResizeHandsMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (g_bEnabled) {
		ResizeMenuHandlerTyped(ResizeType_Hands, menu, action, param1, param2);
	}
}

// ----------------------

public void ConVarEnabledChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	g_bEnabled = (StringToInt(newvalue) != 0);

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsClientAuthorized(i) && !IsClientReplay(i) && !IsClientSourceTV(i)) {
			ReadjustInitialSize(i, true);
		}
	}
}

public void ConVarDamageChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	g_iDamage = StringToInt(newvalue);
}

public void ConVarStepsChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	g_iSteps = StringToInt(newvalue);

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsClientAuthorized(i) && !IsClientReplay(i) && !IsClientSourceTV(i)) {
			SetEntPropFloat(i, Prop_Send, "m_flStepSize", 18.0 * g_fClientCurrentScale[ResizeType_Generic][i]);
		}
	}
}

public void ConVarNotifyChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	g_iNotify = StringToInt(newvalue);
}

public void ConVarLoggingChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	g_iLogging = StringToInt(newvalue);
}

public void ConVarOnJoinChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	g_iOnJoin = StringToInt(newvalue);
}

public void ConVarVoicesChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	g_iVoicesChanged = StringToInt(newvalue);
}

public void ConVarMenuChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	g_iMenu = StringToInt(newvalue);
}

public void ConVarBackstabChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	g_bBackstab = (StringToInt(newvalue) != 0);
}

public void ConVarUnstickChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	g_iUnstick = StringToInt(newvalue);
}

public void ConVarCooldownChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	g_iCooldown = StringToInt(newvalue);
}

// ----------------------

public void ConVarBoundsChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	CvarBoundChanged(ResizeType_Generic);
}

public void ConVarHeadBoundsChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	CvarBoundChanged(ResizeType_Head);
}

public void ConVarTorsoBoundsChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	CvarBoundChanged(ResizeType_Torso);
}

public void ConVarHandsBoundsChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	CvarBoundChanged(ResizeType_Hands);
}

void CvarBoundChanged(int type) {
	ParseConVarToLimits(g_hBound[type], g_szBound[type][0], sizeof(g_szBound[][]), g_fBound[type][0], g_szBound[type][1], sizeof(g_szBound[][]), g_fBound[type][1]);
}

// ----------------------

public void ConVarMenuItemsChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	CvarChanged(ResizeType_Generic, newvalue);
}

public void ConVarMenuHeadItemsChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	CvarChanged(ResizeType_Head, newvalue);
}

public void ConVarMenuTorsoItemsChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	CvarChanged(ResizeType_Torso, newvalue);
}

public void ConVarMenuHandsItemsChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	CvarChanged(ResizeType_Hands, newvalue);
}

void CvarChanged(int type, const char[] newvalue) {
	strcopy(g_szMenuItems[type], sizeof(g_szMenuItems[]), newvalue);
	DestroyMenus();
	BuildMenus();	
}

// ----------------------

public void ConVarScaleChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	ConVarScaleChangedTyped(ResizeType_Generic, "sm_resize_defaultresize", DEFAULT_FALLBACK, newvalue);
}

public void ConVarHeadScaleChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	ConVarScaleChangedTyped(ResizeType_Generic, "sm_resize_defaultheadresize", DEFAULT_HEAD_FALLBACK, newvalue);
}

public void ConVarTorsoScaleChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	ConVarScaleChangedTyped(ResizeType_Generic, "sm_resize_defaulttorsoresize", DEFAULT_TORSO_FALLBACK, newvalue);
}

public void ConVarHandScaleChanged(ConVar convar, const char[] oldvalue, const char[] newvalue) {
	ConVarScaleChangedTyped(ResizeType_Generic, "sm_resize_defaulthandsresize", DEFAULT_HANDS_FALLBACK, newvalue);
}

void ConVarScaleChangedTyped(const int type, const char[] szDefaultConVar, const char[] szFallback, const char[] newvalue) {
	strcopy(g_szDefault[type], sizeof(g_szDefault[]), newvalue);
	TrimString(g_szDefault[type]);
	g_fDefaultResize[type] = StringToFloat(newvalue);
	CheckDefaultValue(g_fDefaultResize[type], g_szDefault[type], sizeof(g_szDefault[]), szDefaultConVar, szFallback);

	for (int i = 1; i <= MaxClients; i++) {
		g_fClientLastScale[type][i] = g_fDefaultResize[type];
		strcopy(g_szClientLastScale[type][i], sizeof(g_szClientLastScale[][]), g_szDefault[type]);
	}
}

void CheckDefaultValue(float &fDefault, char[] szDefaultStr, const int iDefaultStrLen, const char[] szConVarName, const char[] szFallback) {
	if (fDefault <= 0.0) {
		LogError("Invalid ConVar (%s) value. Falling back to %s.", szConVarName, szFallback);
		strcopy(szDefaultStr, iDefaultStrLen, szFallback);
		fDefault = StringToFloat(szFallback);
	}
}

public void OnGameFrame() {
	if (!g_bEnabled) {
		return;
	}
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			if (g_bIsAvailable[ResizeType_Head] && g_fClientCurrentScale[ResizeType_Head][i] != 1.0) {
				SetEntPropFloat(i, Prop_Send, "m_flHeadScale", g_fClientCurrentScale[ResizeType_Head][i]);
			}
			if (g_bIsAvailable[ResizeType_Torso] && g_fClientCurrentScale[ResizeType_Torso][i] != 1.0) {
				SetEntPropFloat(i, Prop_Send, "m_flTorsoScale", g_fClientCurrentScale[ResizeType_Torso][i]);
			}
			if (g_bIsAvailable[ResizeType_Hands] && g_fClientCurrentScale[ResizeType_Hands][i] != 1.0) {
				SetEntPropFloat(i, Prop_Send, "m_flHandScale", g_fClientCurrentScale[ResizeType_Hands][i]);
			}
		}
	}
}

public Action SoundCallback(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed) {
	if (g_bEnabled && g_iVoicesChanged > 0) {
		if (entity > 0 && entity <= MaxClients && channel == SNDCHAN_VOICE) {
			float fActualHeadSize = g_fClientCurrentScale[ResizeType_Generic][entity] * g_fClientCurrentScale[ResizeType_Head][entity];
			if (fActualHeadSize == 1.0 || fActualHeadSize <= 0.0) {
				return Plugin_Continue;
			}
			if (g_iVoicesChanged == 1 || (g_iVoicesChanged == 2 && fActualHeadSize < 1.0) || (g_iVoicesChanged == 3 && fActualHeadSize > 1.0)) {
				//Next expression is ((175/(1+6x))+75) so results stay between 75 and 250 with 100 pitch at normal size.
				pitch = RoundToNearest((175 / (1 + (6 * fActualHeadSize))) + 75);
				flags |= SND_CHANGEPITCH;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if (g_bEnabled && g_iDamage > 0 && attacker > 0 && attacker <= MaxClients && attacker != victim) {
		if (g_fClientCurrentScale[ResizeType_Generic][attacker] == 1.0 || (g_iDamage == 2 && g_fClientCurrentScale[ResizeType_Generic][attacker] >= 1.0) || (g_iDamage == 3 && g_fClientCurrentScale[ResizeType_Generic][attacker] <= 1.0)) {
			return Plugin_Continue;
		}

		//Alter backstabs to deal same damage ratio as body size.
		if (g_bIsTF2 && g_bBackstab && g_bCustomDmgAvailable && victim > 0 && victim <= MaxClients && damagecustom == TF_CUSTOM_BACKSTAB) {
			int iMaxHealth = (g_hGetMaxHealth != null ? SDKCall(g_hGetMaxHealth, victim) : GetEntProp(victim, Prop_Data, "m_iMaxHealth"));
			damage = RoundToCeil(GetMax(iMaxHealth, GetEntProp(victim, Prop_Data, "m_iHealth")) * g_fClientCurrentScale[ResizeType_Generic][attacker]) / 3.0;
			return Plugin_Changed;
		}

		if (weapon == -1 && inflictor > MaxClients && IsValidEntity(inflictor)) {
			char szClassName[64];
			GetEntityClassname(inflictor, szClassName, sizeof(szClassName));
			if ((strcmp(szClassName, "obj_sentrygun") == 0) || (strcmp(szClassName, "tf_projectile_sentryrocket") == 0)) {
				return Plugin_Continue;
			}
		}

		damage *= g_fClientCurrentScale[ResizeType_Generic][attacker];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

int GetMax(const int iValA, const int iValB) {
	return (iValA < iValB ? iValB : iValA);
}

void DisplayMenuSafely(const Menu hMenu, const int client) {
	if (hMenu == null) {
		PrintToConsole(client, "%sUnable to open menu.", CONSOLE_TAG);
	}
	else {
		hMenu.Display(client, MENU_TIME_FOREVER);
	}
}

void StopTimer(const int client, const int type) {
	delete g_hClientTimer[type][client];
}

bool IsClientAllowedPastBounds(const int client, const int type) {
	switch (type) {
		case ResizeType_Generic:  return (CheckCommandAccess(client, "sm_resizeboundsoverride", ADMFLAG_ROOT, true));
		case ResizeType_Head:     return (CheckCommandAccess(client, "sm_resizeheadboundsoverride", ADMFLAG_ROOT, true));
		case ResizeType_Torso:    return (CheckCommandAccess(client, "sm_resizetorsoboundsoverride", ADMFLAG_ROOT, true));
		case ResizeType_Hands:    return (CheckCommandAccess(client, "sm_resizehandsboundsoverride", ADMFLAG_ROOT, true));
	}
	return false;
}

public void OnClientDisconnect_Post(int client) {
	for (int i = 0; i < ResizeTypes; i++) {
		StopTimer(client, i);
		g_fClientLastScale[i][client] = g_fDefaultResize[i];
		g_fClientCurrentScale[i][client] = 1.0;
		g_iLastResize[i][client] = 0;
		strcopy(g_szClientLastScale[i][client], sizeof(g_szClientLastScale[][]), g_szDefault[i]);
		strcopy(g_szClientCurrentScale[i][client], sizeof(g_szClientCurrentScale[][]), "1.0");
	}
}

public void OnMapEnd() {
	DestroyMenus();
}

public void OnPluginEnd() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsClientAuthorized(i) && !IsClientReplay(i) && !IsClientSourceTV(i)) {
			for (int j = 0; j < ResizeTypes; j++) {
				StopTimer(i, j);
				if (g_bIsAvailable[j] && g_fClientCurrentScale[j][i] != 1.0) {
					ResizePlayer(j, i, "1.0");
				}
			}
		}
	}
}

//Written by Steve '11530' Marchant.