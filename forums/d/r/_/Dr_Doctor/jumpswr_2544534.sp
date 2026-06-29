#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Battlefield Duck"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[TF2] Jump server Weapon restriction",
	author = PLUGIN_AUTHOR,
	description = "Weapon restriction For Jump server",
	version = PLUGIN_VERSION,
	url = ""
};
//handle
Handle g_cvenabled;
Handle g_cvremoveparachute;
Handle g_cvremovedemoshield;

/****************
	Start
****************/
public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	CreateConVar("jumpswr_version", PLUGIN_VERSION, "Jumpswr version", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_cvenabled = CreateConVar("sm_jumpswr_enable", "1", "Enable jumpswr plugin?");
	g_cvremoveparachute = CreateConVar("sm_jumpswr_removeparachute", "1", "Remove Parachute(The B.A.S.E. Jumper)");
	g_cvremovedemoshield = CreateConVar("sm_jumpswr_removedemoshield", "1", "Block Demo shield");
}
public Action Event_PlayerSpawn(Handle hEvent, const char[] strName, bool bDontBroadcast) 
{
	CreateTimer(0.1, RestrictionCheck);
}
//On Player Spawn
public Action RestrictionCheck(Handle timer)
{
	if(g_cvenabled)
	{
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (IsValidClient(iClient)) {
				for(int iSlot = 0; iSlot < 8; iSlot++)
				{ 
        			int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
        			if(IsValidEntity(iWeapon))
       				{
       					int Weaponindex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
       					//Remove "The B.A.S.E. Jumper"
       					if(GetConVarBool(g_cvremoveparachute))
      					{
        					if(Weaponindex == 1101) // 1101 = "The B.A.S.E. Jumper" Weapon Index
							{     		
        						RemovePlayerItem(iClient, iWeapon);
        						RemoveEdict(iWeapon);
        					}
        				}
        				//Block "Demo Shield"
       					if(GetConVarBool(g_cvremovedemoshield)) SetEntPropFloat(iClient, Prop_Send, "m_flChargeMeter", 0.0);
        			}
        		}
       		}
		}
	}
	if(g_cvenabled) CreateTimer(0.1, RestrictionCheck);
}


/*******************
Vaild Client?
*******************/
stock bool IsValidClient(int client) 
{ 
    if(client <= 0 ) return false; 
    if(client > MaxClients) return false; 
    if(!IsClientConnected(client)) return false; 
    return IsClientInGame(client); 
}