#include <sourcemod>
#include <tf2>
#include <tf2items>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <weapons>

#define MAX_FILE_LEN 100

/*
Skill Hud Channel
1. SHIFT
2. E
3. Ulti
4. Skill2
5. RELOADING!
6. UltiGage
7. Miscs
*/

new g_Disableow[10];

new bool:g_NoFire[MAXPLAYERS+1];

new Float:UltimateGage[MAXPLAYERS+1]; 

//Sounds
new s_Toggle[MAXPLAYERS+1], s_Damage[MAXPLAYERS+1], s_DamageMax[MAXPLAYERS+1], s_AFK[MAXPLAYERS+1];

new g_Champion[MAXPLAYERS+1], g_BasSecure[MAXPLAYERS+1]; // m_iScore m_iKillAssists m_iRevenge m_iDominations

//Bastion
new g_BasReload[MAXPLAYERS+1], bool:g_OnBasHeal[MAXPLAYERS+1], bool:g_AllowBasHeal[MAXPLAYERS+1];

new g_BasUltimate[MAXPLAYERS+1], Float:g_BasUltimateCooldown[MAXPLAYERS+1];

//Reinhart
new g_ReinCharge[MAXPLAYERS+1], g_ReinCharge_teleTimer[MAXPLAYERS+1], g_ReinChargeAllow[MAXPLAYERS+1] = 1;
new g_ReinChargeTarget[MAXPLAYERS+1];

new bool:g_ReinShield[MAXPLAYERS+1],	g_ReinShieldHealth[MAXPLAYERS+1], bool:g_StartShieldRegen[MAXPLAYERS+1];
new g_ReinEntity[MAXPLAYERS+1] = -1, bool:g_AllowReinTimer[MAXPLAYERS+1];
new bool:g_SetAnim[MAXPLAYERS+1], g_CollisionOffset;
new bool:g_reinbreak[MAXPLAYERS+1];

//Tracer
// Tracer Flash
new g_TracerFlash[MAXPLAYERS+1], g_TracerTimer1[MAXPLAYERS+1], g_TracerTimer2[MAXPLAYERS+1], g_TracerTimer3[MAXPLAYERS+1];
new Float:g_TracerFlashFirstpos[3], g_AllowFlash[MAXPLAYERS+1];
new g_TracerFlashPosi[MAXPLAYERS+1];

//Tracer Rewind
new Float:g_flRewind[MAXPLAYERS+1], bool:g_TracerRewind[MAXPLAYERS+1], bool:g_AllowRewind[MAXPLAYERS+1];
ArrayList g_TracerPos[MAXPLAYERS + 1];
ArrayList g_TracerAng[MAXPLAYERS + 1];
ArrayList g_TracerHealth[MAXPLAYERS + 1];

// Tracer Bomb
new bool:g_TracerOnThrowBomb[MAXPLAYERS+1], g_TracerBombTarget[MAXPLAYERS+1];
new g_iPulseBomb[MAXPLAYERS+1] = -1;

//Soldier:76
//Soldier Gun, Reload, Missile
new bool:g_SoldierDash[MAXPLAYERS+1], Float:g_SoldierMissleCool[MAXPLAYERS+1];
new bool:g_SoldReload[MAXPLAYERS+1];

//Soldier Heal
new g_OnSoldHeal[MAXPLAYERS+1], Float:g_flSoldHeal[MAXPLAYERS+1];
new g_iHealBox[MAXPLAYERS+1] = -1;

//Soldier Ult
new bool:g_OnSoldUlti[MAXPLAYERS+1], Float:g_SoldUltCool[MAXPLAYERS+1];
new ClientEyes[MAXPLAYERS+1];
new ActiveWeapon[MAXPLAYERS+1];
new Float:FOISpeed = 1000000.0;
new g_iPlayerDesiredFOV[MAXPLAYERS+1];
new bool:g_bToHead[MAXPLAYERS+1];

//McCree
//McCree Slump
new bool:g_OnSlump[MAXPLAYERS+1], Float:g_McCreeCool[MAXPLAYERS+1], g_McCreeSlump[MAXPLAYERS+1];

//McCree FlashBomb
new Float:g_McCreeFlashCool[MAXPLAYERS+1], bool:g_OnStun[MAXPLAYERS+1];

//McCree Rapid Fire
new bool:g_McCreeOnRapid[MAXPLAYERS+1], bool:g_AllowRapid[MAXPLAYERS+1], g_Clip[MAXPLAYERS+1];

//McCree Ult
new bool:g_OnMcCreeUlt[MAXPLAYERS+1], Float:g_McCreeUltCool[MAXPLAYERS+1], g_McCreeSightDamage[MAXPLAYERS+1][MAXPLAYERS+1], bool:g_InMcCreeUltView[MAXPLAYERS+1][MAXPLAYERS+1];

//Ana
//Ana Attack
new g_AnaAttackTime[MAXPLAYERS+1], g_AnaAttacker[MAXPLAYERS+1];

//Ana Bomb
new bool:g_OnAnaBomb[MAXPLAYERS+1], Float:g_AnaBombCool[MAXPLAYERS+1];
new g_AnaBomb[MAXPLAYERS+1] = -1;

//Ana Needle
new Float:g_AnaNeedleGun[MAXPLAYERS+1];

//RoadHog
//RoadHog Gun/Disable
new bool:g_DisAbleFire[MAXPLAYERS+1];

//RoadHog Heal
new Float:g_RoadHealCool[MAXPLAYERS+1], bool:g_OnRoadHeal[MAXPLAYERS+1];

//RoadHog Ultimate
new Float:g_RoadUltcool[MAXPLAYERS+1], bool:g_OnRoadUlti[MAXPLAYERS+1];

//Parah
//Parah JetPack
new Float:g_ParahJetPack[MAXPLAYERS+1], bool:g_ParahAllowJump[MAXPLAYERS+1];

//Parah Boost
new Float:g_ParahBoostGage[MAXPLAYERS+1], bool:g_ParahOnTimer[MAXPLAYERS+1], bool:g_ChargeTimer[MAXPLAYERS+1], bool:g_ParahAllowCharge[MAXPLAYERS+1];
new bool:g_ParahDisplayBoost[MAXPLAYERS+1];
new bool:g_AllowBoost[MAXPLAYERS+1];

//Parah Secondary
new Float:g_ParahSeconadry[MAXPLAYERS+1];

//Parah Ult
new g_ParahUltTimer[MAXPLAYERS+1];

//Mercy Gun, Click
new bool:g_MercyOnKritz[MAXPLAYERS+1], g_MercyTarget[MAXPLAYERS+1], g_MercyHealType[MAXPLAYERS+1];

new Float:Aimposition[3];

new String:MapName[2048];
public Plugin:myinfo = {
	name = "TF2 OverWatch",
	description = "",
	author = "Abert",
	version = "1.8.8",
	url = ""
}

public OnMapStart()
{
	GetCurrentMap(MapName, sizeof(MapName)); // 맵 시작 노래
	new Handle:DropWeap = FindConVar("tf_dropped_weapon_lifetime");
	if(DropWeap != INVALID_HANDLE)
	{
		SetConVarInt(DropWeap, 0);
	}
	
	PrecacheSound("replay/rendercomplete.wav");
	PrecacheSound("replay/exitperformancemode.wav");
	PrecacheSound("overwatch/tracer/skills/tracer_blink.mp3", true);
	PrecacheSound("overwatch/tracer/walking/tracer_seeafk.wav", true);
	PrecacheSound("overwatch/tracer/walking/tracer_start.mp3", true);
	PrecacheSound("overwatch/tracer/walking/tracer_start2.mp3", true);
	PrecacheSound("overwatch/tracer/walking/tracer_open.wav", true);
	PrecacheSound("overwatch/tracer/skills/tracer_throwbomb.wav", true);
	PrecacheSound("overwatch/tracer/skills/tracer_throwbomb2.wav", true);
	PrecacheSound("overwatch/bastion/skills/bastion_tank.mp3", true);
	PrecacheSound("overwatch/soldier76/skills/soldier_heixrocket.wav", true);
	PrecacheSound("overwatch/soldier76/walking/soldier76_start.mp3", true);
	PrecacheSound("overwatch/soldier76/walking/soldier76_start2.mp3", true);
	PrecacheSound("overwatch/mccree/walking/mccree_start1.wav", true);
	PrecacheSound("overwatch/mccree/walking/mccree_start2.wav", true);
	PrecacheSound("overwatch/round/round_end.mp3", true);
	PrecacheSound("weapons/airstrike_fire_01.wav");
	PrecacheSound("weapons/airstrike_fire_02.wav");
	PrecacheSound("weapons/airstrike_fire_03.wav");
	PrecacheModel("buildables/sentry3_rockets.mdl", true);
	PrecacheModel("props_mvm/mvm_player_shield.mdl", true);
	PrecacheModel("props_mvm/mvm_player_shield2.mdl", true);
	PrecacheModel("weapons/shells/shell_shotgun.mdl", true);
	PrecacheModel("weapons/w_models/w_cannonball.mdl",true);
	//g_BeamSprite = PrecacheModel("sprites/laserbeam.vmt", true);
	//g_HaloSprite = PrecacheModel("materials/sprites/halo.vmt", true);
	
	AddFileToDownloadsTable("sound/overwatch/tracer/skills/tracer_blink.mp3");
	AddFileToDownloadsTable("sound/overwatch/tracer/walking/tracer_seeafk.wav");
	AddFileToDownloadsTable("sound/overwatch/tracer/walking/tracer_start.mp3");
	AddFileToDownloadsTable("sound/overwatch/tracer/walking/tracer_start2.mp3");
	AddFileToDownloadsTable("sound/overwatch/tracer/walking/tracer_open.wav");
	AddFileToDownloadsTable("sound/overwatch/tracer/skills/tracer_throwbomb.wav");
	AddFileToDownloadsTable("sound/overwatch/tracer/skills/tracer_throwbomb2.wav");
	AddFileToDownloadsTable("sound/overwatch/bastion/skills/bastion_tank.mp3");
	AddFileToDownloadsTable("sound/overwatch/soldier76/skills/soldier_heixrocket.wav");
	AddFileToDownloadsTable("sound/overwatch/soldier76/walking/soldier76_start.mp3");
	AddFileToDownloadsTable("sound/overwatch/soldier76/walking/soldier76_start2.mp3");
	AddFileToDownloadsTable("sound/overwatch/mccree/walking/mccree_start1.wav");
	AddFileToDownloadsTable("sound/overwatch/mccree/walking/mccree_start2.wav");
	AddFileToDownloadsTable("sound/overwatch/round/round_end.mp3");
}

public OnPluginStart()
{
	RegAdminCmd("sm_overwatch", OW, 0);
	RegAdminCmd("sm_setultgage", CallBack_SetGage, ADMFLAG_SLAY);
	RegAdminCmd("sm_grsd", grsd, ADMFLAG_SLAY);
	RegAdminCmd("sm_showchamp", champ, ADMFLAG_SLAY);
	RegConsoleCmd("+primary", CallBack_Primary);
	RegConsoleCmd("+secondary", CallBack_Secondary);
	RegConsoleCmd("+ultimate", CallBack_Ultimate);
	RegConsoleCmd("+skill2", CallBack_Skill); 
	RegConsoleCmd("+reload2", CallBack_Reload2);
	RegConsoleCmd("kill", k);
	HookEvent("player_spawn", CallBack_PlayerSpawn);
	HookEvent("player_death", CallBack_PlayerDeath);
	HookEvent("player_death", CallBack_PlayerDeathN, EventHookMode_Post);
	HookEvent("player_hurt", CallBack_PlayerHurt);
	HookEvent("teamplay_round_start", CallBack_RoundStart);
	HookEvent("teamplay_round_active", CallBack_PlayerSpawn, EventHookMode_Post);
	HookEvent("teamplay_pre_round_time_left", CallBack_RoundTime);
	
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i)) {
		if(IsClientInGame(i)) {
			if(IsPlayerAlive(i)) {
				CreateEyeProp(i);
			}
		}
	}
	
	//Miscs
	g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
}

public Action:k(client, args)
{
	if(g_Champion[client] == 0)
	{
		ForcePlayerSuicide(client);
		return Plugin_Handled;
	} else {
		PrintToChat(client, "오버워치 모드에선 자살이 불가능합니다!");
		return Plugin_Handled;
	}
}

public Action:champ(client, args)
{
	PrintToChat(client, "%d", g_Champion[client]);
}

public OnPluginEnd()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsSprite(ClientEyes[i]))
		{
			AcceptEntityInput(ClientEyes[i], "kill");
		}
	}
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(g_Champion[client] == 7)
	{
		if(g_DisAbleFire[client])
		{
			result = false;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

/*
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(g_Champion[client] == 6)
	{
		new Float:pos[3];
		new Float:ang[3];
		new Float:ipos[3];
		GetClientEyePosition(client, pos);
		GetClientAbsAngles(client, ang);
		new Float:i[1];
		i[0] = 0.0;
		new bool:allowheal = true;
		while(i[0] < 1500.0)
		{
			GetEndPosition(ipos, pos, ang, i[0]);
			for(new j=1; j<=MaxClients; j++)
			{
				if(PlayerCheck(j))
				{
					if(GetClientTeam(client) == GetClientTeam(j) && allowheal)
					{
						new health = GetClientHealth(j);
						new y = health + 50;
						SetEntProp(j, Prop_Send, "m_iHealth", y);
						allowheal = false;
					}
				}
			}
			i[0] += 0.35;
		}
	}
}
*/
public Action:CallBack_RoundTime(Handle:event, const String:name[], bool:dontBroadcast)
{
	new time = GetEventInt(event, "time");
	if(time == 20)
	{
		EmitSoundToAll("overwatch/round/round_end.mp3", SOUND_FROM_WORLD);
	}
}

public Action:grsd(client, args)
{
	new String:arg[256], iarg;
	GetCmdArg(1, arg, sizeof(arg));
	iarg = StringToInt(arg);
	
	g_ReinShieldHealth[client] -= iarg;
}

public OnClientPutInServer(client)
{
	g_Champion[client] = 0;
	s_Damage[client] = 0;
	s_Toggle[client] = 0;
	s_AFK[client] = 0;
	s_DamageMax[client] = 0;
	if(g_TracerPos[client] == null)
	{
		g_TracerPos[client] = new ArrayList(3);
		g_TracerAng[client] = new ArrayList(3);
		g_TracerHealth[client] = new ArrayList(1);
	}
	g_AllowRewind[client] = false;
	g_iPlayerDesiredFOV[client] = 90;
	if (!IsFakeClient(client))
	QueryClientConVar(client, "fov_desired", OnClientGetDesiredFOV);
	CreateTimer(4.0, Tracer_PutRecord, client);
	SDKHook(client, SDKHook_OnTakeDamage, Bastion_TakeDamage);
}

public OnClientDisconnect(client)
{
	new ent = EntRefToEntIndex(g_ReinEntity[client]);
	if(ent != -1)
	{		
		new aclient = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if(IsValidEntity(ent) && aclient == client)
		{
			RemoveEdict(ent);
		}
	}
	if(IsSprite(ClientEyes[client]))
	{
		AcceptEntityInput(ClientEyes[client], "Kill");
	}
	g_Disableow[g_Champion[client]]--
}

public Action:CallBack_SetGage(client, args)
{
	new String:arg[256];
	GetCmdArg(1, arg, sizeof(arg));
	new Float:iArg = StringToFloat(arg);
	UltimateGage[client] = iArg;
}

public Action:CallBack_Primary(client, args)
{
	if(PlayerCheck(client) && IsPlayerAlive(client))
	{
		if(g_Champion[client] == 1)
		{
			
		}
		if(g_Champion[client] == 2)
		{
			if(g_BasSecure[client] == 0)
			{
				g_BasSecure[client] = 2;
				g_NoFire[client] = true;
				CreateTimer(2.7, Bastion_OnChange, client);
				SetHudTextParams(-1.0, -1.0, 2.7, 255, 255, 255, 255);
				ShowHudText(client, 5, "Changing for Deploy Mod!");
				TF2_StunPlayer(client, 2.7, 1.00, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT, 0);
			} else {
				g_BasSecure[client] = 0;
				TF2_SetPlayerClass(client, TFClass_Sniper, true, true);
				GiveWeapon(client, "Bastion");
			}
		}
		if(g_Champion[client] == 3)
		{
			if(g_TracerFlash[client] > 0 && g_AllowFlash[client] == 1 && !g_TracerRewind[client])
			{
				Flash(client);
			}
		}
		if(g_Champion[client] == 4)
		{
			if(g_SoldierDash[client])
			{
				g_SoldierDash[client] = false;
				TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
			} else if(!g_SoldierDash[client]) {
				g_SoldierDash[client] = true;
				TF2_AddCondition(client, TFCond_SpeedBuffAlly, TFCondDuration_Infinite, 0);
			}
		}
		if(g_Champion[client] == 5)
		{
			if(g_McCreeCool[client] - GetGameTime() < 0.1 && !g_OnSlump[client])
			{
				g_McCreeCool[client] = GetGameTime() + 9.5;
				new Float:vel[3], Float:ang[3];
				GetClientAbsAngles(client, ang);
				GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
				vel[0] *= 550.0;
				vel[1] *= 550.0;
				vel[2] = 120.0;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
				CreateTimer(0.55, McCree_Slump, client);
				CreateTimer(0.03, McCree_SlumpAnim, client, TIMER_REPEAT);
				g_McCreeSlump[client] = 0;
				g_OnSlump[client] = true;
			}
		}
		if(g_Champion[client] == 6)
		{
			if(g_AnaNeedleGun[client] - GetGameTime() < 0.1)
			{
				g_AnaNeedleGun[client] = GetGameTime() + 15.0;
				new ananeedle = CreateEntityByName("tf_point_weapon_mimic");
				new Float:pos[3], Float:ang[3], Float:ipos[3];
				GetClientAbsOrigin(client, pos);
				GetClientAbsAngles(client, ang);
				GetEndPosition(ipos, pos, ang, 135.0);
				ipos[2] -= 25.0;
				DispatchKeyValue(ananeedle, "ModelOverride", "models/weapons/w_models/w_cannonball.mdl");
				DispatchKeyValue(ananeedle, "WeaponType", "0");
				DispatchKeyValue(ananeedle, "Damage", "15");
				DispatchKeyValue(ananeedle, "SpeedMin", "900");
				DispatchKeyValue(ananeedle, "SpeedMax", "900");
				SetEntPropEnt(ananeedle, Prop_Send, "m_hOwnerEntity", client);
				DispatchKeyValue(ananeedle, "modelscale", "0.55");
				DispatchSpawn(ananeedle);
				TeleportEntity(ananeedle, ipos, NULL_VECTOR, NULL_VECTOR);
				SDKHook(ananeedle, SDKHook_StartTouch, Ana_Touch);
			}
		}
		if(g_Champion[client] == 8)
		{
			if(g_ParahJetPack[client] - GetGameTime() < 0.1)
			{
				g_AllowBoost[client] = false;
				g_ParahJetPack[client] = GetGameTime() + 17.0;
				decl Float:dAimposition[3], Float:Clientposition[3], Float:vector[3];
				GetPlayerEye(client, dAimposition);
				GetClientAbsOrigin(client, Clientposition);
				MakeVectorFromPoints(Clientposition, dAimposition, vector);
				NormalizeVector(vector, vector);
				ScaleVector(vector, 300.0);
				vector[2] += 850.0;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vector);
				CreateTimer(0.9, Parah_AllowBoost, client);
			}
		}
		if(g_Champion[client] == 9)
		{
			new tar = GetClosestPlayerByClientAngle(client, 50.0, 700.0);
			if(tar != -1)
			{
				new Float:ang[3];
				GetClientAbsAngles(client, ang);
				GetAngleVectors(ang, ang, NULL_VECTOR, NULL_VECTOR);
				ang[0] = ang[0] * 500;
				ang[1] = ang[1] * 500;
				ang[2] = 200.0;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, ang);
			}
		}
	}
}

public Action:CallBack_Secondary(client, args)
{
	if(PlayerCheck(client) && IsPlayerAlive(client))
	{
		if(g_Champion[client] == 1)
		{
			new Float:ClientPosition[3];
			GetClientAbsOrigin(client, ClientPosition);
		} else if(g_Champion[client] == 2) {
			if(g_AllowBasHeal[client] && !g_OnBasHeal[client])
			{
				g_AllowBasHeal[client] = false;
				CreateTimer(0.35, Bastion_HealAnim, client);
				SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 0.001);
			} else if(g_OnBasHeal[client]) {
				g_OnBasHeal[client] = false;
				g_AllowBasHeal[client] = true;
				if(g_BasSecure[client] == 0)
				{
					SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 325.0);
				}
			}
		} else if(g_Champion[client] == 3) {
			if(g_AllowRewind[client] && !g_TracerRewind[client] && PlayerCheck(client) && g_flRewind[client] - GetGameTime() < 0.1 && !g_OnStun[client])
			{
				g_flRewind[client] = GetGameTime() + 22.0;
				g_AllowRewind[client] = false;
				g_TracerRewind[client] = true;
				TF2_AddCondition(client, TFCond_Bonked, 0.8);
				CreateTimer(12.0, Tracer_PutRecord, client); 
				CreateTimer(0.75, Tracer_RewindEffect, client);
				SetEntityMoveType(client, MOVETYPE_NONE);
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(client, 255,255,255,0);
				EmitSoundToAll("replay/exitperformancemode.wav", client);
				EmitSoundToClient(client, "replay/exitperformancemode.wav");
			}
		} else if(g_Champion[client] == 4) {
			if(!g_OnSoldHeal[client] && g_flSoldHeal[client] - GetGameTime() < 0.1)
			{
				g_OnSoldHeal[client] = true;
				g_flSoldHeal[client] = GetGameTime() + 25.0
				new heal = CreateEntityByName("prop_dynamic");
				new Float:pos[3];
				GetClientAbsOrigin(client, pos);
				SetEntPropEnt(heal, Prop_Send, "m_hOwnerEntity", client);
				DispatchKeyValue(heal, "modelscale", "1.5");
				SetEntityModel(heal, "models/weapons/shells/shell_shotgun.mdl");
				DispatchSpawn(heal);
				TeleportEntity(heal, pos, NULL_VECTOR, NULL_VECTOR);
				SetEntityMoveType(heal, MOVETYPE_WALK);
				g_iHealBox[client] = EntIndexToEntRef(heal);
				CreateTimer(5.5, Soldier_Heal, heal);
			}
		} else if(g_Champion[client] == 5) {
			if(g_McCreeFlashCool[client] - GetGameTime() < 0.1)
			{
				g_McCreeFlashCool[client] = GetGameTime() + 15.0;
				new flashbomb = CreateEntityByName("tf_point_weapon_mimic");
				new Float:pos[3], Float:ang[3], Float:ipos[3];
				GetClientAbsOrigin(client, pos);
				GetClientAbsAngles(client, ang);
				GetEndPosition(ipos, pos, ang, 115.0);
				DispatchKeyValue(flashbomb, "ModelOverride", "models/weapons/w_models/w_cannonball.mdl");
				DispatchKeyValue(flashbomb, "WeaponType", "1");
				DispatchKeyValue(flashbomb, "Damage", "0");
				DispatchKeyValue(flashbomb, "SpeedMin", "450");
				DispatchKeyValue(flashbomb, "SpeedMax", "450");
				SetEntPropEnt(flashbomb, Prop_Send, "m_hOwnerEntity", client);
				DispatchKeyValue(flashbomb, "modelscale", "0.5");
				DispatchSpawn(flashbomb);
				TeleportEntity(flashbomb, pos, NULL_VECTOR, NULL_VECTOR);
				CreateTimer(0.25, McCree_FlashBomb, flashbomb);
			}
		} else if(g_Champion[client] == 6) {
			
			if(g_AnaBombCool[client] - GetGameTime() < 0.1 && !g_OnAnaBomb[client])
			{	
				g_AnaBombCool[client] = GetGameTime() + 20.0;
				g_OnAnaBomb[client] = true;
				new ent = CreateEntityByName("tf_point_weapon_mimic");
				decl Float:angs[3];
				decl Float:pos[3];
				decl Float:vecs[3];
				GetClientEyePosition(client, pos);
				GetClientEyeAngles(client, angs);
				GetEndPosition(vecs, pos, angs, 70.0);
				DispatchKeyValueVector(ent, "origin", vecs);
				DispatchKeyValueVector(ent, "angles", angs);	
				DispatchKeyValue(ent, "WeaponType", "2");
				DispatchKeyValue(ent, "SpeedMin", "550");
				DispatchKeyValue(ent, "SpeedMax", "550");
				SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);	
				DispatchKeyValue(ent, "modelscale", "2.0");
				DispatchSpawn(ent);
				TeleportEntity(ent, vecs, NULL_VECTOR, NULL_VECTOR);
				g_AnaBomb[client] = EntIndexToEntRef(ent);
			}
		} else if(g_Champion[client] == 7) {
			if(!g_OnRoadHeal[client] && g_RoadHealCool[client] - GetGameTime() < 0.1)
			{
				g_OnRoadHeal[client] = true;
				g_DisAbleFire[client] = true;
				CreateTimer(2.5, Road_Heal, client);
				TF2_StunPlayer(client, 2.5, 1.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT, 0);
				g_RoadHealCool[client] = GetGameTime() + 15.0;
			}
		} else if(g_Champion[client] == 8) {
			if(g_ParahSeconadry[client] - GetGameTime() < 0.1)
			{
				g_ParahSeconadry[client] = GetGameTime() + 12.0;
				new Float:flPos[3], Float:flAng[3], Float:pos[3];
				GetClientAbsAngles(client, flAng);
				GetClientEyePosition(client, pos);
				GetEndPosition(flPos, pos, flAng, 80.0);
				int ent = CreateEntityByName("tf_point_weapon_mimic");
				DispatchKeyValueVector(ent, "origin", flPos);
				DispatchKeyValueVector(ent, "angles", flAng);	
				DispatchKeyValue(ent, "ModelOverride", "models/weapons/w_models/w_rocket_airstrike/w_rocket_airstrike.mdl");
			//	DispatchKeyValue(ent, "ModelOverride", "models/buildables/sentry3_rockets.mdl");
				DispatchKeyValue(ent, "WeaponType", "0");
				DispatchKeyValue(ent, "SpeedMin", "1980");
				DispatchKeyValue(ent, "SpeedMax", "1980");
				DispatchKeyValue(ent, "Damage", "0");
				DispatchKeyValue(ent, "SplashRadius", "100");
				DispatchSpawn(ent);
	
				SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
				AcceptEntityInput(ent, "FireOnce");
				SDKHook(ent, SDKHook_StartTouch, Parah_StartTouch);
			}
		}
	}
}

public Action:CallBack_Ultimate(client, args)
{
	if(PlayerCheck(client) && IsPlayerAlive(client))
	{
		if(UltimateGage[client] == 100)
		{
			if(g_Champion[client] == 2)
			{
				TF2_SetPlayerClass(client, TFClass_Heavy, true, true);
				g_BasUltimate[client] = 1;
				g_BasUltimateCooldown[client] = GetGameTime() + 8.7;
				EmitSoundToAll("overwatch/bastion/skills/bastion_tank.mp3", client);
				UltimateGage[client] = 0.0;
				TF2_StunPlayer(client, 1.0, 1.00, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT, 0);
				CreateTimer(0.7, Bastion_ForTank, client);
				g_OnBasHeal[client] = false;
			}
			if(g_Champion[client] == 3)
			{
				if(!g_TracerRewind[client])
				{
					new bomb = CreateEntityByName("prop_physics");
					DispatchKeyValue(bomb, "model", "models/props_combine/combine_mine01.mdl");
					DispatchKeyValue(bomb, "modelscale", "0.85");
					SetEntProp(bomb, Prop_Send, "m_CollisionGroup", 0);
					UltimateGage[client] = 0.0;
					new Float:vel[3], Float:aim[3], Float:posi[3];
					GetPlayerEye(client, aim);
					GetClientAbsOrigin(client, posi);
					MakeVectorFromPoints(posi, aim, vel);
					NormalizeVector(vel, vel);
					ScaleVector(vel, 700.0);
					TeleportEntity(bomb, posi, NULL_VECTOR, vel);
					
					switch(GetRandomInt(1, 2))
					{
						case 1: EmitSoundToAll("overwatch/tracer/skills/tracer_throwbomb.wav", client);
						case 2: EmitSoundToAll("overwatch/tracer/skills/tracer_throwbomb2.wav", client);
					}
					
					g_iPulseBomb[client] = EntIndexToEntRef(bomb);
					CreateTimer(0.75, Timer_TracerPulse, bomb);
				}
			}
			if(g_Champion[client] == 4)
			{
				if(PlayerCheck(client))
				{
					UltimateGage[client] = 0.0;
					g_OnSoldUlti[client] = true;
					g_SoldUltCool[client] = GetGameTime() + 5.5;
					CreateTimer(5.5, Sold_Ult, client);
				}
			}
			if(g_Champion[client] == 5)
			{
				UltimateGage[client] = 50.0;
				g_OnMcCreeUlt[client] = true;
				g_McCreeUltCool[client] = GetGameTime() + 10.0;
			}
			if(g_Champion[client] == 7)
			{
				UltimateGage[client] = 0.0;
				g_OnRoadUlti[client] = true;
				g_RoadUltcool[client] = GetGameTime() + 4.5;
				GiveWeapon(client, "RoadHog2");
				CreateTimer(4.5, Road_Ult, client);
			}
			if(g_Champion[client] == 8)
			{
				g_ParahUltTimer[client] = 0;
				CreateTimer(0.03, Parah_Ult, client, TIMER_REPEAT);
			}
			UltimateGage[client] = 0.0;
		}
	}
}

public OnEntityCreated(int entity, const char[] en)
{
	if(StrContains(en, "tf_proj"))
	{
		
	}
}

/*
public Action:TouchProj(int entity, int other)
{
	if(other > MaxClients)
	{
		new client = GetEntPropEnt(other, Prop_Send, "m_hOwnerEntity");
		new ent = EntRefToEntIndex(g_ReinEntity[client]);
		if(ent == other)
		{
			g_ReinShieldHealth[client] -= 120;
			AcceptEntityInput(entity, "Kill");
		}
	}
}
*/

public Action:Timer_TracerPulse(Handle:timer, any:entity)
{
	if(IsValidEntity(entity) && IsValidEdict(entity))
	{
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		new target = g_TracerBombTarget[client];
		new Float:Tpos[3];
		g_TracerOnThrowBomb[client] = false;
		if(PlayerCheck(client) && PlayerCheck(target))
		{
			GetClientAbsOrigin(target, Tpos);
			if(g_TracerBombTarget[client] != 0)
			{
				new weapon = GetPlayerWeaponSlot(client, 1);
				if(!g_TracerRewind[target])
				{
					SDKHooks_TakeDamage(target, client, client, 520.0, DMG_CRIT|DMG_CRUSH, weapon);
					for(new i = 0; i<=MaxClients; i++)
					{
						if(SetHitBoxAndTest(Tpos, i, 120.0) && !g_TracerRewind[i])
						{
							SDKHooks_TakeDamage(i, client, client, 250.0, DMG_CRIT|DMG_CRUSH, weapon);
						}
					}
				}
			}
		}
	}	
	return Plugin_Continue;
}

public Action:CallBack_Skill(client, args)
{
	if(PlayerCheck(client) && IsPlayerAlive(client))
	{
		if(GetClientTeam(client) != 1)
		{
			if(g_Champion[client] == 1)
			{
				new shield = CreateEntityByName("prop_physics_override");
				if(g_ReinShieldHealth[client] > 0 && !g_ReinShield[client] && IsPlayerAlive(client))
				{
					g_StartShieldRegen[client] = false;
					g_ReinShield[client] = true;
					g_SetAnim[client] = false;
					new String:health[256];
					SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 95.0);
					IntToString(g_ReinShieldHealth[client], health, sizeof(health));
					SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", client);  
					SetEntityMoveType(shield, MOVETYPE_VPHYSICS);
					DispatchKeyValue(shield, "classname", "entity_medigun_shield");
					SetEntData(shield, g_CollisionOffset, 3, 4, true);
					//SDKHook(shield, SDKHook_ShouldCollide, Rein_Collide);
					SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(client));  
					//SetEntProp(shield, Prop_Data, "m_CollisionGroup", 13|2);
					//SetEntData(shield, g_CollisionOffset, 2, 4, true);
					DispatchKeyValue(shield, "model", "models/props_mvm/mvm_player_shield2.mdl");
					DispatchKeyValue(shield, "ModelScale", "0.95");
					
					if (TF2_GetClientTeam(client) == TFTeam_Red) 
						DispatchKeyValue(shield, "skin", "0");
					else if (TF2_GetClientTeam(client) == TFTeam_Blue) 
						DispatchKeyValue(shield, "skin", "1");
					
					DispatchSpawn(shield);
					
					SetVariantInt(g_ReinShieldHealth[client]);
					AcceptEntityInput(shield, "SetHealth");
					SDKHook(shield, SDKHook_OnTakeDamage, Rein_ShieldHook);
					SDKHook(shield, SDKHook_StartTouch, Rein_StartTouch);
					EmitSoundToClient(client, "weapons/medi_shield_deploy.wav", shield);
					
					g_ReinEntity[client] = EntIndexToEntRef(shield);
					SetVariantInt(1);
					AcceptEntityInput(client, "SetForcedTauntCam");
					TF2_RemoveAllWeapons(client);
					for(new i=0; i<=5; i++)
					{
						TF2_RemoveWeaponSlot(client, i);
					}
					GiveWeapon(client, "ReinhartShield");
					g_reinbreak[client] = true;
				}
				if(g_ReinShield[client] && g_SetAnim[client])
				{
					g_AllowReinTimer[client] = true;
					g_ReinShield[client] = false;
					new ent = EntRefToEntIndex(g_ReinEntity[client]);
					if(ent != -1)
					{		
						new aclient = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
						if(IsValidEntity(ent) && aclient == client)
						{
							RemoveEdict(ent);
						}
					}
					g_SetAnim[client] = false;
					SetVariantInt(0);
					AcceptEntityInput(client, "SetForcedTauntCam");
					SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 255.0);
					GiveWeapon(client, "Reinhart");
				}
			}
			if(g_Champion[client] == 3)
			{
				if(g_TracerFlash[client] > 0 && g_AllowFlash[client] == 1 && !g_TracerRewind[client])
				{
					Flash(client);
				}
			}
			if(g_Champion[client] == 4)
			{
				if((g_SoldierMissleCool[client] - GetGameTime()) <= 0)
				{
					decl Float:pos[3];
					
					new ent = CreateEntityByName("tf_point_weapon_mimic");
					decl Float:angs[3];
					decl Float:vecs[3];
					GetClientEyePosition(client, pos);
					GetClientEyeAngles(client, angs);
					GetEndPosition(vecs, pos, angs, 70.0);
					
					DispatchKeyValueVector(ent, "origin", vecs);
					DispatchKeyValueVector(ent, "angles", angs);	
					
					SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);	
					if (client > 0 && client <= MaxClients) 
					{ 
						if (!IsClientInGame(client)) 
						{ 
							return; 
						} 
						if (GetClientTeam(client) == 2) { 
							CreateTimer(0.1, SetBLU, ent); 
						} 
						if(GetClientTeam(client) == 3)
						{ 
							CreateTimer(0.1, SetRED, ent); 
						} 
					} 
					DispatchKeyValue(ent, "ModelOverride", "models/buildables/sentry3_rockets.mdl");
					DispatchKeyValue(ent, "FireSound", "sound/overwatch/soldier76/skills/soldier_heixrocket.wav");
				//	DispatchKeyValue(ent, "ModelOverride", "models/buildables/sentry3_rockets.mdl");
					DispatchKeyValue(ent, "WeaponType", "0");
					DispatchKeyValue(ent, "SpeedMin", "1400");
					DispatchKeyValue(ent, "SpeedMax", "1400");
					DispatchKeyValue(ent, "Damage", "90");
					DispatchKeyValue(ent, "SplashRadius", "30");
					DispatchSpawn(ent);
					
					TeleportEntity(ent, vecs, NULL_VECTOR, NULL_VECTOR);
					AcceptEntityInput(ent, "FireOnce");
					
					g_SoldierMissleCool[client] = GetGameTime() + 7.5;
					if(TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly))
					{
						TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
					}
					g_SoldierDash[client] = false;
				}
			}
			if(g_Champion[client] == 5)
			{
				if(g_AllowRapid[client] && !g_McCreeOnRapid[client])
				{
					g_AllowRapid[client] = false;
					g_McCreeOnRapid[client] = true;
					g_Clip[client] = GetWeaponClip(client, 0);
					CreateTimer(2.7, McCree_AllowRapid, client);
					CreateTimer(0.25, McCree_Rapid2, client);
					GiveWeapon(client, "McCree2");
				}
			}
			if(g_Champion[client] == 11)
			{
				if(!g_OnRoadHeal[client])
				{
					new Float:ang[3],Float:iang[3];
					GetClientAbsAngles(client, ang);
					iang[0] = ang[0] - 45.0;
					new ent = CreateEntityByName("tf_point_weapon_mimic");
					decl Float:angs[3];
					decl Float:vecs[3];
					decl Float:pos[3];
					GetClientEyePosition(client, pos);
					GetClientEyeAngles(client, angs);
					GetEndPosition(vecs, pos, angs, 120.0);
					SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
					DispatchKeyValue(ent, "ModelOverride", "models/buildables/sentry3_rockets.mdl");
					DispatchKeyValue(ent, "WeaponType", "0");
					DispatchKeyValue(ent, "SpeedMin", "2500");
					DispatchKeyValue(ent, "SpeedMax", "2500");
					DispatchKeyValue(ent, "Damage", "100");
					DispatchKeyValue(ent, "SplashRadius", "30");
					DispatchSpawn(ent);
					TeleportEntity(ent, vecs, NULL_VECTOR, NULL_VECTOR);
					AcceptEntityInput(ent, "FireOnce");
					while(iang[0] > angs[0] + 45.0)
					{
						new ient = CreateEntityByName("tf_point_weapon_mimic");
						SetEntPropEnt(ient, Prop_Send, "m_hOwnerEntity", client);
						GetEndPosition(vecs, pos, iang, 120.0);
						DispatchKeyValue(ient, "ModelOverride", "models/buildables/sentry3_rockets.mdl");
						DispatchKeyValue(ient, "WeaponType", "0");
						DispatchKeyValue(ient, "SpeedMin", "3500");
						DispatchKeyValue(ient, "SpeedMax", "3500");
						DispatchKeyValue(ient, "Damage", "15");
						DispatchKeyValue(ient, "SplashRadius", "30");
						DispatchSpawn(ient);
						TeleportEntity(ient, vecs, NULL_VECTOR, NULL_VECTOR);
						AcceptEntityInput(ient, "FireOnce");
						g_DisAbleFire[client] = true;
						new clip = GetWeaponClip(client, 1);
						new iclip = clip - 1;
						SetWeaponClip(client, 1, iclip);
						iang[0] += 15.0;
					}
					CreateTimer(0.75, Road_Fire, client);
				}
			}
			if(g_Champion[client] == 9)
			{
				new String:classname[64];
				GetCurrentWeaponClass(client, classname, sizeof(classname));

				if(StrEqual(classname, "CWeaponMedigun"))
				{
					if(!g_MercyOnKritz[client])
					{
						g_MercyOnKritz[client] = true;
						new tar = GetClosestPlayerByClientAngle(client, 40.0, 200.0);
						if(tar != -1)
						{
							g_MercyTarget[client] = tar;
						}
					} else {
						g_MercyOnKritz[client] = false;
						g_MercyTarget[client] = -1;
					}
				}
			}
		}
	}
}

public Action:SetBLU(Handle:timer, any:ent) 
{ 
    SetEntProp(ent, Prop_Send, "m_iTeamNum", 2); 
} 

public Action:SetRED(Handle:timer, any:ent) 
{ 
    SetEntProp(ent, Prop_Send, "m_iTeamNum", 3); 
}  

public Action:CallBack_Reload2(client, args)
{
	if(g_Champion[client] == 4)
	{
		if(!g_SoldReload[client])
		{
			g_SoldReload[client] = true;
			CreateTimer(1.5, Sold_Reload, client);
		}
	}
}

public Action:CallBack_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0 && PlayerCheck(client))
	{
		new team = GetClientTeam(client);
		if(IsPlayerAlive(client) && team != 1)
		{
			if(TF2_GetPlayerClass(client) != TFClass_Heavy && TF2_GetPlayerClass(client) != TFClass_Engineer)
			{
				SetWeaponAmmo(client, 0, 99999);
			}
			/*
			new String:weap[256];
			GetClientWeapon(client, weap, sizeof(weap));
			if(!StrContains(weap, "tf_weapon_bat") && !StrContains(weap, "tf_weapon_lunchbox") && !StrContains(weap, "jar"))
			{
				SetWeaponAmmo(client, 1, 99999);
			}
			*/
			if(g_Champion[client] != 0)
			{
				SetVariantInt(0);
				AcceptEntityInput(client, "SetForcedTauntCam");
			}
			if(g_Champion[client] == 1)
			{
				TF2_SetPlayerClass(client, TFClass_Pyro, true, true);
				GiveWeapon(client, "Reinhart");
				SetEntProp(client, Prop_Send, "m_iHealth", 350);
				SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 255.0);
				g_ReinChargeAllow[client] = 1;
				g_ReinShieldHealth[client] = 1700;
				g_ReinShield[client] = false;
				g_AllowReinTimer[client] = true;
				g_SetAnim[client] = false;
				StartSound(client, "Reinhart");
				g_ReinShield[client] = false;
				new ent = EntRefToEntIndex(g_ReinEntity[client]);
				if(ent != -1)
				{		
					new aclient = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
					if(IsValidEntity(ent) && aclient == client)
					{
						RemoveEdict(ent);
					}
				}
			} else if(g_Champion[client] == 2) {
				TF2_SetPlayerClass(client, TFClass_Sniper, true, true);
				GiveWeapon(client, "Bastion");
				SetEntProp(client, Prop_Send, "m_iHealth", 270);
				g_OnBasHeal[client] = false;
				g_AllowBasHeal[client] = true;
				g_BasReload[client] = 0;
				g_BasSecure[client] = 0;
				StartSound(client, "Bastion");
			} else if(g_Champion[client] == 3) {
				TF2_SetPlayerClass(client, TFClass_Scout, true, true);
				GiveWeapon(client, "Tracer");
				SetEntProp(client, Prop_Send, "m_iHealth", 140);
				g_TracerFlash[client] = 3;
				SetWeaponAmmo(client, 1, 999999);
				g_AllowFlash[client] = 1;
				StartSound(client, "Tracer");
				g_TracerRewind[client] = false;
				g_TracerOnThrowBomb[client] = false;
			} else if(g_Champion[client] == 4) {
				TF2_SetPlayerClass(client, TFClass_Soldier, true, true);
				GiveWeapon(client, "Soldier:76");
				SetEntProp(client, Prop_Send, "m_iHealth", 180);
				SetWeaponAmmo(client, 1, 999999);
				g_OnSoldHeal[client] = false;
				g_SoldReload[client] = false;
				StartSound(client, "Soldier:76");
			} else if(g_Champion[client] == 5) {
				TF2_SetPlayerClass(client, TFClass_Spy, true, true);
				GiveWeapon(client, "McCree");
				SetEntProp(client, Prop_Send, "m_iHealth", 200);
				SetWeaponAmmo(client, 0, 999999);
				g_McCreeCool[client] = 0.0;
				g_McCreeFlashCool[client] = 0.0;
				g_OnSlump[client] = false;
				g_McCreeOnRapid[client] = false;
				g_AllowRapid[client] = true;
				g_OnMcCreeUlt[client] = false;
				StartSound(client, "McCree");
			} else if(g_Champion[client] == 6) {
				TF2_SetPlayerClass(client, TFClass_Medic, true, true);
				GiveWeapon(client, "Ana");
				SetEntProp(client, Prop_Send, "m_iHealth", 190);
				SetWeaponAmmo(client, 0, 999999);
				g_OnAnaBomb[client] = false;
				g_AnaBombCool[client] = 0.0;
				StartSound(client, "Ana");
			} else if(g_Champion[client] == 7) {
				TF2_SetPlayerClass(client, TFClass_Heavy, true, true);
				GiveWeapon(client, "RoadHog");
				SetEntProp(client, Prop_Send, "m_iHealth", 450);
				SetWeaponAmmo(client, 1, 999999);
				g_OnRoadHeal[client] = false;
				g_OnRoadUlti[client] = false;
				g_RoadHealCool[client] = GetGameTime();
				StartSound(client, "RoadHog");
			} else if(g_Champion[client] == 8) {
				TF2_SetPlayerClass(client, TFClass_Soldier, true, true);
				GiveWeapon(client, "Parah");
				SetEntProp(client, Prop_Send, "m_iHealth", 170);
				SetWeaponAmmo(client, 1, 999999);
				StartSound(client, "Parah");
				g_ParahAllowCharge[client] = false;
				g_ParahBoostGage[client] = 100.0;
				g_ParahDisplayBoost[client] = false;
				g_ParahOnTimer[client] = false;
				g_ParahAllowJump[client] = false;
				g_AllowBoost[client] = true;
				g_ParahJetPack[client] = GetGameTime();
				g_ParahSeconadry[client] = GetGameTime();
			} else if(g_Champion[client] == 9) {
				TF2_SetPlayerClass(client, TFClass_Medic, true, true);
				GiveWeapon(client, "Mercy");
				SetWeaponAmmo(client, 1, 999999);
				StartSound(client, "Mercy");
				g_MercyHealType[client] = 0;
				g_MercyOnKritz[client] = false;
				g_MercyTarget[client] = -1;
			}
			for(new i=0; i<=MaxClients; i++)
			{
				g_InMcCreeUltView[i][client] = false;
				g_McCreeSightDamage[i][client] = 0;
			}
		}
	}
}

/*
SetEntProp(entity, Prop_Data, "m_takedamage", 2, 1);// 데미지 타입

*/

public Action:CallBack_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_ReinChargeTarget[client] != 0)
	{
		g_ReinChargeTarget[client] = 0;
	}
	if(g_Champion[client] == 1)
	{
		SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 300.0);
		g_ReinShield[client] = false;
	}
	if(g_Champion[client] == 2)
	{
		g_BasSecure[client] = 0;
	}
	if(g_Champion[client] == 3)
	{
		g_AllowRewind[client] = false;
		g_flRewind[client] = GetGameTime() + 10.0;
		CreateTimer(10.0, Tracer_PutRecord, client);
	}
	if(g_Champion[client] == 4)
	{
		g_SoldierDash[client] = false;
		if(IsSprite(ClientEyes[client]))
		{
			AcceptEntityInput(ClientEyes[client], "kill");
		}
	}
}

public Action:CallBack_PlayerDeathN(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new ent = EntRefToEntIndex(g_ReinEntity[client]);
	if(ent != -1)
	{		
		new aclient = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if(IsValidEntity(ent) && aclient == client)
		{
			AcceptEntityInput(ent, "Kill");
			RemoveEdict(ent);
		}
	}
}

public Action:CallBack_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new damage = GetEventInt(event, "damageamount");
	new Float:add;
	if(attacker != client)
	{
		if(g_Champion[attacker] == 1)
		{
			add = damage / 2 - 5.0; //  buttons |= IN_ATTACK; Rein Force Attack Ulti Animation
			UltimateGage[attacker] += add;
		}
		if(g_Champion[attacker] == 2)
		{
			if(g_BasUltimate[attacker] == 0)
			{
				add = damage / 5 * 2 - 8.5;
				if(add < 0)
				{
					add = 0.75;
				}
			}
			UltimateGage[attacker] += add;
			g_OnBasHeal[client] = false;
			if(g_BasSecure[client] == 0)
			{
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 320.0);
			}
		}
		if(g_Champion[attacker] == 3)
		{
			add = damage / 3 * 2 - 4.0;
			if(add < 0)
			{
				add = 0.1;
			}
			UltimateGage[attacker] += add;
		}
		if(g_Champion[attacker] == 4)
		{
			add = damage / 4 - 10.0;
			if(add < 0)
			{
				add = 0.5;
			}
			UltimateGage[attacker] += add;
			if(g_SoldierDash[client])
			{
				g_SoldierDash[client] = false;
			}
			if(g_SoldReload[client])
			{
				g_SoldReload[client] = false;
			}
		}
		if(g_Champion[attacker] == 5)
		{
			if(!g_OnMcCreeUlt[attacker])
			{
				add = damage / 4 - 15.0;
				if(add < 0)
				{
					add = 0.7;
				}
			}
		}
		if(g_Champion[attacker] == 6)
		{
			if(100 > damage > 25)
			{
				g_AnaAttacker[client] = attacker;
				g_AnaAttackTime[client] = 0;
				CreateTimer(0.35, Ana_AttackAnim, client, TIMER_REPEAT);
			}
		}
		if(g_Champion[attacker] == 7)
		{
			add = damage / 10 - 15.0;
			if(add < 0)
			{
				add = 0.15;
			}
			UltimateGage[attacker] += add;
		}
		if(g_Champion[attacker] == 8)
		{
			add = damage / 2 - 25.0;
			if(add < 0)
			{
				add = 0.35;
			}
			UltimateGage[attacker] += add;
		}
	}
	s_Damage[attacker] += damage;
}

public Action:CallBack_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=0; i<=MaxClients; i++)
	{
		if(PlayerCheck(i))
		{
			if(g_Champion[i] != 0)
			{
				UltimateGage[i] = 0.0;
			}
			if(g_Champion[i] == 3)
			{
				g_flRewind[i] = GetGameTime() + 7.0;
				g_AllowRewind[i] = false;
				CreateTimer(7.0, Tracer_PutRecord, i);
			}
		}
	}
}

public Action:OW(client, args)
{
	if(GetClientTeam(client) != 1 && IsPlayerAlive(client) && client != 0)
	{
		new Handle:menu = CreateMenu(SelectMenu);
		new String:Name[MAX_NAME_LENGTH];
		GetClientName(client, Name, sizeof(Name));
		
		SetMenuTitle(menu, "환영합니다! %s님 오버워치 챔피언을 고르세요", Name);
		AddMenuItem(menu, "0", "오버워치 해제");
		AddMenuItem(menu, "1", "라인하르트");
		AddMenuItem(menu, "2", "바스티온");
		AddMenuItem(menu, "3", "트레이서");
		AddMenuItem(menu, "4", "솔져:76");
		AddMenuItem(menu, "5", "맥크리");
		//AddMenuItem(menu, "6", "아나");
		AddMenuItem(menu, "7", "로드호그");
		AddMenuItem(menu, "8", "파라");
		AddMenuItem(menu, "9", "[장식]메르시");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public SelectMenu(Handle:menu, MenuAction:action, client, Position)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(client))
		{
			new String:Item[256];
			GetMenuItem(menu, Position, Item, sizeof(Item));
			new iItem = StringToInt(Item);
			
			new death = GetEntProp(client, Prop_Data, "m_iDeaths");
			g_Disableow[g_Champion[client]] -= 1;
			if(g_Champion[client] != iItem)
			{
				UltimateGage[client] = 0.0;
			}
			ResetAll(client);
			if(IsPlayerAlive(client) && PlayerCheck(client) && client != 0)
			{
				if(iItem == 0)
				{
					g_Champion[client] = 0;
					g_BasSecure[client] = 0;
				} else if(iItem == 1 && g_Disableow[1] < 3) {
					TF2_SetPlayerClass(client, TFClass_Pyro, true, true);
					g_Champion[client] = 1;
					g_Disableow[1]++
					GiveWeapon(client, "Reinhart");
				} else if(iItem == 2 && g_Disableow[2] <= 2) {
					TF2_SetPlayerClass(client, TFClass_Sniper, true, true);
					g_Champion[client] = 2;
					g_BasSecure[client] = 0;
					g_Disableow[2]++
					GiveWeapon(client, "Bastion");
				} else if(iItem == 3 && g_Disableow[3] <= 2) {
					TF2_SetPlayerClass(client, TFClass_Scout, true, true);
					g_Champion[client] = 3;
					g_Disableow[3]++
					GiveWeapon(client, "Tracer");
				} else if(iItem == 4 && g_Disableow[4] <= 2) {	
					TF2_SetPlayerClass(client, TFClass_Soldier, true, true);
					g_Champion[client] = 4;
					g_Disableow[4]++
					GiveWeapon(client, "Soldier:76");
				} else if(iItem == 5 && g_Disableow[5] < 3) {		
					TF2_SetPlayerClass(client, TFClass_Spy, true, true);
					g_Champion[client] = 5;
					g_Disableow[5]++
					GiveWeapon(client, "McCree");
				} else if(iItem == 6 && g_Disableow[6] <= 2) {	
					TF2_SetPlayerClass(client, TFClass_Medic, true, true);
					g_Champion[client] = 6;
					g_Disableow[6]++
					GiveWeapon(client, "Ana");
				} else if(iItem == 7 && g_Disableow[7] <= 3) {
					TF2_SetPlayerClass(client, TFClass_Heavy, true, true);
					g_Champion[client] = 7;
					g_Disableow[7]++
					GiveWeapon(client, "RoadHog");
				} else if(iItem == 8 && g_Disableow[8] <= 2) {
					TF2_SetPlayerClass(client, TFClass_Soldier, true, true);
					g_Champion[client] = 8;
					g_Disableow[8]++
					GiveWeapon(client, "Parah");
				} else if(iItem == 9 && g_Disableow[9] <= 2) {
					TF2_SetPlayerClass(client, TFClass_Medic, true, true);
					g_Champion[client] = 9;
					g_Disableow[9]++
					GiveWeapon(client, "Mercy");
				} else {
					PrintToChat(client, "\x04[KR-Abert TOW Mod] \x03선택하신 영웅을 선택할 수 있는 자리가 꽉찼습니다");
				}
			}
			ForcePlayerSuicide(client);
			TF2_RespawnPlayer(client);
			new ideath = GetEntProp(client, Prop_Data, "m_iDeaths");
			if(death != ideath)
			{
				ideath -= 1;
				SetEntProp(client, Prop_Data, "m_iDeaths", ideath);
			}
		}
	} 
	if(action == MenuAction_End)
	{
		if(menu != INVALID_HANDLE)
		{
			CloseHandle(menu);
		}
	}
}

stock GiveWeapon(client, String:Champ[])
{
	if(PlayerCheck(client) && IsPlayerAlive(client) && client != 0)
	{
		if(StrEqual(Champ, "Fist"))
		{
			
		}
		if(StrEqual(Champ, "Reinhart"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "2");
			TF2Items_SetClassname(hItem, "tf_weapon_fireaxe");
			TF2Items_SetItemIndex(hItem, 214);
			TF2Items_SetNumAttributes(hItem, 9);
			TF2Items_SetAttribute(hItem, 0, 2, 0.8);
			TF2Items_SetAttribute(hItem, 1, 264, 3.0);
			TF2Items_SetAttribute(hItem, 2, 26, 175.0);
			TF2Items_SetAttribute(hItem, 3, 61, 0.7);
			TF2Items_SetAttribute(hItem, 4, 63, 0.2);
			TF2Items_SetAttribute(hItem, 5, 65, 0.5);
			TF2Items_SetAttribute(hItem, 5, 67, 1.0);
			TF2Items_SetAttribute(hItem, 6, 15, 0.0);
			TF2Items_SetAttribute(hItem, 7, 275, 1.0);
			TF2Items_SetAttribute(hItem, 8, 54, 0.75);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "ReinhartShield"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "2");
			TF2Items_SetClassname(hItem, "tf_weapon_fireaxe");
			TF2Items_SetItemIndex(hItem, 214);
			TF2Items_SetNumAttributes(hItem, 4);
			TF2Items_SetAttribute(hItem, 0, 2, 0.0);
			TF2Items_SetAttribute(hItem, 1, 5, 90000.0);
			TF2Items_SetAttribute(hItem, 2, 26, 175.0);
			TF2Items_SetAttribute(hItem, 3, 54, 0.25);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "Bastion"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "1");
			TF2Items_SetClassname(hItem, "tf_weapon_smg");
			TF2Items_SetItemIndex(hItem, 16);
			TF2Items_SetNumAttributes(hItem, 8);
			TF2Items_SetAttribute(hItem, 0, 2, 0.95);
			TF2Items_SetAttribute(hItem, 1, 36, 0.2);
			TF2Items_SetAttribute(hItem, 2, 5, 1.25);
			TF2Items_SetAttribute(hItem, 3, 54, 0.7);
			TF2Items_SetAttribute(hItem, 4, 97, 1.5);
			TF2Items_SetAttribute(hItem, 5, 112, 50.0);
			TF2Items_SetAttribute(hItem, 6, 125, 145.0);
			TF2Items_SetAttribute(hItem, 7, 275, 1.0);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "Bastion2"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "0");
			TF2Items_SetClassname(hItem, "tf_weapon_minigun");
			TF2Items_SetItemIndex(hItem, 15);
			TF2Items_SetNumAttributes(hItem, 8);
			TF2Items_SetAttribute(hItem, 0, 54, -0.1); // 속도
			TF2Items_SetAttribute(hItem, 1, 326, 0.0);	// 노 점프 
			TF2Items_SetAttribute(hItem, 2, 394, 0.4);
			TF2Items_SetAttribute(hItem, 3, 2, 0.42);
			TF2Items_SetAttribute(hItem, 4, 26, -30.0);
			TF2Items_SetAttribute(hItem, 5, 28, 0.0);
			TF2Items_SetAttribute(hItem, 6, 36, 0.3);
			TF2Items_SetAttribute(hItem, 7, 275, 1.0);
			SetEntProp(client, Prop_Send, "m_iAmmo", 500);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "Bastion3"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "0");
			TF2Items_SetClassname(hItem, "tf_weapon_rocketlauncher");
			TF2Items_SetItemIndex(hItem, 18);
			TF2Items_SetNumAttributes(hItem, 8);
			TF2Items_SetAttribute(hItem, 0, 2, 1.55); 
			TF2Items_SetAttribute(hItem, 1, 54, 1.25);
			TF2Items_SetAttribute(hItem, 2, 99, 1.5);
			TF2Items_SetAttribute(hItem, 3, 3, 900.0);
			TF2Items_SetAttribute(hItem, 4, 26, 200.0);
			TF2Items_SetAttribute(hItem, 5, 4, 15.0);
			TF2Items_SetAttribute(hItem, 6, 96, 5000.0);
			TF2Items_SetAttribute(hItem, 7, 104, 1.8);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "Tracer"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "1");
			TF2Items_SetClassname(hItem, "tf_weapon_pistol");
			TF2Items_SetItemIndex(hItem, 773);
			TF2Items_SetNumAttributes(hItem, 10);
			TF2Items_SetAttribute(hItem, 0, 54, 1.05);
			TF2Items_SetAttribute(hItem, 1, 36, 0.21);
			TF2Items_SetAttribute(hItem, 2, 394, 0.7);
			TF2Items_SetAttribute(hItem, 3, 2, 0.4);
			TF2Items_SetAttribute(hItem, 4, 26, 15.0);
			TF2Items_SetAttribute(hItem, 5, 112, 100.0);
			TF2Items_SetAttribute(hItem, 6, 4, 1.75);
			TF2Items_SetAttribute(hItem, 7, 49, 1.0);
			TF2Items_SetAttribute(hItem, 8, 51, 1.0);
			TF2Items_SetAttribute(hItem, 9, 275, 1.0);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "Soldier:76"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "1");
			TF2Items_SetClassname(hItem, "tf_weapon_shotgun_soldier");
			TF2Items_SetItemIndex(hItem, 10);
			TF2Items_SetNumAttributes(hItem, 10);
			TF2Items_SetAttribute(hItem, 0, 45, 0.16);
			TF2Items_SetAttribute(hItem, 1, 3, 4.1);
			TF2Items_SetAttribute(hItem, 2, 26, -20.0);
			TF2Items_SetAttribute(hItem, 3, 2, 1.17);
			TF2Items_SetAttribute(hItem, 4, 54, 1.15);
			TF2Items_SetAttribute(hItem, 5, 96, 9000.0);
			TF2Items_SetAttribute(hItem, 7, 36, 0.01);
			TF2Items_SetAttribute(hItem, 8, 394, 0.13);
			TF2Items_SetAttribute(hItem, 9, 275, 1.0);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "McCree"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "0");
			TF2Items_SetClassname(hItem, "tf_weapon_revolver");
			TF2Items_SetItemIndex(hItem, 161);
			TF2Items_SetNumAttributes(hItem, 6);
			TF2Items_SetAttribute(hItem, 0, 2, 1.1);
			TF2Items_SetAttribute(hItem, 1, 51, 100.0);
			TF2Items_SetAttribute(hItem, 2, 97, 0.95);
			TF2Items_SetAttribute(hItem, 3, 26, 75.0);
			TF2Items_SetAttribute(hItem, 4, 275, 1.0);
			TF2Items_SetAttribute(hItem, 5, 36, 0.01);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "McCree2"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "0");
			TF2Items_SetClassname(hItem, "tf_weapon_revolver");
			TF2Items_SetItemIndex(hItem, 161);
			TF2Items_SetNumAttributes(hItem, 6);
			TF2Items_SetAttribute(hItem, 0, 2, 0.49);
			TF2Items_SetAttribute(hItem, 1, 5, 0.31);
			TF2Items_SetAttribute(hItem, 2, 51, 100.0);
			TF2Items_SetAttribute(hItem, 3, 97, 0.95);
			TF2Items_SetAttribute(hItem, 4, 26, 75.0);
			TF2Items_SetAttribute(hItem, 5, 275, 1.25);
			TF2Items_SetAttribute(hItem, 5, 36, 2.47);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "Ana"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "0");
			TF2Items_SetClassname(hItem, "tf_weapon_sniperrifle");
			TF2Items_SetItemIndex(hItem, 14);
			TF2Items_SetNumAttributes(hItem, 4);
			TF2Items_SetAttribute(hItem, 0, 249, 0.009);
			TF2Items_SetAttribute(hItem, 1, 2, 0.8);
			TF2Items_SetAttribute(hItem, 2, 42, 1.00);
			TF2Items_SetAttribute(hItem, 3, 26, 40.0);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "RoadHog"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "1");
			TF2Items_SetClassname(hItem, "tf_weapon_shotgun_hwg");
			TF2Items_SetItemIndex(hItem, 11);
			TF2Items_SetNumAttributes(hItem, 5);
			TF2Items_SetAttribute(hItem, 0, 45, 2.5);
			TF2Items_SetAttribute(hItem, 1, 2, 0.55);
			TF2Items_SetAttribute(hItem, 3, 26, 150.0);
			TF2Items_SetAttribute(hItem, 4, 5, 2.0);
			TF2Items_SetAttribute(hItem, 5, 3, 1.25);
			TF2Items_SetAttribute(hItem, 5, 4, 0.7);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "RoadHog2"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "1");
			TF2Items_SetClassname(hItem, "tf_weapon_shotgun_hwg");
			TF2Items_SetItemIndex(hItem, 11);
			TF2Items_SetNumAttributes(hItem, 7);
			TF2Items_SetAttribute(hItem, 0, 45, 2.3);
			TF2Items_SetAttribute(hItem, 1, 2, 0.95);
			TF2Items_SetAttribute(hItem, 3, 26, 150.0);
			TF2Items_SetAttribute(hItem, 4, 5, 0.25);
			TF2Items_SetAttribute(hItem, 5, 3, 999.0);
			TF2Items_SetAttribute(hItem, 6, 275, 1.0);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "Parah"))
		{
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			DeleteWeapons(client, "0");
			TF2Items_SetClassname(hItem, "tf_weapon_rocketlauncher");
			TF2Items_SetItemIndex(hItem, 18);
			TF2Items_SetNumAttributes(hItem, 8);
			TF2Items_SetAttribute(hItem, 0, 2, 0.85);
			TF2Items_SetAttribute(hItem, 1, 102, 0.37);
			TF2Items_SetAttribute(hItem, 2, 104, 1.45);
			TF2Items_SetAttribute(hItem, 3, 3, 1.5);
			TF2Items_SetAttribute(hItem, 4, 275, 1.0);
			TF2Items_SetAttribute(hItem, 5, 26, -30.0);
			TF2Items_SetAttribute(hItem, 6, 394, 1.15);
			TF2Items_SetAttribute(hItem, 7, 43, 1.00);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			CloseHandle(hItem);
		}
		if(StrEqual(Champ, "Mercy"))
		{
			new Handle:hItem2 = TF2Items_CreateItem(OVERRIDE_ALL);
			TF2Items_SetFlags(hItem2, FORCE_GENERATION);
			TF2_RemoveWeaponSlot(client, 1);
			TF2Items_SetClassname(hItem2, "tf_weapon_medigun");
			TF2Items_SetItemIndex(hItem2, 29);
			TF2Items_SetNumAttributes(hItem2, 1);
			TF2Items_SetAttribute(hItem2, 0, 275, 1.0);
			int weapon2 = TF2Items_GiveNamedItem(client, hItem2);
			EquipPlayerWeapon(client, weapon2);
			new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			TF2_RemoveWeaponSlot(client, 0);
			TF2Items_SetClassname(hItem, "tf_weapon_syringegun_medic");
			TF2Items_SetFlags(hItem, FORCE_GENERATION);
			TF2Items_SetItemIndex(hItem, 305);
			TF2Items_SetNumAttributes(hItem, 6);
			TF2Items_SetAttribute(hItem, 0, 2, 1.5);
			TF2Items_SetAttribute(hItem, 1, 275, 1.0);
			TF2Items_SetAttribute(hItem, 2, 4, 0.5);
			TF2Items_SetAttribute(hItem, 3, 97, 0.85);
			TF2Items_SetAttribute(hItem, 1, 104, 150.0); 
			TF2Items_SetAttribute(hItem, 5, 36, 0.01);
			int weapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, weapon);
			TF2_RemoveWeaponSlot(client, 2);
			CloseHandle(hItem);
			CloseHandle(hItem2);
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	//if(iweapon != 13|| iweapon != 23|| iweapon != 0|| iweapon != 18|| iweapon != 10|| iweapon != 6|| iweapon != 21|| iweapon != 12|| iweapon != 2|| iweapon != 19|| iweapon != 20|| iweapon != 1|| iweapon != 15|| iweapon != 11|| iweapon != 5|| iweapon != 9|| iweapon != 22|| iweapon != 7|| iweapon != 25|| iweapon != 26|| iweapon != 17|| iweapon != 29|| iweapon != 8|| iweapon != 14|| iweapon != 16|| iweapon != || iweapon != 3|| iweapon != 24|| iweapon != 735|| iweapon != 4|| iweapon != 27|| iweapon != 30||)
	//Sound
	if(PlayerCheck(client))
	{
		if(g_Champion[client] == 3)
		{
			if(s_DamageMax[client] + 500 > s_Damage[client] > s_DamageMax[client] && s_Toggle[client] == 0)
			{
				EmitSoundToClient(client, "overwatch/tracer/walking/tracer_open.wav");
				s_Toggle[client] = 1;
				s_DamageMax[client] += 2500;
			} else if(s_DamageMax[client] + 500 > s_Damage[client] > s_DamageMax[client] && s_Toggle[client] == 1) {
				EmitSoundToClient(client, "overwatch/tracer/walking/tracer_start.mp3");
				s_Toggle[client] = 0;
				s_DamageMax[client] += 2500;
			}
			if(s_AFK[client] == 1200)
			{
				EmitSoundToClient(client, "overwatch/tracer/walking/tracer_start2.mp3");
			}
		}
		if(buttons != 0) // AFK Check
		{
			s_AFK[client] = 0;
		} else {
			s_AFK[client]++
		}

		new String:weap[256];
		GetClientWeapon(client, weap, sizeof(weap));
		
		//Skills
		if(g_Champion[client] == 1)
		{
			if(StrEqual(weap, "tf_weapon_flamethrower") || StrContains(weap, "tf_weapon_shotgun_") || StrEqual(weap, "tf_weapon_flaregun"))
			{
				GiveWeapon(client, "reinhart");
			}
			if(g_ReinShield[client])
			{
				GiveWeapon(client, "ReinhartShield");
			}
			
			new prim = GetPlayerWeaponSlot(client, 0);
			new second = GetPlayerWeaponSlot(client, 1);
			
			if(prim != -1 && second != -1)
			{
				GiveWeapon(client, "Reinhart");
				SetEntProp(client, Prop_Send, "m_iHealth", 350);
			}
			
			if(g_ReinShield[client])
			{
				new shield = EntRefToEntIndex(g_ReinEntity[client]);
				decl Float:pos[3]
				decl Float:angs[3];
				decl Float:vecs[3];
				GetClientAbsOrigin(client, pos);
				GetClientEyeAngles(client, angs);
				GetEndPosition(vecs, pos, angs, 120.0);
				vecs[2] += 30.0
				TeleportEntity(shield, vecs, angs, NULL_VECTOR);
				g_SetAnim[client] = true;
				g_ReinShieldHealth[client] = GetEntProp(shield, Prop_Data, "m_iHealth");
				if(g_ReinShieldHealth[client] < 1 && g_reinbreak[client])
				{
					g_reinbreak[client] = false;
					GiveWeapon(client, "Reinhart");
				}
			}
			if(g_AllowReinTimer[client])
			{
				CreateTimer(3.0, Rein_ShieldRegen, client);
				g_AllowReinTimer[client] = false;
			}
			if(g_StartShieldRegen[client] && g_ReinShieldHealth[client] < 1700 && !g_ReinShield[client])
			{
				g_ReinShieldHealth[client]++
			}
			
			if(g_ReinCharge[client] == 1)
			{
				new String:Name[MAX_NAME_LENGTH];
				GetClientName(client, Name, sizeof(Name));
				new Float:velo[3], Float:aim[3], Float:posi[3];
				
				GetPlayerEye(client, aim);
				GetClientAbsOrigin(client, posi);
				MakeVectorFromPoints(posi, aim, velo);
				NormalizeVector(velo, velo);
				velo[2] = 0.0;
				if(g_ReinCharge_teleTimer[client] < 350)
				{				
					ScaleVector(vel, 700.0);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velo);
					g_ReinCharge_teleTimer[client]++
					
					if(g_ReinChargeTarget[client] != 0)
					{
						if(PlayerCheck(g_ReinChargeTarget[client]))
						{
						
						}
					}
				} else {
					AcceptEntityInput(client, "SetForceTauntCam");
					g_ReinCharge[client] = 0;
					g_ReinCharge_teleTimer[client] = 0;
					if(g_ReinChargeTarget[client] != 0)
					{
						if(PlayerCheck(g_ReinChargeTarget[client]))
						{
							new Target = g_ReinChargeTarget[client];
							SDKHooks_TakeDamage(Target, 0, client, 235.0, DMG_CRUSH);
						}
					}
				}
				for(new i=0; i<=MaxClients; i++)
				{
					if(PlayerCheck(i))
					{
						new Float:iveloc[3], Float:veloc[3];
						GetClientAbsAngles(client, iveloc);
						GetClientAbsOrigin(i, veloc);
						if(veloc[0] + 20 > iveloc[0] && veloc[0] - 20 < iveloc[0] && veloc[1] + 20 > iveloc[1] && veloc[1] - 20 > iveloc[1])
						{
							if(g_ReinChargeTarget[client] == 0)
							{
								new client_team = GetClientTeam(client);
								new target_team = GetClientTeam(i);
								if(i != client && target_team != client_team && client_team != 1 && target_team != 1)
								{
									g_ReinChargeTarget[client] = i;
								}
							}
						}
					}
				}
				if(g_ReinChargeTarget[client] != 0)
				{
					if(PlayerCheck(g_ReinChargeTarget[client]))
					{
						new String:Target_Name[MAX_NAME_LENGTH], Target = g_ReinChargeTarget[client];
						GetClientName(g_ReinChargeTarget[client], Target_Name, sizeof(Target_Name));
						SetHudTextParams(-1.0, 0.35, 0.4, 255, 255, 255, 255);
						ShowHudText(client, 7, "PUSHING %s", Target_Name);
						ShowHudText(Target, Target, "PUSHED BY %s", Name);
					} else {
						g_ReinChargeTarget[client] = 0;
					}
				}
			}
		}
		if(g_Champion[client] == 2)
		{
			if(!StrEqual(weap, "tf_weapon_smg") && !StrEqual(weap, "tf_weapon_minigun") && g_BasUltimate[client] != 1)
			{
				TF2_SetPlayerClass(client, TFClass_Sniper, true, true);
				GiveWeapon(client, "Bastion");
				SetEntProp(client, Prop_Send, "m_iHealth", 270);
			} // 무기 바꿈방지
			
			if(g_BasSecure[client] == 1)
			{
				new primaryAmmo = GetWeaponAmmo(client, 0);
				if(primaryAmmo < 200)
				{
					g_BasReload[client] = 1;
				}
				if(primaryAmmo > 200)
				{
					SetWeaponAmmo(client, 0, 200);
				}
				if(primaryAmmo == 0)
				{
					if(g_BasReload[client] == 1)
					{
						CreateTimer(2.5, Bastion_ReloadTimer, client);
						g_BasReload[client] = 0;
						SetHudTextParams(0.2, 0.89, 3.0, 255, 255, 255, 255);
						ShowHudText(client, 7, "장전중!");
						TF2_StunPlayer(client, 2.5, 1.0, TF_STUNFLAG_NOSOUNDOREFFECT, 0);
					}
				}
			}
			if(g_OnBasHeal[client] && g_AllowBasHeal[client])
			{
				new health = GetEntProp(client, Prop_Data, "m_iHealth");
				if(g_BasUltimate[client] == 1)
				{
					if(health < 500)
					{
						health += 2;
						SetEntProp(client, Prop_Data, "m_iHealth", health);
					}
				} else {
					health += 1;
					if(health <= 270)
					{
						SetEntProp(client, Prop_Data, "m_iHealth", health);
					}
				}
				if (buttons & IN_ATTACK)
				{
					buttons &= ~IN_ATTACK;
				}
			}
			if(g_NoFire[client])
			{
				if (buttons & IN_ATTACK)
				{
					buttons &= ~IN_ATTACK;
				}
			}
			if(buttons & IN_ATTACK)
			{
				g_OnBasHeal[client] = false;
				g_AllowBasHeal[client] = false;
			} else {
				g_AllowBasHeal[client] = true;
			}
		}
		if(g_Champion[client] == 3)
		{
			if(!StrEqual(weap, "tf_weapon_pistol_scout"))
			{
				TF2_SetPlayerClass(client, TFClass_Scout, true, true);
				GiveWeapon(client, "Tracer");
				SetEntProp(client, Prop_Send, "m_iHealth", 140);
				SetWeaponAmmo(client, 1, 99999999);
			}
			
			if(g_flRewind[client] - GetGameTime() > 25.0)
			{
				g_flRewind[client] = GetGameTime() + 25.0;
			}
			if(g_TracerFlash[client] > 3)
			{
				g_TracerFlash[client] = 3;
			}
			if(buttons == IN_BACK)
			{
				g_TracerFlashPosi[client] = 2;
			} else if(buttons == IN_FORWARD) {
				g_TracerFlashPosi[client] = 1;
			}
			if(g_TracerPos[client] == null)
			{
				g_TracerPos[client] = new ArrayList(3);
				g_TracerAng[client] = new ArrayList(3);
				g_TracerHealth[client] = new ArrayList(1);
			} else {
				if(g_TracerPos[client].Length < 170)
				{
					new Float:TPos[3], Float:TAng[3], health;
					GetClientAbsOrigin(client, TPos);
					GetClientAbsAngles(client, TAng);
					health = GetEntProp(client, Prop_Send, "m_iHealth");
					g_TracerPos[client].PushArray(TPos);
					g_TracerAng[client].PushArray(TAng);
					g_TracerHealth[client].Push(health);
				} else {
					g_TracerPos[client].Erase(0);
					g_TracerAng[client].Erase(0);
					g_TracerHealth[client].Erase(0);
				}
			}
			
			if(g_TracerOnThrowBomb[client])
			{
				new bomb = EntRefToEntIndex(g_iPulseBomb[client]);
				new Float:bombpos[3];
				GetEntPropVector(bomb, Prop_Send, "m_vecOrigin", bombpos);
				new Float:TaPos[3];
				for(new i=0; i<=MaxClients; i++)
				{
					GetClientAbsOrigin(i, TaPos);
					if(GetClientTeam(client) != GetClientTeam(i) && GetClientTeam(client) != 1 && GetClientTeam(i) != 1 && PlayerCheck(i) && PlayerCheck(client))
					{
						if(SetHitBoxAndTest(bombpos, i, 70.0) && PlayerCheck(i))
						{
							g_TracerBombTarget[client] = i;
							i = MaxClients + 1;
						}
					}
				}
			}
			if(g_TracerBombTarget[client] != 0)
			{
				new Float:TargetPos[3];
				GetClientAbsOrigin(g_TracerBombTarget[client], TargetPos);
				if(PlayerCheck(g_TracerBombTarget[client]))
				{
					SetHudTextParams(-1.0, -1.0, 0.25, 228, 0, 0, 255);
					ShowHudText(client, 7, "부착됨!");
					if(g_iPulseBomb[client] != -1)
					{
						new bomb = EntRefToEntIndex(g_iPulseBomb[client]);
						TeleportEntity(bomb, TargetPos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			new String:sscool[256], Float:cool;
			cool = g_flRewind[client] - GetGameTime();
			ChangeFloatValueToString(client, cool, sscool);
			
			if(g_TracerRewind[client] && !g_AllowRewind[client])
			{
				if(g_flRewind[client] - GetGameTime() == 0)
				{
					g_TracerRewind[client] = false;
					g_AllowRewind[client] = true;
				}
			}
		}
		if(g_Champion[client] == 4)
		{	
			if(StrEqual(weap, "tf_weapon_rocketlauncher") || StrContains(weap, "tf_weapon_shotgun_") || StrEqual(weap, "tf_weapon_shovel"))
			{
				GiveWeapon(client, "Soldier:76");
			}
			if(!g_SoldierDash[client])
			{
				if(TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly))
				{
					TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
				}
			}
			if(GetWeaponClip(client, 1) == 0)
			{
				if(!g_SoldReload[client])
				{
					g_SoldReload[client] = true;
					CreateTimer(1.5, Sold_Reload, client);
				}
			}
			if(g_OnSoldHeal[client])
			{
				new Float:HealPos[3], soheal, Float:TraceHealPos[3];
				soheal = EntRefToEntIndex(g_iHealBox[client]);
				if(soheal != -1)
				{
					GetEntPropVector(soheal, Prop_Data, "m_vecOrigin", HealPos);
					new clienthealth = GetClientHealth(client);
					if(clienthealth < 180 && SetHitBoxAndTest(HealPos, client, 200.0))
					{
						clienthealth += 1;
						SetEntProp(client, Prop_Data, "m_iHealth", clienthealth);
					}
					for(new i=1; i<=MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(client) == GetClientTeam(i) && GetClientTeam(i) != 1 && SetHitBoxAndTest(HealPos, i, 200.0) && i != client)
						{
							new ihealth = GetEntProp(i, Prop_Data, "m_iHealth");
							if(ihealth <= 180)
							{
								ihealth += 1;
								SetEntProp(i, Prop_Data, "m_iHealth", ihealth);
								ihealth = GetEntProp(i, Prop_Data, "m_iHealth");
								if(ihealth > 180)
								{
									SetEntProp(i, Prop_Data, "m_iHealth", 180);
								}
							}
						}
					}
					TraceHealPos[0] = HealPos[0];
					TraceHealPos[1] = HealPos[1];
					TraceHealPos[2] = 9500.0;
					//TE_SetupBeamPoints(HealPos, TraceHealPos, g_BeamSprite, g_HaloSprite);
					//Trace
					new Float:ccpos[3];
					GetClientAbsOrigin(client, ccpos);
					new Float:prepos[3];
					new Float:nexpos[3];
					new Float:i[1];
					i[0] = -179.9;
					while(i[0]<= 179.9)
					{
						nexpos[0] = Cosine(DegToRad(i[0]));
						nexpos[1] = Sine(DegToRad(i[0]));
						nexpos[2] = ccpos[2];
						if(nexpos[0] != prepos[0] && nexpos[1] != prepos[1])
						{
							//TE_SetupBeamPoints(prepos, nexpos, g_BeamSprite, g_HaloSprite);
						}
						prepos[0] = nexpos[0];
						prepos[1] = nexpos[1];
						prepos[2] = ccpos[2];
						i[0] += 0.1;
					}
				}
			}
			if(buttons == 0)
			{
				g_SoldierDash[client] = false;
			}
			if(g_SoldReload[client])
			{
				if (buttons & IN_ATTACK)
				{
					buttons &= ~IN_ATTACK;
				}
			}
			new iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(iCurrentWeapon == -1)
				return Plugin_Continue;
			
			ActiveWeapon[client] = GetEntProp(iCurrentWeapon, Prop_Send, "m_iItemDefinitionIndex");
			UpdateFirstOrderIntercept(client);

			new TFClassType:iClass = TF2_GetPlayerClass(client);
			new String:sWeapon[18];
			GetClientWeapon(client, sWeapon, sizeof(sWeapon));

			// Check for, and disable aiming for sapper's, medigun's, and wrench's
			if(StrEqual(sWeapon, "tf_weapon_sapper", false) || StrEqual(sWeapon, "tf_weapon_builder", false) || StrEqual(sWeapon, "tf_weapon_medigun", false) || StrEqual(sWeapon, "tf_weapon_wrench", false))
				return Plugin_Continue;

			g_bToHead[client] = ShouldAimToHead(iClass, sWeapon, ActiveWeapon[client]);

			if(g_OnSoldUlti[client])
			{
				new String:sButton;

				switch(g_OnSoldUlti[client])
				{
					case 1: sButton = IN_ATTACK2; // Secondary Attack
					case 2: sButton = IN_ATTACK3; // Special Attack
					case 3: sButton = IN_RELOAD;
					case 4: sButton = IN_ATTACK;
				}

				if(buttons & sButton)
				{
					AimTick(client, buttons);
				}
			}
			
			if(g_flSoldHeal[client] - GetGameTime() > 27.0)
			{
				g_flSoldHeal[client] = GetGameTime() + 25.0;
			}
			if(buttons & IN_ATTACK)
			{
				g_SoldierDash[client] = false;
			}
			return Plugin_Continue;
		}
		if(g_Champion[client] == 5)
		{
			if(!StrEqual(weap, "tf_weapon_revolver"))
			{
				if(PlayerCheck(client) && IsPlayerAlive(client))
				{
					GiveWeapon(client, "McCree");
					SetWeaponAmmo(client, 0, 999999);
				}
			}
			if(g_McCreeOnRapid[client])
			{
				if(GetWeaponClip(client, 0) != 0)
				{
					buttons |= IN_ATTACK;
					return Plugin_Changed;
				} else {
					g_McCreeOnRapid[client] = false;
					GiveWeapon(client, "McCree");
					SetWeaponClip(client, 0, 0);
				}
			}
			/*
			if(g_OnMcCreeUlt[client])
			{
				if(IsPlayerAlive(client))
				{
					for(new i=0; i<=MaxClients; i++)
					{
						if(IsPlayerAlive(i))
						{
							if(ClientViews(client, i, 1200.0))
							{
								g_InMcCreeUltView[client][i] = true;
								g_McCreeSightDamage[client][i] += 3;
							} else {
								g_InMcCreeUltView[client][i] = false;
								g_McCreeSightDamage[client][i] = 0;
							}
						} else {
							g_InMcCreeUltView[client][i] = false;
							g_McCreeSightDamage[client][i] = 0;
						}
					}
					if(buttons & IN_ATTACK)
					{
						g_OnMcCreeUlt[client] = false;
						for(new i=1; i<=MaxClients; i++)
						{
							if(g_InMcCreeUltView[client][i])
							{
								SDKHooks_TakeDamage(i, client, client, float(g_McCreeSightDamage[client][i]) / 3, DMG_CRIT|DMG_CRUSH);
							}
						}
					}
				} else {
					g_OnMcCreeUlt[client] = false;
				}
				if(g_McCreeUltCool[client] - GetGameTime() < 0.0)
				{
					g_OnMcCreeUlt[client] = false;
				}
			}
			*/
		}
		if(g_Champion[client] == 6)
		{
			if(!StrEqual(weap, "tf_weapon_sniperrifle"))
			{
				if(PlayerCheck(client) && IsPlayerAlive(client))
				{
					GiveWeapon(client, "Ana");
					SetWeaponAmmo(client, 0, 999999);
				}
			}
			if(g_OnAnaBomb[client])
			{
				new ent = EntRefToEntIndex(g_AnaBomb[client])
				if(ent != -1)
				{
					if(IsValidEntity(ent))
					{
						for(new j=1; j<=MaxClients; j++)
						{
							if(PlayerCheck(j))
							{
								new Float:ddpos[3];
								GetClientAbsOrigin(j, ddpos);
								if(SetHitBoxAndTest(ddpos, ent, 55.0))
								{
									new Float:eepos[3];
									GetEntPropVector(ent, Prop_Data, "m_vecOrigin", eepos);
									for(new i=1; i<=MaxClients; i++)
									{
										if(PlayerCheck(i))
										{
											if(SetHitBoxAndTest(eepos, i, 120.0))
											{
												new team = GetClientTeam(client);
												new iteam = GetClientTeam(i);
												if(team != iteam && iteam != 1)
												{
													SDKHooks_TakeDamage(i, client, client, 80.0, DMG_CRUSH);
												} else if(team == iteam) {
													new maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
													new health = GetEntProp(client, Prop_Data, "m_iHealth");
													new hj = health += 100;
													if (hj > maxHealth) {
														hj = maxHealth;
													}
													SetEntProp(client, Prop_Data, "m_iHealth", hj);
												}
											}
										}
									}
									g_OnAnaBomb[client] = false;
									AcceptEntityInput(ent, "Kill");
								}
							}
						}
						if(GetEntityFlags(ent) & FL_ONGROUND)
						{
							new Float:eepos[3];
							GetEntPropVector(ent, Prop_Data, "m_vecOrigin", eepos);
							for(new i=1; i<=MaxClients; i++)
							{
								if(PlayerCheck(i))
								{
									if(SetHitBoxAndTest(eepos, i, 120.0))
									{
										new team = GetClientTeam(client);
										new iteam = GetClientTeam(i);
										if(team != iteam && iteam != 1)
										{
											SDKHooks_TakeDamage(i, client, client, 80.0, DMG_CRUSH);
										} else if(team == iteam) {
											new maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
											new health = GetEntProp(client, Prop_Data, "m_iHealth");
											new hj = health += 100;
											if (hj > maxHealth) {
												hj = maxHealth;
											}
											SetEntProp(client, Prop_Data, "m_iHealth", hj);
										}
									}
								}
							}
							g_OnAnaBomb[client] = false;
							AcceptEntityInput(ent, "Kill");
						}
					}
				}
			}
		}
		if(g_Champion[client] == 7)
		{
			if(g_OnRoadHeal[client])
			{
				new health = GetClientHealth(client);
				health += 2;
				if(health <= 450)
				{
					SetEntProp(client, Prop_Send, "m_iHealth", health);
				} else {
					SetEntProp(client, Prop_Send, "m_iHealth", 450);
				}
				if (buttons & IN_ATTACK) 
				{
					buttons &= ~IN_ATTACK;
				}
			}
			if(g_OnRoadUlti[client])
			{
				buttons |= IN_ATTACK;
			}
			if(-0.1 < g_RoadUltcool[client] - GetGameTime() < 0.1)
			{
				GiveWeapon(client, "RoadHog");
			}
		}
		if(g_Champion[client] == 8)
		{
			if(g_ParahJetPack[client] - GetGameTime() > 25.0)
			{
				g_ParahJetPack[client] = GetGameTime() + 25.0;
			}
			if(buttons & IN_JUMP || buttons & IN_ATTACK2)
			{
				if(GetEntityFlags(client) & FL_ONGROUND)
				{
					if(!g_ParahAllowJump[client])
					{
						g_ParahAllowJump[client] = true;
						CreateTimer(1.5, Parah_AllowJump, client);
					}
				} else {
					Boost(client);
				}
				if(!g_ParahOnTimer[client])
				{
					g_ChargeTimer[client] = true;
					g_ParahAllowCharge[client] = false;
				}
				g_ParahDisplayBoost[client] = true;
			}
			if(!(buttons & IN_JUMP || buttons & IN_ATTACK2))
			{
				CreateTimer(1.5, Parah_DisplayTimer, client);
			}
			if(g_ParahBoostGage[client] < 0.0)
			{
				g_ParahBoostGage[client] = 0.0;
			} else if(g_ParahBoostGage[client] > 100.0) {
				g_ParahBoostGage[client] = 100.0;
			}
			if(!(buttons & IN_JUMP || buttons & IN_ATTACK2) || g_ParahBoostGage[client] == 0.0)
			{
				if(g_ChargeTimer[client])
				{
					g_ChargeTimer[client] = false;
					g_ParahOnTimer[client] = true;
					CreateTimer(0.75, Parah_ChargeTimer, client);
				}
			}
			if(g_ParahAllowCharge[client])
			{
				g_ParahBoostGage[client] += 0.15;
				if(g_ParahBoostGage[client] == 100.0)
				{
					g_ParahAllowCharge[client] = false;
				}
			}
		}
		if(g_Champion[client] == 9)
		{
			if(g_MercyOnKritz[client])
			{
				if(g_MercyTarget[client] != -1)
				{
					TF2_AddCondition(g_MercyTarget[client], TFCond_DefenseBuffed, TFCondDuration_Infinite);
				}
				if(buttons & IN_ATTACK)
				{
					g_MercyOnKritz[client] = false;
				}
				new String:classname[64];
				GetCurrentWeaponClass(client, classname, sizeof(classname));

				if(!StrEqual(classname, "CWeaponMedigun"))
				{
					g_MercyOnKritz[client] = false;
				}
				g_MercyHealType[client] = 2;
			} else {
				new String:classname[64];
				GetCurrentWeaponClass(client, classname, sizeof(classname));
				
				if(StrEqual(classname, "CWeaponMedigun"))
				{
					g_MercyHealType[client] = 1;
				} else {
					g_MercyHealType[client] = 2;
				}
			}
			new String:classname[64];
			if(StrEqual(classname, "CWeaponMedigun"))
			{
				if(!(buttons & IN_ATTACK) && !(buttons == IN_ATTACK2))
				{
					g_MercyHealType[client] = 0;
				}
			}
		}
		if(buttons == IN_RELOAD)
		{
			if(g_BasReload[client] == 1 && g_BasSecure[client] == 1 && g_Champion[client] == 2)
			{ 
				new ammo = GetWeaponAmmo(client, 0);
				if(ammo != 200)
				{
					CreateTimer(2.5, Bastion_ReloadTimer, client);
					SetHudTextParams(-1.0, -1.0, 3.0, 255, 255, 255, 255);
					TF2_StunPlayer(client, 2.5, 1.0, TF_STUNFLAG_NOSOUNDOREFFECT, 0);
					ShowHudText(client, 5, "장전중");
					g_BasReload[client] = 0;
				}
			}
		}
		ShowHud(client, buttons);
	}
	return Plugin_Continue;
}

public Action:ReinChargeReady(Handle:timer, any:client)
{
	g_ReinCharge[client] = 1;
	GetPlayerEye(client, Aimposition);
	return Plugin_Continue;
}

public Action:Rein_ShieldRegen(Handle:timer, any:client)
{
	if(!g_ReinShield[client] && !g_StartShieldRegen[client] && !g_AllowReinTimer[client])
	{
		g_StartShieldRegen[client] = true;
	}
}

public Action:Rein_PrimaryCoolDown(Handle:timer, any:client)
{
	g_ReinChargeAllow[client] = 1;
	SetHudTextParams(-1.0, 0.59, 1.0, 255, 255, 255, 255);
	ShowHudText(client, 1, "Shift is ready!");
	return Plugin_Continue;
}

public Action:Bastion_ReloadTimer(Handle:timer, any:client)
{
	if(g_BasSecure[client] == 1 && PlayerCheck(client))
	{
		SetWeaponAmmo(client, 0, 200);
	}
	g_BasReload[client] = 1;
	return Plugin_Continue;
}

public Action:Bastion_OnChange(Handle:timer, any:client)
{
	g_BasSecure[client] = 1;
	if(IsValidClient(client))
	{
		TF2_SetPlayerClass(client, TFClass_Heavy, true, true);
	}
	GiveWeapon(client, "Bastion2");
	if(GetWeaponAmmo(client, 0) != 200)
	{
		SetWeaponAmmo(client, 0, 200);
	}
	g_NoFire[client] = false;
	return Plugin_Continue;
}

public Action:Tracer_FlashCool1(Handle:timer, any:client)
{
	g_TracerFlash[client]++
	CreateTimer(2.5, Tracer_FlashCool2, client);
	g_TracerTimer1[client] = 0;
	return Plugin_Continue;
}

public Action:Tracer_FlashCool2(Handle:timer, any:client)
{
	if(g_TracerTimer1[client] == 0)
	{
		g_TracerFlash[client]++
		CreateTimer(2.5, Tracer_FlashCool3, client);
	}
	g_TracerTimer2[client] = 0;
	return Plugin_Continue;
}

public Action:Tracer_FlashCool3(Handle:timer, any:client)
{
	if(g_TracerTimer2[client] == 0)
	{
		g_TracerFlash[client]++
	}
	g_TracerTimer3[client] = 0;
	return Plugin_Continue;
}

public Action:Tracer_AllowFlash(Handle:timer, any:client)
{
	g_AllowFlash[client] = 1;
}

public Action:Tracer_RewindEffect(Handle:timer, any:client)
{
	new Float:pos[3], Float:ang[3], health, currenthealth;
	EmitSoundToAll("replay/rendercomplete.wav", client);
	EmitSoundToClient(client, "replay/rendercomplete.wav");
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(client, 255,255,255,255);
	g_TracerPos[client].GetArray(0, pos);
	g_TracerAng[client].GetArray(0, ang);
	currenthealth = GetClientHealth(client);
	health = g_TracerHealth[client].Get(0);
	TeleportEntity(client, pos, ang, NULL_VECTOR);
	if(currenthealth < health)
	{
		SetEntProp(client, Prop_Send, "m_iHealth", health);
	}
	g_TracerRewind[client] = false;
	return Plugin_Continue;
}

public Action:Tracer_PutRecord(Handle:timer, any:client)
{
	g_AllowRewind[client] = true;
}

public Action:Bastion_HealAnim(Handle:timer, any:client)
{
	if(PlayerCheck(client) && g_AllowBasHeal[client])
	{
		g_OnBasHeal[client] = true;
	}
}

public Action:Bastion_ForTank(Handle:timer, any:client)
{
	if(PlayerCheck(client))
	{
		TF2_SetPlayerClass(client, TFClass_Heavy, true, true);
		GiveWeapon(client, "Bastion3");
		SetEntProp(client, Prop_Send, "m_iHealth", 500);
		CreateTimer(8.0, Bastion_Tank, client);
	}
	return Plugin_Continue;
}

public Action:Bastion_Tank(Handle:timer, any:client) // IsPlayerAlive 나중에
{
	if(PlayerCheck(client))
	{
		g_BasUltimate[client] = 0;
		TF2_SetPlayerClass(client, TFClass_Sniper, true, true);
		new health = GetEntProp(client, Prop_Data, "m_iHealth");
		GiveWeapon(client, "Bastion");
		if(health >= 270)
		{
			SetEntProp(client, Prop_Send, "m_iHealth", 270);
		} else {
			SetEntProp(client, Prop_Send, "m_iHealth", health);
		}
		g_OnBasHeal[client] = false;
	}
	return Plugin_Continue;
}

public Action:Sold_Reload(Handle:timer, any:client)
{
	if(g_SoldReload[client])
	{
		g_SoldReload[client] = false;
		SetWeaponClip(client, 1, 25);
	}
}

public Action:Soldier_Heal(Handle:timer, any:entity)
{
	new client;
	if(IsValidEntity(entity))
	{
		client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		AcceptEntityInput(entity, "Kill");
	}
	g_OnSoldHeal[client] = false;
	return Plugin_Continue;
}

public Action:Sold_Ult(Handle:timer, any:client)
{
	g_OnSoldUlti[client] = false;
	return Plugin_Continue;
}

public Action:McCree_Slump(Handle:timer, any:client)
{
	if(g_OnSlump[client])
	{
		g_OnSlump[client] = false;
		new Float:ang[3];
		GetClientAbsAngles(client, ang);
		TeleportEntity(client, NULL_VECTOR, ang, NULL_VECTOR);
		SetWeaponClip(client, 0, 6);
	}
	return Plugin_Continue;
}

public Action:McCree_SlumpAnim(Handle:timer, any:client)
{
	if(PlayerCheck(client))
	{
		if(g_McCreeSlump[client] <= 180)
		{
			new Float:ang[3];
			GetClientAbsAngles(client, ang);
			if(g_McCreeSlump[client] <= 90)
			{
				ang[2]++
			} else if(90 < g_McCreeSlump[client] < 180) {
				ang[2]--
			}
			return Plugin_Continue;
		} else {
			new Float:ang[3];
			GetClientAbsAngles(client, ang);
			TeleportEntity(client, NULL_VECTOR, ang, NULL_VECTOR);
			ang[2] = 0.0;
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action:McCree_FlashBomb(Handle:timer, any:entity)
{
	new Float:epos[3], client, weapon;
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", epos);
	client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	weapon = GetPlayerWeaponSlot(client, 0);
	for(new i=1; i<=MaxClients; i++)
	{
		if(PlayerCheck(i))
		{
			if(SetHitBoxAndTest(epos, i, 230.0) && GetClientTeam(i) != 1 && GetClientTeam(i) != GetClientTeam(client) && i != client)
			{
				if(g_Champion[i] != 2)
				{
					SetHudTextParams(-1.0, 0.45, 0.8, 227, 0, 0, 255);
					ShowHudText(i, 5, "기절함!");
					TF2_StunPlayer(i, 1.15, 1.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_THIRDPERSON, client);
					SDKHooks_TakeDamage(i, 0, client, 30.0, DMG_BURN, weapon);
					g_OnStun[i] = true;
				} else {
					g_NoFire[i] = true;
				}
				CreateTimer(1.15, McCree_StunMotion, i);
			}
		}
	}
	return Plugin_Continue;
}

public Action:McCree_StunMotion(Handle:timer, any:client)
{
	g_OnStun[client] = false;
	g_NoFire[client] = false;
	return Plugin_Continue;
}

public Action:McCree_AllowRapid(Handle:timer, any:client)
{
	g_AllowRapid[client] = true;
	return Plugin_Continue;
}

public Action:McCree_Rapid2(Handle:timer, any:client)
{
	SetWeaponClip(client, 0, g_Clip[client]);
	return Plugin_Continue;
}

public Action:Ana_AttackAnim(Handle:timer, any:client)
{
	if(g_AnaAttackTime[client] != 3 && PlayerCheck(client) && PlayerCheck(g_AnaAttacker[client]))
	{
		new String:Weapon[256];
		GetClientWeapon(g_AnaAttacker[client], Weapon, sizeof(Weapon));
		SDKHooks_TakeDamage(client, 0, g_AnaAttacker[client], 10.0, DMG_BULLET);
		g_AnaAttackTime[client]++
		return Plugin_Continue;
	} else {
		g_AnaAttackTime[client] = 0;
		g_AnaAttacker[client] = 0;
		return Plugin_Stop;
	}
}

public Action:Road_Heal(Handle:timer, any:client)
{
	if(PlayerCheck(client))
	{
		g_OnRoadHeal[client] = false;
		g_DisAbleFire[client] = false;
	}
	return Plugin_Continue;
}

public Action:Road_Fire(Handle:timer, any:client)
{
	g_DisAbleFire[client] = false;
	return Plugin_Continue;
}

public Action:Road_Ult(Handle:timer, any:client)
{
	GiveWeapon(client, "RoadHog");
	g_OnRoadUlti[client] = false;
	return Plugin_Continue;
}

public Action:Parah_ChargeTimer(Handle:timer, any:client)
{
	g_ParahAllowCharge[client] = true;
	g_ParahOnTimer[client] = false;
	return Plugin_Continue;
}

public Action:Parah_DisplayTimer(Handle:timer, any:client)
{
	g_ParahDisplayBoost[client] = false;
	return Plugin_Continue;
}

public Action:Parah_Ult(Handle:timer, any:client)
{
	if(g_ParahUltTimer[client] <= 150)
	{
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
		SetEntityMoveType(client, MOVETYPE_NONE);
		FireRocket(client);
		g_ParahUltTimer[client]++
		return Plugin_Continue;
	} else {
		SetEntityMoveType(client, MOVETYPE_WALK);
		return Plugin_Stop;
	}
}

public Action:Parah_AllowJump(Handle:timer, any:client)
{
	g_ParahAllowJump[client] = false;
	Boost(client);
}

stock DeleteWeapons(client, String:iiSlot[], iiislot = -1)
{
	TF2_RemoveAllWeapons(client);
	for(new i=0; i<= 5 ;i++)
	{
		new iSlot = StringToInt(iiSlot);
		if(i != iSlot)
		{
			TF2_RemoveWeaponSlot(client, i);
		}
	}
}

stock GetWeaponAmmo(client, slot)
{
    if (!IsValidEntity(client)) return 0;

    new weapon = GetPlayerWeaponSlot(client, slot);

    if (weapon != -1)
    {
		if(PlayerCheck(client))
		{
			new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1) * 4;
			new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");

			return GetEntData(client, iAmmoTable + iOffset);
		}
    }

    return 0;
}  

stock SetWeaponAmmo(client, slot, ammo)
{
    new weapon = GetPlayerWeaponSlot(client, slot);

    if (weapon != -1)
    {
        new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1) * 4;
        new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");

        SetEntData(client, iAmmoTable + iOffset, ammo, 4, true);
    }
}

stock GetClientSpeed(client)
{
    new Float:Speed = GetEntPropFloat(client, Prop_Data, "m_flSpeed");
    
    PrintToChat(client, "Your max Speed is %f", Speed);
}  

bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
 
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
 
	if(TR_DidHit(trace)) 
	{
	TR_GetEndPosition(pos, trace);
	CloseHandle(trace);
	return true;
	}
	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
    return entity > GetMaxClients();
}

public GetDeaths(client)
{
    return GetEntProp(client, Prop_Data, "m_iDeaths");
}

public SetDeaths(client, deaths)
{
    SetEntProp(client, Prop_Data, "m_iDeaths", deaths);
}

stock bool:PlayerCheck(Client){
	if(Client > 0 && Client <= MaxClients){
		if(IsClientConnected(Client) == true){
			if(IsClientInGame(Client) == true){
				return true;
			}
		}
	}
	return false;
}

stock CreateParticle(ent, String:particleType[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");

	decl String:name[64];

	if(IsValidEdict(particle))
	{
		new Float:position[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
		position[2] += 50.0;
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", name);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(name);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticle, particle);
	}
}

public Action:DeleteParticle(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classN[64];
        GetEdictClassname(particle, classN, sizeof(classN));
        if (StrEqual(classN, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
    }
}

stock void SetModel(int client, const char[] model)
{
	SetVariantString(model);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}

/*
stock CreateShield(client)
{
	new shield = CreateEntityByName("prop_physics");
	
	SetEntProp(shield, Prop_Data, "m_takedamage", 2, 1);
	SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", client);  
	SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(client));  
	SetEntProp(shield, Prop_Data, "m_iInitialTeamNum", GetClientTeam(client));  
	
	DispatchKeyValue(shield, "model", "models/props_mvm/mvm_player_shield2.mdl");
	DispatchSpawn(shield);
	EmitSoundToClient(client, "weapons/medi_shield_deploy.wav", shield);

	if(IsValidEntity(g_ReinEntity[client]) && g_ReinShieldHealth[client] > 0)
	{
		SetVariantInt(g_ReinShieldHealth[client]);
		AcceptEntityInput(shield, "SetHealth");
	}
	g_ReinEntity[client] = shield;
	
	g_ReinShield[client] = true;
}

stock KillShield(client)
{
	new shield = g_ReinShield[client];
	if(IsValidEntity(shield))
	{
		AcceptEntityInput(shield, "Kill");
	}
	g_ReinShield[client] = false;
}
*/

/*
SetEntData(weapon, m_iClip1, 0);
*/

stock GetWeaponClip(client, slot)
{
	new clip;
	if(PlayerCheck(client))
	{
		new weapon = GetPlayerWeaponSlot(client, slot);
		
		if(IsValidEntity(weapon))
		{
			clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
		}
	}
	return clip;
}

stock SetWeaponClip(client, slot, ammo)
{
	if(PlayerCheck(client))
	{
		new weapon = GetPlayerWeaponSlot(client, slot);
		if(IsValidEntity(weapon))
		{
			SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);
		}
	}
}

stock void Flash(client)
{
	g_TracerFlash[client] = g_TracerFlash[client] - 1;
	new Float:vel[3], Float:aim[3], Float:posi[3], Float:iposi[3];
	GetPlayerEye(client, aim);
	GetClientAbsOrigin(client, posi);
	MakeVectorFromPoints(posi, aim, vel);
	vel[2] = 0.0;
	NormalizeVector(vel, vel);
	if(g_TracerFlashPosi[client] == 1)
	{
		ScaleVector(vel, 700.0);
	} else if(g_TracerFlashPosi[client] == 2) {
		ScaleVector(vel, -700.0);
	} else {
		ScaleVector(vel, 700.0);
	}
	vel[2] += 135.0;
	GetClientAbsOrigin(client, g_TracerFlashFirstpos)
	if(!(GetEntityFlags(client) & FL_ONGROUND))
	{
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	} else if(GetEntityFlags(client)) {
		GetClientAbsOrigin(client, iposi);
		iposi[2] += 50.0;
		TeleportEntity(client, iposi, NULL_VECTOR, vel);
	}
	if(g_TracerFlash[client] == 2)
	{
		CreateTimer(2.5, Tracer_FlashCool3, client);
		g_TracerTimer3[client] = 1;
	}
	if(g_TracerFlash[client] == 1)
	{
		CreateTimer(2.5, Tracer_FlashCool2, client);
		g_TracerTimer2[client] = 1;
	}
	if(g_TracerFlash[client] == 0)
	{
		CreateTimer(2.5, Tracer_FlashCool1, client);
		g_TracerTimer1[client] = 1;
	}
	EmitSoundToAll("overwatch/tracer/skills/tracer_blink.mp3", client);
	g_AllowFlash[client] = 0;
	CreateTimer(0.3, Tracer_AllowFlash, client);
}

stock void ChangeFloatValueToString(client, float flValue, String:GetValue[]) // Need 256 Array
{
	// 25.3333
	new String:sflValue[256], String:sflValue2[256];
	new iflValue = RoundToFloor(flValue); // 25
	new iflValue2 = RoundToFloor(flValue * 10); // 253
	new value = iflValue2 - iflValue * 10;
	
	IntToString(value, sflValue, sizeof(sflValue)); // 3 을 스트링으로 
	IntToString(iflValue, sflValue2, sizeof(sflValue2));
	Format(GetValue, 256, "%s.%s", sflValue2, sflValue);
}

public Action:Rein_ShieldHook(entity, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new health;
	if(PlayerCheck(client) && PlayerCheck(attacker))
	{
		health = g_ReinShieldHealth[client];
		if(GetClientTeam(attacker) != 1 && GetClientTeam(attacker) != GetClientTeam(client))
		{
			health -= RoundToZero(damage);
			SetVariantInt(health);
			AcceptEntityInput(entity, "SetHealth");
		} else if(GetClientTeam(attacker) == GetClientTeam(client)) {
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	
	if(health < 1)
	{
		g_ReinShield[client] = false;
		g_StartShieldRegen[client] = false;
		g_AllowReinTimer[client] = true;
		//SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		new shield = EntRefToEntIndex(g_ReinEntity[client]);
		AcceptEntityInput(shield, "Kill");
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 300.0);
	}
	return Plugin_Continue;
}

stock void StartSound(client, String:Char[])
{
	if(StrEqual(Char, "Tracer"))
	{
		switch(GetRandomInt(0, 1))
		{
			case 0: EmitSoundToAll("overwatch/tracer/walking/tracer_start.mp3", client);
			case 1: EmitSoundToAll("overwatch/tracer/walking/tracer_start2.mp3", client);
		}
	} else if(StrEqual(Char, "Soldier:76")) {
		switch(GetRandomInt(0, 1))
		{
			case 0: EmitSoundToAll("overwatch/soldier76/walking/soldier76_start.mp3", client);
			case 1:	EmitSoundToAll("overwatch/soldier76/walking/soldier76_start2.mp3", client);
		}
	} else if(StrEqual(Char, "McCree")) {
		switch(GetRandomInt(0, 1))
		{
			case 0: EmitSoundToAll("overwatch/mccree/walking/mccree_start1.wav", client);
			case 1:	EmitSoundToAll("overwatch/mccree/walking/mccree_start2.wav", client);
		}
	}
}

stock bool:SetHitBoxAndTest(Float:pos[3], int iclient, float x = 1.0)
{
	new Float:ipos[3];
	GetEntPropVector(iclient, Prop_Data, "m_vecOrigin", ipos);
	if(pos[0] + x > ipos[0] && pos[0] - x < ipos[0] && pos[1] + x > ipos[1] && pos[1] - x < ipos[1] && pos[2] + x > ipos[2] && pos[2] - x < ipos[2])
	{
		return true;
	} else {
		return false;
	}
}

stock void GetEndPosition(float end[3], float start[3], float angle[3], float distance, bool:negative = false)
{
	float vector[3];
	end[0] = start[0];
	end[1] = start[1];
	end[2] = start[2];

	vector[0] = Cosine(DegToRad(angle[1]));
	vector[1] = Sine(DegToRad(angle[1]));
	vector[2] = Sine(DegToRad(angle[0])) * -1.0;
	NormalizeVector(vector, vector);
	ScaleVector(vector, distance);

	if(negative) ScaleVector(vector, -1.0);
	AddVectors(end, vector, end);
}

stock SetPlayerInfo(client, String:aPath[], String:fKey[], String:sKey[], String:tKey[], String:ffKey[], int mode)
{
	new String:KPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, KPath, sizeof(KPath), aPath);
	
	new Handle:DB = CreateKeyValues(fKey);
	FileToKeyValues(DB, KPath);
	if(KvJumpToKey(DB, sKey, true))
	{
		if(mode == 0)
		{
			new num = StringToInt(ffKey);
			KvSetNum(DB, tKey, num);
		} else if(mode == 1) {
			KvSetString(DB, tKey, ffKey);
		} else if(mode == 2) {
			new Float:val[1];
			val[0] = StringToFloat(ffKey);
			KvSetFloat(DB, tKey, val[0]);
		}
	}
	KeyValuesToFile(DB, KPath);
	CloseHandle(DB);
}

stock GetPlayerInfo(client, String:abPath[], String:fKey[], String:sKey[], String:tKey[], String:buffer[], int mode)
{
	new String:KPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, KPath, sizeof(KPath), abPath);
	
	new Handle:DB = CreateKeyValues(fKey);
	FileToKeyValues(DB, KPath);
	if(KvJumpToKey(DB, fKey, true))
	{
		if(mode == 0)
		{
			new num = KvGetNum(DB, tKey, 0);
			IntToString(num, buffer, sizeof(buffer));
		} else if(mode == 1) {
			KvGetString(DB, tKey, buffer, sizeof(buffer));
		} else if(mode == 2) {
			new Float:s[1];
			s[0] = KvGetFloat(DB, tKey);
			FloatToString(s[0], buffer, sizeof(buffer));
		}
	}
}

bool:CanSeeTarget(iClient, iTarget, iTeam, bool:bCheckFOV)
{
	decl Float:flStart[3], Float:flEnd[3];
	GetClientEyePosition(iClient, flStart);
	GetClientEyePosition(iTarget, flEnd);
	
	TR_TraceRayFilter(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, iTarget);
	if(TR_GetEntityIndex() == iTarget)
	{
		if(TF2_GetPlayerClass(iTarget) == TFClass_Spy)
		{
			if(TF2_IsPlayerInCondition(iTarget, TFCond_Cloaked) || TF2_IsPlayerInCondition(iTarget, TFCond_Disguised))
			{
				if(TF2_IsPlayerInCondition(iTarget, TFCond_CloakFlicker)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_OnFire)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_Jarated)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_Milked)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_Bleeding))
				{
					return true;
				}

				return false;
			}
			if(TF2_IsPlayerInCondition(iTarget, TFCond_Disguised) && GetEntProp(iTarget, Prop_Send, "m_nDisguiseTeam") == iTeam)
			{
				return false;
			}

			return true;
		}
		
		if(TF2_IsPlayerInCondition(iTarget, TFCond_Ubercharged)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedHidden)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedCanteen)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedOnTakeDamage)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_PreventDeath)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_Bonked))
		{
			return false;
		}
		
		if(bCheckFOV)
		{
			decl Float:eyeAng[3], Float:reqVisibleAng[3];
			GetClientEyeAngles(iClient, eyeAng);
			
			new Float:flFOV = float(g_iPlayerDesiredFOV[iClient]);
			SubtractVectors(flEnd, flStart, reqVisibleAng);
			GetVectorAngles(reqVisibleAng, reqVisibleAng);
			
			new Float:flDiff = FloatAbs(AngleDiff(eyeAng[0], reqVisibleAng[0])) + FloatAbs(AngleDiff(eyeAng[1], reqVisibleAng[1]));
			if (flDiff > ((flFOV * 0.5) + 10.0)) 
				return false;
		}

		return true;
	}

	return false;
}

public bool:TraceRayFilterClients(iEntity, iMask, any:hData)
{
	if(iEntity > 0 && iEntity <=MaxClients)
	{
		if(iEntity == hData)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	return true;
}

stock CreateEyeProp(iClient)
{
	if(IsSprite(ClientEyes[iClient]))
		AcceptEntityInput(ClientEyes[iClient], "Kill");

	new DProp = CreateEntityByName("env_sprite");

	if(DProp > 0 && IsValidEntity(DProp))
	{
		DispatchKeyValue(DProp, "classname", "env_sprite");
		DispatchKeyValue(DProp, "spawnflags", "1");
		DispatchKeyValue(DProp, "rendermode", "0");
		DispatchKeyValue(DProp, "rendercolor", "0 0 0");
		
		DispatchKeyValue(DProp, "model", "effects/strider_bulge_dudv_dx60.vmt");
		SetVariantString("!activator");
		AcceptEntityInput(DProp, "SetParent", iClient, DProp, 0);
		SetVariantString("head");
		AcceptEntityInput(DProp, "SetParentAttachment", DProp , DProp, 0);
		DispatchSpawn(DProp);

		ClientEyes[iClient] = EntIndexToEntRef(DProp);
		SDKHook(DProp, SDKHook_SetTransmit, OnShouldProp);

		TeleportEntity(DProp, Float:{0.0,0.0,-4.0}, NULL_VECTOR, NULL_VECTOR);

	}
}

public Action:OnShouldProp(iEnt, iClient)
{
	return Plugin_Handled;
}

stock bool:IsSprite(Ent)
{
	if(Ent != -1 && IsValidEdict(Ent) && IsValidEntity(Ent) && IsEntNetworkable(Ent))
	{
		decl String:ClassName[255];
		GetEdictClassname(Ent, ClassName, 255);
		if(StrEqual(ClassName, "env_sprite"))
			return true;
	}
	return false;
}

stock ClampAngle(Float:flAngles[3])
{
	while(flAngles[0] > 89.0)  flAngles[0]-=360.0;
	while(flAngles[0] < -89.0) flAngles[0]+=360.0;
	while(flAngles[1] > 180.0) flAngles[1]-=360.0;
	while(flAngles[1] <-180.0) flAngles[1]+=360.0;
}

bool:ShouldAimToHead(TFClassType:iClass, const String:strWeapon[], iWeapon)
{
	// These checks are probably mostly redundant, but just want to be sure I make certain classes aim at certain points of the body to be effective
		
	if(StrEqual(strWeapon, "tf_weapon_pipebomblauncher", false)
	|| StrEqual(strWeapon, "tf_weapon_grenadelauncher", false)
	|| StrEqual(strWeapon, "tf_weapon_cannon", false)
	|| StrEqual(strWeapon, "tf_weapon_crossbow", false)
	|| StrEqual(strWeapon, "tf_weapon_syringegun_medic", false)
	|| StrEqual(strWeapon, "tf_weapon_flaregun", false))
		return true;
	
	switch(iWeapon)			// Any revolver other than Ambassador
	{
		case 24,161,210,224,460,535,1142,15011,15027,15042,15051:
			return false;
	}
	
	if (iClass == TFClass_Sniper || (iClass == TFClass_Spy && !StrEqual(strWeapon, "tf_weapon_knife", false)))
		return true;
		
	return false;
}

UpdateFirstOrderIntercept(iClient)
{
	switch(ActiveWeapon[iClient])
	{
		case 812,833,44,648,595: FOISpeed = 3000.0;
		case 49,351,740,1081: FOISpeed = 2000.0;
		case 442,588: FOISpeed = 1200.0;
		case 997,305,1079: FOISpeed = 2400.0;
		case 414: FOISpeed = 1540.0;
		case 127: FOISpeed = 1980.0;
		case 222,1121,58,1083,1105: FOISpeed = 925.0;
		case 996: FOISpeed = 1811.0;
		case 56,1005,1092: FOISpeed = 1800.0;
		case 308: FOISpeed = 1510.0;
		case 19,206,1007,1151: FOISpeed = 1215.0;
		case 18,205,228,441,513,658,730,800,809,889,898,907,916,965,974,1085,1104,15006,15014,15028,15043,15052,15057: FOISpeed = 1100.0;
		case 17,204,36,412,20,207,130,661,797,806,886,895,904,913,962,971,1150,15009,15012,15024,15038,15045,15048: FOISpeed = 1000.0;
		default: FOISpeed = 1000000.0;
	}
}

//first-order intercept using absolute target position (http://wiki.unity3d.com/index.php/Calculating_Lead_For_Projectiles)
FirstOrderIntercept(Float:shooterPosition[3],Float:shooterVelocity[3],Float:shotSpeed,Float:targetPosition[3],Float:targetVelocity[3])
{
    decl Float:targetRelativePosition[3];
    SubtractVectors(targetPosition, shooterPosition, targetRelativePosition);
    decl Float:targetRelativeVelocity[3];
    SubtractVectors(targetVelocity, shooterVelocity, targetRelativeVelocity);
    new Float:t = FirstOrderInterceptTime(shotSpeed, targetRelativePosition, targetRelativeVelocity);

    ScaleVector(targetRelativeVelocity, t);
    AddVectors(targetPosition, targetRelativeVelocity, targetPosition);
}

//first-order intercept using relative target position
Float:FirstOrderInterceptTime(Float:shotSpeed, Float:targetRelativePosition[3], Float:targetRelativeVelocity[3])
{
    new Float:velocitySquared = GetVectorLength(targetRelativeVelocity, true);
    if(velocitySquared < 0.001)
    {
        return 0.0;
    }

    new Float:a = velocitySquared - shotSpeed*shotSpeed;
    if (FloatAbs(a) < 0.001)  //handle similar velocities
    {
        new Float:t = -GetVectorLength(targetRelativePosition, true)/(2.0*GetVectorDotProduct(targetRelativeVelocity, targetRelativePosition));

        return t > 0.0 ? t : 0.0; //don't shoot back in time
    }

    new Float:b = 2.0*GetVectorDotProduct(targetRelativeVelocity, targetRelativePosition);
    new Float:c = GetVectorLength(targetRelativePosition, true);
    new Float:determinant = b*b - 4.0*a*c;

    if (determinant > 0.0)  //determinant > 0; two intercept paths (most common)
    { 
        new Float:t1 = (-b + SquareRoot(determinant))/(2.0*a);
        new Float:t2 = (-b - SquareRoot(determinant))/(2.0*a);
        if (t1 > 0.0)
        {
            if (t2 > 0.0) 
            {
                return t2 < t2 ? t1 : t2; //both are positive
            }
            else
            {
                return t1; //only t1 is positive
            }
        }
        else
        {
            return t2 > 0.0 ? t2 : 0.0; //don't shoot back in time
        }
    }
    else if (determinant < 0.0) //determinant < 0; no intercept path
    {
        return 0.0;
    }
    else //determinant = 0; one intercept path, pretty much never happen
    {
        determinant = -b/(2.0*a);       // temp
        return determinant > 0.0 ? determinant : 0.0; //don't shoot back in time
    }
}

stock Float:GetVectorAnglesTwoPoints(const Float:startPos[3], const Float:endPos[3], Float:angles[3])
{
	static Float:tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

stock Float:AngleDiff(Float:firstAngle, Float:secondAngle)
{
	new Float:diff = secondAngle - firstAngle;
	return AngleNormalize(diff);
}

stock Float:AngleNormalize(Float:angle)
{
	while (angle > 180.0) angle -= 360.0;
	while (angle < -180.0) angle += 360.0;
	return angle;
}

public AimTick(iClient, &iButtons)
{
	static NextTargetTime[MAXPLAYERS+1];
	static Target[MAXPLAYERS+1];
	
	decl Float:clientEyes[3], Float:targetEyes[3];
	GetClientEyePosition(iClient, clientEyes);
	
	new iTeam = GetClientTeam(iClient);
	
	// Thanks Mitchell for this awesome code
	if(NextTargetTime[iClient] < GetTime())
	{
		Target[iClient] = GetClosestClient(iClient);
		NextTargetTime[iClient] = GetTime() + 5;
	}
	if(!IsValidClient(Target[iClient]) || !IsPlayerAlive(Target[iClient]))
	{
		Target[iClient] = GetClosestClient(iClient);
		NextTargetTime[iClient] = GetTime() + 5;
	}
	else
	{
		GetClientEyePosition(Target[iClient], targetEyes);
		if(!CanSeeTarget(iClient, Target[iClient],  iTeam, false))
		{
			Target[iClient] = GetClosestClient(iClient);
			NextTargetTime[iClient] = GetTime() + 5;
		}
	}

	if(Target[iClient] > 0)
	{
		if(IsSprite(ClientEyes[Target[iClient]]))
		{
			decl Float:camangle[3], Float:targetVel[3], Float:originVel[3];
			GetEntPropVector(ClientEyes[Target[iClient]], Prop_Data, "m_vecAbsOrigin", targetEyes);
			GetEntPropVector(Target[iClient], Prop_Data, "m_vecVelocity", targetVel);
			GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", originVel);
					
			if(!g_bToHead[iClient])
				targetEyes[2] -= 25.0;
			
			FirstOrderIntercept(clientEyes, Float:{0.0, 0.0, 0.0}, FOISpeed, targetEyes, targetVel);
			
			switch(ActiveWeapon[iClient])
			{
				case 56, 1005, 1092, 39, 351, 595, 740, 1081:
					targetEyes[2] += GetVectorDistance(clientEyes, targetEyes)/75.0;	// Calculate the dropoff
			}

			GetVectorAnglesTwoPoints(clientEyes, targetEyes, camangle);
			ClampAngle(camangle);
			
			TeleportEntity(iClient, NULL_VECTOR, camangle, NULL_VECTOR);
		}
		else Target[iClient] = 0;
	}
}

stock GetClosestClient(iClient)
{
	decl Float:fClientLocation[3];
	GetClientEyePosition(iClient, fClientLocation);
	decl Float:fEntityOrigin[3];

	new iTeam = GetClientTeam(iClient);
	new iClosestEntity = -1;
	new Float:fClosestDistance = -1.0;
	new Float:fEntityDistance;

	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) != iTeam && IsPlayerAlive(i) && i != iClient)
		{
			GetClientEyePosition(i, fEntityOrigin);
			fEntityDistance = GetVectorDistance(fClientLocation, fEntityOrigin);
			if((fEntityDistance < fClosestDistance) || fClosestDistance == -1.0)
			{
				if(CanSeeTarget(iClient, i, iTeam, false) && IsSprite(ClientEyes[i]))
				{
					fClosestDistance = fEntityDistance;
					iClosestEntity = i;
				}
			}
		}
	}
	return iClosestEntity;
}

stock bool:IsValidClient(iClient, bool:bAlive = false)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;

	if(IsClientSourceTV(iClient) || IsClientReplay(iClient))
		return false;
	
	if(bAlive && !IsPlayerAlive(iClient))
		return false;

	return true;
}

public OnClientGetDesiredFOV(QueryCookie:cookie, iClient, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!IsValidClient(iClient)) return;
	
	g_iPlayerDesiredFOV[iClient] = StringToInt(cvarValue);
}

public Action:Ana_Touch(client, other)
{
	if(PlayerCheck(client))
	{
		if(IsPlayerAlive(client))
		{
			TF2_StunPlayer(client, 7.0, 1.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_THIRDPERSON, 0);
			SetHudTextParams(-1.0, -1.0, 3.0, 255, 255, 255, 255);
			ShowHudText(client, 5, "수면 당함!");
		}
	}
}

public bool:Rein_Collide( entity, collisiongroup, contentsmask, bool:result ) 
{ 
	if(entity > MaxClients && IsValidEntity(entity))
	{
		result = true;
	}
}  

stock void Boost(client)
{
	if(g_ParahBoostGage[client] != 0.0 && g_AllowBoost[client])
	{
		g_ParahBoostGage[client] -= 0.47;
		decl Float:aim[3];
		GetClientAbsAngles(client, aim);
		GetAngleVectors(aim, aim, NULL_VECTOR, NULL_VECTOR);
		if(GetClientButtons(client) & IN_FORWARD)
		{
			aim[0] = aim[0] * 300;
			aim[1] = aim[1] * 300;
		}
		if(GetClientButtons(client) & IN_BACK)
		{
			aim[0] = aim[0] * -300;
			aim[1] = aim[1] * -300;
		}
		aim[2] = 120.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, aim);
	}
}

int CreateLauncher(int client)
{
	int ent = CreateEntityByName("tf_point_weapon_mimic");
	DispatchKeyValue(ent, "ModelOverride", "models/weapons/w_models/w_rocket_airstrike/w_rocket_airstrike.mdl");
	DispatchKeyValue(ent, "WeaponType", "0");
	DispatchKeyValue(ent, "SpeedMin", "2000");
	DispatchKeyValue(ent, "SpeedMax", "2000");
	DispatchKeyValue(ent, "Damage", "35");
	DispatchKeyValue(ent, "SplashRadius", "120");
	DispatchSpawn(ent);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	AcceptEntityInput(ent, "FireOnce");
	
	return ent;
}

void FireRocket(int client)
{
	float flPos[3], flAng[3];
	GetClientEyeAngles(client, flAng);
	GetClientEyePosition(client, flPos);
	
	int l1 = CreateLauncher(client);
	SetEntProp(l1, Prop_Data, "m_nSimulationTick", 3);
	int l2 = CreateLauncher(client);
	SetEntProp(l2, Prop_Data, "m_nSimulationTick", 4);
}

stock Timer_FireRocket(int iRef)
{
	int ent = EntRefToEntIndex(iRef);
	if(ent != -1)
	{
		int client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		int iLauncher = GetEntProp(ent, Prop_Data, "m_nSimulationTick");
		
		float flMaxs[3];
		GetEntPropVector(client, Prop_Send, "m_vecMaxs", flMaxs);
		
		float flPos[3], flAng[3], vLeft[3];
		GetClientEyeAngles(client, flAng);
		GetClientEyePosition(client, flPos);
		GetAngleVectors(flAng, vLeft, NULL_VECTOR, NULL_VECTOR);
		
		switch(iLauncher)
		{
			case 1:
			{
				flPos[0] += (vLeft[0] * -50);
				flPos[1] += (vLeft[1] * -50);
				flPos[2] += (vLeft[2] * -50);
			}
			case 2:
			{
				flPos[0] += (vLeft[0] * 50);
				flPos[1] += (vLeft[1] * 50);
				flPos[2] += (vLeft[2] * 50);
			}
		}
		
		flPos[2] -= GetRandomFloat(-(flMaxs[2] / 1.5), flMaxs[2] / 1.5);
		
		DispatchKeyValueVector(ent, "origin", flPos);
		DispatchKeyValueVector(ent, "angles", flAng);
		
		switch(GetRandomInt(1, 3))
		{
			case 1: EmitSoundToAll("weapons/airstrike_fire_01.wav", ent);
			case 2: EmitSoundToAll("weapons/airstrike_fire_02.wav", ent);
			case 3: EmitSoundToAll("weapons/airstrike_fire_03.wav", ent);
		}
		
		AcceptEntityInput(ent, "FireOnce");
	}
}

stock void ShowHud(client, buttons)
{
	if(GetClientTeam(client) != 1)
	{
		if(g_Champion[client] != 0)
		{
			if(UltimateGage[client] > 100.0)
			{
				UltimateGage[client] = 100.0;
			}
			if(UltimateGage[client] < 0.0)
			{
				UltimateGage[client] = 0.0;
			}
			SetHudTextParams(0.75, 0.89, 0.25, 255, 255, 255, 255);
			if(UltimateGage[client] < 100.0)
			{
				new String:sUlt[256];
				ChangeFloatValueToString(client, UltimateGage[client], sUlt);
				ShowHudText(client, 4, "궁극기 상태: %s%", sUlt);
			} else {
				if(g_Champion[client] == 2)
				{
					ShowHudText(client, 4, "궁극기 상태: 설정: 탱크", UltimateGage[client]);
				}
				if(g_Champion[client] == 3)
				{
					ShowHudText(client, 4, "궁극기 상태: PULSE BOMB", UltimateGage[client]);
				}
				if(g_Champion[client] == 4)
				{
					ShowHudText(client, 4, "궁극기 상태: 자동 조준경", UltimateGage[client]);
				}
				if(g_Champion[client] == 5)
				{
					ShowHudText(client, 4, "궁극기 상태: 황야의 무법자", UltimateGage[client]);
				}
				if(g_Champion[client] == 7)
				{
					ShowHudText(client, 4, "궁극기 상태: 뱅뱅뱅", UltimateGage[client]);
				}
				if(g_Champion[client] == 8)
				{
					ShowHudText(client, 4, "궁극기 상태: 포화", UltimateGage[client]);
				}
			}
		}
		if(g_Champion[client] == 1)
		{
			if(!g_ReinShield[client])
			{
				if(g_ReinShieldHealth[client] > 1000)
				{
					SetHudTextParams(0.25, 0.89, 0.25, 86, 227, 0, 255);
				} else if(1000 >= g_ReinShieldHealth[client] >= 550) {
					SetHudTextParams(0.25, 0.89, 0.25, 223, 227, 0, 255);
				} else if(550 > g_ReinShieldHealth[client]) {
					SetHudTextParams(0.25, 0.89, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 3, "방벽체력: %d", g_ReinShieldHealth[client]);
			} else {
				if(g_ReinShieldHealth[client] > 1000)
				{
					SetHudTextParams(-1.0, -1.0, 0.25, 86, 227, 0, 255);
				} else if(1000 > g_ReinShieldHealth[client] >= 550) {
					SetHudTextParams(-1.0, -1.0, 0.25, 223, 227, 0, 255);
				} else if(550 > g_ReinShieldHealth[client]) {
					SetHudTextParams(-1.0, -1.0, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 3, "방벽\n=========\n|  %d   |\n=========", g_ReinShieldHealth[client]);
			}
			if(g_ReinShieldHealth[client] < 0)
			{
				g_ReinShieldHealth[client] = 0;
			}
		}
		if(g_Champion[client] == 2)
		{
			if(g_BasUltimate[client] == 1)
			{
				if(GetGameTime() < g_BasUltimateCooldown[client]) 
				{
					new Float:cooldown =  g_BasUltimateCooldown[client] - GetGameTime();
					if(cooldown > 5.0)
					{
						SetHudTextParams(0.55, -1.0, 0.25, 86, 227, 0, 255);
					} else if(5.0 >= cooldown >= 3.0) {
						SetHudTextParams(0.55, -1.0, 0.25, 223, 227, 0, 255);
					} else if(3.0 > cooldown) {
						SetHudTextParams(0.55, -1.0, 0.25, 227, 0, 0, 255);
					}
					new String:scool[256];
					ChangeFloatValueToString(client, cooldown, scool);
					ShowHudText(client, 6, "궁극기: %s초", scool);
				}
			}
			if(g_OnBasHeal[client] && g_AllowBasHeal[client])
			{
				SetHudTextParams(-1.0, -1.0, 0.25, 255, 255, 255, 255)
				ShowHudText(client, 2, "체력 회복 중...");
			}
		}
		if(g_Champion[client] == 3)
		{
			SetHudTextParams(0.3, 0.85, 0.25, 255, 255, 255, 255);
			ShowHudText(client, 1, "점멸: %d", g_TracerFlash[client]);
			if(g_flRewind[client] - GetGameTime() > 0.0)
			{
				new Float:cooldown = g_flRewind[client] - GetGameTime();
				new String:sCool[256];
				ChangeFloatValueToString(client, cooldown, sCool);
				if(cooldown > 15.0)
				{
					SetHudTextParams(0.3, 0.89, 0.25, 86, 227, 0, 255);
				} else if(15.0 >= cooldown >= 8.0) {
					SetHudTextParams(0.3, 0.89, 0.25, 223, 227, 0, 255);
				} else if(8.0 > cooldown) {
					SetHudTextParams(0.3, 0.89, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 3, "시간역행: %s초", sCool);
			} else {
				SetHudTextParams(0.3, 0.89, 0.25, 255, 255, 255, 255);
				ShowHudText(client, 3, "시간역행: 준비됨");
			}
		}
		if(g_Champion[client] == 4)
		{
			if((g_SoldierMissleCool[client] - GetGameTime()) > 0.0)
			{
				new Float:cooldown = g_SoldierMissleCool[client] - GetGameTime();
				new String:sCool[256];
				ChangeFloatValueToString(client, cooldown, sCool);
				if(cooldown > 5.0)
				{
					SetHudTextParams(0.7, 0.85, 0.25, 86, 227, 0, 255);
				} else if(5.0 >= cooldown >= 2.0) {
					SetHudTextParams(0.7, 0.85, 0.25, 223, 227, 0, 255);
				} else if(2.0 > cooldown) {
					SetHudTextParams(0.7, 0.85, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 3, "나선 로켓: %s", sCool);
			} else {
				SetHudTextParams(0.7, 0.85, 0.25, 255, 255, 255, 255);
				ShowHudText(client, 3, "나선 로켓: 준비됨");
			}
			if(!g_OnSoldUlti[client])
			{
				if(g_SoldierDash[client])
				{
					SetHudTextParams(0.3, 0.85, 0.25, 255, 255, 255, 255);
					ShowHudText(client, 1, "전투태세: 활성화");
				} else {
					SetHudTextParams(0.3, 0.85, 0.25, 255, 255, 255, 255);
					ShowHudText(client, 1, "전투태세: 비활성화");
				}
			}
			if(g_flSoldHeal[client] - GetGameTime() > 0.0)
			{
				new Float:cooldown = g_flSoldHeal[client] - GetGameTime();
				new String:sCool[256];
				ChangeFloatValueToString(client, cooldown, sCool);
				if(cooldown > 20.0)
				{
					SetHudTextParams(0.3, 0.89, 0.25, 86, 227, 0, 255);
				} else if(20.0 >= cooldown >= 8.0) {
					SetHudTextParams(0.3, 0.89, 0.25, 223, 227, 0, 255);
				} else if(8.0 > cooldown) {
					SetHudTextParams(0.3, 0.89, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 2, "생체장: %s초", sCool);
			} else {
				SetHudTextParams(0.3, 0.89, 0.25, 255, 255, 255, 255);
				ShowHudText(client, 2, "생체장: 준비됨");
			}
		}
		if(g_Champion[client] == 5)
		{
			if(!g_OnMcCreeUlt[client])
			{
				if(g_McCreeCool[client] - GetGameTime() > 0.0)
				{
					new Float:cooldown = g_McCreeCool[client] - GetGameTime();
					new String:sCool[256];
					ChangeFloatValueToString(client, cooldown, sCool);
					if(cooldown > 7.5)
					{
						SetHudTextParams(0.3, 0.85, 0.25, 86, 227, 0, 255);
					} else if(7.5 >= cooldown >= 4.5) {
						SetHudTextParams(0.3, 0.85, 0.25, 223, 227, 0, 255);
					} else if(4.5 > cooldown) {
						SetHudTextParams(0.3, 0.85, 0.25, 227, 0, 0, 255);
					}
					ShowHudText(client, 1, "구르기: %s초", sCool);
				} else {
					SetHudTextParams(0.3, 0.85, 0.25, 255, 255, 255, 255);
					ShowHudText(client, 1, "구르기: 준비됨");
				}
				if(g_McCreeFlashCool[client] - GetGameTime() > 0.0)
				{
					new Float:cooldown = g_McCreeFlashCool[client] - GetGameTime();
					new String:sCool[256];
					ChangeFloatValueToString(client, cooldown, sCool);
					if(cooldown > 12.0)
					{
						SetHudTextParams(0.3, 0.89, 0.25, 86, 227, 0, 255);
					} else if(12.0 >= cooldown >= 5.5) {
						SetHudTextParams(0.3, 0.89, 0.25, 223, 227, 0, 255);
					} else if(5.5 > cooldown) {
						SetHudTextParams(0.3, 0.89, 0.25, 227, 0, 0, 255);
					}
					ShowHudText(client, 2, "섬광탄: %s초", sCool);
				} else {
					SetHudTextParams(0.3, 0.89, 0.25, 255, 255, 255, 255);
					ShowHudText(client, 2, "섬광탄: 준비됨");
				}
			} else {
				new Float:cooldown = g_McCreeUltCool[client] - GetGameTime();
				new String:sCool[256];
				ChangeFloatValueToString(client, cooldown, sCool);
				if(cooldown > 4.0)
				{
					SetHudTextParams(0.55, -1.0, 0.25, 86, 227, 0, 255);
				} else if(4.0 >= cooldown >= 2.5) {
					SetHudTextParams(0.55, -1.0, 0.25, 223, 227, 0, 255);
				} else if(2.5 > cooldown) {
					SetHudTextParams(0.55, -1.0, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 1, "황야의 무법자: %s초", sCool);
				new String:iName[256];
				for(new i=1; i<=MaxClients; i++)
				{
					if(g_InMcCreeUltView[client][i])
					{
						new String:m[256];
						GetClientName(i, m, sizeof(m));
						new health = GetClientHealth(i);
						new ihealth = health - g_McCreeSightDamage[client][i];
						new ii = ihealth * 100 / health;
						if(ii < 0)
						{
							Format(iName, sizeof(iName), "%s\n%s: 100%", iName, m);
						} else {
							Format(iName, sizeof(iName), "%s\n%s: %d%", iName, m, ii);
						}
					}
				}
				Format(iName, sizeof(iName), "________Target________%s", iName);
				SetHudTextParams(0.55, -1.0, 0.25, 86, 227, 0, 255);
				ShowHudText(client, 1, "%s", iName);
			}
		}
		if(g_Champion[client] == 6)
		{
			if(g_AnaBombCool[client] - GetGameTime() > 0.0)
			{
				new Float:cooldown = g_AnaBombCool[client] - GetGameTime();
				new String:sCool[256];
				ChangeFloatValueToString(client, cooldown, sCool);
				if(cooldown > 15.5)
				{
					SetHudTextParams(0.3, 0.89, 0.25, 86, 227, 0, 255);
				} else if(15.5 >= cooldown >= 10.5) {
					SetHudTextParams(0.3, 0.89, 0.25, 223, 227, 0, 255);
				} else if(10.5 > cooldown) {
					SetHudTextParams(0.3, 0.89, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 2, "생체 수류탄: %s초", sCool);
			} else {
				SetHudTextParams(0.3, 0.89, 0.25, 255, 255, 255, 255);
				ShowHudText(client, 2, "생체 수류탄: 준비됨");
			}
			if(g_AnaNeedleGun[client] - GetGameTime() > 0.0)
			{
				new Float:cooldown = g_AnaNeedleGun[client] - GetGameTime();
				new String:sCool[256];
				ChangeFloatValueToString(client, cooldown, sCool);
				if(cooldown > 7.5)
				{
					SetHudTextParams(0.3, 0.85, 0.25, 86, 227, 0, 255);
				} else if(7.5 >= cooldown >= 4.5) {
					SetHudTextParams(0.3, 0.85, 0.25, 223, 227, 0, 255);
				} else if(4.5 > cooldown) {
					SetHudTextParams(0.3, 0.85, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 1, "수면총: %s초", sCool);
			} else {
				SetHudTextParams(0.3, 0.85, 0.25, 255, 255, 255, 255);
				ShowHudText(client, 1, "수면총: 준비됨");
			}
		}
		if(g_Champion[client] == 7)
		{
			if(g_RoadHealCool[client] - GetGameTime() > 0.0)
			{
				new Float:cooldown = g_RoadHealCool[client] - GetGameTime();
				new String:sCool[256];
				ChangeFloatValueToString(client, cooldown, sCool);
				if(cooldown > 15.0)
				{
					SetHudTextParams(0.3, 0.89, 0.25, 86, 227, 0, 255);
				} else if(15.0 >= cooldown >= 8.0) {
					SetHudTextParams(0.3, 0.89, 0.25, 223, 227, 0, 255);
				} else if(8.0 > cooldown) {
					SetHudTextParams(0.3, 0.89, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 2, "핰핰: %s초", sCool);
			} else {
				SetHudTextParams(0.3, 0.89, 0.25, 255, 255, 255, 255);
				ShowHudText(client, 2, "핰핰: 준비됨");
			}
			if(g_RoadUltcool[client] - GetGameTime() > 0.0)
			{
				new Float:cooldown = g_RoadUltcool[client] - GetGameTime();
				new String:sCool[256];
				ChangeFloatValueToString(client, cooldown, sCool);
				if(cooldown > 5.5)
				{
					SetHudTextParams(0.55, -1.0, 0.25, 86, 227, 0, 255);
				} else if(5.5 >= cooldown >= 3.5) {
					SetHudTextParams(0.55, -1.0, 0.25, 223, 227, 0, 255);
				} else if(3.5 > cooldown) {
					SetHudTextParams(0.55, -1.0, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 3, "구구구: %s", sCool);
			}
		}
		if(g_Champion[client] == 8)
		{
			if(g_ParahDisplayBoost[client] || g_ParahAllowCharge[client])
			{
				new Float:cooldown = g_ParahBoostGage[client];
				new String:sCool[256];
				ChangeFloatValueToString(client, cooldown, sCool);
				if(cooldown > 70.0)
				{
					SetHudTextParams(0.55, -1.0, 0.25, 86, 227, 0, 255);
				} else if(70.0 >= cooldown >= 45.0) {
					SetHudTextParams(0.55, -1.0, 0.25, 223, 227, 0, 255);
				} else if(45.0 > cooldown) {
					SetHudTextParams(0.55, -1.0, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 5, "제트팩: %s%", sCool);
			}
			if(g_ParahJetPack[client] - GetGameTime() > 0.0)
			{
				new Float:cooldown = g_ParahJetPack[client] - GetGameTime();
				new String:sCool[256];
				ChangeFloatValueToString(client, cooldown, sCool);
				if(cooldown > 15.0)
				{
					SetHudTextParams(0.3, 0.85, 0.25, 86, 227, 0, 255);
				} else if(15.0 >= cooldown >= 8.0) {
					SetHudTextParams(0.3, 0.85, 0.25, 223, 227, 0, 255);
				} else if(8.0 > cooldown) {
					SetHudTextParams(0.3, 0.85, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 1, "수직상승: %s초", sCool);
			} else {
				SetHudTextParams(0.3, 0.85, 0.25, 255, 255, 255, 255);
				ShowHudText(client, 1, "수직상승: 준비됨");
			}
			if(g_ParahSeconadry[client] - GetGameTime() > 0.0)
			{
				new Float:cooldown = g_ParahSeconadry[client] - GetGameTime();
				new String:sCool[256];
				ChangeFloatValueToString(client, cooldown, sCool);
				if(cooldown > 15.0)
				{
					SetHudTextParams(0.3, 0.89, 0.25, 86, 227, 0, 255);
				} else if(15.0 >= cooldown >= 8.0) {
					SetHudTextParams(0.3, 0.89, 0.25, 223, 227, 0, 255);
				} else if(8.0 > cooldown) {
					SetHudTextParams(0.3, 0.89, 0.25, 227, 0, 0, 255);
				}
				ShowHudText(client, 2, "두둥탁 폭탄: %s초", sCool);
			} else {
				SetHudTextParams(0.3, 0.89, 0.25, 255, 255, 255, 255);
				ShowHudText(client, 2, "두둥탁 폭탄: 준비됨");
			}
		}
		if(g_Champion[client] == 9)
		{
			if(g_MercyHealType[client] == 0)
			{
				SetHudTextParams(0.3, 0.85, 0.25, 255, 255, 255, 255);
				ShowHudText(client, 1, "힐 타입: 비활성화");
			} else if(g_MercyHealType[client] == 1) {
				SetHudTextParams(0.3, 0.85, 0.25, 255, 255, 255, 255);
				ShowHudText(client, 1, "힐 타입: 치유");
			} else {
				SetHudTextParams(0.3, 0.85, 0.25, 255, 255, 255, 255);
				ShowHudText(client, 1, "힐 타입: 공격력");
			}
		}
	}
}

stock bool:ClientViews(Viewer, Target, Float:fMaxDistance=0.0, Float:fThreshold=0.73)
{
    decl Float:fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
    decl Float:fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
    decl Float:fViewDir[3];
    decl Float:fTargetPos[3]; GetClientEyePosition(Target, fTargetPos);
    decl Float:fTargetDir[3];
    decl Float:fDistance[3];
    
    fViewAng[0] = fViewAng[2] = 0.0;
    GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
    
    fDistance[0] = fTargetPos[0]-fViewPos[0];
    fDistance[1] = fTargetPos[1]-fViewPos[1];
    fDistance[2] = 0.0;
    if (fMaxDistance != 0.0)
    {
        if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) >= (fMaxDistance*fMaxDistance))
            return false;
    }

    NormalizeVector(fDistance, fTargetDir);
    if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;
    
    new Handle:hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    if (TR_DidHit(hTrace))
	{
		CloseHandle(hTrace); 
		return false; 
	}
    CloseHandle(hTrace);
    
    return true;
}

// ----------------------------------------------------------------------------
// ClientViewsFilter()
// ----------------------------------------------------------------------------
public bool:ClientViewsFilter(Entity, Mask, any:Junk)
{
    if (Entity >= 1 && Entity <= MaxClients) 
	{
		return false;
	}
    return true;
}

public Action:Rein_StartTouch(int entity, int other)
{
}

stock ResetAll(client)
{
	
}

stock TF2_GetHealingTarget(client)
{
    new String:classname[64];
    TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));

    if(StrEqual(classname, "CWeaponMedigun"))
    {
        new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if(GetEntProp(index, Prop_Send, "m_bHealing") == 1)
        {
            return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
        }
    }
    return -1;
}

stock GetClosestPlayerByClientAngle(int client, float angdistance = 80.0, float posdistance = 120.0, int sameteam = 1)
{
	new Float:AngDiff[MAXPLAYERS+1];
	new Float:LowDiff[1], LowPlayer = -1;
	LowDiff[0] = -1.0;
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsPlayerAlive(client) && IsPlayerAlive(i))
		{
			new Float:pos[3], Float:ipos[3], Float:opt[3], Float:posang[3], Float:ang[3], Float:Diff[1];
			GetClientAbsOrigin(client, pos);
			GetClientAbsOrigin(i, ipos);
			MakeVectorFromPoints(pos, ipos, opt);
			GetVectorAngles(opt, posang);
			GetClientEyeAngles(client, ang);
			Diff[0] = AngleDifference(posang[0], ang[0]);
			if(SetHitBoxAndTest(pos, i, posdistance) && Diff[0] < angdistance)
			{
				if(sameteam == 0)
				{
					if(GetClientTeam(i) != GetClientTeam(client))
					{
						AngDiff[i] = AngleDifference(posang[0], ang[0]);
					}
				} else if(sameteam == 1) {
					if(GetClientTeam(i) == GetClientTeam(client))
					{
						AngDiff[i] = AngleDifference(posang[0], ang[0]);
					}
				} else {
					AngDiff[i] = AngleDifference(posang[0], ang[0]);
				}
			} else {
				return -1;
			}
		}
	}
	
	for(new j=1; j<=MaxClients; j++)
	{
		if(LowDiff[0] == -1.0 && LowPlayer == -1)
		{
			LowDiff[0] = AngDiff[j];
			LowPlayer = j;
		} else {
			if(LowDiff[0] > AngDiff[j])
			{
				LowDiff[0] = AngDiff[j];
				LowPlayer = j;
			}
		}
	}
	
	return LowPlayer;
}

stock Float:AngleDifference(Float:fFirst, Float:fSecond)
{
	new Float:fDifference = fSecond - fFirst;
	while (fDifference < -180) fDifference += 360;
	while (fDifference > 180) fDifference -= 360;
	return fDifference;
}

public Action:Parah_StartTouch(int entity, other)
{
	new Float:pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	for(new i=1; i<=MaxClients; i++)
	{
		if(PlayerCheck(i) && IsPlayerAlive(i) && SetHitBoxAndTest(pos, i, 700.0) && GetClientTeam(client) == GetClientTeam(i))
		{
			new Float:ipos[3];
			GetClientAbsOrigin(i, ipos);
			pos[0] = FloatAbs(pos[0]);
			pos[1] = FloatAbs(pos[1]);
			pos[2] = FloatAbs(pos[2]);
			ipos[0] = FloatAbs(ipos[0]);
			ipos[1] = FloatAbs(ipos[1]);
			ipos[2] = FloatAbs(ipos[2]);
			pos[0] = 0.0;
			pos[1] = 0.0;
			pos[2] = 0.0;
			ipos[0] -= pos[0];
			ipos[1] -= pos[1];
			ipos[2] -= pos[2];
			decl Float:ves[3];
			ves[0] = 800 / ipos[0];
			ves[1] = 800 / ipos[1];
			ves[2] = 300 / ipos[2];
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, ves);
			if(g_Champion[i] == 7)
			{
				g_AllowBoost[i] = false;
				CreateTimer(1.5, Parah_AllowBoost, i);
			}
		}
	}
}

public Action:Parah_AllowBoost(Handle:timer, any:client)
{
	g_AllowBoost[client] = true;
}

public Action:Bastion_TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(g_Champion[victim] == 2)
	{
		g_OnBasHeal[victim] = false;
	}
}