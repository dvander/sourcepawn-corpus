#include <sourcemod>
#include <sdktools>

#pragma semicolon 1


static Handle:hEnabled;
static bool:bEnabled = false;
static Handle:kvEffects = INVALID_HANDLE;
static String:VaultPath[PLATFORM_MAX_PATH];
static Float:fMaxSpeed[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Speshial Weapons Mod",
	author = "Jaro 'Monkeys' Vanderheijden",
	description = "A simply manageable plugin that adds additional effects to weapons",
	version = "1.3",
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	PrintToConsole(0, "[SWM] Speshial Weapons Mod initiated.");
	
	RegAdminCmd("sm_swm_seteffect", SetEffect, ADMFLAG_SLAY);
	
	HookEvent("player_spawn", EventSpawn);
	HookEvent("player_hurt", EventHurt);
	
	hEnabled = CreateConVar("sm_swm_enabled", "1", "Enable or disable Speshial Weapons Mod");
	CreateConVar("sm_swm_version", "1.3", "Version of the Speshial Weapons Mod", FCVAR_NOTIFY);
	
	BuildPath(Path_SM, VaultPath, sizeof(VaultPath), "data/swm_effects.txt");
	if(FileExists(VaultPath) == false) SetFailState("[JPH] ERROR: Missing file '%s'", VaultPath);
	
}

public Action:SetEffect(Client, Args)
{
	if (Args < 2)
	{
		ReplyToCommand(Client,"[SWM] Set Effect Syntax: sm_swm_seteffect weapon_<name> <effect name>");
	}
	decl String:sWeapon[64];
	decl String:sEffect[64];
	
	GetCmdArg(1, sWeapon, sizeof(sWeapon));
	GetCmdArg(2, sEffect, sizeof(sEffect));
	
	KvSetString(kvEffects, sWeapon, sEffect);
	KeyValuesToFile(kvEffects, VaultPath);
	
	return Plugin_Handled;
}

public OnMapStart()
{	
	bEnabled = GetConVarBool(hEnabled);
	
	if(kvEffects != INVALID_HANDLE)
	{
		CloseHandle(kvEffects);
		kvEffects = INVALID_HANDLE;
	}
	kvEffects = CreateKeyValues("Effects");
	FileToKeyValues(kvEffects,VaultPath);
}

public Action:EventSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
	if (bEnabled)
	{
		new Client;
		Client = GetClientOfUserId(GetEventInt(Event, "userid"));

		//When a player spawns, all attributes should be set to normal.
		if (Client > 0) ExecEffect(Client);
	}
	return Plugin_Continue;
}

public Action:EventHurt(Handle:Event, const String:Name[], bool:Broadcast)
{
	//Only do anything if the plugin is active
	if (bEnabled)
	{
		new Client,Attacker,Health;
		Client = GetClientOfUserId(GetEventInt(Event, "userid"));
		Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
		Health = GetEventInt(Event,"health");
		
		//When the client and attacker are the same or noone, nothing should happen.
		if(Attacker == 0 || Client == 0 || Attacker == Client || Health <= 0)
			return Plugin_Continue;
	
		decl String:sWeapon[64];
		GetClientWeapon(Attacker, sWeapon, sizeof(sWeapon));

		ExecEffect(Client, Attacker, sWeapon);
	}
	
	return Plugin_Continue;
}

ExecEffect(Client, Attacker = 0, const String:sWeapon[] = "weapon_physcannon")
{
	decl String:sEffect[64];
	KvGetString(kvEffects, sWeapon, sEffect, sizeof(sEffect), "normal");
	
	if(StrEqual(sEffect, "normal", false))
	{
		SetEntityMoveType(Client, MOVETYPE_ISOMETRIC);
		SetEntityRenderMode(Client, RENDER_NORMAL);
		SetEntityRenderColor(Client, 255, 255, 255, 255);
		ClientCommand(Client, "r_screenoverlay 0");
		fMaxSpeed[Client] = 190.0;
	} else
	if(StrEqual(sEffect, "blind", false))
	{
		ClientCommand(Client, "r_screenoverlay tp_eyefx/tp_black");
		SetEntityRenderColor(Client, 0, 0, 0, 255);
	} else
	if(StrEqual(sEffect, "stop", false))
	{
		ClientCommand(Client, "r_screenoverlay debug/yuv");
		SetEntityMoveType(Client, MOVETYPE_NONE);
		SetEntityRenderColor(Client, 30, 30, 30, 255);
	} else
	if(StrEqual(sEffect, "slow", false))
	{
		ClientCommand(Client, "r_screenoverlay debug/yuv");
		fMaxSpeed[Client] = 60.0;
		SetEntityRenderColor(Client, 0, 0, 0, 125);
	} else
	if(StrEqual(sEffect, "daze", false))
	{
		ClientCommand(Client, "r_screenoverlay tp_eyefx/tp_eyefx");	 
		SetEntityRenderColor(Client, 0, 0, 255, 255);
	} else
	if(StrEqual(sEffect, "disorient", false))
	{
		ClientCommand(Client, "r_screenoverlay tp_eyefx/tpeye3");
		decl Float:Angles[3];
		Angles[0] = GetRandomFloat(0.0, 360.0);
		Angles[1] = GetRandomFloat(0.0, 360.0);
		Angles[2] = GetRandomFloat(-50.0, 50.0);
		TeleportEntity(Client, NULL_VECTOR, Angles, NULL_VECTOR);
	} else
	if(StrEqual(sEffect, "speed", false))
	{
		ClientCommand(Client, "r_screenoverlay tp_eyefx/tpeye2");
		fMaxSpeed[Client] = 380.0;
		SetEntityRenderColor(Client, 255, 0, 0, 0);
	} else
	if(StrEqual(sEffect, "bump", false))
	{
		decl Float:Vel[3] = {0.0,0.0,500.0};
		TeleportEntity(Client, NULL_VECTOR, NULL_VECTOR, Vel);
	} else
	if(StrEqual(sEffect, "disarm", false))
	{
		decl Offset;
		Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
		
		decl WeaponId;
		for(new X = 0; X < 20; X = (X + 4))
		{
			WeaponId = GetEntDataEnt2(Client, Offset + X);
			if(WeaponId > 0)
			{
				RemovePlayerItem(Client, WeaponId);
				RemoveEdict(WeaponId);
			}
		}
		SetEntityRenderColor(Client, 0, 255, 0, 255);
	} else
	if(StrEqual(sEffect, "ggswitch", false))
	{
		ClientCommand(Client, "use weapon_physcannon");
	} else
	if(StrEqual(sEffect, "fly", false))
	{
		SetEntityMoveType(Client, MOVETYPE_FLYGRAVITY);
		SetEntityRenderColor(Client, 255, 125, 0, 255);
	} else
	if(StrEqual(sEffect, "drain", false))
	{
		DealDamage(Client, 3, Attacker, (1 << 20), "drain");
		SetEntityHealth(Attacker, (GetClientHealth(Attacker) + 3 > 100)? 100 : (GetClientHealth(Attacker) + 3));
	}
	/* Possibility for more, perhaps even on the attacker */
}

public Action:OnPlayerRunCmd(Client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static bHasSprinted[MAXPLAYERS+1];
	if(buttons & IN_SPEED)
	{
		if(!bHasSprinted[Client])
		{
			SetEntPropFloat(Client, Prop_Data, "m_flMaxspeed", 320.0 + (fMaxSpeed[Client] - 190.0));
			bHasSprinted[Client] = true;
		}
	} else
	if(bHasSprinted[Client])
	{
		SetEntPropFloat(Client, Prop_Data, "m_flMaxspeed", fMaxSpeed[Client]);
		bHasSprinted[Client] = false;
	}
	return Plugin_Continue;
}

stock DealDamage(victim, damage, attacker = 0, dmg_type = 0, String:weapon[]="")
{
    if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
    {
        new String:dmg_str[16];
        IntToString(damage,dmg_str,16);
        new String:dmg_type_str[32];
        IntToString(dmg_type,dmg_type_str,32);
        new PointHurt = CreateEntityByName("point_hurt");
        if(PointHurt)
        {
            DispatchKeyValue(victim,"targetname","dmged_target");
            DispatchKeyValue(PointHurt,"DamageTarget","dmged_target");
            DispatchKeyValue(PointHurt,"Damage",dmg_str);
            DispatchKeyValue(PointHurt,"DamageType",dmg_type_str);
            if(!StrEqual(weapon,""))
            {
                DispatchKeyValue(PointHurt,"classname",weapon);
            }
            DispatchSpawn(PointHurt);
            AcceptEntityInput(PointHurt,"Hurt",(attacker>0)?attacker:-1);
            DispatchKeyValue(PointHurt,"classname","point_hurt");
            DispatchKeyValue(victim,"targetname","nondmged_target");
            RemoveEdict(PointHurt);
        }
    }
}