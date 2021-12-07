/*ChangeLog-------------------------------------------------------------------------------------------------------------------------------------------
Ver 1.0.0			- 2018/01/19 初期バージョン
Ver 1.1.0			- 2018/01/24
								  [追加] 除去したアイテムの代替に使用するアイテムを指定出来る機能を追加
											除去・置換したアイテムが一つ以上あった場合に、ラウンドスタート直前にプレイヤーに通知する機能を追加
											除去・置換したアイテムの一覧をメニューで見れる機能を追加
								  [変更] アイテムを除去し始めるタイミングをラウンドスタート直前からに変更
Ver 2.0.0			- 2018/01/28
								  [追加] サーバー毎に設定ファイルを切り替えできる機能を追加
											代替可能アイテムに弾薬箱を追加
											代替アイテムにランダムグループを使用できる機能を追加
											除去・置換を行わないマップを指定できる機能を追加
								  [変更] プラグインで使用する各種設定ファイルを複数に分散
											アイテムの除去・置換を始めるタイミングを切り替え出来るように変更 (マップスタート / ラウンドスタート)
Ver 2.0.1			- 2018/01/30	
								  [修正] 軽微なバグの修正
								  [追加] マップ毎に特定のアイテムグループを除去・置換せず、代わりにゾンビへのダメージを無効にできるグループ機能を追加
Ver 2.0.2			- 2018/02/02
								  [修正] 軽微なバグの修正
								  [変更] StartMode の MapStart と RoundStart の値を反転
Ver 2.0.3			- 2018/02/03
								  [修正] サプライボックスから取り出した弾薬箱がすぐに置換されてしまう不具合を修正
Ver 2.0.4			- 2018/02/12
								  [修正] Engine error: ED_Alloc: no free edicts のエラーが発生しないように、代替アイテムのスポーンタイミングを修正
----------------------------------------------------------------------------------------------------------------------------------------------------------*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION 					"2.0.4"
#define CHAT_PREFIX							"\x01[\x04ItemDeleter\x01]"
#define SYSTEM_MAIN_CONFIG 			"configs/item_deleter/item_deleter.cfg"
#define SYSTEM_ITEMS_CONFIG 		"configs/item_deleter/system/id_sys_items.cfg"
#define MAX_RANDOM_GROUP_ITEM	64

enum ErrorType
{
	ErrorType_FileNotFound,
	ErrorType_FileLoadFailed,
	ErrorType_KeyNotFound
};

enum ItemType
{
	ItemType_RandomGroup  = -1,
	ItemType_Generic = 0,
	ItemType_Weapon = 1,
	ItemType_Medical = 2,
	ItemType_AmmoBox = 3,
	ItemType_AmmoBoxRs = 4,
	ItemType_Walkietalkie = 5
};

enum StartMode
{
	StartMode_Disable = 0,
	StartMode_RoundStart = 1,
	StartMode_MapStart = 2
};

public Plugin myinfo = 
{
	name = "[NMRiH]Item Deleter",
	author = "misosiruGT",
	description = "",
	version = PLUGIN_VERSION,
	url = "misosirugt@gmail.com"
}

static StartMode m_startMode = StartMode_Disable;	//除去・置換を開始するタイミング
static char m_sMenuChatCommand[64] = ""	;		//除去・置換したアイテムの一覧メニュー呼び出し用チャットコマンド名
static StringMap m_smItems = null;					//アイテムの除去設定を格納するハッシュマップ
static StringMap m_smItemTypes = null;				//アイテムの種類を格納するハッシュマップ
static StringMap m_smItemWeights = null;			//アイテムの重量を格納するハッシュマップ
static StringMap m_smSubstituteItems = null;		//除去するアイテムの代替に使用するアイテム名を格納するハッシュマップ
static KeyValues m_kvRandomGroups = null;		//代替アイテムをランダムに選ぶために使用するランダムグループを格納する
static StringMap m_smAmmoBoxType = null;		//弾薬箱の種類を格納するハッシュマップ (キーにモデル名、値に弾薬箱の種類)
static StringMap m_smAmmoBoxRsKeys = null;	//ランダムスポナーで使用する弾薬箱の名前を格納するハッシュマップ
static StringMap m_smZombies = null;				//ダメージ無効用にフックしたゾンビのエンティティインデックスを格納するハッシュマップ
static StringMap m_smInvalidWeapons = null;		//マップから除去・置換せずにダメージのみを無効にするアイテム名を格納するハッシュマップ
static char m_sInvalidWeaponGroup[64] = "";		//マップでアイテムの除去・置換・ダメージを無効にするグループ名
static bool m_bNoItemDeleteMap = false;			//アイテムを除去しないマップの確認用
static bool m_bAutoDeleteStart = false;				//エンティティ生成時に自動除去するかの確認用
static bool m_bChatAnnounce = false;					//ラウンドスタート時に除去・置換したアイテムの通知用
static bool m_bAlreadyAnnounce = false;				//ラウンドスタート時に除去・置換したアイテムの通知確認用
static int m_iWeaponsOffset = -1;						//プレイヤーの武器インベントリオフセット

static Menu m_mnDeleteItemInfo = null;			//除去・置換したアイテム一覧メインメニュー
static Menu m_mnDeletedItems = null;			//除去したアイテム一覧メニュー
static Menu m_mnSubstitutedItems = null;		//置換したアイテム一覧メニュー
static Menu m_mnInvalidWeapons = null;			//除去・置換・ダメージ無効のアイテム一覧メニュー

public void OnPluginStart()
{
	CreateConVar("sm_item_deleter_version", PLUGIN_VERSION, "NMRiH Item Deleter Version", 
							FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	char mainConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, mainConfig, sizeof(mainConfig), "%s", SYSTEM_MAIN_CONFIG);
	if (FileExists(mainConfig)) {
		char itemsConfig[PLATFORM_MAX_PATH];
		LoadMainData(mainConfig, itemsConfig, sizeof(itemsConfig));

		char sysItemsConfig[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sysItemsConfig, sizeof(sysItemsConfig), "%s", SYSTEM_ITEMS_CONFIG);
		if (FileExists(sysItemsConfig)) {
			if (FileExists(itemsConfig)) {
				m_smItems = new StringMap();
				m_smItemTypes = new StringMap();
				m_smItemWeights = new StringMap();
				m_smSubstituteItems = new StringMap();
				m_kvRandomGroups = new KeyValues("random_groups");
				m_smInvalidWeapons = new StringMap();
				m_smZombies = new StringMap();
				m_smAmmoBoxType = new StringMap();
				m_smAmmoBoxRsKeys = new StringMap();
				BuildDeleteItemInfoMenus();
				LoadItemsData(sysItemsConfig, true);	//システムで使用するアイテム設定の取得
				LoadItemsData(itemsConfig, false);		//変更可能なアイテム設定の取得
			
			} else {
				SetConfigError(ErrorType_FileNotFound, itemsConfig);
			}
		} else {
			SetConfigError(ErrorType_FileNotFound, sysItemsConfig);
		}
	} else {
		SetConfigError(ErrorType_FileNotFound, mainConfig);
	}
	
	LoadTranslations("nmrih_item_deleter.phrases");
	LoadTranslations("nmrih_item_shop_y9v12.phrases"); //アイテム名の翻訳に使用
	
	if (!IsEmptyString(m_sMenuChatCommand)) {
		RegConsoleCmd(m_sMenuChatCommand, Command_DeleteItemInfo);
	}
	
	m_iWeaponsOffset = FindSendPropInfo("CNMRiH_Player", "m_hMyWeapons");
	HookEvent("state_change", Event_StateChange, EventHookMode_Pre);
	HookEvent("nmrih_practice_ending", Event_StateChange, EventHookMode_Pre);
	HookEvent("nmrih_reset_map", Event_StateChange, EventHookMode_Pre);
}

public void OnMapStart()
{
	if (m_startMode == StartMode_MapStart && (!m_bNoItemDeleteMap || (m_bNoItemDeleteMap && m_smInvalidWeapons.Size > 0))) {
		AllEdictsCheck();
		m_bAutoDeleteStart = true;
	}
}

public void OnMapEnd()
{
	m_bAutoDeleteStart = false;
	m_bAlreadyAnnounce = false;
}

public Action Event_StateChange(Event event, const char[] name, bool dontBroadcast)
{
	if (m_startMode == StartMode_Disable) return Plugin_Continue;
	
	if (StrEqual(name, "nmrih_practice_ending")) {
		m_bAlreadyAnnounce = false;
		
	} else if (StrEqual(name, "nmrih_reset_map")) {
		if (m_startMode == StartMode_RoundStart) {
			m_bAutoDeleteStart = false;
		}
	} else if (StrEqual(name, "state_change") && event.GetInt("state") == 2) {	//state 2 Practice End Freeze
		if (m_startMode == StartMode_RoundStart && (!m_bNoItemDeleteMap || (m_bNoItemDeleteMap && m_smInvalidWeapons.Size > 0))) {
			AllEdictsCheck();
			m_bAutoDeleteStart = true;
		}
		
		if (m_bChatAnnounce && !m_bAlreadyAnnounce) {
			if (m_bNoItemDeleteMap && m_smInvalidWeapons.Size == 0) {
				PrintToChatAll("%s %t", CHAT_PREFIX, "Round start announce No item delete map");
				
			} else {
				if (m_mnDeletedItems.ItemCount > 0 || m_mnSubstitutedItems.ItemCount > 0) {
					if (!IsEmptyString(m_sMenuChatCommand)) {
						char cmdName[64];
						FormatEx(cmdName, sizeof(cmdName), "\x04!%s\x01", m_sMenuChatCommand);
						PrintToChatAll("%s %t", CHAT_PREFIX, "Round start announce", cmdName);
					} else {
						PrintToChatAll("%s %t", CHAT_PREFIX, "Round start announce No command");
					}
				}
				if (m_bNoItemDeleteMap && m_smInvalidWeapons.Size > 0) {
					PrintToChatAll("%s %t", CHAT_PREFIX, "Round start announce Invalid items");
				}
			}
			m_bAlreadyAnnounce = true;
		}
	}

	return Plugin_Continue;
}

//全てのエンティティをチェックして除去・置換するアイテムを探す
void AllEdictsCheck()
{
	int maxEdicts = GetMaxEntities();
	for (int ent = MaxClients + 1; ent <= maxEdicts; ent++) {
		if (IsValidEdict(ent)) {
			char className[64];
			GetEdictClassname(ent, className, sizeof(className));
			int val; //ダメージ無効アイテムの確認に使う。中身は常に 0
			if (!m_smInvalidWeapons.GetValue(className, val)) {
				if (GetItemType(className) == ItemType_AmmoBox) {
					if (IsDeleteAmmoBox(ent)) {
						DeleteAmmoBox(ent);
					}
				} else if (IsDeleteItem(className)) {
					DeleteItem(ent);
				}
			}
		}
	}	
}

//除去・置換したアイテムの一覧メニュー表示
public Action Command_DeleteItemInfo(int client, int args)
{
	if (client > 0) {
		if (m_startMode == StartMode_Disable) {
			PrintToChat(client, "%s %t", CHAT_PREFIX, "Deleter disabled");
			
		} else if (m_bNoItemDeleteMap && m_smInvalidWeapons.Size == 0) {
			PrintToChat(client, "%s %t", CHAT_PREFIX, "No item delete map");
			
		} else {
			m_mnDeleteItemInfo.Display(client, MENU_TIME_FOREVER);
		}
	}
	
	return Plugin_Handled;
}

//エンティティが生成された (スポーンはしていない)
public void OnEntityCreated(int entity, const char[] classname)
{
	if (m_startMode == StartMode_Disable) return;
	
	int val;	//ダメージ無効アイテムの確認に使う。中身は常に 0
	if (m_bAutoDeleteStart && (!m_bNoItemDeleteMap || (m_bNoItemDeleteMap && !m_smInvalidWeapons.GetValue(classname, val)))) {
		if (GetItemType(classname) == ItemType_AmmoBox) {
			SDKHook(entity, SDKHook_SpawnPost, OnDeleteTargetAmmoBox_Spawn);
			
		} else if (IsDeleteItem(classname)) {	
			SDKHook(entity, SDKHook_SpawnPost, OnDeleteTargetItem_Spawn);
		}
	}
	
	if (m_bNoItemDeleteMap && m_smInvalidWeapons.Size > 0 && IsZombie(classname)) {
		SDKHook(entity, SDKHook_OnTakeDamage, OnZombieTakeDamage);
		char entNum[8];
		IntToString(entity, entNum, sizeof(entNum));
		m_smZombies.SetValue(entNum, 0);
	}
	
}

//エンティティが破棄された
public void OnEntityDestroyed(int entity)
{
	if (m_bNoItemDeleteMap && m_smInvalidWeapons.Size > 0) {
		char entNum[8];
		IntToString(entity, entNum, sizeof(entNum));
		if (m_smZombies.Remove(entNum)) {
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnZombieTakeDamage);
		}
	}
}

//ゾンビがダメージを受ける前
public Action OnZombieTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (MaxClients >= attacker > 0) {
		char className[64];
		GetEdictClassname(inflictor, className, sizeof(className));
		int val; //ダメージ無効アイテムの確認に使う。中身は常に 0
		//武器に設定されているグループが登録されていたら、ゾンビへのダメージを 0 にする
		if (m_smInvalidWeapons.GetValue(className, val)) {
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

//除去対象のアイテムがスポーンした
public Action OnDeleteTargetItem_Spawn(int entity)
{
	CreateTimer(0.0, Timer_DeleteItem_Delay, entity, TIMER_FLAG_NO_MAPCHANGE);
	SDKUnhook(entity, SDKHook_SpawnPost, OnDeleteTargetItem_Spawn);
	
	return Plugin_Stop;
}

//除去対象の弾薬箱がスポーンした
public Action OnDeleteTargetAmmoBox_Spawn(int entity)
{
	if (IsDeleteAmmoBox(entity)) {
		CreateTimer(0.0, Timer_DeleteAmmoBox_Delay, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
	SDKUnhook(entity, SDKHook_SpawnPost, OnDeleteTargetAmmoBox_Spawn);
	
	return Plugin_Stop;
}

//スポーンした除去対象アイテムを１ゲームフレーム待ってから処理する
public Action Timer_DeleteItem_Delay(Handle timer, any data)
{
	DeleteItem(data);
}

//スポーンした除去対象弾薬箱を１ゲームフレーム待ってから処理する
public Action Timer_DeleteAmmoBox_Delay(Handle timer, any data)
{
	DeleteAmmoBox(data);
}

//アイテムを除去する (代替アイテムがある場合、それと置き換える)
void DeleteItem(int entity)
{
	if (!IsValidEdict(entity)) return;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	char className[64], substituteItemName[64];
	float vecOrigin[3];
	DataPack dp;
	
	GetEdictClassname(entity, className, sizeof(className));
	//除去対象アイテムの代替アイテムは設定されているか？
	if (m_smSubstituteItems.GetString(className, substituteItemName, sizeof(substituteItemName))) {
		dp = new DataPack();
		CreateDataTimer(1.0, Timer_SpawningSubstituteItem_Delay, dp, TIMER_FLAG_NO_MAPCHANGE);
		dp.WriteString(substituteItemName);
		//除去対象アイテムの所有者はプレイヤーか？
		if (0 < owner && owner <= MaxClients) {
			GetClientAbsOrigin(owner, vecOrigin);
			dp.WriteFloat(vecOrigin[0]);
			dp.WriteFloat(vecOrigin[1]);
			dp.WriteFloat(vecOrigin[2]);
			dp.WriteCell(owner);
			dp.WriteCell((GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon") == entity));
			
			//プレイヤーのインベントリからアイテムを直接除去すると総重量が狂うので調整する
			int itemWeight;
			int playerCarriedWeight = GetEntProp(owner, Prop_Send, "_carriedWeight");
			if (m_smItemWeights.GetValue(className, itemWeight)) {
				if (playerCarriedWeight >= itemWeight) {
					playerCarriedWeight -= itemWeight;
					SetEntProp(owner, Prop_Send, "_carriedWeight", playerCarriedWeight);
				}
			}
		} else {
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
			dp.WriteFloat(vecOrigin[0]);
			dp.WriteFloat(vecOrigin[1]);
			dp.WriteFloat(vecOrigin[2]);
			dp.WriteCell(INVALID_ENT_REFERENCE);
			dp.WriteCell(false);
		}
	}
	
	//除去対象アイテムを除去する
	AcceptEntityInput(entity, "Kill");
}

//弾薬箱を除去する (代替アイテムがある場合、それと置き換える)
void DeleteAmmoBox(int entity)
{
	if (!IsValidEdict(entity)) return;
	
	char ammoModel[PLATFORM_MAX_PATH], ammoType[32], substituteItemName[64];
	GetEntPropString(entity, Prop_Data, "m_ModelName", ammoModel, sizeof(ammoModel));
	m_smAmmoBoxType.GetString(ammoModel, ammoType, sizeof(ammoType));
	
	//除去対象アイテムの代替アイテムは設定されているか？
	if (m_smSubstituteItems.GetString(ammoType, substituteItemName, sizeof(substituteItemName))) {
		DataPack dp = new DataPack();
		CreateDataTimer(1.0, Timer_SpawningSubstituteItem_Delay, dp, TIMER_FLAG_NO_MAPCHANGE);
		dp.WriteString(substituteItemName);
		float vecOrigin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
		dp.WriteFloat(vecOrigin[0]);
		dp.WriteFloat(vecOrigin[1]);
		dp.WriteFloat(vecOrigin[2]);
		dp.WriteCell(INVALID_ENT_REFERENCE);
		dp.WriteCell(false);
	}
	
	//除去対象アイテムを除去する
	AcceptEntityInput(entity, "Kill");
}

//代替アイテムの処理を１秒遅らせる
public Action Timer_SpawningSubstituteItem_Delay(Handle timer, Handle pack)
{
	DataPack dp = view_as<DataPack>(pack);
	char substituteItemName[64];
	float itemOrigin[3];
	
	dp.Reset();
	dp.ReadString(substituteItemName, sizeof(substituteItemName));
	itemOrigin[0] = dp.ReadFloat();
	itemOrigin[1] = dp.ReadFloat();
	itemOrigin[2] = dp.ReadFloat() + 1.0;	//代替アイテムがマップ外に落ちないように高さを +1.0
	int player = dp.ReadCell();
	bool isPlayerSwitchItem = dp.ReadCell();
	SpawningSubstituteItem(substituteItemName, itemOrigin, player, isPlayerSwitchItem);
}

//代替アイテムを生成・スポーンさせる
void SpawningSubstituteItem(const char[] itemName, float origin[3], int player, bool isPlayerSwitchItem)
{
	ItemType substituteItemType;
	int substituteItem = CreateSubstituteItem(itemName, substituteItemType);
	if (substituteItem == INVALID_ENT_REFERENCE || !DispatchSpawn(substituteItem)) {
		return;
	}
	
	TeleportEntity(substituteItem, origin, NULL_VECTOR, NULL_VECTOR);
	
	if (player != INVALID_ENT_REFERENCE) {
		if (IsClientInGame(player) && IsPlayerAlive(player)) {
			if (substituteItemType != ItemType_AmmoBoxRs) {
				AcceptEntityInput(substituteItem, "Use", player);
			}
			if (isPlayerSwitchItem) {
				if (IsPlayerHaveItemEnt(player, substituteItem) && substituteItemType == ItemType_Weapon) {
					SetEntPropEnt(player, Prop_Send, "m_hActiveWeapon", substituteItem);	//代替アイテムを持っていて、装備可能なので切り替える
					
				} else {	//代替アイテムは装備不可かプレイヤーの足元にあるので、装備を「素手」に切り替える
					int weapon_Fists = GetEntDataEnt2(player, m_iWeaponsOffset);
					if (IsValidEdict(weapon_Fists)) {
						SetEntPropEnt(player, Prop_Send, "m_hActiveWeapon", weapon_Fists);
					}
				}
				ChangeEdictState(player, GetEntSendPropOffs(player, "m_hActiveWeapon"));
			}
		} else {
			//代替アイテムがあり、かつ除去対象アイテムの所有者がサーバーから切断、または死亡していたら生成した代替アイテムをキルする
			AcceptEntityInput(substituteItem, "Kill");
		}
	}
	
	if (substituteItemType == ItemType_AmmoBoxRs) {
		AcceptEntityInput(substituteItem, "InputSpawn");
		AcceptEntityInput(substituteItem, "Kill");
	}
}

//代替アイテムを生成してエンティティインデックスとアイテムの種類を返す
int CreateSubstituteItem(const char[] className, ItemType &itemType)
{
	int itemEnt = INVALID_ENT_REFERENCE;
	
	switch (GetItemType(className)) {
		case ItemType_RandomGroup: {
			char randomItemName[64];
			if (GetRandomGroupItem(className, randomItemName, sizeof(randomItemName))) {
				ItemType randomItemType = GetItemType(randomItemName);
				if (randomItemType != ItemType_RandomGroup && randomItemType != ItemType_Generic) {
					//ランダムグループから選ばれた代替アイテムを再帰呼出しで生成する
					itemEnt = CreateSubstituteItem(randomItemName, itemType);
				}
			}
		}
		case ItemType_Weapon, ItemType_Medical, ItemType_Walkietalkie: {
			itemEnt = CreateEntityByName(className);
			char substituteItemName[64];
			GetEdictClassname(itemEnt, substituteItemName, sizeof(substituteItemName));
			itemType = GetItemType(substituteItemName);
		}
		case ItemType_AmmoBox: {
			char rsKey[64];
			if (m_smAmmoBoxRsKeys.GetString(className, rsKey, sizeof(rsKey))) {
				itemEnt = CreateEntityByName("random_spawner");
				if (itemEnt != INVALID_ENT_REFERENCE) {
					DispatchKeyValue(itemEnt, rsKey, "100");
					DispatchKeyValue(itemEnt, "ammo_fill_pct_max", "100");
					DispatchKeyValue(itemEnt, "ammo_fill_pct_min", "100");
					DispatchKeyValue(itemEnt, "spawnflags", "2");	//Don't spawn on map start
					itemType = ItemType_AmmoBoxRs;
				}
			}
		}
	}
	
	return itemEnt;
}

//指定したクラス名からアイテムの種類を調べる
ItemType GetItemType(const char[] className)
{
	ItemType type;
	
	if (StrEqual(className, "item_ammo_box")) {
		type = ItemType_AmmoBox;
		
	} else if (!m_smItemTypes.GetValue(className, type)) {
		type = ItemType_Generic;
	}
	
	return type;
}

//アイテムの除去設定を調べる
bool IsDeleteItem(const char[] className)
{
	bool deleteFlag = false;
	return (m_smItems.GetValue(className, deleteFlag) && deleteFlag);
}

//弾薬箱の除去設定を調べる
bool IsDeleteAmmoBox(int entity)
{
	char ammoModel[PLATFORM_MAX_PATH], ammoType[32];
	GetEntPropString(entity, Prop_Data, "m_ModelName", ammoModel, sizeof(ammoModel));
	m_smAmmoBoxType.GetString(ammoModel, ammoType, sizeof(ammoType));
	
	bool deleteFlag = false;
	return (m_smItems.GetValue(ammoType, deleteFlag) && deleteFlag);
}

//ランダムグループから代替アイテムを一つ返す
bool GetRandomGroupItem(const char[] groupName, char[] randomItem, int randomItemMaxLength)
{
	int itemCount = 0;
	char groupItems[MAX_RANDOM_GROUP_ITEM][64];
	
	if (m_kvRandomGroups.JumpToKey(groupName, false)) {
		if (m_kvRandomGroups.GotoFirstSubKey(false)) {
			do {
				char itemName[64];
				m_kvRandomGroups.GetSectionName(itemName, sizeof(itemName));
				if (itemCount < MAX_RANDOM_GROUP_ITEM) {
					strcopy(groupItems[itemCount], sizeof(groupItems[]), itemName);
					itemCount++;
				} else {
					break;
				}
			} while (m_kvRandomGroups.GotoNextKey(false));
		}
		m_kvRandomGroups.Rewind();
		strcopy(randomItem, randomItemMaxLength, groupItems[GetRandomInt(0, itemCount - 1)]);
		return true;
	}
	
	return false;
}

//プレイヤーが既に同じアイテムを持っているかを調べる (弾薬箱には対応していない)
stock bool IsPlayerHaveItem(int client, const char[] newItemName)
{
	for (int i = 0; i <= 47; i++) {
		int item = GetEntDataEnt2(client, m_iWeaponsOffset + i * 4);
		if (item != INVALID_ENT_REFERENCE) {
			char className[64];
			GetEdictClassname(item, className, sizeof(className));
			if (StrEqual(className, newItemName)) {
				return true;
			}
		}
	}
	return false;
}

//指定したアイテムエンティティをプレイヤーが持っているかを調べる (弾薬箱には対応していない)
bool IsPlayerHaveItemEnt(int client, int checkItem)
{
	for (int i = 0; i <= 47; i++) {
		int item = GetEntDataEnt2(client, m_iWeaponsOffset + i * 4);
		if (item != INVALID_ENT_REFERENCE && item == checkItem) {
			return true;
		}
	}
	return false;
}

//メイン設定をファイルから取得する
void LoadMainData(const char[] filePath, char[] itemsConfigPath, int maxLength)
{	
	KeyValues kv = new KeyValues("ItemDeleter");
	
	if (kv.ImportFromFile(filePath)) {
		kv.GetString("menu_chat_command", m_sMenuChatCommand, sizeof(m_sMenuChatCommand));	//メニュー呼び出し用コマンド名の取得
		
		char ip[32], port[12], serverIpPort[64];
		LongIpToString(FindConVar("hostip").IntValue, '.', ip, sizeof(ip));
		FindConVar("hostport").GetString(port, sizeof(port));
		FormatEx(serverIpPort, sizeof(serverIpPort), "%s:%s", ip, port);
		
		//サーバーIP+Port または default のキーが存在するか？存在するならそのキーへジャンプ
		if (!kv.JumpToKey(serverIpPort, false) && !kv.JumpToKey("default", false)) {
			SetConfigError(ErrorType_KeyNotFound, filePath, "default");	//どちらのキーも存在しないので、プラグインを終了させる
		}
		kv.GetString("items_config", itemsConfigPath, maxLength);
		BuildPath(Path_SM, itemsConfigPath, maxLength, "%s", itemsConfigPath);
		m_startMode = view_as<StartMode>(kv.GetNum("delete_start_mode", 0));
		m_bChatAnnounce = view_as<bool>(kv.GetNum("chat_announce", 0));
		
		//現在のマップがアイテム除去を行わないマップか調べる
		char noItemDeleteMaps[PLATFORM_MAX_PATH];
		kv.GetString("no_item_delete_maps", noItemDeleteMaps, sizeof(noItemDeleteMaps));
		if (!IsEmptyString(noItemDeleteMaps))  {
			BuildPath(Path_SM, noItemDeleteMaps, sizeof(noItemDeleteMaps), "%s", noItemDeleteMaps);
			if (FileExists(noItemDeleteMaps)) {
				KeyValues kvMaps = new KeyValues("ItemDeleter_NoItemDeleteMaps");
				if (kvMaps.ImportFromFile(noItemDeleteMaps)) {
					char currentMap[128];
					GetCurrentMap(currentMap, sizeof(currentMap));
					if (kvMaps.JumpToKey(currentMap, false)) {
						kvMaps.GetString(NULL_STRING, m_sInvalidWeaponGroup, sizeof(m_sInvalidWeaponGroup));
						m_bNoItemDeleteMap = true;
					}
				}
				delete kvMaps;
			}
		}
		
	} else {	//ファイルの読み込みに失敗した
		SetConfigError(ErrorType_FileLoadFailed, filePath);
	}
	
	delete kv;
}

//アイテムの設定をファイルから取得する(システムアイテムデータ取得と共有)
void LoadItemsData(const char[] filePath, bool IsSystemData)
{
	KeyValues kv = new KeyValues(IsSystemData ? "ItemDeleter_System_Items" : "ItemDeleter_Items");
	
	if (!kv.ImportFromFile(filePath)) {
		//ファイルの読み込みに失敗した
		SetConfigError(ErrorType_FileLoadFailed, filePath);
		return;
	}
	//アイテムの除去・置換設定の取得
	if (kv.JumpToKey("items", false)) {
		if (kv.GotoFirstSubKey(false)) {
			do {
				char itemName[64];
				kv.GetSectionName(itemName, sizeof(itemName));
				if (StrEqual(itemName, "me_fists") || StrEqual(itemName, "item_zippo")) {
					continue;
					
				} else if (IsSystemData) {	
					ItemType type = view_as<ItemType>(kv.GetNum("item_type", 0));
					int weight = kv.GetNum("weight", 0);
					m_smItemTypes.SetValue(itemName, type);
					m_smItemWeights.SetValue(itemName, weight);
				} else {
					bool isDelete = view_as<bool>(kv.GetNum("delete", 0));
					char substituteItemName[64], damageGroupName[64];
					kv.GetString("substitute_item", substituteItemName, sizeof(substituteItemName));
					kv.GetString("weapon_group", damageGroupName, sizeof(damageGroupName));
					m_smItems.SetValue(itemName, isDelete);
					if (m_bNoItemDeleteMap && !IsEmptyString(damageGroupName) && StrEqual(damageGroupName, m_sInvalidWeaponGroup)) {
						m_smInvalidWeapons.SetValue(itemName, 0);
						m_mnInvalidWeapons.AddItem(itemName, itemName, ITEMDRAW_DISABLED);
						
					} else if (!IsEmptyString(substituteItemName) && isDelete) {
						m_smSubstituteItems.SetString(itemName, substituteItemName);
						m_mnSubstitutedItems.AddItem(itemName, substituteItemName, ITEMDRAW_DISABLED);
						
					} else if (isDelete) {
						m_mnDeletedItems.AddItem(itemName, itemName, ITEMDRAW_DISABLED);
					}
				}
			} while (kv.GotoNextKey(false));
		}
		kv.Rewind();
	}
	//弾薬箱の除去・置換設定の取得
	if (kv.JumpToKey("ammo_boxes", false)) {
		if (kv.GotoFirstSubKey(false)) {
			bool invalid = false;
			if (!IsSystemData) {
				char weaponGroupName[64];
				kv.GetString(NULL_STRING, weaponGroupName, sizeof(weaponGroupName));
				if (m_bNoItemDeleteMap && !IsEmptyString(weaponGroupName) && StrEqual(weaponGroupName, m_sInvalidWeaponGroup)) {
					m_smInvalidWeapons.SetValue("item_ammo_box", 0);
					invalid = true;
					kv.GotoNextKey(false);
				}
			}
			do {
				char ammoBoxName[64];
				kv.GetSectionName(ammoBoxName, sizeof(ammoBoxName));
				if (IsSystemData) {
					char modelPath[PLATFORM_MAX_PATH], rsKey[64];
					ItemType type = view_as<ItemType>(kv.GetNum("item_type", 0));
					kv.GetString("model", modelPath, sizeof(modelPath));
					kv.GetString("rs_key", rsKey, sizeof(rsKey));
					m_smItemTypes.SetValue(ammoBoxName, type);
					if (!IsEmptyString(modelPath)) {
						m_smAmmoBoxType.SetString(modelPath, ammoBoxName);
					}
					if (!IsEmptyString(rsKey)) {
						m_smAmmoBoxRsKeys.SetString(ammoBoxName, rsKey);
					}
				} else {
					char substituteItemName[64];
					bool isDelete = view_as<bool>(kv.GetNum("delete", 0));
					kv.GetString("substitute_item", substituteItemName, sizeof(substituteItemName));
					m_smItems.SetValue(ammoBoxName, isDelete);
					if (invalid) {
						m_mnInvalidWeapons.AddItem(ammoBoxName, ammoBoxName, ITEMDRAW_DISABLED);
						
					} else if (!invalid && !IsEmptyString(substituteItemName) && isDelete) {
						m_smSubstituteItems.SetString(ammoBoxName, substituteItemName);
						m_mnSubstitutedItems.AddItem(ammoBoxName, substituteItemName, ITEMDRAW_DISABLED);
						
					} else if (!invalid && isDelete) {
						m_mnDeletedItems.AddItem(ammoBoxName, ammoBoxName, ITEMDRAW_DISABLED);
					}
				}
			} while (kv.GotoNextKey(false));
		}
		kv.Rewind();
	}
	//代替アイテムに使用するランダムグループ設定の取得
	if (kv.JumpToKey("random_groups", false)) {
		if (kv.GotoFirstSubKey(false)) {
			do {
				char groupName[64];
				kv.GetSectionName(groupName, sizeof(groupName));
				m_kvRandomGroups.JumpToKey(groupName, true);
				int itemCount = 0;
				if (kv.GotoFirstSubKey(false)) {
					do {
						char randomItemName[64];
						kv.GetSectionName(randomItemName, sizeof(randomItemName));
						m_kvRandomGroups.SetNum(randomItemName, 0);
						itemCount++;
					} while (kv.GotoNextKey(false));
					if (itemCount > 0) {
						m_smItemTypes.SetValue(groupName, ItemType_RandomGroup);
					} else {
						m_kvRandomGroups.DeleteKey(groupName);
					}
					m_kvRandomGroups.Rewind();
					kv.GoBack();
				}
			} while (kv.GotoNextKey(false));
		}
		kv.Rewind();
	}
	
	delete kv;
}

//設定ファイルの読み込みに失敗した。プラグインを終了する。
void SetConfigError(ErrorType type, const char[] filePath, const char[] keyName = "")
{
	char errorMsg[512];
	
	switch (type) {
		case ErrorType_FileNotFound: {
			FormatEx(errorMsg, sizeof(errorMsg), "Config file(%s) was not found.", filePath);
		}
		case ErrorType_FileLoadFailed: {
			FormatEx(errorMsg, sizeof(errorMsg), "Config file(%s) load error.", filePath);
		}
		case ErrorType_KeyNotFound: {
			FormatEx(errorMsg, sizeof(errorMsg), "Key name(%s) was not found in (%s)", keyName, filePath);
		}
	}
	
	SetFailState(errorMsg);
}

//除去・置換したアイテムの一覧メニューを生成
void BuildDeleteItemInfoMenus()
{
	m_mnDeleteItemInfo = new Menu(Menu_Main, MenuAction_DrawItem | MenuAction_DisplayItem);
	m_mnDeletedItems = new Menu(Menu_Sub, MenuAction_Display | MenuAction_DrawItem | MenuAction_DisplayItem);
	m_mnSubstitutedItems = new Menu(Menu_Sub, MenuAction_Display | MenuAction_DrawItem | MenuAction_DisplayItem);
	m_mnInvalidWeapons = new Menu(Menu_Sub, MenuAction_Display | MenuAction_DrawItem | MenuAction_DisplayItem);
	
	m_mnDeleteItemInfo.SetTitle("** Delete Items Info **\n ");
	m_mnDeleteItemInfo.AddItem("1", "Menu Deleted items");
	m_mnDeleteItemInfo.AddItem("2", "Menu Substituted items");
	m_mnDeleteItemInfo.AddItem("3", "Menu Invalid items");
	
	m_mnDeletedItems.SetTitle("Menu Deleted items");
	m_mnDeletedItems.ExitBackButton = true;
	
	m_mnSubstitutedItems.SetTitle("Menu Substituted items");
	m_mnSubstitutedItems.ExitBackButton = true;
	
	m_mnInvalidWeapons.SetTitle("Menu Invalid items");
	m_mnInvalidWeapons.ExitBackButton = true;
}

//メインメニュー コールバック
public int Menu_Main(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action) {
		case MenuAction_Select: {
			char info[8], disp[64];
			menu.GetItem(param2, info, sizeof(info), _, disp, sizeof(disp));
			switch (StringToInt(info)) {
				case 1: {	//Deleted items
					m_mnDeletedItems.Display(param1, MENU_TIME_FOREVER);
				}
				case 2: {	//Substituted items
					m_mnSubstitutedItems.Display(param1, MENU_TIME_FOREVER);
				}
				case 3: {	//Invalid weapons
					m_mnInvalidWeapons.Display(param1, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_DrawItem: {
			char info[8];
			int itemCount = 0;
			menu.GetItem(param2, info, sizeof(info));
			switch (StringToInt(info)) {
				case 1: itemCount = m_mnDeletedItems.ItemCount;
				case 2: itemCount = m_mnSubstitutedItems.ItemCount;
				case 3: itemCount = m_smInvalidWeapons.Size;
			}
			return (itemCount > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
		case MenuAction_DisplayItem: {
			int itemCount = 0;
			char info[8], disp[64], buffer[128];
			menu.GetItem(param2, info, sizeof(info), _, disp, sizeof(disp));
			switch (StringToInt(info)) {
				case 1: itemCount = m_mnDeletedItems.ItemCount;
				case 2: itemCount = m_mnSubstitutedItems.ItemCount;
				case 3: itemCount = m_smInvalidWeapons.Size;
			}
			FormatEx(buffer, sizeof(buffer), "%T (%d)", disp, param1, itemCount);
			return RedrawMenuItem(buffer);
		}
	}
	return 0;
}

//サブメニュー (除去・置換共通) コールバック
public int Menu_Sub(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action) {
		case MenuAction_Display: {
			Panel panel = view_as<Panel>(param2);
			char title[64], tTitle[64], buffer[128];
			menu.GetTitle(title, sizeof(title));
			FormatEx(tTitle, sizeof(tTitle), "%T", title, param1);
			if (menu == m_mnDeletedItems) {
				FormatEx(buffer, sizeof(buffer), "---- %s ----\n ", tTitle);
				
			} else if (menu == m_mnSubstitutedItems) {
				FormatEx(buffer, sizeof(buffer), "-+-+ %s +-+-\n ", tTitle);
				
			} else {
				FormatEx(buffer, sizeof(buffer), "~~~~ %s ~~~~\n ", tTitle);
			}
			panel.SetTitle(buffer);
		}
		case MenuAction_Select: {	//置換アイテムにランダムグループが設定されている項目のみ
			char info[64], disp[64], tDescription[256];
			menu.GetItem(param2, info, sizeof(info), _, disp, sizeof(disp));
			FormatEx(tDescription, sizeof(tDescription), "%T", "Menu Random substituted items description", param1);
			Menu randomMenu = new Menu(Menu_RandomItems, MenuAction_DrawItem | MenuAction_DisplayItem);
			randomMenu.SetTitle("?+- %T -+?\n%s\n ", info, param1, tDescription);
			if (m_kvRandomGroups.JumpToKey(disp, false)) {
				if (m_kvRandomGroups.GotoFirstSubKey(false)) {
					do {
						char itemName[64];
						m_kvRandomGroups.GetSectionName(itemName, sizeof(itemName));
						randomMenu.AddItem(info, itemName, ITEMDRAW_DISABLED);
						
					} while (m_kvRandomGroups.GotoNextKey(false));
				}
				m_kvRandomGroups.Rewind();
			}
			randomMenu.ExitBackButton = true;
			randomMenu.Display(param1, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack) {
				m_mnDeleteItemInfo.Display(param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_DrawItem: {
			int style;
			char disp[64];
			menu.GetItem(param2, "", 0, style, disp, sizeof(disp));
			return (menu == m_mnSubstitutedItems && GetItemType(disp) == ItemType_RandomGroup ? ITEMDRAW_DEFAULT : style);
		}
		case MenuAction_DisplayItem: {
			char info[64], disp[64], buffer[128];
			menu.GetItem(param2, info, sizeof(info), _, disp, sizeof(disp));
			if (menu == m_mnDeletedItems || menu == m_mnInvalidWeapons) {
				FormatEx(buffer, sizeof(buffer), "%T", info, param1);
				
			} else {
				char tItemName[128];
				FormatEx(tItemName, sizeof(tItemName), "%T", info, param1);
				if  (GetItemType(disp) == ItemType_RandomGroup) {
					FormatEx(buffer, sizeof(buffer), "%s --> Random", tItemName);
					
				} else {
					char tSubstituteItemName[128];
					FormatEx(tSubstituteItemName, sizeof(tSubstituteItemName), "%T", disp, param1);
					FormatEx(buffer, sizeof(buffer), "%s --> %s", tItemName, tSubstituteItemName);
				}
			}
			return RedrawMenuItem(buffer);
		}
	}
	return 0;
}

//ランダムグループアイテムメニュー コールバック
public int Menu_RandomItems(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action) {
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack) {
				m_mnDeleteItemInfo.Display(param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_DrawItem: {
			int style;
			menu.GetItem(param2, "", 0, style);
			return style;
		}
		case MenuAction_DisplayItem: {
			char disp[64], tItemName[128];
			menu.GetItem(param2, "", 0, _, disp, sizeof(disp));
			FormatEx(tItemName, sizeof(tItemName), "%T", disp, param1);
			return RedrawMenuItem(tItemName);
		}
	}
	return 0;
}

//整数のIPを文字列のIPに変換する
stock void LongIpToString(int longIp, char delimiter, char[] buffer, int maxLength)
{
	int pieces[4];

	pieces[0] = (longIp >> 24) & 0x000000FF;
	pieces[1] = (longIp >> 16) & 0x000000FF;
	pieces[2] = (longIp >> 8) & 0x000000FF;
	pieces[3] = longIp & 0x000000FF;

	FormatEx(buffer, maxLength, "%d%s%d%s%d%s%d", pieces[0], delimiter, pieces[1], delimiter, pieces[2], delimiter, pieces[3]);
}

//指定したchar型配列の値が空文字列か調べる
stock bool IsEmptyString(const char[] string)
{
	return (string[0] == '\0');
}

//指定したクラス名がゾンビが調べる
stock bool IsZombie(const char[] className)
{
	return (StrEqual(className, "npc_nmrih_shamblerzombie") || StrEqual(className, "npc_nmrih_runnerzombie")
				|| StrEqual(className, "npc_nmrih_kidzombie") || StrEqual(className, "npc_nmrih_tunnedzombie"));
}