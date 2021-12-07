#pragma semicolon 1

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

//Min jump time to count as a jump
#define JUMP_TIME				0.5
		
//Max time a player can touch a bhop platform
#define TELEPORT_DELAY			0.15
		
//Reset a bhop platform anyway until this cooldown lifts
#define PLATTFORM_COOLDOWN		1.0

//Func_Door list
new g_iBhopDoorList[MAX_BHOPBLOCKS];
new g_iBhopDoorTeleList[MAX_BHOPBLOCKS];
new g_iBhopDoorCount;

//Func_Button list
new g_iBhopButtonList[MAX_BHOPBLOCKS];
new g_iBhopButtonTeleList[MAX_BHOPBLOCKS];
new g_iBhopButtonCount;

//Min-/MaxVec Offsets
new g_iOffs_clrRender = -1;
new g_iOffs_vecOrigin = -1;
new g_iOffs_vecMins = -1;
new g_iOffs_vecMaxs = -1;

//Func_Door Offsets
new g_iDoorOffs_vecPosition1 = -1;
new g_iDoorOffs_vecPosition2 = -1;
new g_iDoorOffs_flSpeed = -1;
new g_iDoorOffs_spawnflags = -1;
new g_iDoorOffs_NoiseMoving = -1;
new g_iDoorOffs_sLockedSound = -1;
new g_iDoorOffs_bLocked = -1;

//Func_Button Offsets
new g_iButtonOffs_vecPosition1 = -1;
new g_iButtonOffs_vecPosition2 = -1;
new g_iButtonOffs_flSpeed = -1;
new g_iButtonOffs_spawnflags = -1;

new bool:g_bLateLoaded = false;

new Handle:g_hSDK_Touch = INVALID_HANDLE;

new Float:g_fLastJump[MAXPLAYERS+1] = {0.0, ...};

public Plugin:myinfo = 
{
	name = "MPBH",
	author = "DaFox, petsku & Zipcore",
	description = "Prevents (oldschool) bhop plattform from moving down.",
	version = "1.0",
	url = "zipcore#googlemail.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("mpbh");
	g_bLateLoaded = late;

	return APLRes_Success;
}

public OnPluginStart()
{
	new Handle:hGameConf = INVALID_HANDLE;
	hGameConf = LoadGameConfigFile("sdkhooks.games");
	if(hGameConf == INVALID_HANDLE)
	{
		SetFailState("GameConfigFile sdkhooks.games was not found");
		return;
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"Touch");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity,SDKPass_Pointer);
	g_hSDK_Touch = EndPrepSDKCall();
	CloseHandle(hGameConf);

	if(g_hSDK_Touch == INVALID_HANDLE)
	{
		SetFailState("Unable to prepare virtual function CBaseEntity::Touch");
		return;
	}

	g_iOffs_clrRender = FindSendPropInfo("CBaseEntity","m_clrRender");
	g_iOffs_vecOrigin = FindSendPropInfo("CBaseEntity","m_vecOrigin");
	g_iOffs_vecMins = FindSendPropInfo("CBaseEntity","m_vecMins");
	g_iOffs_vecMaxs = FindSendPropInfo("CBaseEntity","m_vecMaxs");
	
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("round_start",Event_RoundStart,EventHookMode_PostNoCopy);
	
	if(g_bLateLoaded)
		ResetMultiBhop();
}

public Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	ResetMultiBhop();
}

public OnPluginEnd()
{
	AlterBhopBlocks(true);
}

public OnMapStart()
{
	ResetMultiBhop();
}

public OnMapEnd()
{
	AlterBhopBlocks(true);

	g_iBhopDoorCount = 0;
	g_iBhopButtonCount = 0;
}

public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_fLastJump[client] = GetGameTime();
	//GetClientAbsOrigin(client, g_fJumpLastCord[client]);

	return Plugin_Continue;
}

public Entity_Touch(bhop,client)
{
	//bhop = entity
	if(0 < client <= MaxClients)
	{
		static Float:flPunishTime[MAXPLAYERS + 1], iLastBlock[MAXPLAYERS + 1] = { -1,... };

		new Float:time = GetGameTime();

		new Float:diff = time - flPunishTime[client];

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

public Action:RemoveColouredBlocks(Handle:timer, any:bhop)
{
	new colour[4] = {255,255,255,255};
	SetEntDataArray(bhop, g_iOffs_clrRender , colour, 4, 1, true);
}

FindBhopBlocks()
{
	decl Float:startpos[3], Float:endpos[3], Float:mins[3], Float:maxs[3], tele;
	new ent = -1;

	while((ent = FindEntityByClassname(ent,"func_door")) != -1)
	{
		if(g_iDoorOffs_vecPosition1 == -1)
		{
			g_iDoorOffs_vecPosition1 = FindDataMapOffs(ent,"m_vecPosition1");
			g_iDoorOffs_vecPosition2 = FindDataMapOffs(ent,"m_vecPosition2");
			g_iDoorOffs_flSpeed = FindDataMapOffs(ent,"m_flSpeed");
			g_iDoorOffs_spawnflags = FindDataMapOffs(ent,"m_spawnflags");
			g_iDoorOffs_NoiseMoving = FindDataMapOffs(ent,"m_NoiseMoving");
			g_iDoorOffs_sLockedSound = FindDataMapOffs(ent,"m_ls.sLockedSound");
			g_iDoorOffs_bLocked = FindDataMapOffs(ent,"m_bLocked");
		}

		GetEntDataVector(ent,g_iDoorOffs_vecPosition1,startpos);
		GetEntDataVector(ent,g_iDoorOffs_vecPosition2,endpos);

		if(startpos[2] > endpos[2])
		{
			GetEntDataVector(ent,g_iOffs_vecMins,mins);
			GetEntDataVector(ent,g_iOffs_vecMaxs,maxs);

			startpos[0] += (mins[0] + maxs[0]) * 0.5;
			startpos[1] += (mins[1] + maxs[1]) * 0.5;
			startpos[2] += maxs[2];

			if((tele = CustomTraceForTeleports(startpos,endpos[2] + maxs[2])) != -1)
			{
				g_iBhopDoorList[g_iBhopDoorCount] = ent;
				g_iBhopDoorTeleList[g_iBhopDoorCount] = tele;

				if(++g_iBhopDoorCount == sizeof g_iBhopDoorList)
				{
					break;
				}
			}
		}
	}

	ent = -1;

	while((ent = FindEntityByClassname(ent,"func_button")) != -1)
	{
		if(g_iButtonOffs_vecPosition1 == -1)
		{
			g_iButtonOffs_vecPosition1 = FindDataMapOffs(ent,"m_vecPosition1");
			g_iButtonOffs_vecPosition2 = FindDataMapOffs(ent,"m_vecPosition2");
			g_iButtonOffs_flSpeed = FindDataMapOffs(ent,"m_flSpeed");
			g_iButtonOffs_spawnflags = FindDataMapOffs(ent,"m_spawnflags");
		}

		GetEntDataVector(ent,g_iButtonOffs_vecPosition1,startpos);
		GetEntDataVector(ent,g_iButtonOffs_vecPosition2,endpos);

		if(startpos[2] > endpos[2] && (GetEntData(ent,g_iButtonOffs_spawnflags,4) & SF_BUTTON_TOUCH_ACTIVATES))
		{
			GetEntDataVector(ent,g_iOffs_vecMins,mins);
			GetEntDataVector(ent,g_iOffs_vecMaxs,maxs);

			startpos[0] += (mins[0] + maxs[0]) * 0.5;
			startpos[1] += (mins[1] + maxs[1]) * 0.5;
			startpos[2] += maxs[2];

			if((tele = CustomTraceForTeleports(startpos,endpos[2] + maxs[2])) != -1)
			{
				g_iBhopButtonList[g_iBhopButtonCount] = ent;
				g_iBhopButtonTeleList[g_iBhopButtonCount] = tele;

				if(++g_iBhopButtonCount == sizeof g_iBhopButtonList)
				{
					break;
				}
			}
		}
	}
	AlterBhopBlocks(false);
}

stock GetBhopDoorID(entity)
{
	for (new i = 0; i < g_iBhopDoorCount; i++)
	{
		if(entity == g_iBhopDoorList[i])
			return i;
	}

	return -1;
}

stock GetBhopButtonID(entity)
{
	for (new i = 0; i < g_iBhopButtonCount; i++)
	{
		if(entity == g_iBhopButtonList[i])
			return i;
	}

	return -1;
}

AlterBhopBlocks(bool:bRevertChanges)
{
	static Float:vecDoorPosition2[sizeof g_iBhopDoorList][3];
	static Float:flDoorSpeed[sizeof g_iBhopDoorList];
	static iDoorSpawnflags[sizeof g_iBhopDoorList];
	static bool:bDoorLocked[sizeof g_iBhopDoorList];

	static Float:vecButtonPosition2[sizeof g_iBhopButtonList][3];
	static Float:flButtonSpeed[sizeof g_iBhopButtonList];
	static iButtonSpawnflags[sizeof g_iBhopButtonList];

	decl ent, i;

	if(bRevertChanges)
	{
		for (i = 0; i < g_iBhopDoorCount; i++)
		{
			ent = g_iBhopDoorList[i];
			
			if(IsValidEntity(ent))
			{
				SetEntDataArray(ent, g_iOffs_clrRender , {255, 255, 255, 255}, 4, 1, true);
				SetEntDataVector(ent,g_iDoorOffs_vecPosition2,vecDoorPosition2[i]);
				SetEntDataFloat(ent,g_iDoorOffs_flSpeed,flDoorSpeed[i]);
				SetEntData(ent,g_iDoorOffs_spawnflags,iDoorSpawnflags[i],4);

				if(!bDoorLocked[i])
				{
					AcceptEntityInput(ent,"Unlock");
				}

				SDKUnhook(ent,SDKHook_Touch,Entity_Touch);
			}
		}

		for (i = 0; i < g_iBhopButtonCount; i++)
		{
			ent = g_iBhopButtonList[i];

			if(IsValidEntity(ent))
			{
				SetEntDataArray(ent, g_iOffs_clrRender , {255, 255, 255, 255}, 4, 1, true);
				SetEntDataVector(ent,g_iButtonOffs_vecPosition2,vecButtonPosition2[i]);
				SetEntDataFloat(ent,g_iButtonOffs_flSpeed,flButtonSpeed[i]);
				SetEntData(ent,g_iButtonOffs_spawnflags,iButtonSpawnflags[i],4);

				SDKUnhook(ent,SDKHook_Touch,Entity_Touch);
			}
		}
	}
	else
	{
		//note: This only gets called directly after finding the blocks, so the entities are valid.
		decl Float:startpos[3];

		for (i = 0; i < g_iBhopDoorCount; i++)
		{
			ent = g_iBhopDoorList[i];

			GetEntDataVector(ent,g_iDoorOffs_vecPosition2,vecDoorPosition2[i]);
			flDoorSpeed[i] = GetEntDataFloat(ent,g_iDoorOffs_flSpeed);
			iDoorSpawnflags[i] = GetEntData(ent,g_iDoorOffs_spawnflags,4);
			bDoorLocked[i] = GetEntData(ent,g_iDoorOffs_bLocked,1) ? true : false;

			GetEntDataVector(ent,g_iDoorOffs_vecPosition1,startpos);
			SetEntDataVector(ent,g_iDoorOffs_vecPosition2,startpos);

			SetEntDataFloat(ent,g_iDoorOffs_flSpeed,0.0);
			SetEntData(ent,g_iDoorOffs_spawnflags,SF_DOOR_PTOUCH,4);
			AcceptEntityInput(ent,"Lock");

			SetEntData(ent,g_iDoorOffs_sLockedSound,GetEntData(ent,g_iDoorOffs_NoiseMoving,4),4);

			SDKHook(ent,SDKHook_Touch,Entity_Touch);
		}

		for (i = 0; i < g_iBhopButtonCount; i++)
		{
			ent = g_iBhopButtonList[i];

			GetEntDataVector(ent,g_iButtonOffs_vecPosition2,vecButtonPosition2[i]);
			flButtonSpeed[i] = GetEntDataFloat(ent,g_iButtonOffs_flSpeed);
			iButtonSpawnflags[i] = GetEntData(ent,g_iButtonOffs_spawnflags,4);

			GetEntDataVector(ent,g_iButtonOffs_vecPosition1,startpos);
			SetEntDataVector(ent,g_iButtonOffs_vecPosition2,startpos);

			SetEntDataFloat(ent,g_iButtonOffs_flSpeed,0.0);
			SetEntData(ent,g_iButtonOffs_spawnflags,SF_BUTTON_DONTMOVE|SF_BUTTON_TOUCH_ACTIVATES,4);

			SDKHook(ent,SDKHook_Touch,Entity_Touch);
		}
	}
}

CustomTraceForTeleports(const Float:startpos[3],Float:endheight,Float:step=1.0)
{
	decl teleports[512];
	new tpcount, ent = -1;

	while((ent = FindEntityByClassname(ent,"trigger_teleport")) != -1 && tpcount != sizeof teleports)
	{
		teleports[tpcount++] = ent;
	}

	decl Float:mins[3], Float:maxs[3], Float:origin[3], i;

	origin[0] = startpos[0];
	origin[1] = startpos[1];
	origin[2] = startpos[2];

	do
	{
		for (i = 0; i < tpcount; i++)
		{
			ent = teleports[i];
			GetAbsBoundingBox(ent,mins,maxs);

			if(mins[0] <= origin[0] <= maxs[0] && mins[1] <= origin[1] <= maxs[1] && mins[2] <= origin[2] <= maxs[2])
			{
				return ent;
			}
		}

		origin[2] -= step;
	} while(origin[2] >= endheight);

	return -1;
}

GetAbsBoundingBox(ent,Float:mins[3],Float:maxs[3])
{
	decl Float:origin[3];

	GetEntDataVector(ent,g_iOffs_vecOrigin,origin);
	GetEntDataVector(ent,g_iOffs_vecMins,mins);
	GetEntDataVector(ent,g_iOffs_vecMaxs,maxs);

	mins[0] += origin[0];
	mins[1] += origin[1];
	mins[2] += origin[2];

	maxs[0] += origin[0];
	maxs[1] += origin[1];
	maxs[2] += origin[2];
}

Teleport(client, bhop)
{

	decl i;
	new tele = -1, ent = bhop;

	//search door trigger list
	for (i = 0; i < g_iBhopDoorCount; i++)
	{
		if(ent == g_iBhopDoorList[i])
		{
			tele = g_iBhopDoorTeleList[i];
			break;
		}
	}

	//no destination? search button trigger list
	if(tele == -1)
	{
		for (i = 0; i < g_iBhopButtonCount; i++)
		{
			if(ent == g_iBhopButtonList[i])
			{
				tele = g_iBhopButtonTeleList[i];
				break;
			}
		}
	}

	//set teleport destination
	if(tele != -1 && IsValidEntity(tele))
	{
		SDKCall(g_hSDK_Touch,tele,client);
	}
}

stock ResetMultiBhop()
{
	g_iBhopDoorCount = 0;
	g_iBhopButtonCount = 0;

	FindBhopBlocks();

	// Reset and do it again to fix game crashesa for an unikonwn reason
	AlterBhopBlocks(true);
	g_iBhopDoorCount = 0;
	g_iBhopButtonCount = 0;
	FindBhopBlocks();
}