#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "L4D2 Weapon Attack Speed Modifier",
	author = "Machine",
	description = "Modifies the Survivors Weapon Attack Speed",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1369117#post1369117"
};

static int WeaponSpeed[MAXPLAYERS + 1] = {0, ...}, m_bInReload = 0, iSlot = 0, args2 = 0, target_list[MAXPLAYERS] = {0, ...}, target_count = 0;
static ConVar WeaponSpeedEnabled, WeaponSpeedAmount, WeaponSpeedRecoil;
static bool bWeaponSpeedEnabled = false, bWeaponSpeedRecoil = false, tn_is_ml = false;
static float fWeaponSpeedAmount = 0.0, m_flNextPrimaryAttack = 0.0, m_flNextSecondaryAttack = 0.0, m_flCycle = 0.0;
static char Target[32], arg2[32], target_Name[MAX_TARGET_LENGTH], clientName[64], Name[64];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("l4d2_weaponspeed_version", PLUGIN_VERSION, "L4D2 Weapon Attack Speed Modifier Version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	WeaponSpeedEnabled = CreateConVar("l4d2_weaponspeed_everyone", "0", "<0|1> - Apply the Weapon Attack Speed Modifier on Everyone?", CVAR_FLAGS, true, 0.0, true, 1.0);
	WeaponSpeedAmount = CreateConVar("l4d2_weaponspeed_amount", "1.6", "<1.0-2.0> - Weapon Attack Speed Modified Value", CVAR_FLAGS, true, 1.0, true, 2.0);
	WeaponSpeedRecoil = CreateConVar("l4d2_weaponspeed_recoil", "1", "<0|1> - Weapon Recoil Enabled?", CVAR_FLAGS, true, 0.0, true, 1.0);

	WeaponSpeedEnabled.AddChangeHook(ConVarsChanged);
	WeaponSpeedAmount.AddChangeHook(ConVarsChanged);
	WeaponSpeedRecoil.AddChangeHook(ConVarsChanged);

	//Execute or create cfg
	AutoExecConfig(true, "l4d2_weaponspeed");

	RegAdminCmd("l4d2_weaponspeed", Command_WeaponSpeed, ADMFLAG_BAN, "l4d2_weaponspeed <#userid|Name> <0|1> - Changes clients default weapon speed");
}

public void OnConfigsExecuted()
{
	ConVarsChanged(null, "", "");
}

void ConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bWeaponSpeedEnabled = WeaponSpeedEnabled.BoolValue;
	fWeaponSpeedAmount = WeaponSpeedAmount.FloatValue;
	bWeaponSpeedRecoil = WeaponSpeedRecoil.BoolValue;
}

public void OnClientPutInServer(int client)
{
	if(bWeaponSpeedEnabled && client > 0)
	{
		WeaponSpeed[client] = 0;
	}
}

Action Command_WeaponSpeed(int client, int args)
{
	if(bWeaponSpeedEnabled)
	{
		if (args < 1)
		{
			if (client > 0)
			{
				if (WeaponSpeed[client] == 0)
				{
					WeaponSpeed[client] = 1;
					PrintToChat(client,"\x01[SM] Your \x03Weapon Speed\x01 has been modified");
				}
				else
				{
					WeaponSpeed[client] = 0;
					PrintToChat(client,"\x01[SM] Your \x05Weapon Speed\x01 has returned to normal");
				}
			}
			else
			{
				ReplyToCommand(client, "[SM] Must be in game to modify Weapon Speed on yourself");
			}
		}
		else if (args == 1)
		{
			ReplyToCommand(client, "[SM] Usage: l4d2_weaponspeed <#userid|Name> <0|1>");
		}
		else if (args == 2)
		{
			GetCmdArg(1, Target, sizeof(Target));
			GetCmdArg(2, arg2, sizeof(arg2));
			args2 = StringToInt(arg2);

			if ((target_count = ProcessTargetString(
				Target,
				client,
				target_list,
				MAXPLAYERS,
				0,
				target_Name,
				sizeof(target_Name),
				tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for (int i = 0; i < target_count; i++)
			{
				GetClientName(target_list[i], clientName, sizeof(clientName));
				if (args2 == 0)
				{
					ReplyToCommand(client,"[SM] Custom Weapon Speed Disabled on %s",clientName);
					WeaponSpeed[target_list[i]] = 0;
					PrintToChat(target_list[i],"\x01[SM] Your \x05Weapon Speed\x01 has returned to normal");
				}
				else if (args2 == 1)
				{
					ReplyToCommand(client,"[SM] Custom Weapon Speed Enabled on %s",clientName);
					WeaponSpeed[target_list[i]] = 1;
					PrintToChat(target_list[i],"\x01[SM] Your \x03Weapon Speed\x01 has been modified");
				}
				else
				{
					ReplyToCommand(client, "[SM] Usage: l4d2_weaponspeed <#userid|Name> <0|1>");
				}
			}
		}
		else if (args > 2)
		{
			ReplyToCommand(client, "[SM] Usage: l4d2_weaponspeed <#userid|Name> <0|1>");
		}
	}
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	//OnPlayerRunCmd seems to work best for this so we can get the right frame to set our values on the players weapon
	if (bWeaponSpeedEnabled && client > 0 && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if (GetConVarInt(WeaponSpeedEnabled) == 1 || WeaponSpeed[client] == 1)
		{
			if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
			{
				GetClientWeapon(client, Name, sizeof(Name));
				if (StrEqual(Name, "weapon_smg") || StrEqual(Name, "weapon_smg_silenced") || StrEqual(Name, "weapon_smg_mp5")
				|| StrEqual(Name, "weapon_rifle") || StrEqual(Name, "weapon_rifle_sg552") || StrEqual(Name, "weapon_rifle_ak47")
				|| StrEqual(Name, "weapon_autoshotgun") || StrEqual(Name, "weapon_shotgun_spas") || StrEqual(Name, "weapon_rifle_m60")
				|| StrEqual(Name, "weapon_sniper_awp") || StrEqual(Name, "weapon_sniper_military") || StrEqual(Name, "weapon_sniper_scout")
				|| StrEqual(Name, "weapon_hunting_rifle") || StrEqual(Name, "weapon_pumpshotgun") || StrEqual(Name, "weapon_shotgun_chrome"))
				{
					AdjustWeaponSpeed(client, fWeaponSpeedAmount, 0);
				}
				else if (StrEqual(Name, "weapon_melee"))
				{
					AdjustWeaponSpeed(client, fWeaponSpeedAmount, 1);
				}
			}
		}
	}
	return Plugin_Continue;
}

stock void AdjustWeaponSpeed(int client, float Amount, int slot)
{
	iSlot = GetPlayerWeaponSlot(client, slot);
	if (iSlot > 0)
	{
		m_flNextPrimaryAttack = GetEntPropFloat(iSlot, Prop_Send, "m_flNextPrimaryAttack");
		m_flNextSecondaryAttack = GetEntPropFloat(iSlot, Prop_Send, "m_flNextSecondaryAttack");
		m_flCycle = GetEntPropFloat(iSlot, Prop_Send, "m_flCycle");
		m_bInReload = GetEntProp(iSlot, Prop_Send, "m_bInReload");
		//Getting the animation cycle at zero seems to be key here, however the scar and pistols weren't seem to be getting affected
		if (m_flCycle == 0.000000 && m_bInReload < 1)
		{
			SetEntPropFloat(iSlot, Prop_Send, "m_flPlaybackRate", Amount);
			SetEntPropFloat(iSlot, Prop_Send, "m_flNextPrimaryAttack", m_flNextPrimaryAttack - ((Amount - 1.0) / 2));
			SetEntPropFloat(iSlot, Prop_Send, "m_flNextSecondaryAttack", m_flNextSecondaryAttack - ((Amount - 1.0) / 2));
			if (!bWeaponSpeedRecoil) SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", NULL_VECTOR); //no recoil
		}
	}
}
