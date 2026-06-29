//UPDATE INFO
//2.0 - MADE SURE TO SAVE ALL VICTIMS HEALTH WHEN A ROCKET IS USED, OR A GRENADE. ONLY ATTACKER WILL BE PENALISED.
//3.0 - Added a Cvar to control the percentage of the damage reflected onto the attacker.

#pragma semicolon 1 

#include <sourcemod>
#include <sdkhooks>
#include <sdktools> 
#define PLUGIN_VERSION "3"
new Handle:g_CvarEnabled;
new Handle:g_CvarPerc;
new Handle:ff = INVALID_HANDLE; 
new bool:bLateLoad = false; 

public Plugin:myinfo = 
{
	name = "[INS] ReflectTK",
	author = "wribit",
	description = "simple plugin that reflects the damage caused by a team mate attacking another.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_reflecttk_version", PLUGIN_VERSION, "Version of the ReflectTK Plugin", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CvarEnabled = CreateConVar("sm_reflecttk_enabled","1","Enables(1) or disables(0) the plugin.",FCVAR_NOTIFY);
	g_CvarPerc = CreateConVar("sm_reflecttk_perc","100", "Sets the percentage of the damage reflected onto the attacker.", FCVAR_NOTIFY);
	ff = FindConVar("mp_friendlyfire"); 
	AutoExecConfig(true,"plugin.reflecttk");
 
	if(bLateLoad) 
	{ 
		for (new i = 1; i <= MaxClients; i++) 
		{ 
			if (IsClientConnected(i) && IsClientInGame(i)) 
			{ 
				OnClientPutInServer(i); 
			} 
		} 
	} 
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{ 
    bLateLoad = late; 
    return APLRes_Success; 
} 

public OnClientPutInServer(client) 
{ 
    SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage); 
} 

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) 
{ 

	if (!GetConVarBool(ff) || attacker < 1 || victim < 1 || attacker > MaxClients || victim > MaxClients || !GetConVarBool(g_CvarEnabled)) 
	{ 
		return Plugin_Continue; 
	} 
	 
	if ((GetClientTeam(attacker) == GetClientTeam(victim)) && (attacker != victim)) 
	{ 
		new Float:locPerc;
		//VICTIM
		//take into consideration values that are illogical
		if(GetConVarFloat(g_CvarPerc) > 100 || GetConVarFloat(g_CvarPerc) <= 0)
		{
			locPerc = 100.0; //set to default.
		}
		else
		{
			locPerc = GetConVarFloat(g_CvarPerc);
		}
			
		new Float:locDamage = damage * (locPerc / 100);
		damage = 0.0; //SET VICTIM DAMAGE TO 0
		//ATTACKER
		if(IsPlayerAlive(attacker))
		{
			new health = GetClientHealth(attacker);
			if(health > 0)
			{
				health -= ((locDamage >= 0.0) ? RoundFloat(locDamage) : (RoundFloat(locDamage) * -1));
				if (health <= 0)
				{
					health = 0;
				}
			}
			
			if (health <= 0 || RoundFloat(locDamage) >= 100) 
			{ 
				// ATTACKER DEAD
				ForcePlayerSuicide(attacker); 
			} 
			else
			{
				//ATTACKER HURT
				SetEntityHealth(attacker, health);	
			}
		}
		
		//LET PLAYERS KNOW WHAT HAPPENED
		new Handle:VictimPanel = CreatePanel(INVALID_HANDLE);
		new Handle:AttackerPanel = CreatePanel(INVALID_HANDLE);
		new String:sVicPrint[80];
		new String:sAttPrint[80];
		
		Format(sAttPrint,sizeof(sAttPrint), "- %i HP for hurting %N", ((locDamage >= 0.0) ? RoundFloat(locDamage) : (RoundFloat(locDamage) * -1)), victim);
		Format(sVicPrint,sizeof(sVicPrint), "%N was penalized for shooting you", attacker);
		//WHAT THE VICTIM SEES
		DrawPanelText(VictimPanel, sVicPrint);
		SendPanelToClient(VictimPanel, victim, NullMenuHandler, 1);
		CloseHandle(VictimPanel);
		//WHAT THE ATTACKER SEES
		DrawPanelText(AttackerPanel, sAttPrint);
		SendPanelToClient(AttackerPanel, attacker, NullMenuHandler, 1);
		CloseHandle(AttackerPanel);
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public NullMenuHandler(Handle:menu, MenuAction:action, param1, param2) 
{
}