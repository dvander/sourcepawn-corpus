///////////////////////////////////////////////////
//             pragma & defines & includes       //
///////////////////////////////////////////////////


#pragma semicolon 1

#define PLUGIN_AUTHOR "Benito"
#define PLUGIN_VERSION "1.00"
#define LOGODEV "{blue}[AREA]"


#include <sourcemod>
#include <sdktools>
#include <smlib>
//#include <morecolors> // CSS
#include <colorvariables>


///////////////////////////////////////////////////
//                functions                      //
///////////////////////////////////////////////////

bool IsInAreaMod[MAXPLAYERS+1] = false;
bool g_UseShoot[MAXPLAYERS+1];               


public Plugin myinfo = 
{
	name = "Area position",
	author = PLUGIN_AUTHOR,
	description = "Montre les position indiqué avec la balle de l'arme",
	version = PLUGIN_VERSION,
	url = "https://revolution-team.fr/"
};

public void OnPluginStart()
{
	HookEvent("bullet_impact", OnBulletImpact, EventHookMode_Pre);
	
	RegConsoleCmd("sm_area", Command_Area);
}

public Action OnBulletImpact(Handle:event, const String:weaponName[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsRootAdmin(client))
	{
		if (IsInAreaMod[client])
		{
			if (!g_UseShoot[client])
			{
				g_UseShoot[client] = true;
				
				static float pos[3];
				pos[0] = GetEventFloat(event,"x");
				pos[1] = GetEventFloat(event,"y");
				pos[2] = GetEventFloat(event,"z");
				
				CPrintToChat(client, "%s : Coordonnées : %f %f %f", LOGODEV, pos[0], pos[1], pos[2]);
			}
			else if (g_UseShoot[client])
			{
				g_UseShoot[client] = false;
			}
		}
	}
	
	return Plugin_Handled;
}

public ActionOnClientPreAdminCheck(client)
{
	ResetInfos(client);
}	

public ResetInfos(client)
{
	IsInAreaMod[client] = false;
}	

public Action Command_Area(client, args)
{
	if (IsValidAndAlive(client))
	{
		if (IsRootAdmin(client))
		{
			if (!IsInAreaMod[client])
			{
				CPrintToChat(client, "%s : Mode création de zones activé.", LOGODEV);
				IsInAreaMod[client] = true;
				
				disarm(client);
				GivePlayerItem(client, "weapon_usp_silencer"); // Set weapon_usp_ if is css
			}
			else
			{
				CPrintToChat(client, "%s : Mode création de zones désactivé.", LOGODEV);
				IsInAreaMod[client] = false;
				
				disarm(client);
				GivePlayerItem(client, "weapon_knife");
			}
		}
	}
	
	return Plugin_Handled;
}

public IsRootAdmin(client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT) // ADMFLAG_ROOT = FLAG 'Z' for ROOT PERMISSION
		return true;
	else
		return false;
}

public disarm(player)
{
	int wepIdx;
	for (new f = 0; f < 6; f++)
		if (f < 6 && (wepIdx = GetPlayerWeaponSlot(player, f)) != -1)  
			RemovePlayerItem(player, wepIdx);
}

public IsValidAndAlive(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
		return true;
	else
		return false;
}