#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#define PL_VERSION "1.0"
new g_health[MAXPLAYERS+1];
new g_kills[MAXPLAYERS+1];
new maxkills;
new minkills;
new g_assists[MAXPLAYERS+1];
new maxassists;
new g_deaths[MAXPLAYERS+1];
new maxdeaths;
new g_suicides[MAXPLAYERS+1];
new maxsuicides;
new g_damage[MAXPLAYERS+1];
new g_airdamage[MAXPLAYERS+1];
new maxdamage;
new maxairdamage;
new bestshot;
new bestshooter;
new g_shots[MAXPLAYERS+1];
new g_hits[MAXPLAYERS+1];
new Float:g_lastshot[MAXPLAYERS+1];
new maxacc;
new minacc;
new g_medikits[MAXPLAYERS+1];
new maxmed;
new g_ammopacks[MAXPLAYERS+1];
new maxammo;
new g_dist[MAXPLAYERS+1];
new g_grdist[MAXPLAYERS+1];
new g_airdist[MAXPLAYERS+1];
new Float:g_oldpos[MAXPLAYERS+1][3];
new maxdist;
new mindist;
new maxgrdist;
new maxairdist;
new bool:roundend = false;
new g_condOffset;
public Plugin:myinfo =
{
	name = "Round Stats",
	author = "MikeJS",
	description = "Stats and awards.",
	version = PL_VERSION,
	url = "http://mikejs.byethost18.com/"
};
public OnPluginStart() {
	g_condOffset = FindSendPropInfo("CTFPlayer", "m_nPlayerCond");
	CreateConVar("sm_rstats_version", PL_VERSION, "Round Stats version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_death", Event_player_death);
	HookEvent("player_hurt", Event_player_hurt);
	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("teamplay_round_start", Event_round_start);
	HookEvent("teamplay_restart_round", Event_round_start);
	HookEvent("teamplay_round_win", Event_round_win);
	HookEntityOutput("item_healthkit_small", "OnPlayerTouch", EntityOutput_medikit);
	HookEntityOutput("item_healthkit_medium", "OnPlayerTouch", EntityOutput_medikit);
	HookEntityOutput("item_healthkit_full", "OnPlayerTouch", EntityOutput_medikit);
	HookEntityOutput("item_ammopack_small", "OnPlayerTouch", EntityOutput_ammopack);
	HookEntityOutput("item_ammopack_medium", "OnPlayerTouch", EntityOutput_ammopack);
	HookEntityOutput("item_ammopack_full", "OnPlayerTouch", EntityOutput_ammopack);
	HookEntityOutput("prop_dynamic", "OnAnimationBegun", EntityOutput_propdyna);
}
public OnClientPutInServer(client) {
	g_kills[client] = 0;
	g_assists[client] = 0;
	g_deaths[client] = 0;
	g_suicides[client] = 0;
	g_damage[client] = 0;
	g_airdamage[client] = 0;
	g_shots[client] = 0;
	g_hits[client] = 0;
}
public OnGameFrame() {
	if(!roundend) {
		for(new i=1;i<=MaxClients;i++) {
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)>1) {
				new cond = GetEntData(i, g_condOffset);
				if(cond & 8192 || cond & 32768 || TF2_GetPlayerClass(i)==TFClass_Medic) {
					g_health[i] = GetClientHealth(i);
				}
				decl Float:vecPos[3];
				GetClientAbsOrigin(i, vecPos);
				new dist = RoundFloat(GetVectorDistance(vecPos, g_oldpos[i]));
				g_dist[i] += dist;
				if(GetEntityFlags(i) & FL_ONGROUND) {
					g_grdist[i] += dist;
				} else {
					g_airdist[i] += dist;
				}
				g_oldpos[i][0] = vecPos[0];
				g_oldpos[i][1] = vecPos[1];
				g_oldpos[i][2] = vecPos[2];
			}
		}
	}
}
public EntityOutput_medikit(const String:output[], caller, activator, Float:delay) {
	g_health[activator] = GetClientHealth(activator);
	g_medikits[activator]++;
}
public EntityOutput_ammopack(const String:output[], caller, activator, Float:delay) {
	g_ammopacks[activator]++;
}
public EntityOutput_propdyna(const String:output[], caller, activator, Float:delay) {
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i) && !IsClientObserver(i)) {
			g_health[i] = GetClientHealth(i);
		}
	}
}
public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!roundend) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(client==attacker) {
			g_suicides[client]++;
		} else {
			new assister = GetClientOfUserId(GetEventInt(event, "assister"));
			g_kills[attacker]++;
			if(assister) {
				g_assists[assister]++;
			}
			g_deaths[client]++;
		}
	}
}
public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!roundend) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new health = GetEventInt(event, "health");
		new damage = g_health[client]-health;
		g_damage[attacker] += damage;
		if(!(GetEntityFlags(attacker) & FL_ONGROUND)) {
			g_airdamage[attacker] += damage;
		}
		g_health[client] = health;
		if(damage>bestshot) {
			bestshot = damage;
			bestshooter = attacker;
		}
		if(client!=attacker) {
			new Float:gametime = GetGameTime();
			if(g_lastshot[attacker]!=gametime) {
				g_hits[attacker]++;
				g_lastshot[attacker] = gametime;
			}
		}
	}
}
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!roundend) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		GetClientAbsOrigin(client, g_oldpos[client]);
		CreateTimer(0.01, Timer_SaveHealth, client);
	}
}
public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	roundend = false;
	g_kills[0] = g_assists[0] = g_deaths[0] = g_suicides[0] = g_damage[0] = g_airdamage[0] = g_shots[0] = g_hits[0] = g_medikits[0] = g_ammopacks[0] = g_dist[0] = g_grdist[0] = g_airdist[0] = bestshot = bestshooter -1;
	for(new i=1;i<=MaxClients;i++) {
		g_kills[i] = g_assists[i] = g_deaths[i] = g_suicides[i] = g_damage[i] = g_airdamage[i] = g_shots[i] = g_hits[i] = g_medikits[i] = g_ammopacks[i] = g_dist[i] = g_grdist[i] = g_airdist[i] = 0;
	}
}
public Action:Event_round_win(Handle:event, const String:name[], bool:dontBroadcast) {
	decl String:buffer[64];
	roundend = true;
	maxkills = minkills = maxassists = maxdeaths = maxsuicides = maxdamage = maxairdamage = maxacc = minacc = maxmed = maxammo = maxdist = mindist = maxgrdist = maxairdist = 0;
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i)) {
			if(g_kills[i]>g_kills[maxkills]) { maxkills = i; }
			if(g_kills[i]<g_kills[minkills]) { minkills = i; }
			if(g_assists[i]>g_assists[maxassists]) { maxassists = i; }
			if(g_deaths[i]>g_deaths[maxdeaths]) { maxdeaths = i; }
			if(g_suicides[i]>g_suicides[maxsuicides]) { maxsuicides = i; }
			if(g_damage[i]>g_damage[maxdamage]) { maxdamage = i; }
			if(g_airdamage[i]>g_airdamage[maxairdamage]) { maxairdamage = i; }
			if(g_shots[i]>0 && g_hits[i]>0) {
				if(maxacc==0) {
					maxacc = i;
				} else if(float(g_hits[i])/float(g_shots[i])*100.0>(float(g_hits[maxacc])/float(g_shots[maxacc]))*100.0) {
					maxacc = i;
				}
				if(minacc==0) {
					minacc = i;
				} else if((float(g_hits[i])/float(g_shots[i]))*100.0<(float(g_hits[minacc])/float(g_shots[minacc]))*100.0) {
					minacc = i;
				}
			}
			if(g_medikits[i]>g_medikits[maxmed]) { maxmed = i; }
			if(g_ammopacks[i]>g_ammopacks[maxammo]) { maxammo = i; }
			if(g_dist[i]>g_dist[maxdist]) { maxdist = i; }
			if(g_dist[i]<g_dist[mindist]) { mindist = i; }
			if(g_grdist[i]>g_grdist[maxgrdist]) { maxgrdist = i; }
			if(g_airdist[i]>g_airdist[maxairdist]) { maxairdist = i; }
			new Handle:panel = CreatePanel();
			SetPanelTitle(panel, "Your round stats:");
			Format(buffer, sizeof(buffer), "Kills: %i", g_kills[i]);
			DrawPanelText(panel, buffer);
			Format(buffer, sizeof(buffer), "Assists: %i", g_assists[i]);
			DrawPanelText(panel, buffer);
			Format(buffer, sizeof(buffer), "Deaths: %i", g_deaths[i]);
			DrawPanelText(panel, buffer);
			Format(buffer, sizeof(buffer), "Suicides: %i", g_suicides[i]);
			DrawPanelText(panel, buffer);
			if(g_hits[i]>0&&g_shots[i]>0) {
				Format(buffer, sizeof(buffer), "Accuracy: %.2f%%", float(g_hits[i])/float(g_shots[i])*100);
				DrawPanelText(panel, buffer);
			} else {
				DrawPanelText(panel, "Accuracy: 0%%");
			}
			Format(buffer, sizeof(buffer), "Damage: %i", g_damage[i]);
			DrawPanelText(panel, buffer);
			Format(buffer, sizeof(buffer), "Distance: %i", g_dist[i]);
			DrawPanelText(panel, buffer);
			DrawPanelItem(panel, "Next");
			DrawPanelItem(panel, "Close");
			SendPanelToClient(panel, i, Menu_awards1, MENU_TIME_FOREVER);
			CloseHandle(panel);
		}
	}
	StartPrint(INVALID_HANDLE, 0);
}
public Action:Timer_SaveHealth(Handle:timer, any:client) {
	g_health[client] = GetClientHealth(client);
}
public Action:StartPrint(Handle:timer, any:count) {
	switch(count) {
		case 0: PrintToChatAll("\x01Most lethal: \x04%N\x01 (\x04%i\x01 kills)", maxkills, g_kills[maxkills]);
		case 1: PrintToChatAll("\x01Most peaceful: \x04%N\x01 (\x04%i\x01 kills)", minkills, g_kills[minkills]);
		case 2: PrintToChatAll("\x01Cling on: \x04%N\x01 (\x04%i\x01 assists)", maxassists, g_assists[maxassists]);
		case 3: PrintToChatAll("\x01Most losses: \x04%N\x01 (\x04%i\x01 deaths)", maxdeaths, g_deaths[maxdeaths]);
		case 4: PrintToChatAll("\x01Lemming award: \x04%N\x01 (\x04%i\x01 SDs)", maxsuicides, g_suicides[maxsuicides]);
		case 5: PrintToChatAll("\x01Most damaging: \x04%N\x01 (\x04%i\x01 dmg)", maxdamage, g_damage[maxdamage]);
		case 6: PrintToChatAll("\x01Bird of prey: \x04%N\x01 (\x04%i\x01 air dmg)", maxairdamage, g_airdamage[maxairdamage]);
		case 7: PrintToChatAll("\x01Marksman: \x04%N\x01 (\x04%.2f\x01%% acc)", maxacc, float(g_hits[maxacc])/float(g_shots[maxacc])*100);
		case 8: PrintToChatAll("\x01Pathetic shot: \x04%N\x01 (\x04%.2f\x01%% acc)", minacc, float(g_hits[minacc])/float(g_shots[minacc])*100);
		case 9: PrintToChatAll("\x01Best shot: \x04%N\x01 (\x04%i\x01 dmg)", bestshooter, bestshot);
		case 10: PrintToChatAll("\x01Hypochondriac: \x04%N\x01 (\x04%i\x01 medkits)", maxmed, g_medikits[maxmed]);
		case 11: PrintToChatAll("\x01Hoarder: \x04%N\x01 (\x04%i\x01 ammopacks)", maxammo, g_ammopacks[maxammo]);
		case 12: PrintToChatAll("\x01Cartographer: \x04%N\x01 (\x04%i\x01 units)", maxdist, g_dist[maxdist]);
		case 13: PrintToChatAll("\x01Marathon man: \x04%N\x01 (\x04%i\x01 units)", maxgrdist, g_grdist[maxgrdist]);
		case 14: PrintToChatAll("\x01Screaming eagle: \x04%N\x01 (\x04%i\x01 units)", maxairdist, g_airdist[maxairdist]);
		case 15: PrintToChatAll("\x01Screaming sloth: \x04%N\x01 (\x04%i\x01 units)", mindist, g_dist[mindist]);
		default: return;
	}
	CreateTimer(0.9, StartPrint, ++count);
}
public Menu_awards1(Handle:menu, MenuAction:action, param1, param2) {
	if(action==MenuAction_Select) {
		PrintToChatAll("%i", param1);
	}
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result) {
	if(!roundend) {
		g_shots[client]++;
	}
	return Plugin_Continue;
}
/*
Most lethal - most kills
Lackluster - most assists
Most losses - most deaths
Lemming award - most suicides
Most damaging - most damage dealt

Most flammable - most fire damage taken
Most peaceful - least kills
Marksman - highest accuracy
Pathetic shot - lowest accuracy
Hypochondriac - most medikits picked up

Hoarder - most ammo crates picked up
Cartographer - longest distance travelled
Marathon man - longest distance travelled by foot
Screaming eagle - longest distance travelled in air
Screaming sloth - lowest distance travelled

Bully - most dominations
Victim - most dominated
Bag man - most flag caps
Fists of fury - most melee kills
Most dishonourable - most damage from behind

Survivor - most kills with less than 25% health left
Trigger happy - most shots fired
Longest spree - most kills within 5 seconds of each other
Glass jaw - most melee deaths
Brain surgeon - most headshots

Daredevil - most fall damage taken
*/