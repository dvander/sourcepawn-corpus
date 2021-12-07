#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "LaFF"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};
//DAMAGE
ConVar GAMESETpercentt; //t
ConVar GAMESETpercenttvip; //tvip
ConVar GAMESETpercentct; //ct
ConVar GAMESETpercentctvip; //ctvip
//DAMAGE

//speed
ConVar GAMESETtvipspeed; //tvip
ConVar GAMESETtspeed; //t
ConVar GAMESETctvipspeed; // ct vip
ConVar GAMESETctspeed; //ct 
//speed

//hp and armor
ConVar GAMESETthpstart; //t
ConVar GAMESETtviphpstart; //t vip
ConVar GAMESETcthpstart; //ct
ConVar GAMESETctviphpstart; //ct vip

ConVar GAMESETtarstart; //t
ConVar GAMESETtviparstart; //t vip
ConVar GAMESETctarstart; //ct
ConVar GAMESETctviparstart; //ct vip
//hp and armor
//// grav
ConVar GAMESETtgrstart;
ConVar GAMESETtvipgrstart;
ConVar GAMESETctgrstart;
ConVar GAMESETctvipgrstart;
///grav
public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	
	GAMESETpercentt = CreateConVar("gs_d_t", "1", "boost damage of T by x%");
	GAMESETpercenttvip = CreateConVar("gs_d_t_vip", "1", "boost damage of T by x%ˇnote that VIP dmg is other than T dmg so it doesnt stack");
	GAMESETpercentct = CreateConVar("gs_d_ct", "1", "boost damage of CT by x%");
	GAMESETpercentctvip = CreateConVar("gs_d_ct_vip", "1", "boost damage of T by x%ˇnote that VIP dmg is other than CT dmg so it doesnt stack");
	
	
	GAMESETtvipspeed = CreateConVar("gs_s_t_vip", "1.0", "speed of vip T");
	GAMESETtspeed = CreateConVar("gs_s_t", "1.0", "speed of t");
	GAMESETctvipspeed = CreateConVar("gs_s_ct_vip", "1.0", "speed of ct vip");
	GAMESETctspeed = CreateConVar("gs_s_ct", "1.0", "speed of ct");
	
	GAMESETthpstart = CreateConVar("gs_hp_t_vip", "100", "Starting HP of T normal player");
	GAMESETtviphpstart = CreateConVar("gs_hp_t", "100", "Starting HP of T vip player");
	GAMESETcthpstart = CreateConVar("gs_hp_ct_vip", "100", "Starting hp of CT normal player");
	GAMESETctviphpstart = CreateConVar("gs_hp_ct", "100", "Starting hp of CT vip player");
	
	
	GAMESETtarstart = CreateConVar("gs_ar_t_vip", "100", "Starting armor of T normal player");
	GAMESETtviparstart = CreateConVar("gs_ar_t", "100", "Starting armor of T vip player");
	GAMESETctarstart = CreateConVar("gs_ar_ct_vip", "100", "Starting armor of CT normal player");
	GAMESETctviparstart = CreateConVar("gs_ar_ct", "100", "Starting armor of CT vip player");
	
	GAMESETtgrstart = CreateConVar("gs_gr_t_vip", "1.0", "Gravity of T normal player");
	GAMESETtvipgrstart = CreateConVar("gs_gr_t", "1.0", "Gravity of T vip player");
	GAMESETctgrstart = CreateConVar("gs_gr_ct_vip", "1.0", "Gravity of CT normal player");
	GAMESETctvipgrstart = CreateConVar("gs_gr_ct", "1.0", "Gravity of CT vip player");
	
	
	AutoExecConfig(true, "GameSettings");
}
public void OnClientPutInServer(int client)
{
	if (IsValidClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDmg);
	}
	
}
/////////////// damage
public Action OnTakeDmg(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (IsValidClient(attacker))
	{
		float OnePercent = damage / 100;
		if (GetClientTeam(attacker) == CS_TEAM_T) //team T
		{
			if (IsVIP(attacker))
			{
				damage = OnePercent * GAMESETpercenttvip.FloatValue + damage; //VIP T
				return Plugin_Changed;
			}
		}
		else if (!IsVIP(attacker))
		{
			damage = OnePercent * GAMESETpercentt.FloatValue + damage; // T
			return Plugin_Changed;
		}
		
		//team T
		if (GetClientTeam(attacker) == CS_TEAM_CT) //team CT
		{
			if (IsVIP(attacker))
			{
				damage = OnePercent * GAMESETpercentctvip.FloatValue + damage; //VIP CT
				return Plugin_Changed;
			}
			else if (!IsVIP(attacker))
			{
				damage = OnePercent * GAMESETpercentct.FloatValue + damage; // CT
				return Plugin_Changed;
			}
			
		} //team CT
		
		return Plugin_Changed;
		
	}
	return Plugin_Handled;
}

///////////damage

//////////speed and gravity (hp + armor)
public Action OnRoundStart(Event event, const char[] name, bool dbc)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (GetClientTeam(i) == CS_TEAM_T) //team T
			{
				if (IsVIP(i))
				{
					SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", GAMESETtvipspeed.FloatValue); //vip speed for t
					SetEntityHealth(i, GAMESETtviphpstart.IntValue); //HP vip
					SetEntProp(i, Prop_Send, "m_ArmorValue", GAMESETtviparstart.IntValue, 1); //ar vip
					SetEntityGravity(i, GAMESETtvipgrstart.FloatValue);
				}
				else
				{
					SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", GAMESETtspeed.FloatValue); // T speed
					SetEntityHealth(i, GAMESETthpstart.IntValue); //HP normal
					SetEntProp(i, Prop_Send, "m_ArmorValue", GAMESETtarstart.IntValue, 1); //ar normal
					SetEntityGravity(i, GAMESETtgrstart.FloatValue);
				}
			}
			else if (GetClientTeam(i) == CS_TEAM_CT) //team CT
			{
				if (IsVIP(i))
				{
					SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", GAMESETctvipspeed.FloatValue); //vip speed for Ct
					SetEntityHealth(i, GAMESETctviphpstart.IntValue); //HP VIP
					SetEntProp(i, Prop_Send, "m_ArmorValue", GAMESETctviparstart.IntValue, 1); //ct ar vip
					SetEntityGravity(i, GAMESETctvipgrstart.FloatValue);
				}
				else
				{
					SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", GAMESETctspeed.FloatValue); // CT speed
					SetEntityHealth(i, GAMESETcthpstart.IntValue); //HP normal
					SetEntProp(i, Prop_Send, "m_ArmorValue", GAMESETctarstart.IntValue, 1);
					SetEntityGravity(i, GAMESETctgrstart.FloatValue);
				}
			}
		}
	}
}
//////////speed and gravity
stock bool IsValidClient(int client)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client))
	{
		return true;
	}
	
	return false;
}
stock bool IsVIP(int client)
{
	return CheckCommandAccess(client, "", ADMFLAG_RESERVATION, true);
} 