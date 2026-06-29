/*
 /////////////////////////////		   //////////////			/////         /////
			/////					  ///////////////			/////       /////
			/////					 ////////////////			/////     /////
			/////					//////      /////			/////    /////
			/////				   //////       /////			/////  /////
			/////				  //////        /////			//////////
			/////				 ////////////////////			//////////
			/////				/////////////////////			/////  /////
			/////			   //////           /////			/////    /////
			/////			  //////            /////			/////     /////
			/////            //////             /////			/////       /////
			/////           //////              /////			/////         /////

	[TF2] Disguise Jutsu
	Author: Chaosxk (Tak)
	Alliedmodders: http://forums.alliedmods.net/member.php?u=87026
	Current Version: 3.0
	
	Version Log:
	3.0 - 
	- Removed speed cvar
	- Fixed players not being able to disguise as a model
	- Added disable cvar to disable models from being used
	- Added allowed team cvar
	 Fixed diguise join, added admin as one of them by setting it to 2.  (Admin Generic)
	*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "3.0"
#define FADE_SCREEN_TYPE_IN  (0x0001 | 0x0010)

new Handle:Enabled = INVALID_HANDLE;
new Handle:cvarJoin = INVALID_HANDLE;
new Handle:ShowMenu = INVALID_HANDLE;
new Handle:cvarGib = INVALID_HANDLE;
new Handle:cvarSize = INVALID_HANDLE;
new Handle:cvarSound = INVALID_HANDLE;
new Handle:cvarStun = INVALID_HANDLE;
new Handle:coolDownTimer = INVALID_HANDLE;
new Handle:cvarDisabled = INVALID_HANDLE;
new Handle:soundTimer = INVALID_HANDLE;

new g_Disguise[MAXPLAYERS+1];
new g_Count[MAXPLAYERS+1];
new String:MDL[MAXPLAYERS+1][PLATFORM_MAX_PATH];
new g_coolDown[MAXPLAYERS+1];
new Float:timeLeft[MAXPLAYERS+1];
new stopSpam[MAXPLAYERS+1];
new g_soundCooldown[MAXPLAYERS+1];

new const String:Models[][]= {
	{"models/props_farm/wooden_barrel.mdl"},
	{"models/props_2fort/frog.mdl"},
	{"models/props_well/computer_cart02.mdl"},
	{"models/props_2fort/cow001_reference.mdl"},
	{"models/buildables/dispenser_lvl3_light.mdl"},
	{"models/props_gameplay/orange_cone001.mdl"},
	{"models/props_gameplay/cap_point_base.mdl"},
	{"models/egypt/palm_tree/palm_tree_medium.mdl"},
	{"models/flag/briefcase.mdl"},
	{"models/props_halloween/halloween_gift.mdl"},
	{"models/items/tf_gift.mdl"},
	{"models/props_halloween/halloween_demoeye.mdl"},
	{"models/props_halloween/ghost.mdl"},
	{"models/bots/merasmus/merasmus.mdl"},
	{"models/bots/headless_hatman.mdl"},
	{"models/props_halloween/jackolantern_01.mdl"},
	{"models/items/ammopack_large.mdl"},
	{"models/items/medkit_large.mdl"}, //17
	{"models/props_farm/gibs/wooden_barrel_break01.mdl"},
	{"models/props_farm/gibs/wooden_barrel_chunk02.mdl"},
	{"models/props_farm/gibs/wooden_barrel_chunk03.mdl}"},
	{"models/props_farm/gibs/wooden_barrel_chunk04.mdl"},
	{"models/buildables/gibs/dispenser_gib1.mdl"},
	{"models/buildables/gibs/dispenser_gib2.mdl"},
	{"models/buildables/gibs/dispenser_gib3.mdl"},
	{"models/buildables/gibs/dispenser_gib4.mdl"},
	{"models/buildables/gibs/dispenser_gib5.mdl"}
};

new const String:g_DisabledName[][] = {
	{"barrel"},
	{"frog"},
	{"cart"},
	{"cow"},
	{"dispenser"},
	{"controlpoint"},
	{"palmtree"},
	{"briefcase"},
	{"gift1"},
	{"gift2"},
	{"monoculus"},
	{"ghost"},
	{"merasmus"},
	{"horseman"},
	{"latern"},
	{"ammo"},
	{"med"}
};

new g_Disabled[sizeof(g_DisabledName)];

new const stock String:PLAYER_DISGUISE_SOUND[_:TFClassType - 1][5][] = {
	{			// Scout
		"vo/scout_generic01.wav",
		"vo/scout_apexofjump02.wav",
		"vo/scout_award07.wav",
		"vo/scout_award09.wav",
		"vo/scout_cheers04.wav"
	}, {		// Sniper
		"vo/sniper_award02.wav",
		"vo/sniper_award03.wav",
		"vo/sniper_award07.wav",
		"vo/sniper_award11.wav",
		"vo/sniper_award13.wav"
	}, {		// Soldier
		"vo/soldier_cheers01.wav",
		"vo/soldier_goodjob02.wav",
		"vo/soldier_KaBoomAlts02.wav",
		"vo/soldier_positivevocalization01.wav",
		"vo/soldier_yes01.wav"
	}, {		// Demo Man
		"vo/demoman_laughshort01.wav",
		"vo/demoman_laughshort02.wav",
		"vo/demoman_laughevil02.wav",
		"vo/demoman_laughshort03.wav",
		"vo/demoman_laughevil05.wav"
	}, {		// Medic
		"vo/medic_cheers01.wav",
		"vo/medic_cheers05.wav",
		"vo/medic_specialcompleted11.wav",
		"vo/medic_positivevocalization01.wav",
		"vo/medic_positivevocalization02.wav"
	}, {		// Heavy
		"vo/heavy_yell2.wav",
		"vo/heavy_specialweapon05.wav",
		"vo/heavy_specialcompleted05.wav",
		"vo/heavy_laughterbig04.wav",
		"vo/heavy_yell1.wav"
	}, {		// Pyro
		"vo/pyro_positivevocalization01.wav",
		"vo/pyro_specialcompleted01.wav",
		"vo/pyro_standonthepoint01.wav",
		"vo/pyro_autocappedintelligence01.wav",
		"vo/pyro_autodejectedtie01.wav"
	}, {		// Spy
		"vo/spy_cheers04.wav",
		"vo/spy_positivevocalization01.wav",
		"vo/spy_positivevocalization02.wav",
		"vo/spy_positivevocalization04.wav",
		"vo/spy_laughshort05.wav"
	}, {		// Engineer
		"vo/engineer_engineer_laughevil01.wav",
		"vo/engineer_engineer_laughevil03.wav",
		"vo/engineer_engineer_laughevil05.wav",
		"vo/engineer_laughhappy01.wav",
		"vo/engineer_yes02.wav"
	}
};

new const stock String:PLAYER_DISGUISED_SOUND[_:TFClassType - 1][5][] = {
	{			// Scout
		"vo/scout_beingshotinvincible29.wav",
		"vo/scout_laughevil01.wav",
		"vo/scout_laughevil02.wav",
		"vo/scout_laughevil03.wav",
		"vo/scout_laughhappy01.wav"
	}, {		// Sniper
		"vo/sniper_laughevil01.wav",
		"vo/sniper_laughevil02.wav",
		"vo/sniper_laughevil03.wav",
		"vo/sniper_laughshort04.wav",
		"vo/sniper_laughshort01.wav"
	}, {		// Soldier
		"vo/soldier_laughevil01.wav",
		"vo/soldier_laughevil02.wav",
		"vo/soldier_laughevil03.wav",
		"vo/soldier_laughlong01.wav",
		"vo/soldier_laughshort01.wav"
	}, {		// Demo Man
		"vo/demoman_laughevil01.wav",
		"vo/demoman_laughshort05.wav",
		"vo/demoman_laughevil03.wav",
		"vo/demoman_laughevil04.wav",
		"vo/demoman_laughshort06.wav"
	}, {		// Medic
		"vo/medic_laughevil01.wav",
		"vo/medic_laughevil02.wav",
		"vo/medic_laughevil03.wav",
		"vo/medic_laughevil04.wav",
		"vo/medic_laughevil05.wav"
	}, {		// Heavy
		"vo/heavy_laughevil04.wav",
		"vo/heavy_laughevil02.wav",
		"vo/heavy_laughevil03.wav",
		"vo/heavy_laughevil01.wav",
		"vo/heavy_laughhappy01.wav"
	}, {		// Pyro
		"vo/pyro_laughevil02.wav",
		"vo/pyro_autoonfire02.wav",
		"vo/pyro_laughevil04.wav",
		"vo/pyro_goodjob01.wav",
		"vo/pyro_laughevil03.wav"
	}, {		// Spy
		"vo/spy_laughevil01.wav",
		"vo/spy_laughevil02.wav",
		"vo/spy_laughshort05.wav",
		"vo/spy_laughhappy02.wav",
		"vo/spy_laughshort04.wav"
	}, {		// Engineer
		"vo/engineer_engineer_laughevil02.wav",
		"vo/engineer_engineer_laughevil04.wav",
		"vo/engineer_laughhappy02.wav",
		"vo/engineer_laughshort02.wav",
		"vo/engineer_laughshort03.wav"
	}
};

new const stock String:PLAYER_REVEALED_SOUND[_:TFClassType - 1][5][] = {
	{			// Scout
		"vo/scout_award12.wav",
		"vo/scout_battlecry05.wav",
		"vo/scout_cartgoingbackdefense03.wav",
		"vo/scout_domination02.wav",
		"vo/scout_generic01.wav"
	}, {		// Sniper
		"vo/sniper_award02.wav",
		"vo/sniper_award11.wav",
		"vo/sniper_award12.wav",
		"vo/sniper_battlecry03.wav",
		"vo/sniper_cheers02.wav"
	}, {		// Soldier
		"vo/soldier_battlecry06.wav",
		"vo/soldier_KaBoomAlts01.wav",
		"vo/soldier_PickAxeTaunt04.wav",
		"vo/soldier_robot07.wav",
		"vo/soldier_specialcompleted02.wav"
	}, {		// Demo Man
		"vo/demoman_laughhappy01.wav",
		"vo/demoman_laughhappy02.wav",
		"vo/demoman_laughlong01.wav",
		"vo/demoman_laughlong02.wav",
		"vo/demoman_laughshort04.wav"
	}, {		// Medic
		"vo/medic_cheers06.wav",
		"vo/medic_battlecry01.wav",
		"vo/medic_cheers05.wav",
		"vo/medic_yes02.wav",
		"vo/medic_cheers01.wav"
	}, {		// Heavy
		"vo/heavy_autodejectedtie03.wav",
		"vo/heavy_award01.wav",
		"vo/heavy_award02.wav",
		"vo/heavy_battlecry01.wav",
		"vo/heavy_battlecry03.wav"
	}, {		// Pyro
		"vo/pyro_battlecry01.wav",
		"vo/pyro_battlecry02.wav",
		"vo/pyro_cheers01.wav",
		"vo/pyro_helpme01.wav",
		"vo/pyro_laughevil01.wav"
	}, {		// Spy
		"vo/spy_specialcompleted12.wav",
		"vo/spy_battlecry01.wav",
		"vo/spy_battlecry04.wav",
		"vo/spy_positivevocalization03.wav",
		"vo/spy_specialcompletion06.wav"
	}, {		// Engineer
		"vo/engineer_laughevil06.wav",
		"vo/engineer_gunslingertriplepunchfinal01.wav",
		"vo/engineer_laughlong01.wav",
		"vo/engineer_laughlong02.wav",
		"vo/engineer_laughshort01.wav"
	}
};
	
public Plugin:myinfo = {
	name = "[TF2] Disguise jutsu",
	author = "Tak (Chaosxk)",
	description = "Disguise yourself from enemies!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf")) {
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart() {
	CreateConVar("sm_disguise_version", PLUGIN_VERSION, "Version of disguise jutsu plugin.", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	Enabled = CreateConVar("sm_disguise_enabled", "1", "Enable disguise jutsu to be enabled.");
	cvarJoin = CreateConVar("sm_disguise_join", "0", "Enable players to disguise jutsu when they join? No = 0 Public = 1 Admin = 2");
	cvarGib = CreateConVar("sm_disguise_gib", "1", "Should gibs spawn when the model break?");
	cvarSize = CreateConVar("sm_disguise_size", "1.0", "What should the player's size be when they disguise.");
	cvarSound = CreateConVar("sm_disguise_sound", "1.0", "Should players be allowed to play sounds when disguised?");
	cvarStun = CreateConVar("sm_disguise_stun", "0.0", "Can players get stunned while disguised? 0 = No, 1 = Yes");
	coolDownTimer = CreateConVar("sm_disguise_cooldown", "10", "How long until players can disguise again? (Default: 10)");
	soundTimer = CreateConVar("sm_disguise_timer", "2", "Cooldown before players can play a sound from medic call. (Default: 10)");
	cvarDisabled = CreateConVar("sm_disguise_disabled", "", "Which models should be disabled?");
	
	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_stunned", Player_Stun);
	HookEvent("player_death", Player_Death);
	HookConVarChange(cvarDisabled, cvarChange);
	
	RegAdminCmd("sm_disguise", Disguise, ADMFLAG_GENERIC, "Allows you to disguise jutsu and other people.");
	RegAdminCmd("sm_disguiseme", DisguiseMe, ADMFLAG_GENERIC, "Enables you to disguise jutsu yourself only.");
	RegConsoleCmd("sm_dmenu", DisguiseMenu, "Shows what type of disguise you can use.");
	
	LoadDisabledAbilities();

	AddCommandListener(VoiceListener, "voicemenu");
	AutoExecConfig(true, "disguise");
	LoadTranslations("common.phrases");
}

public OnMapStart() {
	//lots of stuff to precache, this loop makes it easier
	for(new i = 0; i < sizeof(Models); i++) {
		PrecacheModel(Models[i], true);
	}
	for(new i = 0; i < _:TFClassType-1; i++) {
		for(new j = 0; j < 5; j++) {
			PrecacheSound(PLAYER_DISGUISE_SOUND[i][j], true);
			PrecacheSound(PLAYER_DISGUISED_SOUND[i][j], true);
			PrecacheSound(PLAYER_REVEALED_SOUND[i][j], true);
		}
	}
	for(new i = 0; i < MaxClients+1; i++) {
		if(IsValidClient(i)) {
			Format(MDL[i], sizeof(MDL[]), "%s", Models[0]);
		}
	}
}

public cvarChange(Handle:convar, String:oldValue[], String:newValue[]) {
	if(convar == cvarDisabled) {
		LoadDisabledAbilities();
	}
}

public Action:VoiceListener(client, const String:command[], argc) {
	if(IsValidClient(client)) {
		if(g_Disguise[client] == 1) {
			decl String:arguments[32];
			GetCmdArgString(arguments, sizeof(arguments));
			if(StrEqual(arguments, "0 0", false)) {
				if(g_Count[client] == 1) {
					if(g_soundCooldown[client] == 0) {
						EmitSoundToAll(PLAYER_DISGUISED_SOUND[_:TF2_GetPlayerClass(client)-1][GetRandomInt(0, 4)], client, _, _, _, 1.0);
						g_soundCooldown[client] = 1;
						CreateTimer(GetConVarFloat(soundTimer), resetSoundCoolDown, GetClientUserId(client));
						//blocks medic call :)
					}
					return Plugin_Handled;
				}
			}
		}
	}
	//continues with medic call if else :)
	return Plugin_Continue;
}

public Action:resetSoundCoolDown(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		g_soundCooldown[client] = 0;
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &Impulse, Float:Vel[3], Float:Angles[3], &Weapon) {
	if(IsValidClient(client)) {
		if(g_Disguise[client] == 1) {
			if((GetEntityFlags(client) & FL_DUCKING) && (GetEntityFlags(client) & FL_ONGROUND) && !(GetEntityFlags(client) & FL_INWATER) && g_Count[client] == 0 && buttons & IN_ATTACK3) {
				if(g_coolDown[client] == 0) {
					EnableDisguise(client);
					g_Count[client] = 1;
				}
				else if(g_coolDown[client] == 1 && stopSpam[client] == 1) {
					PrintToChat(client, "[Disguise] You can disguise again in %0.0f seconds", timeLeft[client]);
					stopSpam[client] = 0;
				}
			}
			else if(buttons & IN_ATTACK || buttons & IN_ATTACK2 || !(GetEntityFlags(client) & FL_DUCKING)) {
				if(g_Count[client] == 1) {
					DisableDisguise(client);
					g_Count[client] = 0;
					timeLeft[client] = GetConVarFloat(coolDownTimer);
					CreateTimer(1.0, timeLeftCounter, GetClientUserId(client));
					PrintToChat(client, "[Disguise] You can disguise again in %0.0f seconds", GetConVarFloat(coolDownTimer));
				}
				else if(stopSpam[client] == 0) {
					stopSpam[client] = 1;
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action:timeLeftCounter(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		timeLeft[client] -= 1.0;
		if(timeLeft[client] > 0.0) {
			CreateTimer(1.0, timeLeftCounter, GetClientUserId(client));
		}
		else if(timeLeft[client] <= 0.0) {
			timeLeft[client] = 0.0;
			g_coolDown[client] = 0;
		}
	}
}

public OnClientPutInServer(client) {
	if(IsValidClient(client)) {
		g_Disguise[client] = 0;
		g_Count[client] = 0;
		Format(MDL[client], sizeof(MDL[]), "%s", Models[0]);
	}
}

public Action:Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)  {
	new i = GetClientOfUserId(GetEventInt(event, "userid")); 
	if(IsClientInGame(i)) {
		if(Enabled) {
			new join = GetConVarInt(cvarJoin);
			if(join == 1 || join == 2 && (GetUserFlagBits(i) & ADMFLAG_GENERIC)) {
				g_Disguise[i] = 1;
			}
			else {
				g_Disguise[i] = 0;
			}
		}
	}
}

public Player_Stun(Handle:event, const String:name[], bool:dontBroadcast)  {
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if(IsValidClient(client)) {
		if(!GetConVarBool(cvarStun)) {
			if(g_Disguise[client] == 1) {
				TF2_RemoveCondition(client, TFCond_Dazed);
			}
		}
	}
}

public Player_Death(Handle:event, const String:name[], bool:dontBroadcast)  {
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if(IsValidClient(client)) {
		if(g_Count[client] == 1) {
			DisableDisguise(client);
			g_Count[client] = 0;
		}
	}
}
public Action:DisguiseMe(client, args) {
	if(Enabled) {
		if(IsValidClient(client)) {
			if (g_Disguise[client] == 0) {
				g_Disguise[client] = 1;
				PrintToChat(client, "[Disguise] You have enabled disguise jutsu. Type !dmenu to choose your disguise.");
			}
			else {	
				g_Disguise[client] = 0;
				PrintToChat(client, "[Disguise] You have disabled disguise jutsu.");
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:DisguiseMenu(client, args) {
	if(Enabled) {
		if(IsValidClient(client)) {
			if (g_Disguise[client] == 0) PrintToChat(client, "[Disguise] You have no access to this command, type !disguiseme to enable.");
			else MenuPlease(client);
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Disguise(client, args) {
	if(Enabled) {
		if(IsValidClient(client)) {
			decl String:arg1[65], String:arg2[65];
			GetCmdArg(1, arg1, sizeof(arg1));
			GetCmdArg(2, arg2, sizeof(arg2));
			new button = StringToInt(arg2);
			
			decl String:target_name[MAX_TARGET_LENGTH];
			decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
			if((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_CONNECTED,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			
			if(args < 2) {
				PrintToChat(client, "[Disguise] Usage: sm_disguise <client> <On: 1 ; Off = 0>");
				return Plugin_Handled;
			}
			
			if(args == 2) {
				for(new i = 0; i < target_count; i++) {
					if(IsValidClient(target_list[i])) {
						new target = target_list[i];
						if(button == 1) {
							g_Disguise[target] = 1;
							ShowActivity2(client, "[Disguise] ", "%N has given %s disguise jutsu.", client, target_name);
							PrintToChat(target, "[Disguise] You are given the ability to use disguise jitsu.  Type !dmenu to choose your disguise.");
						}
						if(button == 0) {
							g_Disguise[target] = 0;
							ShowActivity2(client, "[Disguise] ", "%N has removed %s disguise jutsu.", client, target_name);
							PrintToChat(target, "[Disguise] You are removed of the ability to use disguise jitsu.");
						}
					}
				}
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

stock MenuPlease(client) {	
	ShowMenu = CreateMenu(MenuMainHandler);
	SetMenuTitle(ShowMenu, "Disguise Jutsu Menu");
	if(g_Disabled[0] == 0) AddMenuItem(ShowMenu, "0", "Barrel");
	if(g_Disabled[1] == 0) AddMenuItem(ShowMenu, "1", "Frog");
	if(g_Disabled[2] == 0) AddMenuItem(ShowMenu, "2", "Cart");
	if(g_Disabled[3] == 0) AddMenuItem(ShowMenu, "3", "Cow");
	if(g_Disabled[4] == 0) AddMenuItem(ShowMenu, "4", "Dispenser");
	if(g_Disabled[5] == 0) AddMenuItem(ShowMenu, "5", "Control Point");
	if(g_Disabled[6] == 0) AddMenuItem(ShowMenu, "6", "Palm Tree");
	if(g_Disabled[7] == 0) AddMenuItem(ShowMenu, "7", "Briefcase");
	if(g_Disabled[8] == 0) AddMenuItem(ShowMenu, "8", "Halloween Gift");
	if(g_Disabled[9] == 0) AddMenuItem(ShowMenu, "9", "Christmas Gift");
	if(g_Disabled[10] == 0) AddMenuItem(ShowMenu, "10", "Monoculus");
	if(g_Disabled[11] == 0) AddMenuItem(ShowMenu, "11", "Ghost");
	if(g_Disabled[12] == 0) AddMenuItem(ShowMenu, "12", "Merasmus");
	if(g_Disabled[13] == 0) AddMenuItem(ShowMenu, "13", "Horsemann");
	if(g_Disabled[14] == 0) AddMenuItem(ShowMenu, "14", "JackO'Latern");
	if(g_Disabled[15] == 0) AddMenuItem(ShowMenu, "15", "Ammo Kit");
	if(g_Disabled[16] == 0) AddMenuItem(ShowMenu, "16", "Med Kit");
	SetMenuExitBackButton(ShowMenu, true);
	DisplayMenu(ShowMenu, client, 30);
}

public MenuMainHandler(Handle:menu, MenuAction:action, client, slot) {
	if(action == MenuAction_Select) {	
		new String:info[32];
		GetMenuItem(menu, slot, info, sizeof(info));
		new value = StringToInt(info);
		Format(MDL[client], sizeof(MDL[]), "%s", Models[value]);
	}	
	else if (action == MenuAction_End) {
		if(slot == MenuCancel_ExitBack) MenuPlease(client);
		CloseHandle(menu);
	}
}

stock EnableDisguise(client) {
	if(g_coolDown[client] == 0) {
		SetVariantString(MDL[client]); AcceptEntityInput(client, "SetCustomModel");
		SetVariantInt(1); AcceptEntityInput(client, "SetCustomModelRotates");
		
		if(GetConVarBool(cvarSound)) EmitSoundToAll(PLAYER_DISGUISE_SOUND[_:TF2_GetPlayerClass(client)-1][GetRandomInt(0, 4)], client, _, _, _, 1.0);
		FadeScreen(client, 50, 50, 50, 255, 100, FADE_SCREEN_TYPE_IN);
		
		if(StrEqual(MDL[client], "models/props_farm/wooden_barrel.mdl")) {
			SetVariantString("0 0 30");
			AcceptEntityInput(client, "SetCustomModelOffset");
		}
		
		else if(StrEqual(MDL[client], "models/flag/briefcase.mdl")) {
			SetVariantString("0 0 5");
			AcceptEntityInput(client, "SetCustomModelOffset");
		}
		
		else if(StrEqual(MDL[client], "models/buildables/dispenser_lvl3_light.mdl")) {
			if(GetClientTeam(client) == 2) {
				SetVariantInt(1);
				AcceptEntityInput(client, "Skin");
			}
			if(GetClientTeam(client) == 3) {
				SetVariantInt(2);
				AcceptEntityInput(client, "Skin");
			}
		}
		
		else if(StrEqual(MDL[client], "models/props_halloween/halloween_demoeye.mdl")) {
			SetVariantString("0 0 30");
			AcceptEntityInput(client, "SetCustomModelOffset");
		}	
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", GetConVarFloat(cvarSize));
		
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
		
		for(new i = 0; i < 3; i++) {
			new weaponIndex = GetPlayerWeaponSlot(client, i);
			if(weaponIndex != -1) {
				SetEntityRenderMode(weaponIndex, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weaponIndex, _, _, _, 0);
			}
		}
		new hideBody = -1;
		while ((hideBody = FindEntityByClassname(hideBody, "tf_ragdoll")) != -1) {
			new iOwner = GetEntProp(hideBody, Prop_Send, "m_iPlayerIndex");
			if(iOwner == client) {
				AcceptEntityInput(hideBody, "Kill");
			}
		}
		new removeHat = -1;
		while ((removeHat = FindEntityByClassname(removeHat, "tf_wearable")) != -1) {
			new i = GetEntPropEnt(removeHat, Prop_Send, "m_hOwnerEntity");
			if(i == client) {
				SetEntityRenderMode(removeHat, RENDER_TRANSCOLOR);
				SetEntityRenderColor(removeHat, _, _, _, 0);
			}
		}	
		new removeCan = -1;
		while((removeCan = FindEntityByClassname(removeCan, "tf_powerup_bottle")) != -1) {
			new i = GetEntPropEnt(removeCan, Prop_Send, "m_hOwnerEntity");
			if(i == client) {
				SetEntityRenderMode(removeCan, RENDER_TRANSCOLOR);
				SetEntityRenderColor(removeCan, _, _, _, 0);
			}
		}
		g_coolDown[client] = 1;
	}
}

stock DisableDisguise(client) {
	if(g_coolDown[client] == 1) {
		SetVariantString(""); AcceptEntityInput(client, "SetCustomModel");
		SetVariantInt(0); AcceptEntityInput(client, "SetCustomModelRotates");
		SetVariantInt(0); AcceptEntityInput(client, "SetForcedTauntCam");
		
		if(GetConVarBool(cvarSound)) EmitSoundToAll(PLAYER_REVEALED_SOUND[_:TF2_GetPlayerClass(client)-1][GetRandomInt(0, 4)], client, _, _, _, 1.0);
		if((StrEqual(MDL[client], "models/props_farm/wooden_barrel.mdl")) && GetConVarBool(cvarGib)) {
			new gibModel = CreateEntityByName("prop_physics_override");
			if (IsValidEntity(gibModel)) {
				SetEntityModel(gibModel, "models/props_farm/wooden_barrel.mdl");
				new Float:pos[3];
				GetClientAbsOrigin(client, pos);
				pos[2] += 30.0 * GetConVarFloat(cvarSize);
				TeleportEntity(gibModel, pos, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(gibModel);
				AcceptEntityInput(gibModel, "Break");
			}
		}	
		else if((StrEqual(MDL[client], "models/buildables/dispenser_lvl3_light.mdl")) && GetConVarBool(cvarGib)) {
			new gibModel = CreateEntityByName("prop_physics_override");
			if (IsValidEntity(gibModel)) {
				SetEntityModel(gibModel, "models/buildables/dispenser_lvl3_light.mdl");
				new Float:pos[3];
				GetClientAbsOrigin(client, pos);
				pos[2] += 30.0 * GetConVarFloat(cvarSize);
				TeleportEntity(gibModel, pos, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(gibModel);
						
				if(GetClientTeam(client) == 2) {
					SetVariantInt(1);
					AcceptEntityInput(gibModel, "Skin");
				}
				if(GetClientTeam(client) == 3) {
					SetVariantInt(2);
					AcceptEntityInput(gibModel, "Skin");
				}
				AcceptEntityInput(gibModel, "Break");
			}
		}

		for(new i = 0; i < 3; i++) {
			new weaponIndex = GetPlayerWeaponSlot(client, i);
			if(weaponIndex != -1) {
				SetEntityRenderMode(weaponIndex, RENDER_NORMAL);
				SetEntityRenderColor(weaponIndex, 255, 255, 255, 255);
			}
		}
		
		new addHat = -1;
		while ((addHat = FindEntityByClassname(addHat, "tf_wearable")) != -1) {
			new i = GetEntPropEnt(addHat, Prop_Send, "m_hOwnerEntity");
			if(i == client) {
				SetEntityRenderMode(addHat, RENDER_NORMAL);
				SetEntityRenderColor(addHat, 255, 255, 255, 255);
			}
		}
		
		new addCan = -1;
		while((addCan = FindEntityByClassname(addCan, "tf_powerup_bottle")) != -1) {
			new i = GetEntPropEnt(addCan, Prop_Send, "m_hOwnerEntity");
			if(i == client) {
				SetEntityRenderMode(addCan, RENDER_NORMAL);
				SetEntityRenderColor(addCan, _, _, _, 0);
			}
		}
	}
}

stock LoadDisabledAbilities() {
	new String:disabled[255];
	GetConVarString(cvarDisabled, disabled, sizeof(disabled));
	for(new i = 0; i < sizeof(g_DisabledName); i++) {
		g_Disabled[i] = 0;
		if(StrContains(disabled, g_DisabledName[i], false) != -1) {
			g_Disabled[i] = 1;
		}
	}
}

stock FadeScreen(client, red, green, blue, alpha, duration, type) {
	new Handle:msg = StartMessageOne("Fade", client);
	BfWriteShort(msg, 255);
	BfWriteShort(msg, duration);
	BfWriteShort(msg, type);
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

stock ClearTimer(&Handle:timer) {  
	if (timer != INVALID_HANDLE) {  
		KillTimer(timer);  
	}  
	timer = INVALID_HANDLE;  
}  

stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}