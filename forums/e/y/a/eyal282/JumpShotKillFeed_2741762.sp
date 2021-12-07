#pragma semicolon 1
#include sdktools
#include sdkhooks

#define JUMP_SHOT 1

static const char g_sExtendedInfo[][] = {"js"};
static const char g_sWeapons[][] = {"deagle", "elite", "fiveseven", "glock", "ak47", "aug", "awp", "famas", "g3sg1", "galilar", "m249", "m4a1", "mac10", "p90", "mp5sd", "ump45", "xm1014", "bizon", "mag7", "negev", "sawedoff", "tec9", "p2000", "hkp2000", "mp7", "mp9", "nova", "p250", "scar20", "sg556", "ssg08", "m4a1_silencer", "m4a1_silencer_off", "usp_silencer", "usp_silencer_off", "cz75a", "revolver"};

float g_DamagePosition[MAXPLAYERS+1][3];

public Plugin myinfo =
{
	name = "Jump Shot Kill Feed",
	description = "Отображает больше информации при убийстве",
	author = "Plugin first made by Phoenix (˙·٠●Феникс●٠·˙), functionality added by Eyal282",
	version = "1.2",
	url = "zizt.ru hlmod.ru"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_player_death, EventHookMode_Pre);
	
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		OnClientPutInServer(i);
	}
}

char sPath[] = "materials/panorama/images/icons/equipment/";

public void OnMapStart()
{
	char sBuf[PLATFORM_MAX_PATH];
	
	for(int i = 0; i < sizeof g_sWeapons; i++)
	{
		FormatEx(sBuf, sizeof sBuf, "%s%s_js_bz.svg", sPath, g_sWeapons[i]);
		
		if(FileExists(sBuf))
			AddFileToDownloadsTable(sBuf);
	}
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
}

public void OnTakeDamageAlivePost(int iClient, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	g_DamagePosition[iClient] = damagePosition;
}

public Action Event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid"), attacker = event.GetInt("attacker"), iClient, iAttacker;
	
	if(userid != attacker && (iClient = GetClientOfUserId(userid)) && (iAttacker = GetClientOfUserId(attacker)))
	{
		char sWeapon[64];
		event.GetString("weapon", sWeapon, sizeof sWeapon);
		
		if(IsWeaponHasExtendedInfo(sWeapon))
		{
			int ExtendedInfo = 0;

			if(!(GetEntityFlags(iAttacker) & FL_ONGROUND))
				ExtendedInfo |= JUMP_SHOT;
			
			if(ExtendedInfo)
			{
				Format(sWeapon, sizeof sWeapon, "%s_%s_bz", sWeapon, g_sExtendedInfo[ExtendedInfo-1]);
				
				char sBuf[PLATFORM_MAX_PATH];
				FormatEx(sBuf, sizeof(sBuf), "%s%s.svg", sPath, sWeapon);
				
				if(FileExists(sBuf))
				{
					event.SetString("weapon", sWeapon);

					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

bool IsWeaponHasExtendedInfo(const char[] sWeapon)
{
	for(int i = 0; i < sizeof g_sWeapons; i++)
	{
		if(strcmp(g_sWeapons[i], sWeapon) == 0)
		{
			return true;
		}
	}
	return false;
}