#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <stuck>


#define PLUGIN_NAME		 	"stuck"
#define PLUGIN_AUTHOR	   	"Erreur 500 && El Diablo"
#define PLUGIN_DESCRIPTION	"Fix stuck players"
#define PLUGIN_VERSION	  	"1.3"
#define PLUGIN_CONTACT	  	"erreur500@hotmail.fr"

new TimeLimit;
new Counter[MAXPLAYERS+1] 	= {0, ...};
new Countdown[MAXPLAYERS+1] = {0, ...};

new Float:Step;
new Float:RadiusSize;

new Handle:c_Limit			= INVALID_HANDLE;
new Handle:c_Countdown 		= INVALID_HANDLE;
new Handle:c_Radius			= INVALID_HANDLE;
new Handle:c_Step 			= INVALID_HANDLE;


public Plugin:myinfo =
{
	name		= PLUGIN_NAME,
	author	  	= PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version	 	= PLUGIN_VERSION,
	url		 	= PLUGIN_CONTACT
};


public OnPluginStart()
{
	CreateConVar("stuck_version", PLUGIN_VERSION, "Stuck version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_Limit		= CreateConVar("stuck_limit", 				"1", 	"How many !stuck can a player use ? (0 = no limit)", FCVAR_PLUGIN, true, 0.0);
	c_Countdown	= CreateConVar("stuck_wait", 				"60", 	"Time to wait before earn new !stuck.", FCVAR_PLUGIN, true, 0.0);
	c_Radius	= CreateConVar("stuck_radius", 				"200", 	"Radius size to fix player position.", FCVAR_PLUGIN, true, 10.0);
	c_Step		= CreateConVar("stuck_step", 				"20", 	"Step between each position tested.", FCVAR_PLUGIN, true, 1.0);

	//AutoExecConfig(true, "stuck"); // remove old variables as they can cause issues.

	HookConVarChange(c_Countdown, CallBackCVarCountdown);
	HookConVarChange(c_Radius, CallBackCVarRadius);
	HookConVarChange(c_Step, CallBackCVarStep);

	TimeLimit = GetConVarInt(c_Countdown);
	if(TimeLimit < 0)
		TimeLimit = -TimeLimit;

	RadiusSize = GetConVarInt(c_Radius) * 1.0;
	if(RadiusSize < 10.0)
		RadiusSize = 10.0;

	Step = GetConVarInt(c_Step) * 1.0;
	if(Step < 1.0)
		Step = 1.0;

	RegConsoleCmd("stuck", StuckCmd, "Are you stuck ?");

	CreateTimer(1.0, Timer, INVALID_HANDLE, TIMER_REPEAT);
}

public OnMapStart()
{
	for(new i=0; i<MaxClients; i++)
		Counter[i] = 0;
}

public CallBackCVarCountdown(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TimeLimit = StringToInt(newVal);
	if(TimeLimit < 0)
		TimeLimit = -TimeLimit;

	LogMessage("stuck_wait = %i", TimeLimit);
}

public CallBackCVarRadius(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RadiusSize = StringToInt(newVal) * 1.0;
	if(RadiusSize < 10.0)
		RadiusSize = 10.0;

	LogMessage("stuck_radius = %f", RadiusSize);
}

public CallBackCVarStep(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Step = StringToInt(newVal) * 1.0;
	if(Step < 1.0)
		Step = 1.0;

	LogMessage("stuck_step = %f", Step);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("IsPlayerStuck", Native_IsPlayerStuck);
	CreateNative("UnStuckPlayer", Native_UnStuckPlayer);

	return APLRes_Success;
}

public Action:Timer(Handle:timer)
{
	for(new i=0; i<MaxClients; i++)
	{
		if(Counter[i] > 0)
		{
			Countdown[i]++;
			if(Countdown[i] >= TimeLimit)
			{
				Countdown[i] = 0;
				Counter[i]--;
			}
		}
		else if(Counter[i] == 0 && Countdown[i] != 0)
			Countdown[i] = 0;
	}
}

public Action:StuckCmd(iClient, Args)
{
	if(iClient>0 && iClient<=MaxClients)
	{
		//if(iClient <= 0) return;

		//if(!IsPlayerAlive(iClient))
			//PrintToChat(iClient, "[!stuck] How a death can be stuck !?");
		int cLimitc = GetConVarInt(c_Limit);
		if(cLimitc > 0 && Counter[iClient] >= cLimitc)
		{
			if(IsClientConnected(iClient) && IsClientInGame(iClient))
			{
				PrintToChat(iClient, "[!stuck] Sorry, you must wait %i seconds before use this command again.", TimeLimit - Countdown[iClient]);
			}
			return Plugin_Handled;
		}

		++Counter[iClient];

		if(IsClientConnected(iClient) && IsClientInGame(iClient))
		{
			if(CheckIfPlayerIsStuck(iClient))
			{
				CheckIfPlayerIsReallyStuck(iClient, 0, 500.0, 0.0, 0.0);
			}
			else
			{
				PrintToChat(iClient, "[!stuck] Well Tried, but you are not stuck!");
			}
		}
	}
	return Plugin_Handled;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//									Stuck Detection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


stock bool:CheckIfPlayerIsStuck(iClient)
{
	decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];

	GetClientMins(iClient, vecMin);
	GetClientMaxs(iClient, vecMax);
	GetClientAbsOrigin(iClient, vecOrigin);

	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceEntityFilterSolid);
	return TR_DidHit();	// head in wall ?
}


public bool:TraceEntityFilterSolid(entity, contentsMask)
{
	return entity > 1;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//									More Stuck Detection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


stock CheckIfPlayerIsReallyStuck(iClient, testID, Float:X=0.0, Float:Y=0.0, Float:Z=0.0)	// In few case there are issues with IsPlayerStuck()
{
	decl Float:vecVelo[3];
	decl Float:vecOrigin[3];
	GetClientAbsOrigin(iClient, vecOrigin);

	vecVelo[0] = X;
	vecVelo[1] = Y;
	vecVelo[2] = Z;

	SetEntPropVector(iClient, Prop_Data, "m_vecBaseVelocity", vecVelo);

	new Handle:DataPack2;
	CreateDataTimer(0.1, TimerWait, DataPack2);
	WritePackCell(DataPack2, iClient);
	WritePackCell(DataPack2, testID);
	WritePackFloat(DataPack2, vecOrigin[0]);
	WritePackFloat(DataPack2, vecOrigin[1]);
	WritePackFloat(DataPack2, vecOrigin[2]);
}

public Action:TimerWait(Handle:timer, Handle:data)
{
	decl Float:vecOrigin[3];
	decl Float:vecOriginAfter[3];

	ResetPack(data, false);
	new iClient 		= ReadPackCell(data);
	new testID 			= ReadPackCell(data);
	vecOrigin[0]		= ReadPackFloat(data);
	vecOrigin[1]		= ReadPackFloat(data);
	vecOrigin[2]		= ReadPackFloat(data);


	GetClientAbsOrigin(iClient, vecOriginAfter);

	if(GetVectorDistance(vecOrigin, vecOriginAfter, false) < 10.0)
	{
		if(testID == 0)
			CheckIfPlayerIsReallyStuck(iClient, 1, 0.0, 0.0, -500.0);	// Jump
		else if(testID == 1)
			CheckIfPlayerIsReallyStuck(iClient, 2, -500.0, 0.0, 0.0);
		else if(testID == 2)
			CheckIfPlayerIsReallyStuck(iClient, 3, 0.0, 500.0, 0.0);
		else if(testID == 3)
			CheckIfPlayerIsReallyStuck(iClient, 4, 0.0, -500.0, 0.0);
		else if(testID == 4)
			CheckIfPlayerIsReallyStuck(iClient, 5, 0.0, 0.0, 300.0);
		else if(!FixPlayerPosition(iClient))
			PrintToChat(iClient,"[!stuck] Sorry, I'm not able to fix your position.");
		else
		{
			//Counter[iClient]++;
			PrintToChat(iClient, "[!stuck] Done!");
		}
	}
	else
		PrintToChat(iClient, "[!stuck] Well Tried, but you are not stuck!");
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//									Fix Position
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


bool:FixPlayerPosition(iClient)
{
	new Float:pos_Z = 0.1;

	while(pos_Z <= RadiusSize && !TryFixPosition(iClient, 10.0, pos_Z))
	{
		pos_Z = -pos_Z;
		if(pos_Z > 0.0)
			pos_Z += Step;
	}

	return !CheckIfPlayerIsStuck(iClient);
}

bool:TryFixPosition(iClient, Float:Radius, Float:pos_Z)
{
	new Float:pixels = FLOAT_PI*2*Radius;
	decl Float:compteur;
	decl Float:vecPosition[3];
	decl Float:vecOrigin[3];
	decl Float:vecAngle[3];
	new coups = 0;

	GetClientAbsOrigin(iClient, vecOrigin);
	GetClientEyeAngles(iClient, vecAngle);
	vecPosition[2] = vecOrigin[2] + pos_Z;

	while(coups < pixels)
	{
		vecPosition[0] = vecOrigin[0] + Radius * Cosine(compteur * FLOAT_PI / 180);
		vecPosition[1] = vecOrigin[1] + Radius * Sine(compteur * FLOAT_PI / 180);

		TeleportEntity(iClient, vecPosition, vecAngle, NULL_VECTOR);
		if(!CheckIfPlayerIsStuck(iClient))
			return true;

		compteur += 360/pixels;
		coups++;
	}

	TeleportEntity(iClient, vecOrigin, vecAngle, NULL_VECTOR);
	if(Radius <= RadiusSize)
		return TryFixPosition(iClient, Radius + Step, pos_Z);

	return false;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//									Stuck Detection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


public Native_IsPlayerStuck(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	if(iClient <= 0 || iClient >= MaxClients) return false;
	if(!IsPlayerAlive(iClient)) return false;
	return CheckIfPlayerIsStuck(iClient);
}

public Native_UnStuckPlayer(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	if(iClient <= 0 || iClient >= MaxClients) return false;
	if(!IsPlayerAlive(iClient)) return false;

	if(CheckIfPlayerIsStuck(iClient))
		return FixPlayerPosition(iClient);
	else
		return false;
}


