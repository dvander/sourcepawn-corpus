/**
 * Ion Cannon simulation in SourceMod
 * Fires an satellite laser beam just like in Command & Conquer Renegade: Reborn
 * 
 * Original AMX Mod X code by A.F.
 * http://forums.space-headed.net/viewtopic.php?f=25&t=542
 * 
 * Sounds and Math taken from the weaponmod ion cannon by A.F.
 * 
 * If you think there's a great effect left, please just share your ideas!
 * 
 * env_shooter stock by V0gelz
 * 
 * By Peace-Maker
 * visit http://www.wcfan.de/
 * 
 * Changelog:
 * 1.0: Initial release
 * 1.1: Added alternative hl2 only sounds and admin command to give ion cannons
 * 1.2: Added own cvar for weapon, fixed fire, added cvar for glowing sprite amount, fixed showing progress bar on games that don't support it
 * 1.2.1: Fixed using m_iAccount even if sm_ion_buy_price is set to 0, Added blue glow to where ion cannon has been deployed
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>
#include <smlib>

#define PLUGIN_VERSION "1.2.1"

#define ION_MODEL "models/props_lab/tpplug.mdl"
#define MDL_LASER "sprites/laser.vmt"

#define SOUND_APPROACH "ion/approaching.wav"
#define SOUND_BEACON "ion/beacon_set.wav"
#define SOUND_STOP "common/warning.wav"
#define SOUND_BEEP "ion/beacon_beep.wav"
#define SOUND_ATTACK "ion/attack.wav"
#define SOUND_READY "ion/ready.wav"
#define SOUND_PLANT "ion/beacon_plant.wav"

// Support for L4D or just servers, who don't want their players to download the sound
//#define ALTERNATIVE_SOUNDS

#define ACTION_BLOCK	(IN_JUMP | IN_DUCK | IN_FORWARD | IN_BACK | IN_LEFT | IN_RIGHT | IN_MOVELEFT | IN_MOVERIGHT | IN_RELOAD | IN_RUN | IN_USE)

#define PREFIX "{olive}Ion Cannon {default}>{green} "

new Handle:g_hFiringWeapon[MAXPLAYERS+2] = {INVALID_HANDLE,...};
new bool:g_bIsPressingAttack[MAXPLAYERS+2] = {false,...};
new g_iFireWeaponStartTime[MAXPLAYERS+2] = {0,...};
new Handle:g_hFiringWeaponCountdown[MAXPLAYERS+2] = {INVALID_HANDLE,...};
new g_iIonCannonAmmo[MAXPLAYERS+2] = {0,...};
new g_iInfoTargetEntity[MAXPLAYERS+2] = {-1,...};
new Float:g_fInfoTargetOrigin[MAXPLAYERS+2][3];
new g_iBeaconBeepPitch[MAXPLAYERS+2];
new Float:g_fBeaconBeepTime[MAXPLAYERS+2];

new Float:g_fBeamOrigin[MAXPLAYERS+2][8][3];
new Float:g_fBeamDegrees[MAXPLAYERS+2][8];
new Float:g_fBeamDistance[MAXPLAYERS+2];
new Float:g_fBeamRotationSpeed[MAXPLAYERS+2];
new bool:g_bShowBeams[MAXPLAYERS+2] = {false,...};

new Float:g_fSkyOrigin[MAXPLAYERS+2][3];

new bool:g_bUseProgressBar = false;

// Effect sprites
new g_iLaserSprite;
new g_iHaloSprite;
new g_iGlowSprite;
new g_iExplosionModel;
new g_iSmokeSprite1;
new g_iSmokeSprite2;

// ConVars
new Handle:g_hCVAmmo;
new Handle:g_hCVMaxAmmo;
new Handle:g_hCVBuy;
new Handle:g_hCVPrice;
new Handle:g_hCVDeployTime;
new Handle:g_hCVShakeTime;
new Handle:g_hCVRadius;
new Handle:g_hCVMinDamage;
new Handle:g_hCVMaxDamage;
new Handle:g_hCVIonWeapon;
new Handle:g_hCVGlowSprites;
new Handle:g_hCVPlaceTime;

public Plugin:myinfo = 
{
	name = "Ion Cannon",
	author = "Jannik 'Peace-Maker' Hartung, AMXX version: A.F.",
	description = "C&C Ion Cannon in Source games",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_ion_version", PLUGIN_VERSION, "Ion cannon version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	
	RegConsoleCmd("sm_buyion", Command_BuyIon, "Buy an ion cannon");
	
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_giveion", Command_GiveIon, ADMFLAG_ROOT, "Give a player an ion cannon. Usage: sm_giveion <#userid|steamid|name>");
	
	g_hCVAmmo = CreateConVar("sm_ion_defaultammo", "1", "How many ion cannons should a player get by default on join?", FCVAR_PLUGIN, true, 0.0);
	g_hCVMaxAmmo = CreateConVar("sm_ion_maxammo", "5", "How many ion cannons should a player be able to \"carry\" at a time?", FCVAR_PLUGIN, true, 1.0);
	g_hCVBuy = CreateConVar("sm_ion_buy_enable", "1", "Are players allowed to buy an ion cannon via \"!buyion\"?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVPrice = CreateConVar("sm_ion_buy_price", "10000", "How much money does the ion cannon cost?", FCVAR_PLUGIN, true, 0.0);
	g_hCVDeployTime = CreateConVar("sm_ion_deploytime", "30", "How long does it take to display the beams after deploying a ion cannon in seconds?", FCVAR_PLUGIN, true, 0.1, true, 35.0);
	g_hCVShakeTime = CreateConVar("sm_ion_shaketime", "10", "How long should the client's screen shake after explosion in seconds?", FCVAR_PLUGIN, true, 0.0);
	g_hCVRadius = CreateConVar("sm_ion_radius", "2000", "The radius of the explosion.", FCVAR_PLUGIN, true, 1001.0);
	g_hCVMinDamage = CreateConVar("sm_ion_mindamage", "42100", "How much damage does the explosion deal at min?", FCVAR_PLUGIN, true, 1000.0);
	g_hCVMaxDamage = CreateConVar("sm_ion_maxdamage", "54200", "How much damage does the explosion deal at max?", FCVAR_PLUGIN, true, 2000.0);
	g_hCVIonWeapon = CreateConVar("sm_ion_weapon", "weapon_knife", "Which weapon should be used to deploy ion cannons?", FCVAR_PLUGIN);
	g_hCVGlowSprites = CreateConVar("sm_ion_glowsprites", "300", "How many glow sprites should be spit out on explosion? (Note: They are shot twice with different velocity!)", FCVAR_PLUGIN, true, 0.0);
	g_hCVPlaceTime = CreateConVar("sm_ion_placetime", "5", "How many seconds should player have to stand still to deploy an ion cannon?", FCVAR_PLUGIN, true, 0.1, true, 15.0);
	
	decl String:sGameFolder[64];
	GetGameFolderName(sGameFolder, sizeof(sGameFolder));
	if(StrContains(sGameFolder, "cstrike", false) != -1)
		g_bUseProgressBar = true;
	
	AutoExecConfig(true, "plugin.ioncannon");
}

public OnMapStart()
{
#if defined ALTERNATIVE_SOUNDS
	PrecacheSound("ambient/explosions/exp1.wav");
	PrecacheSound("ambient/explosions/explode_2.wav");
	PrecacheSound("ambient/explosions/explode_6.wav");
	PrecacheSound("vehicles/tank_turret_stop1.wav");
	PrecacheSound("buttons/button19.wav");
	PrecacheSound("weapons/physgun_off.wav");
	PrecacheSound("weapons/physcannon/superphys_hold_loop.wav");
	PrecacheSound("ambient/machines/floodgate_stop1.wav");
	PrecacheSound("ambient/machines/laundry_machine1_amb.wav");
	PrecacheSound("ambient/levels/citadel/drone1lp.wav");
	PrecacheSound("ambient/levels/citadel/zapper_warmup1.wav");
	PrecacheSound("ambient/levels/labs/electric_explosion1.wav");
	PrecacheSound("ambient/levels/labs/teleport_preblast_suckin1.wav");
	PrecacheSound("ambient/levels/streetwar/strider_distant2.wav");
	PrecacheSound("ambient/wind/wind_hit1.wav");
	PrecacheSound("ambient/wind/wind_hit2.wav");
	PrecacheSound("ambient/wind/wind_hit3.wav");
	PrecacheSound("ambient/wind/wasteland_wind.wav");
	PrecacheSound("ambient/wind/windgust_strong.wav");
	PrecacheSound("ambient/levels/labs/electric_explosion1.wav");
	PrecacheSound("ambient/levels/labs/electric_explosion2.wav");
	PrecacheSound("ambient/levels/labs/electric_explosion3.wav");
	PrecacheSound("ambient/levels/labs/electric_explosion4.wav");
	PrecacheSound("ambient/levels/labs/electric_explosion5.wav");
#else
	decl String:sSoundFile[100];
	Format(sSoundFile, sizeof(sSoundFile), "sound/%s", SOUND_APPROACH);
	AddFileToDownloadsTable(sSoundFile);
	Format(sSoundFile, sizeof(sSoundFile), "sound/%s", SOUND_BEACON);
	AddFileToDownloadsTable(sSoundFile);
	Format(sSoundFile, sizeof(sSoundFile), "sound/%s", SOUND_BEEP);
	AddFileToDownloadsTable(sSoundFile);
	Format(sSoundFile, sizeof(sSoundFile), "sound/%s", SOUND_ATTACK);
	AddFileToDownloadsTable(sSoundFile);
	Format(sSoundFile, sizeof(sSoundFile), "sound/%s", SOUND_READY);
	AddFileToDownloadsTable(sSoundFile);
	Format(sSoundFile, sizeof(sSoundFile), "sound/%s", SOUND_PLANT);
	AddFileToDownloadsTable(sSoundFile);
	
	PrecacheSound(SOUND_APPROACH, true);
	PrecacheSound(SOUND_BEACON, true);
	PrecacheSound(SOUND_BEEP, true);
	PrecacheSound(SOUND_ATTACK, true);
	PrecacheSound(SOUND_READY, true);
	PrecacheSound(SOUND_PLANT, true);
#endif
	
	PrecacheSound(SOUND_STOP, true);
	
	PrecacheModel(ION_MODEL, true);
	PrecacheModel(MDL_LASER, true);
	PrecacheMaterial("materials/sprites/xfireball3.vtf");
	PrecacheModel("materials/sprites/flare1.vmt",true);
	g_iLaserSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_iGlowSprite = PrecacheModel("sprites/blueglow2.vmt", true);
	g_iExplosionModel = PrecacheModel("materials/sprites/sprite_fire01.vmt");
	g_iSmokeSprite1 = PrecacheModel("materials/effects/fire_cloud1.vmt",true);
	g_iSmokeSprite2 = PrecacheModel("materials/effects/fire_cloud2.vmt",true);
}

public OnClientPutInServer(client)
{
	g_iIonCannonAmmo[client] = GetConVarInt(g_hCVAmmo);
}

public OnClientDisconnect(client)
{
	if(g_iInfoTargetEntity[client] != -1 && IsValidEntity(g_iInfoTargetEntity[client]))
	{
		AcceptEntityInput(g_iInfoTargetEntity[client], "Kill");
	}
	g_iInfoTargetEntity[client] = -1;
	g_iFireWeaponStartTime[client] = 0;
	
	if(g_hFiringWeapon[client] != INVALID_HANDLE)
	{
		KillTimer(g_hFiringWeapon[client]);
		g_hFiringWeapon[client] = INVALID_HANDLE;
	}
	
	if(g_hFiringWeaponCountdown[client] != INVALID_HANDLE)
	{
		KillTimer(g_hFiringWeaponCountdown[client]);
		g_hFiringWeaponCountdown[client] = INVALID_HANDLE;
	}
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Client_Shake(client, SHAKE_STOP);
	
	if(g_bUseProgressBar)
	{
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
	}
	
	if(g_iInfoTargetEntity[client] != -1 && IsValidEntity(g_iInfoTargetEntity[client]))
	{
		AcceptEntityInput(g_iInfoTargetEntity[client], "Kill");
	}
	
	g_iInfoTargetEntity[client] = -1;
	g_iFireWeaponStartTime[client] = 0;
	
	if(g_hFiringWeapon[client] != INVALID_HANDLE)
	{
		KillTimer(g_hFiringWeapon[client]);
		g_hFiringWeapon[client] = INVALID_HANDLE;
	}
	
	if(g_hFiringWeaponCountdown[client] != INVALID_HANDLE)
	{
		KillTimer(g_hFiringWeaponCountdown[client]);
		g_hFiringWeaponCountdown[client] = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// Player is firing and got an ion cannon
	if(buttons & IN_ATTACK && !g_bIsPressingAttack[client] && g_iIonCannonAmmo[client] > 0)
	{
		// Player isn't currently placing an ion cannon
		if(g_hFiringWeapon[client] == INVALID_HANDLE)
		{
			// Player is holding the correct weapon?
			decl String:sWeapon[64], String:sIonWeapon[64];
			GetConVarString(g_hCVIonWeapon, sIonWeapon, sizeof(sIonWeapon));
			new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(iWeapon != -1
			&& IsValidEntity(iWeapon)
			&& IsValidEdict(iWeapon)
			&& GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon))
			&& StrEqual(sWeapon, sIonWeapon))
			{
				if(g_iInfoTargetEntity[client] != -1)
				{
					CPrintToChat(client, "%sYou can only place one {red}ion cannon{green} at a time.", PREFIX);
				}
				/*else if(!IsClientOutside(client))
				{
					CPrintToChat(client, "%sYou have to be outside to deploy an {red}ion cannon{green}.", PREFIX);
				}*/
				else
				{
					// Prepare new ion cannon
					g_iInfoTargetEntity[client] = -1;
					g_iBeaconBeepPitch[client] = 97;
					g_fBeaconBeepTime[client] = 1.12;
					g_fBeamDistance[client] = 350.0;
					g_fBeamRotationSpeed[client] = 0.0;
					g_bShowBeams[client] = false;
					
					#if defined ALTERNATIVE_SOUNDS
						EmitSoundToClient(client, "weapons/physcannon/superphys_hold_loop.wav");
						EmitSoundToClient(client, "weapons/physgun_off.wav");
					#else
						EmitSoundToClient(client, SOUND_BEACON, SOUND_FROM_PLAYER, SNDCHAN_WEAPON);
					#endif
					g_iIonCannonAmmo[client]--;
					
					new Float:fPlaceTime = GetConVarFloat(g_hCVPlaceTime);
					
					if(g_bUseProgressBar)
					{
						SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
						SetEntProp(client, Prop_Send, "m_iProgressBarDuration", RoundToNearest(fPlaceTime));
					}
					
					g_iFireWeaponStartTime[client] = GetTime();
					g_hFiringWeaponCountdown[client] = CreateTimer(0.5, Timer_OnUpdatePlaceCountdown, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
					
					g_hFiringWeapon[client] = CreateTimer(fPlaceTime, Timer_OnIonPlanted, client, TIMER_FLAG_NO_MAPCHANGE);
					PrintCenterText(client, "Placing an ion cannon (%d seconds)", RoundToNearest(fPlaceTime));
				}
				g_bIsPressingAttack[client] = true;
			}
		}
		
	}
	else if(g_hFiringWeapon[client] != INVALID_HANDLE
			&& (buttons & ACTION_BLOCK
			|| weapon > 0
			|| !(buttons & IN_ATTACK)))
	{
		g_iIonCannonAmmo[client]++;
		KillTimer(g_hFiringWeapon[client]);
		g_hFiringWeapon[client] = INVALID_HANDLE;
		
		g_iFireWeaponStartTime[client] = 0;
		KillTimer(g_hFiringWeaponCountdown[client]);
		g_hFiringWeaponCountdown[client] = INVALID_HANDLE;
		
		#if defined ALTERNATIVE_SOUNDS
		StopSound(client, SNDCHAN_AUTO, "weapons/physcannon/superphys_hold_loop.wav");
		StopSound(client, SNDCHAN_AUTO, "weapons/physgun_off.wav");
		#else
		StopSound(client, SNDCHAN_WEAPON, SOUND_BEACON);
		#endif
		
		EmitSoundToClient(client, SOUND_STOP, SOUND_FROM_PLAYER, SNDCHAN_WEAPON);
		
		PrintCenterText(client, "Stopped placing an ion cannon");
		
		if(g_bUseProgressBar)
		{
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
			SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
		}
	}
	
	if(!(buttons & IN_ATTACK))
		g_bIsPressingAttack[client] = false;
	
	if(g_bIsPressingAttack[client])
	{
		buttons &= ~IN_ATTACK;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action:Command_BuyIon(client, args)
{
	if(!GetConVarBool(g_hCVBuy))
	{
		CPrintToChatAll("%s Ion cannon buying is disabled.", PREFIX);
		return Plugin_Handled;
	}
	
	new iPrice = GetConVarInt(g_hCVPrice), iMoney;
	
	if(iPrice > 0)
	{
		iMoney = GetEntProp(client, Prop_Send, "m_iAccount");
		
		if(iMoney < iPrice)
		{
			CPrintToChatAll("%s You don't have enough money to buy an ion cannon. $%d needed.", PREFIX, iPrice);
			return Plugin_Handled;
		}
	}
	
	new iMaxAmmo = GetConVarInt(g_hCVMaxAmmo);
	
	if(g_iIonCannonAmmo[client]+1 > iMaxAmmo)
	{
		CPrintToChatAll("%s You're only allowed to buy %d ion cannons at a time.", PREFIX, iMaxAmmo);
		return Plugin_Handled;
	}
	
	// Increase ammo and get the money
	g_iIonCannonAmmo[client]++;
	if(iPrice > 0)
		SetEntProp(client, Prop_Send, "m_iAccount", iMoney-iPrice);
	
	CPrintToChatAll("%s You bought an ion cannon for $%d. Place it with your knife.", PREFIX, iPrice);
	
	return Plugin_Handled;
}

public Action:Command_GiveIon(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "Ion Cannon > Usage: sm_giveion <#userid|steamid|name>");
		return Plugin_Handled;
	}
	
	new String:sTarget[50];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	
	new iTarget = FindTarget(client, sTarget, false, false);
	if(iTarget == -1)
		return Plugin_Handled;
	
	g_iIonCannonAmmo[iTarget]++;
	
	CPrintToChat(client, "%s You gave %N an ion cannon.", PREFIX, iTarget);
	CPrintToChat(iTarget, "%s %N gave you an ion cannon. Place it with your knife.", PREFIX, client);
	
	return Plugin_Handled;
}

public Action:Timer_OnUpdatePlaceCountdown(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || g_iFireWeaponStartTime[client] == 0)
	{
		g_hFiringWeaponCountdown[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	new iDifference = GetConVarInt(g_hCVPlaceTime) - GetTime() + g_iFireWeaponStartTime[client];
	if(iDifference < 1)
	{
		g_hFiringWeaponCountdown[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	PrintCenterText(client, "Placing an ion cannon (%d seconds)", iDifference);
	
	return Plugin_Continue;
}

public Action:Timer_OnIonPlanted(Handle:timer, any:client)
{
	CPrintToChatAll("%s%N deployed an {red}ion cannon{green} beacon.", PREFIX, client);
	#if defined ALTERNATIVE_SOUNDS
	StopSound(client, SNDCHAN_AUTO, "weapons/physcannon/superphys_hold_loop.wav");
	StopSound(client, SNDCHAN_AUTO, "weapons/physgun_off.wav");
	#else
	EmitSoundToAll(SOUND_PLANT, SOUND_FROM_PLAYER, SNDCHAN_WEAPON);
	#endif
	
	g_hFiringWeapon[client] = INVALID_HANDLE;
	
	if(g_bUseProgressBar)
	{
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
	}
	
	g_iInfoTargetEntity[client] = CreateEntityByName("info_target");
	if(g_iInfoTargetEntity[client] == -1)
		return Plugin_Stop;
	
	DispatchKeyValue(g_iInfoTargetEntity[client], "targetname", "info_target_ion");
	SetEntityModel(g_iInfoTargetEntity[client], ION_MODEL);
	
	SetEntityMoveType(g_iInfoTargetEntity[client], MOVETYPE_NONE);
	SetEntPropEnt(g_iInfoTargetEntity[client], Prop_Data, "m_hOwnerEntity", client);
	SetEntProp(g_iInfoTargetEntity[client], Prop_Send, "m_nSolidType", 6);
	
	new enteffects = GetEntProp(g_iInfoTargetEntity[client], Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(g_iInfoTargetEntity[client], Prop_Send, "m_fEffects", enteffects);
	
	GetClientAbsOrigin(client, g_fInfoTargetOrigin[client]);
	TeleportEntity(g_iInfoTargetEntity[client], g_fInfoTargetOrigin[client], NULL_VECTOR, NULL_VECTOR);
	
	TE_SetupGlowSprite(g_fInfoTargetOrigin[client], g_iGlowSprite, 3.0, 1.0, 100);
	TE_SendToAll();
	
	#if defined ALTERNATIVE_SOUNDS
	EmitSoundToAll("vehicles/tank_turret_stop1.wav", g_iInfoTargetEntity[client], SNDCHAN_ITEM, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, g_iBeaconBeepPitch[client]);
	#else
	EmitSoundToAll(SOUND_BEEP, g_iInfoTargetEntity[client], SNDCHAN_ITEM, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, g_iBeaconBeepPitch[client]);
	#endif
	CreateTimer(g_fBeaconBeepTime[client], Timer_OnPlayBeaconBeep, client, TIMER_FLAG_NO_MAPCHANGE);
	
	CreateTimer(5.0, Timer_OnIonStartup, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action:Timer_OnPlayBeaconBeep(Handle:timer, any:client)
{
	if(g_iInfoTargetEntity[client] == -1)
		return Plugin_Stop;
	
	g_iBeaconBeepPitch[client] += 3;
	g_fBeaconBeepTime[client] -= 0.03;
	if(g_iBeaconBeepPitch[client] > 255) 
		g_iBeaconBeepPitch[client] = 255;
	if(g_fBeaconBeepTime[client] < 0.3) 
		g_fBeaconBeepTime[client] = 0.3;
	
	#if defined ALTERNATIVE_SOUNDS
	EmitSoundToAll("vehicles/tank_turret_stop1.wav", g_iInfoTargetEntity[client], SNDCHAN_ITEM, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, g_iBeaconBeepPitch[client]);
	#else
	EmitSoundToAll(SOUND_BEEP, g_iInfoTargetEntity[client], SNDCHAN_ITEM, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, g_iBeaconBeepPitch[client]);
	#endif
	
	CreateTimer(g_fBeaconBeepTime[client], Timer_OnPlayBeaconBeep, client, TIMER_FLAG_NO_MAPCHANGE);
	
	TE_SetupGlowSprite(g_fInfoTargetOrigin[client], g_iGlowSprite, g_fBeaconBeepTime[client], 1.0, 100);
	TE_SendToAll();
	
	return Plugin_Stop;
}

public Action:Timer_OnIonStartup(Handle:timer, any:client)
{
	if(g_iInfoTargetEntity[client] == -1)
		return Plugin_Stop;
	
	#if defined ALTERNATIVE_SOUNDS
	#else
	EmitSoundToAll(SOUND_APPROACH);
	#endif
	CPrintToChatAll("%sWarning - {red}ion cannon{green} satellite approaching.", PREFIX);
	CreateTimer(GetConVarFloat(g_hCVDeployTime), Timer_OnTraceReady, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action:Timer_OnTraceReady(Handle:timer, any:client)
{
	if(g_iInfoTargetEntity[client] == -1)
		return Plugin_Stop;
	
	// 1st
	g_fBeamOrigin[client][0][0] = g_fInfoTargetOrigin[client][0] + 300.0;
	g_fBeamOrigin[client][0][1] = g_fInfoTargetOrigin[client][1] + 150.0;
	g_fBeamOrigin[client][0][2] = g_fInfoTargetOrigin[client][2];
	g_fBeamDegrees[client][0] = 0.0;
	
	// 2nd
	g_fBeamOrigin[client][1][0] = g_fInfoTargetOrigin[client][0] + 300.0;
	g_fBeamOrigin[client][1][1] = g_fInfoTargetOrigin[client][1] - 150.0;
	g_fBeamOrigin[client][1][2] = g_fInfoTargetOrigin[client][2];
	g_fBeamDegrees[client][1] = 45.0;
	
	// 3rd
	g_fBeamOrigin[client][2][0] = g_fInfoTargetOrigin[client][0] - 300.0;
	g_fBeamOrigin[client][2][1] = g_fInfoTargetOrigin[client][1] - 150.0;
	g_fBeamOrigin[client][2][2] = g_fInfoTargetOrigin[client][2];
	g_fBeamDegrees[client][2] = 90.0;
	
	// 4th
	g_fBeamOrigin[client][3][0] = g_fInfoTargetOrigin[client][0] - 300.0;
	g_fBeamOrigin[client][3][1] = g_fInfoTargetOrigin[client][1] + 150.0;
	g_fBeamOrigin[client][3][2] = g_fInfoTargetOrigin[client][2];
	g_fBeamDegrees[client][3] = 135.0;
	
	// 5th
	g_fBeamOrigin[client][4][0] = g_fInfoTargetOrigin[client][0] + 150.0;
	g_fBeamOrigin[client][4][1] = g_fInfoTargetOrigin[client][1] + 300.0;
	g_fBeamOrigin[client][4][2] = g_fInfoTargetOrigin[client][2];
	g_fBeamDegrees[client][4] = 180.0;
	
	// 6th
	g_fBeamOrigin[client][5][0] = g_fInfoTargetOrigin[client][0] + 150.0;
	g_fBeamOrigin[client][5][1] = g_fInfoTargetOrigin[client][1] - 300.0;
	g_fBeamOrigin[client][5][2] = g_fInfoTargetOrigin[client][2];
	g_fBeamDegrees[client][5] = 225.0;
	
	// 7th
	g_fBeamOrigin[client][6][0] = g_fInfoTargetOrigin[client][0] - 150.0;
	g_fBeamOrigin[client][6][1] = g_fInfoTargetOrigin[client][1] - 300.0;
	g_fBeamOrigin[client][6][2] = g_fInfoTargetOrigin[client][2];
	g_fBeamDegrees[client][6] = 270.0;
	
	// 8th
	g_fBeamOrigin[client][7][0] = g_fInfoTargetOrigin[client][0] - 150.0;
	g_fBeamOrigin[client][7][1] = g_fInfoTargetOrigin[client][1] + 300.0;
	g_fBeamOrigin[client][7][2] = g_fInfoTargetOrigin[client][2];
	g_fBeamDegrees[client][7] = 315.0;
	
	g_bShowBeams[client] = true;
	
	// Show traces
	new Float:fTime = 0.0;
	new Handle:hDataPack[8];
	for(new i = 0; i<8;i++)
	{
		fTime += 0.3;
		hDataPack[i] = CreateDataPack();
		WritePackCell(hDataPack[i], i);
		WritePackCell(hDataPack[i], client);
		ResetPack(hDataPack[i]);
		
		CreateTimer(fTime, Timer_OnTraceStart, hDataPack[i], TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	}
	
	//Timer_OnLaserRotate(INVALID_HANDLE, client);
	#if defined ALTERNATIVE_SOUNDS
	EmitSoundToAll("ambient/machines/laundry_machine1_amb.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	EmitSoundToAll("ambient/machines/floodgate_stop1.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	CreateTimer(1.0, Timer_PlayerAlternativeSounds, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	#else
	EmitSoundToAll(SOUND_READY, g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	#endif
	
	for(new Float:i = 0.0; i<7.5;i+=0.01)
	{
		CreateTimer(i+3.0, Timer_OnLaserRotate, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	CreateTimer(2.9, Timer_OnAddSpeed, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(11.5, Timer_OnCreateFire, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(12.5, Timer_OnClearLasers, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(15.2, Timer_OnFireIonCannon, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action:Timer_OnTraceStart(Handle:timer, any:data)
{
	new i = ReadPackCell(data);
	new client = ReadPackCell(data);
	
	if(g_iInfoTargetEntity[client] == -1)
		return Plugin_Stop;
	
	g_fSkyOrigin[client] = GetDistanceToSky(g_iInfoTargetEntity[client]);
	new Float:fRandomZ = Math_GetRandomFloat(300.0, g_fSkyOrigin[client][2]);
	
	new Float:fBeamOrigin[3];
	fBeamOrigin[0] = g_fBeamOrigin[client][i][0];
	fBeamOrigin[1] = g_fBeamOrigin[client][i][1];
	fBeamOrigin[2] = g_fBeamOrigin[client][i][2] + fRandomZ;
	
	TE_SetupGlowSprite(fBeamOrigin, g_iGlowSprite, 2.0, 10.0, 100);
	TE_SendToAll();
	
	new Handle:hDataPack = CreateDataPack();
	WritePackCell(hDataPack, i);
	WritePackCell(hDataPack, client);
	ResetPack(hDataPack);
	
	#if defined ALTERNATIVE_SOUNDS
	EmitSoundToAll("buttons/button19.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, 30);
	#endif
	
	ShowBeam(hDataPack);
	return Plugin_Stop;
}

ShowBeam(Handle:data)
{
	new i = ReadPackCell(data);
	new client = ReadPackCell(data);

	if(g_iInfoTargetEntity[client] == -1 || !g_bShowBeams[client])
		return;
	
	new Float:fStart[3];
	fStart[0] = g_fBeamOrigin[client][i][0];
	fStart[1] = g_fBeamOrigin[client][i][1];
	fStart[2] = g_fSkyOrigin[client][2];
	
	TE_SetupBeamPoints(fStart, g_fBeamOrigin[client][i], g_iLaserSprite, g_iHaloSprite, 0, 0, 0.08, 30.0, 30.0, 0, 0.0, {255, 255, 255, 255}, 20);
	TE_SendToAll();
	
	TE_SetupGlowSprite(g_fBeamOrigin[client][i], g_iGlowSprite, 0.03, 5.0, 100);
	TE_SendToAll();
	
	new Handle:hDataPack = CreateDataPack();
	WritePackCell(hDataPack, i);
	WritePackCell(hDataPack, client);
	ResetPack(hDataPack);
	
	CreateTimer(0.01, Timer_OnShowBeam, hDataPack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
}

public Action:Timer_OnShowBeam(Handle:timer, any:data)
{
	ShowBeam(data);
	return Plugin_Stop;
}

#if defined ALTERNATIVE_SOUNDS
public Action:Timer_PlayerAlternativeSounds(Handle:timer, any:client)
{
	if(g_iInfoTargetEntity[client] == -1 || !g_bShowBeams[client])
		return Plugin_Stop;
	
	EmitSoundToAll("ambient/levels/streetwar/strider_distant2.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	
	decl String:sSound[128];
	Format(sSound, sizeof(sSound), "ambient/wind/wind_hit%d.wav", Math_GetRandomInt(1,3));
	EmitSoundToAll(sSound, g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	
	Format(sSound, sizeof(sSound), "ambient/levels/labs/electric_explosion%d.wav", Math_GetRandomInt(1,5));
	EmitSoundToAll(sSound, g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	
	return Plugin_Continue;
}
#endif

public Action:Timer_OnLaserRotate(Handle:timer, any:client)
{
	if(g_iInfoTargetEntity[client] == -1 || !g_bShowBeams[client])
		return Plugin_Stop;
	
	g_fBeamDistance[client] -= 0.467;
	for(new i=0;i<8;i++)
	{
		// Calculate the alpha
		g_fBeamDegrees[client][i] += g_fBeamRotationSpeed[client];
		if(g_fBeamDegrees[client][i] > 360.0)
			g_fBeamDegrees[client][i] -= 360.0;
		
		// Calculate the next origin
		g_fBeamOrigin[client][i][0] = g_fInfoTargetOrigin[client][0] + Sine(g_fBeamDegrees[client][i]) * g_fBeamDistance[client];
		g_fBeamOrigin[client][i][1] = g_fInfoTargetOrigin[client][1] + Cosine(g_fBeamDegrees[client][i]) * g_fBeamDistance[client];
		g_fBeamOrigin[client][i][2] = g_fInfoTargetOrigin[client][2] + 0.0;
	}
	return Plugin_Stop;
}

public Action:Timer_OnAddSpeed(Handle:timer, any:client)
{
	if(g_iInfoTargetEntity[client] == -1 || !g_bShowBeams[client])
		return Plugin_Stop;
	
	if(g_fBeamRotationSpeed[client] > 1.0)
		g_fBeamRotationSpeed[client] = 1.0;
	
	g_fBeamRotationSpeed[client] += 0.1;
	
	CreateTimer(0.6, Timer_OnAddSpeed, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action:Timer_OnCreateFire(Handle:timer, any:client)
{
	if(g_iInfoTargetEntity[client] == -1)
		return Plugin_Stop;
	
	new iFire = CreateEntityByName("env_fire");
	if(iFire != -1)
	{
		TeleportEntity(iFire, g_fInfoTargetOrigin[client], NULL_VECTOR, NULL_VECTOR);
		// Amount of time the fire will burn (in seconds). 
		DispatchKeyValue(iFire, "health", "2");
		// Height (in world units) of the flame. The flame will get proportionally wider as it gets higher. 
		DispatchKeyValue(iFire, "firesize", "200");
		// Amount of time the fire takes to grow to full strength. Set higher to make the flame build slowly. 
		DispatchKeyValue(iFire, "fireattack", "2");
		// Either Normal or Plasma. Natural is a general all purpose flame, like a wood fire. 
		DispatchKeyValue(iFire, "firetype", "Normal");
		// Multiplier of the burn damage done by the flame. Flames damage all the time, but can be made to hurt more. This number multiplies damage by 1(so 50 = 50 damage). It hurts every second. 
		DispatchKeyValue(iFire, "damagescale", "1.0");
		// delete when out
		SetVariantString("spawnflags 128");
		AcceptEntityInput(iFire,"AddOutput");
		
		DispatchSpawn(iFire);
		
		ActivateEntity(iFire);
		AcceptEntityInput(iFire, "StartFire", client);
	}
	
	CreateTimer(1.5, Timer_OnCreateFire, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action:Timer_OnClearLasers(Handle:timer, any:client)
{
	if(g_iInfoTargetEntity[client] == -1)
		return Plugin_Stop;
	
	g_bShowBeams[client] = false;
	
	#if defined ALTERNATIVE_SOUNDS
	EmitSoundToAll("ambient/levels/labs/teleport_preblast_suckin1.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, 60);
	EmitSoundToAll("ambient/levels/citadel/zapper_warmup1.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, 60);
	#endif
	
	return Plugin_Stop;
}

public Action:Timer_OnFireIonCannon(Handle:timer, any:client)
{
	if(g_iInfoTargetEntity[client] == -1)
		return Plugin_Stop;
	
	new Float:fIonRadius = GetConVarFloat(g_hCVRadius);
	new Float:fMinDamage = GetConVarFloat(g_hCVMinDamage);
	new Float:fMaxDamage = GetConVarFloat(g_hCVMaxDamage);
	
	// Shake player's screens if in range
	new Float:fPlayerOrigin[3], Float:fVecConnecting[3], Float:fDirectionAngle[3], Float:fEndPosition[3];
	new Float:fShakeTime = GetConVarFloat(g_hCVShakeTime);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, fPlayerOrigin);
			fPlayerOrigin[2] += 50.0;
			MakeVectorFromPoints(g_fInfoTargetOrigin[client], fPlayerOrigin, fVecConnecting);
			GetVectorAngles(fVecConnecting, fDirectionAngle);
			TR_TraceRayFilter(g_fInfoTargetOrigin[client], fDirectionAngle, CONTENTS_PLAYERCLIP, RayType_Infinite, TraceRay_PlayerOnly, i);
			if(TR_DidHit())
			{
				TR_GetEndPosition(fEndPosition);
				if(GetDistance(g_fInfoTargetOrigin[client], fEndPosition) <= fIonRadius + 8000.0)
					Client_Shake(i, SHAKE_START, 255.0, 255.0, fShakeTime);
			}
		}
	}
	
	// Play effects
	TE_SetupBeamPoints(g_fSkyOrigin[client], g_fInfoTargetOrigin[client], g_iLaserSprite, g_iHaloSprite, 0, 10, 15.0, 100.0, 100.0, 10, 4.0, {255, 255, 255, 255}, 0);
	
	TE_SetupBeamPoints(g_fSkyOrigin[client], g_fInfoTargetOrigin[client], g_iLaserSprite, g_iHaloSprite, 0, 10, 15.0, 100.0, 100.0, 10, 4.0, {255, 255, 255, 255}, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(g_fSkyOrigin[client], g_fInfoTargetOrigin[client], g_iLaserSprite, g_iHaloSprite, 0, 30, 10.0, 60.0, 60.0, 10, 5.0, {0, 100, 250, 100}, 20);
	
	TE_SetupBeamPoints(g_fSkyOrigin[client], g_fInfoTargetOrigin[client], g_iLaserSprite, g_iHaloSprite, 0, 30, 10.0, 60.0, 60.0, 10, 5.0, {0, 100, 250, 100}, 20);
	TE_SendToAll();
	
	new Float:fBeamHigh[3];
	fBeamHigh[0] = g_fInfoTargetOrigin[client][0];
	fBeamHigh[1] = g_fInfoTargetOrigin[client][1];
	fBeamHigh[2] = g_fInfoTargetOrigin[client][2]+20.0;
	
	TE_SetupBeamRingPoint(fBeamHigh, 0.0, fIonRadius - 1000.0, g_iLaserSprite, g_iHaloSprite, 0, 30, 20.0, 100.0, 2.0, {0, 100, 250, 100}, 0, 0);
	
	TE_SetupBeamRingPoint(fBeamHigh, 0.0, fIonRadius - 1000.0, g_iLaserSprite, g_iHaloSprite, 0, 30, 20.0, 100.0, 2.0, {0, 100, 250, 100}, 10, 0);
	
	TE_SetupBeamRingPoint(fBeamHigh, 0.0, fIonRadius - 1000.0, g_iLaserSprite, g_iHaloSprite, 0, 30, 20.0, 100.0, 2.0, {0, 100, 250, 100}, 20, 0);
	
	TE_SetupBeamRingPoint(fBeamHigh, 0.0, fIonRadius - 1000.0, g_iLaserSprite, g_iHaloSprite, 0, 30, 20.0, 100.0, 2.0, {0, 100, 250, 100}, 30, 0);
	TE_SendToAll();
	
	for(new i=0;i<=300;i+=30)
	{
		TE_SetupBeamRingPoint(fBeamHigh, 0.0, fIonRadius, g_iLaserSprite, g_iHaloSprite, 0, 30, 10.0, 100.0, 5.0, {255, 255, 255, 200}, 300-i, 0);
		TE_SendToAll();
	}
	
	fBeamHigh[2] += 80.0;
	
	for(new i=0;i<=300;i+=30)
	{
		TE_SetupBeamRingPoint(fBeamHigh, 0.0, fIonRadius, g_iLaserSprite, g_iHaloSprite, 0, 30, 10.0, 100.0, 5.0, {255, 255, 255, 200}, 300-i, 0);
		TE_SendToAll();
	}
	
	fBeamHigh[2] += 80.0;
	
	for(new i=0;i<=300;i+=30)
	{
		TE_SetupBeamRingPoint(fBeamHigh, 0.0, fIonRadius, g_iLaserSprite, g_iHaloSprite, 0, 30, 10.0, 100.0, 5.0, {200, 255, 255, 200}, 300-i, 0);
		TE_SendToAll();
	}
	
	fBeamHigh[2] -= 160.0;
	
	new Float:fMagnitude = Math_GetRandomFloat(fMinDamage, fMaxDamage);
	
	// Create explosion
	new iExplosion = CreateEntityByName("env_explosion");
	if(iExplosion != -1)
	{
		TeleportEntity(iExplosion, g_fInfoTargetOrigin[client], NULL_VECTOR, NULL_VECTOR);
		//DispatchKeyValue(iExplosion, "fireballsprite", "materials/sprites/xfireball3.vtf");
		SetEntProp(iExplosion, Prop_Data, "m_sFireballSprite", g_iExplosionModel);
		// The amount of damage done by the explosion. 
		SetEntProp(iExplosion, Prop_Data, "m_iMagnitude", RoundToNearest(fMagnitude));
		// If specified, the radius in which the explosion damages entities. If unspecified, the radius will be based on the magnitude. 
		SetEntProp(iExplosion, Prop_Data, "m_iRadiusOverride", RoundToNearest(fIonRadius));
		// Who get's the frag if someone gets killed by the explosion
		SetEntPropEnt(iExplosion, Prop_Data, "m_hOwnerEntity", client);
		// Damagetype
		SetEntProp(iExplosion, Prop_Data, "m_iCustomDamageType", DMG_BLAST);
		SetEntProp(iExplosion, Prop_Data, "m_nRenderMode", 5); // Additive
		DispatchSpawn(iExplosion);
		ActivateEntity(iExplosion);
		AcceptEntityInput(iExplosion, "Explode", client, client);
	}
	
	// Show smoke
	TE_SetupSmoke(fBeamHigh, g_iSmokeSprite1, 350.0, 15);
	TE_SetupSmoke(fBeamHigh, g_iSmokeSprite2, 350.0, 15);
	TE_SetupDust(fBeamHigh, Float:{0.0,0.0,0.0}, 150.0, 15.0);
	TE_SendToAll();
	
	TE_SetupExplosion(g_fInfoTargetOrigin[client], g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(fIonRadius), RoundToNearest(fMagnitude));
	
	TE_SetupExplosion(fBeamHigh, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(fIonRadius), RoundToNearest(fMagnitude));
	
	fBeamHigh[2] += 500.0;
	TE_SetupExplosion(fBeamHigh, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(fIonRadius), RoundToNearest(fMagnitude));
	
	fBeamHigh[2] -= 100.0;
	fBeamHigh[1] += 600.0;
	TE_SetupExplosion(fBeamHigh, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(fIonRadius), RoundToNearest(fMagnitude));
	
	fBeamHigh[0] -= 1600.0;
	TE_SetupExplosion(fBeamHigh, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(fIonRadius), RoundToNearest(fMagnitude));
	
	fBeamHigh[1] += 600.0;
	TE_SetupExplosion(fBeamHigh, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(fIonRadius), RoundToNearest(fMagnitude));
	
	fBeamHigh[1] -= 600.0;
	fBeamHigh[0] += 600.0;
	TE_SetupExplosion(fBeamHigh, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(fIonRadius), RoundToNearest(fMagnitude));
	TE_SendToAll();
	
	for(new Float:i = 0.1;i<=12.0;i+=0.1)
		CreateTimer(i, Timer_ShowExplosions, client, TIMER_FLAG_NO_MAPCHANGE);
	
	
	new Float:fDirection[3] = {-90.0,0.0,0.0};
	new Float:fAmount = GetConVarFloat(g_hCVGlowSprites);
	env_shooter(client, fDirection, fAmount, 0.1, fDirection, 1200.0, 5.0, 20.5, g_fInfoTargetOrigin[client], "materials/sprites/flare1.vmt");
	
	env_shooter(client, fDirection, fAmount, 0.1, fDirection, 500.0, 5.0, 15.5, g_fInfoTargetOrigin[client], "materials/sprites/flare1.vmt");
	
	new iFire = CreateEntityByName("env_fire");
	if(iFire != -1)
	{
		TeleportEntity(iFire, g_fInfoTargetOrigin[client], NULL_VECTOR, NULL_VECTOR);
		// Amount of time the fire will burn (in seconds). 
		DispatchKeyValue(iFire, "health", "30");
		// Height (in world units) of the flame. The flame will get proportionally wider as it gets higher. 
		DispatchKeyValue(iFire, "firesize", "1000");
		// Amount of time the fire takes to grow to full strength. Set higher to make the flame build slowly. 
		DispatchKeyValue(iFire, "fireattack", "1");
		// Either Normal or Plasma. Natural is a general all purpose flame, like a wood fire. 
		DispatchKeyValue(iFire, "firetype", "Plasma");
		// Multiplier of the burn damage done by the flame. Flames damage all the time, but can be made to hurt more. This number multiplies damage by 1(so 50 = 50 damage). It hurts every second. 
		DispatchKeyValue(iFire, "damagescale", "100");
		// delete when out
		SetVariantString("spawnflags 128");
		AcceptEntityInput(iFire,"AddOutput");
		
		DispatchSpawn(iFire);
		
		ActivateEntity(iFire);
		AcceptEntityInput(iFire, "StartFire", client);
	}
	
	#if defined ALTERNATIVE_SOUNDS
	EmitSoundToAll("ambient/explosions/exp1.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	EmitSoundToAll("ambient/explosions/explode_2.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	EmitSoundToAll("ambient/explosions/explode_6.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	EmitSoundToAll("ambient/levels/citadel/drone1lp.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	EmitSoundToAll("ambient/levels/labs/electric_explosion1.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	EmitSoundToAll("ambient/wind/wasteland_wind.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	EmitSoundToAll("ambient/wind/windgust_strong.wav", g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	CreateTimer(30.0, Timer_StopSound, client, TIMER_FLAG_NO_MAPCHANGE);
	#else
	EmitSoundToAll(SOUND_ATTACK, g_iInfoTargetEntity[client], SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	#endif
	
	AcceptEntityInput(g_iInfoTargetEntity[client], "Kill");
	g_iInfoTargetEntity[client] = -1;
	
	return Plugin_Stop;
}

public Action:Timer_ShowExplosions(Handle:timer, any:client)
{
	new Float:fIonRadius = GetConVarFloat(g_hCVRadius);
	new Float:fMinDamage = GetConVarFloat(g_hCVMinDamage);
	new Float:fMaxDamage = GetConVarFloat(g_hCVMaxDamage);
	
	// The actual magnitude is unimportant, since this is only an effect
	new Float:fMagnitude = Math_GetRandomFloat(fMinDamage, fMaxDamage);
	
	for(new x=0;x<=30;x++)
	{
		g_fBeamDistance[client] += 1.467;
		if(g_fBeamDistance[client] > 350.0)
			g_fBeamDistance[client] = 0.0;
		for(new i=0;i<8;i++)
		{
			// Calculate the alpha
			g_fBeamDegrees[client][i] += 30.0;
			if(g_fBeamDegrees[client][i] > 360.0)
				g_fBeamDegrees[client][i] -= 360.0;
			
			// Calculate the next origin
			g_fBeamOrigin[client][i][0] = g_fInfoTargetOrigin[client][0] + Sine(g_fBeamDegrees[client][i]) * g_fBeamDistance[client];
			g_fBeamOrigin[client][i][1] = g_fInfoTargetOrigin[client][1] + Cosine(g_fBeamDegrees[client][i]) * g_fBeamDistance[client];
			g_fBeamOrigin[client][i][2] = g_fInfoTargetOrigin[client][2] + 0.0;
			
			TE_SetupExplosion(g_fBeamOrigin[client][i], g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(fIonRadius), RoundToNearest(fMagnitude));
			TE_SendToAll();
		}
	}
	return Plugin_Stop;
}

public Action:Timer_RemoveRagdoll(Handle:timer, any:data)
{
	if(IsValidEntity(data))
		AcceptEntityInput(data, "Kill");
}

public Action:Timer_StopSound(Handle:timer, any:data)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
		{
			StopSound(i, SNDCHAN_AUTO, "ambient/wind/windgust_strong.wav");
			StopSound(i, SNDCHAN_AUTO, "ambient/wind/wasteland_wind.wav");
			StopSound(i, SNDCHAN_AUTO, "ambient/levels/citadel/drone1lp.wav");
		}
	}
}

public bool:TraceRay_PlayerOnly(entity, contentsMask, any:data)
{
	if (entity == data)
	{
		return true;
	}
	else
	{
		return false;
	}
}

stock Float:GetDistanceToSky(entity)
{
	new Float:TraceEnd[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TraceEnd);

	new Float:f_dest[3];
	f_dest[0] = TraceEnd[0];
	f_dest[1] = TraceEnd[1];
	f_dest[2] = TraceEnd[2] + 8192.0;

	new Float:SkyOrigin[3];
	new Handle:hTrace = TR_TraceRayEx(TraceEnd, f_dest, CONTENTS_WINDOW|CONTENTS_MONSTER, RayType_EndPoint);
	TR_GetEndPosition(SkyOrigin, hTrace);
	CloseHandle(hTrace);

	return SkyOrigin;
}


// This is stupid and does not work at all.
/*stock bool:IsClientOutside(client)
{
	new Float:fPlayerOrigin[3];
	GetClientAbsOrigin(client, fPlayerOrigin);
	
	new iEnt;
	
	while(TR_GetPointContents(fPlayerOrigin, iEnt) == CONTENTS_EMPTY)
		fPlayerOrigin[2] += 5.0;
	
	if(TR_GetPointContents(fPlayerOrigin, iEnt) & CONTENTS_DETAIL)
		return true;
	
	return false;
}*/

Float:GetDistance(const Float:vec1[3], const Float:vec2[3])
{
	decl Float:x, Float:y, Float:z;
	
	x = vec1[0] - vec2[0];
	y = vec1[1] - vec2[1];
	z = vec1[2] - vec2[2];
	
	return SquareRoot(x*x + y*y + z*z);
}

// Thanks to V0gelz
stock env_shooter(client ,Float:Angles[3], Float:iGibs, Float:Delay, Float:GibAngles[3], Float:Velocity, Float:Variance, Float:Giblife, Float:Location[3], String:ModelType[] )
{
	//decl Ent;

	//Initialize:
	new Ent = CreateEntityByName("env_shooter");
		
	//Spawn:

	if (Ent == -1)
	return;

  	//if (Ent>0 && IsValidEdict(Ent))

	if(Ent>0 && IsValidEntity(Ent) && IsValidEdict(Ent))
  	{

		//Properties:
		//DispatchKeyValue(Ent, "targetname", "flare");

		// Gib Direction (Pitch Yaw Roll) - The direction the gibs will fly. 
		DispatchKeyValueVector(Ent, "angles", Angles);
	
		// Number of Gibs - Total number of gibs to shoot each time it's activated
		DispatchKeyValueFloat(Ent, "m_iGibs", iGibs);

		// Delay between shots - Delay (in seconds) between shooting each gib. If 0, all gibs shoot at once.
		DispatchKeyValueFloat(Ent, "delay", Delay);

		// <angles> Gib Angles (Pitch Yaw Roll) - The orientation of the spawned gibs. 
		DispatchKeyValueVector(Ent, "gibangles", GibAngles);

		// Gib Velocity - Speed of the fired gibs. 
		DispatchKeyValueFloat(Ent, "m_flVelocity", Velocity);

		// Course Variance - How much variance in the direction gibs are fired. 
		DispatchKeyValueFloat(Ent, "m_flVariance", Variance);

		// Gib Life - Time in seconds for gibs to live +/- 5%. 
		DispatchKeyValueFloat(Ent, "m_flGibLife", Giblife);
		
		// <choices> Used to set a non-standard rendering mode on this entity. See also 'FX Amount' and 'FX Color'. 
		DispatchKeyValue(Ent, "rendermode", "5");

		// Model - Thing to shoot out. Can be a .mdl (model) or a .vmt (material/sprite). 
		DispatchKeyValue(Ent, "shootmodel", ModelType);

		// <choices> Material Sound
		DispatchKeyValue(Ent, "shootsounds", "-1"); // No sound

		// <choices> Simulate, no idea what it realy does tbh...
		// could find out but to lazy and not worth it...
		//DispatchKeyValue(Ent, "simulation", "1");

		SetVariantString("spawnflags 4");
		AcceptEntityInput(Ent,"AddOutput");

		ActivateEntity(Ent);

		//Input:
		// Shoot!
		AcceptEntityInput(Ent, "Shoot", client);
			
		//Send:
		TeleportEntity(Ent, Location, NULL_VECTOR, NULL_VECTOR);

		//Delete:
		//AcceptEntityInput(Ent, "kill");
		CreateTimer(3.0, Timer_KillEnt, Ent);
	}
}


public Action:Timer_KillEnt(Handle:Timer, any:Ent)
{
        if(IsValidEntity(Ent))
        {
                decl String:classname[64];
                GetEdictClassname(Ent, classname, sizeof(classname));
                if (StrEqual(classname, "env_shooter", false) || StrEqual(classname, "gib", false) || StrEqual(classname, "env_sprite", false))
                {
                        RemoveEdict(Ent);
                }
        }
}