#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

public Plugin myinfo=
{
	name = "WeaponDestroy",
	author = "BHaType(& dr_lex for newdecls and some balance & theproperson translate)",
	description = "Оружие может заклинить в какой-то момент.",
	version = "4.9.9",
	url = "https://steamcommunity.com/id/fallinourblood/"
}

bool IsFucked[2048+1] = false;
int ref[2048+1];
Handle EndLoadBar[MAXPLAYERS+1];
int Shots[MAXPLAYERS+1];
 
ConVar hCountOfShots, hTimerOfOutKlin, HintText;

ConVar MP5, SMG, SMG_Silence, Chrome, Pump, Hunting, M60, AutoShotGun, ShotSpas, Sniper_military, RifleM16, AK47, RifleDesert, SniperAwp, RifleSG552, ScoutSniper, GrenadeLaucnher;

public void OnPluginStart()
{
	HookEvent("weapon_fire", FireBulletsPost);
	
	hTimerOfOutKlin = CreateConVar("vTime", "3.5", "Время расклина(желательно ставить флоат(20.0)");
	hCountOfShots = CreateConVar("vShots", "125", "Кол-во выстрелов для срабатывания шанса");
	HintText = CreateConVar("vIsHint", "1", "Тип сообщения 0 - чат, 1 - хинт", FCVAR_NONE, true, 0.0, true, 1.0);
	
	MP5 = CreateConVar("vChanceMP5", "25" , "Chance 0-100%", FCVAR_NONE);
	SMG = CreateConVar("vChanceUzi", "25" , "Chance 0-100%", FCVAR_NONE);
	SMG_Silence = CreateConVar("vChanceSMG", "25" , "Chance 0-100%", FCVAR_NONE);
	Chrome = CreateConVar("vChanceChrome", "25" , "Chance 0-100%", FCVAR_NONE);
	Pump = CreateConVar("vChancePump", "25" , "Chance 0-100%", FCVAR_NONE);
	Hunting = CreateConVar("vChanceHunting", "25" , "Chance 0-100%", FCVAR_NONE);
	M60 = CreateConVar("vChanceM60", "25" , "Chance 0-100%", FCVAR_NONE);
	AutoShotGun = CreateConVar("vChanceAutoShotGun", "25" , "Chance 0-100%", FCVAR_NONE);
	ShotSpas = CreateConVar("vChanceSpap", "25" , "Chance 0-100%", FCVAR_NONE);
	Sniper_military = CreateConVar("vChanceMilitary", "25" , "Chance 0-100%", FCVAR_NONE);
	RifleM16 = CreateConVar("vChanceM16", "25" , "Chance 0-100%", FCVAR_NONE);
	AK47 = CreateConVar("vChanceAK", "25" , "Chance 0-100%", FCVAR_NONE);
	RifleDesert = CreateConVar("vChanceRifleDesert", "25" , "Chance 0-100%", FCVAR_NONE);
	SniperAwp = CreateConVar("vChanceAwp", "25" , "Chance 0-100%", FCVAR_NONE);
	RifleSG552 = CreateConVar("vChanceSG552", "25" , "Chance 0-100%", FCVAR_NONE);
	ScoutSniper = CreateConVar("vChanceScout", "25" , "Chance 0-100%", FCVAR_NONE);
	GrenadeLaucnher = CreateConVar("vChanceLauncher", "8" , "Chance 0-100%", FCVAR_NONE);
	
	LoadTranslations("WeaponJoked.phrases");
	AutoExecConfig(true, "KlinikaWeapon");
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
    SDKHook(client, SDKHook_WeaponSwitch, WeaponSwitch);
}

public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
    SDKUnhook(client, SDKHook_WeaponSwitch, WeaponSwitch);
    if (EndLoadBar[client] != null)
    {
        KillTimer(EndLoadBar[client]);
        EndLoadBar[client] = null;
    }
}

public Action WeaponSwitch(int client, int weapon)
{
	if (bIsSurvivor(client))
	{
		if (EndLoadBar[client] != null)
		{
			KillTimer(EndLoadBar[client]);
			EndLoadBar[client] = null;
		}
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
    }
	return Plugin_Continue;
}

public Action WeaponCanUse(int client, int weapon)
{
    if (bIsSurvivor(client))
    {
        if (EndLoadBar[client] != null)
        {
            KillTimer(EndLoadBar[client]);
            EndLoadBar[client] = null;
        }
        SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
        SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
    }
    return Plugin_Continue;
}

public Action FireBulletsPost(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
   
	int vSlot = GetPlayerWeaponSlot(client, 0);
	int iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	char sWeaponEx[32];
	GetEntityClassname(iCurrentWeapon, sWeaponEx, sizeof(sWeaponEx));
	
	
	if (bIsSurvivor(client) && !IsFakeClient(client))
	{
		if (iCurrentWeapon == vSlot)
		{
			if (!IsFucked[iCurrentWeapon])
			{
				if (Shots[client] >= GetConVarInt(hCountOfShots))
				{
					if (StrEqual(sWeaponEx, "weapon_sniper_awp"))
					{
						if (GetRandomInt(0, 100) <= GetConVarInt(SniperAwp))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_autoshotgun"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(AutoShotGun))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_grenade_launcher"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(GrenadeLaucnher))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_hunting_rifle"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(Hunting))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_pumpshotgun"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(Pump))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_rifle"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(RifleM16))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_rifle_ak47"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(AK47))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_rifle_desert"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(RifleDesert))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_rifle_m60"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(M60))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_rifle_sg552"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(RifleSG552))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_shotgun_chrome"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(Chrome))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_shotgun_spas"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(ShotSpas))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_smg"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(SMG))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_smg_mp5"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(MP5))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_smg_silenced"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(SMG_Silence))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_sniper_military"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(Sniper_military))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					else if (StrEqual(sWeaponEx, "weapon_sniper_scout"))
					{
						if (GetRandomInt(0, 100) < GetConVarInt(ScoutSniper))
						{
							IsFucked[iCurrentWeapon] = true;
							ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
							if(GetConVarInt(HintText) == 0)
							{
								PrintToChat(client, "%t", "WeaponBroke");
							}
							else
							{
								PrintHintText(client, "%t", "WeaponBroke");
							}
						}
					}
					Shots[client] = 0;
				}
				Shots[client]++;
			}
		}
	}
}
 
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon)
{
    int vSlot = GetPlayerWeaponSlot(client, 0);
    if (!IsValidEntity(vSlot))
    {
        return Plugin_Continue;
    }
    int iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    int FuckedWeapon = EntRefToEntIndex(ref[iCurrentWeapon]);
    if (FuckedWeapon == iCurrentWeapon)
    {
        if (IsFucked[FuckedWeapon])
        {
            if (buttons & IN_ATTACK)
            {
                SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 99999.0);
                SetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flNextPrimaryAttack", 99999.0);
                //buttons &= ~IN_ATTACK;
            }
            else if (buttons & IN_USE)
            {
                if (EndLoadBar[client] == null)
                {
                    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
                    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", GetConVarFloat(hTimerOfOutKlin));
                    Handle vPosition;
                    EndLoadBar[client] = CreateDataTimer(GetConVarFloat(hTimerOfOutKlin), EndBar, vPosition, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
                    WritePackCell(vPosition, FuckedWeapon);
                    WritePackCell(vPosition, client);
                }
            }
            else if (!(buttons & IN_USE))
            {
                if (EndLoadBar[client] != null)
                {
                    KillTimer(EndLoadBar[client]);
                    EndLoadBar[client] = null;
                }
                SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
                SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
            }
        }
        else
        {
            if (EndLoadBar[client] != null)
            {
                KillTimer(EndLoadBar[client]);
                EndLoadBar[client] = null;
                SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
                SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
            }
        }
    }
    return Plugin_Continue;
}
 
public Action EndBar(Handle timer, Handle vPosition)
{
    ResetPack(vPosition);
   
    int IsFuck = ReadPackCell(vPosition);
    int client = ReadPackCell(vPosition);
   
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
    IsFucked[IsFuck] = false;
    SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
    SetEntPropFloat(IsFuck, Prop_Send, "m_flNextPrimaryAttack", 0.0);
    KillTimer(EndLoadBar[client]);
    EndLoadBar[client] = null;
    if(GetConVarInt(HintText) == 0)
	{
		PrintToChat(client, "%t", "HasBeenFixed");
	}
	else
	{
		PrintHintText(client, "%t", "HasBeenFixed");
	}
}
 
stock bool bIsSurvivor(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && !IsClientInKickQueue(client) && IsPlayerAlive(client);
}