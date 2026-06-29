#include <sourcemod>
//#include <sdktools>
//#include <sdkhooks>
#include <left4dhooks>
#pragma newdecls required

#define PLUGIN_VERSION "1.0.1"

#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

Handle l4d_tank_50cal_enable;
int g_iTankClass;

public Plugin myinfo = 
{
	name = "Tank targets 50cal's users",
	author = "Axel Juan Nieves",
	description = "Tanks will target survivors using a mounted machine gun.",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion test = GetEngineVersion();

    if ( test == Engine_Left4Dead ) g_iTankClass = (1<<5)|(1<<6);
    else if( test == Engine_Left4Dead2 ) g_iTankClass = (1<<8);
    else
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_tank_50cal_ver", PLUGIN_VERSION, "", 0);
	l4d_tank_50cal_enable = CreateConVar("l4d_tank_50cal_enable", "1", "Enable/Disable this plugin", 0);

	AutoExecConfig(true, "l4d_tank_50cal");
}

public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{	
	if ( !GetConVarBool(l4d_tank_50cal_enable) )
		return Plugin_Continue;
	if ( !IsPlayerTank2(specialInfected) )
		return Plugin_Continue;
	if ( !IsValidClientAlive(curTarget) )
		return Plugin_Continue;
	
	int entity = INVALID_ENT_REFERENCE;
	int iClosestSurvivor;
	char classname[32];
	
	//look for the closest survivor using a 50cal...
	for (int i=1; i<=MAXPLAYERS; i++)
	{
		if ( !IsValidClientInGame(i) ) continue;
		if ( GetClientTeam(i)!=TEAM_SURVIVOR ) continue;
		if ( !IsPlayerAlive(i) ) continue;
		
		entity = GetEntPropEnt(i, Prop_Send, "m_hUseEntity");
		if ( !IsValidEntity(entity) )
			continue;
		
		//GetEntPropString(entity, Prop_Data, "m_iName", classname, sizeof(classname));
		if ( !IsValidEdict(entity) )
			continue;
		
		GetEdictClassname(entity, classname, sizeof(classname));
		if ( strcmp(classname, "prop_mounted_machine_gun")!=0 )
			continue;
		
		//PrintToChatAll("%N is using %s", i, classname);
		//PrintToServer("%N is using %s", i, classname);
			
		//set new target first time...
		if ( iClosestSurvivor==0 )
			iClosestSurvivor = i;
		
		//check for a closest new target...
		if ( ClientsDistance(specialInfected, i) < ClientsDistance(specialInfected, iClosestSurvivor) )
			iClosestSurvivor = i;
	}
	
	//let's ensure everything above was right...
	if ( !IsValidClientAlive(iClosestSurvivor) )
		return Plugin_Continue;
	
	curTarget = iClosestSurvivor;
	return Plugin_Changed;
}

stock float ClientsDistance(int client1, int client2)
{
	if ( !IsValidClientAlive(client1) )
		return -1.0
	if ( !IsValidClientAlive(client2) )
		return -1.0
	
	float fPos1[3], fPos2[3];
	GetClientAbsOrigin(client1, fPos1);
	GetClientAbsOrigin(client2, fPos2);
	
	return GetVectorDistance(fPos1, fPos2);
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}

stock bool IsValidClientAlive(int client)
{
	if ( !IsValidClientInGame(client) )
		return false;
	
	if ( !IsPlayerAlive(client) )
		return false;
	
	return true;
}

stock int IsPlayerTank2(int client)
{
	if ( (1<<GetEntProp(client, Prop_Send, "m_zombieClass")) & g_iTankClass )
		return 1;
	
	return 0;
}