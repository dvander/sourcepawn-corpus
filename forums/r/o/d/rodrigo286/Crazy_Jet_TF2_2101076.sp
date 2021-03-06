/*
Description:

Allows pyro to use JETPACK when hold space bar.  (Mr Troll)

This plugin is based from the after burner ability from the RMF ability pack.
https://forums.alliedmods.net/showthread.php?t=99871

This plugin requested by member Vadia111.

Version 1.0.0 ( I made a non-complete re-write, 90%+ re-writed. )
Version 1.0.1 ( 100% re-write )
Version 1.0.2 ( Some bug fixes and css support )
Version 1.0.3 ( Some bug fixes, improve plugin, more game support, clean code and added advanced jet control (beta) )

Commands:

Hold the jump button | Fly with jet
Hold the jump, forward, back, left and right buttons | Fly with jet [Advanced control (beta)]
sm_jet | Take one jet
sm_jetinfo | Show fuel info on player HUD

CVARs:

sm_cjet_enabled 0 / 1 Crazy Jet plugin enabled? (DEF. 1)
sm_cjet_adminonly 0 / 1 Crazy Jet for admins only? (DEF. 0)
sm_cjet_adminflag ADMFLAG* If adminonly is enabled, put here a flag for filter users (DEF. b)
sm_cjet_unlimited 0 / 1 / 2 Unlimited fuel. 0 dont unlimited / 1 all / 2 adm only (DEF. 0)
sm_cjet_force 100 / 1000 Jet fly force (DEF. 450)
sm_cjet_fuel 10.0 / 1000.0 Fuel of jet. -1/s if flying (DEF. 200.0)
sm_cjet_time 0.0 / 1000.0 Time to jet charge (DEF. 5.0)
sm_cjet_reset_respawn 0 / 1 Reset jet fuel on player respawn? (DEF. 0)
sm_cjet_win_allow 0 / 1 Allow use Jet on round end? (DEF. 0) | TF2 ONLY
sm_cjet_intel_allow 0 / 1 Allow use Jet while carry intel? (DEF. 0) | TF2 ONLY
sm_cjet_allow_scout 0 / 1 Allow scout use jet? (DEF. 1) | TF2 ONLY
sm_cjet_allow_sniper 0 / 1 Allow sniper use jet? (DEF. 1) | TF2 ONLY
sm_cjet_allow_soldier 0 / 1 Allow soldier use jet? (DEF. 1) | TF2 ONLY
sm_cjet_allow_demoman 0 / 1 Allow demoman use jet? (DEF. 1) | TF2 ONLY
sm_cjet_allow_medic 0 / 1 Allow medic use jet? (DEF. 1) | TF2 ONLY
sm_cjet_allow_heavy 0 / 1 Allow heavy use jet? (DEF. 1) | TF2 ONLY
sm_cjet_allow_pyro 0 / 1 Allow pyro use jet? (DEF. 1) | TF2 ONLY
sm_cjet_allow_spy 0 / 1 Allow spy use jet? (DEF. 1) | TF2 ONLY
sm_cjet_allow_engineer 0 / 1 Allow engineer use jet? (DEF. 1) | TF2 ONLY
sm_cjet_fly_sound "SOUND" Sound of jet fly [DEF. ambient/boiler_01.wav (TF2)] | [DEF. ambient/machines/gas_loop_1.wav (CSS)]
sm_cjet_reload_sound "SOUND" Sound if jet reload the fuel [DEF. weapons/recon_ping.wav (TF2)] | [DEF. buttons/weapon_confirm.wav (CSS)]
sm_cjet_empty_sound "SOUND" Sound if jet empty of fuel [DEF. weapons/buffed_off.wav (TF2)] | [DEF. buttons/weapon_cant_buy.wav (CSS)]
sm_cjet_primary_particle TF2 particle Base particle effect (DEF. burningplayer_rainbow_OLD) | TF2 ONLY
sm_cjet_secondary_particle TF2 particle Secondary particle effect (DEF. burningplayer_rainbow_stars) | TF2 ONLY
sm_cjet_adv_control 0 / 1 Advanced jet control? (beta) (DEF. 0)
sm_cjet_allow_tr 0 / 1 Allow terrorists use jet? (DEF. 1) | CSS ONLY
sm_cjet_allow_ct 0 / 1 Allow counter-terrorists use jet? (DEF. 1) | CSS ONLY
sm_cjet_fly_keys 0 / 1 Keys to fly. 0 default (jump) / 1 custom (jump + mouse attack2) (DEF. 0)
sm_cjet_fuel_info 0 / 1 Fuel on HUD. 0 default (text) / 1 custom (splash bar) (DEF. 0)
sm_cjet_version - Current plugin version

*ADMFLAG: a, b, c, d, e, f, g, i, j, k, l, m, n, o, p, q, r, s, t and z.

[OB] Full Particle List [7/21/13] by Sreaper ==> https://forums.alliedmods.net/showthread.php?t=127111

Credits:

Plugin re-write - Rodrigo286
Idea - Vadia111
New fly method based on despirator jetpack for ZR.

Changelog:

* Version 1.0.0 *
Initial Release

* Version 1.0.1 *
Complete 100% re-write with new fly method
New cvars
New features
Clean code
All TF2 class support
HUD Info added
More commands

* Version 1.0.2 *
Soft fly
New cvars
Clean code
Particles/Condition effects
Support custom fly sounds
Code organized with includes
Counter-Strike Source Support added (alpha)

* Version 1.0.3 *
Some bug fixes
New cvars
Clean code
Improve plugin
Support custom reload and empty sounds
Added advanced jet control (beta)
Counter-Strike Global Offensive Support added (alpha)
Now jet consume 0.5% of fuel while player fly
Fuel bar added (tf2 only)
*/
/* 
	Library includes
*/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#pragma semicolon 1
/* 
	Internal includes
*/
#include "crazy_jet/TF2_effects"
#include "crazy_jet/tools"
#include "crazy_jet/adminflag"
#include "crazy_jet/TF2_cvars"
#include "crazy_jet/TF2_fuelinfo"
#include "crazy_jet/TF2_weaponsmisc"
/* 
	Current plugin version
*/
#define PLUGIN_VERSION "1.0.3"
/*
	Enums
*/
enum {
	FlagEvent_PickedUp = 1,
	FlagEvent_Captured,
	FlagEvent_Defended,
	FlagEvent_Dropped
};
/* 
	Plugin info
*/
public Plugin:myinfo = 
{
	name = "SM Crazy Jet",
	author = "Rodrigo286",
	description = "Jet ability for fun gameplay",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=235576"
}

public OnPluginStart()
{
// #----------------------------------------------HOOK PLAYER SPAWN--------------------------------------------------#
	HookEvent("player_spawn", OnPlayerSpawn);
// #------------------------------------------------HOOK ROUND END---------------------------------------------------#
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", OnRoundEnd, EventHookMode_PostNoCopy);
// #--------------------------------------------------HOOK INTEL-----------------------------------------------------#
	HookEvent("teamplay_flag_event", OnTakeIntel);
// #------------------------------------------------HOOK CHANGE CLASS------------------------------------------------#
	HookEvent("player_changeclass", OnPlayerChangeClass);
// #---------------------------------------------CVARS CONFIGURATION-------------------------------------------------#
	CreateConVar("sm_cjet_version", PLUGIN_VERSION, "\"SM Crazy Jet\" version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY);
	Init_CVars();
// #------------------------------------------------MAKE COMMANDS----------------------------------------------------#
	RegConsoleCmd("sm_cjet", CallJet);
	RegConsoleCmd("sm_cjetinfo", CallHud);
// #---------------------------------------------------HUD INFO------------------------------------------------------#
	CreateTimer(0.3, PJetHUDInfo, _, TIMER_REPEAT);
}

public OnConfigsExecuted() 
{
/*
	Precache and Download some sounds
*/
	if(!StrEqual(FlySound, ""))
	{
		PrecacheSound(FlySound);
		decl String:path[256];
		FormatEx(path, sizeof(path), "sound/%s", FlySound);
		AddFileToDownloadsTable(path);
	}

	if(!StrEqual(ReloadSound, ""))
	{
		PrecacheSound(ReloadSound);
		decl String:path[256];
		FormatEx(path, sizeof(path), "sound/%s", ReloadSound);
		AddFileToDownloadsTable(path);
	}

	if(!StrEqual(EmptySound, ""))
	{
		PrecacheSound(EmptySound);
		decl String:path[256];
		FormatEx(path, sizeof(path), "sound/%s", EmptySound);
		AddFileToDownloadsTable(path);
	}
}

public Action:OnPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return;

	Flying[client] = false;
	RoundEnd = false;
	HaveIntel[client] = false;
	if(ResetOnSpawn)
	{
		Activated[client] = false;
		jetUses[client] = JetMaxUses;
	}
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!WinAllow && IsValidClient(i) && HaveJet[i] && !RoundEnd)
		{
			RoundEnd = true;
			PrintToChat(i, "\x03[\x04SM: Crazy Jet\x03] \x01Jet blocked on round end !");
		}
	}
}

public OnTakeIntel(Handle:event, const String:name[], bool:dontBroadcast)
{		
	new client = GetEventInt(event, "player");

	if(IsValidClient(client))
	{
		switch(GetEventInt(event, "eventtype"))
		{		
			case FlagEvent_PickedUp:
			{
				if(!AllowIntel)
				{
					HaveIntel[client] = true;	
					PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01Jet blocked while you carry intel !");
				}
			}
			case FlagEvent_Captured, FlagEvent_Dropped:
			{
				HaveIntel[client] = false;
			}
		}
	}
}

public OnClientPutInServer(client)
{
	HaveJet[client] = false;
	Flying[client] = false;
	RoundEnd = false;
	HaveIntel[client] = false;
	HudInfo[client] = true;
	jetUses[client] = JetMaxUses;
	SCalc[client] = jetUses[client];
	SCalc0[client] = SCalc[client] * 0.5 / 100;
	SCalc2[client] = 100.0;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	_CloseHandle(hReloadTime[client]);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!CjetEnable || !IsPlayerAlive(client) || Activated[client] || !IsValidClient(client) || !HaveJet[client] || RoundEnd || HaveIntel[client])
		return Plugin_Continue;
		
	if(buttons & IN_JUMP && !FlyKeys || buttons & IN_JUMP && buttons & IN_ATTACK2 && FlyKeys)
	{
		if(jetUses[client] != 0 && jetUses[client] <= JetMaxUses)
		{
			if(OnlyAdmins && !IsClientAdmin(client) && !Activated[client])
			{
				PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01Crazy Jet only for admins, sorry, dropping your jet...");
				HaveJet[client] = false;
				return Plugin_Continue;
			}

			if(TF2_GetPlayerClass(client) == TFClass_Scout && !AllowScout || TF2_GetPlayerClass(client) == TFClass_Sniper && !AllowSniper || TF2_GetPlayerClass(client) == TFClass_Soldier && !AllowSoldier || TF2_GetPlayerClass(client) == TFClass_DemoMan && !AllowDemoMan || TF2_GetPlayerClass(client) == TFClass_Medic && !AllowMedic || TF2_GetPlayerClass(client) == TFClass_Heavy && !AllowHeavy || TF2_GetPlayerClass(client) == TFClass_Pyro && !AllowPyro || TF2_GetPlayerClass(client) == TFClass_Spy && !AllowSpy || TF2_GetPlayerClass(client) == TFClass_Engineer && !AllowEngineer && !Activated[client])
			{
				PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01Crazy Jet temporarily dont Allowed for you class, dropping your jet...");
				HaveJet[client] = false;
				return Plugin_Continue;
			}

			new Float:ClientEyeAngle[3];
			new Float:Velocity[3];
			new Float:ang[3];
			
			GetClientEyeAngles(client, ClientEyeAngle);
			
			if(AdvControl)
			{
				if(buttons & ~IN_FORWARD)
				{
					if(buttons & IN_FORWARD)
					{
						ClientEyeAngle[0] = -40.0;
					}
					else if(buttons & IN_BACK)
					{
						ClientEyeAngle[0] = -120.0;
					}
					else if(buttons & IN_MOVELEFT)
					{
						ClientEyeAngle[1] -= 270.0;
					}
					else if(buttons & IN_MOVERIGHT)
					{
						ClientEyeAngle[1] -= 90.0;
					}
					else
					{
						ClientEyeAngle[0] = -80.0;
					}
				}
			}
			if(!AdvControl)
				ClientEyeAngle[0] = -40.0;

			GetAngleVectors(ClientEyeAngle, Velocity, NULL_VECTOR, NULL_VECTOR);
			
			ScaleVector(Velocity, Force);
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Velocity);	
			
			CreateTimer(0.1, Unactivated, client);

			if(!Activated[client])
			{
				SCalc1[client] = SCalc[client] * 0.5 / 100;
				if(Unlimited == 0)
				{
					if(SCalc0[client] == SCalc1[client])
					{
						SCalc2[client] -= 0.5;
						jetUses[client] -= SCalc0[client];
					}
				}
				else if(Unlimited == 1)
				{
					if(SCalc0[client] == SCalc1[client])
					{
						SCalc2[client] = 100.0;
						jetUses[client] = JetMaxUses;
					}
				}
				else if(Unlimited == 2)
				{
					if(!IsClientAdmin(client))
					{
						if(SCalc0[client] == SCalc1[client])
						{
							SCalc2[client] -= 0.5;
							jetUses[client] -= SCalc0[client];
						}
					}
				}

				Flying[client] = true;
				Activated[client] = true;
				DelParticles(client);
				TF2_AddCondition(client, TFCond:TFCond_TeleportedGlow, 999.0);
				ang[2] = -120.0;
				pRainbow[client] = SpawnParticle(Particle1, 0.0, _, client, "flag", _, ang, _);
				pStars[client] = SpawnParticle(Particle2, 0.0, _, client, "flag", _, ang, _);
				StopSound(client, SNDCHAN_AUTO, FlySound);
				EmitSoundToClient(client, FlySound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
		}
		else
		{
			if(hReloadTime[client] != INVALID_HANDLE)
				return Plugin_Continue;

			hReloadTime[client] = CreateTimer(ReloadTime, Reload, client);
			StopSound(client, SNDCHAN_AUTO, FlySound);
			EmitSoundToClient(client, EmptySound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01Jet out of fuel, charging please wait...");
			TF2_RemoveCondition(client, TFCond:TFCond_TeleportedGlow);
			Flying[client] = false;
			DelParticles(client);
		}
	}

	return Plugin_Continue;
}

public Action:Unactivated(Handle:timer, any:client)
{
	if(!IsValidClient(client))
		return;

	DelParticles(client);
	Activated[client] = false;
	Flying[client] = false;
	StopSound(client, SNDCHAN_AUTO, FlySound);
	TF2_RemoveCondition(client, TFCond:TFCond_TeleportedGlow);
}

public Action:Reload(Handle:timer, any:client)
{
	hReloadTime[client] = INVALID_HANDLE;

	if(!IsValidClient(client))
		return;

	jetUses[client] = JetMaxUses;
	SCalc2[client] = 100.0;
	PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01Jet charged and ready for use !");
	EmitSoundToClient(client, ReloadSound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

public Action:CallHud(client, args)
{
	if(IsValidClient(client))
	{
		if(!CjetEnable)
		{
			PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01Crazy Jet temporarily disabled, sorry.");

			return;
		}

		if(HudInfo[client] == true)
		{
			HudInfo[client] = false;

			PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01You disable HUD INFO.");
		}
		else if(HudInfo[client] == false)
		{
			HudInfo[client] = true;

			PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01You enable HUD INFO.");
		}
	}
}  

public Action:CallJet(client, args)
{
	if(IsValidClient(client))
	{
		if(!CjetEnable)
		{
			PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01Crazy Jet temporarily disabled, sorry.");
			return;
		}

		if(OnlyAdmins && !IsClientAdmin(client))
		{
			PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01Crazy Jet only for admins, sorry.");
			return;
		}

		if(TF2_GetPlayerClass(client) == TFClass_Scout && !AllowScout || TF2_GetPlayerClass(client) == TFClass_Sniper && !AllowSniper || TF2_GetPlayerClass(client) == TFClass_Soldier && !AllowSoldier || TF2_GetPlayerClass(client) == TFClass_DemoMan && !AllowDemoMan || TF2_GetPlayerClass(client) == TFClass_Medic && !AllowMedic || TF2_GetPlayerClass(client) == TFClass_Heavy && !AllowHeavy || TF2_GetPlayerClass(client) == TFClass_Pyro && !AllowPyro || TF2_GetPlayerClass(client) == TFClass_Spy && !AllowSpy || TF2_GetPlayerClass(client) == TFClass_Engineer && !AllowEngineer)
		{
			PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01Crazy Jet temporarily dont Allowed for you class.");
			return;
		
		}

		if(HaveJet[client] == true)
		{
			HaveJet[client] = false;
			PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01You drop you Jet.");
			SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		}
		else if(HaveJet[client] == false)
		{
			HaveJet[client] = true;
			PrintToChat(client, "\x03[\x04SM: Crazy Jet\x03] \x01You take you Jet.");

			if(TF2_GetPlayerClass(client) == TF2_GetClass("heavy") && HaveJet[client])
			{
				TF2_RemoveWeaponSlot(client, 0);
				SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
			}
		}
	}
}

public Action:OnPlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsValidClient(client))
		CreateTimer(0.1, Check, client);

	return Plugin_Continue;
}

public Action:Check(Handle:timer, any:client)
{
	if(IsValidClient(client))
	{
		if(HaveJet[client])
		{
			new TFClassType:classe = TF2_GetPlayerClass(client);

			if(classe == TFClass_Heavy)
			{
				TF2_RemoveWeaponSlot(client, 0);
				SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
			}

			if(classe != TFClass_Heavy)
				SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		}
	}
}