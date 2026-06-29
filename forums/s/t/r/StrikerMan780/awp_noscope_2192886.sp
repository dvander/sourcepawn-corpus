#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "AWP No Scope",
	author = "Specter, XARiUS",
	description = "AWP No Scoping Plugin",
	version = "1.0",
	url = "http://www.eyesight.se"
};

new String:language[4];
new String:languagecode[4];
new bool:g_enabled;
new bool:g_bulletpath;
new g_laser;
new Handle:g_Cvarenabled = INVALID_HANDLE;
new Handle:g_Cvarbulletpath = INVALID_HANDLE;

public OnPluginStart()
{
  LoadTranslations("awpnoscope.phrases");
  CreateConVar("sm_awpnoscope_version", VERSION, "AWP No Scope Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  g_Cvarenabled = CreateConVar("sm_awpnoscope_enabled", "1", "Enable this plugin. 0 = Disabled");
  g_Cvarbulletpath = CreateConVar("sm_awpnoscope_bulletpath", "0", "Show the bullet path using a small laser beam. 0 = Disabled");
  GetLanguageInfo(GetServerLanguage(), languagecode, sizeof(languagecode), language, sizeof(language));

  HookEvent("weapon_zoom", EventWeaponZoom, EventHookMode_Post);
  HookEvent("bullet_impact", OnBulletImpact, EventHookMode_Post);
  
  HookConVarChange(g_Cvarenabled, OnSettingChanged);
  HookConVarChange(g_Cvarbulletpath, OnSettingChanged);

  g_enabled = GetConVarBool(g_Cvarenabled);
  g_bulletpath = GetConVarBool(g_Cvarbulletpath);
}

public OnMapStart()
{
	g_laser = PrecacheModel("materials/sprites/laser.vmt");
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
  if (convar == g_Cvarenabled)
  {
    if (newValue[0] == '1')
    {
      PrintHintTextToAll("%t", "AWP Noscope enabled");
      EmitSoundToAll("weapons/zoom.wav");
      g_enabled = true;
    }
    else
    {
      PrintHintTextToAll("%t", "AWP Noscope disabled");
      EmitSoundToAll("weapons/zoom.wav");
      g_enabled = false;
    }
  }
  if (convar == g_Cvarbulletpath)
  {
    if (newValue[0] == '1')
    {
			g_bulletpath = true;
    }
    else
    {
      g_bulletpath = false;
    }
  }
}

public Action:OnBulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (g_enabled && g_bulletpath)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new String:weaponname[32];
		GetClientWeapon(client, weaponname, sizeof(weaponname));
	
		if (StrEqual(weaponname, "weapon_awp", false))
		{
			new color[4];

			if (GetClientTeam(client) == 3)
			{
				color = {75, 75, 255, 255};
			}
			else
			{
				color = {255, 75, 75, 255};
			}
			
			decl Float:bulletOrigin[3];
			GetClientEyePosition(client, bulletOrigin);
	
			decl Float:bulletDestination[3];
			bulletDestination[0] = GetEventFloat(event, "x");
			bulletDestination[1] = GetEventFloat(event, "y");
			bulletDestination[2] = GetEventFloat(event, "z");

			TE_SetupBeamPoints(bulletOrigin, bulletDestination, g_laser, 0, 0, 0, 0.5, 1.0, 1.0, 10, 0.0, color, 0);
			TE_SendToAll(); 
		}
	}
}

public Action:EventWeaponZoom(Handle:event,const String:name[],bool:dontBroadcast)
{
  if (g_enabled)
  {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new String:weaponname[32];
    GetClientWeapon(client, weaponname, sizeof(weaponname));
    if (StrEqual(weaponname, "weapon_awp", false))
    {
      new weapon = GetPlayerWeaponSlot(client, 0);
      if (IsValidEdict(weapon))
      {
        RemovePlayerItem(client, weapon);
        RemoveEdict(weapon);
        CreateTimer(0.1, GiveAWP, client);
        PrintHintText(client, "%t", "Not Allowed");
      }
      return Plugin_Continue;
    }
    return Plugin_Continue;
  }
  return Plugin_Continue;
}

public Action:GiveAWP(Handle:Timer, any:client)
{
  GivePlayerItem(client, "weapon_awp");
}
