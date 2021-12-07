//Stropy
#define PN "TF2 Jail - Hide And Seek]" //NPDU = No plugins dependencies update
#define PA "Elpapuh"
#define PDESC "Play a better hide and seek mode in tf2 jailbreak server"
#define PV "1.7.5"
#define PURL "https://forums.alliedmods.net/showthread.php?t=300720"

public Plugin myinfo = 
{
	name = PN,
	author = PA,
	description = PDESC,
	version = PV,
	url = PURL
};

#pragma semicolon 1

#define DEBUG 
#define UPDATE_URL	"https://jlovers.ml/plugins/playhas.txt"

//Include requeriments

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <morecolors>
#include <smlib>
#include <tf2jail>
#include <tf2_advanced>
#include <updater>

//Plugin requeriments
#undef REQUIRE_PLUGIN
#include <updater>
#include <tf2jail>
#define REQUIRE_PLUGIN

new Handle:StartSearchTimer = INVALID_HANDLE;
new Handle:RestoreSpeed = INVALID_HANDLE;
new Handle:FreezeTimer = INVALID_HANDLE;

new bool:g_bLateLoad = false;
new bool:g_bFallDamage = false;

public OnPluginStart()
{
	HookEvent("teamplay_round_win", RoundEnd);
	if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public TF2Jail_OnLastRequestExecute(const String:Handler[])
{	

	new Float:speed = 500.0;

	if (StrEqual(Handler, "PlayHAS"))
	{
	
		HookEvent("player_death", PlayerDies);
	
		ServerCommand("sm_freeze @blue 45");
		
		TF2Jail_ManageCells(OPEN);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				switch (GetClientTeam(i))
				{
				
					case TFTeam_Red:
					{
						CPrintToChat(i, "{haunted}[{magenta}HideAndSeek{haunted}] {orange}You have to hide faster as you can, before you get 'tired' Haha");
						TF2_RemoveWeaponSlot(i, 0);
						TF2_RemoveWeaponSlot(i, 1);
						SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", speed);  
					}
				
					case TFTeam_Blue:
					{
						CPrintToChat(i, "{haunted}[{magenta}HideAndSeek{haunted}] {orange}You have to catch (kill) reds before round ends Helouda");
					}
				}
			}
		}
		ClearTimer(StartSearchTimer);
		ClearTimer(RestoreSpeed);
		ClearTimer(FreezeTimer);
		StartSearchTimer = CreateTimer(50.0, StunReds, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		RestoreSpeed = CreateTimer(65.0, RSpeed, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		FreezeTimer = CreateTimer(80.0, FreezeReds, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnMapStart()
{
	PrecacheSound("haseek/start.wav", true);
	PrecacheSound("haseek/die.wav", true);
	PrecacheSound("haseek/kill.wav");
	//PreCacheSound("haseek/dieunknown.wav, true");
	
	AddFileToDownloadsTable("sound/haseek/start.wav");
	AddFileToDownloadsTable("sound/haseek/die.wav");
	AddFileToDownloadsTable("sound/haseek/kill.wav");
	PrintToServer("The plugin is running the latest version");
}

public OnConfigsExecuted()
{
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		g_bLateLoad = false;
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:StunReds(Handle:hTimer)
{
	StartSearchTimer = INVALID_HANDLE;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			switch (GetClientTeam(i))
			{
				case TFTeam_Red: 
				{
				TF2_SetPlayerSpeed(i, Float:100);
				CPrintToChat(i, "{gray}[{orange}HideAndSeek{gray}] {red}You're tyred, you can't run anymore");
				}
				
				case TFTeam_Blue: 
				{
				CPrintToChat(i, "{gray}[{orange}HideAndSeek{gray}] {cyan}Reds got stunned, their speed has been slowed");
				}
			}
		}
	}
}

public Action:RSpeed(Handle:hTimer)
{
	RestoreSpeed = INVALID_HANDLE;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			switch (GetClientTeam(i))
			{
				case TFTeam_Red: 
				{
				TF2_SetPlayerDefaultSpeed(i);
				CPrintToChat(i, "{gray}[{orange}HideAndSeek{gray}] {red}Your energy have been restored");
				}
			}
		}
	}
}

public Action:FreezeReds(Handle:hTimer)
{
	new Float:speed = 0.0;
	FreezeTimer = INVALID_HANDLE;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			switch (GetClientTeam(i))
			{
				case TFTeam_Red: 
				{
				SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", speed);  
				EmitSoundToClient(i, "haseek/start.wav");
				SetEntityHealth(i, 1);
				CPrintToChat(i, "{gray}[{orange}HideAndSeek{gray}] {red}You're tired, so..., you can't move");
				}
				
				case TFTeam_Blue:
				{
				CPrintToChat(i, "{red}[{gray}HideAndSeek{red}] {orange}Reds are tired, so..., they can't move");
				}
			}
		}
		
		if (TF2_GetPlayerClass(i) == TFClass_Medic && TF2_GetClientTeam(i) == TFTeam_Red)
		{
			TF2_SetPlayerClass(i, TFClass_Spy);
		}
	}
}

public PlayerDies(Event event, const char[] name, bool dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			switch (GetClientTeam(i))
			{
				
				case TFTeam_Blue:
				{
					EmitSoundToClient(i, "haseek/kill.wav");
				}
				
				case TFTeam_Red:
				{
					EmitSoundToClient(i, "haseek/die.wav");
				}
			}
		}
	}
}

public RoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	ClearTimer(StartSearchTimer);
	ClearTimer(RestoreSpeed);
	ClearTimer(FreezeTimer);
	
	UnhookEvent("player_death", PlayerDies);
	
	g_bFallDamage = false;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (g_bFallDamage && (damagetype & DMG_FALL))
	{
		damage = damage * 3.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

//Stropy