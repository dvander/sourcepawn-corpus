


public Plugin myinfo =
{
	name = "[cs:s]Fix weapon_reload event spam - shotguns",
	author = "Bacardi",
	description = "Block weapon_reload event spam",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};


public void OnPluginStart()
{
	HookEvent("weapon_reload", weapon_reload, EventHookMode_Pre);
}

public Action weapon_reload(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid", 0));

	if(client == 0)
		return Plugin_Continue;

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if(weapon == -1 || !HasEntProp(weapon, Prop_Send, "m_reloadState")) // weapon is not shotgun
		return Plugin_Continue;




	int ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"));

	if(ammo <= 0) // no more primary ammo
		return Plugin_Stop;

	char clsname[15];
	GetEntityClassname(weapon, clsname, sizeof(clsname));

	int MaxClip1 = 0;

	// Unfortunally Max Clip size is added manually
	if(StrContains(clsname, "xm1014", false) != -1)
	{
		MaxClip1 = 7;
	}
	else if(StrContains(clsname, "m3", false) != -1)
	{
		MaxClip1 = 8;
	}

	if(GetEntProp(weapon, Prop_Send, "m_iClip1") >= MaxClip1) // clip full
		return Plugin_Stop;


	//PrintToServer(" m_flTimeWeaponIdle %f", GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") - GetGameTime());

	// Reload begins from m_reloadState == 0, but we are tracking event "weapon_reload" which will appear very late.
	// Next best thing is look m_reloadState == 1
	if(GetEntProp(weapon, Prop_Send, "m_reloadState") == 1)
	{
		float m_flNextPrimaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack") - GetGameTime();

		if(m_flNextPrimaryAttack >= 0.50) // When first Reload start in m_reloadState == 0, it add once, +0.5 seconds. This is good way follow in m_reloadState == 1
			return Plugin_Continue;
	}



	return Plugin_Stop;
}