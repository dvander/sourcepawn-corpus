#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CONFIG	"data/maps_ladders.cfg"
#define MODEL_BOX	"models/props/cs_militia/silo_01.mdl"

#define MAXTRIGGERS 32
#define STUCKTIME 2.0

float g_vOrigin[MAXTRIGGERS][3], g_flStuckTime[MAXTRIGGERS];
int g_iTrigger[MAXTRIGGERS];
char g_szName[36];
bool g_bTouch[MAXPLAYERS + 1];
bool bMoveType[MAXPLAYERS+1]=false;

public Plugin myinfo =
{
	name = "[L4D2] Ladders Fix",
	author = "BHaType",
	description = "Fixes ladders.",
	version = "0.1",
	url = ""
}

public void OnMapStart()
{
	if (!IsModelPrecached(MODEL_BOX))
		PrecacheModel(MODEL_BOX, true);

	GetCurrentMap(g_szName, sizeof g_szName);
}

void LoadConfig()
{
	int entity;
	
	for (int i; i < MAXTRIGGERS; i++)
	{
		g_vOrigin[i][0] = 0.0;
		g_vOrigin[i][1] = 0.0;
		g_vOrigin[i][2] = 0.0;
		
		if ((entity = EntRefToEntIndex(g_iTrigger[i])) > MaxClients && IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "kill");
			g_iTrigger[i] = 0;
		}
	}
	
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), CONFIG);

	if (!FileExists(szPath))
	{
		SetFailState("[Tank Ladders Fix] Config has not been found");
		return;
	}

	KeyValues hKeyValues = new KeyValues("Data");
	
	if (!hKeyValues.ImportFromFile(szPath))
	{
		delete hKeyValues;
		return;
	}
	
	hKeyValues.JumpToKey(g_szName, true);
	
	char szTemp[4];
	float vMins[3], vMaxs[3], vOrigin[3];
	
	for (int i; i < MAXTRIGGERS; i++)
	{
		IntToString(i, szTemp, sizeof szTemp);
		
		if (!hKeyValues.JumpToKey(szTemp))
			break;
			
		hKeyValues.GetVector("Trigger Origin", vOrigin);
		hKeyValues.GetVector("Mins", vMins);
		hKeyValues.GetVector("Maxs", vMaxs);
		hKeyValues.GetVector("Origin", g_vOrigin[i]);
		
		g_flStuckTime[i] = hKeyValues.GetFloat("Stuck Time");
		
		if (g_flStuckTime[i] <= 0.0)
			g_flStuckTime[i] = STUCKTIME;
		
		CreateTriggerMultiple(i, vOrigin, vMaxs, vMins);
		
		hKeyValues.GoBack();
	}
	
	delete hKeyValues;
}

public Action OnPlayerRunCmd(int client)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 8)
		return Plugin_Continue;
		
	if (GetEntityMoveType(client) == MOVETYPE_LADDER)
	{
		if (bMoveType[client] == false)
		{
			SDKHook(client, SDKHook_StartTouch, StartTouch);
			bMoveType[client] = true;
		}
	}
	
	else if (GetEntityMoveType(client) == MOVETYPE_WALK)
	{
		if (bMoveType[client] == true)
		{
			SDKHook(client, SDKHook_StartTouch, EndTouch);
			bMoveType[client] = false;
		}
	}
	
	return Plugin_Continue;
}

public void OnEndTouch(const char[] output, int caller, int activator, float delay)
{
	if (activator <= 0 || !IsClientInGame(activator) || !IsFakeClient(activator) || GetClientTeam(activator) != 3 || GetEntProp(activator, Prop_Send, "m_zombieClass") != 8)
		return;
		
	caller = EntIndexToEntRef(caller);

	for (int i; i < MAXTRIGGERS; i++)
	{
		if (caller == g_iTrigger[i])
		{
			g_bTouch[activator] = false;
			SetEntProp(activator, Prop_Data, "m_iHammerID", 0);
			break;
		}
	}
}

public void OnStartTouch(const char[] output, int caller, int activator, float delay)
{
	if (IsClientInGame(activator) && GetClientTeam(activator) == 3 && IsFakeClient(activator) && GetEntProp(activator, Prop_Send, "m_zombieClass") == 8)
	{
		caller = EntIndexToEntRef(caller);

		for (int i; i < MAXTRIGGERS; i++)
		{
			if (caller == g_iTrigger[i])
			{
				g_bTouch[activator] = true;
				SetEntProp(activator, Prop_Data, "m_iHammerID", i);
				CreateTimer(g_flStuckTime[i], tTimer, GetClientUserId(activator));
				break;
			}
		}
	}
}

public Action tTimer (Handle timer, int clientindex)
{
	int index;
	if ((index = GetClientOfUserId(clientindex)) <= 0 || !IsClientInGame(index) || !IsPlayerAlive(index) || !g_bTouch[index])
		return;
	
	index = GetEntProp(index, Prop_Data, "m_iHammerID");
	L4D2_RunScript("CommandABot({cmd = 1, pos = Vector( %f, %f, %f ), bot = GetPlayerFromUserID(%i)})", g_vOrigin[index][0], g_vOrigin[index][1], g_vOrigin[index][2], clientindex);
}

void CreateTriggerMultiple(int index, float vOrigin[3], float vMaxs[3], float vMins[3])
{
	int trigger = CreateEntityByName("trigger_multiple");
	DispatchKeyValue(trigger, "StartDisabled", "0");
	DispatchKeyValue(trigger, "spawnflags", "1");
	DispatchKeyValue(trigger, "entireteam", "0");
	DispatchKeyValue(trigger, "allowincap", "0");
	DispatchKeyValue(trigger, "allowghost", "0");

	DispatchSpawn(trigger);
	SetEntityModel(trigger, MODEL_BOX);

	SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", vMaxs);
	SetEntPropVector(trigger, Prop_Send, "m_vecMins", vMins);
	SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
	TeleportEntity(trigger, vOrigin, NULL_VECTOR, NULL_VECTOR);
	
	HookSingleEntityOutput(trigger, "OnStartTouch", OnStartTouch);
	HookSingleEntityOutput(trigger, "OnEndTouch", OnEndTouch);
	
	g_iTrigger[index] = EntIndexToEntRef(trigger);
}

public void OnPluginStart()
{
	HookEvent("round_start", eStart, EventHookMode_PostNoCopy);
}

public void eStart (Event event, const char[] name, bool dontbroadcast)
{
	CreateTimer(3.5, tLoad);
}

public Action tLoad (Handle timer)
{
	LoadConfig();
}

// Uncle Jessie Code
public void StartTouch(int client)
{
	SDKUnhook(client, SDKHook_StartTouch, StartTouch);
	if (client) SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
}

public void EndTouch(int client)
{
	SDKUnhook(client, SDKHook_StartTouch, EndTouch);
	if (client) SetEntProp(client, Prop_Data, "m_CollisionGroup", 6);
}

// Timocop Code
stock void L4D2_RunScript(const char[] sCode, any ...)
{
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) 
	{
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
			SetFailState("Could not create 'logic_script'");
		
		DispatchSpawn(iScriptLogic);
	}
	
	char sBuffer[128];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}