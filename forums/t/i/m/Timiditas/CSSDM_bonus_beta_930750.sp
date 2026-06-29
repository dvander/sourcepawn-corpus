
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3beta"

new g_iHealth;
new g_list[65][3][2]; //stores how many grenades of what type have exploded for every client - 0 grenades used, 1 kills
new String: weaponlist[][] = { "hegrenade", "flashbang", "smokegrenade" };
new neededlist[3] = {2,5,1}; //needed kills to get another item of the type listed above
new healthamount = 15;
new headshotamount = 15;
new knifeamount = 30;
new nademode = 0;
new healthmode = 100;
new me_enable = 1;
new FFA = 1;

new Handle:cv_enable = INVALID_HANDLE;
new Handle:cv_nademode = INVALID_HANDLE;
new Handle:cv_healthmode = INVALID_HANDLE;
new Handle:cv_health = INVALID_HANDLE;
new Handle:cv_health_head = INVALID_HANDLE;
new Handle:cv_health_knife = INVALID_HANDLE;
new Handle:cv_neededkills_HE = INVALID_HANDLE;
new Handle:cv_neededkills_flash = INVALID_HANDLE;
new Handle:cv_neededkills_smoke = INVALID_HANDLE;
new Handle:cv_FFA = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "DM Bonus",
	author = "Timiditas",
	description = "Gives new Nade/Smoke/Flash and HP for kills",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=930953#post930953"
};

public OnPluginStart()
{
	CreateConVar("dm_bonus_version", PLUGIN_VERSION, "dm_bonus_version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
	if (g_iHealth == -1)
	{
		SetFailState("[dm_bonus] Error - Unable to get offset for CSSPlayer::m_iHealth");
		return;
	}
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("weapon_fire", EventWeaponFire);
	cv_enable = CreateConVar("dm_bonus_enable", "1", "Enable/Disable plugin");
	cv_nademode = CreateConVar("dm_bonus_nademode", "0", "0 = replenish used nades only, 1 = always give nade (useful in conjunction with SM plugin 'Grenade Pack')");
	cv_healthmode = CreateConVar("dm_bonus_healthmode", "100", "Replenish health up to this amount, 0 = No maximum, always gives bonus health");
	cv_health = CreateConVar("dm_bonus_health", "15", "Amount of HP to give for every kill, 0 = disable");
	cv_health_head = CreateConVar("dm_bonus_health_headshot", "15", "Amount of HP to give for headshot, 0 = disable");
	cv_health_knife = CreateConVar("dm_bonus_health_knife", "30", "Amount of HP to give for knifekill");
	cv_neededkills_HE = CreateConVar("dm_bonus_needed_HE", "2", "Kills needed to receive hegrenade, 0 = disable");
	cv_neededkills_flash = CreateConVar("dm_bonus_needed_flash", "5", "Kills needed to receive flashbang, 0 = disable");
	cv_neededkills_smoke = CreateConVar("dm_bonus_needed_smoke", "1", "Kills needed to receive smokegrenade, 0 = disable");
	cv_FFA = CreateConVar("dm_bonus_FFA", "1", "Free for all mode (teamkills do count)");
	AutoExecConfig(true, "dm_bonus");
	
	HookConVarChange(cv_enable, EnableChanged);
	HookConVarChange(cv_nademode, SettingChanged);
	HookConVarChange(cv_healthmode, SettingChanged);
	HookConVarChange(cv_health_head, SettingChanged);
	HookConVarChange(cv_health_knife, SettingChanged);
	HookConVarChange(cv_health, SettingChanged);
	HookConVarChange(cv_neededkills_HE, SettingChanged);
	HookConVarChange(cv_neededkills_flash, SettingChanged);
	HookConVarChange(cv_neededkills_smoke, SettingChanged);
	HookConVarChange(cv_FFA, SettingChanged);
	me_enable = GetConVarInt(cv_enable);
	ReadCvars();
}

public SettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ReadCvars();
}
public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iNew = StringToInt(newValue);
	new iOld = StringToInt(oldValue);
	if (iNew == iOld)
		return;
	if (iNew == 1)
	{
		me_enable = 1;
		ResetAll();
	}
	else
		me_enable = 0;
}

get_weapon_index(const String: weapon_name[])
{
	new loop_break = 0;
	new index = 0;
	
	while ((loop_break == 0) && (index < sizeof(weaponlist)))
	{
		if (strcmp(weapon_name, weaponlist[index], true) == 0)
			loop_break++;
		index++;
	}

	if (loop_break == 0)
		return -1;
	else
		return index - 1;
}

public Action:EventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (me_enable == 0 || nademode == 1)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client < 1)
		return Plugin_Continue;
	
	new String:weapon[64];
	GetEventString(event, "weapon", weapon, 64);
	new weapon_index = get_weapon_index(weapon);
	if (weapon_index == -1)
		return Plugin_Continue;

	g_list[client][weapon_index][0]++;
	//This method might be rather stupid. You won't get any nades if you don't had any in the first place.
	return Plugin_Continue;
}
public OnClientPutInServer(client)
{
	if(me_enable == 0)
		return;
	
	ResetClient(client);
}

ResetAll()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		ResetClient(i);
	}
}
ResetClient(client)
{
	for (new j = 0; j < 3; j++)
	{
		g_list[client][j][0] = 0;
		g_list[client][j][1] = 0;
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(me_enable == 0)
		return;
	
	ResetAll();
}

ReadCvars()
{
	neededlist[0] = GetConVarInt(cv_neededkills_HE);
	neededlist[1] = GetConVarInt(cv_neededkills_flash);
	neededlist[2] = GetConVarInt(cv_neededkills_smoke);
	healthamount = GetConVarInt(cv_health);
	nademode = GetConVarInt(cv_nademode);
	healthmode = GetConVarInt(cv_healthmode);
	headshotamount = GetConVarInt(cv_health_head);
	knifeamount = GetConVarInt(cv_health_knife);
	FFA = GetConVarInt(cv_FFA);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(me_enable == 0)
		return;
  
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	new victim = GetClientOfUserId(victimId);
	new attacker = GetClientOfUserId(attackerId);
	if(attacker == 0)
		return;
	new String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	new team_victim = GetClientTeam(victim);
	new team_attacker = GetClientTeam(attacker);
	new bool:teamkill = (team_victim == team_attacker);
	
	if(attacker == victim) //suicide
		return;
	if(FFA == 0 && teamkill)
    return;
    
	if (healthamount != 0 || headshotamount != 0 || knifeamount != 0)
	{
		new bool:headie = GetEventBool(event, "headshot");
		new givehealth;
		if (headie)
			givehealth = headshotamount;
		else
			givehealth = healthamount;
		if (strcmp(weapon[0],"knife",false) == 0)
      givehealth += knifeamount;
      
		if(givehealth != 0)
		{
			new oldhealth = GetEntData(attacker,g_iHealth,4);
			new iBuf = oldhealth;
			if(healthmode == 0)
				oldhealth += givehealth;
			else
			{
				if(oldhealth < healthmode)
				{
					oldhealth += givehealth;
					if (oldhealth > healthmode)
						oldhealth = healthmode;
				}
			}
			if (iBuf != oldhealth)
				SetEntData(attacker, g_iHealth, oldhealth);
		}
	}
	
	ResetClient(victim);
	new client = attacker;
	for (new j = 0; j < 3; j++)
	{
		if(neededlist[j] == 0)
			continue;
		
		g_list[client][j][1]++;
		
		if(g_list[client][j][1] >= neededlist[j])
		{
			if((g_list[client][j][0] > 0 && nademode == 0) || nademode == 1)
			{
				g_list[client][j][1] = 0;
				if(nademode == 0)
					g_list[client][j][0]--;
				new String:ent_weapon[64];
				Format(ent_weapon, sizeof(ent_weapon), "weapon_%s", weaponlist[j]);
				GivePlayerItem(client, ent_weapon);
			}
		}
	}
}
