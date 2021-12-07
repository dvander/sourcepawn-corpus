#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#pragma semicolon		1
#pragma newdecls		required

#define PLUGIN_VERSION		"1.2"

#define and	&&
#define or	||

#define PLYR			MAXPLAYERS+1
#define IsClientValid(%1)	( 0 < %1 and %1 <= MaxClients )
#define nullvec			NULL_VECTOR

public Plugin myinfo = { //registers plugin
	name = "projectile indicator",
	author = "Nergal/Assyrian/Ashurian",
	description = "Has players detect nearby projectiles",
	version = PLUGIN_VERSION,
	url = "Alliedmodders",
};

bool bDetectProjs[PLYR];

ConVar
	PluginEnabled,
	DetectGrenades,
	DetectStickies,
	DetectGrenadeRadius,
	DetectStickyRadius,
	DetectFriendly
;

public void OnPluginStart ()	// be a rebel! Detach parameter parens from func name !
{
	PluginEnabled = CreateConVar("projindic_enabled", "1", "Enable Projectile Indicator plugin", FCVAR_NONE, true, 0.0, true, 1.0);

	DetectGrenades = CreateConVar("projindic_grenades", "1", "Enable the Projectile Indicator plugin to detect pipe grenades", FCVAR_NONE, true, 0.0, true, 1.0); // THIS INCLUDES CANNONBALLS

	DetectStickies = CreateConVar("projindic_stickies", "1", "Enable the Projectile Indicator plugin to detect stickybombs", FCVAR_NONE, true, 0.0, true, 1.0);

	DetectGrenadeRadius = CreateConVar("projindic_grenaderadius", "300.0", "Detection radius for pipe grenades in Hammer Units", FCVAR_NONE, true, 0.0, true, 99999.0);

	DetectStickyRadius = CreateConVar("projindic_stickyradius", "300.0", "Detection radius for stickybombs in Hammer Units", FCVAR_NONE, true, 0.0, true, 99999.0);

	DetectFriendly = CreateConVar("projindic_detectfriendly", "1", "Detect friendly projectiles", FCVAR_NONE, true, 0.0, true, 1.0);

	//RegAdminCmd("sm_command", CommandTemplate, ADMFLAG_SLAY, "AdminCommandTemplate");
	RegConsoleCmd("sm_detect", ToggleIndicator);
	RegConsoleCmd("sm_indic", ToggleIndicator);
	RegConsoleCmd("sm_forcedetect", ForceDetection);
	RegConsoleCmd("sm_forcedetection", ForceDetection);

	AutoExecConfig(true, "Projectile-Indicator");

	for (int i=MaxClients; i ; --i) {
		if ( !IsValidClient(i) )
			continue;
		OnClientPutInServer(i);
	}
}

public void OnClientPutInServer (int client)
{
	bDetectProjs[client] = true;
	SDKHook(client, SDKHook_PostThinkPost, IndicatorThink);
	//CreateTimer(0.1, TimerIndicatorThink, client, TIMER_REPEAT);
}
public void IndicatorThink (int client)
{
	if ( !PluginEnabled.BoolValue )
		return ;
	else if ( !bDetectProjs[client] )
		return ;
	else if ( !IsPlayerAlive(client) or IsClientObserver(client) )
		return ;

	float screenx,
		screeny,
		vecGrenDelta[3],
		vecStickyDelta[3]
	;

	int iEntity = -1,
		refentity,
		thrower // make variables OUTSIDE loop
	;

	if (DetectGrenades.BoolValue) {
		while ( (iEntity = FindEntityByClassname(iEntity, "tf_projectile_pipe")) != -1 )
		{
			refentity = EntIndexToEntRef(iEntity);
			if ( GetDistFromProj(client, refentity) > DetectGrenadeRadius.FloatValue ) {
				continue;
			}

			thrower = GetThrower(iEntity);
			if ( thrower != -1 and GetClientTeam(thrower) == GetClientTeam(client) and !DetectFriendly.BoolValue ) {
				continue;
			}
			vecGrenDelta = GetDeltaVector(client, refentity);
			NormalizeVector(vecGrenDelta, vecGrenDelta);
			GetProjPosToScreen(client, vecGrenDelta, screenx, screeny);
			DrawIndicator(client, screenx, screeny, "O");
		}
	}
	iEntity = -1;
	if (DetectStickies.BoolValue) {
		while ( (iEntity = FindEntityByClassname(iEntity, "tf_projectile_pipe_remote")) != -1 )
		{
			refentity = EntIndexToEntRef(iEntity);
			if ( GetDistFromProj(client, refentity) > DetectStickyRadius.FloatValue )
				continue;

			thrower = GetThrower(iEntity);
			if ( thrower != -1 and GetClientTeam(thrower) == GetClientTeam(client) and !DetectFriendly.BoolValue )
				continue;

			vecStickyDelta = GetDeltaVector(client, refentity);
			NormalizeVector(vecStickyDelta, vecStickyDelta);
			GetProjPosToScreen(client, vecStickyDelta, screenx, screeny);
			DrawIndicator(client, screenx, screeny, "X");
		}
	}
	return ;
}

public Action ToggleIndicator (int client, int args)
{
	if ( !PluginEnabled.BoolValue )
		return Plugin_Continue;

	bDetectProjs[client] = true;
	ReplyToCommand(client, "Projectile Indicator on");
	return Plugin_Handled;
}
public Action ForceDetection (int client, int args)	// forces players to become the tank class regardless of team cvars
{
	if (!PluginEnabled.BoolValue)
		return Plugin_Handled;

	if (args < 1) {
		ReplyToCommand(client, "[Projectile Indicator] Usage: sm_forcedetect <player/target>");
		return Plugin_Handled;
	}
	char name[PLATFORM_MAX_PATH]; GetCmdArg(1, name, sizeof(name));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[PLYR], target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(name, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i=0; i < target_count; ++i)
		if (IsValidClient(target_list[i]))
			bDetectProjs[target_list[i]] = true;

	ReplyToCommand(client, "Forcing Projectile Indicators");

	return Plugin_Handled;
}
/*
public Action CommandTemplate(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[Speed Mod] Usage: !command <target> <parameter>");
		return Plugin_Handled;
	}
	char szTargetname[64]; GetCmdArg(1, szTargetname, sizeof(szTargetname));
	char szNum[64]; GetCmdArg(2, szNum, sizeof(szNum));


	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS+1], target_count;
	bool tn_is_ml;
	if ( (target_count = ProcessTargetString(szTargetname, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0 )
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		if ( IsValidClient(target_list[i]) )
		{

		}
	}
	return Plugin_Handled;
}*/

stock bool IsValidClient (const int client, bool replaycheck=true)
{
	if ( !IsClientValid(client) )
		return false;
	if ( !IsClientInGame(client) )
		return false;
	if ( GetEntProp(client, Prop_Send, "m_bIsCoaching") )
		return false;
	if ( replaycheck )
		if ( IsClientSourceTV(client) or IsClientReplay(client) )
			return false;
	return true;
}
stock int GetOwner (const int ent)
{
	if ( IsValidEdict(ent) and IsValidEntity(ent) )
		return GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	return -1;
}
stock int GetThrower (const int ent)
{
	if ( IsValidEdict(ent) and IsValidEntity(ent) )
		return GetEntPropEnt(ent, Prop_Send, "m_hThrower");
	return -1;
}

/**
	 * Gets the position of the projectile from the player's position
	 * and converts the data to screen numbers
	 *
	 * @param vecDelta	delta vector to work from
	 * @param xpos		x position of the screen
	 * @param ypos		y position of the screen
	 * @noreturn
	 * @note		set xpos and ypos as references so we can "return" both of them.
	 * @props		Code by Valve from their Source Engine hud_damageindicator.cpp
**/
stock void GetProjPosToScreen ( const int client, const float vecDelta[3], float& xpos, float& ypos )
{
	//float flRadius = 360.0;
	/*
	 get Player Data: eye position and angles - Why do we need eye pos? it's NEVER used!
	 EVEN IN THE ORIGINAL C++ CODE, playerPosition ISN'T USED. Wtf valve?
	*/		
	//float playerPosition[3]; GetClientEyePosition(client, playerPosition);
	float playerAngles[3]; GetClientEyeAngles(client, playerAngles);

	float vecforward[3], right[3], up[3] = { 0.0, 0.0, 1.0 };
	GetAngleVectors(playerAngles, vecforward, nullvec, nullvec );
	vecforward[2] = 0.0;

	NormalizeVector(vecforward, vecforward);
	GetVectorCrossProduct(up, vecforward, right);

	float front = GetVectorDotProduct(vecDelta, vecforward);
	float side = GetVectorDotProduct(vecDelta, right);
	/*
		this is part of original c++ code. unfortunately, it didn't work right.
		it made the indicators appear to the side when a projectile was RIGHT IN FRONT OF PLAYER...
		however, switching it made it work as intended =3
	*/
	//xpos = flRadius * -side;
	//ypos = flRadius * -front;

	xpos = 360.0 * -front;
	ypos = 360.0 * -side;

	// Get the rotation (yaw)
	//float flRotation = ArcTangent2(xpos, ypos) + FLOAT_PI;
	//flRotation *= 180.0 / FLOAT_PI; // Convert to degrees

	float flRotation = (ArcTangent2(xpos, ypos) + FLOAT_PI) * (180.0 / FLOAT_PI);

	float yawRadians = -flRotation * FLOAT_PI / 180.0; // Convert back to radians
	//float coss = Cosine(yawRadians);
	//float sinu = Sine(yawRadians);

	// Rotate it around the circle
	xpos = ( 500 + (360.0 * Cosine(yawRadians)) ) / 1000.0; // divide by 1000 to make it fit with HudTextParams
	ypos = ( 500 - (360.0 * Sine(yawRadians)) ) / 1000.0;
}
/**
 * gets the delta vector between player and projectile!
 *
 * @param entref	serial reference of the entity
 * @param vecBuffer	float buffer to store vector result
 * @return		delta vector from vecBuffer
 */
stock float[] GetDeltaVector( const int client, const int entref )
{
	float vec[3];
	int proj = EntRefToEntIndex(entref);
	if ( proj <= 0 or !IsValidEntity(proj) )
		return vec;

	float vecPlayer[3];	GetClientAbsOrigin(client, vecPlayer);
	float vecPos[3];	GetEntPropVector(proj, Prop_Data, "m_vecAbsOrigin", vecPos);
	SubtractVectors( vecPlayer, vecPos, vec );
	return vec;
}

/**
 * gets the distance between player and projectile!
 *
 * @param entref	serial reference of the entity
 * @return		distance between player and proj
 */
stock float GetDistFromProj ( const int client, const int entref )
{
	int proj = EntRefToEntIndex(entref);
	if ( proj <= 0 or !IsValidEntity(proj) )
		return -1.0;

	float projpos[3]; GetEntPropVector(proj, Prop_Data, "m_vecAbsOrigin", projpos);
	float clientpos[3]; GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", clientpos);
	return GetVectorDistance(clientpos, projpos);
}

/**
 * Displays the Projectile indicator to alert player of nearly projectiles
 *
 * @param xpos		x position of the screen
 * @param ypos		y position of the screen
 * @noreturn
 */
/*	This is how SetHudTextParams sets the x and y pos
	|-------------------------------------------------------|
	|			y 0.0				|
	|			|				|
	|			|				|
	|			|				|
	|			|				|
	|			|				|
	|			|				|
	|x 0.0 -----------------|-------------------------> 1.0 |
	|			|				|
	|			|				|
	|			|				|
	|			|				|
	|			V				|
	|			1.0				|
	|-------------------------------------------------------|
*/
stock void DrawIndicator ( const int client, const float xpos, const float ypos, const char[] textc )
{
	//Handle HUDindicator = CreateHudSynchronizer();
	SetHudTextParams(xpos, ypos, 0.1, 255, 100, 0, 255, 0, 0.35, 0.0, 0.1); // orange color for visibility
	//ShowSyncHudText(client, HUDindicator, textc);
	ShowHudText(client, -1, textc);
}
