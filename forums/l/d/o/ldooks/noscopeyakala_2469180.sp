#include <sdkhooks>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <emitsoundany>
#include <colors>

new kackisi[MAXPLAYERS+1]; 
new kackisihs[MAXPLAYERS+1]; 

public Plugin:myinfo = 
{
	name = "[AWP] No-Scope Detector",
	author = "Ak0 + translated to english by ldooks",
	description = "Awp Maping No-Scope Detector",
	version = "1.1",
	url = "www.frmakdag.com"
}


public OnPluginStart ()
{
	HookEvent("player_death", OnPlayerDeath);
}

public bool:OnClientConnect(client)
{
	kackisi[client] = 0;
	kackisihs[client] = 0;
	return true; 
}  
public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:isim[32];
	decl String:g_sWeapon[32];
	new bool:hscek = GetEventBool(event, "headshot");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new zoombilgi = GetEntProp(attacker, Prop_Send, "m_bIsScoped")
	GetClientName(attacker, isim, sizeof(isim));
	GetEventString(event, "weapon", g_sWeapon, sizeof(g_sWeapon));
	if(StrEqual(g_sWeapon, "awp") || StrEqual(g_sWeapon, "ssg08"))
	{
		if (hscek && !zoombilgi) 
		{
			kackisihs[attacker]++;
			CPrintToChatAll("{green}%s {darkred}Noscope + Headshot.", isim);
			PrintToChat(attacker, "HS + Total number of noscopes: %d", kackisihs[attacker]);
		} else if (!zoombilgi) {
			kackisi[attacker]++;
			CPrintToChatAll("{green}%s {darkred}Noscope.", isim);
			PrintToChat(attacker, "Total number of noscopes: %d",kackisi[attacker]);
		}
	}
	
}