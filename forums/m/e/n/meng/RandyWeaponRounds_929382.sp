/* RandomWeaponRounds.sp

Description: Random weapon practice.

*/

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "0.7"

public Plugin:myinfo =
{
	name = "RandyWeaponRounds",
	author = "Meng",
	description = "Random weapon practice",
	version = "PLUGIN_VERSION",
	url = ""
}

new String:g_ww[32];
new bool:enabled;
new bool:g_hbz = false;
new Switch;
new g_WeaponParent;

public OnPluginStart()
{
	CreateConVar("randomweapons_version", PLUGIN_VERSION, "Random Weapons Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

	HookEvent("round_start", RoundStart);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("round_end", EventRoundEnd);

	RegAdminCmd("sm_randomweapons", OnOffSwitch, ADMFLAG_RCON);
}

static const String:RWeapons[25][] = {
	"weapon_m4a1",
	"weapon_ak47",
	"weapon_aug",
	"weapon_galil",
	"weapon_xm1014",
	"weapon_mp5navy",
	"weapon_g3sg1",
	"weapon_awp",
	"weapon_sg550",
	"weapon_ump45",
	"weapon_scout",
	"weapon_m3",
	"weapon_famas",
	"weapon_sg552",
	"weapon_p90",
	"weapon_glock",
	"weapon_usp",
	"weapon_deagle",
	"weapon_fiveseven",
	"weapon_elite",
	"weapon_p228",
	"weapon_mac10",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_tmp"
};

public Action:OnOffSwitch(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_randomweapons <1/0>");
		return Plugin_Handled;
	}
	new String:power[8];
	GetCmdArg(1, power, sizeof(power));
	Switch = StringToInt(power);
	if (Switch)
	{
		PrintToChatAll("Randy Weapon Rounds Enabled! (next round)");
		enabled = true;
		new ent = -1;
		new ent2 = -1;
		while ((ent = FindEntityByClassname(ent,"func_buyzone")) != -1) 
		{
			if (IsValidEdict(ent))
				AcceptEntityInput(ent,"Disable");
		}
		if ((FindEntityByClassname(ent2, "func_bomb_target" )) != -1)
			g_hbz = true;
		else
			g_hbz = false;
	}
	else if (!Switch)
	{
		PrintToChatAll("Randy Weapon Rounds Disabled!");
		enabled = false;
		new ent = -1;
		while ((ent = FindEntityByClassname(ent,"func_buyzone")) != -1) 
		{
			if (IsValidEdict(ent))
				AcceptEntityInput(ent,"Enable");
		}
	}
	return Plugin_Continue;
}

public RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (enabled)
	{
		new maxent = GetMaxEntities(), String:ent[64];
		for (new i = GetMaxClients(); i < maxent; i++)
		{
			if (IsValidEdict(i) && IsValidEntity(i))
			{
				GetEdictClassname(i, ent, sizeof(ent));
				if (StrContains(ent, "weapon_") != -1 && 
				GetEntDataEnt2(i, g_WeaponParent) == -1)
					RemoveEdict(i);
			}
		}
	}
}

StripAndGiveRWeapon(client)
{
	new wepIdx;
	for (new i = 0; i < 5; i++)
	{
		if ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
		{  
			RemovePlayerItem(client, wepIdx);
			RemoveEdict(wepIdx);
		}        
	} 
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, g_ww);
	GivePlayerItem(client, "item_assaultsuit");
}

public Action:givedefuser(Handle:timer, any:client)
{
	GivePlayerItem(client, "item_defuser");
}

public EventPlayerSpawn(Handle:event, const String:name[],bool:dontBroadcast)
{
	if (enabled)
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		new team = GetClientTeam(client);
		if (team == 2)
			StripAndGiveRWeapon(client);
		else if (team == 3)
		{
			StripAndGiveRWeapon(client);
			if (g_hbz)
				CreateTimer(3.0, givedefuser, client);
		}
	}
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (enabled)
		strcopy(g_ww, sizeof(g_ww), RWeapons[GetRandomInt(0, sizeof(RWeapons) - 1)]);
}