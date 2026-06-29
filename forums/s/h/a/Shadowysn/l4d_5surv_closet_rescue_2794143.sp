#define PLUGIN_NAME "[L4D1/2] 5+ Survivor Rescue Closet"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Allows a single rescue entity to rescue all eligible survivors."
#define PLUGIN_VERSION "1.0.0b"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=340659"
#define PLUGIN_NAME_SHORT "5+ Survivor Rescue Closet"
#define PLUGIN_NAME_TECH "rescue_five_plus"

#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>
//#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

//#define AUTOEXEC_CFG "auto_rescue"

//bool g_isSequel = false;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_Left4Dead)
	{
		return APLRes_Success;
	}
	else if (ev == Engine_Left4Dead2)
	{
		//g_isSequel = true;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead and Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

bool isRescuing = false;
float g_fMinRescueTime;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	ConVar version_cvar = CreateConVar("sm_"...PLUGIN_NAME_TECH..."_version", PLUGIN_VERSION, PLUGIN_NAME_SHORT..." version.", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	if (version_cvar != null)
		version_cvar.SetString(PLUGIN_VERSION);
	
	ConVar hTempCVar = FindConVar("rescue_min_dead_time");
	hTempCVar.AddChangeHook(CC_ACR_MinRescueTime);
	g_fMinRescueTime = hTempCVar.FloatValue;
	
	delete hTempCVar;
	
	HookEvent("survivor_rescued", survivor_rescued, EventHookMode_Post);
	
	// Use common.phrases for ReplyToTargetError
	//LoadTranslations("common.phrases");
}

void CC_ACR_MinRescueTime(ConVar convar, const char[] oldValue, const char[] newValue) { g_fMinRescueTime = convar.FloatValue; }

void survivor_rescued(Event event, const char[] name, bool dontBroadcast)
{
	if (isRescuing) return;
	
	int victim = GetClientOfUserId(event.GetInt("victim", 0));
	if (victim == 0 || !IsGameSurvivor(victim)) return;
	
	int rescuer = GetClientOfUserId(event.GetInt("rescuer", 0));
	//bool isRescuerValid = (rescuer != 0);
	if (rescuer == 0) return; // assume rescues without a rescuer are from plugin-spawned rescues meant to respawn specific survivors
	
	int door = event.GetInt("dooridx", -1);
	bool isDoorValid = RealValidEntity(door);
	
	float pos[3]/*, ang[3]*/;
	GetClientAbsOrigin(victim, pos);
	
	isRescuing = true;
	int manualRescue = 0;
	float gameTime = GetGameTime();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsGameSurvivor(i) || IsPlayerAlive(i)) continue;
		
		float deathTime = GetEntPropFloat(i, Prop_Send, "m_flDeathTime");
		if (gameTime < deathTime + g_fMinRescueTime) continue;
		
		if (manualRescue == 0)
		{
			// m_iHammerID is 0 for new entities 
			manualRescue = CreateEntityByName("info_survivor_rescue");
			if (manualRescue == -1)
			{
				RequestFrame(rescueFrameReq);
				return;
			}
			DispatchKeyValueVector(manualRescue, "origin", pos);
			DispatchSpawn(manualRescue);
		}
		
		SetEntPropEnt(manualRescue, Prop_Send, "m_survivor", i);
		AcceptEntityInput(manualRescue, "Rescue", /*isRescuerValid ? */rescuer/* : -1*/, isDoorValid ? door : -1);
	}
	
	RequestFrame(rescueFrameReq);
	if (manualRescue != 0) AcceptEntityInput(manualRescue, "Kill");
}

void rescueFrameReq()
{ isRescuing = false; }

stock bool IsGameSurvivor(int client)
{ return (GetClientTeam(client) == 2); }

stock bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }