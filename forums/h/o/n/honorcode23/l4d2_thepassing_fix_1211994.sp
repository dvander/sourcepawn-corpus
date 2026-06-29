#include <sourcemod>
#include <sdktools>

static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hBecomeGhost = INVALID_HANDLE;
static Handle:hState_Transition = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;
new Handle:timerxx = INVALID_HANDLE;

//Plugin Info
public Plugin:myinfo = 
{
	name = "Stuck Fix",
	author = "honorcode23",
	description = "Will fix the stucking errors with l4d1 models on the passing",
	version = "1.0",
	url = "none"
}

public OnPluginStart()
{
	hGameConf = LoadGameConfigFile("l4drespawn");
	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "BecomeGhost");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hBecomeGhost = EndPrepSDKCall();
		if (hBecomeGhost == INVALID_HANDLE) LogError("L4D_SM_Respawn: BecomeGhost Signature broken");

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "State_Transition");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hState_Transition = EndPrepSDKCall();
		if (hState_Transition == INVALID_HANDLE) LogError("L4D_SM_Respawn: State_Transition Signature broken");
	}
	else
	{
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/l4drespawn.txt , you FAILED AT INSTALLING");
	}
}

public OnMapStart()
{
	decl String:mapname[256];
	GetCurrentMap(mapname, sizeof(mapname));
	if(timerxx != INVALID_HANDLE)
	{
		KillTimer(timerxx);
		timerxx = INVALID_HANDLE;
	}
	if(StrEqual(mapname, "c6m1_riverbank") || StrEqual(mapname, "c6m3_port"))
	{
		timerxx = CreateTimer(1.0, StartTimer, _, TIMER_REPEAT);
	}
}

public Action:StartTimer(Handle:timer)
{
	decl Float:badpos1[3];
	decl Float:badpos2[3];
	decl Float:badpos3[3];
	decl Float:badpos4[3];
	decl Float:goodpos1[3];
	decl Float:goodpos2[3];

	badpos1[0] = 1168.0;
	badpos1[1] = 4446.0;
	badpos1[2] = 508.0;

	goodpos1[0] = 911.0;
	goodpos1[1] = 3656.0;
	goodpos1[2] = 171.0;

	badpos2[0] = -216.0;
	badpos2[1] = -1055.0;
	badpos2[2] = 414.0;

	badpos3[0] = -256.0;
	badpos3[1] = -1120.0;
	badpos3[2] = 412.0;

	badpos4[0] = -236.0;
	badpos4[1] = -1076.0;
	badpos4[2] = 414.0;

	goodpos2[0] = -442.0;
	goodpos2[1] = -1080.0;
	goodpos2[2] = 382.0;
	for(new i=1 ; i<=MaxClients ; i++)
	{
		decl Float:VecOrigin[3];
		GetClientAbsOrigin(i, VecOrigin);
		if((FloatCompare(VecOrigin[0], badpos2[0]) == 0 && FloatCompare(VecOrigin[1], badpos2[1]) == 0 && FloatCompare(VecOrigin[2], badpos2[2]) == 0) || (FloatCompare(VecOrigin[0], badpos3[0]) == 0 && FloatCompare(VecOrigin[1], badpos3[1]) == 0 && FloatCompare(VecOrigin[2], badpos3[2]) == 0) || 
		(FloatCompare(VecOrigin[0], badpos4[0]) == 0 && FloatCompare(VecOrigin[1], badpos4[1]) == 0 && FloatCompare(VecOrigin[2], badpos4[2]) == 0))
		{
			if(!IsFakeClient(i))
			{
				ForcePlayerSuicide(i);
				CreateTimer(2.5, RespawnClient, i);
			}
		}
		if((FloatCompare(VecOrigin[0], badpos1[0]) == 0 && FloatCompare(VecOrigin[1], badpos1[1]) == 0 && FloatCompare(VecOrigin[2], badpos1[2]) == 0))
		{
			if(!IsFakeClient(i))
			{
				ForcePlayerSuicide(i);
				CreateTimer(2.5, RespawnClient, i);
			}
		}
	}
}

public Action:RespawnClient(Handle:timer, any:client)
{
	decl Float:badpos1[3];
	decl Float:badpos2[3];
	decl Float:badpos3[3];
	decl Float:badpos4[3];
	decl Float:goodpos1[3];
	decl Float:goodpos2[3];

	badpos1[0] = 1168.0;
	badpos1[1] = 4446.0;
	badpos1[2] = 508.0;

	goodpos1[0] = 911.0;
	goodpos1[1] = 3656.0;
	goodpos1[2] = 171.0;

	badpos2[0] = -216.0;
	badpos2[1] = -1055.0;
	badpos2[2] = 414.0;

	badpos3[0] = -256.0;
	badpos3[1] = -1120.0;
	badpos3[2] = 412.0;

	badpos4[0] = -236.0;
	badpos4[1] = -1076.0;
	badpos4[2] = 414.0;

	goodpos2[0] = -442.0;
	goodpos2[1] = -1080.0;
	goodpos2[2] = 382.0;
	
	SDKCall(hRoundRespawn, client);
	decl Float:pos[3];
	decl String:map[256];
	GetCurrentMap(map, sizeof(map));
	if(!IsValidEntity(client))
	{
		return;
	}
	if(StrEqual(map, "c6m1_riverbank"))
	{
		pos = goodpos1;
	}
	if(StrEqual(map, "c6m3_port"))
	{
		pos = goodpos2;
	}
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}