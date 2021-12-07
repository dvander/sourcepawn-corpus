#define PLUGIN_VERSION 		"1.0"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Molotov Drink
*	Author	:	Dragokas & SilverShot
*	Descrp	:	Get drunk by drinking Molotovs.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=329271
*	Plugins	:	http://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers
*	Plugins	:	http://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Dragokas

========================================================================================
	Change Log:

1.0 (17-Jan-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define EFFECT_TIME			10.0

#define g_FreezeSound "physics/glass/glass_impact_bullet4.wav"
#define g_DrinkSound_1 "player/items/pain_pills/pills_use_1.wav"
#define g_DrinkSound_2 "player/survivor/splat/hit_slimesplat7.wav"
#define g_DrinkSound_3 "player/water/pl_wade2.wav"

ConVar	g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarDelete;
int		g_iCvarDelete;
bool	g_bCvarAllow, g_bLeft4Dead2, g_bActive;
bool	g_bDrinking[MAXPLAYERS+1];
int		g_iIntensity[MAXPLAYERS+1];
float	g_fStartTime[MAXPLAYERS+1];
float	g_fFinalAngle[MAXPLAYERS+1];
float	g_fPrevAngle[MAXPLAYERS+1];
float	g_fDirAngle[MAXPLAYERS+1];
int		g_iFrame[MAXPLAYERS+1];
bool 	g_bSway[MAXPLAYERS+1];
float 	g_fEyeAngles[MAXPLAYERS+1][3];
int		g_iPlayerColor[MAXPLAYERS+1][4];
int		g_iUsedCount[MAXPLAYERS+1];
int		g_iLastEntity[MAXPLAYERS+1];
bool	g_bFreezed[MAXPLAYERS+1];
Handle	g_hDrinking[MAXPLAYERS+1];
UserMsg	g_FadeUserMsgId;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Molotov Drink",
	author = "Dragokas & SilverShot",
	description = "Get drunk by drinking Molotovs.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=329271"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	if( late ) g_bActive = true;
	CreateNative("MD_Intoxicate", NATIVE_Intoxicate);
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow = CreateConVar(		"l4d_molotov_drink_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(		"l4d_molotov_drink_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(		"l4d_molotov_drink_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(		"l4d_molotov_drink_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarDelete = CreateConVar(		"l4d_molotov_drink_uses",			"5",			"Maximum drinks per Molotov, deletes after this many uses.", CVAR_FLAGS );
	CreateConVar(						"l4d_molotov_drink_version",		PLUGIN_VERSION,	"Molotov Drink plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_molotov_drink");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarDelete.AddChangeHook(ConVarChanged_Cvars);

	// UserMsg
	g_FadeUserMsgId = GetUserMessageId("Fade");
}

public int NATIVE_Intoxicate(Handle plugin, int numParams)
{
	if(numParams < 2 )
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");

	int iClient = GetNativeCell(1);
	int iLevel = GetNativeCell(2);

	if( iLevel == g_iIntensity[iClient] )
	{
		return 0;
	}
	else if( iLevel == 0 )
	{
		g_iIntensity[iClient] = 0;
	}
	else if( iLevel == -1 )
	{
		CreateTimer(0.0, tmrDrinking, GetClientUserId(iClient));
	}
	else if( iLevel > g_iIntensity[iClient] )
	{
		g_iIntensity[iClient] = iLevel - 1;
		CreateTimer(0.0, tmrDrinking, GetClientUserId(iClient));
	}
	else {
		g_iIntensity[iClient]--;
	}
	return 1;
}


// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarDelete = g_hCvarDelete.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("round_start", Event_RoundStart);
		HookEvent("round_end", Event_RoundEnd);
		HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("round_start", Event_RoundStart);
		UnhookEvent("round_end", Event_RoundEnd);
		UnhookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	static char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}

public void OnMapStart()
{
	PrecacheSound(g_FreezeSound, true);
	PrecacheSound(g_DrinkSound_1, true);
	PrecacheSound(g_DrinkSound_2, true);
	PrecacheSound(g_DrinkSound_3, true);
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bActive = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		g_iFrame[i] = 0;
		g_iIntensity[i] = 0;
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bActive = false;
	OnMapEnd();
}

public void OnMapEnd()
{
	for( int i = 0; i <= MaxClients; i++ )
	{
		g_iUsedCount[i] = 0;
		g_iLastEntity[i] = 0;
	}
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));  // ?????
	g_bDrinking[client] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( g_bCvarAllow && g_bActive && (buttons & IN_ZOOM) )
	{
		if( HoldingMolotov(client) )
		{
			if( g_bDrinking[client] == false )
			{
				g_bDrinking[client] = true;

				SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
				if( g_bLeft4Dead2 )
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 1.0);
				else
					SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 1);

				g_hDrinking[client] = CreateTimer(1.0, tmrDrinking, GetClientUserId(client));
			}
			return;
			
		} else {
			if( g_hDrinking[client] != null )
				delete g_hDrinking[client];
		}
	} else {
		if( g_hDrinking[client] != null )
			delete g_hDrinking[client];
	}

	if( g_bDrinking[client] )
	{
		g_bDrinking[client] = false;

		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
		if( g_bLeft4Dead2 )
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
		else
			SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
	}
}

public Action tmrDrinking(Handle timer, int client)
{
	if( (client = GetClientOfUserId(client)) )
	{
		g_hDrinking[client] = null;

		int weapon = HoldingMolotov(client);
		if( weapon != g_iLastEntity[client] )
		{
			g_iLastEntity[client] = 0;
			g_iUsedCount[client] = 0;
		}

		if( weapon && g_iUsedCount[client] >= g_iCvarDelete )
		{
			AcceptEntityInput(weapon, "Kill");
		}

		if( g_iIntensity[client] == 0 )
		{
			CreateTimer(1.0, tmrDrunk, GetClientUserId(client), TIMER_REPEAT);
		}

		switch(GetRandomInt(1, 3))
		{
			case 1: EmitSoundToClient(client, g_DrinkSound_1);
			case 2: EmitSoundToClient(client, g_DrinkSound_2);
			case 3: EmitSoundToClient(client, g_DrinkSound_3, _, _, SNDLEVEL_GUNFIRE);
		}

		if( g_iIntensity[client] < 3 )
			g_iIntensity[client] += 1;

		//PrintToChat(client, "Intensity: %i", g_iIntensity[client] );

		g_fStartTime[client] = GetGameTime();
	}
}

public Action tmrDrunk(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);

	if( client )
	{
		if( !IsClientInGame(client) || !IsPlayerAlive(client) )
		{
			StopEffects(client);
			return Plugin_Stop;
		}

		float diff = GetGameTime() - g_fStartTime[client];

		if( diff < 0 )
		{
			StopEffects(client);
			return Plugin_Stop;
		}

		if( diff >= EFFECT_TIME )
		{
			g_iIntensity[client] -= 1;
			if( g_iIntensity[client] <= 0 )
			{
				StopEffects(client);
				return Plugin_Stop;
			}
			else if( g_iIntensity[client] == 2 )
			{
				UnFreezePlayer(client);
			}
			g_fStartTime[client] = GetGameTime();
		}
		DoEffects(client);
	}
	else {
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void SmoothSway(int client)
{
	const float step = 0.5;
	StopSway(client);
	g_bSway[client] = true;
	float angs[3];
	GetClientEyeAngles(client, angs);
	CopyVector(angs, g_fEyeAngles[client]);
	g_fPrevAngle[client] = angs[2];
	g_fDirAngle[client] = g_fFinalAngle[client] > angs[2] ? step : -step;
	SDKHook(client, SDKHook_PreThink,  OnPreThinkClient);
	SDKHook(client, SDKHook_PreThinkPost,  OnThinkClient);
}

void StopSway(int client)
{
	if( IsClientInGame(client) )
	{
		SDKUnhook(client, SDKHook_PreThink,  OnPreThinkClient);
		SDKUnhook(client, SDKHook_PreThinkPost,  OnThinkClient);
	}
	g_bSway[client] = false;
}

public void OnPreThinkClient(int client)
{
	GetClientEyeAngles(client, g_fEyeAngles[client]);
}

public void OnThinkClient(int client)
{
	static float angs[3];

	g_iFrame[client]++;

	if( g_iFrame[client] % 1 == 0 )
	{
		if( !IsClientInGame(client) || g_iIntensity[client] < 2 )
		{
			StopSway(client);
		}
		else {
			CopyVector(g_fEyeAngles[client], angs);

			angs[2] += g_fDirAngle[client];

			//PrintToChatAll("dir: %.2f. Cur: %f, final: %f", g_fDirAngle[client], angs[2], g_fFinalAngle[client]);

			if( (g_fDirAngle[client] > 0.0 && angs[2] > g_fFinalAngle[client]) || (g_fDirAngle[client] < 0.0 && angs[2] < g_fFinalAngle[client]) )
			{
				g_fDirAngle[client] *= -1.0;
				g_fFinalAngle[client] = GetRandomAngle( client, g_fDirAngle[client] );
			}

			if( g_fPrevAngle[client] != angs[2] )
			{
				if( ( g_fDirAngle[client] > 0.0 && angs[2] > g_fPrevAngle[client] ) || (g_fDirAngle[client] < 0.0 && angs[2] < g_fPrevAngle[client]) )
				{
					TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
					g_fPrevAngle[client] = angs[2];
				}
			}
		}
	}
}

void CopyVector(float vec[3], float dst[3])
{
	for (int i = 0; i < 3; i++)
		dst[i] = vec[i];
}

float GetRandomAngle(int client, float dir = 0.0)
{
	float min = 4.0 * g_iIntensity[client];
	float max = 9.0 * g_iIntensity[client];
	if( dir == 0.0 )
	{
		return GetRandomInt(0,1) ? GetRandomFloat(-max,-min) : GetRandomFloat(min,max);
	}
	return dir < 0.0 ? GetRandomFloat(-max,-min) : GetRandomFloat(min,max);
}

void FreezePlayer(int client)
{
	//PrintToChat(client, "FreezePlayer. State: %b", g_bFreezed[client]);

	if( g_bFreezed[client] )
		return;
	SetEntityMoveType(client, MOVETYPE_NONE);
	GetEntityRenderColor(client, g_iPlayerColor[client][0], g_iPlayerColor[client][1], g_iPlayerColor[client][2], g_iPlayerColor[client][3]);
	SetEntityRenderColor(client, 0, 128, 255, 192);
	float vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(g_FreezeSound, vec, client, SNDLEVEL_RAIDSIREN);
	g_bFreezed[client] = true;
}

void UnFreezePlayer(int client)
{
	//PrintToChat(client, "UnFreezePlayer");

	if( !g_bFreezed[client] )
		return;
	int r, g, b, a;
	SetEntityMoveType(client, MOVETYPE_WALK);
	GetEntityRenderColor(client, r, g, b, a);
	SetEntityRenderColor(client, g_iPlayerColor[client][0], g_iPlayerColor[client][1], g_iPlayerColor[client][2], a == 192 ? g_iPlayerColor[client][3] : a );
	float vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(g_FreezeSound, vec, client, SNDLEVEL_RAIDSIREN);
	g_bFreezed[client] = false;
}

void DoEffects(int client)
{
	//PrintToChat(client, "DoEffects" );

	float angs[3];

	switch (g_iIntensity[client])
	{
		case 1: {
			if( !g_bSway[client] )
			{
				GetClientEyeAngles(client, angs);
				angs[2] = GetRandomAngle(client);
				TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
			}
		}
		case 2: {
			if( !g_bSway[client] )
			{
				g_fFinalAngle[client] = GetRandomAngle(client);
				SmoothSway(client);
			}
			SetFade(client);
		}
		case 3: {
			FreezePlayer(client);
			SetFade(client);
		}
	}
}

void StopEffects(int client)
{
	//PrintToChat(client, "StopEffects" );

	if( g_bSway[client] )
	{
		StopSway(client);
	}

	if( IsClientInGame(client) )
	{
		float angs[3];
		GetClientEyeAngles(client, angs);
		angs[2] = 0.0;
		TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);

		UnFreezePlayer(client);
		RemoveFade(client);
	}

	g_iIntensity[client] = 0;
}

void SetFade(int client)
{
	int clients[1];
	clients[0] = client;

	int duration = 255;
	int holdtime = 255;
	int flags = 0x0002;
	int color[4] = { 0, 0, 0, 128 };
	color[0] = GetRandomInt(0, g_iIntensity[client] * 85);
	color[1] = GetRandomInt(0, g_iIntensity[client] * 85);
	color[2] = GetRandomInt(0, g_iIntensity[client] * 85);
	color[3] = 64 + g_iIntensity[client] * 32;

	Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	if( message != INVALID_HANDLE )
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);

		EndMessage();
	}
}

void RemoveFade(int client)
{
	int clients[1];
	clients[0] = client;

	int duration = 1536;
	int holdtime = 1536;
	int flags = (0x0001 | 0x0010);
	int color[4] = { 0, 0, 0, 0 };

	Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	if( message != INVALID_HANDLE )
	{
		if( GetUserMessageType() == UM_Protobuf )
		{
			Protobuf pb = UserMessageToProtobuf(message);
			pb.SetInt("duration", duration);
			pb.SetInt("hold_time", holdtime);
			pb.SetInt("flags", flags);
			pb.SetColor("clr", color);
		}
		else
		{
			BfWrite bf = UserMessageToBfWrite(message);
			bf.WriteShort(duration);
			bf.WriteShort(holdtime);
			bf.WriteShort(flags);
			bf.WriteByte(color[0]);
			bf.WriteByte(color[1]);
			bf.WriteByte(color[2]);
			bf.WriteByte(color[3]);
		}
		EndMessage();
	}
}

int HoldingMolotov(int client)
{
	int weapon;
	if( client && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
	{
		weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( weapon > 0 && IsValidEntity(weapon) )
		{
			static char sTemp[16];
			GetEntityClassname(weapon, sTemp, sizeof(sTemp));
			if( strncmp(sTemp[7], "molotov", 7) == 0 )
				return weapon;
		}
	}
	return 0;
}