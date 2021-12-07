#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <dukehacks>
#define PL_VERSION "1.9"
new Handle:g_hJump = INVALID_HANDLE;
new bool:g_bJump = true;
new Handle:g_hDash = INVALID_HANDLE;
new bool:g_bDash = true;
new Handle:g_hGlide = INVALID_HANDLE;
new bool:g_bGlide = true;
new Handle:g_hPower = INVALID_HANDLE;
new Float:g_fPower = 266.67;
new Handle:g_hGlidePower = INVALID_HANDLE;
new Float:g_fGlidePower = 12.5;
new Float:g_fHGlidePower = 4.17;
new Handle:g_hGlideAngle = INVALID_HANDLE;
new g_iGlideAngle = 45;
new Handle:g_hDashPower = INVALID_HANDLE;
new Float:g_fDashPower = 500.0;
new Handle:g_hDashDelay = INVALID_HANDLE;
new Float:g_fDashDelay = 1.5;
new Handle:g_hDashFireDelay = INVALID_HANDLE;
new Float:g_fDashFireDelay = 0.5;
new Handle:g_hSpeed = INVALID_HANDLE;
new bool:g_bSpeed = true;
new Handle:g_hVarBurn = INVALID_HANDLE;
new bool:g_bVarBurn = true;
new Handle:g_hBackCrit = INVALID_HANDLE;
new g_iBackCrit = 75;
new Handle:g_hFireaxe = INVALID_HANDLE;
new bool:g_bFireaxe = true;
new Handle:g_hAmmo = INVALID_HANDLE;
new bool:g_bAmmo = false;
new Handle:g_hBurstAmmo = INVALID_HANDLE;
new g_iBurstAmmo = 25;
new g_iAddAmmo = 0;
new bool:g_bBurstAmmoChanged = false;
new offsAmmo;
new offsNextPrimaryAttack;
new bool:g_bPyro[MAXPLAYERS+1];
new g_iOldAmmo[MAXPLAYERS+1];
new g_iBurn[MAXPLAYERS+1];
new Handle:g_hDashTimers[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:g_hBurnTimers[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new bool:g_bCanDash[MAXPLAYERS+1];
new g_bCanMove = true;
public Plugin:myinfo = 
{
	name = "Pyro++",
	author = "MikeJS",
	description = "Makes pyros more versatile and less of an 'M1+W n0ob' class.",
	version = PL_VERSION,
	url = "http://www.mikejsavage.com/"
};
public OnPluginStart() {
	offsAmmo = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	offsNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	CreateConVar("sm_pyro_version", PL_VERSION, "Pyro++ version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hJump = CreateConVar("sm_pyro_abjump", "1", "Enable/disable airblast jump.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hDash = CreateConVar("sm_pyro_dash", "1", "Enable/disable dashing.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hGlide = CreateConVar("sm_pyro_glide", "1", "Enable/disable gliding.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hPower = CreateConVar("sm_pyro_abpower", "266.67", "Airblast jump strength.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hGlidePower = CreateConVar("sm_pyro_glidepower", "15.0", "Backburner glide strength.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hGlideAngle = CreateConVar("sm_pyro_glideangle", "45", "Angle needed to glide.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hDashPower = CreateConVar("sm_pyro_dashpower", "500.0", "Dash strength.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hDashDelay = CreateConVar("sm_pyro_dashdelay", "1.5", "Delay between dashes.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hDashFireDelay = CreateConVar("sm_pyro_dashfiredelay", "0.5", "Delay before firing after a dash.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hSpeed = CreateConVar("sm_pyro_speed", "1", "Make pyros run at medic speed.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hVarBurn = CreateConVar("sm_pyro_varburn", "1", "Make afterburn duration dependant on damage dealt.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hBackCrit = CreateConVar("sm_pyro_backcrit", "75", "Backburner crit angle.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hFireaxe = CreateConVar("sm_pyro_fireaxe", "1", "Make the fireaxe ignite people.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hAmmo = CreateConVar("sm_pyro_ammo", "0", "Give flamethrower infinite ammo.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hBurstAmmo = FindConVar("tf_flamethrower_burstammo");
	HookEvent("player_changeclass", Event_player_changeclass);
	HookEvent("player_spawn", Event_player_spawn);
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
	dhAddClientHook(CHK_PreThink, PreThinkHook);
	dhAddClientHook(CHK_TakeDamage, TakeDamageHook);
}
public OnMapStart() {
	PrecacheSound("vo/pyro_no01.wav");
	PrecacheSound("player/crit_received1.wav");
	PrecacheSound("player/crit_hit.wav");
	g_bCanMove = true;
}
public OnConfigsExecuted() {
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
	if(g_iBurstAmmo<5) {
		g_iAddAmmo = 5-g_iBurstAmmo;
		g_bBurstAmmoChanged = true;
		SetConVarInt(g_hBurstAmmo, 5);
	} else {
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
public Cvar_burstammo(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iBurstAmmo = GetConVarInt(g_hBurstAmmo);
	if(!g_bBurstAmmoChanged) {
		if(g_iBurstAmmo<5) {
			g_iAddAmmo = 5-g_iBurstAmmo;
			g_bBurstAmmoChanged = true;
			SetConVarInt(g_hBurstAmmo, 5);
		} else {
			g_iAddAmmo = 0;
		}
	} else {
		g_bBurstAmmoChanged = false;
	}
}
public Action:PreThinkHook(client) {
	if(g_bPyro[client] && IsPlayerAlive(client)) {
		new ammo = GetEntData(client, offsAmmo+4, 4);
		if(g_bCanMove) {
			new wpn = GetPlayerWeaponSlot(client, 0);
			if(wpn==-1)
				return Plugin_Continue;
			new buttons = GetEntProp(client, Prop_Data, "m_nButtons");
			if(GetEntProp(wpn, Prop_Send, "m_iEntityQuality")>0) {
				if(g_bGlide && buttons&IN_ATTACK && ammo>0 && !(GetEntityFlags(client)&FL_ONGROUND)) {
					decl String:wpnname[32];
					GetClientWeapon(client, wpnname, sizeof(wpnname));
					new Float:nextattack = GetEntDataFloat(wpn, offsNextPrimaryAttack), Float:time = GetGameTime();
					if(StrEqual(wpnname, "tf_weapon_flamethrower") && time>=(nextattack-0.1)) {
						decl Float:vecAng[3];
						GetClientEyeAngles(client, vecAng);
						if(vecAng[0]<g_iGlideAngle)
							return Plugin_Continue;
						if(time>=nextattack)
							SetEntData(client, offsAmmo+4, --ammo, 4);
						decl Float:vecVel[3];
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVel);
						vecAng[0] *= -1.0;
						vecAng[0] = DegToRad(vecAng[0]);
						vecAng[1] = DegToRad(vecAng[1]);
						vecVel[0] -= g_fHGlidePower*Cosine(vecAng[0])*Cosine(vecAng[1]);
						vecVel[1] -= g_fHGlidePower*Cosine(vecAng[0])*Sine(vecAng[1]);
						if(vecVel[2]-(g_fGlidePower*Sine(vecAng[0]))<0)
							vecVel[2] -= g_fGlidePower*Sine(vecAng[0]);
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVel);
					}
				} else if(g_bDash && buttons&IN_ATTACK2 && g_bCanDash[client]) {
					new flags = GetEntityFlags(client);
					if(flags&FL_ONGROUND && !(flags&FL_DUCKING)) {
						decl Float:vecOrigin[3], Float:vecAng[3], Float:vecVel[3];
						GetClientEyePosition(client, vecOrigin);
						GetClientEyeAngles(client, vecAng);
						if(buttons&IN_FORWARD) {
							if(buttons&IN_MOVELEFT) {
								vecAng[1] += 45.0;
							} else if(buttons&IN_MOVERIGHT) {
								vecAng[1] -= 45.0;
							}
						} else if(buttons&IN_BACK) {
							vecAng[1] += 180.0;
							if(buttons&IN_MOVELEFT) {
								vecAng[1] -= 45.0;
							} else if(buttons&IN_MOVERIGHT) {
								vecAng[1] += 45.0;
							}
						} else if(buttons&IN_MOVELEFT) {
							vecAng[1] += 90.0;
						} else if(buttons&IN_MOVERIGHT) {
							vecAng[1] -= 90.0;
						}
						if(vecAng[1]>360) {
							vecAng[1] -= 360.0;
						} else if(vecAng[1]<0) {
							vecAng[1] += 360.0;
						}
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVel);
						new Float:speed = GetVectorLength(vecVel);
						if(speed<g_fDashPower) speed = g_fDashPower;
						vecAng[0] *= -1.0;
						vecAng[0] = DegToRad(vecAng[0]);
						vecAng[1] = DegToRad(vecAng[1]);
						vecVel[0] = speed*Cosine(vecAng[1]);
						vecVel[1] = speed*Sine(vecAng[1]);
						vecVel[2] = 266.66;
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVel);
						if(g_fDashDelay>0) {
							g_bCanDash[client] = false;
							g_hDashTimers[client] = CreateTimer(g_fDashDelay, AllowDash, client);
						}
						EmitAmbientSound("vo/pyro_no01.wav", vecOrigin, client, SNDLEVEL_RAIDSIREN);
						if(g_fDashFireDelay>0) {
							new ent, Float:time = GetGameTime()+g_fDashFireDelay; 
							for(new i=0;i<=2;i++) {
								ent = GetPlayerWeaponSlot(client, i);
								if(ent!=-1)
									SetEntDataFloat(ent, offsNextPrimaryAttack, time, true);
							}
						}
					}
				}
			} else {
				if(g_bJump && g_iOldAmmo[client]-ammo==g_iBurstAmmo && !(GetEntityFlags(client)&FL_ONGROUND)) {
					decl Float:vecAng[3], Float:vecVel[3];
					GetClientEyeAngles(client, vecAng);
					GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVel);
					vecAng[0] *= -1.0;
					vecAng[0] = DegToRad(vecAng[0]);
					vecAng[1] = DegToRad(vecAng[1]);
					vecVel[0] -= g_fPower*Cosine(vecAng[0])*Cosine(vecAng[1]);
					vecVel[1] -= g_fPower*Cosine(vecAng[0])*Sine(vecAng[1]);
					vecVel[2] -= g_fPower*Sine(vecAng[0]);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVel);
					if(g_iAddAmmo>0) {
						ammo += g_iAddAmmo;
						SetEntData(client, offsAmmo+4, ammo, 4);
					}
				}
			}
			if(g_bSpeed)
				SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 320.0);
		}
		if(g_bAmmo) {
			SetEntData(client, offsAmmo+4, 200, 4);
			g_iOldAmmo[client] = 200;
		} else {
			g_iOldAmmo[client] = ammo;
		}
	}
	return Plugin_Continue;
}
public Action:TakeDamageHook(client, attacker, inflictor, Float:damage, &Float:multiplier, damagetype) {
	if(attacker>0 && attacker<=MaxClients && g_bPyro[attacker]) {
		if(damagetype&DMG_PLASMA) {
			if(g_bVarBurn) {
				new changed = false;
				decl String:wpn[32];
				GetEntityNetClass(inflictor, wpn, sizeof(wpn));
				if(StrEqual(wpn, "CTFProjectile_Flare")) {
					g_iBurn[client] += 10;
					new Handle:pack;
					g_hBurnTimers[client] = CreateDataTimer(10.0, CheckExtinguish, pack);
					WritePackCell(pack, client);
					WritePackCell(pack, g_iBurn[client]);
				} else if(StrEqual(wpn, "CTFFlameThrower")) {
					if(GetEntProp(inflictor, Prop_Send, "m_iEntityQuality")>0 && !(damagetype&DMG_ACID)) {
						decl Float:vecOriginC[3], Float:vecOriginA[3], Float:vecAnglesA[3], Float:vecAnglesC[3];
						GetClientEyePosition(client, vecOriginC);
						GetClientEyePosition(attacker, vecOriginA);
						SubtractVectors(vecOriginC, vecOriginA, vecAnglesA);
						NormalizeVector(vecAnglesA, vecAnglesA);
						GetVectorAngles(vecAnglesA, vecAnglesA);
						GetClientEyeAngles(client, vecAnglesC);
						new Float:angles = FloatAbs(vecAnglesA[1]-vecAnglesC[1]);
						while(angles>360)
							angles -= 360;
						if(angles<=g_iBackCrit || angles>=(360-g_iBackCrit)) {
							EmitSoundToClient(client, "player/crit_received1.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, 95);
							EmitSoundToClient(attacker, "player/crit_hit.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, 85);
							vecOriginC[2] += 5.0;
							new tblidx = FindStringTable("ParticleEffectNames"), count = GetStringTableNumStrings(tblidx), idx = INVALID_STRING_INDEX;
							decl String:tmp[128];
							for(new i=0;i<count;i++) {
								ReadStringTable(tblidx, i, tmp, sizeof(tmp));
								if(StrEqual(tmp, "crit_text", false)) {
									idx = i;
									break;
								}
							}
							if(idx==INVALID_STRING_INDEX) {
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
							multiplier *= 3.0;
							changed = true;
						}
					}
					new Float:time = 10.0;
					g_iBurn[client]++;
					switch(g_iBurn[client]) {
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
					g_hBurnTimers[client] = CreateDataTimer(time, CheckExtinguish, pack);
					WritePackCell(pack, client);
					WritePackCell(pack, g_iBurn[client]);
				}
				if(changed)
					return Plugin_Changed;
			}
		} else if(g_bFireaxe && attacker>0 && !(damagetype&DMG_BURN)) {
			decl String:wpn[32];
			new ent = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			if(ent!=-1) {
				GetEntityNetClass(ent, wpn, sizeof(wpn));
				if(StrEqual(wpn, "CTFFireAxe") && GetEntProp(ent, Prop_Send, "m_iEntityQuality")==0) {
					TF2_IgnitePlayer(client, attacker);
					if(g_bVarBurn) {
						g_iBurn[client] += 10;
						new Handle:pack;
						g_hBurnTimers[client] = CreateDataTimer(10.0, CheckExtinguish, pack);
						WritePackCell(pack, client);
						WritePackCell(pack, g_iBurn[client]);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action:Event_player_changeclass(Handle:event, const String:name[], bool:dontBroadcast) {
	if(GetEventInt(event, "class")==7) {
		g_bPyro[GetClientOfUserId(GetEventInt(event, "userid"))] = true;
	} else {
		g_bPyro[GetClientOfUserId(GetEventInt(event, "userid"))] = false;
	}
}
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(TF2_GetPlayerClass(client)==TFClass_Pyro) {
		g_bPyro[client] = true;
		CreateTimer(0.1, CheckFlares, client);
		if(g_hDashTimers[client]!=INVALID_HANDLE) {
			KillTimer(g_hDashTimers[client]);
			g_hDashTimers[client] = INVALID_HANDLE;
		}
		if(g_hBurnTimers[client]!=INVALID_HANDLE) {
			KillTimer(g_hBurnTimers[client]);
			g_hBurnTimers[client] = INVALID_HANDLE;
			g_iBurn[client] = 0;
		}
		g_bCanDash[client] = true;
	} else {
		g_bPyro[client] = false;
	}
}
public Action:Event_round_active(Handle:event, const String:name[], bool:dontBroadcast) {
	g_bCanMove = true;
}
public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	g_bCanMove = false;
}
public Action:CheckFlares(Handle:timer, any:client) {
	if(IsClientInGame(client) && IsPlayerAlive(client) && g_bPyro[client]) {
		decl String:classname[32], wpn;
		for(new i=0;i<=5;i++) {
			wpn = GetPlayerWeaponSlot(client, i);
			if(wpn!=-1) {
				GetEdictClassname(wpn, classname, sizeof(classname));
				if(StrEqual(classname, "tf_weapon_flaregun"))
					SetEntData(client, offsAmmo+8, 16, 4);
			}
		}
	}
}
public Action:CheckExtinguish(Handle:timer, any:pack) {
	ResetPack(pack);
	new client = ReadPackCell(pack);
	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		if(ReadPackCell(pack)==g_iBurn[client]) {
			new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
			if(cond&131072)
				SetEntProp(client, Prop_Send, "m_nPlayerCond", cond&~131072);
			g_iBurn[client] = 0;
		}
	}
	g_hBurnTimers[client] = INVALID_HANDLE;
}
public Action:AllowDash(Handle:timer, any:client) {
	g_bCanDash[client] = true;
	g_hDashTimers[client] = INVALID_HANDLE;
}