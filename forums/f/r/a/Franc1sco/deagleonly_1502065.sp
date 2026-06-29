
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


#define PLUGIN_VERSION "v1.0"

public Plugin:myinfo =
{
	name = "SM Only Deagle",
	author = "Franc1sco Steam: franug",
	description = "Mod for only deagle server",
	version = PLUGIN_VERSION,
	url = "www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
	CreateConVar("sm_OnlyDeagle", PLUGIN_VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if ( (IsClientInGame(client)) && (IsPlayerAlive(client) && GetClientTeam(client) > 1) )
	{
		new wepIdx;

		// strip all weapons
		for (new s = 0; s < 4; s++)
		{
			if ((wepIdx = GetPlayerWeaponSlot(client, s)) != -1)
			{
				RemovePlayerItem(client, wepIdx);
				RemoveEdict(wepIdx);
			}
		}

		GivePlayerItem(client, "weapon_deagle");
	}
}

public OnClientPutInServer(client)
{
   SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action:OnWeaponCanUse(client, weapon)
{
  decl String:sClassname[32];
  GetEdictClassname(weapon, sClassname, sizeof(sClassname));
  if (!StrEqual(sClassname, "weapon_deagle"))
        return Plugin_Handled;
  return Plugin_Continue;
}