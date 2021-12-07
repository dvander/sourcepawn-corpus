#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "1.0"
#define PLUGIN_PREFIX "\x04[The Hidden]\x01"


#define HIDDEN_OVERLAY "effects/combine_binocoverlay"
#define HIDDEN_COLOR {0, 0, 0, 3}

#define HIDDEN_HP 500
#define HIDDEN_HP_PER_PLAYER 300
#define HIDDEN_HP_PER_KILL 200

#define HIDDEN_VISIBLE_TIME 0.5
#define HIDDEN_SUPER_JUMP_TIME 5.0

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

new hidden;
new hiddenHp;
new hiddenHpMax;
new Float:hiddenVisible;
new Float:hiddenJump;
new bool:newHidden;
new bool:playing;

new Handle:t_disableCps;

new bool:started;

new Handle:cv_enable;

public OnPluginStart(){
	ResetConVar(CreateConVar("sm_hidden_version", PLUGIN_VERSION, "The Hidden Version",
	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY), true, true);
	
	cv_enable = CreateConVar("sm_hidden_enable", "1.0", "Enables/Disables Hidden",
	FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookConVarChange(cv_enable, CC_Enable);
}

public StartPlugin(){
	if(started) return;
	started=true;
	
	t_disableCps = CreateTimer(5.0, Timer_DisableCps, _, TIMER_REPEAT);
	
	HookEvent("teamplay_round_start", teamplay_round_start);
	
	HookEvent("player_team", player_team);
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_hurt", player_hurt);
	HookEvent("player_death", player_death);
}

public StopPlugin(){
	if(!started) return;
	started=false;
	
	KillTimer(t_disableCps);
	
	UnhookEvent("teamplay_round_start", teamplay_round_start);
	
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
		hidden=0;
	}
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

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

public Action:teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast){
	NewGame();
}

public Action:player_team(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new HTeam:team = HTeam:GetEventInt(event, "team");
	
	if(client != hidden && team==HTeam_Hidden){
		ChangeClientTeam(client, _:HTeam_Iris);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:player_spawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if(client==hidden){
		if(class!=TFClass_Spy){
			TF2_SetPlayerClass(client, TFClass_Spy, true, true);
			TF2_RespawnPlayer(client);
		}
	}else{
		if(class==TFClass_Spy){
			TF2_SetPlayerClass(client, TFClass_Soldier, true, true);
			TF2_RespawnPlayer(client);
			if(playing){
				PrintToChat(client, "%s You cannot use the spy on team IRIS", PLUGIN_PREFIX);
			}
		}
		RemoveHiddenVision(client);
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
	if(!playing) return Plugin_Handled;
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(victim==hidden){
		hiddenHp=0;
		RemoveHiddenPowers(victim);
		PrintToChatAll("%s The Hidden was killed!", PLUGIN_PREFIX);
	}else{
		if(hidden!=0 && attacker==hidden){
			hiddenHp+=HIDDEN_HP_PER_KILL;
			if(hiddenHp>hiddenHpMax){
				hiddenHp=hiddenHpMax;
			}
			PrintToChatAll("%s The Hidden killed \x03%N\x01 and ate his body", PLUGIN_PREFIX, victim);
		}
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

public OnGameFrame(){
	if(!started) return;
	
	
	new Float:tickInterval = GetTickInterval();
	ShowHiddenHP(tickInterval);
	
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
			GiveHiddenVision(i);
			
			if(newHidden){
				newHidden=false;
				GiveHiddenPowers(i);
			}
			
			new flags=TF2_GetPlayerConditionFlags(i);
			
			if(flags & TF_CONDFLAG_DISGUISING
			|| flags & TF_CONDFLAG_DISGUISED
			){
				TF2_RemovePlayerDisguise(i);
			}
			
			if(hiddenJump>0.0){
				hiddenJump-=tickInterval;
				if(hiddenJump<0.0){
					hiddenJump=0.0;
				}
			}
			
			if(hiddenVisible>0.0){
				hiddenVisible-=tickInterval;
				if(hiddenVisible<0.0){
					hiddenVisible=0.0;
				}
			}
			if(hiddenVisible<=0.0){
				if(!(flags & TF_CONDFLAG_CLOAKED)){
					TF2_AddCondition(i, TFCond_Cloaked, -1.0);
				}
			}else{
				if(flags & TF_CONDFLAG_CLOAKED){
					TF2_RemoveCondition(i, TFCond_Cloaked);
				}
			}
			
			if(flags & TF_CONDFLAG_ONFIRE){
				AddHiddenVisible(HIDDEN_VISIBLE_TIME);
				TF2_RemoveCondition(i, TFCond_OnFire);
			}
			
			if(flags & TF_CONDFLAG_JARATED){
				AddHiddenVisible(HIDDEN_VISIBLE_TIME);
				TF2_RemoveCondition(i, TFCond_Jarated);
			}
			
			if(flags & TF_CONDFLAG_MILKED){
				AddHiddenVisible(HIDDEN_VISIBLE_TIME);
				TF2_RemoveCondition(i, TFCond_Milked);
			}
			
			SetEntPropFloat(i, Prop_Send, "m_flCloakMeter", 95.0);
			
			if(GetEntProp(i, Prop_Send, "m_bGlowEnabled")){
				SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);
			}
			
		}else{
			RemoveHiddenVision(i);
			
			if(HTeam:GetClientTeam(i) == HTeam_Hidden){
				ChangeClientTeam(i, _:HTeam_Iris);
			}
			
			if(!GetEntProp(i, Prop_Send, "m_bGlowEnabled")){
				SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
			}
		}
	}
	
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	if(client==hidden){
		new bool:changed=false;
		
		if(buttons&IN_RELOAD){
			buttons&=~IN_RELOAD;
			changed=true;
			HiddenSuperJump();
		}
		
		if(buttons&IN_ATTACK && hiddenVisible<=0.0 && TF2_GetPlayerConditionFlags(client) & TF_CONDFLAG_CLOAKED){
			TF2_RemoveCondition(client, TFCond_Cloaked);
			AddHiddenVisible(HIDDEN_VISIBLE_TIME);
			changed=true;
		}
		
		if(buttons&IN_ATTACK2){
			buttons&=~IN_ATTACK2;
			changed=true;
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

stock NewGame(){
	playing=false;
	SelectHidden();
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
				TF2_RespawnPlayer(i);
			}
			PrintToChat(i, "%s You are The Hidden! Kill the IRIS Team!", PLUGIN_PREFIX);
		}else{
			if(HTeam:GetClientTeam(i) != HTeam_Iris){
				ChangeClientTeam(i, _:HTeam_Iris);
				TF2_RespawnPlayer(i);
			}
			PrintToChat(i, "%s \x03%N\x01 is The Hidden! Kill him before he kills you!", PLUGIN_PREFIX, hidden);
		}
	}
	newHidden=true;
	
	playing=true;
}

stock SelectHidden(){
	hidden=0;
	hiddenHpMax=HIDDEN_HP+((GetClientCount(true)-1)*HIDDEN_HP_PER_PLAYER)
	hiddenHp=hiddenHpMax;
	hiddenVisible=0.0;
	hiddenJump=0.0;
	
	new clientsCount;
	new clients[MAXPLAYERS+1];
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		if(!IsClientPlaying(i)) continue;
		if(IsFakeClient(i)) continue;
		clients[clientsCount++]=i;
	}
	
	//If there isn't any players, try to add bots
	if(clientsCount==0){
		for(new i=1;i<=MaxClients;++i){
			if(!IsClientInGame(i)) continue;
			if(!IsClientPlaying(i)) continue;
			clients[clientsCount++]=i;
		}
	}
	
	if(clientsCount==0){
		return hidden;
	}
	
	SortIntegers(clients, clientsCount, Sort_Random);
	
	hidden = clients[0];
	
	return hidden;
}

stock GiveHiddenPowers(i){
	
	TF2_RemoveWeaponSlot(i, 0); // Revolver
	//TF2_RemoveWeaponSlot(i, 1); // Sapper
	//TF2_RemoveWeaponSlot(i, 2); // Knife
	TF2_RemoveWeaponSlot(i, 3);
	TF2_RemoveWeaponSlot(i, 4);
	TF2_RemoveWeaponSlot(i, 5);
	EquipPlayerWeapon(i, GetPlayerWeaponSlot(i, 2));
	
	GiveHiddenVision(i);
	
	//SetEntProp(i, Prop_Send, "m_iHideHUD", (2<<12)-1);
}

stock RemoveHiddenPowers(i){
	
	RemoveHiddenVision(i);
	
	//SetEntProp(i, Prop_Send, "m_iHideHUD", 0);
}


stock GiveHiddenVision(i){
	OverlayCommand(i, HIDDEN_OVERLAY);
}

stock RemoveHiddenVision(i){
	OverlayCommand(i, "\"\"");
}

stock ShowHiddenHP(Float:duration){
	if(hidden==0) return;
	duration*=2;
	
	new Float:perc=float(hiddenHp)/float(hiddenHpMax)*100.0;
	SetHudTextParams(-1.0, 0.3, duration, 255, 255, 255, 255)
	
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		if(IsFakeClient(i)) continue;
		if(i==hidden) continue;
		ShowHudText(i, 0, "The Hidden: %.1f%%", perc);
	}
	
	if(perc>60.0){
		SetHudTextParams(-1.0, 0.3, duration, 128, 255, 128, 255);
	}else if(perc>30.0){
		SetHudTextParams(-1.0, 0.3, duration, 255, 128, 0, 255);
	}else{
		SetHudTextParams(-1.0, 0.3, duration, 255, 0, 0, 255);
	}
	
	
	ShowHudText(hidden, 0, "The Hidden: %.1f%%", perc);
	if(hiddenJump<=0.0){
		SetHudTextParams(-1.0, 0.325, duration, 128, 255, 128, 255);
	}else{
		SetHudTextParams(-1.0, 0.325, duration, 255, 255, 255, 255);
	}
	ShowHudText(hidden, 1, "Super Jump: %.0f%%", 100.0-(hiddenJump/HIDDEN_SUPER_JUMP_TIME*100.0));
}

stock HiddenSuperJump(){
	if(hiddenJump>0.0) return;
	hiddenJump = HIDDEN_SUPER_JUMP_TIME;
	
	decl Float:vel[3];
	GetEntPropVector(hidden, Prop_Data, "m_vecAbsVelocity", vel);
	vel[2] += 700.0;
	
	new flags=GetEntityFlags(hidden);
	if(flags & FL_ONGROUND){
		flags &= ~FL_ONGROUND;
	}
	SetEntityFlags(hidden, flags);
	
	TeleportEntity(hidden, NULL_VECTOR, NULL_VECTOR, vel);
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

public Action:Timer_DisableCps(Handle:timer){
	DisableCps();
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

stock SetEntityFlags(ent, flags){
	SetEntProp(ent, Prop_Data, "m_fFlags", flags);
}
stock IsClientPlaying(i){
	new HTeam:team=HTeam:GetClientTeam(i);
	return team==HTeam_Hidden || team==HTeam_Iris;
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
