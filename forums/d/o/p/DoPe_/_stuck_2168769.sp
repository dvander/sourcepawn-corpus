#pragma semicolon 1

#include <sourcemod>
#include <sdktools>


#define PLUGIN_NAME		 	"Stuck"
#define PLUGIN_AUTHOR	   	"Erreur 500"
#define PLUGIN_DESCRIPTION	"Fix player stuck position"
#define PLUGIN_VERSION	  	"1.0"
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
	c_Limit		= CreateConVar("stuck_limit", 	"7", "How many !stuck can a player use ? (0 = no limit)", FCVAR_PLUGIN, true, 0.0);
	c_Countdown	= CreateConVar("stuck_wait", 	"300", "Time to wait before earn new !stuck.", FCVAR_PLUGIN, true, 0.0);
	c_Radius	= CreateConVar("stuck_radius", 	"200", "Radius size to fix player position.", FCVAR_PLUGIN, true, 10.0);
	c_Step		= CreateConVar("stuck_step", 	"20", "Step between each position tested.", FCVAR_PLUGIN, true, 1.0);
	
	AutoExecConfig(true, "!stuck");
	
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
	
	RegConsoleCmd("sm_stuck", StuckCmd, "Unstuck player on use");
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
	if(iClient <= 0) return;
	
	if(!IsPlayerAlive(iClient))
		PrintToChat(iClient, "[!stuck] How a death can be stuck !?");
	else if(IsPlayerStuck(iClient))
	{
		if(GetConVarInt(c_Limit) > 0 && Counter[iClient] >= GetConVarInt(c_Limit))
			PrintToChat(iClient, "[!stuck] Sorry, you must wait %i seconds before use this command again.", TimeLimit - Countdown[iClient]);
		else
			IsPlayerReallyStuck(iClient, 0, 500.0, 0.0, 0.0);
	}
	else
		PrintToChat(iClient, "[!stuck] Well Tried, but you are not stuck!");
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//									Stuck Detection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


stock bool:IsPlayerStuck(iClient)
{
	decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];

	GetClientMins(iClient, vecMin);
	GetClientMaxs(iClient, vecMax);
	GetClientAbsOrigin(iClient, vecOrigin);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceEntityFilterEntities, iClient);
	if(!TR_DidHit())	// Foot in wall ?
	{
		GetClientEyePosition(iClient, vecOrigin);
		TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceEntityFilterEntities, iClient);
		return TR_DidHit();	// head in wall ?
	}
	
	return true;
}

public bool:TraceEntityFilterEntities(entity, contentsMask, any:data) 
{
	return entity > 1;
}


stock IsPlayerReallyStuck(iClient, testID, Float:X=0.0, Float:Y=0.0, Float:Z=0.0)	// In few case there are issues with IsPlayerStuck()
{
	decl Float:vecVelo[3];
	decl Float:vecOrigin[3];
	GetClientAbsOrigin(iClient, vecOrigin);
	
	vecVelo[0] = X;
	vecVelo[1] = Y;
	vecVelo[2] = Z;
	
	SetEntPropVector(iClient, Prop_Data, "m_vecBaseVelocity", vecVelo);
	
	new Handle:DataPack;
	CreateDataTimer(0.1, TimerWait, DataPack); 
	WritePackCell(DataPack, iClient);
	WritePackCell(DataPack, testID);
	WritePackFloat(DataPack, vecOrigin[0]);
	WritePackFloat(DataPack, vecOrigin[1]);
	WritePackFloat(DataPack, vecOrigin[2]);
}

public Action:TimerWait(Handle:timer, Handle:data)
{	
	decl Float:vecOrigin[3];
	decl Float:vecOriginAfter[3];
	
	ResetPack(data, false);
	new iClient 	= ReadPackCell(data);
	new testID 		= ReadPackCell(data);
	vecOrigin[0]	= ReadPackFloat(data);
	vecOrigin[1]	= ReadPackFloat(data);
	vecOrigin[2]	= ReadPackFloat(data);
	
	
	GetClientAbsOrigin(iClient, vecOriginAfter);
	
	if(GetVectorDistance(vecOrigin, vecOriginAfter, false) < 10.0)
	{
		if(testID == 0)
			IsPlayerReallyStuck(iClient, 1, 0.0, 0.0, -500.0);	// Jump
		else if(testID == 1)
			IsPlayerReallyStuck(iClient, 2, -500.0, 0.0, 0.0);
		else if(testID == 2)
			IsPlayerReallyStuck(iClient, 3, 0.0, 500.0, 0.0);
		else if(testID == 3)
			IsPlayerReallyStuck(iClient, 4, 0.0, -500.0, 0.0);
		else if(testID == 4)
			IsPlayerReallyStuck(iClient, 5, 0.0, 0.0, 300.0);
		else if(FixPlayerPosition(iClient))
			PrintToChat(iClient, "[!stuck] Done!");
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
	
	if(IsPlayerStuck(iClient))
	{
		PrintToChat(iClient,"[!stuck] Sorry, I'm not able to fix your position.");
		return false;
	}
	else
	{
		Counter[iClient]++;
		return true;
	}
}

bool:TryFixPosition(iClient, Float:Radius, Float:pos_Z)
{
	new Float:pixels = FLOAT_PI*2*Radius;
	new Float:compteur = 0.0;
	decl Float:vecPosition[3];
	decl Float:vecOrigin[3];
	decl Float:vecAngle[3];
	new coups = 0;

	GetClientAbsOrigin(iClient, vecOrigin);
	GetClientEyeAngles(iClient, vecAngle);
	vecPosition[2] = vecOrigin[2] + pos_Z;

	while (coups < pixels)
	{
		vecPosition[0] = vecOrigin[0]  + Radius * Cosine(compteur * FLOAT_PI / 180);
		vecPosition[1] = vecOrigin[1]  + Radius * Sine(compteur * FLOAT_PI / 180);

		TeleportEntity(iClient, vecPosition, vecAngle, NULL_VECTOR);
		if(!IsPlayerStuck(iClient))
			return true;
		
		compteur += 360/pixels;
		coups++;
	}
	
	TeleportEntity(iClient, vecOrigin, vecAngle, NULL_VECTOR);
	if(Radius <= RadiusSize)
		return TryFixPosition(iClient, Radius + Step, pos_Z);
	
	return false;
}

