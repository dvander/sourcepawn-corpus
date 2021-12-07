

/*
* SourceMod Hosties Project
* by: databomb & dataviruset
*
* This file is part of the SM Hosties project.
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the GNU General Public License, version 3.0, as published by the
* Free Software Foundation.
* 
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
* details.
*
* You should have received a copy of the GNU General Public License along with
* this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// Sample Last Request Plugin: Shotgun Wars!

#include <sourcemod>
#include <sdktools>
// Make certain the lastrequest.inc is last on the list
#include <hosties>
#include <lastrequest>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.3"

// This global will store the index number for the new Last Request
new g_LREntryNum;

new String:g_sLR_Name[64];

new Handle:gH_Timer_GiveHealth = INVALID_HANDLE;
new Handle:gH_Timer_Countdown = INVALID_HANDLE;

new Handle:gH_StartHP = INVALID_HANDLE;
new Handle:gH_StartClip = INVALID_HANDLE;
new Handle:gH_StartAmmo = INVALID_HANDLE;
new Handle:gH_RegenerateHP = INVALID_HANDLE;
new Handle:gH_HP = INVALID_HANDLE;
new Handle:gH_Time = INVALID_HANDLE;
new StartHP;
new StartClip;
new StartAmmo;
new bool:RegenerateHP;
new HPToRegen;
new Float:TimeToWait;

new bool:bAllCountdownsCompleted = false;

enum theColors
{
	color_Red = 0,
	color_Green,
	color_Blue
};

public Plugin:myinfo =
{
	name = "Last Request: Shotgun Wars (Fixed)",
	author = "databomb & dataviruset & TimeBomb",
	description = "An example of how to add LRs",
	version = PLUGIN_VERSION,
	url = "vintagejailbreak.org"
};

public OnPluginStart()
{
	// Load translations
	LoadTranslations("shotgunwars.phrases");
	
	// Load the name in default server language
	Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "Shotgun Wars", LANG_SERVER);
	
	// Create any cvars you need here
	gH_StartHP = CreateConVar("sm_lr_shotgunwars_hp", "250", "HP to start the LR with", FCVAR_PLUGIN, true, 100.0, false);
	StartHP = GetConVarInt(gH_StartHP);
	HookConVarChange(gH_StartHP, Hookconvar);
	
	gH_StartClip = CreateConVar("sm_lr_shotgunwars_clip", "8", "Shotgun clips to start the LR with", FCVAR_PLUGIN);
	StartClip = GetConVarInt(gH_StartClip);
	HookConVarChange(gH_StartClip, Hookconvar);
	
	gH_StartAmmo = CreateConVar("sm_lr_shotgunwars_ammo", "9999", "Ammo to start the LR with", FCVAR_PLUGIN);
	StartAmmo = GetConVarInt(gH_StartAmmo);
	HookConVarChange(gH_StartAmmo, Hookconvar);
	
	gH_RegenerateHP = CreateConVar("sm_lr_shotgunwars_regen", "1", "Regenrate HP?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	RegenerateHP = GetConVarBool(gH_RegenerateHP);
	HookConVarChange(gH_RegenerateHP, Hookconvar);
	
	gH_HP = CreateConVar("sm_lr_shotgunwars_regenhp", "1", "HP to regenerate if Regenrate HP enabled", FCVAR_PLUGIN);
	HPToRegen = GetConVarInt(gH_HP);
	HookConVarChange(gH_HP, Hookconvar);
	
	gH_Time = CreateConVar("sm_lr_shotgunwars_regentime", "2.0", "[FLOAT] Time to wait before each HP regeneration.", FCVAR_PLUGIN, true, 1.0);
	TimeToWait = GetConVarFloat(gH_Time);
	HookConVarChange(gH_Time, Hookconvar);
	
	AutoExecConfig();
}

public Hookconvar(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_StartHP)
	{
		StartHP = StringToInt(newVal);
	}
	
	else if(cvar == gH_StartClip)
	{
		StartClip = StringToInt(newVal);
	}
	
	else if(cvar == gH_StartAmmo)
	{
		StartAmmo == StringToInt(newVal);
	}
	
	else if(cvar == gH_RegenerateHP)
	{
		RegenerateHP = StringToInt(newVal)? true:false;
	}
	
	else if(cvar == gH_HP)
	{
		HPToRegen = StringToInt(newVal);
	}
	
	else if(cvar == gH_Time)
	{
		TimeToWait = StringToFloat(newVal);
		if(gH_Timer_GiveHealth != INVALID_HANDLE && RegenerateHP)
		{
			ClearTimer(gH_Timer_GiveHealth);
			gH_Timer_GiveHealth = CreateTimer(TimeToWait, Timer_GiveHealth, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

stock ClearTimer(Handle:Timer)
{
	CloseHandle(Timer);
	Timer = INVALID_HANDLE;
}

public OnConfigsExecuted()
{
	static bool:bAddedShotgunWars = false;
	if (!bAddedShotgunWars)
	{
		g_LREntryNum = AddLastRequestToList(ShotgunWars_Start, ShotgunWars_Stop, g_sLR_Name);
		bAddedShotgunWars = true;
	}       
}

// The plugin should remove any LRs it loads when it's unloaded
public OnPluginEnd()
{
	RemoveLastRequestFromList(ShotgunWars_Start, ShotgunWars_Stop, g_sLR_Name);
}

public ShotgunWars_Start(Handle:LR_Array, iIndexInArray)
{
	new This_LR_Type = GetArrayCell(LR_Array, iIndexInArray, _:Block_LRType);
	if (This_LR_Type == g_LREntryNum)
	{               
		new LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner);
		new LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, _:Block_Guard);
		
		// check datapack value
		new LR_Pack_Value = GetArrayCell(LR_Array, iIndexInArray, _:Block_Global1);     
		switch (LR_Pack_Value)
		{
			case -1:
			{
				PrintToServer("no info included");
			}
		}
		
		SetEntityHealth(LR_Player_Prisoner, StartHP);
		SetEntityHealth(LR_Player_Guard, StartHP);
		
		StripAllWeapons(LR_Player_Prisoner);
		StripAllWeapons(LR_Player_Guard);
		
		// Store a countdown timer variable - we'll use 3 seconds
		SetArrayCell(LR_Array, iIndexInArray, 3, _:Block_Global1);
		
		if (gH_Timer_Countdown == INVALID_HANDLE)
		{
			gH_Timer_Countdown = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		
		PrintToChatAll(CHAT_BANNER, "LR SGW Start", LR_Player_Prisoner, LR_Player_Guard);
	}
}

public ShotgunWars_Stop(This_LR_Type, LR_Player_Prisoner, LR_Player_Guard)
{
	if (This_LR_Type == g_LREntryNum)
	{
		if (IsClientInGame(LR_Player_Prisoner))
		{
			SetEntityGravity(LR_Player_Prisoner, 1.0);
			if (IsPlayerAlive(LR_Player_Prisoner))
			{
				SetEntityHealth(LR_Player_Prisoner, 100);
				GivePlayerItem(LR_Player_Prisoner, "weapon_knife");
				PrintToChatAll(CHAT_BANNER, "SGW Win", LR_Player_Prisoner);
			}
		}
		if (IsClientInGame(LR_Player_Guard))
		{
			SetEntityGravity(LR_Player_Guard, 1.0);
			if (IsPlayerAlive(LR_Player_Guard))
			{
				SetEntityHealth(LR_Player_Guard, 100);
				GivePlayerItem(LR_Player_Guard, "weapon_knife");
				PrintToChatAll(CHAT_BANNER, "SGW Win", LR_Player_Guard);
			}
		}
	}
}

public Action:Timer_Countdown(Handle:timer)
{
	new numberOfLRsActive = ProcessAllLastRequests(ShotgunWars_Countdown, g_LREntryNum);
	if ((numberOfLRsActive <= 0) || bAllCountdownsCompleted)
	{
		gH_Timer_Countdown = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_GiveHealth(Handle:timer)
{
	// Sort through all last requests
	new numberOfLRsActive = ProcessAllLastRequests(ShotgunWars_Heal, g_LREntryNum); 
	if (numberOfLRsActive <= 0)
	{
		gH_Timer_GiveHealth = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public ShotgunWars_Countdown(Handle:LR_Array, iIndexInArray)
{
	new LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner);
	new LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, _:Block_Guard);
	
	new countdown = GetArrayCell(LR_Array, iIndexInArray, _:Block_Global1);
	if (countdown > 0)
	{
		bAllCountdownsCompleted = false;
		PrintCenterText(LR_Player_Prisoner, "LR begins in %i...", countdown);
		PrintCenterText(LR_Player_Guard, "LR begins in %i...", countdown);
		SetArrayCell(LR_Array, iIndexInArray, --countdown, _:Block_Global1);            
	}
	else if (countdown == 0)
	{
		bAllCountdownsCompleted = true;
		SetArrayCell(LR_Array, iIndexInArray, --countdown, _:Block_Global1);    
		
		new PrisonerGun = GivePlayerItem(LR_Player_Prisoner, "weapon_xm1014");
		new GuardGun = GivePlayerItem(LR_Player_Guard, "weapon_xm1014");
		
		SetArrayCell(LR_Array, iIndexInArray, PrisonerGun, _:Block_PrisonerData);
		SetArrayCell(LR_Array, iIndexInArray, GuardGun, _:Block_GuardData);
		
		SetEntityRenderFx(PrisonerGun, RenderFx:RENDERFX_DISTORT);
		SetEntityRenderFx(GuardGun, RenderFx:RENDERFX_DISTORT);
		
		SetEntityRenderColor(PrisonerGun, 255, 0, 0, 255);
		SetEntityRenderColor(GuardGun, 255, 0, 0, 255);
		
		SetEntityGravity(LR_Player_Prisoner, 0.7);
		SetEntityGravity(LR_Player_Guard, 0.7);
		
		SetEntData(PrisonerGun, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), StartClip);
		SetEntData(PrisonerGun, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), StartClip);
		
		new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
		
		SetEntData(LR_Player_Prisoner, ammoOffset+(7*4), StartAmmo);
		SetEntData(LR_Player_Guard, ammoOffset+(7*4), StartAmmo);
		
		if(RegenerateHP && gH_Timer_GiveHealth == INVALID_HANDLE)
		{
			gH_Timer_GiveHealth = CreateTimer(TimeToWait, Timer_GiveHealth, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public ShotgunWars_Heal(Handle:LR_Array, iIndexInArray)
{
	new Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner);
	new Guard = GetArrayCell(LR_Array, iIndexInArray, _:Block_Guard);
	
	new PHP = GetClientHealth(Prisoner);
	new GHP = GetClientHealth(Guard);
	
	if(PHP < GetConVarInt(gH_StartHP))
	{
		SetEntityHealth(Prisoner, PHP + HPToRegen);
	}
	if(GHP < GetConVarInt(gH_StartHP))
	{
		SetEntityHealth(Guard, GHP + HPToRegen);
	}
	
	new PrisonerGun = GetArrayCell(LR_Array, iIndexInArray, _:Block_PrisonerData);
	new GuardGun = GetArrayCell(LR_Array, iIndexInArray, _:Block_GuardData);
	
	static randomColor = _:color_Red;
	
	switch (randomColor % 3)
	{
		case color_Red:
		{
			SetEntityRenderColor(PrisonerGun, 255, 0, 0, 255);
			SetEntityRenderColor(GuardGun, 255, 0, 0, 255);
		}
		case color_Green:
		{
			SetEntityRenderColor(PrisonerGun, 0, 255, 0, 255);
			SetEntityRenderColor(GuardGun, 0, 255, 0, 255);         
		}
		case color_Blue:
		{
			SetEntityRenderColor(PrisonerGun, 0, 0, 255, 255);
			SetEntityRenderColor(GuardGun, 0, 0, 255, 255);
		}
	}
	
	randomColor++;
}