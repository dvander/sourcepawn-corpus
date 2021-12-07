#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

public Plugin myinfo=
{
	name = "WeaponDestroy",
	author = "BHaType(& dr_lex for newdecls and some balance)",
	description = "The weapon may jam at some point",
	version = "4.9.2",
	url = "https://steamcommunity.com/id/fallinourblood/"
}

bool IsFucked[2048+1] = false;
int ref[2048+1];
Handle EndLoadBar[MAXPLAYERS+1];
int Shots[MAXPLAYERS+1];
 
ConVar hChanceOfKlin, hCountOfShots, hTimerOfOutKlin, HintText;

public void OnPluginStart()
{
	HookEvent("weapon_fire", FireBulletsPost);
	hChanceOfKlin = CreateConVar("vChance", "50", "The chance of weapons jamming from 0 to 100");
	hCountOfShots = CreateConVar("vShots", "150", "Number of shots to trigger a chance");
	hTimerOfOutKlin = CreateConVar("vTime", "3.5", "Number of seconds to fix the weapon");
	HintText = CreateConVar("vIsHint", "1", "Message type 0 - chat, 1 - hint", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "WeaponDestroy");
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
   
    if (!(StrEqual(sWeaponEx, "weapon_sniper_awp") || StrEqual(sWeaponEx, "weapon_sniper_scout")))
    {
        if (iCurrentWeapon == vSlot)
        {
            if (bIsSurvivor(client) && !IsFakeClient(client))
            {
                if (!IsFucked[iCurrentWeapon])
                {
                    if (Shots[client] > GetConVarInt(hCountOfShots))
                    {
                        if (GetRandomInt(0, 100) < GetConVarInt(hChanceOfKlin))
                        {
                            IsFucked[iCurrentWeapon] = true;
                            ref[iCurrentWeapon] = EntIndexToEntRef(iCurrentWeapon);
                            if(GetConVarInt(HintText) == 0)
                            {
                            	PrintToChat(client, "Your weapon is jammed, press E to fix");
                            }
                            else
                            {
                            	PrintHintText(client, "Your weapon is jammed, press E to fix");
                            }
                        }
                        Shots[client] = 0;
                    }
                    Shots[client]++;
                }
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
}
 
stock bool bIsSurvivor(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && !IsClientInKickQueue(client) && IsPlayerAlive(client);
}