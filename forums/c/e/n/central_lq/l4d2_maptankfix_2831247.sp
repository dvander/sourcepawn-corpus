#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define DEBUG		   0
#define PLUGIN_VERSION "1.1"
#define GAMEDATA	   "fix_maptank.games"

bool			 g_bHaveKick;

int				 g_iTankFix;
ConVar			 g_Onoff;
ArrayList 		 g_aEntList;
Handle			 g_hdAcceptInput, g_hSpecialSpawn;

stock const char L4D2_Infectedprops[10][] = {
	"",
	"m_tongueVictim",
	"",
	"m_pounceVictim",
	"",
	"m_jockeyVictim",
	"m_pummelVictim",
	"",
	"",
	""
};

public Plugin myinfo =
{
	name		= "[L4D2] 地图机关tank生成修复",
	author		= "洛琪",
	description = "防止地图自带的机关tank因为槽位问题无法刷新而造成的机关卡关(如伦理机关克等)[绝境]",
	version		= PLUGIN_VERSION,
	url			= "https://steamcommunity.com/profiles/76561198812009299/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "插件只支持求生之路2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_aEntList = new ArrayList();
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if (FileExists(sPath) == false) SetFailState("\n==========\nMissing required file: \"%s\".==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if (hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	int offset = GameConfGetOffset(hGameData, "AcceptInput");
	if (offset == 0) SetFailState("Failed to load \"AcceptInput\", invalid offset.");

	g_hSpecialSpawn = DHookCreateFromConf(hGameData, "L4DD::ZombieManager::SpawnSpecial");
	if (!g_hSpecialSpawn) SetFailState("Failed to find \"L4DD::ZombieManager::SpawnSpecial\" offset.");
	if (!DHookEnableDetour(g_hSpecialSpawn, false, SpecialSpawnDetour)) SetFailState("Failed to detour \"L4DD::ZombieManager::SpawnSpecial\".");

	delete hGameData;
	g_hdAcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, AcceptInput);
	DHookAddParam(g_hdAcceptInput, HookParamType_CharPtr);
	DHookAddParam(g_hdAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(g_hdAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(g_hdAcceptInput, HookParamType_Object, 20, DHookPass_ByVal | DHookPass_ODTOR | DHookPass_OCTOR | DHookPass_OASSIGNOP);
	DHookAddParam(g_hdAcceptInput, HookParamType_Int);

	g_Onoff = CreateConVar("l4d2_tank_fix", "1", "是否开启tank修复. 1=开启，0=关闭.", FCVAR_NOTIFY);
	g_Onoff.AddChangeHook(ConVarChanged);
	g_iTankFix = g_Onoff.IntValue;

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	// AutoExecConfig(true, "l4d2_maptankfix"); 生成cfg?
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsTankFix();
}

void IsTankFix()
{
	g_iTankFix = g_Onoff.IntValue;
}

// 这些实体基本上生成之后就不会变化了 所以round_start再hook也可以 当然如果要考虑"万一",还是用entity_create吧
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	delete g_aEntList;
	g_aEntList = new ArrayList();
	g_bHaveKick = false;
	int entity	= -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		char szEntityName[64];
		GetEntityClassname(entity, szEntityName, sizeof(szEntityName));
		if (StrEqual(szEntityName, "commentary_zombie_spawner", false))
		{
			#if DEBUG
				LogMessage("Detour commentary_zombie_spawner");
			#endif
			DHookEntity(g_hdAcceptInput, false, entity);
		}

		if (StrEqual(szEntityName, "info_zombie_spawn", false))
		{
			char propName[50];
			GetEntPropString(entity, Prop_Data, "m_szPopulation", propName, sizeof(propName));
			if (StrEqual(propName, "tank", false) || StrEqual(propName, "river_docks_trap", false) || StrEqual(propName, "church", false))
			{
				#if DEBUG
					LogMessage("info_zombie_spawn Detour");
				#endif
				DHookEntity(g_hdAcceptInput, false, entity);
			}
		}
	}
}

// 如果输入符合
MRESReturn AcceptInput(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	#if DEBUG
		LogMessage("Detour Get Input");
	#endif
	if (g_iTankFix == 0 || FindValueInList(pThis)) return MRES_Ignored;

	#if DEBUG
		LogMessage("Detour Entity Input");
	#endif

	char szEntityName[64];
	GetEntityClassname(pThis, szEntityName, sizeof(szEntityName));
	if (StrEqual(szEntityName, "info_zombie_spawn"))
	{
	#if DEBUG
			LogMessage("Detour info_zombie_spawn Respawn");
	#endif
		CreateTimer(0.1, CheckIfSpawnSucess, EntIndexToEntRef(pThis));
	}

	if (StrEqual(szEntityName, "commentary_zombie_spawner"))
	{
		char result[128];
		DHookGetParamString(hParams, 1, result, sizeof(result));
		if (StrEqual(result, "tank", false) || StrEqual(result, "river_docks_trap", false) || StrEqual(result, "church", false))
		{
			#if DEBUG
				LogMessage("Detour commentary_zombie_spawner Respawn");
			#endif
			CreateTimer(0.1, CheckIfSpawnSucess, EntIndexToEntRef(pThis));
		}
	}
	return MRES_Ignored;
}

// tank重生期间禁止新特感刷新
MRESReturn SpecialSpawnDetour(DHookReturn hReturn, DHookParam hParams)
{
	if (g_iTankFix == 0 || IsListNull()) return MRES_Ignored;
	int var1;
	var1 = DHookGetParam(hParams, 1);
	if (var1 != 8)
	{
		#if DEBUG
			LogMessage("Prevent Special Spawn");
		#endif
		hReturn.Value = -1;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public Action CheckIfSpawnSucess(Handle timer, int iEnt)
{
	iEnt = EntRefToEntIndex(iEnt);
	if(iEnt == INVALID_ENT_REFERENCE) return Plugin_Continue;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidEntity(client) && IsClientInGame(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client))
		{
			int class = GetEntProp(client, Prop_Send, "m_zombieClass");
			if (class == 8)
			{
				float vPos[3], cPos[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", vPos);
				GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", cPos);
				if (GetVectorDistance(vPos, cPos, true) <= 100.0 * 100.0)
				{
					#if DEBUG
						LogMessage("ResPawn Sucess");
					#endif
					CreateTimer(0.1, LaterRemoveArray, iEnt);
					return Plugin_Continue;
				}
			}
		}
	}
	PushValueInList(iEnt);
	ReleaseSlotFromSpecial();
	CreateTimer(0.1, LaterSpawnTank, EntIndexToEntRef(iEnt));
	return Plugin_Continue;
}

// 刷克
public Action LaterSpawnTank(Handle timer, int iEnt)
{
	iEnt = EntRefToEntIndex(iEnt);
	if(iEnt == INVALID_ENT_REFERENCE) return Plugin_Continue;

	char class[56];
	GetEdictClassname(iEnt, class, sizeof(class));
	if (StrEqual(class, "info_zombie_spawn"))
	{
		AcceptEntityInput(iEnt, "SpawnZombie");
	}
	else
	{
		SetVariantString("tank");
		AcceptEntityInput(iEnt, "SpawnZombie");
	}
	
	CreateTimer(0.1, CheckIfSpawnSucess, EntIndexToEntRef(iEnt));
	return Plugin_Continue;
}

// 解除刷特封锁
public Action LaterRemoveArray(Handle timer, int iEnt)
{
	#if DEBUG
		LogMessage("Plugins Process End");
	#endif
	RemoveValueFromList(iEnt);
	g_bHaveKick = false;
	return Plugin_Continue;
}

// 腾出槽位
void ReleaseSlotFromSpecial()
{
	#if DEBUG
		LogMessage("Start Release Slot From Special");
	#endif
	g_bHaveKick = false;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidSpecialsBot(client))
		{
			int class = GetEntProp(client, Prop_Send, "m_zombieClass");
			if (class < 8 && class != 4 && !IsPlayerAlive(client))
			{
				KickClientEx(client);
				g_bHaveKick = true;
				break;
			}
		}
	}

	if (!g_bHaveKick)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidSpecialsBot(client))
			{
				int class = GetEntProp(client, Prop_Send, "m_zombieClass");
				if (class < 8 && class != 4 && IsInfectedCanKick(client, class))
				{
					KickClientEx(client);
					g_bHaveKick = true;
					break;
				}
			}
		}
	}

	if (!g_bHaveKick)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidSpecialsBot(client))
			{
				int class = GetEntProp(client, Prop_Send, "m_zombieClass");
				if (class < 8 && class != 4)
				{
					KickClientEx(client);
					break;
				}
			}
		}
	}
}

// 以下函数为一些内部使用函数
bool IsValidSpecialsBot(int client)
{
	return IsValidEntity(client) && IsClientInGame(client) && GetClientTeam(client) == 3 && IsFakeClient(client);
}

bool IsInfectedCanKick(int client, int class)
{
	if (strlen(L4D2_Infectedprops[class]) == 0)
		return true;

	int h_vic = GetEntPropEnt(client, Prop_Send, L4D2_Infectedprops[class]);
	if (IsValidEntity(h_vic) && h_vic > 0)
		return false;
	return true;
}

void PushValueInList(int value)
{
	int index = g_aEntList.FindValue(value);
	if(index < 0) g_aEntList.Push(value);
}

void RemoveValueFromList(int value)
{
	int index = g_aEntList.FindValue(value);
	if(index >= 0) g_aEntList.Erase(index);
}

bool FindValueInList(int value)
{
	return g_aEntList.FindValue(value) >= 0;
}

bool IsListNull()
{
	return g_aEntList.Length == 0;
}