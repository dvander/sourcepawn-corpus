#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <zombiereloaded>

#pragma newdecls required

#define PLUGIN_NAME		 	"Anti-Stuck"
#define PLUGIN_AUTHOR	   	"Erreur 500, Wesker"
#define PLUGIN_DESCRIPTION	"Optimized player anti-stuck, with ZR support"
#define PLUGIN_VERSION	  	"1.8.1"
#define PLUGIN_CONTACT	  	"steam-gamers.net"

int 	g_iTimeLimit;
int 	g_iCounter[MAXPLAYERS + 1];
int 	g_iStuckCheck[MAXPLAYERS + 1];
bool	g_bZRLoaded = false;
bool	g_bRoundRestrict = false;
float 	g_fTime[MAXPLAYERS + 1];
float 	g_fHorizontalStep;
float 	g_fVerticalStep;
float	g_fHorizontalRadius;
float	g_fVerticalRadius;
float 	g_fOriginalPos[MAXPLAYERS + 1][3];
float 	g_fOriginalVel[MAXPLAYERS + 1][3];
Handle 	c_Limit			= null;
Handle 	c_Countdown		= null;
Handle 	c_HRadius		= null;
Handle 	c_VRadius		= null;
Handle 	c_HStep			= null;
Handle 	c_VStep			= null;
Handle 	c_Delay_H		= null;
Handle 	c_Delay_Z		= null;
Handle 	c_RoundTime		= null;
Handle 	c_SpawnCheck	= null;
Handle 	DelayTimer[MAXPLAYERS + 1];
Handle 	RoundTimer = null;


public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author	  	= PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version	 	= PLUGIN_VERSION,
	url		 	= PLUGIN_CONTACT
};

public void OnPluginStart()
{
	CreateConVar("sm_stuck_version", PLUGIN_VERSION, "Stuck version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_Limit			= CreateConVar("sm_stuck_limit", 				"1", 	"How many times command can be used before cooldown (0 = no limit)", _, true, 0.0);
	c_Countdown		= CreateConVar("sm_stuck_wait", 				"30", 	"How long the command cooldown is in seconds", _, true, 0.0, true, 1000.0);
	c_HRadius		= CreateConVar("sm_stuck_horizontal_radius", 	"60", 	"Horizontal radius size to fix player position", _, true, 10.0);
	c_VRadius		= CreateConVar("sm_stuck_vertical_radius", 		"190", 	"Vertical radius size to fix player position", _, true, 10.0);
	c_HStep			= CreateConVar("sm_stuck_horizontal_step", 		"30", 	"Horizontal distance between each position tested (recommended default)", _, true, 10.0);
	c_VStep			= CreateConVar("sm_stuck_vertical_step", 		"50", 	"Vertical distance between each position tested (recommended default)", _, true, 10.0);
	c_Delay_H		= CreateConVar("sm_stuck_delay_h",				"5", 	"How long to delay the command for a Human (in seconds), -1 to block", _, false, -1.0, true, 60.0);
	c_Delay_Z		= CreateConVar("sm_stuck_delay_z",				"2", 	"How long to delay the command for a Zombie (in seconds), -1 to block", _, false, -1.0, true, 60.0);
	c_RoundTime		= CreateConVar("sm_stuck_roundtime",			"0", 	"How long after the round starts can players use !stuck (0 to disable)", _, true, 0.0, false, _);
	c_SpawnCheck	= CreateConVar("sm_stuck_spawncheck",			"0", 	"Check if players are stuck after they spawn (1 to enable, 0 to disable)", _, true, 0.0, true, 1.0);
	
	HookConVarChange(c_Countdown, OnConVarChange);
	HookConVarChange(c_HRadius, OnConVarChange);
	HookConVarChange(c_VRadius, OnConVarChange);
	HookConVarChange(c_HStep, OnConVarChange);
	HookConVarChange(c_VStep, OnConVarChange);
	
	g_iTimeLimit = GetConVarInt(c_Countdown);
	if(g_iTimeLimit < 0)
		g_iTimeLimit = -g_iTimeLimit;
		
	g_fHorizontalStep = float(GetConVarInt(c_HStep));
	
	g_fVerticalStep = float(GetConVarInt(c_VStep));
		
	g_fHorizontalRadius = float(GetConVarInt(c_HRadius));
		
	g_fVerticalRadius = float(GetConVarInt(c_VRadius));
	
	RegConsoleCmd("sm_stuck", StuckCmd, "Are you stuck ?");
	RegConsoleCmd("sm_unstuck", StuckCmd, "Are you stuck ?");
	
	HookEvent("round_start",Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end",Event_RoundEnd, EventHookMode_PostNoCopy);
	
	if(!HookEventEx("player_spawn", Event_PlayerSpawn, EventHookMode_Post))
    {
        SetFailState("Hook event \"player_spawn\" failed");
        return;
	}
	
	AutoExecConfig(true, "stuck");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("ZR_IsClientZombie");
	MarkNativeAsOptional("ZR_IsClientHuman");
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	//Check if ZR is available
	g_bZRLoaded = GetFeatureStatus( FeatureType_Native, "ZR_IsClientHuman" ) == FeatureStatus_Available;
}

public void OnMapStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_iCounter[i] = 0;
		g_iStuckCheck[i] = -1;
		g_fTime[i] = GetGameTime();
	}
}

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (DelayTimer[i] != null)
		{
			KillTimer(DelayTimer[i]);
			DelayTimer[i] = null;
		}
	}
}

public void OnConVarChange(Handle cvar, const char[] oldVal, const char[] newVal)
{
    if (cvar == c_Countdown) {
    	g_iTimeLimit = StringToInt(newVal);
		if(g_iTimeLimit < 0)
			g_iTimeLimit = -g_iTimeLimit;
			
		LogMessage("stuck_wait = %i", g_iTimeLimit);
    } else if (cvar == c_HRadius) {
		g_fHorizontalRadius = float(StringToInt(newVal));
		if(g_fHorizontalRadius < 10.0)
			g_fHorizontalRadius = 10.0;
		
		LogMessage("horizontal_stuck_radius = %f", g_fHorizontalRadius);
	} else if (cvar == c_VRadius) {
		g_fVerticalRadius = float(StringToInt(newVal));
		if(g_fVerticalRadius < 10.0)
			g_fVerticalRadius = 10.0;
		
		LogMessage("vertical_stuck_radius = %f", g_fVerticalRadius);
	} else if (cvar == c_HStep) {
		g_fHorizontalStep = float(StringToInt(newVal));
		if(g_fHorizontalStep < 1.0)
			g_fHorizontalStep = 1.0;
			
		LogMessage("h_stuck_Step = %f", g_fHorizontalStep);
	} else if (cvar == c_VStep) {
		g_fVerticalStep = float(StringToInt(newVal));
		if(g_fVerticalStep < 1.0)
			g_fVerticalStep = 1.0;
			
		LogMessage("v_stuck_Step = %f", g_fVerticalStep);
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("userid");
	if (GetConVarInt(c_SpawnCheck) == 1) {
		if (DelayTimer[client] != null)
		{
			KillTimer(DelayTimer[client]);
			DelayTimer[client] = null;
		}
		DelayTimer[client] = CreateTimer(GetRandomFloat(0.5, 10.0), FDelayTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (int j = 1; j <= MaxClients; j++) {
		if (DelayTimer[j] != null)
		{
			KillTimer(DelayTimer[j]);
			DelayTimer[j] = null;
		}
		g_iStuckCheck[j] = -1;
	}
	g_bRoundRestrict = false;
	float RoundTime = float(GetConVarInt(c_RoundTime));
	if (RoundTime >= 1.0) {
		if (RoundTimer != null) {
			KillTimer(RoundTimer);
			RoundTimer = null;
		}
		RoundTimer = CreateTimer(RoundTime, RoundWait, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	for (int j = 1; j <= MaxClients; j++) {
		if (DelayTimer[j] != null)
		{
			KillTimer(DelayTimer[j]);
			DelayTimer[j] = null;
		}
		g_iStuckCheck[j] = -1;
	}
}

public Action RoundWait(Handle timer)
{
	g_bRoundRestrict = true;
	RoundTimer = null;
}

public void OnClientDisconnect(int client)
{
	if (DelayTimer[client] != null)
	{
		KillTimer(DelayTimer[client]);
		DelayTimer[client] = null;
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

public Action StuckCmd(int client, any args)
{
	
	if(!IsValidClient(client)) return;
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[Stuck] You must be alive to use this command");
		return;
	}
	
	if (GetConVarInt(c_RoundTime) >= 1) {
		if (g_bRoundRestrict) {
			PrintToChat(client, "[Stuck] %i seconds have past, you must wait until next round to use !stuck", GetConVarInt(c_RoundTime));
			return;
		}
	}
	
	//Check if g_iCounter is enabled
	if (GetConVarInt(c_Limit) > 0)
	{
		//If g_iCounter is more than 0
		if(g_iCounter[client] > 0)
		{
			//If cooldown has past, reset the g_iCounter
			if(g_fTime[client] < GetGameTime())
			{
				g_iCounter[client] = 0;
			}
		}
		
		//First g_iCounter set the delay to current time + delay
		if (g_iCounter[client] == 0)
			g_fTime[client] = GetGameTime() + float(g_iTimeLimit);
		
		//Player g_iCounter is over the limit, block command
		if (g_iCounter[client] >= GetConVarInt(c_Limit))
		{
			PrintToChat(client, "[Stuck] You must wait %i seconds before use this command again.", RoundFloat(g_fTime[client] - GetGameTime()));
			return;
		}
		
		//g_iCounter not yet reached limit, add to g_iCounter
		g_iCounter[client]++;
	}
	
	if (DelayTimer[client] != null || g_iStuckCheck[client] != -1)
	{
		PrintToChat(client, "[Stuck] Unstuck is already in progress, %i checks completed so far.", g_iStuckCheck[client]);
		return;
	}
	
	if (g_bZRLoaded) {
		if (GetConVarInt(c_Delay_H) > 0 && ZR_IsClientHuman(client))
		{
			PrintToChat(client, "[Stuck] Attempting unstuck in %i seconds.", GetConVarInt(c_Delay_H));
			DelayTimer[client] = CreateTimer(GetConVarFloat(c_Delay_H), FDelayTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		} else if (GetConVarInt(c_Delay_Z) > 0 && ZR_IsClientZombie(client)) {
			PrintToChat(client, "[Stuck] Attempting unstuck in %i seconds.", GetConVarInt(c_Delay_Z));
			DelayTimer[client] = CreateTimer(GetConVarFloat(c_Delay_Z), FDelayTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		} else if (GetConVarInt(c_Delay_H) < 0 && ZR_IsClientHuman(client)) {
			PrintToChat(client, "[Stuck] This command is disabled for Humans.");
			return;
		} else if (GetConVarInt(c_Delay_Z) < 0 && ZR_IsClientZombie(client)) {
			PrintToChat(client, "[Stuck] This command is disabled for Zombies.");
			return;
		} else {
			g_iStuckCheck[client] = 0;
			StartStuckDetection(client);
		}
	} else {
		g_iStuckCheck[client] = 0;
		StartStuckDetection(client);
	}
}


public Action FDelayTimer(Handle timer, any client)
{
	g_iStuckCheck[client] = 0;
	DelayTimer[client] = null;
	StartStuckDetection(client);
}

stock void StartStuckDetection(int client)
{
	GetClientAbsOrigin(client, g_fOriginalPos[client]); //Save original pos
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", g_fOriginalVel[client]);
	
	//Disable player controls to prevent abuse / exploits
	int flags = GetEntityFlags(client) | FL_ATCONTROLS;
	SetEntityFlags(client, flags);
	
	g_iStuckCheck[client]++;
	CheckIfPlayerCanMove(client, 0, 500.0, 0.0, 0.0);
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//									Ray Trace
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


stock float DistFromWall(int client, float direction[3])
{
	float fDist, vecOrigin[3], vecEnd[3];
	Handle ray;
	
	GetClientAbsOrigin(client, vecOrigin);
	vecOrigin[2] += 25.0; //Dont start from the feet
	ray = TR_TraceRayFilterEx(vecOrigin, direction, MASK_SOLID, RayType_Infinite, TraceEntitiesAndWorld);
	
	if (TR_DidHit(ray)) {
		TR_GetEndPosition(vecEnd, ray);
		fDist = GetVectorDistance(vecOrigin, vecEnd, false);
		delete ray;
		return fDist;
	}
	delete ray;
	return -1.0;
}

public bool TraceEntitiesAndWorld(int entity, int contentsMask)
{
	//Dont care about clients or physics props
	if (entity < 1 || entity > MaxClients) {
		if (IsValidEntity(entity)) {
			char eClass[128];
			if (GetEntityClassname(entity, eClass, sizeof(eClass))) {
				if (StrContains(eClass, "prop_physics") != -1)
					return false;
			}
			return true;
		}
	}
	return false;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//									More Stuck Detection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


stock void CheckIfPlayerCanMove(int client, int testID, float X = 0.0, float Y = 0.0, float Z = 0.0, float Radius = 1.0, float pos_Z = 1.0, float DegreeAngle = 1.0)	// In few case there are issues with IsPlayerStuck() like clip
{
	float vecVelo[3];
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	
	vecVelo[0] = X;
	vecVelo[1] = Y;
	vecVelo[2] = Z;
	
	SetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", vecVelo);
	
	//TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelo);
	
	DataPack TimerDataPack1;
	CreateDataTimer(0.01, TimerWait, TimerDataPack1, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(TimerDataPack1, client);
	WritePackCell(TimerDataPack1, testID);
	WritePackFloat(TimerDataPack1, vecOrigin[0]);
	WritePackFloat(TimerDataPack1, vecOrigin[1]);
	WritePackFloat(TimerDataPack1, vecOrigin[2]);
	WritePackFloat(TimerDataPack1, Radius);
	WritePackFloat(TimerDataPack1, pos_Z);
	WritePackFloat(TimerDataPack1, DegreeAngle);
}

public Action TimerWait(Handle timer, Handle data)
{	
	float vecOrigin[3];
	float vecOriginAfter[3];
	
	ResetPack(data, false);
	int client 			= ReadPackCell(data);
	int testID 			= ReadPackCell(data);
	vecOrigin[0]		= ReadPackFloat(data);
	vecOrigin[1]		= ReadPackFloat(data);
	vecOrigin[2]		= ReadPackFloat(data);
	float Radius		= ReadPackFloat(data);
	float pos_Z			= ReadPackFloat(data);
	float DegreeAngle	= ReadPackFloat(data);
	
	
	GetClientAbsOrigin(client, vecOriginAfter);
	
	if(GetVectorDistance(vecOrigin, vecOriginAfter, false) < 8.0) // Can't move
	{
		if(testID == 0) {
			CheckIfPlayerCanMove(client, 1, 0.0, 0.0, -500.0, Radius, pos_Z, DegreeAngle);	// Jump
		} else if(testID == 1) {
			CheckIfPlayerCanMove(client, 2, -500.0, 0.0, 0.0, Radius, pos_Z, DegreeAngle);
		} else if(testID == 2) {
			CheckIfPlayerCanMove(client, 3, 0.0, 500.0, 0.0, Radius, pos_Z, DegreeAngle);
		} else if(testID == 3) {
			CheckIfPlayerCanMove(client, 4, 0.0, -500.0, 0.0, Radius, pos_Z, DegreeAngle);
		} else if(testID == 4) {
			CheckIfPlayerCanMove(client, 5, 0.0, 0.0, 300.0, Radius, pos_Z, DegreeAngle);
		} else {
			if (Radius == 1.0 && pos_Z == 1.0 && DegreeAngle == 1.0) {
				g_iStuckCheck[client]++;
				TryFixPosition(client, g_fHorizontalStep, 0.0, -180.0); //First time settings
				return;
			} else {
				g_iStuckCheck[client]++;
				TryFixPosition(client, Radius, pos_Z, DegreeAngle); //Continue where we left off
				return;
			}
		}
	} else {
		if(g_iStuckCheck[client] < 2 && g_iStuckCheck[client] != -1) {
			PrintToChat(client, "[Stuck] You do not appear to be stuck.");
			TeleportEntity(client, g_fOriginalPos[client], NULL_VECTOR, g_fOriginalVel[client]); //Reset to original pos / velocity
			//Enable controls
			int flags = GetEntityFlags(client) & ~FL_ATCONTROLS;
			SetEntityFlags(client, flags);
			g_iStuckCheck[client] = -1;
		} else {
			PrintToChat(client, "[Stuck] Your position has been fixed, you should now be unstuck.");
			//Enable controls
			int flags = GetEntityFlags(client) & ~FL_ATCONTROLS;
			SetEntityFlags(client, flags);
			g_iStuckCheck[client] = -1;
		}
	}
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//									Fix Position
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


public Action CheckWait(Handle timer, Handle data)
{	
	ResetPack(data, false);
	int client 		= ReadPackCell(data);
	float Radius		= ReadPackFloat(data);
	float pos_Z			= ReadPackFloat(data);
	float DegreeAngle	= ReadPackFloat(data);

	DelayTimer[client] = null;
	TryFixPosition(client, Radius, pos_Z, DegreeAngle);
}

stock void TryFixPosition(int client, float Radius, float pos_Z, float DegreeAngle)
{
	float vecPosition[3];
	float vecOrigin[3];
	float vecAngle[3];
	
	if (g_iStuckCheck[client] == -1) {
		PrintToChat(client,"[Stuck] Something went wrong, if you are still stuck try /stuck again or call an admin.");
		if (DelayTimer[client] != null)
		{
			KillTimer(DelayTimer[client]);
			DelayTimer[client] = null;
		}
		return;
	}
	
	//g_fMaxRadius[client] = 30
		
	if (pos_Z <= g_fVerticalRadius)
	{
		if (Radius <= g_fHorizontalRadius)
		{
			GetClientAbsOrigin(client, vecOrigin);
			//GetClientEyeAngles(client, vecAngle);
			vecPosition[2] = vecOrigin[2] + pos_Z;
		
			//DegreeAngle = -180.0;
			if (DegreeAngle < 180.0)
			{
				vecPosition[0] = vecOrigin[0] + Radius * Cosine(DegreeAngle * FLOAT_PI / 180); // convert angle in radian
				vecPosition[1] = vecOrigin[1] + Radius * Sine(DegreeAngle * FLOAT_PI / 180);
				
				SubtractVectors(vecPosition, vecOrigin, vecAngle);
				
				//Get the distance to the warp location
				vecOrigin[2] += 25.0; //Match the raytrace
				float potentialDist = GetVectorDistance(vecPosition, vecOrigin, false);
				potentialDist += 10.0;
				DegreeAngle += 60.0; // start off next time +10
				
				//Allow only if player is already in wall, or if the wall is beyond the warp location
				float fDist = DistFromWall(client, vecAngle);
				if (fDist > 16.0 && fDist <= potentialDist) {
					DataPack TimerDataPack2;
					DelayTimer[client] = CreateDataTimer(0.0, CheckWait, TimerDataPack2, TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(TimerDataPack2, client);
					WritePackFloat(TimerDataPack2, Radius);
					WritePackFloat(TimerDataPack2, pos_Z);
					WritePackFloat(TimerDataPack2, DegreeAngle);
					return;
				}
				
				//Debug
				//PrintToChat(client, "[Stuck] Debug, Radius %f, pos Z %f, Angle %f", Radius, pos_Z, DegreeAngle);
				TeleportEntity(client, vecPosition, NULL_VECTOR, view_as<float>({0.0, 0.0, -300.0}));
				CheckIfPlayerCanMove(client, 0, 500.0, 0.0, 0.0, Radius, pos_Z, DegreeAngle);
				return;
			}
							
			//					TeleportEntity(client, vecOrigin, vecAngle, fGroundVelocity);
			DegreeAngle = -180.0; //Restart the degree loop
			Radius += g_fHorizontalStep; //Increase the radius
			if (DelayTimer[client] != null)
			{
				KillTimer(DelayTimer[client]);
				DelayTimer[client] = null;
			}
			DataPack TimerDataPack2;
			DelayTimer[client] = CreateDataTimer(GetRandomFloat(0.0, 0.5), CheckWait, TimerDataPack2, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(TimerDataPack2, client);
			WritePackFloat(TimerDataPack2, Radius);
			WritePackFloat(TimerDataPack2, pos_Z);
			WritePackFloat(TimerDataPack2, DegreeAngle);
			return;
		}
		
		if (pos_Z == 0.0) {
			//No point in flipping the first time
			pos_Z += g_fVerticalStep;
		} else {
			if (pos_Z < 0.0) {
				//Negative, flip back to positive and increase
				pos_Z = FloatAbs(pos_Z);
				pos_Z += g_fVerticalStep;
			} else if (pos_Z > 0.0) {
				//Positive, flip to negative and try again
				pos_Z *= -1.0;
			}	
		}
		
			
		Radius = g_fHorizontalStep; //Restart the radius loop
		DegreeAngle = -180.0; //Restart the degree loop
		if (DelayTimer[client] != null)
		{
			KillTimer(DelayTimer[client]);
			DelayTimer[client] = null;
		}
		DataPack TimerDataPack2;
		DelayTimer[client] = CreateDataTimer(GetRandomFloat(0.0, 2.0), CheckWait, TimerDataPack2, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(TimerDataPack2, client);
		WritePackFloat(TimerDataPack2, Radius);
		WritePackFloat(TimerDataPack2, pos_Z);
		WritePackFloat(TimerDataPack2, DegreeAngle);
		return;
	}

	//Probably safe to say you are stuck now
	PrintToChat(client,"[Stuck] Unable to fix your position, please call for admin assistance.");
	TeleportEntity(client, g_fOriginalPos[client], NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0})); //Reset position to wherever they used the command
	//Enable controls
	int flags = GetEntityFlags(client) & ~FL_ATCONTROLS;
	SetEntityFlags(client, flags);
	g_iStuckCheck[client] = -1;
}