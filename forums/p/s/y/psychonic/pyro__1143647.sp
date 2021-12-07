#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

#define PL_VERSION "2.0"

#define ITEMIDX_FIREAXE       2
#define ITEMIDX_FLAMETHROWER 21
#define ITEMIDX_FLAREGUN     31
#define ITEMIDX_BACKBURNER   40

#if !defined TF_CONDFLAG_ONFIRE
	#define TF_CONDFLAG_ONFIRE (1 << 20)
#endif

new Handle:g_hJump = INVALID_HANDLE;
new Handle:g_hDash = INVALID_HANDLE;
new Handle:g_hGlide = INVALID_HANDLE;
new Handle:g_hPower = INVALID_HANDLE;
new Handle:g_hGlidePower = INVALID_HANDLE;
new Handle:g_hGlideAngle = INVALID_HANDLE;
new Handle:g_hDashPower = INVALID_HANDLE;
new Handle:g_hDashDelay = INVALID_HANDLE;
new Handle:g_hDashFireDelay = INVALID_HANDLE;
new Handle:g_hSpeed = INVALID_HANDLE;
new Handle:g_hVarBurn = INVALID_HANDLE;
new Handle:g_hBackCrit = INVALID_HANDLE;
new Handle:g_hFireaxe = INVALID_HANDLE;
new Handle:g_hAmmo = INVALID_HANDLE;
new Handle:g_hBurstAmmo = INVALID_HANDLE;

new bool:g_bJump = true;
new bool:g_bDash = true;
new bool:g_bGlide = true;
new Float:g_fPower = 266.67;
new Float:g_fGlidePower = 12.5;
new Float:g_fHGlidePower = 4.17;
new g_iGlideAngle = 45;
new Float:g_fDashPower = 500.0;
new Float:g_fDashDelay = 1.5;
new Float:g_fDashFireDelay = 0.5;
new bool:g_bSpeed = true;
new bool:g_bVarBurn = true;
new g_iBackCrit = 75;
new bool:g_bFireaxe = true;
new bool:g_bAmmo = false;
new g_iBurstAmmo = 25;
new g_iAddAmmo = 0;
new bool:g_bBurstAmmoChanged = false;

new offsAmmo = -1;
new offsButtons = -1;
new offsFlags = -1;
new offsActiveWpn = -1;
new offsVelocity = -1;
new offsMaxSpeed = -1;
new offsPlyrCond = -1;
new offsNextPrimaryAttack = -1;
new offsItemIdx = -1;

new bool:g_bPyro[MAXPLAYERS+1];
new bool:g_bAlive[MAXPLAYERS+1];
new bool:g_bIngame[MAXPLAYERS+1];

new g_iOldAmmo[MAXPLAYERS+1];
new g_iBurn[MAXPLAYERS+1];
new Handle:g_hDashTimers[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:g_hBurnTimers[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new bool:g_bCanDash[MAXPLAYERS+1];
new g_bCanMove = true;

public Plugin:myinfo = 
{
	name = "Pyro+++",
	author = "psychonic, MikeJS",
	description = "Makes pyros more versatile and less of an 'M1+W n0ob' class.",
	version = PL_VERSION,
	url = "http://www.mikejsavage.com/"
};

public OnPluginStart()
{
	offsAmmo = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	offsButtons = FindSendPropInfo("CTFPlayer", "m_nButtons");
	offsFlags = FindSendPropInfo("CTFPlayer", "m_fFlags");
	offsActiveWpn = FindSendPropInfo("CTFPlayer", "m_hActiveWeapon");
	offsVelocity = FindSendPropInfo("CTFPlayer", "m_vecVelocity");
	offsMaxSpeed = FindSendPropInfo("CTFPlayer", "m_flMaxspeed");
	offsPlyrCond = FindSendPropInfo("CTFPlayer", "m_nPlayerCond");
	offsNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	offsItemIdx = FindSendPropInfo("CBaseCombatWeapon", "m_iItemDefinitionIndex");
	
	if (offsAmmo == -1 || offsButtons == -1 || offsFlags == -1 || offsActiveWpn == -1 || offsVelocity == -1
		|| offsMaxSpeed == -1 || offsPlyrCond == -1 || offsNextPrimaryAttack == -1 || offsItemIdx == -1
		)
	{
		SetFailState("Failed to lookup ent prop offsets");
	}
	
	CreateConVar("sm_pyro_version", PL_VERSION, "Pyro++ version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hJump = CreateConVar("sm_pyro_abjump", "1", "Enable/disable airblast jump.");
	g_hDash = CreateConVar("sm_pyro_dash", "1", "Enable/disable dashing.");
	g_hGlide = CreateConVar("sm_pyro_glide", "1", "Enable/disable gliding.");
	g_hPower = CreateConVar("sm_pyro_abpower", "266.67", "Airblast jump strength.");
	g_hGlidePower = CreateConVar("sm_pyro_glidepower", "15.0", "Backburner glide strength.");
	g_hGlideAngle = CreateConVar("sm_pyro_glideangle", "45", "Angle needed to glide.");
	g_hDashPower = CreateConVar("sm_pyro_dashpower", "500.0", "Dash strength.");
	g_hDashDelay = CreateConVar("sm_pyro_dashdelay", "1.5", "Delay between dashes.");
	g_hDashFireDelay = CreateConVar("sm_pyro_dashfiredelay", "0.5", "Delay before firing after a dash.");
	g_hSpeed = CreateConVar("sm_pyro_speed", "1", "Make pyros run at medic speed.");
	g_hVarBurn = CreateConVar("sm_pyro_varburn", "1", "Make afterburn duration dependant on damage dealt.");
	g_hBackCrit = CreateConVar("sm_pyro_backcrit", "75", "Backburner crit angle.");
	g_hFireaxe = CreateConVar("sm_pyro_fireaxe", "1", "Make the fireaxe ignite people.");
	g_hAmmo = CreateConVar("sm_pyro_ammo", "0", "Give flamethrower infinite ammo.");
	g_hBurstAmmo = FindConVar("tf_flamethrower_burstammo");
	
	HookEvent("player_changeclass", Event_player_changeclass);
	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("player_team", Event_player_team);
	HookEvent("player_death", Event_player_death);
	HookEvent("teamplay_round_active", Event_round_active);
	HookEvent("teamplay_round_start", Event_round_start);
	HookEvent("teamplay_restart_round", Event_round_start);
	
	HookConVarChange(g_hJump, Cvar_jump);
	HookConVarChange(g_hDash, Cvar_dash);
	HookConVarChange(g_hGlide, Cvar_glide);
	HookConVarChange(g_hPower, Cvar_power);
	HookConVarChange(g_hGlidePower, Cvar_glidepower);
	HookConVarChange(g_hGlideAngle, Cvar_glideangle);
	HookConVarChange(g_hDashPower, Cvar_dashpower);
	HookConVarChange(g_hDashDelay, Cvar_dashdelay);
	HookConVarChange(g_hDashFireDelay, Cvar_dashfiredelay);
	HookConVarChange(g_hSpeed, Cvar_speed);
	HookConVarChange(g_hVarBurn, Cvar_varburn);
	HookConVarChange(g_hBackCrit, Cvar_backcrit);
	HookConVarChange(g_hFireaxe, Cvar_fireaxe);
	HookConVarChange(g_hAmmo, Cvar_ammo);
	HookConVarChange(g_hBurstAmmo, Cvar_burstammo);
	
	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		g_bIngame[i] = true;
		SDKHook(i, SDKHook_PreThink, PreThinkHook);
		SDKHook(i, SDKHook_OnTakeDamage, TakeDamageHook);
	}
}

public OnMapStart()
{
	PrecacheSound("vo/pyro_no01.wav");
	PrecacheSound("player/crit_received1.wav");
	PrecacheSound("player/crit_hit.wav");
	g_bCanMove = true;
}

public OnConfigsExecuted()
{
	g_bJump = GetConVarBool(g_hJump);
	g_bDash = GetConVarBool(g_hDash);
	g_bGlide = GetConVarBool(g_hGlide);
	g_fPower = GetConVarFloat(g_hPower);
	g_fGlidePower = GetConVarFloat(g_hGlidePower);
	g_iGlideAngle = GetConVarInt(g_hGlideAngle);
	g_fHGlidePower = g_fGlidePower/3.0;
	g_fDashPower = GetConVarFloat(g_hDashPower);
	g_fDashDelay = GetConVarFloat(g_hDashDelay);
	g_fDashFireDelay = GetConVarFloat(g_hDashFireDelay);
	g_bAmmo = GetConVarBool(g_hAmmo);
	g_bSpeed = GetConVarBool(g_hSpeed);
	g_bVarBurn = GetConVarBool(g_hVarBurn);
	g_iBackCrit = GetConVarInt(g_hBackCrit);
	g_bFireaxe = GetConVarBool(g_hFireaxe);
	g_iBurstAmmo = GetConVarInt(g_hBurstAmmo);
	if (g_iBurstAmmo < 5)
	{
		g_iAddAmmo = 5 - g_iBurstAmmo;
		g_bBurstAmmoChanged = true;
		SetConVarInt(g_hBurstAmmo, 5);
	}
	else
	{
		g_iAddAmmo = 0;
	}
}
public Cvar_jump(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bJump = GetConVarBool(g_hJump);
}
public Cvar_dash(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bDash = GetConVarBool(g_hDash);
}
public Cvar_glide(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bGlide = GetConVarBool(g_hGlide);
}
public Cvar_power(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fPower = GetConVarFloat(g_hPower);
}
public Cvar_glidepower(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fGlidePower = GetConVarFloat(g_hGlidePower);
	g_fHGlidePower = g_fGlidePower/3.0;
}
public Cvar_glideangle(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iGlideAngle = GetConVarInt(g_hGlideAngle);
}
public Cvar_dashpower(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fDashPower = GetConVarFloat(g_hDashPower);
}
public Cvar_dashdelay(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fDashDelay = GetConVarFloat(g_hDashDelay);
}
public Cvar_dashfiredelay(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fDashFireDelay = GetConVarFloat(g_hDashFireDelay);
}
public Cvar_speed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bSpeed = GetConVarBool(g_hSpeed);
}
public Cvar_varburn(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bVarBurn = GetConVarBool(g_hVarBurn);
}
public Cvar_backcrit(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iBackCrit = GetConVarInt(g_hBackCrit);
}
public Cvar_fireaxe(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bFireaxe = GetConVarBool(g_hFireaxe);
}
public Cvar_ammo(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bAmmo = GetConVarBool(g_hAmmo);
}

public Cvar_burstammo(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iBurstAmmo = GetConVarInt(g_hBurstAmmo);
	if (!g_bBurstAmmoChanged)
	{
		if (g_iBurstAmmo < 5)
		{
			g_iAddAmmo = 5-g_iBurstAmmo;
			g_bBurstAmmoChanged = true;
			SetConVarInt(g_hBurstAmmo, 5);
		}
		else
		{
			g_iAddAmmo = 0;
		}
	}
	else
	{
		g_bBurstAmmoChanged = false;
	}
}

public PreThinkHook(client)
{
	if (!g_bPyro[client] || !g_bAlive[client])
	{
		return;
	}
	
	new ammo = GetEntData(client, offsAmmo+4, 4);
	if (g_bCanMove)
	{
		new wpn = GetPlayerWeaponSlot(client, 0);
		if (wpn == -1)
		{
			return;
		}
		
		new buttons = GetEntData(client, offsButtons);
		if (GetEntData(wpn, offsItemIdx) == ITEMIDX_BACKBURNER)
		{
			if (g_bGlide && ammo > 0 && (buttons & IN_ATTACK) == IN_ATTACK && (GetEntData(client, offsFlags) & FL_ONGROUND) != FL_ONGROUND
				&& GetEntDataEnt2(client, offsActiveWpn) == ITEMIDX_BACKBURNER
				)
			{
				new Float:nextattack = GetEntDataFloat(wpn, offsNextPrimaryAttack);
				new Float:time = GetGameTime();
				if (time >= (nextattack - 0.1))
				{
					decl Float:vecAng[3];
					GetClientEyeAngles(client, vecAng);
					if(vecAng[0]<g_iGlideAngle)
					{
						return;
					}
					if (time >= nextattack)
					{
						SetEntData(client, offsAmmo+4, --ammo, 4);
					}
					decl Float:vecVel[3];
					GetEntDataVector(client, offsVelocity, vecVel);
					vecAng[0] *= -1.0;
					vecAng[0] = DegToRad(vecAng[0]);
					vecAng[1] = DegToRad(vecAng[1]);
					vecVel[0] -= g_fHGlidePower * Cosine(vecAng[0]) * Cosine(vecAng[1]);
					vecVel[1] -= g_fHGlidePower * Cosine(vecAng[0]) * Sine(vecAng[1]);
					if (vecVel[2] - (g_fGlidePower * Sine(vecAng[0])) < 0)
					{
						vecVel[2] -= g_fGlidePower*Sine(vecAng[0]);
					}
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVel);
				}
			}
			else if (g_bDash && (buttons & IN_ATTACK2) == IN_ATTACK2 && g_bCanDash[client])
			{
				new flags = GetEntData(client, offsFlags);
				if ((flags & FL_ONGROUND) == FL_ONGROUND && (flags & FL_DUCKING) != FL_DUCKING)
				{
					decl Float:vecOrigin[3], Float:vecAng[3], Float:vecVel[3];
					GetClientEyePosition(client, vecOrigin);
					GetClientEyeAngles(client, vecAng);
					if ((buttons & IN_FORWARD) == IN_FORWARD)
					{
						if ((buttons & IN_MOVELEFT) == IN_MOVELEFT)
						{
							vecAng[1] += 45.0;
						}
						else if ((buttons & IN_MOVERIGHT) == IN_MOVERIGHT)
						{
							vecAng[1] -= 45.0;
						}
					}
					else if ((buttons & IN_BACK) == IN_BACK)
					{
						vecAng[1] += 180.0;
						if ((buttons & IN_MOVELEFT) == IN_MOVELEFT)
						{
							vecAng[1] -= 45.0;
						}
						else if ((buttons & IN_MOVERIGHT) == IN_MOVERIGHT)
						{
							vecAng[1] += 45.0;
						}
					}
					else if ((buttons & IN_MOVELEFT) == IN_MOVELEFT)
					{
						vecAng[1] += 90.0;
					}
					else if ((buttons & IN_MOVERIGHT) == IN_MOVERIGHT)
					{
						vecAng[1] -= 90.0;
					}
					
					if (vecAng[1] > 360)
					{
						vecAng[1] -= 360.0;
					}
					else if (vecAng[1] < 0)
					{
						vecAng[1] += 360.0;
					}
					
					GetEntDataVector(client, offsVelocity, vecVel);
					new Float:speed = GetVectorLength(vecVel);
					if (speed < g_fDashPower)
					{
						speed = g_fDashPower;
					}
					
					vecAng[0] *= -1.0;
					vecAng[0] = DegToRad(vecAng[0]);
					vecAng[1] = DegToRad(vecAng[1]);
					vecVel[0] = speed * Cosine(vecAng[1]);
					vecVel[1] = speed * Sine(vecAng[1]);
					vecVel[2] = 266.66;
					
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVel);
					if (g_fDashDelay > 0)
					{
						g_bCanDash[client] = false;
						g_hDashTimers[client] = CreateTimer(g_fDashDelay, AllowDash, GetClientUserId(client));
					}
					
					EmitAmbientSound("vo/pyro_no01.wav", vecOrigin, client, SNDLEVEL_RAIDSIREN);
					
					if (g_fDashFireDelay > 0)
					{
						new ent, Float:time = GetGameTime() + g_fDashFireDelay; 
						for (new i = 0; i <= 2; i++)
						{
							ent = GetPlayerWeaponSlot(client, i);
							if (ent == -1)
							{
								continue;
							}
							SetEntDataFloat(ent, offsNextPrimaryAttack, time, true);
						}
					}
				}
			}
		}
		else
		{
			if (g_bJump && (g_iOldAmmo[client] - ammo) == g_iBurstAmmo && (GetEntData(client, offsFlags) & FL_ONGROUND) != FL_ONGROUND)
			{
				decl Float:vecAng[3], Float:vecVel[3];
				GetClientEyeAngles(client, vecAng);
				GetEntDataVector(client, offsVelocity, vecVel);
				vecAng[0] *= -1.0;
				vecAng[0] = DegToRad(vecAng[0]);
				vecAng[1] = DegToRad(vecAng[1]);
				vecVel[0] -= g_fPower * Cosine(vecAng[0]) * Cosine(vecAng[1]);
				vecVel[1] -= g_fPower * Cosine(vecAng[0]) * Sine(vecAng[1]);
				vecVel[2] -= g_fPower * Sine(vecAng[0]);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVel);
				
				if (g_iAddAmmo > 0)
				{
					ammo += g_iAddAmmo;
					SetEntData(client, offsAmmo+4, ammo, 4);
				}
			}
		}
		if (g_bSpeed)
		{
			SetEntDataFloat(client, offsMaxSpeed, 320.0);
		}
	}
	
	if (g_bAmmo)
	{
		SetEntData(client, offsAmmo+4, 200, 4);
		g_iOldAmmo[client] = 200;
	}
	else
	{
		g_iOldAmmo[client] = ammo;
	}
	
	return;
}

public Action:TakeDamageHook(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (attacker == 0 || attacker > MaxClients || !g_bPyro[attacker])
	{
		return Plugin_Continue;
	}
	
	if ((damagetype & DMG_PLASMA) == DMG_PLASMA)
	{
		if (g_bVarBurn && inflictor > 0)
		{
			new changed = false;
			new wpn = -1;
			if (inflictor <= MaxClients)
			{
				wpn = GetEntData(GetEntDataEnt2(inflictor, offsActiveWpn), offsItemIdx);
			}
			else
			{
				wpn = GetEntData(inflictor, offsItemIdx);
			}
			
			if (wpn == ITEMIDX_FLAREGUN)
			{
				g_iBurn[victim] += 10;
				new Handle:pack;
				g_hBurnTimers[victim] = CreateDataTimer(10.0, CheckExtinguish, pack);
				WritePackCell(pack, GetClientUserId(victim));
				WritePackCell(pack, g_iBurn[victim]);
			}
			else if (wpn == ITEMIDX_FLAMETHROWER || wpn == ITEMIDX_BACKBURNER)
			{
				// use item def index
				if (wpn == ITEMIDX_BACKBURNER && (damagetype & DMG_ACID) != DMG_ACID)
				{
					decl Float:vecOriginC[3], Float:vecOriginA[3], Float:vecAnglesA[3], Float:vecAnglesC[3];
					GetClientEyePosition(victim, vecOriginC);
					GetClientEyePosition(attacker, vecOriginA);
					SubtractVectors(vecOriginC, vecOriginA, vecAnglesA);
					NormalizeVector(vecAnglesA, vecAnglesA);
					GetVectorAngles(vecAnglesA, vecAnglesA);
					GetClientEyeAngles(victim, vecAnglesC);
					
					new Float:angles = FloatAbs(vecAnglesA[1]-vecAnglesC[1]);
					if (angles > 360)
					{
						angles -= 360;
					}
					
					if (angles <= g_iBackCrit || angles >= (360-g_iBackCrit))
					{
						EmitSoundToClient(victim, "player/crit_received1.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, 95);
						EmitSoundToClient(attacker, "player/crit_hit.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, 85);
						vecOriginC[2] += 5.0;
						new tblidx = FindStringTable("ParticleEffectNames"), count = GetStringTableNumStrings(tblidx), idx = INVALID_STRING_INDEX;
						decl String:tmp[128];
						for (new i = 0; i < count; i++)
						{
							ReadStringTable(tblidx, i, tmp, sizeof(tmp));
							if (StrEqual(tmp, "crit_text", false))
							{
								idx = i;
								break;
							}
						}
						
						if (idx == INVALID_STRING_INDEX)
						{
							LogError("Could not find crit particle.");
							return Plugin_Handled;
						}
						
						TE_Start("TFParticleEffect");
						TE_WriteFloat("m_vecOrigin[0]", vecOriginC[0]);
						TE_WriteFloat("m_vecOrigin[1]", vecOriginC[1]);
						TE_WriteFloat("m_vecOrigin[2]", vecOriginC[2]);
						TE_WriteVector("m_vecAngles", NULL_VECTOR);
						TE_WriteNum("m_iParticleSystemIndex", idx);
						TE_SendToClient(attacker);
						
						damage *= 3.0;
						changed = true;
					}
				}
				new Float:time = 10.0;
				g_iBurn[victim]++;
				switch(g_iBurn[victim])
				{
					case 1: time = 0.25;
					case 2: time = 0.5;
					case 3: time = 1.0;
					case 4: time = 2.0;
					case 5: time = 3.0;
					case 6: time = 4.0;
					case 7: time = 5.0;
					case 8: time = 6.5;
					case 9: time = 8.0;
					case 10: time = 10.0;
				}
				new Handle:pack;
				WritePackCell(pack, GetClientUserId(victim));
				WritePackCell(pack, g_iBurn[victim]);
				g_hBurnTimers[victim] = CreateDataTimer(time, CheckExtinguish, pack);
			}
			if (changed)
			{
				return Plugin_Changed;
			}
		}
	}
	else if (g_bFireaxe && attacker > 0 && (damagetype & DMG_BURN) != DMG_BURN)
	{
		new ent = GetEntDataEnt2(attacker, offsActiveWpn);
		if (ent == -1)
		{
			return Plugin_Continue;
		}
		
		if (GetEntData(ent, offsItemIdx) != ITEMIDX_FIREAXE)
		{
			return Plugin_Continue;
		}
		
		TF2_IgnitePlayer(victim, attacker);
		if (!g_bVarBurn)
		{
			return Plugin_Continue;
		}
		
		g_iBurn[victim] += 10;
		new Handle:pack;
		WritePackCell(pack, GetClientUserId(victim));
		WritePackCell(pack, g_iBurn[victim]);
		g_hBurnTimers[victim] = CreateDataTimer(10.0, CheckExtinguish, pack);
	}
	return Plugin_Continue;
}

public Event_player_changeclass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (TFClassType:GetEventInt(event, "class") == TFClass_Pyro)
	{
		g_bPyro[GetClientOfUserId(GetEventInt(event, "userid"))] = true;
		return;
	}

	g_bPyro[GetClientOfUserId(GetEventInt(event, "userid"))] = false;
}

public Event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "team") < 2)
	{
		g_bAlive[GetClientOfUserId(GetEventInt(event, "userid"))] = false;
	}
}

public Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if (client > MaxClients || !g_bIngame[client])
	{
		return;
	}
	
	if (TF2_GetPlayerClass(client) != TFClass_Pyro)
	{
		g_bPyro[client] = false;
	}
	
	g_bPyro[client] = true;
	g_bCanDash[client] = true;
	
	CreateTimer(0.1, CheckFlares, userid);
	if (g_hDashTimers[client]!=INVALID_HANDLE)
	{
		KillTimer(g_hDashTimers[client]);
		g_hDashTimers[client] = INVALID_HANDLE;
	}
	
	if (g_hBurnTimers[client]!=INVALID_HANDLE)
	{
		KillTimer(g_hBurnTimers[client]);
		g_hBurnTimers[client] = INVALID_HANDLE;
		g_iBurn[client] = 0;
	}
	
	if (GetClientTeam(client) < 2)
	{
		g_bAlive[client] = false;
		return;
	}
	g_bAlive[client] = true;
}

public Event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= MaxClients)
	{
		g_bAlive[client] = false;
	}
}

public Event_round_active(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bCanMove = true;
}

public Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bCanMove = false;
}

public Action:CheckFlares(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > MaxClients || !g_bPyro[client] || !g_bIngame[client] || !g_bAlive[client])
	{
		return Plugin_Stop;
	}
	
	for (new i = 0; i <= 5; i++)
	{
		new wpn = GetPlayerWeaponSlot(client, i);
		if (wpn == -1)
		{
			continue;
		}
		
		if (GetEntData(wpn, offsItemIdx) != ITEMIDX_FLAREGUN)
		{
			continue;
		}
		
		SetEntData(client, offsAmmo+8, 16, 4);
	}
	return Plugin_Stop;
}

public Action:CheckExtinguish(Handle:timer, any:pack)
{
	ResetPack(pack);
	// should be passing userid
	new client = GetClientOfUserId(ReadPackCell(pack));

	if (client <= MaxClients && g_bIngame[client] && g_bAlive[client]
		&& ReadPackCell(pack) == g_iBurn[client]
		)
	{
		new cond = GetEntData(client, offsPlyrCond);
		if ((cond & TF_CONDFLAG_ONFIRE) == TF_CONDFLAG_ONFIRE)
		{
			SetEntData(client, offsPlyrCond, cond & ~TF_CONDFLAG_ONFIRE);
		}
		g_iBurn[client] = 0;
	}
	g_hBurnTimers[client] = INVALID_HANDLE;
}

public Action:AllowDash(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client <= MaxClients)
	{
		g_bCanDash[client] = true;
		g_hDashTimers[client] = INVALID_HANDLE;
	}	
}

public OnClientPutInServer(client)
{
	g_bIngame[client] = true;
	SDKHook(client, SDKHook_PreThink, PreThinkHook);
	SDKHook(client, SDKHook_OnTakeDamage, TakeDamageHook);
}

public OnClientDisconnect(client)
{
	g_bIngame[client] = false;
	
	if (g_hDashTimers[client]!=INVALID_HANDLE)
	{
		KillTimer(g_hDashTimers[client]);
		g_hDashTimers[client] = INVALID_HANDLE;
	}
	
	if (g_hBurnTimers[client]!=INVALID_HANDLE)
	{
		KillTimer(g_hBurnTimers[client]);
		g_hBurnTimers[client] = INVALID_HANDLE;
		g_iBurn[client] = 0;
	}
}