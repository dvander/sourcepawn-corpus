/*******************************************************\
* Bounty hunt Mod for TF2
* By Afronanny
* 
* - Randomly choose a player from each team
* - Randomly choose a death type, and assign to both players.
* - Set a beacon on the players chosen for the bounty hunt as a sort of mark so opposition will know who to hunt. just something to "mark" the bountied players so the other team knows who to hunt.)
* - When one of the players is killed by the correctly chosen death, the other team gets buffed with crits for 5-10 seconds.
* - After the buff expires, have the mod "reroll" bounties and start again.
* 
* TODO:
* - Prevent bounty turtling
* - Add cvar for display of bounty in chat/HUD/both
* - Punish team for turtling
* 		-Cvar for uber/crits/both for turtling
* 		-Cvar for length of punishment
* - Make beacon more noticable/add sound
* - Bounty kills other bounty = Something epic?
* - Clean up the disgusting DeathType code
\********************************************************/ 

#include <sourcemod>
#include <sdktools>
#include <tf2>
#pragma semicolon 1

#define PLUGIN_VERSION		"0.2"

//Macros to make my life easier
#define CLIENTLOOP		for (new i = 1; i <= MaxClients; i++) 
#define CLIENTINGAME(i)	\
if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
	#define IF_ENABLED 	if (GetConVarBool(g_hCvarEnabled))

new Handle:g_hCvarEnabled;
//new Handle:g_hCvarAntiTurtleReroll;
new Handle:g_hCvarCritDuration;

new Handle:g_hCvarAds;
new Handle:g_hCvarAdsTime;

new DeathType:g_DeathType;

new g_iBlueBounty;
new g_iRedBounty;

new g_BeamSprite;
new g_HaloSprite;

new Handle:g_hHudSyncBlue;
new Handle:g_hHudSyncRed;
new Handle:g_hHudSyncDT;

new Handle:g_hHudSyncAds1;
new Handle:g_hHudSyncAds2;

new Handle:g_hTimerAds;

new tf_gamerules;

enum String:DeathType {
	DeathType_ClumsyPainfulDeath = 0,
	DeathType_Scattergun,
	DeathType_ScoutPistol,
	DeathType_Bat,
	DeathType_ForceANature,
	DeathType_Sandman,
	DeathType_RocketLauncher,
	DeathType_DirectHit,
	DeathType_SoldierShotgun,
	DeathType_Shovel,
	DeathType_Pickaxe,
	DeathType_Flamethrower,
	DeathType_Backburner,
	DeathType_PyroShotgun,
	DeathType_Flaregun,
	DeathType_Sledgehammer,
	DeathType_Axtinguisher,
	DeathType_Axe,
	DeathType_GrenadeLauncher,
	DeathType_Sword,
	DeathType_StickyBomb,
	DeathType_Shield,
	DeathType_Minigun,
	DeathType_Natascha,
	DeathType_HeavyShotgun,
	DeathType_Fists,
	DeathType_KGB,
	DeathType_Wrench,
	DeathType_EngiPistol,
	DeathType_EngiShotgun,
	DeathType_Sentry,
	DeathType_Telefrag,
	DeathType_NeedleGun,
	DeathType_Blutsauger,
	DeathType_BoneSaw,
	DeathType_UberSaw,
	DeathType_SniperRifle,
	DeathType_Cuntsman,
	DeathType_SMG,
	DeathType_Kukri,
	DeathType_Shiv, 
	DeathType_Revolver,
	DeathType_Ambassador,
	DeathType_Knife,
	DeathType_TauntSpy,
	DeathType_TauntScout,
	DeathType_TauntSoldier,
	DeathType_TauntPyro,
	DeathType_TauntDemo,
	DeathType_TauntHwg,
	DeathType_TauntSniper,
	DeathType_DemoAxe
};

public Plugin:myinfo = 
{
	name = "TF2 Bounty Hunt",
	author = "Afronanny",
	description = "Bounty Hunt Mod for TF2",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=116530"
}



public OnMapStart()
{
	IF_ENABLED
	{
		CreateTimer(5.0, Timer_Reroll, _, TIMER_FLAG_NO_MAPCHANGE);
		g_hTimerAds = CreateTimer(GetConVarFloat(g_hCvarAdsTime), Timer_Advertise, _, TIMER_REPEAT);
		
		tf_gamerules = FindEntityByClassname(MaxClients + 1, "tf_gamerules");
		if (tf_gamerules == -1)
		{
			LogError("Could not find tf_gamerules. Team Score may not be increased");
		}
		g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
		g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	}
}

public OnMapEnd()
{
	if (g_hTimerAds != INVALID_HANDLE)
	{
		CloseHandle(g_hTimerAds);
		g_hTimerAds = INVALID_HANDLE;
	}
}

public OnPluginStart()
{
	g_hCvarEnabled = CreateConVar("sm_bounty_enabled", "1", "Enable the Bounty Hunt mod", FCVAR_PLUGIN|FCVAR_SPONLY);
	//g_hCvarAntiTurtleReroll = CreateConVar("sm_bounty_antiturtle", "1", "Reroll the bounty if the bounty is turtling in spawn");
	g_hCvarCritDuration = CreateConVar("sm_bounty_critduration", "10.0", "Duration of crits/Time before new bounty is chosen", FCVAR_PLUGIN|FCVAR_SPONLY);
	CreateConVar("sm_tf2bounty_version", PLUGIN_VERSION, "Version of TF2 Bounty Hunt", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_PLUGIN);
	
	g_hCvarAds = CreateConVar("sm_bounty_ads", "1", "Advertise the plugin + its creator", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_hCvarAdsTime = CreateConVar("sm_bounty_ads_interval", "300.0", "Interval to show the credits", FCVAR_PLUGIN|FCVAR_SPONLY);
	
	HookConVarChange(g_hCvarAds, ConVarChanged_Ads);
	HookConVarChange(g_hCvarAdsTime, ConVarChanged_Ads);
	
	RegAdminCmd("sm_reroll", Command_Reroll, ADMFLAG_GENERIC);
	RegConsoleCmd("sm_showbounty", Command_ShowBounty);
	HookEvent("player_death", Event_PlayerDeath);
	
	
	
	LoadTranslations("bounty.phrases");
	
	g_hHudSyncAds1 = CreateHudSynchronizer();
	g_hHudSyncAds2 = CreateHudSynchronizer();
	
	g_hHudSyncBlue = CreateHudSynchronizer();
	g_hHudSyncRed = CreateHudSynchronizer();
	g_hHudSyncDT = CreateHudSynchronizer();
	
	
	
	
	AddServerTag("bountyhunt");
	AutoExecConfig(true);
}

public OnPluginEnd()
{
	CloseHandle(g_hHudSyncAds1);
	CloseHandle(g_hHudSyncAds2);
	CloseHandle(g_hHudSyncBlue);
	CloseHandle(g_hHudSyncDT);
	CloseHandle(g_hHudSyncRed);
	
	RemoveServerTag("bountyhunt");
}

public Action:Timer_Advertise(Handle:timer)
{
	CLIENTLOOP
	{
		CLIENTINGAME (i)
		{
			SetHudTextParams(-1.0, 0.3, 5.0, 0, 206, 209, 255, 2);
			ShowSyncHudText(i, g_hHudSyncAds1, "TF2 Bounty Mod v%s", PLUGIN_VERSION);
			SetHudTextParams(-1.0, 0.33, 5.0, 0, 255, 0, 255, 2);
			ShowSyncHudText(i, g_hHudSyncAds2, "Created by Afronanny");
		}
	}
	return Plugin_Continue;
}

public Action:Command_Reroll(client, args)
{
	if (GetConVarBool(g_hCvarEnabled))
	{
		CreateTimer(0.1, Timer_Reroll, _, TIMER_FLAG_NO_MAPCHANGE);
		ReplyToCommand(client, "Bounty has been rerolled");
	} else {
		ReplyToCommand(client, "Bounty Hunt is disabled");
	}
}

public Action:Command_ShowBounty(client, args)
{
	if (GetConVarBool(g_hCvarEnabled))
	{
		CLIENTLOOP
		{
			CLIENTINGAME(i)
			{
				ClearSyncHud(i, g_hHudSyncBlue);
				SetHudTextParams(0.24, 0.89, 600.0, 75, 75, 255, 255, 0, 6.0, 0.1, 0.2);
				ShowSyncHudText(i, g_hHudSyncBlue, "Blue Bounty: %N",  g_iBlueBounty);
				
			}
		}
		
		CLIENTLOOP
		{
			CLIENTINGAME(i)
			{
				ClearSyncHud(i, g_hHudSyncRed);
				SetHudTextParams(0.24, 0.92, 600.0, 255, 75, 75, 255, 0, 6.0, 0.1, 0.2);
				ShowSyncHudText(i, g_hHudSyncRed, "Red Bounty: %N",  g_iRedBounty);
				//PrintToChat(i, "%t Red Bounty: %N", "Tag", newred);
			}
		}
		
		decl String:dtype[256];
		GetWepForDeathType(g_DeathType, dtype, sizeof(dtype));
		
		CLIENTLOOP
		{
			CLIENTINGAME(i)
			{
				ClearSyncHud(i, g_hHudSyncDT);
				SetHudTextParams(0.24, 0.95, 600.0, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
				ShowSyncHudText(i, g_hHudSyncDT, "Death Type: %t",  dtype);
			}
		}
	} else {
		ReplyToCommand(client, "Bounty Hunt is disabled");
	}
	return Plugin_Handled;
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_hCvarEnabled))
	{
		new dead = GetClientOfUserId(GetEventInt(event, "userid"));
		new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		decl String:wep[256];
		GetEventString(event, "weapon_logclassname", wep, sizeof(wep));
		
		if ((dead == g_iBlueBounty || dead == g_iRedBounty) && DeathCheck(wep))
		{
			if (killer != 0)
			{
				BuffTeam(GetClientTeam(killer));
			} else {
				if (GetClientTeam(dead) == 2)
				{
					BuffTeam(3);
				} else if (GetClientTeam(dead) == 3)
				{
					BuffTeam(2);
				}
			}
		}
	}
	return Plugin_Continue;
}

public bool:DeathCheck(String:type[])
{
	decl String:wep[256];
	GetWepForDeathType(g_DeathType, wep, sizeof(wep));
	if (strcmp(wep, type) == 0)
	{
		return true;
	}
	
	return false;
}
public GetWepForDeathType(DeathType:type, String:wep[], maxlen)
{
	if (type == DeathType:DeathType_ClumsyPainfulDeath )
	{
		strcopy(wep, maxlen, "worldspawn");
		return; 
	}
	if (type == DeathType:DeathType_Scattergun )
	{
		strcopy(wep, maxlen, "scattergun");
		return; 
	}
	if (type == DeathType:DeathType_ScoutPistol )
	{
		strcopy(wep, maxlen, "pistol_scout");
		return; 
	}
	if (type == DeathType:DeathType_Bat )
	{
		strcopy(wep, maxlen, "bat");
		return; 
	}
	if (type == DeathType:DeathType_ForceANature )
	{
		strcopy(wep, maxlen, "force_a_nature");
		return;
	}
	if (type == DeathType:DeathType_Sandman )
	{
		strcopy(wep, maxlen, "sandman");
		return; 
	}
	if (type == DeathType:DeathType_RocketLauncher )
	{
		strcopy(wep, maxlen, "tf_projectile_rocket");
		return; 
	}
	if (type == DeathType:DeathType_DirectHit )
	{
		strcopy(wep, maxlen, "rocketlauncher_directhit");
		return; 
	}
	if (type == DeathType:DeathType_SoldierShotgun )
	{
		strcopy(wep, maxlen, "shotgun_soldier");
		return; 
	}
	if (type == DeathType:DeathType_Shovel )
	{
		strcopy(wep, maxlen, "shovel");
		return; 
	}
	if (type == DeathType:DeathType_Pickaxe )
	{
		strcopy(wep, maxlen, "unique_pickaxe");
		return;
	}
	if (type == DeathType:DeathType_Flamethrower )
	{
		strcopy(wep, maxlen, "flamethrower");
		return; 
	}
	if (type == DeathType:DeathType_Backburner )
	{
		strcopy(wep, maxlen, "backburner");
		return; 
	}
	if (type == DeathType:DeathType_PyroShotgun )
	{
		strcopy(wep, maxlen, "shotgun_pyro");
		return; 
	}
	if (type == DeathType:DeathType_Flaregun )
	{
		strcopy(wep, maxlen, "flaregun");
		return;
	}
	if (type == DeathType:DeathType_Sledgehammer )
	{
		strcopy(wep, maxlen, "sledgehammer");
		return; 
	}
	if (type == DeathType:DeathType_Axtinguisher )
	{
		strcopy(wep, maxlen, "axtinguisher");
		return; 
	}
	if (type == DeathType:DeathType_Axe )
	{
		strcopy(wep, maxlen, "fireaxe");
		return; 
	}
	if (type == DeathType:DeathType_GrenadeLauncher )
	{
		strcopy(wep, maxlen, "tf_projectile_pipe");
		return; 
	}
	if (type == DeathType:DeathType_Sword )
	{
		strcopy(wep, maxlen, "sword");
		return; 
	}
	if (type == DeathType:DeathType_StickyBomb )
	{
		strcopy(wep, maxlen, "tf_projectile_pipe_remote");
		return;
	}
	if (type == DeathType:DeathType_Shield )
	{
		strcopy(wep, maxlen, "demoshield");
		return; 
	}
	if (type == DeathType:DeathType_Minigun )
	{
		strcopy(wep, maxlen, "minigun");
		return; 
	}
	if (type == DeathType:DeathType_Natascha )
	{
		strcopy(wep, maxlen, "natascha");
		return; 
	}
	if (type == DeathType:DeathType_HeavyShotgun )
	{
		strcopy(wep, maxlen, "shotgun_hwg");
		return; 
	}
	if (type == DeathType:DeathType_Fists )
	{
		strcopy(wep, maxlen, "fists");
		return; 
	}
	if (type == DeathType:DeathType_KGB )
	{
		strcopy(wep, maxlen, "gloves");
		return; 
	}
	if (type == DeathType:DeathType_Wrench )
	{
		strcopy(wep, maxlen, "wrench");
		return; 
	}
	if (type == DeathType:DeathType_EngiPistol )
	{
		strcopy(wep, maxlen, "pistol");
		return; 
	}
	if (type == DeathType:DeathType_EngiShotgun )
	{
		strcopy(wep, maxlen, "shotgun_primary");
		return; 
	}
	if (type == DeathType:DeathType_Sentry )
	{
		strcopy(wep, maxlen, "obj_sentrygun");
		return; 
	}
	if (type == DeathType:DeathType_Telefrag )
	{
		strcopy(wep, maxlen, "telefrag");
		return; 
	}
	if (type == DeathType:DeathType_NeedleGun )
	{
		strcopy(wep, maxlen, "syringegun_medic");
		return;
	}
	if (type == DeathType:DeathType_Blutsauger )
	{
		strcopy(wep, maxlen, "blutsauger");
		return; 
	}
	if (type == DeathType:DeathType_BoneSaw )
	{
		strcopy(wep, maxlen, "bonesaw");
		return; 
	}
	if (type == DeathType:DeathType_UberSaw )
	{
		strcopy(wep, maxlen, "ubersaw");
		return; 
	}
	if (type == DeathType:DeathType_SniperRifle )
	{
		strcopy(wep, maxlen, "sniperrifle");
		return; 
	}
	if (type == DeathType:DeathType_Cuntsman )
	{
		strcopy(wep, maxlen, "tf_projectile_arrow");
		return; 
	}
	if (type == DeathType:DeathType_SMG )
	{
		strcopy(wep, maxlen, "smg");
		return; 
	}
	if (type == DeathType:DeathType_Kukri )
	{
		strcopy(wep, maxlen, "club");
		return; 
	}
	if (type == DeathType:DeathType_Shiv )
	{
		strcopy(wep, maxlen, "tribalkukri");
		return; 
	}
	if (type == DeathType:DeathType_Revolver )
	{
		strcopy(wep, maxlen, "revolver");
		return;
	}
	if (type == DeathType:DeathType_Ambassador )
	{
		strcopy(wep, maxlen, "ambassador");
		return; 
	}
	if (type == DeathType:DeathType_Knife )
	{
		strcopy(wep, maxlen, "knife");
		return; 
	}
	if (type == DeathType:DeathType_TauntSpy )
	{
		strcopy(wep, maxlen, "taunt_spy");
		return; 
	}
	if (type == DeathType:DeathType_TauntScout )
	{
		strcopy(wep, maxlen, "taunt_scout");
		return; 
	}
	if (type == DeathType:DeathType_TauntSoldier )
	{
		strcopy(wep, maxlen, "taunt_soldier");
		return; 
	}
	if (type == DeathType:DeathType_TauntPyro )
	{
		strcopy(wep, maxlen, "taunt_pyro");
		return; 
	}
	if (type == DeathType:DeathType_TauntDemo )
	{
		strcopy(wep, maxlen, "taunt_demoman");
		return; 
	}
	if (type == DeathType:DeathType_TauntHwg )
	{
		strcopy(wep, maxlen, "taunt_heavy");
		return; 
	}
	if (type == DeathType:DeathType_TauntSniper )
	{
		strcopy(wep, maxlen, "taunt_sniper");
		return; 
	}
	/*//Scotsman's Skullcutter - I don't have this weapon. Cannot tell what log_classname for this is <_<
	if (type == DeathType:DeathType_DemoAxe)
	{
		strcopy(wep, maxlen, "");
	return; }*/
}


public Action:Timer_Reroll(Handle:timer)
{
	if (GetConVarBool(g_hCvarEnabled))
	{
		g_DeathType = DeathType:GetRandomInt(0, 51); //Ew don't hardcode the number of death types!
		
		
		new arrTeamBlue[MaxClients];
		new arrTeamRed[MaxClients];
		
		new BlueIterator;
		new RedIterator;
		
		new team;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				team = GetClientTeam(i);
				if (team == 2)
				{
					arrTeamRed[RedIterator] = i;
					RedIterator++;
				} else if (team == 3)
				{
					arrTeamBlue[BlueIterator] = i;
					BlueIterator++;
				}
			}
		}
		
		new newred;
		new newblue;
		
		newred = arrTeamRed[GetRandomInt(0, RedIterator-1)];
		newblue = arrTeamBlue[GetRandomInt(0, BlueIterator-1)];
		
		
		if (newred != g_iRedBounty)
			AddBountyEffect(newred);
		if (newblue != g_iBlueBounty)
			AddBountyEffect(newblue);
		
		
		g_iBlueBounty = newblue;
		g_iRedBounty = newred;
		
		CLIENTLOOP
		{
			CLIENTINGAME(i)
			{
				ClearSyncHud(i, g_hHudSyncBlue);
				SetHudTextParams(0.24, 0.89, 600.0, 75, 75, 255, 255, 0, 6.0, 0.1, 0.2);
				ShowSyncHudText(i, g_hHudSyncBlue, "Blue Bounty: %N",  newblue);
				
			}
		}
		
		CLIENTLOOP
		{
			CLIENTINGAME(i)
			{
				ClearSyncHud(i, g_hHudSyncRed);
				SetHudTextParams(0.24, 0.92, 600.0, 255, 75, 75, 255, 0, 6.0, 0.1, 0.2);
				ShowSyncHudText(i, g_hHudSyncRed, "Red Bounty: %N",  newred);
				//PrintToChat(i, "%t Red Bounty: %N", "Tag", newred);
			}
		}
		
		decl String:dtype[256];
		GetWepForDeathType(g_DeathType, dtype, sizeof(dtype));
		
		CLIENTLOOP
		{
			CLIENTINGAME(i)
			{
				ClearSyncHud(i, g_hHudSyncDT);
				SetHudTextParams(0.24, 0.95, 600.0, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
				ShowSyncHudText(i, g_hHudSyncDT, "Death Type: %t",  dtype);
				//PrintToChat(i, "%t Death Type: %t", "Tag",  dtype);
			}
		}
	}
	return Plugin_Continue;
}



public Action:Timer_Beacon(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		if (g_iBlueBounty == client || g_iRedBounty == client)
		{
			new Float:origin[3];
			GetClientAbsOrigin(client, origin);
			origin[2] += 10.0;
			TE_SetupBeamRingPoint(origin, 10.0, 100.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 15.0, 0.0, {255,0,0,255}, 10, 0);
			TE_SendToAll();
			return Plugin_Continue;
		} else {
			return Plugin_Stop;
		}
	} else {
		return Plugin_Stop;
	}
}

public AddBountyEffect(client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		CreateTimer(1.0, Timer_Beacon, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public BuffTeam(team)
{
	IF_ENABLED
	{
		decl String:teamstr[16];
		if (team == 2)
		{
			strcopy(teamstr, sizeof(teamstr), "Red");
		} else if (team == 3)
		{
			strcopy(teamstr, sizeof(teamstr), "Blue");
		}
		CLIENTLOOP
		{
			CLIENTINGAME(i)
			{
				SetHudTextParams(-1.0, -1.0, GetConVarFloat(g_hCvarCritDuration), 255,20,147,255, 2);
				ShowSyncHudText(i, g_hHudSyncDT, "%s wins!", teamstr);
				if (GetClientTeam(i) == team)
					TF2_AddCondition(i, TFCond_Kritzkrieged, GetConVarFloat(g_hCvarCritDuration));
			}
		}
		if (team == 2)
		{
			SetVariantInt(1);
			AcceptEntityInput(tf_gamerules, "AddRedTeamScore");
		} else if (team == 3)
		{
			SetVariantInt(1);
			AcceptEntityInput(tf_gamerules, "AddBlueTeamScore");
		}
		
		CreateTimer(GetConVarFloat(g_hCvarCritDuration), Timer_Reroll, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public ConVarChanged_Ads(Handle:convar, const String:oldValue[], const String:newValue[])
{
	IF_ENABLED
	{
		if (GetConVarBool(g_hCvarAds))
		{
			CloseHandle(g_hTimerAds);
			g_hTimerAds = CreateTimer(GetConVarFloat(g_hCvarAdsTime), Timer_Advertise, _, TIMER_REPEAT);
		}
	}
}



