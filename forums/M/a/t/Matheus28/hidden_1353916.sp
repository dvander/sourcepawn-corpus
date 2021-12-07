#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "2.0"
#define PLUGIN_PREFIX "\x04[The Hidden]\x01"

#define TICK_INTERVAL 0.1

#define HIDDEN_OVERLAY "effects/combine_binocoverlay"
#define HIDDEN_COLOR {0, 0, 0, 3}

#define HIDDEN_HP 500
#define HIDDEN_HP_PER_PLAYER 50
#define HIDDEN_HP_PER_KILL 75


#define HIDDEN_INVISIBILITY_TIME 100.0
#define HIDDEN_STAMINA_TIME 7.5

#define HIDDEN_BOO
#define HIDDEN_BOO_TIME 20.0
#define HIDDEN_BOO_DURATION 3.5
#define HIDDEN_BOO_VISIBLE 1.5
#define HIDDEN_JUMP_TIME 0.5
#define HIDDEN_AWAY_TIME 15.0

#define HIDDEN_BOO_FILE "vo/taunts/spy_taunts06.wav"

#define ROUND_TIME 60
#define ROUND_TIME_PER_PLAYER 15

#define HIDEHUD_WEAPONSELECTION ( 1<<0 ) // Hide ammo count & weapon selection
#define HIDEHUD_FLASHLIGHT ( 1<<1 )
#define HIDEHUD_ALL ( 1<<2 )
#define HIDEHUD_HEALTH ( 1<<3 ) // Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD ( 1<<4 ) // Hide when local player's dead
#define HIDEHUD_NEEDSUIT ( 1<<5 ) // Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS ( 1<<6 ) // Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT ( 1<<7 ) // Hide all communication elements (saytext, voice icon, etc)
#define HIDEHUD_CROSSHAIR ( 1<<8 ) // Hide crosshairs
#define HIDEHUD_VEHICLE_CROSSHAIR ( 1<<9 ) // Hide vehicle crosshair
#define HIDEHUD_INVEHICLE ( 1<<10 )
#define HIDEHUD_BONUS_PROGRESS ( 1<<11 ) // Hide bonus progress display (for bonus map challenges)

#define HIDEHUD_BITCOUNT 12


public Plugin:myinfo = {
	name = "The Hidden",
	author = "Matheus28",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}


enum HTeam{
	HTeam_Unassigned = TFTeam_Unassigned,
	HTeam_Spectator = TFTeam_Spectator,
	HTeam_Hidden = TFTeam_Blue,
	HTeam_Iris = TFTeam_Red
}

new lastHiddenUserid;
new hidden;
new hiddenHp;
new hiddenHpMax;
new bool:hiddenStick;
new Float:hiddenStamina;
new Float:hiddenInvisibility;
new Float:hiddenVisible;
new Float:hiddenJump;
new bool:hiddenAway;
new Float:hiddenAwayTime;
#if defined HIDDEN_BOO
	new Float:hiddenBoo;
#endif
new bool:newHidden;
new bool:playing;


new forceNextHidden;

new Handle:t_disableCps;
new Handle:t_tick;

new bool:started;

new Handle:cv_enable;

public OnPluginStart(){
	LoadTranslations("common.phrases");
	
	ResetConVar(CreateConVar("sm_hidden_version", PLUGIN_VERSION, "The Hidden Version",
	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY), true, true);
	
	cv_enable = CreateConVar("sm_hidden_enable", "1.0", "Enables/Disables Hidden",
	FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_nexthidden", Cmd_NextHidden, ADMFLAG_CHEATS, "Forces the next hidden to be certain player");
	
	HookConVarChange(cv_enable, CC_Enable);
}

public StartPlugin(){
	if(started) return;
	started=true;
	
	t_tick = CreateTimer(TICK_INTERVAL, Timer_Tick, _, TIMER_REPEAT);
	t_disableCps = CreateTimer(5.0, Timer_DisableCps, _, TIMER_REPEAT);
	
	HookEvent("teamplay_round_start", teamplay_round_start);
	HookEvent("teamplay_round_win", teamplay_round_win);
	HookEvent("teamplay_round_active", teamplay_round_active);
	HookEvent("arena_round_start", teamplay_round_active);
	
	HookEvent("player_team", player_team);
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_hurt", player_hurt);
	HookEvent("player_death", player_death);
}

public OnPluginEnd(){
	if(started){
		for(new i=1;i<=MaxClients;++i){
			if(!IsClientInGame(i)) continue;
			RemoveHiddenVision(i);
		}
	}
}

public StopPlugin(){
	if(!started) return;
	started=false;
	
	KillTimer(t_tick);
	KillTimer(t_disableCps);
	
	UnhookEvent("teamplay_round_start", teamplay_round_start);
	UnhookEvent("teamplay_round_win", teamplay_round_win);
	UnhookEvent("teamplay_round_active", teamplay_round_active);
	UnhookEvent("arena_round_start", teamplay_round_active);
	
	UnhookEvent("player_team", player_team);
	UnhookEvent("player_spawn", player_spawn);
	UnhookEvent("player_hurt", player_hurt);
	UnhookEvent("player_death", player_death);
}

public Action:OnGetGameDescription(String:gameDesc[64]){
	if(started){
		strcopy(gameDesc, 64, "The Hidden");
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnClientDisconnect(client){
	if(client==hidden){
		ResetHidden();
	}
}

public OnMapStart(){
	CheckEnable();
	playing=true;
	
	PrecacheSound(HIDDEN_BOO_FILE, true);
}


public CC_Enable(Handle:convar, const String:oldValue[], const String:newValue[]){
	CheckEnable();
}

public CheckEnable(){
	if(IsArenaMap() && GetConVarBool(cv_enable)){
		StartPlugin();
	}else{
		StopPlugin();
	}
}

public Action:Cmd_NextHidden(client, args){
	if(!started) return Plugin_Continue;
	if(args<1){
		if(GetCmdReplySource()==SM_REPLY_TO_CHAT){
			ReplyToCommand(client, "%s Usage: /nexthidden <player>", PLUGIN_PREFIX);
		}else{
			ReplyToCommand(client, "%s Usage: sm_nexthidden <player>", PLUGIN_PREFIX);
		}
		return Plugin_Handled;
	}
	
	decl String:tmp[128];
	GetCmdArg(1, tmp, sizeof(tmp));
	
	
	new target = FindTarget(client, tmp, false, false);
	if(target==-1) return Plugin_Handled;
	
	forceNextHidden = GetClientUserId(target);
	
	PrintToChat(client, "%s The next hidden will be \x03%N\x01", PLUGIN_PREFIX, target);
	
	return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

public Action:teamplay_round_win(Handle:event, const String:name[], bool:dontBroadcast){
	playing=true;
	CreateTimer(0.5, Timer_ResetHidden);
}

public Action:teamplay_round_active(Handle:event, const String:name[], bool:dontBroadcast){
	playing=true;
}

public Action:teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast){
	playing=false;
	CreateTimer(0.1, Timer_NewGame);
}

public Action:Timer_NewGame(Handle:timer){
	NewGame();
}
public Action:Timer_ResetHidden(Handle:timer){
	ResetHidden();
}


public Action:player_team(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || IsClientInGame(client)) return;
	new HTeam:team = HTeam:GetEventInt(event, "team");
	
	if(client != hidden && team==HTeam_Hidden){
		ChangeClientTeam(client, _:HTeam_Iris);
	}
}

public Action:player_spawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if(client==hidden){
		if(class!=TFClass_Spy){
			TF2_SetPlayerClass(client, TFClass_Spy, true, true);
			CreateTimer(0.1, Timer_Respawn, client);
		}
		newHidden=true;
	}else{
		if(class==TFClass_Spy || class==TFClass_Engineer){
			TF2_SetPlayerClass(client, TFClass_Soldier, true, true);
			CreateTimer(0.1, Timer_Respawn, client);
			if(playing){
				PrintToChat(client, "%s You cannot use this class on team IRIS", PLUGIN_PREFIX);
			}
		}
	}
}

public Action:player_hurt(Handle:event, const String:name[], bool:dontBroadcast){
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(victim!=hidden) return;
	
	new damage = GetEventInt(event, "damageamount");
	
	hiddenHp-=damage;
	if(hiddenHp<0) hiddenHp=0;
	
	if(hiddenHp>500){
		SetEntityHealth(hidden, 500);
	}else if(hiddenHp>0){
		SetEntityHealth(hidden, hiddenHp);
	}
}

public Action:player_death(Handle:event, const String:name[], bool:dontBroadcast){
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!playing){
		if(victim==hidden){
			RemoveHiddenPowers(victim);
		}
		return;
	}
	
	if(victim==hidden){
		hiddenHp=0;
		RemoveHiddenPowers(victim);
		PrintToChatAll("%s \x03The Hidden\x01 was killed!", PLUGIN_PREFIX);
	}else{
		if(hidden!=0 && attacker==hidden){
			hiddenInvisibility+=HIDDEN_INVISIBILITY_TIME*0.35
			if(hiddenInvisibility>HIDDEN_INVISIBILITY_TIME){
				hiddenInvisibility=HIDDEN_INVISIBILITY_TIME;
			}
			hiddenHp+=HIDDEN_HP_PER_KILL;
			if(hiddenHp>hiddenHpMax){
				hiddenHp=hiddenHpMax;
			}
			PrintToChatAll("%s \x03The Hidden\x01 killed \x03%N\x01 and ate his body", PLUGIN_PREFIX, victim);
			CreateTimer(0.1, Timer_Dissolve, victim);
		}
	}
}
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

public OnGameFrame(){
	if(!started) return;
	if(!CanPlay()) return;
	
	new Float:tickInterval = GetTickInterval();
	
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		
		if(i==hidden && IsPlayerAlive(i)){
			if(GetClientHealth(i)>0){
				if(hiddenHp>500){
					SetEntityHealth(i, 500);
				}else{
					SetEntityHealth(i, hiddenHp);
				}
			}
			
			SetEntDataFloat(i, FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), 400.0, true);
			
			if(newHidden){
				newHidden=false;
				CreateTimer(0.5, Timer_GiveHiddenPowers, GetClientUserId(hidden));
			}
			
			if(hiddenAway){
				hiddenAwayTime+=tickInterval;
				if(hiddenAwayTime>HIDDEN_AWAY_TIME){
					ForcePlayerSuicide(i);
					PrintToChatAll("%s \x03The Hidden\x01 was killed because he was away", PLUGIN_PREFIX);
					continue;
				}
			}
			
			new eflags=GetEntityFlags(i);
			
			if(TF2_IsPlayerInCondition(i, TFCond_Disguised) || TF2_IsPlayerInCondition(i, TFCond_Disguising)){
				TF2_RemovePlayerDisguise(i);
			}
			
			if(hiddenInvisibility>0.0){
				hiddenInvisibility-=tickInterval;
				if(hiddenInvisibility<0.0){
					hiddenInvisibility=0.0;
					ForcePlayerSuicide(i);
					PrintToChatAll("%s \x03The Hidden\x01 lost his powers!", PLUGIN_PREFIX);
					continue;
				}
			}
			
			#if defined HIDDEN_BOO
				if(hiddenBoo>0.0){
					hiddenBoo-=tickInterval;
					if(hiddenBoo<0.0){
						hiddenBoo=0.0;
					}
				}
			#endif
			
			if(!hiddenStick){
				HiddenUnstick();
				if(hiddenStamina<HIDDEN_STAMINA_TIME){
					hiddenStamina += tickInterval/2;
					if(hiddenStamina>HIDDEN_STAMINA_TIME){
						hiddenStamina=HIDDEN_STAMINA_TIME;
					}
				}
			}else{
				hiddenStamina-=tickInterval;
				if(hiddenStamina<=0.0){
					hiddenStamina=0.0;
					hiddenStick=false;
					HiddenUnstick();
				}else if(GetEntityMoveType(hidden)==MOVETYPE_WALK){
					SetEntityMoveType(hidden, MOVETYPE_NONE);
				}
			}
			
			if(eflags & FL_ONGROUND || hiddenStick){
				if(hiddenJump>0.0){
					hiddenJump-=tickInterval;
					if(hiddenJump<0.0){
						hiddenJump=0.0;
					}
				}
			}
			
			if(hiddenVisible>0.0){
				hiddenVisible-=tickInterval;
				if(hiddenVisible<0.0){
					hiddenVisible=0.0;
				}
			}
			
			
			if(hiddenInvisibility>0.0){
				if(hiddenVisible<=0.0){
					if(!TF2_IsPlayerInCondition(i, TFCond_Cloaked)){
						TF2_AddCondition(i, TFCond_Cloaked, -1.0);
					}
				}else{
					if(TF2_IsPlayerInCondition(i, TFCond_Cloaked)){
						TF2_RemoveCondition(i, TFCond_Cloaked);
					}
				}
			}else{
				if(TF2_IsPlayerInCondition(i, TFCond_Cloaked)){
					TF2_RemoveCondition(i, TFCond_Cloaked);
				}
			}
			
			if(TF2_IsPlayerInCondition(i, TFCond_DeadRingered)){
				TF2_RemoveCondition(i, TFCond_DeadRingered);
			}
			
			if(TF2_IsPlayerInCondition(i, TFCond_Kritzkrieged)){
				TF2_RemoveCondition(i, TFCond_Kritzkrieged);
			}
			
			if(TF2_IsPlayerInCondition(i, TFCond_OnFire)){
				AddHiddenVisible(0.5);
				TF2_RemoveCondition(i, TFCond_OnFire);
				GiveHiddenVision(i);
			}
			
			if(TF2_IsPlayerInCondition(i, TFCond_Ubercharged)){
				TF2_RemoveCondition(i, TFCond_Ubercharged);
				GiveHiddenVision(i);
			}
			
			if(TF2_IsPlayerInCondition(i, TFCond_Jarated)){
				AddHiddenVisible(1.0);
				TF2_RemoveCondition(i, TFCond_Jarated);
				GiveHiddenVision(i);
			}
			
			if(TF2_IsPlayerInCondition(i, TFCond_Milked)){
				AddHiddenVisible(0.75);
				TF2_RemoveCondition(i, TFCond_Milked);
			}
			
			if(TF2_IsPlayerInCondition(i, TFCond_Bonked)){
				AddHiddenVisible(1.0);
				TF2_RemoveCondition(i, TFCond_Bonked);
			}
			
			if(TF2_IsPlayerInCondition(i, TFCond_Bleeding)){
				AddHiddenVisible(0.5);
				TF2_RemoveCondition(i, TFCond_Bleeding);
			}
			
			SetEntPropFloat(i, Prop_Send, "m_flCloakMeter", hiddenInvisibility/HIDDEN_INVISIBILITY_TIME*100.0);
			
			if(GetEntProp(i, Prop_Send, "m_bGlowEnabled")){
				SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);
			}
			
		}else if(IsClientPlaying(i)){
			if(HTeam:GetClientTeam(i) == HTeam_Hidden){
				ChangeClientTeam(i, _:HTeam_Iris);
			}
			
			if(IsPlayerAlive(i) && !GetEntProp(i, Prop_Send, "m_bGlowEnabled")){
				SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
			}
		}
	}
	
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	if(!CanPlay()) return Plugin_Continue;
	if(client==hidden){
		new bool:changed=false;
		
		if(hiddenStick && hiddenStamina<HIDDEN_STAMINA_TIME-0.5){
			if(buttons & IN_FORWARD
			|| buttons & IN_BACK
			|| buttons & IN_MOVELEFT
			|| buttons & IN_MOVERIGHT
			|| buttons & IN_JUMP
			){
				HiddenUnstick();
			}
		}
		
		if(hiddenAway && (buttons & IN_FORWARD
		|| buttons & IN_BACK
		|| buttons & IN_MOVELEFT
		|| buttons & IN_MOVERIGHT
		|| buttons & IN_JUMP
		)){
			hiddenAway=false;
		}
		
		if(buttons&IN_ATTACK){
			changed=true;
			
			TF2_RemoveCondition(client, TFCond_Cloaked);
			AddHiddenVisible(0.75);
		}
		
		if(buttons&IN_ATTACK2){
			buttons&=~IN_ATTACK2;
			changed=true;
			
			HiddenSpecial();
		}
		
		if(buttons&IN_RELOAD){
			#if defined HIDDEN_BOO
				HiddenBoo();
			#endif
		}
		
		if(changed){
			return Plugin_Changed
		}
	}
	return Plugin_Continue;
}

public AddHiddenVisible(Float:value){
	if(hiddenVisible<value) hiddenVisible=value;
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

stock ResetHidden(){
	if(hidden!=0 && IsClientInGame(hidden)){
		RemoveHiddenPowers(hidden);
		lastHiddenUserid=GetClientUserId(hidden);
	}else{
		lastHiddenUserid=0;
	}
	hidden=0;
}

stock NewGame(){
	if(!CanPlay()) return;
	if(hidden!=0){
		return;
	}
	playing=false;
	SelectHidden();
	if(hidden==0) return;
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		if(!IsClientPlaying(i)) continue;
		if(i==hidden){
			new bool:respawn=false;
			if(HTeam:GetClientTeam(i) != HTeam_Hidden){
				ChangeClientTeam(i, _:HTeam_Hidden);
				respawn=true;
			}
			if(TF2_GetPlayerClass(i)!=TFClass_Spy){
				TF2_SetPlayerClass(i, TFClass_Spy, true, true);
				respawn=true;
			}
			if(respawn){
				CreateTimer(0.1, Timer_Respawn, i);
			}
		}else{
			new bool:respawn=false;
			if(HTeam:GetClientTeam(i) != HTeam_Iris){
				ChangeClientTeam(i, _:HTeam_Iris);
				respawn=true;
			}
			new TFClassType:class=TF2_GetPlayerClass(i);
			
			if(class==TFClass_Unknown || class==TFClass_Spy || class==TFClass_Engineer){
				TF2_SetPlayerClass(i, TFClass_Soldier, true, true);
				respawn=true;
			}
			if(respawn){
				CreateTimer(0.1, Timer_Respawn, i);
			}
			PrintToChat(i, "%s \x03%N\x01 is \x03The Hidden\x01! Kill him before he kills you!", PLUGIN_PREFIX, hidden);
		}
	}
	newHidden=true;
}

stock SelectHidden(){
	hidden=0;
	hiddenHpMax=HIDDEN_HP+((GetClientCount(true)-1)*HIDDEN_HP_PER_PLAYER)
	hiddenHp=hiddenHpMax;
	hiddenVisible=0.0;
	hiddenStamina=HIDDEN_STAMINA_TIME;
	hiddenStick=false;
	hiddenAway=true;
	hiddenAwayTime=0.0;
	hiddenJump=0.0;
	hiddenInvisibility=HIDDEN_INVISIBILITY_TIME;
	
	#if defined HIDDEN_BOO
		hiddenBoo=0.0;
	#endif
	
	new tmp=GetClientOfUserId(forceNextHidden);
	
	if(tmp){
		hidden=tmp;
		forceNextHidden=0;
	}else{
		new clientsCount;
		new clients[MAXPLAYERS+1];
		for(new i=1;i<=MaxClients;++i){
			if(!IsClientInGame(i)) continue;
			if(!IsClientPlaying(i)) continue;
			if(IsFakeClient(i)) continue;
			if(IsClientSourceTV(i)) continue;
			if(IsClientReplay(i)) continue;
			if(IsClientInKickQueue(i)) continue;
			if(IsClientTimingOut(i)) continue;
			if(GetClientUserId(i)==lastHiddenUserid) continue;
			clients[clientsCount++]=i;
		}
		
		//If there isn't any players, try to add the last hidden
		if(clientsCount==0){
			tmp=GetClientOfUserId(lastHiddenUserid);
			if(tmp!=0){
				clients[clientsCount++]=tmp;
			}
		}
		
		//If there isn't any players, try to add bots
		if(clientsCount==0){
			for(new i=1;i<=MaxClients;++i){
				if(!IsClientInGame(i)) continue;
				if(!IsClientPlaying(i)) continue;
				if(IsClientSourceTV(i)) continue;
				if(IsClientReplay(i)) continue;
				clients[clientsCount++]=i;
			}
		}
		
		if(clientsCount==0){
			return hidden;
		}
		
		hidden = clients[GetRandomInt(0, clientsCount-1)];
	}
	
	ChangeClientTeam(hidden, _:HTeam_Hidden);
	TF2_SetPlayerClass(hidden, TFClass_Spy, true, true);
	
	if(!IsPlayerAlive(hidden)){
		TF2_RespawnPlayer(hidden);
	}
	
	PrintToChat(hidden, "%s You are \x03The Hidden\x01! Kill the IRIS Team!", PLUGIN_PREFIX);
	PrintToChat(hidden, "\x03Right click to use the super jump or stick to walls, Press R to use your special\x01", PLUGIN_PREFIX);
	
	return hidden;
}

public Action:Timer_GiveHiddenPowers(Handle:timer, any:data){
	GiveHiddenPowers(GetClientOfUserId(data));
}

stock GiveHiddenPowers(i){
	if(!i) return;
	
	TF2_RemoveWeaponSlot(i, 0); // Revolver
	//TF2_RemoveWeaponSlot(i, 1); // Sapper
	TF2_RemoveWeaponSlot(i, 2); // Knife
	TF2_RemoveWeaponSlot(i, 3); // Disguise Kit
	TF2_RemoveWeaponSlot(i, 4); // Invisibility Watch
	TF2_RemoveWeaponSlot(i, 5); // Golden Machine Gun
	
	// This will add the knife to the spy, even if he has another unlock
	new knife=GivePlayerItem(i, "tf_weapon_knife");
	SetEntProp(knife, Prop_Send, "m_iItemDefinitionIndex", 4);
	SetEntProp(knife, Prop_Send, "m_iEntityLevel", 100);
	SetEntProp(knife, Prop_Send, "m_iEntityQuality", 10);
	SetEntProp(knife, Prop_Send, "m_bInitialized", 1);
	// Also, I hate extensions :p
	
	EquipPlayerWeapon(i, knife);
	
	
	GiveHiddenVision(i);
	
	SetEntProp(i, Prop_Send, "m_iHideHUD", HIDEHUD_HEALTH);
}

stock RemoveHiddenPowers(i){
	
	RemoveHiddenVision(i);
	
	SetEntProp(i, Prop_Send, "m_iHideHUD", 0);
}


stock GiveHiddenVision(i){
	OverlayCommand(i, HIDDEN_OVERLAY);
}

stock RemoveHiddenVision(i){
	OverlayCommand(i, "\"\"");
}

stock ShowHiddenHP(Float:duration){
	if(hidden==0) return;
	duration+=0.1;
	
	new Float:perc=float(hiddenHp)/float(hiddenHpMax)*100.0;
	SetHudTextParams(-1.0, 0.3, duration, 255, 255, 255, 255)
	
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		if(IsFakeClient(i)) continue;
		if(i==hidden) continue;
		ShowHudText(i, 0, "The Hidden: %.1f%%", perc);
	}
	
	if(perc>60.0){
		SetHudTextParams(-1.0, 0.3, duration, 0, 255, 0, 255);
	}else if(perc>30.0){
		SetHudTextParams(-1.0, 0.3, duration, 128, 128, 0, 255);
	}else{
		SetHudTextParams(-1.0, 0.3, duration, 255, 0, 0, 255);
	}
	
	ShowHudText(hidden, 0, "The Hidden: %.1f%%", perc);
	
	SetHudTextParams(-1.0, 0.325, duration, 255, 255, 255, 255);
	ShowHudText(hidden, 1, "Stamina: %.0f%%", hiddenStamina/HIDDEN_STAMINA_TIME*100.0);
	
	#if defined HIDDEN_BOO
		SetHudTextParams(-1.0, 0.35, duration, 255, 255, 255, 255);
		ShowHudText(hidden, 2, "Boo: %.0f%%", 100.0-hiddenBoo/HIDDEN_BOO_TIME*100.0);
	#endif
}

stock bool:HiddenSpecial(){
	if(hidden==0) return;
	
	if(HiddenStick()==-1){
		HiddenSuperJump();
	}
}

stock HiddenStick(){
	if(hidden==0) return 0;
	
	decl Float:pos[3];
	decl Float:ang[3];
	
	GetClientEyeAngles(hidden, ang);
	GetClientEyePosition(hidden, pos);
	
	
	new Handle:ray = TR_TraceRayFilterEx(pos, ang, MASK_ALL, RayType_Infinite, TraceRay_HitWorld);
	if(TR_DidHit(ray)){
		decl Float:pos2[3];
		TR_GetEndPosition(pos2, ray);
		if(GetVectorDistance(pos, pos2)<64.0){
			if(hiddenStick || hiddenStamina<HIDDEN_STAMINA_TIME*0.7){
				CloseHandle(ray);
				return 0;
			}
			
			hiddenStick=true;
			if(GetEntityMoveType(hidden)!=MOVETYPE_NONE){
				SetEntityMoveType(hidden, MOVETYPE_NONE);
			}
			CloseHandle(ray);
			return 1;
		}else{
			CloseHandle(ray);
			return -1;
		}
	}else{
		CloseHandle(ray);
		return -1;
	}
}

public HiddenUnstick(){
	hiddenStick=false;
	if(GetEntityMoveType(hidden)==MOVETYPE_NONE){
		SetEntityMoveType(hidden, MOVETYPE_WALK);
		new Float:vel[3];
		TeleportEntity(hidden, NULL_VECTOR, NULL_VECTOR, vel);
	}
}

public bool:TraceRay_HitWorld(entityhit, mask) {
	return entityhit==0;
}

stock bool:HiddenSuperJump(){
	if(hidden==0) return false;
	if(hiddenJump>0.0) return false;
	hiddenJump = HIDDEN_JUMP_TIME;
	
	HiddenUnstick();
	
	decl Float:ang[3];
	decl Float:vel[3];
	GetClientEyeAngles(hidden, ang);
	GetEntPropVector(hidden, Prop_Data, "m_vecAbsVelocity", vel);
	
	
	decl Float:tmp[3];
	
	GetAngleVectors(ang, tmp, NULL_VECTOR, NULL_VECTOR);
	
	vel[0] += tmp[0]*900.0;
	vel[1] += tmp[1]*900.0;
	vel[2] += tmp[2]*900.0;
	
	new flags=GetEntityFlags(hidden);
	if(flags & FL_ONGROUND){
		flags &= ~FL_ONGROUND;
	}
	SetEntityFlags(hidden, flags);
	
	TeleportEntity(hidden, NULL_VECTOR, NULL_VECTOR, vel);
	
	AddHiddenVisible(1.0);
	
	return true;
}

#if defined HIDDEN_BOO
stock bool:HiddenBoo(){
	if(hidden==0) return false;
	if(hiddenBoo>0.0) return false;
	hiddenBoo = HIDDEN_BOO_TIME;
	
	decl Float:pos[3];
	decl Float:eye[3];
	decl Float:pos2[3];
	GetClientAbsOrigin(hidden, pos);
	GetClientEyePosition(hidden, eye);
	
	AddHiddenVisible(HIDDEN_BOO_VISIBLE);
	
	new targets[MaxClients];
	new targetsCount;
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(i==hidden) continue;
		GetClientAbsOrigin(i, pos2);
		if(GetVectorDistance(pos, pos2, true)>196.0*196.0){
			continue
		}
		
		TF2_StunPlayer(i, HIDDEN_BOO_DURATION, _, TF_STUNFLAG_GHOSTEFFECT|TF_STUNFLAG_THIRDPERSON, hidden);
		targets[targetsCount++] = i;
	}
	targets[targetsCount++] = hidden;
	
	EmitSound(targets, targetsCount, HIDDEN_BOO_FILE, SOUND_FROM_PLAYER, _, _, _, _, _, hidden, eye);
	
	return true;
}
#endif


//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

public Action:Timer_Respawn(Handle:timer, any:data){
	TF2_RespawnPlayer(data);
}
public Action:Timer_Tick(Handle:timer){
	ShowHiddenHP(TICK_INTERVAL);
}

public Action:Timer_DisableCps(Handle:timer){
	DisableCps();
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
stock bool:CanPlay(){
	new r=0;
	new c=0;
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		if(!IsClientPlaying(i)) continue;
		++c;
		if(IsFakeClient(i)) continue;
		++r;
	}
	return r>0 && c>1;
}

/*stock SetEntityFlags(ent, flags){
	SetEntProp(ent, Prop_Data, "m_fFlags", flags);
}*/


stock IsClientPlaying(i){
	return GetClientTeam(i)>0 && !GetEntProp(i, Prop_Send, "m_bArenaSpectator");
}
stock GetClientsPlaying(){
	new c;
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		if(!IsClientPlaying(i)) continue;
		++c;
	}
	return c;
}
stock MakeTeamWin(team){
	new ent = FindEntityByClassname(-1, "team_control_point_master");
	if (ent == -1){
		ent = CreateEntityByName("team_control_point_master");
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "Enable");
	}
	
	SetVariantInt(team);
	AcceptEntityInput(ent, "SetWinner");
}

stock bool:IsArenaMap(){
	decl String:curMap[32];
	GetCurrentMap(curMap, sizeof(curMap));
	return strncmp("arena_", curMap, 6, false)==0;
}

stock OverlayCommand(client, String:overlay[]){	
	if(client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
		ClientCommand(client, "r_screenoverlay %s", overlay);
	}
}
stock DisableCps(){
	new i = -1;
	new CP = 0;
	
	for (new n = 0; n <= 16; n++){
		CP = FindEntityByClassname(i, "trigger_capture_area");
		if(IsValidEntity(CP)){
			AcceptEntityInput(CP, "Disable");
			i = CP;
		}else{
			break;
		}
	}
}

public Action:Timer_Dissolve(Handle:timer, any:data){
	Dissolve(data, 3);
}

stock Dissolve(client, type){
	if(!IsClientInGame(client)) return;

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(ragdoll<0) return;

	decl String:dname[32], String:dtype[32];
	Format(dname, sizeof(dname), "dis_%d", client);
	Format(dtype, sizeof(dtype), "%d", type);
	
	new ent = CreateEntityByName("env_entity_dissolver");
	if(ent>0){
		DispatchKeyValue(ragdoll, "targetname", dname);
		DispatchKeyValue(ent, "dissolvetype", dtype);
		DispatchKeyValue(ent, "target", dname);
		DispatchKeyValue(ent, "magnitude", "10");
		AcceptEntityInput(ent, "Dissolve", ragdoll, ragdoll);
		AcceptEntityInput(ent, "Kill");
	}
}