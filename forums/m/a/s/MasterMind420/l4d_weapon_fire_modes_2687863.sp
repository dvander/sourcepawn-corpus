//If Burst Mode check clip if less than 2 do normal single fire
//Check clip make sure its greater than 0 or dont unlock???
/* >>> CHANGELOG <<< //
[ v1.0 ]
Initial Release

[ v1.1 ]
Fixed - Mode switch PrintToChat on unsupported weapons

Changed - Weapon checks have been moved around and optimized somewhat
		  Moved function code from PostThink to OnPlayerRunCmd
		  Renamed plugin file to l4d_weapon_fire_modes(delete v1.0 from your plugins directory)

Features - Added L4D1 support
		   Added late load support

[ v1.2 ]
Fixed - Burst fire for pistols is now as intended
		Burst fire bug when 1 bullet in clip and then reloading

Changed - Reworked most of the function code to optimize and correct the way it was intended to function
		  You must now release the fire button before the gun continues to fire in single and burst mode
		  Optimized some of the code thanks to Silvers suggestions

Features - Added Semi Auto mode for pistols
		   Added Burst mode bullet count option (Dragokas)
		   Added l4d_weapon_fire_modes.cfg

[ v1.3 ]
Fixed - Switching multiple guns in a slot breaks changing fire modes

Changed -

Features -

// >>> CHANGELOG <<< */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

static EngineVersion game;
static int iMode[2048+1], iCount[MAXPLAYERS+1], iWeaponId[MAXPLAYERS+1];
static const char SOUND_MODECHANGE[] = "^ui/menu_accept.wav", sClsName[MAXPLAYERS+1][32];
ConVar BurstCount;

public Plugin myinfo =
{
	name = "[L4D/L4D2] Weapon Fire Modes",
	author = "MasterMind420",
	description = "",
	version = "1.3",
	url = ""
}

public void OnPluginStart()
{
	BurstCount = CreateConVar("l4d_burst_count", "2", "Number of bullets fired in burst mode", FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d_weapon_fire_modes");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	game = GetEngineVersion();

	if (game != Engine_Left4Dead && game != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnMapStart()
{
	PrefetchSound(SOUND_MODECHANGE);
	PrecacheSound(SOUND_MODECHANGE, true);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnWeaponSwitchPost(int client, int weapon)
{
	iCount[client] = 0;
	iWeaponId[client] = 0;

	weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if (weapon > MaxClients && IsValidEntity(weapon))
	{
		iWeaponId[client] = weapon;
		GetEntityClassname(weapon, sClsName[client], sizeof(sClsName));
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		static int iWeapon;
		iWeapon = iWeaponId[client];

		if (iWeapon > MaxClients && IsValidEntity(iWeapon))
		{
			if (strcmp(sClsName[client][7], "rifle_desert") == 0 || StrContains(sClsName[client], "sniper") > -1)
				return;

			if (strncmp(sClsName[client][7], "pistol", 6) == 0 || StrContains(sClsName[client], "smg") > -1 || StrContains(sClsName[client], "rifle") > -1)
			{
				if (GetEntProp(client, Prop_Data, "m_afButtonPressed") & IN_ZOOM)
				{
					iCount[client] = 0;
					iMode[iWeapon] += 1;

					SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.01);
					EmitSoundToClient(client, SOUND_MODECHANGE, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);

					switch (iMode[iWeapon])
					{
						case 0:
						{
							if (strncmp(sClsName[client][7], "pistol", 6) == 0)
								PrintToChat(client, "\x04[FIRE MODE] \x01Single");
							else
								PrintToChat(client, "\x04[FIRE MODE] \x01Auto");
						}
						case 1:
						{
							if (strncmp(sClsName[client][7], "pistol", 6) == 0)
								PrintToChat(client, "\x04[FIRE MODE] \x01Auto");
							else
								PrintToChat(client, "\x04[FIRE MODE] \x01Single");
						}
						case 2:
						{
							PrintToChat(client, "\x04[FIRE MODE] \x01Burst");
						}
						case 3:
						{
							if (strncmp(sClsName[client][7], "pistol", 6) == 0)
								PrintToChat(client, "\x04[FIRE MODE] \x01Semi-Auto");
							else
							{
								iMode[iWeapon] = 0;
								PrintToChat(client, "\x04[FIRE MODE] \x01Auto");
							}
						}
						default:
						{
							iMode[iWeapon] = 0;

							if (strncmp(sClsName[client][7], "pistol", 6) == 0)
								PrintToChat(client, "\x04[FIRE MODE] \x01Single");
							else
								PrintToChat(client, "\x04[FIRE MODE] \x01Auto");
						}
					}
				}

				if (buttons & IN_ATTACK)
				{
					if (game == Engine_Left4Dead2)
					{
						if (GetEntProp(client, Prop_Send, "m_usingMountedGun") > 0 || GetEntProp(client, Prop_Send, "m_usingMountedWeapon") > 0)
							return;
					}

					if (GetEntProp(client, Prop_Data, "m_afButtonPressed") & IN_ATTACK2 || GetEntPropFloat(iWeapon, Prop_Send, "m_flCycle") > 0)
						return;

					if (GetEntProp(iWeapon, Prop_Send, "m_bInReload") > 0)
					{
						iCount[client] = 0;
						return;
					}

					static float fRate;
					iCount[client] += 1;

					switch (iMode[iWeapon])
					{
						case 0: //NORMAL
							iCount[client] = 0;
						case 1:
						{
							if (strncmp(sClsName[client][7], "pistol", 6) == 0) //AUTO
							{
								fRate = 0.2;

								if (StrEqual(sClsName[client], "weapon_pistol_magnum"))
									fRate = 0.4;

								SetEntProp(iWeapon, Prop_Send, "m_isHoldingFireButton", 0);
								ChangeEdictState(iWeapon, FindDataMapInfo(iWeapon, "m_isHoldingFireButton"));

								SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + fRate);
								ChangeEdictState(iWeapon, FindDataMapInfo(iWeapon, "m_flNextPrimaryAttack"));
							}
							else //SINGLE
							{
								if (iCount[client] >= 1)
								{
									iCount[client] = 0;

									SetEntProp(iWeapon, Prop_Send, "m_isHoldingFireButton", 0);
									ChangeEdictState(iWeapon, FindDataMapInfo(iWeapon, "m_isHoldingFireButton"));

									SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 999.0);
									ChangeEdictState(iWeapon, FindDataMapInfo(iWeapon, "m_flNextPrimaryAttack"));
								}
							}
						}
						case 2: //BURST
						{
							if (strncmp(sClsName[client][7], "pistol", 6) == 0)
							{
								if (iCount[client] < GetConVarInt(BurstCount))
								{
									SetEntProp(iWeapon, Prop_Send, "m_isHoldingFireButton", 0);
									ChangeEdictState(iWeapon, FindDataMapInfo(iWeapon, "m_isHoldingFireButton"));
								}
								else
									iCount[client] = 0;
							}
							else
							{
								if (iCount[client] >= GetConVarInt(BurstCount))
								{
									iCount[client] = 0;

									SetEntProp(iWeapon, Prop_Send, "m_isHoldingFireButton", 0);
									ChangeEdictState(iWeapon, FindDataMapInfo(iWeapon, "m_isHoldingFireButton"));

									SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 999.0);
									ChangeEdictState(iWeapon, FindDataMapInfo(iWeapon, "m_flNextPrimaryAttack"));
								}
							}
						}
						case 3: //PISTOL SEMI AUTO
						{
							fRate = 0.5;

							if (StrEqual(sClsName[client], "weapon_pistol_magnum"))
								fRate = 1.0;

							SetEntProp(iWeapon, Prop_Send, "m_isHoldingFireButton", 0);
							ChangeEdictState(iWeapon, FindDataMapInfo(iWeapon, "m_isHoldingFireButton"));

							SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + fRate);
							ChangeEdictState(iWeapon, FindDataMapInfo(iWeapon, "m_flNextPrimaryAttack"));
						}
					}
				}
				else if (GetEntProp(client, Prop_Data, "m_afButtonReleased") == IN_ATTACK)
				{
					iCount[client] = 0;
					SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.01);
				}
			}
		}
	}
}