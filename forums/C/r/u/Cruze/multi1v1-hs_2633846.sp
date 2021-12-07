#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multicolors>
#include <multi1v1>

#pragma semicolon 1
#pragma newdecls required

bool g_bHeadShot[MAXPLAYERS+1];

Handle gh_MessageLoc, gh_Ranked;

public Plugin myinfo =
{
    name = "CS:GO Multi1v1: Headshot round addon",
    author = "Bara",
    description = "Adds an headshot round-type",
    version = "1.0.1",
    url = "git.tf/Bara"
};

public void OnPluginStart()
{
    // Lateload support
	for(int client = 1; client <= MaxClients; client++)
	{
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	gh_MessageLoc 	= CreateConVar("sm_1v1_hs_msgloc", "1", "Message location of \"This is headshot round\" message. 0 = Chat. 1 = Hint");
	gh_Ranked 		= CreateConVar("sm_1v1_hs_ranked", "1", "Ranked? 0 for no.");
	
	AutoExecConfig(true, "plugin.1v1hs");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && IsClientInGame(victim) && IsClientInGame(attacker))
	{
		if (g_bHeadShot[victim] && g_bHeadShot[attacker])
		{
			if(damagetype & CS_DMG_HEADSHOT)
			{
				return Plugin_Continue;
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void Multi1v1_OnRoundTypesAdded()
{
	if(GetConVarBool(gh_Ranked))
		Multi1v1_AddRoundType("Headshot", "headshot", HeadshotHandler, true, true, "HeadshotOnly", true);
	else
		Multi1v1_AddRoundType("Headshot", "headshot", HeadshotHandler, true, false, "", true);
}

public void HeadshotHandler(int client)
{
	char sRifle[WEAPON_NAME_LENGTH], sPistol[WEAPON_NAME_LENGTH];
	Multi1v1_GetRifleChoice(client, sRifle);
	Multi1v1_GetPistolChoice(client, sPistol);
	
	int iRifle = GivePlayerItem(client, sRifle);
	int iPistol = GivePlayerItem(client, sPistol);
	
	EquipPlayerWeapon(client, iRifle);
	EquipPlayerWeapon(client, iPistol);
	
	g_bHeadShot[client] = true;

	if(GetConVarBool(gh_MessageLoc))
		PrintHintText(client, "<font color='#8b0000'>This is a headshot only round!</font>");
	else
		CPrintToChat(client, "{darkred}This is a headshot only round!");
}

// Reset stuff
public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			g_bHeadShot[client] = false;
		}
	}
}