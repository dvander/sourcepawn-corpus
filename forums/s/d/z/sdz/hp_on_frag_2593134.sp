#include <sourcemod>

ConVar g_cvFlagRequired;

public Plugin myinfo = 
{
	name = "HP on Frag",
	author = "sidezz",
	description = "give u hp if u kill someone n u gotta admin flag",
	version = "1.0",
	url = "lol"
};

public void OnPluginStart()
{
	g_cvFlagRequired = CreateConVar("flag_hp_required", "t", "Flag required to recieve hp");
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(!IsClientInGame(attacker) || !IsClientAuthorized(attacker)) return

	//Get the flags of the dude:
	char steamid[32]; GetClientAuthId(attacker, AuthId_Steam2, steamid, sizeof(steamid));
	AdminId admin = FindAdminByIdentity("steam", steamid);

	//is valid admin?
	if(admin == INVALID_ADMIN_ID) return;

	AdminFlag flag;

	//if the cvar isn't good then just hardcode stuff:
	if(FindFlagByChar(g_cvFlagRequired.IntValue, flag))
	{
		if(admin.HasFlag(flag, Access_Real))
		{
			SetEntityHealth(attacker, GetClientHealth(attacker) + 5);
		}
	}
	else
	{
		if(admin.HasFlag(Admin_Custom6, Access_Real))
		{
			SetEntityHealth(attacker, GetClientHealth(attacker) + 5);
		}
	}

	return;
}