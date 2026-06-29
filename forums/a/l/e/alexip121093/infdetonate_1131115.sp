#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "0.1"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define DMG_GENERIC	0
#define TEAM_INFECTED 3
new propinfoghost;

DealDamage(victim,damage,attacker=0,dmg_type=DMG_GENERIC,String:weapon[]="")
{
	if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
	{
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(victim,"targetname","war3_hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(victim,"targetname","war3_donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}

// Plugin info
public Plugin:myinfo =
{
	name = "Infected Self Detonation",
	author = "ne0cha0s",
	description = "Allows an infected player to detonate themselves by pressing the reload button (currently supports boomer, spitter, smoker.)",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1131068"
};
// Plugin start
public OnPluginStart()
{
	// Requires that plugin will only work on Left 4 Dead or Left 4 Dead 2
    decl String:game_name[64];
    GetGameFolderName(game_name, sizeof(game_name));
    if (!StrEqual(game_name, "left4dead", false) 
      && !StrEqual(game_name, "left4dead2", false))
    {
        SetFailState("This plugin will only work on Left 4 Dead or Left 4 Dead 2.");
    }
	CreateConVar("l4d_infected_self_detonate_version", PLUGIN_VERSION, " Infected Self Detonate Version ", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	//AutoExecConfig(false, "l4d_infected_self_detonate");  //you have no cvar no need this
}
public Action:OnPlayerRunCmd(client, &buttons)
{
     // Check to see if player is human (end action if not)
    if (IsFakeClient(client)) return;    

     // Check to see if player is in game (end action if not)
    if (!IsClientInGame(client)) return;    
    
     // Check to see if player is on infected team (end action if not)
    if (GetClientTeam(client) != TEAM_INFECTED) return;
      
if (!IsPlayerAlive(client)) return;
 
if(IsPlayerSpawnGhost(client)) return;
    // Check to see if player is smoker, boomer, or spitter (class = 1, 2, 4) (end action if not)
    if (GetEntProp(client, Prop_Send, "m_zombieClass") != 4 && GetEntProp(client, Prop_Send, "m_zombieClass") != 1 && GetEntProp(client, Prop_Send, "m_zombieClass") != 2) return;
    // Check to see if reload button is being pressed (end action if not)
    if  (!(buttons & IN_RELOAD)) return;
    
    // Kill Infected
    DealDamage(client,1000,client,DMG_GENERIC,"");
} 


bool:IsPlayerSpawnGhost(client)
{
 if(GetEntData(client, propinfoghost, 1)) return true;
 else return false;
}
