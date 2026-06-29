#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

//Func_ Flags
#define SF_BUTTON_DONTMOVE				(1<<0)		//dont move when fired (func_button)
#define SF_BUTTON_TOUCH_ACTIVATES		(1<<8)		//button fires when touched (func_button)
#define SF_DOOR_PTOUCH					(1<<10)		//player touch opens (func_door)

//Max. number of door/button based bhop blocks handled in a map
#define MAX_BHOPBLOCKS	1024
		
//Max time a player can touch a bhop platform
#define TELEPORT_DELAY			0.15
		
//Reset a bhop platform anyway until this cooldown lifts
#define PLATTFORM_COOLDOWN		1.0

//Func_Door list
int    g_iBhopDoorList[MAX_BHOPBLOCKS];
int    g_iBhopDoorTeleList[MAX_BHOPBLOCKS];
int    g_iBhopDoorCount;

//Func_Button list
int    g_iBhopButtonList[MAX_BHOPBLOCKS];
int    g_iBhopButtonTeleList[MAX_BHOPBLOCKS];
int    g_iBhopButtonCount;

bool   g_bLateLoaded = false;

Handle g_hSDK_Touch = INVALID_HANDLE;

float  g_fLastJump[MAXPLAYERS+1] = {0.0, ...};

public Plugin myinfo = 
{
	name = "MPBH",
	author = "DaFox, petsku & Zipcore | Slidy Edit",
	description = "Prevents (oldschool) bhop plattform from moving down.",
	version = "1.1",
	url = "zipcore#googlemail.com"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("mpbh");
	g_bLateLoaded = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile("sdkhooks.games");
	if(hGameConf == INVALID_HANDLE)
	{
		SetFailState("GameConfigFile sdkhooks.games was not found");
		return;
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "Touch");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDK_Touch = EndPrepSDKCall();
	CloseHandle(hGameConf);

	if(g_hSDK_Touch == INVALID_HANDLE)
	{
		SetFailState("Unable to prepare virtual function CBaseEntity::Touch");
		return;
	}
	
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("round_start", Event_RoundStartPost, EventHookMode_PostNoCopy);
	
	if(g_bLateLoaded)
	{
		ResetMultiBhop();
	}
}

public void OnPluginEnd()
{
	AlterBhopBlocks(true);
}

public void OnMapEnd()
{
	AlterBhopBlocks(true);

	g_iBhopDoorCount = 0;
	g_iBhopButtonCount = 0;
}

public void OnMapStart()
{
	// can probably remove this since it gets hooked again after round start, but just in case
	ResetMultiBhop();
}

public Action Event_RoundStartPost(Event event, const char[] name, bool dontBroadcast)
{
	// re-hook as hooks get removed on round startpos
	ResetMultiBhop();
}

public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_fLastJump[client] = GetGameTime();

	return Plugin_Continue;
}

public void Entity_Touch(int bhop, int client)
{
	//bhop = entity
	if(0 < client <= MaxClients)
	{
		static float flPunishTime[MAXPLAYERS + 1];
		static int iLastBlock[MAXPLAYERS + 1] = { -1, ... };

		float time = GetGameTime();
		float diff = time - flPunishTime[client];

		if(iLastBlock[client] != bhop || diff > PLATTFORM_COOLDOWN)
		{
			//reset cooldown
			iLastBlock[client] = bhop;
			flPunishTime[client] = time + TELEPORT_DELAY;
		}
		else if(diff > TELEPORT_DELAY)
		{
			if(time - g_fLastJump[client] > (PLATTFORM_COOLDOWN + TELEPORT_DELAY))
			{
				Teleport(client, iLastBlock[client]);
				iLastBlock[client] = -1;
			}
		}
	}
}

void FindBhopBlocks()
{
	float startpos[3], endpos[3];
	float mins[3], maxs[3];
	int tele;
	int ent = -1;

	while((ent = FindEntityByClassname(ent, "func_door")) != -1)
	{
		GetEntPropVector(ent, Prop_Data, "m_vecPosition1", startpos);
		GetEntPropVector(ent, Prop_Data, "m_vecPosition2", endpos);

		if(startpos[2] > endpos[2])
		{
			GetEntPropVector(ent, Prop_Data, "m_vecMins", mins);
			GetEntPropVector(ent, Prop_Data, "m_vecMaxs", maxs);

			startpos[0] += (mins[0] + maxs[0]) * 0.5;
			startpos[1] += (mins[1] + maxs[1]) * 0.5;
			startpos[2] += maxs[2];

			if((tele = CustomTraceForTeleports(startpos, endpos[2] + maxs[2])) != -1)
			{
				g_iBhopDoorList[g_iBhopDoorCount] = EntIndexToEntRef(ent);
				g_iBhopDoorTeleList[g_iBhopDoorCount] = EntIndexToEntRef(tele);

				if(++g_iBhopDoorCount == sizeof g_iBhopDoorList)
				{
					LogError("[MPBH] Hit MAX_BHOP_BLOCKS limit, consider increasing the maximum...");
					break;
				}
			}
		}
	}

	ent = -1;

	while((ent = FindEntityByClassname(ent, "func_button")) != -1)
	{
		GetEntPropVector(ent, Prop_Data, "m_vecPosition1", startpos);
		GetEntPropVector(ent, Prop_Data, "m_vecPosition2", endpos);

		if(startpos[2] > endpos[2] && (GetEntProp(ent, Prop_Data, "m_spawnflags", 4) & SF_BUTTON_TOUCH_ACTIVATES))
		{
			GetEntPropVector(ent, Prop_Data, "m_vecMins", mins);
			GetEntPropVector(ent, Prop_Data, "m_vecMaxs", maxs);

			startpos[0] += (mins[0] + maxs[0]) * 0.5;
			startpos[1] += (mins[1] + maxs[1]) * 0.5;
			startpos[2] += maxs[2];

			if((tele = CustomTraceForTeleports(startpos, endpos[2] + maxs[2])) != -1)
			{
				g_iBhopButtonList[g_iBhopButtonCount] = EntIndexToEntRef(ent);
				g_iBhopButtonTeleList[g_iBhopButtonCount] = EntIndexToEntRef(tele);

				if(++g_iBhopButtonCount == sizeof g_iBhopButtonList)
				{
					LogError("[MPBH] Hit MAX_BHOP_BLOCKS limit, consider increasing the maximum...");
					break;
				}
			}
		}
	}
	
	AlterBhopBlocks(false);
}

void AlterBhopBlocks(bool bRevertChanges)
{
	static float vecDoorPosition2[sizeof g_iBhopDoorList][3];
	static float flDoorSpeed[sizeof g_iBhopDoorList];
	static int iDoorSpawnflags[sizeof g_iBhopDoorList];
	static bool bDoorLocked[sizeof g_iBhopDoorList];

	static float vecButtonPosition2[sizeof g_iBhopButtonList][3];
	static float flButtonSpeed[sizeof g_iBhopButtonList];
	static int iButtonSpawnflags[sizeof g_iBhopButtonList];

	static int ent;
	static int i;

	if(bRevertChanges)
	{
		for(i = 0; i < g_iBhopDoorCount; i++)
		{
			ent = EntRefToEntIndex(g_iBhopDoorList[i]);
			
			if(IsValidEntity(ent))
			{
				SetEntityRenderColor(ent, 255, 255, 255, 255);
				SetEntPropVector(ent, Prop_Data, "m_vecPosition2", vecDoorPosition2[i]);
				SetEntPropFloat(ent, Prop_Data, "m_flSpeed", flDoorSpeed[i]);
				SetEntProp(ent, Prop_Data, "m_spawnflags", iDoorSpawnflags[i], 4);

				if(!bDoorLocked[i])
				{
					AcceptEntityInput(ent, "Unlock");
				}

				SDKUnhook(ent, SDKHook_Touch, Entity_Touch);
			}
		}

		for(i = 0; i < g_iBhopButtonCount; i++)
		{
			ent = EntRefToEntIndex(g_iBhopButtonList[i]);

			if(IsValidEntity(ent))
			{
				SetEntityRenderColor(ent, 255, 255, 255, 255);
				SetEntPropVector(ent, Prop_Data, "m_vecPosition2", vecButtonPosition2[i]);
				SetEntPropFloat(ent, Prop_Data, "m_flSpeed", flButtonSpeed[i]);
				SetEntProp(ent, Prop_Data, "m_spawnflags", iButtonSpawnflags[i], 4);

				SDKUnhook(ent, SDKHook_Touch, Entity_Touch);
			}
		}
	}
	else
	{
		//note: This only gets called directly after finding the blocks, so the entities are valid.
		float startpos[3];

		for(i = 0; i < g_iBhopDoorCount; i++)
		{
			ent = EntRefToEntIndex(g_iBhopDoorList[i]);

			GetEntPropVector(ent, Prop_Data, "m_vecPosition2", vecDoorPosition2[i]);
			flDoorSpeed[i] = GetEntPropFloat(ent, Prop_Data, "m_flSpeed");
			iDoorSpawnflags[i] = GetEntProp(ent, Prop_Data, "m_spawnflags", 4);
			bDoorLocked[i] = GetEntProp(ent, Prop_Data, "m_bLocked", 1) ? true : false;

			GetEntPropVector(ent, Prop_Data, "m_vecPosition1", startpos);
			SetEntPropVector(ent, Prop_Data, "m_vecPosition2", startpos);

			SetEntPropFloat(ent, Prop_Data, "m_flSpeed", 0.0);
			SetEntProp(ent, Prop_Data, "m_spawnflags", SF_DOOR_PTOUCH, 4);
			AcceptEntityInput(ent, "Lock");

			char noisemoving[PLATFORM_MAX_PATH];
			GetEntPropString(ent, Prop_Data, "m_NoiseMoving", noisemoving, sizeof noisemoving);
			SetEntPropString(ent, Prop_Data, "m_ls.sLockedSound", noisemoving);

			SDKHook(ent, SDKHook_Touch, Entity_Touch);
		}

		for (i = 0; i < g_iBhopButtonCount; i++)
		{
			ent = EntRefToEntIndex(g_iBhopButtonList[i]);

			GetEntPropVector(ent, Prop_Data, "m_vecPosition2", vecButtonPosition2[i]);
			flButtonSpeed[i] = GetEntPropFloat(ent, Prop_Data, "m_flSpeed");
			iButtonSpawnflags[i] = GetEntProp(ent, Prop_Data, "m_spawnflags");

			GetEntPropVector(ent, Prop_Data, "m_vecPosition1", startpos);
			SetEntPropVector(ent, Prop_Data, "m_vecPosition2", startpos);

			SetEntPropFloat(ent, Prop_Data, "m_flSpeed", 0.0);
			SetEntProp(ent, Prop_Data, "m_spawnflags", SF_BUTTON_DONTMOVE|SF_BUTTON_TOUCH_ACTIVATES, 4);

			SDKHook(ent, SDKHook_Touch, Entity_Touch);
		}
	}
}

int CustomTraceForTeleports(const float startpos[3], float endheight, float step=1.0)
{
	static int teleports[512];
	int tpcount, ent = -1;

	while((ent = FindEntityByClassname(ent, "trigger_teleport")) != -1)
	{
		if(tpcount == sizeof teleports)
		{
			LogError("[MPBH] Max trigger_teleports limit reached, consider increasing maximum...");
			break;
		}
		teleports[tpcount++] = ent;
	}

	float mins[3], maxs[3], origin[3];
	origin = startpos;

	do
	{
		for (int i = 0; i < tpcount; i++)
		{
			ent = teleports[i];
			GetAbsBoundingBox(ent, mins, maxs);

			if(mins[0] <= origin[0] <= maxs[0]
				&& mins[1] <= origin[1] <= maxs[1]
				&& mins[2] <= origin[2] <= maxs[2])
			{
				return ent;
			}
		}

		origin[2] -= step;
	} while(origin[2] >= endheight);

	return -1;
}

stock void GetAbsBoundingBox(int ent, float mins[3], float maxs[3])
{
	float origin[3];

	GetEntPropVector(ent, Prop_Data, "m_vecOrigin", origin);
	GetEntPropVector(ent, Prop_Data, "m_vecMins", mins);
	GetEntPropVector(ent, Prop_Data, "m_vecMaxs", maxs);

	for(int i = 0; i < 3; i++)
	{
		mins[i] += origin[i];
		maxs[i] += origin[i];
	}
}

stock void Teleport(int client, int bhop)
{
	int tele = -1;
	int entref = EntIndexToEntRef(bhop);
	
	//search door trigger list
	for(int i = 0; i < g_iBhopDoorCount; i++)
	{
		if(entref == g_iBhopDoorList[i])
		{
			tele = EntRefToEntIndex(g_iBhopDoorTeleList[i]);
			break;
		}
	}

	//no destination? search button trigger list
	if(tele == -1)
	{
		for (int i = 0; i < g_iBhopButtonCount; i++)
		{
			if(entref == g_iBhopButtonList[i])
			{
				tele = EntRefToEntIndex(g_iBhopButtonTeleList[i]);
				break;
			}
		}
	}

	//set teleport destination
	if(tele != -1 && IsValidEntity(tele))
	{
		SDKCall(g_hSDK_Touch, tele, client);
	}
}

stock void ResetMultiBhop()
{
	g_iBhopDoorCount = 0;
	g_iBhopButtonCount = 0;

	FindBhopBlocks();
}