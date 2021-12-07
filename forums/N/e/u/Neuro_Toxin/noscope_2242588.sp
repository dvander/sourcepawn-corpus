#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <autoexecconfig>
//#include <updater>

#define NOSCOPE_VERSION  "1.0.3.1"
#define UPDATE_URL    "https://bara.in/update/noscope.txt"

new Handle:g_hEnablePlugin = INVALID_HANDLE,
	Handle:g_hEnableOneShot = INVALID_HANDLE,
	Handle:g_hEnableWeapon = INVALID_HANDLE,
	Handle:g_hAllowGrenade = INVALID_HANDLE,
	Handle:g_hAllowWorld = INVALID_HANDLE,
	Handle:g_hAllowMelee = INVALID_HANDLE,
	Handle:g_hAllowedWeapon = INVALID_HANDLE,
	Handle:g_hAllowOnGround = INVALID_HANDLE;

new String:g_sAllowedWeapon[32],
	String:g_sGrenade[32],
	String:g_sWeapon[32];

new m_flNextSecondaryAttack;

public Plugin:myinfo =
{
	name = "NoScope (Jump Support)",
	author = "Bara, Jump support by Neuro Toxin",
	description = "",
	version = NOSCOPE_VERSION,
	url = "www.bara.in"
};

public OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSS && GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Only CSS and CSGO Support");
	}

	//LoadTranslations("noscope.phrases"); <- no translations are in use

	AutoExecConfig_SetFile("plugin.noscope", "sourcemod");
	AutoExecConfig_SetCreateFile(true);

	CreateConVar("noscope_version", NOSCOPE_VERSION, "NoScope", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnablePlugin = AutoExecConfig_CreateConVar("noscope_enable", "1", "Enable / Disalbe NoScope Plugin", _, true, 0.0, true, 1.0);
	g_hEnableOneShot = AutoExecConfig_CreateConVar("noscope_oneshot", "0", "Enable / Disable kill enemy with one shot", _, true, 0.0, true, 1.0);
	g_hEnableWeapon = AutoExecConfig_CreateConVar("noscope_oneweapon", "1", "Enable / Disalbe Only One Weapon Damage", _, true, 0.0, true, 1.0);
	g_hAllowGrenade = AutoExecConfig_CreateConVar("noscope_allow_grenade", "0", "Enable / Disalbe Grenade Damage", _, true, 0.0, true, 1.0);
	g_hAllowWorld = AutoExecConfig_CreateConVar("noscope_allow_world", "0", "Enable / Disalbe World Damage", _, true, 0.0, true, 1.0);
	g_hAllowMelee = AutoExecConfig_CreateConVar("noscope_allow_knife", "0", "Enable / Disalbe Knife Damage", _, true, 0.0, true, 1.0);
	g_hAllowedWeapon = AutoExecConfig_CreateConVar("noscope_allow_weapon", "weapon_awp", "What weapon should the player get back after it has zoomed?");
	g_hAllowOnGround = AutoExecConfig_CreateConVar("noscope_allow_onground", "0", "Enable / Disable NoScope only when the player is jumping ");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	m_flNextSecondaryAttack = FindSendPropOffs("CBaseCombatWeapon", "m_flNextSecondaryAttack");

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_PreThink, OnPreThink);
		}
	}

	if (LibraryExists("updater"))
	{
		//Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		//Updater_AddPlugin(UPDATE_URL);
	}
}

public OnClientPutInServer(i)
{
	SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(i, SDKHook_PreThink, OnPreThink);
}

public Action:OnPreThink(client)
{
	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetNoScope(client, iWeapon);
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(GetConVarInt(g_hEnablePlugin))
	{
		if(IsClientValid(victim))
		{
			if(damagetype & DMG_FALL || attacker == 0)
			{
				if(GetConVarInt(g_hAllowWorld))
				{
					return Plugin_Continue;
				}
				else
				{
					return Plugin_Handled;
				}
			}

			if(IsClientValid(attacker))
			{
				GetEdictClassname(inflictor, g_sGrenade, sizeof(g_sGrenade));
				GetClientWeapon(attacker, g_sWeapon, sizeof(g_sWeapon));

				if(GetConVarInt(g_hEnableWeapon))
				{
					GetConVarString(g_hAllowedWeapon, g_sAllowedWeapon, sizeof(g_sAllowedWeapon));

					if(!StrEqual(g_sWeapon[7], g_sAllowedWeapon))
					{
						return Plugin_Handled;
					}
				}

				if(GetConVarInt(g_hEnableOneShot))
				{
					damage = float(GetClientHealth(victim));
					return Plugin_Changed;
				}

				if(GetConVarInt(g_hAllowMelee))
				{
					if(StrEqual(g_sWeapon, "weapon_knife"))
					{
						return Plugin_Continue;
					}
				}

				if(GetConVarInt(g_hAllowGrenade))
				{
					if(GetEngineVersion() == Engine_CSS)
					{
						if(StrEqual(g_sGrenade, "hegrenade_projectile"))
						{
							return Plugin_Continue;
						}
					}
					else if(GetEngineVersion() == Engine_CSGO)
					{
						if(StrEqual(g_sGrenade, "hegrenade_projectile") || StrEqual(g_sGrenade, "decoy_projectile") || StrEqual(g_sGrenade, "molotov_projectile"))
						{
							return Plugin_Continue;
						}
					}
				}
				return Plugin_Continue;
			}
			else
			{
				return Plugin_Handled;
			}
		}
		else
		{
			return Plugin_Handled;
		}
	}
	else
	{
		return Plugin_Continue;
	}
}

stock SetNoScope(client, weapon)
{
	if(IsValidEdict(weapon))
	{
		decl String:classname[MAX_NAME_LENGTH];

		if (GetEdictClassname(weapon, classname, sizeof(classname))
		|| StrEqual(classname[7], "ssg08")  || StrEqual(classname[7], "aug")
		|| StrEqual(classname[7], "sg550")  || StrEqual(classname[7], "sg552")
		|| StrEqual(classname[7], "sg556")  || StrEqual(classname[7], "awp")
		|| StrEqual(classname[7], "scar20") || StrEqual(classname[7], "g3sg1"))
		{
			if (GetConVarBool(g_hAllowOnGround))
			{
				if (!(GetEntityFlags(client) & FL_ONGROUND))
				{
					if (GetEntProp(client, Prop_Send, "m_bIsScoped"))
					{
						SetEntProp(weapon, Prop_Send, "m_zoomLevel", 0);
						SetEntProp(client, Prop_Send, "m_iFOV", 90);
						SetEntProp(client, Prop_Send, "m_bIsScoped", 0);
						SetEntProp(client, Prop_Send, "m_bResumeZoom", 0);
					}
					SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 0.1);
				}
			}
			else
				SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 0.1);
		}
	}
}

stock bool:IsClientValid(client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}