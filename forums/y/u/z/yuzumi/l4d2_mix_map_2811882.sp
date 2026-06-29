#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define DEBUG 						0
#define CVAR_FLAGS					FCVAR_NOTIFY|FCVAR_DONTRECORD
#define CVAR_FLAGS_PLUGIN_VERSION	FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY
#define PLUGIN_VERSION				"1.1"
#define FILE_NAME 					"l4d2_mix_map"
#define PREFIX						"[Mix Map] "

Address g_pDirector;
Handle g_hSDK_CDirector_IsFirstMapInScenario;

char
	g_sValidLandMarkName[128],
	g_sTransitionMap[64];

bool
	g_bInited,
	g_bEnable,
	g_bStart,
	g_bSpawn,
	g_bIsValid,
	g_bFinaleStarted,
	g_bFirstMap,
	g_bOnlyOfficialMap;

float
	g_fChangeChance;

int
	g_iEnt_LandMarkId = INVALID_ENT_REFERENCE,
	g_iEnt_ChangeLevelId = INVALID_ENT_REFERENCE,
	g_iMixCount,
	g_iMaxMixCount;

ConVar
	g_hCvar_Enable,
	g_hCvar_ChangeChance,
	g_hCvar_OnlyOfficialMap,
	g_hCvar_MaxMixCount;

StringMap
	g_mMapLandMarkSet,
	g_mMapSet;

StringMapSnapshot
	g_msMapLandMarkSet,
	g_msMapSet;

static const char officialMap[57][] = {
	"c1m1_hotel", "c1m2_streets", "c1m3_mall", "c1m4_atrium",
	"c2m1_highway", "c2m2_fairgrounds", "c2m3_coaster", "c2m4_barns", "c2m5_concert",
	"c3m1_plankcountry", "c3m2_swamp", "c3m3_shantytown", "c3m4_plantation",
	"c4m1_milltown_a", "c4m2_sugarmill_a", "c4m3_sugarmill_b", "c4m4_milltown_b", "c4m5_milltown_escape",
	"c5m1_waterfront", "c5m2_park", "c5m3_cemetery", "c5m4_quarter", "c5m5_bridge",
	"c6m1_riverbank", "c6m2_bedlam", "c6m3_port",
	"c7m1_docks", "c7m2_barge", "c7m3_port",
	"c8m1_apartment", "c8m2_subway", "c8m3_sewers", "c8m4_interior", "c8m5_rooftop",
	"c9m1_alleys", "c9m2_lots",
	"c10m1_caves", "c10m2_drainage", "c10m3_ranchhouse", "c10m4_mainstreet", "c10m5_houseboat",
	"c11m1_greenhouse", "c11m2_offices", "c11m3_garage", "c11m4_terminal", "c11m5_runway",
	"c12m1_hilltop", "c12m2_traintunnel", "c12m3_bridge", "c12m4_barn", "c12m5_cornfield",
	"c13m1_alpinecreek", "c13m2_southpinestream", "c13m3_memorialbridge", "c13m4_cutthroatcreek",
	"c14m1_junkyard", "c14m2_lighthouse"
};

public Plugin myinfo =
{
	name = "Mix Map",
	author = "Yuzumi",
	description = "Randomize a non-finale map at the map transition.",
	version = PLUGIN_VERSION,
	url = "https://github.com/joyrhyme/L4D2-Plugins/tree/main/MixMap"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if( engine != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart() {
	g_mMapLandMarkSet = new StringMap();
	g_mMapSet = new StringMap();
	LoadKvFile();

	InitGameData();

	CreateConVar("random_map_version", PLUGIN_VERSION, "Random Map Transitions version.", CVAR_FLAGS_PLUGIN_VERSION);
	g_hCvar_Enable = CreateConVar("random_map_enable", "1", "启用插件", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_ChangeChance = CreateConVar("random_map_chance", "0.5", "有多大的几率触发随机地图", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_OnlyOfficialMap = CreateConVar("random_map_only_official", "1", "随机地图时只随机列表里存在的官方图", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_MaxMixCount = CreateConVar("random_map_max_mix_count", "5", "单次流程最多随机几次", CVAR_FLAGS, true, 1.0);

	g_hCvar_Enable.AddChangeHook(CvarChange);
	g_hCvar_ChangeChance.AddChangeHook(CvarChange);
	g_hCvar_OnlyOfficialMap.AddChangeHook(CvarChange);
	g_hCvar_MaxMixCount.AddChangeHook(CvarChange);

	#if DEBUG
	RegConsoleCmd("sm_test", Command_Test, "测试用-显示当前地图里插件所需的实体信息");
	RegConsoleCmd("sm_find", Command_Find, "测试用-查找当前地图里插件所需的实体信息");
	#endif
	RegAdminCmd("sm_rm_addconfig", Command_AddConfig, ADMFLAG_ROOT, "尝试添加当前地图到随机地图配置中");
	RegAdminCmd("sm_rm_reload", Command_Reload, ADMFLAG_ROOT, "重新加载地图配置");

	Init();

	AutoExecConfig(true, "l4d2_mix_map");
}

// 插件结束
public void OnPluginEnd() {
	ResetPlugin();
}

// 地图开始
public void OnMapStart() {
	//	
}

// 地图结束
public void OnMapEnd() {
	ResetPlugin();
}

// Cvar变更事件
void CvarChange(Handle convar, const char[] oldValue, const char[] newValue) {
	Init();
}

// 初始化Cvar与绑定事件
void Init() {
	g_bEnable = g_hCvar_Enable.BoolValue;
	g_bOnlyOfficialMap = g_hCvar_OnlyOfficialMap.BoolValue;
	g_fChangeChance = g_hCvar_ChangeChance.FloatValue;
	g_iMaxMixCount = g_hCvar_MaxMixCount.IntValue;
	
	if (g_bEnable && ! g_bInited) {
		HookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
		HookEvent("round_end",				Event_RoundEnd,			EventHookMode_PostNoCopy);
		HookEvent("player_spawn",			Event_PlayerSpawn,		EventHookMode_PostNoCopy);
		HookEvent("finale_radio_start", 	Event_FinaleStart, 		EventHookMode_PostNoCopy);
		HookEvent("gauntlet_finale_start", 	Event_FinaleStart, 		EventHookMode_PostNoCopy);
		HookEvent("map_transition",			Event_MapTransition,	EventHookMode_PostNoCopy);
		//HookEvent("player_transitioned",	Event_PlayerTransition,	EventHookMode_PostNoCopy);
		g_bInited = true;
	} else if (! g_bEnable && g_bInited) {
		UnhookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
		UnhookEvent("round_end",			Event_RoundEnd,			EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn",			Event_PlayerSpawn,		EventHookMode_PostNoCopy);
		UnhookEvent("finale_radio_start", 	Event_FinaleStart, 		EventHookMode_PostNoCopy);
		UnhookEvent("gauntlet_finale_start",Event_FinaleStart, 		EventHookMode_PostNoCopy);
		UnhookEvent("map_transition",		Event_MapTransition,	EventHookMode_PostNoCopy);
		// UnhookEvent("player_transitioned",	Event_PlayerTransition,	EventHookMode_PostNoCopy);
		g_bInited = false;
	}
}

// 初始化签名文件
void InitGameData() {
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof buffer, "gamedata/%s.txt", FILE_NAME);
	if (! FileExists(buffer))
		SetFailState("Missing required file: \"%s\".\n", buffer);

	GameData hGameData = new GameData(FILE_NAME);
	if (! hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata", FILE_NAME);

	g_pDirector = hGameData.GetAddress("CDirector");
	if (g_pDirector == Address_Null)
		SetFailState("Failed to get CDirector address");

	StartPrepSDKCall(SDKCall_Raw);
	if (PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsFirstMapInScenario") == false)
		SetFailState("Failed to setup signature for CDirector::IsFirstMapInScenario");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDK_CDirector_IsFirstMapInScenario = EndPrepSDKCall();
	if ( g_hSDK_CDirector_IsFirstMapInScenario == null )
		SetFailState("Failed to create SDKCall \"IsFirstMapInScenario\"");

	DynamicDetour dRestoreTransitioned = DynamicDetour.FromConf(hGameData, "RestoreTransitionedEntities");
	if (! dRestoreTransitioned)
		SetFailState("Failed to setup detour for RestoreTransitionedEntities");

	if (! dRestoreTransitioned.Enable(Hook_Pre, Detour_OnRestoreTransitionedEntities))
		SetFailState("Failed to detour for RestoreTransitionedEntities");

	DynamicDetour dTransitionRestore = DynamicDetour.FromConf(hGameData, "TransitionRestore");
	if (! dTransitionRestore)
		SetFailState("Failed to setup detour for TransitionRestore");
	if (! dTransitionRestore.Enable(Hook_Post, Detour_CTerrorPlayer_TransitionRestore_Post))
		SetFailState("Failed to detour post: \"TransitionRestore\"");

	delete hGameData;
}

// 过渡时地图实体处理的绕行函数
MRESReturn Detour_OnRestoreTransitionedEntities() {
	if (g_bEnable) {
		#if DEBUG
		LogMessage("Detour");
		#endif
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

// 玩家过渡函数
MRESReturn Detour_CTerrorPlayer_TransitionRestore_Post(int pThis, DHookReturn hReturn) {
	if (! g_bEnable || GetClientTeam(pThis) > 2)
		return MRES_Ignored;

	// 传送玩家到起点(防止因过渡时安全屋大小不匹配而导致的传送到安全屋外)
	CheatCommand(pThis, "warp_to_start_area");
	return MRES_Ignored;
}

// 地图开始过渡
void Event_MapTransition(Event hEvent, const char[] name, bool dontBroadcast) {
	#if DEBUG
	LogMessage("MapTransition");
	#endif
	// 如果字符串不为空
	if (g_sTransitionMap[0] != '\0') {
		// 过渡中代表成功过关, 把地图从随机列表中移除, 并刷新快照.
		++g_iMixCount;
		g_mMapSet.Remove(g_sTransitionMap);
		g_msMapSet = g_mMapSet.Snapshot();
	}
}

// 救援流程开始
void Event_FinaleStart(Event hEvent, const char[] name, bool dontBroadcast) {
	/* 
		判断救援流程标记变量为false时
		(因为此函数绑定多个救援事件(防止部分三方图的奇怪终局),防止重复触发)
	*/
	if (! g_bFinaleStarted) {
		#if DEBUG
		LogMessage("FinaleStart");
		#endif
		g_bFinaleStarted = true;
		g_iMixCount = 0;
		// 如果数组大小为0则重置哈希表
		if (g_msMapSet.Length == 0) {
			g_mMapSet = g_mMapLandMarkSet.Clone();
			g_msMapSet = g_mMapSet.Snapshot();
		}
	}
}

// 回合开始
void Event_RoundStart (Event event, const char[] name, bool dontBroadcast) {
	if (g_bSpawn == true && g_bStart == false) {
		#if DEBUG
		LogMessage("RoundStart");
		#endif
		if (g_bEnable) {
			g_bFirstMap = IsFirstMapInScenario();
			CreateTimer(1.0, TimerFindEntity, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	g_bStart = true;
}

// 回合结束
void Event_RoundEnd (Event event, const char[] name, bool dontBroadcast) {
	#if DEBUG
	LogMessage("RoundEnd");
	#endif
	ResetPlugin();
}

// 玩家生成事件
void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	if (g_bSpawn == false && g_bStart == true) {
		#if DEBUG
		LogMessage("PlayerSpawn");
		#endif
		if (g_bEnable) {
			g_bFirstMap = IsFirstMapInScenario();
			CreateTimer(1.0, TimerFindEntity, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	g_bSpawn = true;
}

// 寻找实体和修改实体计时器
Action TimerFindEntity(Handle timer)
{
	ResetPlugin();
	if ((g_bIsValid = FindMapEntity())) {
		// 如果找到了实体, 则进行实体属性修改 
		ChangeEntityProp();
	}

	return Plugin_Continue;
}

// 重置变量属性
void ResetPlugin() {
	g_iEnt_LandMarkId = INVALID_ENT_REFERENCE;
	g_iEnt_ChangeLevelId = INVALID_ENT_REFERENCE;
	g_bStart = false;
	g_bSpawn = false;
	g_bFinaleStarted = false;
	g_sValidLandMarkName[0] = '\0';
}

// 读取kv配置文件
bool LoadKvFile(int &arrayLength = 0) {
	char FilePath[PLATFORM_MAX_PATH];
	KeyValues kv = new KeyValues("l4d2_mix_map");

	// 文件不存在 返回失败
	BuildPath(Path_SM, FilePath, sizeof FilePath, "data/%s.cfg", FILE_NAME);
	if (! FileExists(FilePath)) {
		LogError("%s Missing required file: \"%s.cfg\".", PREFIX, FILE_NAME);
		delete kv;
		return false;
	}
	// 无法导入Kv文件内容 返回失败
	if (! kv.ImportFromFile(FilePath)) {
		LogError("%s Failed to load \"data/%s.cfg\".", PREFIX, FILE_NAME);
		delete kv;
		return false;
	}

	// 清空哈希表
	g_mMapLandMarkSet.Clear();
	g_mMapSet.Clear();
	// 如果不存在数据 则为清空数据
	if (! kv.GotoFirstSubKey()) {
		g_msMapLandMarkSet = g_mMapLandMarkSet.Snapshot();
		g_msMapSet = g_mMapSet.Snapshot();
		delete kv;
		return true;
	}
	char MapName[64];
	char LandMarkName[128];
	// 遍历数据
	do {
		// 获取节点名和对应key值
		kv.GetSectionName(MapName, sizeof MapName);
		kv.GetString("landmark_name", LandMarkName, sizeof LandMarkName);
		// 写入哈希表
		g_mMapLandMarkSet.SetString(MapName, LandMarkName);
	} while (kv.GotoNextKey());
	// 创建哈希表的索引快照
	g_msMapLandMarkSet = g_mMapLandMarkSet.Snapshot();
	g_mMapSet = g_mMapLandMarkSet.Clone();
	g_msMapSet = g_mMapSet.Snapshot();
	arrayLength = g_msMapLandMarkSet.Length;

	delete kv;
	return true;
}

// 写入kv配置文件
bool SaveKvFile() {
	char FilePath[PLATFORM_MAX_PATH];
	File file;
	KeyValues kv = new KeyValues("l4d2_mix_map");

	BuildPath(Path_SM, FilePath, sizeof FilePath, "data/%s.cfg", FILE_NAME);
	// 文件不存在
	if (! FileExists(FilePath)) {
		file = OpenFile(FilePath, "w");
		// 无法打开文件
		if (! file) {
			LogError("%s Cannot open file: \"%s\"", PREFIX, FilePath);
			return false;
		}
	}
	delete file;

	// 遍历哈希表索引, 写入kv文件
	if (g_msMapLandMarkSet.Length > 0) {
		char KeyName[64];
		char LandMarkName[128];
		for (int i = 0; i < g_msMapLandMarkSet.Length; ++i) {
			// 获取KeyName
			g_msMapLandMarkSet.GetKey(i, KeyName, sizeof KeyName);
			// 获取哈希表内对应内容
			g_mMapLandMarkSet.GetString(KeyName, LandMarkName, sizeof LandMarkName);
			// 跳到对应的节点, 不存在则新建
			kv.JumpToKey(KeyName, true);
			// 写入数据
			kv.SetString("landmark_name", LandMarkName);
			// 返回上层节点
			kv.Rewind();
		}
		// 写入内容到文件
		kv.ExportToFile(FilePath);
	}

	delete kv;
	return true;
}

// 查找地图实体
bool FindMapEntity() {
	/**
	 * 检查是否存在changelevel实体, 不存在则为终局地图, 插件不处理
	 * !!地图可能可以存在多个终点安全屋, 所以changelevel实体也可以多个!! (插件只服务官方地图, 不考虑mod地图, 所以只会存在一个终点安全屋)
	 * 但要支持上局地图过渡装备过来, 则肯定会有一个landmark实体没绑定changelevel实体, 该实体名字则为过渡数据到此章节用的实体名
	 * 第一章节可以修改, 但不可以添加配置(换图会出海报). 终局不可以修改, 但可以添加配置
	 */
	int CId, LId, ModifyLId = INVALID_ENT_REFERENCE;
	char LandMarkName[128], BindName[128];
	bool HasChangeLevel = true;

	// 如果找不到转换地图实体, 记录失败(因为终局图没此实体, 但有过渡到此地图的过渡实体, 下面会获取用于添加到配置, 然后再返回失败)
	if ((CId = FindEntityByClassname(CId, "info_changelevel")) == INVALID_ENT_REFERENCE) {
		HasChangeLevel = false;
	} else {
		// 获取实体所绑定的LankMark实体名
		GetEntPropString(CId, Prop_Data, "m_landmarkName", BindName, sizeof BindName);
		// 如果 没拿到绑定名字, 记录失败
		if (BindName[0] == '\0') {
			HasChangeLevel = false;
		}
	}

	// 遍历过渡实体, 找到没被绑定的实体名和可修改的实体ID
	while ((LId = FindEntityByClassname(LId, "info_landmark")) != INVALID_ENT_REFERENCE) {
		GetEntPropString(LId, Prop_Data, "m_iName", LandMarkName, sizeof LandMarkName);
		// 如果与转换地图实体所绑的名字一样, 则为修改用的实体, 记录ID
		if (StrEqual(LandMarkName, BindName, false)) {
			ModifyLId = LId;
		} else {
			if (! g_bFirstMap) {
				// 把用于过渡到此地图的过渡实体名回写全局变量
				Format(g_sValidLandMarkName, sizeof g_sValidLandMarkName, "%s", LandMarkName); // 用于写配置项
			}
		}
	}
	// 如果 没找到可修改的实体 或 前面已经判定为失败, 返回失败
	if (ModifyLId == INVALID_ENT_REFERENCE || ! HasChangeLevel) {
		return false;
	}
	
	// 把找到的信息回写全局变量
	g_iEnt_ChangeLevelId = CId;
	g_iEnt_LandMarkId = ModifyLId;

	return true;
}

// 修改实体属性
void ChangeEntityProp() {
	char MapName[64];
	g_sTransitionMap[0] = '\0';

	// 如果找不到转换地图实体, 返回失败
	if (g_iEnt_ChangeLevelId == INVALID_ENT_REFERENCE || ! IsValidEntity(g_iEnt_ChangeLevelId)) {
		g_bIsValid = false;
		return;
	}
	// 如果找不到可修改的实体, 返回失败
	if (g_iEnt_LandMarkId == INVALID_ENT_REFERENCE || ! IsValidEntity(g_iEnt_LandMarkId)) {
		g_bIsValid = false;
		return;
	}

	// 没到触发概率, 返回失败
	if (! AllowModify()) {
		PrintToChatAll("%s Currently space-time is stable, with no unusual fluctuations.", PREFIX);
		g_bIsValid = false;
		return;
	}

	// 获取要切换到的地图属性, 如果获取不到则返回信息并终止修改
	if (! GetChangeLevelMap(MapName, sizeof MapName)) {
		PrintToChatAll("%s Currently in a single timeline without any temporal fluctuations.", PREFIX);
		//PrintToChatAll("%s 没找到符合要求的地图, 终止修改.", PREFIX);
		g_bIsValid = false;
		return;
	}

	char LandMarkName[128];
	// 获取对应索引的地图名和过渡实体名
	g_mMapLandMarkSet.GetString(MapName, LandMarkName, sizeof LandMarkName);
	// 修改实体属性
	SetEntPropString(g_iEnt_ChangeLevelId, Prop_Data, "m_mapName", MapName);
	SetEntPropString(g_iEnt_ChangeLevelId, Prop_Data, "m_landmarkName", LandMarkName);
	SetEntPropString(g_iEnt_LandMarkId, Prop_Data, "m_iName", LandMarkName);
	g_sTransitionMap = MapName;
	PrintToChatAll("%s An uncharted rift in space-time has appeared. After changeLevel, you will travel to %s ...", PREFIX, MapName);
}

// 获取触发概率
bool AllowModify() {
	if (GetRandomFloat(0.0, 1.0) <= g_fChangeChance) {
		return true;
	}
	return false;
}

// 获取要换的地图
bool GetChangeLevelMap(char[] name, int maxLength) {
	// 如果已经跳图次数大于等于最大跳图次数, 返回失败
	if (g_iMixCount >= g_iMaxMixCount) {
		return false;
	}

	// 获取当前地图名称
	char MapName[64];
	char CheckMapName[64];
	GetCurrentMap(MapName, sizeof MapName);
	// 创建随机用的动态数组
	ArrayList MapList = new ArrayList(64);

	// 把地图数据推入动态数组 (排除当前地图)
	for (int i = 0; i < g_msMapSet.Length; ++i) {
		g_msMapSet.GetKey(i, CheckMapName, sizeof CheckMapName);
		// 如果只允许官方地图 且 非当前地图且为官方地图, 则加入数组
		if (g_bOnlyOfficialMap && ! StrEqual(MapName, CheckMapName, false) && IsOfficialMap(CheckMapName)) {
			MapList.PushString(CheckMapName);
		// 否则允许全部地图且非当前地图, 则加入数组
		} else if (! g_bOnlyOfficialMap && ! StrEqual(MapName, CheckMapName, false)) {
			MapList.PushString(CheckMapName);
		}
	}
	// 如果数组大小为0 返回失败
	if (! MapList.Length) {
		delete MapList;
		return false;
	}

	// 获取随机的地图名称
	MapList.GetString(GetRandomInt(0, MapList.Length - 1), name, maxLength);

	delete MapList;
	return true;
}

// 检查是否为官方图
bool IsOfficialMap(const char[] MapName) {
	for (int i = 0; i < sizeof officialMap; ++i) {
		if (StrEqual(MapName, officialMap[i], false)) {
			return true;
		}
	}
	return false;
}

#if DEBUG
// DEBUG用
Action Command_Test(int client, int args) {
	if (g_iEnt_ChangeLevelId != INVALID_ENT_REFERENCE) {
		char Name[64];
		char LName[128];
		if (g_iEnt_ChangeLevelId != INVALID_ENT_REFERENCE) {
			GetEntPropString(g_iEnt_ChangeLevelId, Prop_Data, "m_mapName", Name, sizeof Name);
		}
		if (g_iEnt_LandMarkId != INVALID_ENT_REFERENCE) {
			GetEntPropString(g_iEnt_LandMarkId, Prop_Data, "m_iName", LName, sizeof LName);
		}
		ReplyToCommand(client, "过渡到此地图所需实体名: %s", g_sValidLandMarkName);
		ReplyToCommand(client, "ChangeLevel ID: %d, 通关换的图: %s", g_iEnt_ChangeLevelId, Name);
		ReplyToCommand(client, "LandMark ID: %d, 过渡到下一张图的实体名: %s", g_iEnt_LandMarkId, LName);
		ReplyToCommand(client, "是否触发了跳图: %s", g_bIsValid ? "是" : "否");
	} else {
		ReplyToCommand(client, "地图不符合要求, 这是终局吧?");
	}
	ReplyToCommand(client, "MapSet长度: %d", g_msMapSet.Length);
	ReplyToCommand(client, "MapLandMarkSet长度: %d", g_msMapLandMarkSet.Length);
	ReplyToCommand(client, "要过渡的图: %s", g_sTransitionMap[0] != '\0' ? g_sTransitionMap : "无");
	ReplyToCommand(client, "已经跳图次数: %d", g_iMixCount);

	return Plugin_Handled;
}
#endif

#if DEBUG
Action Command_Find(int client, int args) {
	int CId, LId = INVALID_ENT_REFERENCE;
	char LandMarkName[128], BindName[128];

	if ((CId = FindEntityByClassname(CId, "info_changelevel")) != INVALID_ENT_REFERENCE) {
		GetEntPropString(CId, Prop_Data, "m_landmarkName", BindName, sizeof BindName);
		ReplyToCommand(client, "换图所绑landMark实体: %s", BindName);
	}

	while ((LId = FindEntityByClassname(LId, "info_landmark")) != INVALID_ENT_REFERENCE) {
		GetEntPropString(LId, Prop_Data, "m_iName", LandMarkName, sizeof LandMarkName);
		if (StrEqual(LandMarkName, BindName, false)) {
			ReplyToCommand(client, "可修改用过渡实体ID: %d, 名称: %s", LId, LandMarkName);
		} else {
			ReplyToCommand(client, "可提取用过渡实体ID: %d, 名称: %s", LId, LandMarkName);
		}
	}

	return Plugin_Handled;
}
#endif

// 添加地图信息到配置文件
Action Command_AddConfig(int client, int args) {
	// 如果符合添加配置的地图设定
	if (g_sValidLandMarkName[0] != '\0') {
		char Name[64];
		// 获取地图名
		GetCurrentMap(Name, sizeof Name);
		// 相关数据写入哈希表并创建哈希快照
		g_mMapLandMarkSet.SetString(Name, g_sValidLandMarkName);
		g_msMapLandMarkSet = g_mMapLandMarkSet.Snapshot();
		g_mMapSet.SetString(Name, g_sValidLandMarkName);
		g_msMapSet = g_mMapSet.Snapshot();
		// 保存kv配置文件
		SaveKvFile();
		ReplyToCommand(client, "%s Add %s to random map list success!", PREFIX, Name);
	} else {
		ReplyToCommand(client, "%s The map does not meet the requirements to be added, first map cannot be added", PREFIX);
	}
	return Plugin_Handled;
}

// 重载配置文件
Action Command_Reload(int client, int args) {
	int len;
	if (! LoadKvFile(len)) {
		ReplyToCommand(client, "%s Reload list failed.", PREFIX);
	} else {
		ReplyToCommand(client, "%s Reload %d maps success!", PREFIX, len);
	}
	return Plugin_Handled;
}

void CheatCommand(int client, const char[] cmd) {
	int flags = GetCommandFlags(cmd);
	int bits = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, cmd);
	SetCommandFlags(cmd, flags);
	SetUserFlagBits(client, bits);
}

// 是否为第一章节
bool IsFirstMapInScenario() {
	return SDKCall(g_hSDK_CDirector_IsFirstMapInScenario, g_pDirector);
}