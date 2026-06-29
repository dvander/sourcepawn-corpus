/*
V1.0
Initial Release
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

bool bLateLoad;
EngineVersion game;
int iTime[MAXPLAYERS+1], iWeaponId[MAXPLAYERS+1], HintIndex[2048+1], HintEntity[2048+1];
bool bFirstSwitch[MAXPLAYERS+1];
float fPipeTimer[2048+1];
static const char SOUND[] = "^buttons/button14.wav";

ConVar MinTime, MaxTime, ShowHint, ShowThruWalls;
Handle hGameData = null;

public Plugin myinfo =
{
	name = "Enhanced Pipe Bomb",
	author = "MasterMind420",
	description = "Adds Some Options To Pipe Bombs",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	hGameData = LoadGameConfigFile("l4d_pipe_bomb");

	if (hGameData == null)
		SetFailState("l4d_pipe_bomb Game data missing!");

	MinTime = CreateConVar("l4d_min_time", "1", "Minimum Allowed Pipebomb Timer");
	MaxTime = CreateConVar("l4d_max_time", "8", "Maximum Allowed Pipebomb Timer");
	ShowHint = CreateConVar("l4d_show_hint", "1", "[1 = Enable][0 = Disable] Show Timer Hint On Thrown Pipe Bomb");
	ShowThruWalls = CreateConVar("l4d_show_thru_walls", "1", "[1 = Enable][0 = Disable] Show Timer Hint Thru Walls/Objects");

	AutoExecConfig(true, "l4d_enhanced_pipebomb");

	HookEvent("player_disconnect", ePlayerDisconnect);

	if (bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
				OnClientPutInServer(i);
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	game = GetEngineVersion();

	if (game != Engine_Left4Dead && game != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	bLateLoad = late;
	return APLRes_Success;
}

public void OnMapStart()
{
	PrefetchSound(SOUND);
	PrecacheSound(SOUND, true);
}

public void OnClientPutInServer(int client)
{
	iTime[client] = GetConVarInt(MaxTime);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnWeaponSwitchPost(int client, int weapon)
{
	iWeaponId[client] = 0;
	weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if (weapon > MaxClients && IsValidEntity(weapon))
	{
		char sClsName[12];
		GetEntityClassname(weapon, sClsName, sizeof(sClsName));

		if (strncmp(sClsName[7], "pipe", 4) == 0)
		{
			iWeaponId[client] = weapon;

			if (!bFirstSwitch[client])
			{
				bFirstSwitch[client] = true;
				PrintToChat(client, "\x04[TIMER] \x01PRESS RELOAD TO CHANGE TIMER");
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		static int iWeapon;
		iWeapon = iWeaponId[client];

		if (iWeapon > MaxClients && IsValidEntity(iWeapon))
		{
			if (GetEntProp(client, Prop_Data, "m_afButtonPressed") & IN_RELOAD)
			{
				iTime[client]++;

				if (iTime[client] > GetConVarInt(MaxTime))
					iTime[client] = GetConVarInt(MinTime);

				EmitSoundToClient(client, SOUND, _, SNDCHAN_STATIC, SNDLEVEL_GUNFIRE);
				PrintToChat(client, "\x04[TIMER] \x01%i", iTime[client]);
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "pipe_bomb_projectile"))
		SDKHook(entity, SDKHook_SpawnPost, SpawnPost);
}

public void SpawnPost(int entity)
{
	if (IsValidEntity(entity))
		RequestFrame(NextFrame, EntIndexToEntRef(entity));
}

public void NextFrame(any entref)
{
	int entity = EntRefToEntIndex(entref);

	if (IsValidEntity(entity))
	{
		int iThrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");

		if (iThrower > 0 && iThrower <= MaxClients)
		{
			char sModel[2];
			GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

			if (sModel[0] == 0)
				return;

			CreateHintEntity(entity);
			SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
			fPipeTimer[entity] = GetEngineTime() + float(iTime[iThrower]);
			CreateTimer(0.1, PipeBombThink, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			iTime[iThrower] = GetConVarInt(MaxTime);
		}
	}
}

public Action PipeBombThink(Handle timer, any entref)
{
	int entity = EntRefToEntIndex(entref);

	if (IsValidEntity(entity))
	{
		float fTimer = fPipeTimer[entity] - GetEngineTime();
		int iTimer = RoundFloat(fTimer);

		if (iTimer <= 0)
		{
			DestroyHintEntity(entity);
			DetonatePipeBombSig(entity);
			return Plugin_Stop;
		}

		if (GetConVarInt(ShowHint) == 1)
		{
			char sMessage[3];
			Format(sMessage, sizeof(sMessage), "%i", iTimer);
			DisplayInstructorHint(entity, 0.0, 0.0, 0.0, true, false, "", "", "", GetConVarInt(ShowThruWalls), {255, 255, 0}, sMessage);
		}

		return Plugin_Continue;
	}

	return Plugin_Stop;
}

void DetonatePipeBombSig(int entity)
{
	static Handle hSig;

	if (hSig == null)
	{
		StartPrepSDKCall(SDKCall_Entity);

		if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CPipeBombProjectile_Detonate"))
			SetFailState("CPipeBombProjectile_Detonate unable to find signature");

		hSig = EndPrepSDKCall();
	}

	if (IsValidEntity(entity))
	{
		if (hSig != null)
			SDKCall(hSig, entity);
		else
			SetFailState("CPipeBombProjectile_Detonate Signature broken.");
	}
}

public void ePlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	bFirstSwitch[GetClientOfUserId(event.GetInt("userid"))] = false;
}

stock void DisplayInstructorHint(int target, float fTime, float fHeight, float fRange, bool bFollow, bool bShowOffScreen, char[] sIconOnScreen, char[] sIconOffScreen, char[] sCmd, int ShowTextAlways, int iColor[3], char sText[3])
{
	if (!IsValidEntity(HintEntity[target]))
		return;

	char sBuffer[32];

	FormatEx(sBuffer, sizeof(sBuffer), "pipe_%d", target);
	DispatchKeyValue(target, "targetname", sBuffer);
	DispatchKeyValue(HintEntity[target], "hint_target", sBuffer);
	DispatchKeyValue(HintEntity[target], "hint_name", sBuffer);
	DispatchKeyValue(HintEntity[target], "hint_replace_key", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bFollow);
	DispatchKeyValue(HintEntity[target], "hint_static", sBuffer);
	DispatchKeyValue(HintEntity[target], "hint_timeout", "0.0");

	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fHeight));
	DispatchKeyValue(HintEntity[target], "hint_icon_offset", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fRange));
	DispatchKeyValue(HintEntity[target], "hint_range", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bShowOffScreen);
	DispatchKeyValue(HintEntity[target], "hint_nooffscreen", sBuffer);

	DispatchKeyValue(HintEntity[target], "hint_icon_onscreen", sIconOnScreen);
	DispatchKeyValue(HintEntity[target], "hint_icon_offscreen", sIconOffScreen);

	DispatchKeyValue(HintEntity[target], "hint_binding", sCmd);

	//FormatEx(sBuffer, sizeof(sBuffer), "%d", ShowTextAlways);
	DispatchKeyValue(HintEntity[target], "hint_forcecaption", "1");

	FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d", iColor[0], iColor[1], iColor[2]);
	DispatchKeyValue(HintEntity[target], "hint_color", sBuffer);

	//ReplaceString(sText, sizeof(sText), "\n", " ");
	DispatchKeyValue(HintEntity[target], "hint_caption", sText);
	DispatchKeyValue(HintEntity[target], "hint_activator_caption", sText);
	DispatchKeyValue(HintEntity[target], "hint_flags", "0");
	DispatchKeyValue(HintEntity[target], "hint_display_limit", "0");
	DispatchKeyValue(HintEntity[target], "hint_suppress_rest", "1");
	DispatchKeyValue(HintEntity[target], "hint_instance_type", "2");
	DispatchKeyValue(HintEntity[target], "hint_auto_start", "false");
	DispatchKeyValue(HintEntity[target], "hint_local_player_only", "true");
	DispatchKeyValue(HintEntity[target], "hint_allow_nodraw_target", "true");
	//DispatchKeyValue(HintEntity[target], "hint_pulseoption", "1");
	//DispatchKeyValue(HintEntity[target], "hint_alphaoption", "1");
	//DispatchKeyValue(HintEntity[target], "hint_shakeoption", "1");

	AcceptEntityInput(HintEntity[target], "ShowHint");
	HintIndex[target] = EntIndexToEntRef(HintEntity[target]);
}

void DestroyHintEntity(int client)
{
	if (IsValidEntRef(HintIndex[client]))
	{
		AcceptEntityInput(HintIndex[client], "Kill");
		HintIndex[client] = -1;
	}
}

void CreateHintEntity(int client)
{
	if (IsValidEntRef(HintIndex[client]))
	{
		AcceptEntityInput(HintIndex[client], "Kill");
		HintIndex[client] = -1;
	}

	HintEntity[client] = CreateEntityByName("env_instructor_hint");

	if (HintEntity[client] < 0)
		return;

	DispatchSpawn(HintEntity[client]);

	HintIndex[client] = EntIndexToEntRef(HintEntity[client]);
}

static bool IsValidEntRef(int iEntRef)
{
    static int iEntity;
    iEntity = EntRefToEntIndex(iEntRef);
    return (iEntRef && iEntity != INVALID_ENT_REFERENCE && IsValidEntity(iEntity));
}