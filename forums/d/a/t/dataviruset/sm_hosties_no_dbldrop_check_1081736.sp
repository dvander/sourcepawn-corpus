#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

// Constants
#define PLUGIN_VERSION	 "1.04"

#define MESS			 "\x03[SM_Hosties] \x01%t"
#define DEBUG_MESS		 "\x04[SM_Hosties DEBUG] \x01"

// Global vars
new Handle:LRsenabled;
new LRchoises[64];
new LRaskcaller = 0;
new LRtype;
new LRplayers[64];
new bool:LRinprogress = false;
new LRprogressplayer1;
new LRprogressplayer2;

new CFloser = 0;
new bool:CFdone = false;

new bool:GTp1dropped = false;
new bool:GTp2dropped = false;
new Float:GTp1droppos[3];
new Float:GTp2droppos[3];
new bool:GTcheckerstarted = false;
new bool:GTp1done = false;
new bool:GTp2done = false;
new bool:GTp1cheat = false;
new bool:GTp2cheat = false;
new Float:GTdeagle1lastpos[3];
new Float:GTdeagle2lastpos[3];

new GTBeamSprite;
new GTred[4] = {255, 25, 15, 255};
new GTblue[4] = {50, 75, 255, 255};

new GTdeagle1 = 0;
new GTdeagle2 = 0;

new S4Slastshot = 0;
new S4Sp1latestammo = 0;
new S4Sp2latestammo = 0;
new s4s_doubleshot_action = 0;
new lr_gt_mode = 0;

new bool:LRannounced = false;

new rebels[64];
new rebelscount = 0;
new bool:AllowWeaponDrop = true;

// ConVar-stuff
new Handle:sm_hosties_lr_kf_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_kf_cheat_action	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_s4s_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_s4s_dblsht_action	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_s4s_shot_taken		 = INVALID_HANDLE;
new Handle:sm_hosties_lr_gt_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_gt_mode			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_cf_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_cf_slay			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_cf_cheat_action	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_cf_loser_color1	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_cf_loser_color2	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_cf_loser_color3	 = INVALID_HANDLE;
new Handle:sm_hosties_lr					 = INVALID_HANDLE;
new Handle:sm_hosties_lr_ts_max				 = INVALID_HANDLE;
new Handle:sm_hosties_lr_beacon				 = INVALID_HANDLE;
new Handle:sm_hosties_lr_rebel_mode			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_p_killed_action	 = INVALID_HANDLE;
new Handle:sm_hosties_ct_start				 = INVALID_HANDLE;
new Handle:sm_hosties_rebel_color1			 = INVALID_HANDLE;
new Handle:sm_hosties_rebel_color2			 = INVALID_HANDLE;
new Handle:sm_hosties_rebel_color3			 = INVALID_HANDLE;
new Handle:sm_hosties_freekill_sound		 = INVALID_HANDLE;
new Handle:sm_hosties_lr_sound				 = INVALID_HANDLE;
new Handle:sm_hosties_announce_rebel		 = INVALID_HANDLE;
new Handle:sm_hosties_announce_rules		 = INVALID_HANDLE;
new Handle:sm_hosties_announce_attack		 = INVALID_HANDLE;
new Handle:sm_hosties_announce_rebel_down	 = INVALID_HANDLE;
new Handle:sm_hosties_announce_lr			 = INVALID_HANDLE;
new Handle:sm_hosties_rules_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_checkplayers_enable	 = INVALID_HANDLE;
new Handle:sm_hosties_version				 = INVALID_HANDLE;

new String:freekill_sound[PLATFORM_MAX_PATH] = "-1";
new String:lr_sound[PLATFORM_MAX_PATH] = "-1";

public Plugin:myinfo =
{
	name = "Hosties for SM",
	author = "dataviruset",
	description = "Hosties and ba_jail functionality for SourceMod",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	// Load translations
	LoadTranslations("hosties.phrases");

	// Console commands
	RegConsoleCmd("sm_lr", Command_LastRequest);
	RegConsoleCmd("sm_lastrequest", Command_LastRequest);
	RegConsoleCmd("sm_checkplayers", Command_CheckPlayers);

	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/hosties_rulesdisable.ini");
	new Handle:fileh = OpenFile(file, "r");
	if (fileh == INVALID_HANDLE)
		RegConsoleCmd("sm_rules", Command_Rules);

	// Events hooks
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnect);

	// Create ConVars
	sm_hosties_lr = CreateConVar("sm_hosties_lr", "1", "Enable or disable Last Requests (the !lr command); 0 - disable, 1 - enable");
	sm_hosties_lr_ts_max = CreateConVar("sm_hosties_lr_ts_max", "2", "The maximum number of terrorists left to enable LR; 0 - LR is always enabled, >0 - maximum number of Ts");
	sm_hosties_lr_beacon = CreateConVar("sm_hosties_lr_beacon", "1", "Whether or not to beacon players on LR; 0 - disable, 1 - enable");
	sm_hosties_lr_rebel_mode = CreateConVar("sm_hosties_lr_rebel_mode", "1", "LR-mode for rebelling terrorists; 0 - Rebelling Ts can never have a LR, 1 - Rebelling Ts must let the CT decide if a LR is OK, 2 - Rebelling Ts can have a LR just like other Ts");
	sm_hosties_lr_p_killed_action = CreateConVar("sm_hosties_lr_p_killed_action", "0", "What to do when a LR-player gets killed by a player not in LR during LR; 0 - just abort LR, 1 - abort LR and slay the attacker");
	sm_hosties_ct_start = CreateConVar("sm_hosties_ct_start", "2", "Weapons given CT on spawn; 0 - knife only, 1 - knife and deagle, 2 - knife, deagle and colt");
	sm_hosties_lr_kf_enable = CreateConVar("sm_hosties_lr_kf_enable", "1", "Enable LR Knife Fight; 0 - disable, 1 - enable");
	sm_hosties_lr_kf_cheat_action = CreateConVar("sm_hosties_lr_kf_cheat_action", "1", "What to do with a knife fighter who attacks the other player with another weapon than knife; 0 - abort LR, 1 - slay player");
	sm_hosties_lr_s4s_enable = CreateConVar("sm_hosties_lr_s4s_enable", "1", "Enable LR Shot4Shot; 0 - disable, 1 - enable");
	sm_hosties_lr_s4s_dblsht_action = CreateConVar("sm_hosties_lr_s4s_dblsht_action", "1", "What to do with someone who fires 2 shots in a row in Shot4Shot; 0 - nothing (ignore completely), 1 - abort the LR, 2 - slay the player who fired 2 shots in a row");
	sm_hosties_lr_s4s_shot_taken = CreateConVar("sm_hosties_lr_s4s_shot_taken", "1", "Enable announcements in Shot4Shot when a contestant has taken his shot; 0 - disable, 1 - enable");
	sm_hosties_lr_gt_enable = CreateConVar("sm_hosties_lr_gt_enable", "1", "Enable LR Gun Toss; 0 - disable, 1 - enable");
	sm_hosties_lr_gt_mode = CreateConVar("sm_hosties_lr_gt_mode", "1", "How Gun Toss will be played; 0 - deagle gets 7 ammo at start, 1 - deagle gets 7 ammo on drop, colouring of deagles, deagle markers and distance meter");
	sm_hosties_lr_cf_enable = CreateConVar("sm_hosties_lr_cf_enable", "1", "Enable LR Chicken Fight; 0 - disable, 1 - enable");
	sm_hosties_lr_cf_slay = CreateConVar("sm_hosties_lr_cf_slay", "1", "Slay the loser of a Chicken Fight instantly? 0 - disable, 1 - enable");
	sm_hosties_lr_cf_cheat_action = CreateConVar("sm_hosties_lr_cf_cheat_action", "1", "What to do with a chicken fighter who attacks the other player with another weapon than knife; 0 - abort LR, 1 - slay player");
	sm_hosties_lr_cf_loser_color1 = CreateConVar("sm_hosties_lr_cf_loser_color1", "255", "What color to turn the loser of a chicken fight into (only if sm_hosties_lr_cf_slay == 0, set R, G and B values to 255 to disable) (Rgb); x - red value");
	sm_hosties_lr_cf_loser_color2 = CreateConVar("sm_hosties_lr_cf_loser_color2", "255", "What color to turn the loser of a chicken fight into (rGb); x - green value");
	sm_hosties_lr_cf_loser_color3 = CreateConVar("sm_hosties_lr_cf_loser_color3", "0", "What color to turn the loser of a chicken fight into (rgB); x - blue value");
	sm_hosties_rebel_color1 = CreateConVar("sm_hosties_rebel_color1", "255", "What color to turn a rebel into (set R, G and B values to 255 to disable) (Rgb); x - red value");
	sm_hosties_rebel_color2 = CreateConVar("sm_hosties_rebel_color2", "0", "What color to turn a rebel into (rGb); x - green value");
	sm_hosties_rebel_color3 = CreateConVar("sm_hosties_rebel_color3", "0", "What color to turn a rebel into (rgB); x - blue value");
	sm_hosties_freekill_sound = CreateConVar("sm_hosties_freekill_sound", "sm_hosties/freekill1.mp3", "What sound to play if a non-rebelling player gets attacked (yeah, it's freeattack, not freekill) relative to the sound-folder; -1 - disable, path - path to sound file (set downloading and precaching in addons/sourcemod/configs/hosties_sounddownloads.ini)");
	sm_hosties_lr_sound = CreateConVar("sm_hosties_lr_sound", "sm_hosties/lr1.mp3", "What sound to play when LR gets available, relative to the sound-folder (also requires sm_hosties_announce_lr to be 1); -1 - disable, path - path to sound file (set downloading and precaching in addons/sourcemod/configs/hosties_sounddownloads.ini)");
	sm_hosties_announce_rebel = CreateConVar("sm_hosties_announce_rebel", "1", "Enable or disable chat announcements when a terrorist becomes a rebel; 0 - disable, 1 - enable");
	sm_hosties_announce_rules = CreateConVar("sm_hosties_announce_rules", "1", "Enable or disable rule announcements in the beginning of every round ('please follow the rules listed in !rules'); 0 - disable, 1 - enable");
	sm_hosties_announce_attack = CreateConVar("sm_hosties_announce_attack", "1", "Enable or disable announcements when a CT attacks a non-rebelling T; 0 - disable, 1 - enable");
	sm_hosties_announce_rebel_down = CreateConVar("sm_hosties_announce_rebel_down", "1", "Enable or disable chat announcements when a rebel is killed; 0 - disable, 1 - enable");
	sm_hosties_announce_lr = CreateConVar("sm_hosties_announce_lr", "1", "Enable or disable chat announcements when Last Requests starts to be available; 0 - disable, 1 - enable");
	sm_hosties_rules_enable = CreateConVar("sm_hosties_rules_enable", "1", "Enable or disable rules showing up at !rules command (if you need to disable the command registration on plugin startup, add a file in your sourcemod/configs/ named hosties_rulesdisable.ini with any content); 0 - disable, 1 - enable");
	sm_hosties_checkplayers_enable = CreateConVar("sm_hosties_checkplayers_enable", "1", "Enable or disable the !checkplayers command; 0 - disable, 1 - enable");
	sm_hosties_version = CreateConVar("sm_hosties_version", PLUGIN_VERSION, "SM_Hosties plugin version (unchangeable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	SetConVarString(sm_hosties_version, PLUGIN_VERSION);
	AutoExecConfig(true, "sm_hosties");

	// Hook ConVar-changes
	HookConVarChange(sm_hosties_version, VersionChange);

	LRsenabled = CreateArray(2);
}

public OnMapStart()
{
	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/hosties_sounddownloads.ini");
	new Handle:fileh = OpenFile(file, "r");
	if (fileh != INVALID_HANDLE)
	{
		new String:buffer[256];
		new String:buffer_full[PLATFORM_MAX_PATH];

		while(ReadFileLine(fileh, buffer, sizeof(buffer)))
		{
			TrimString(buffer);
			if ( (StrContains(buffer, "//") == -1) && (!StrEqual(buffer, "")) /*&& (!StrEqual(buffer, "\n"))*/ )
			{
				PrintToServer("Reading sounddownloads line :: %s", buffer);
				Format(buffer_full, sizeof(buffer_full), "sound/%s", buffer);
				if (FileExists(buffer_full))
				{
					PrintToServer("Precaching %s", buffer);
					PrecacheSound(buffer, true);
					AddFileToDownloadsTable(buffer_full);
					PrintToServer("Adding %s to downloads table", buffer_full);
				}
				else
				{
					PrintToServer("File does not exist! %s", buffer_full);
				}
			}
			else
			{
				PrintToServer("Ignoring sounddownloads line :: %s", buffer);
			}
		}

	}

	GTBeamSprite = PrecacheModel("materials/sprites/laser.vmt");
}

public OnConfigsExecuted()
{
	// Enable Last Requests
	if (GetConVarInt(sm_hosties_lr_kf_enable) == 1)
		PushArrayCell(LRsenabled, 0);
	if (GetConVarInt(sm_hosties_lr_s4s_enable) == 1)
		PushArrayCell(LRsenabled, 1);
	if (GetConVarInt(sm_hosties_lr_gt_enable) == 1)
		PushArrayCell(LRsenabled, 2);
	if (GetConVarInt(sm_hosties_lr_cf_enable) == 1)
		PushArrayCell(LRsenabled, 3);

	s4s_doubleshot_action = GetConVarInt(sm_hosties_lr_s4s_dblsht_action);
	lr_gt_mode = GetConVarInt(sm_hosties_lr_gt_mode);
	GetConVarString(sm_hosties_freekill_sound, freekill_sound, sizeof(freekill_sound));
	if (!StrEqual(freekill_sound, "-1"))
	{
		new String:freekill_sound_full[PLATFORM_MAX_PATH] = "sound/";
		StrCat(freekill_sound_full, sizeof(freekill_sound_full), freekill_sound);
		if (!FileExists(freekill_sound_full))
		{
			freekill_sound = "-1";
		}
	}
	GetConVarString(sm_hosties_lr_sound, lr_sound, sizeof(lr_sound));
	if (!StrEqual(lr_sound, "-1"))
	{
		new String:lr_sound_full[PLATFORM_MAX_PATH] = "sound/";
		StrCat(lr_sound_full, sizeof(lr_sound_full), lr_sound);
		if (!FileExists(lr_sound_full))
		{
			lr_sound = "-1";
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

public VersionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, PLUGIN_VERSION);
}

public Action:OnWeaponDrop(client, weapon)
{
	if (AllowWeaponDrop == false)
		return Plugin_Handled;

	if ( (LRinprogress == true) && (lr_gt_mode == 1) && (LRtype == 2) && ((client == LRprogressplayer1) || (client == LRprogressplayer2)) )
	{
		/*new String:p_weapon[32];
		GetClientWeapon(client, p_weapon, sizeof(p_weapon));*/
		new String:weapon_name[32];
		GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
		if (StrEqual(weapon_name, "weapon_deagle"))
		{
			new iWeapon = GetEntDataEnt2(client, FindSendPropInfo("CCSPlayer", "m_hActiveWeapon"));
			SetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 7);
			if (client == LRprogressplayer1)
			{
				GetClientAbsOrigin(client, GTp1droppos);
				//PrintToChatAll("\x04[SM_Hosties DEBUG] \x01GT - P1 DROPPED = TRUE");
				GTp1dropped = true;
			}
			else
			{
				GetClientAbsOrigin(client, GTp2droppos);
				//PrintToChatAll("\x04[SM_Hosties DEBUG] \x01GT - P2 DROPPED = TRUE");
				GTp2dropped = true;
			}

			if (!GTcheckerstarted)
			{
				GTcheckerstarted = true;
				CreateTimer(0.2, GTchecker, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}

	return Plugin_Continue;
}

public Action:OnWeaponEquip(client, weapon)
{
	if ( (LRinprogress) && (LRtype == 2))
	{
		if ( (client == LRprogressplayer1) && (GTp1dropped) && (!GTp1done) )
		{
			new String:weapon_name[32];
			GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
			if (StrEqual(weapon_name, "weapon_deagle"))
			{
				GTp1cheat = true;
				GTp1done = true;
			}
		}
		else if ( (client == LRprogressplayer2) && (GTp2dropped) && (!GTp2done) )
		{
			new String:weapon_name[32];
			GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
			if (StrEqual(weapon_name, "weapon_deagle"))
			{
				GTp2cheat = true;
				GTp2done = true;
			}
		}
	}

	return Plugin_Continue;
}

// Gun Toss distance meter and BeamSprite application
public Action:GTchecker(Handle:timer)
{
	if ( (!IsClientConnected(LRprogressplayer1)) || (!IsClientInGame(LRprogressplayer1)) || (!IsPlayerAlive(LRprogressplayer1))
	|| (!IsClientConnected(LRprogressplayer2)) || (!IsClientInGame(LRprogressplayer2)) || (!IsPlayerAlive(LRprogressplayer2)) )
	{
		return Plugin_Stop;
		//CloseHandle(timer);
	}

	new Float:GTdeagle1pos[3];
	new Float:GTdeagle2pos[3];

	if (GTp1dropped && !GTp1done)
	{
		GetEntPropVector(GTdeagle1, Prop_Data, "m_vecOrigin", GTdeagle1pos);
		if (GetVectorDistance(GTdeagle1lastpos, GTdeagle1pos) == 0.00)
		{
			GTp1done = true;
			new Float:beamStartP1[3];
			new Float:beamSubtractP1[3] = {0.00, 0.00, -30.00};
			MakeVectorFromPoints(beamSubtractP1, GTdeagle1pos, beamStartP1);
			TE_SetupBeamPoints(beamStartP1, GTdeagle1pos, GTBeamSprite, 0, 0, 0, 18.0, 10.0, 10.0, 7, 0.0, GTred, 0);
			TE_SendToAll();
		}
		else
		{
			GTdeagle1lastpos = GTdeagle1pos;
		}
	}
	if (GTp2dropped && !GTp2done)
	{
		GetEntPropVector(GTdeagle2, Prop_Data, "m_vecOrigin", GTdeagle2pos);
		//GetEntPropVector(GTdeagle2, Prop_Send, "m_vecOrigin", GTdeagle2pos);
		if (GetVectorDistance(GTdeagle2lastpos, GTdeagle2pos) == 0.00)
		{
			GTp2done = true;
			new Float:beamStartP2[3];
			new Float:beamSubtractP2[3] = {0.00, 0.00, -30.00};
			MakeVectorFromPoints(beamSubtractP2, GTdeagle2pos, beamStartP2);
			TE_SetupBeamPoints(beamStartP2, GTdeagle2pos, GTBeamSprite, 0, 0, 0, 18.0, 10.0, 10.0, 7, 0.0, GTblue, 0);
			TE_SendToAll();
		}
		else
		{
			GTdeagle2lastpos = GTdeagle2pos;
		}
	}

	if ( GTp1done && !GTp2done && GTp1cheat )
	{
		PrintHintTextToAll("%t\n\n%N -- 0\n%N -- 0", "Distance Meter", LRprogressplayer1, GetVectorDistance(GTp1droppos, GTdeagle1pos), LRprogressplayer2);
	}
	else if (GTp1done && !GTp2done)
	{
		PrintHintTextToAll("%t\n\n%N -- %f\n%N -- 0", "Distance Meter", LRprogressplayer1, GetVectorDistance(GTp1droppos, GTdeagle1pos), LRprogressplayer2);
	}

	if ( GTp2done && !GTp1done && GTp2cheat )
	{
		PrintHintTextToAll("%t\n\n%N -- 0\n%N -- 0", "Distance Meter", LRprogressplayer1, GetVectorDistance(GTp1droppos, GTdeagle1pos), LRprogressplayer2);
	}
	else if (GTp2done && !GTp1done)
	{
		PrintHintTextToAll("%t\n\n%N -- 0\n%N -- %f", "Distance Meter", LRprogressplayer1, LRprogressplayer2, GetVectorDistance(GTp2droppos, GTdeagle2pos));
	}

	if (GTp1done && GTp2done && !GTp1cheat && !GTp2cheat)
	{
		PrintHintTextToAll("%t\n\n%N -- %f\n%N -- %f", "Distance Meter", LRprogressplayer1, GetVectorDistance(GTp1droppos, GTdeagle1pos), LRprogressplayer2, GetVectorDistance(GTp2droppos, GTdeagle2pos));
		return Plugin_Stop;
		//CloseHandle(timer);
	}
	else
	{
		if (GTp1done && GTp2done && GTp1cheat && GTp2cheat)
		{
			return Plugin_Stop;
			//CloseHandle(timer);
		}
	}

	return Plugin_Continue;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	LRinprogress = false;
	GTp1dropped = false;
	GTp2dropped = false;

	for (new i = 0; i < sizeof(rebels); i++)
	{
		rebels[i] = 0;
	}
	rebelscount = 0;
	PrintToChatAll(MESS, "Powered By Hosties");

	if (GetConVarInt(sm_hosties_announce_rules) == 1)
		PrintToChatAll(MESS, "Please Follow Rules");

	new ct_give = GetConVarInt(sm_hosties_ct_start);

	// strip all weapons and give new stuff
	new wepIdx;
	for(new i=1; i <= GetMaxClients(); i++)
	{
		if ( (IsClientConnected(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i)) ) // if player exists and is alive
		{
			for (new s = 0; s < 4; s++)
			{
				if ((wepIdx = GetPlayerWeaponSlot(i, s)) != -1)
				{
					RemovePlayerItem(i, wepIdx);
					RemoveEdict(wepIdx);
				}
			}

			// if player == T
			if (GetClientTeam(i) == 2)
			{
				GivePlayerItem(i, "weapon_knife");
			}
			// if player == CT
			else if (GetClientTeam(i) == 3)
			{
				GivePlayerItem(i, "weapon_knife");
				if (ct_give > 0)
					GivePlayerItem(i, "weapon_deagle");
				if (ct_give > 1)
					GivePlayerItem(i, "weapon_m4a1");
			}
		}
		//PrintToChatAll("\x04[SM_Hosties DEBUG] \x01Weapon stripper: Loop %d finished.", i);
	}

	// everything done, enable player weapon dropping again
	AllowWeaponDrop = true;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// disable player weapon dropping
	AllowWeaponDrop = false;

	// reset LR announce
	LRannounced = false;
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ev_attacker = GetEventInt(event, "attacker");
	new ev_target = GetEventInt(event, "userid");
	new attacker = GetClientOfUserId(ev_attacker);
	new target = GetClientOfUserId(ev_target);

	if ( (LRinprogress) && ((LRtype == 0) || (LRtype == 3)) && ((attacker == LRprogressplayer1) || (attacker == LRprogressplayer2)) && ((target == LRprogressplayer1) || (target == LRprogressplayer2)) )
	{
		/*new String:weapon[32];
		GetClientWeapon(attacker, weapon, sizeof(weapon));*/
		new String:weapon[32];
		GetEventString(event, "weapon", weapon, 32);
		if (!StrEqual(weapon, "knife"))
		{
			if (LRtype == 0) // knife fight weapon hurt
			{
				if (GetConVarInt(sm_hosties_lr_kf_cheat_action) == 1)
				{
					ForcePlayerSuicide(attacker);
					PrintToChatAll(MESS, "Knife Fight Gun Attack Slay", attacker, target, weapon);
					if (GetConVarInt(sm_hosties_lr_beacon) == 1)
						ServerCommand("sm_beacon #%d", GetClientUserId(target));
				}
				else
				{
					PrintToChatAll(MESS, "Knife Fight Gun Attack Abort", attacker, target, weapon);
					if (GetConVarInt(sm_hosties_lr_beacon) == 1)
					{
						ServerCommand("sm_beacon #%d", GetClientUserId(target));
						ServerCommand("sm_beacon #%d", GetClientUserId(attacker));
					}
				}
			}
			else // chicken fight weapon hurt
			{
				if ( (GetConVarInt(sm_hosties_lr_cf_cheat_action) == 1) && (!CFdone) )
				{
					ForcePlayerSuicide(attacker);
					PrintToChatAll(MESS, "Chicken Fight Gun Attack Slay", attacker, target, weapon);
					if (GetConVarInt(sm_hosties_lr_beacon) == 1)
						ServerCommand("sm_beacon #%d", GetClientUserId(target));
					GivePlayerItem(target, "weapon_knife");
				}
				else
				{
					if (!CFdone)
					{
						PrintToChatAll(MESS, "Chicken Fight Gun Attack Abort", attacker, target, weapon);
						if (GetConVarInt(sm_hosties_lr_beacon) == 1)
						{
							ServerCommand("sm_beacon #%d", GetClientUserId(target));
							ServerCommand("sm_beacon #%d", GetClientUserId(attacker));
						}
						GivePlayerItem(target, "weapon_knife");
						GivePlayerItem(attacker, "weapon_knife");
					}
				}
			}

			LRinprogress = false;
		}
	}
	else if ( (attacker != 0) && (target != 0) && (GetClientTeam(attacker) == 2) && (GetClientTeam(target) == 3) ) // if attacker was a terrorist and target was a counter-terrorist
	{
		if (!in_array(rebels, attacker))
		{
			if ( (!LRinprogress) || ((LRinprogress) && (attacker != LRprogressplayer1) && (attacker != LRprogressplayer2)) )
			{
				if (GetConVarInt(sm_hosties_announce_rebel) == 1)
					PrintToChatAll(MESS, "New Rebel", attacker);

				rebels[rebelscount] = attacker;
				if ( (GetConVarInt(sm_hosties_rebel_color1) != 255) || (GetConVarInt(sm_hosties_rebel_color2) != 255) || (GetConVarInt(sm_hosties_rebel_color3) != 255) )
				{
					SetEntityRenderMode(attacker, RENDER_TRANSCOLOR);
					SetEntityRenderColor(attacker, GetConVarInt(sm_hosties_rebel_color1), GetConVarInt(sm_hosties_rebel_color2), GetConVarInt(sm_hosties_rebel_color3), 255);
				}
				rebelscount++;
			}
		}
	}
	else if ( (attacker != 0) && (target != 0) && (GetClientTeam(attacker) == 3) && (GetClientTeam(target) == 2) ) // if attacker was a counter-terrorist and target was a terrorist
	{
		if (GetConVarInt(sm_hosties_announce_attack) == 1)
			if ( (!in_array(rebels, target)) && (LRinprogress == false) || ((LRinprogress == true) && (attacker != LRprogressplayer1) && (attacker != LRprogressplayer2)) )
			{
				PrintToChatAll(MESS, "Freeattack", attacker, target);
				if (!StrEqual(freekill_sound, "-1"))
				{
					EmitSoundToAll(freekill_sound);
				}
			}
	}

}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ev_attacker = GetEventInt(event, "attacker");
	new ev_target = GetEventInt(event, "userid");
	new attacker = GetClientOfUserId(ev_attacker);
	new target = GetClientOfUserId(ev_target);

	// check if the death had to do with a LR
	if ( (LRinprogress == true) && (target != CFloser) && (attacker == LRprogressplayer1 || attacker == LRprogressplayer2 || attacker == 0 || attacker == target) && (target == LRprogressplayer1 || target == LRprogressplayer2) )
	{

		//PrintToChatAll("\x04[SM_Hosties DEBUG] \x01LR-DEATH - attacker: %d (%N), target: %d (%N)", attacker, attacker, target, target);

		// de-beacon the winning player and set vars
		if (GetConVarInt(sm_hosties_lr_beacon) == 1)
		{
			if ( (attacker != 0) && (attacker != target) )
			{
				ServerCommand("sm_beacon #%d", GetClientUserId(attacker));
			}
			else
			{
				if (target == LRprogressplayer1)
				{
					ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));
				}
				else
				{
					ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));
				}
			}
		}
		if ( (LRtype == 2) && (lr_gt_mode != 0) )
		{
			SetEntityRenderColor(GTdeagle1, 255, 255, 255);
			SetEntityRenderMode(GTdeagle1, RENDER_NORMAL);
			SetEntityRenderColor(GTdeagle2, 255, 255, 255);
			SetEntityRenderMode(GTdeagle2, RENDER_NORMAL);
		}
		
		LRinprogress = false;

		S4Slastshot = 0;

		GTp1dropped = false;
		GTp2dropped = false;
	}
	// check if the victim was the loser of a chicken fight
	else if ( (LRinprogress == true) && (target == CFloser) )
	{
		LRinprogress = false;
		CFdone = false;
		CFloser = 0;
	}
	// check if the victim was a LR-player and the attacker was NOT a LR-player
	else if ( (LRinprogress == true) && (target == LRprogressplayer1 || target == LRprogressplayer2) && ((attacker != LRprogressplayer1) && (attacker != LRprogressplayer2)) && (attacker != 0) )
	{

		// set vars
		LRinprogress = false;

		S4Slastshot = 0;

		GTp1dropped = false;
		GTp2dropped = false;
		CFdone = false;
		CFloser = 0;

		if (GetConVarInt(sm_hosties_lr_p_killed_action) == 1)
		{
			ForcePlayerSuicide(attacker);
			PrintToChatAll(MESS, "Non LR Kill LR Slay", attacker, target);
		}
		else
		{
			PrintToChatAll(MESS, "Non LR Kill LR Abort", attacker, target);
		}

		// de-beacon if necessary
		if (GetConVarInt(sm_hosties_lr_beacon) == 1)
		{
			if (target == LRprogressplayer1)
			{
				ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));
			}
			else
			{
				ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));
			}
		}
	}
	// check if the victim was a rebelling T
	else if ( (in_array(rebels, target)) && (attacker != 0) )
	{
		if (GetConVarInt(sm_hosties_announce_rebel_down) == 1)
			PrintToChatAll(MESS, "Rebel Kill", attacker, target);
	}

	if ( (GetConVarInt(sm_hosties_announce_lr) == 1) && (GetConVarInt(sm_hosties_lr) == 1) && (LRannounced == false) ) // if LR should be announced and LR is enabled
	{
		new Ts = 0;
		new CTs = 0;		
		for(new i=1; i <= GetMaxClients(); i++)
		{
			if ( (IsClientConnected(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i)) )
			{
				if (GetClientTeam(i) == 2)
					Ts++;
				else if (GetClientTeam(i) == 3)
					CTs++;
			}
		}
		if ( (Ts == GetConVarInt(sm_hosties_lr_ts_max)) && (CTs > 0) )
		{
			PrintToChatAll(MESS, "LR Available");
			LRannounced = true;
			if (!StrEqual(lr_sound, "-1"))
			{
				EmitSoundToAll(lr_sound);
			}
		}
	}
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ev_client = GetEventInt(event, "userid");
	new client = GetClientOfUserId(ev_client);
	if ( (LRinprogress == true) && ((client == LRprogressplayer1) || (client == LRprogressplayer2)) )
	{
		// set vars
		LRinprogress = false;

		S4Slastshot = 0;

		GTp1dropped = false;
		GTp2dropped = false;
		CFdone = false;
		CFloser = 0;

		if (GetConVarInt(sm_hosties_lr_beacon) == 1)
		{
			if (client == LRprogressplayer1)
			{
				ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));
			}
			else
			{
				ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));
			}
		}

		if ( (LRtype == 2) && (lr_gt_mode != 0) )
		{
			SetEntityRenderColor(GTdeagle1, 255, 255, 255);
			SetEntityRenderMode(GTdeagle1, RENDER_NORMAL);
			SetEntityRenderColor(GTdeagle2, 255, 255, 255);
			SetEntityRenderMode(GTdeagle2, RENDER_NORMAL);
		}

		PrintToChatAll(MESS, "LR Player Disconnect", client);
	}
}

public Action:CFchecker(Handle:timer)
{
	if ( (LRinprogress == true) && (CFdone != true) && (LRtype == 3) ) // NEW chicken fight game script :o
	{
		new p1EntityBelow = GetEntDataEnt2(LRprogressplayer1, FindSendPropOffs("CBasePlayer", "m_hGroundEntity"));
		new p2EntityBelow = GetEntDataEnt2(LRprogressplayer2, FindSendPropOffs("CBasePlayer", "m_hGroundEntity"));
		if (p1EntityBelow == LRprogressplayer2) // p1 is standing on p2
		{
			if (GetConVarInt(sm_hosties_lr_cf_slay) == 1)
			{
				PrintToChatAll(MESS, "Chicken Fight Win And Slay", LRprogressplayer1, LRprogressplayer2);
				ForcePlayerSuicide(LRprogressplayer2);
				if (GetConVarInt(sm_hosties_lr_beacon) == 1)
					ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));

				LRinprogress = false;
				GivePlayerItem(LRprogressplayer1, "weapon_knife");
			}
			else
			{
				CFdone = true;
				CFloser = LRprogressplayer2;
				PrintToChatAll(MESS, "Chicken Fight Win", LRprogressplayer1);
				PrintToChat(LRprogressplayer1, MESS, "Chicken Fight Kill Loser", LRprogressplayer2);
				if (GetConVarInt(sm_hosties_lr_beacon) == 1)
				{
					ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));
					ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));
				}

				GivePlayerItem(LRprogressplayer1, "weapon_knife");

				if ( (GetConVarInt(sm_hosties_lr_cf_loser_color1) != 255) || (GetConVarInt(sm_hosties_lr_cf_loser_color2) != 255) || (GetConVarInt(sm_hosties_lr_cf_loser_color3) != 255) )
				{
					CreateTimer(0.5, SetLoserColor, LRprogressplayer2, TIMER_REPEAT);
				}
			}

		}
		else if (p2EntityBelow == LRprogressplayer1) // p2 is standing on p1
		{
			if (GetConVarInt(sm_hosties_lr_cf_slay) == 1)
			{
				PrintToChatAll(MESS, "Chicken Fight Win And Slay", LRprogressplayer2, LRprogressplayer1);
				ForcePlayerSuicide(LRprogressplayer1);
				if (GetConVarInt(sm_hosties_lr_beacon) == 1)
					ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));

				LRinprogress = false;
				GivePlayerItem(LRprogressplayer2, "weapon_knife");
			}
			else
			{
				CFdone = true;
				CFloser = LRprogressplayer1;
				PrintToChatAll(MESS, "Chicken Fight Win", LRprogressplayer2);
				PrintToChat(LRprogressplayer2, MESS, "Chicken Fight Kill Loser", LRprogressplayer1);
				if (GetConVarInt(sm_hosties_lr_beacon) == 1)
				{
					ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));
					ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));
				}

				GivePlayerItem(LRprogressplayer2, "weapon_knife");

				if ( (GetConVarInt(sm_hosties_lr_cf_loser_color1) != 255) || (GetConVarInt(sm_hosties_lr_cf_loser_color2) != 255) || (GetConVarInt(sm_hosties_lr_cf_loser_color3) != 255) )
				{
					CreateTimer(0.5, SetLoserColor, LRprogressplayer1, TIMER_REPEAT);
				}
			}

		}
	}
	else
	{
		return Plugin_Stop;
		//CloseHandle(timer);
	}

	return Plugin_Continue;
}

public OnGameFrame()
{
	if (s4s_doubleshot_action != 0)
	{
		if ((LRinprogress == true) && (LRtype == 1))
		{
			if (GetClientButtons(LRprogressplayer1) & IN_ATTACK)
			{
				new String:weapon[32];
				GetClientWeapon(LRprogressplayer1, weapon, sizeof(weapon));
				if (StrEqual(weapon, "weapon_deagle"))
				{
					if (S4Sp1latestammo == 0)
					S4Sp1latestammo = 50;

					new iWeapon = GetEntDataEnt2(LRprogressplayer1, FindSendPropInfo("CCSPlayer", "m_hActiveWeapon"));
					new currentammo = GetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"));
					if (currentammo < S4Sp1latestammo)
					{
						if (S4Slastshot == LRprogressplayer1)
						{
							if (s4s_doubleshot_action == 2)
							{
								ForcePlayerSuicide(LRprogressplayer1);
								PrintToChatAll(MESS, "S4S Double Shot Slay", LRprogressplayer1);
								if (GetConVarInt(sm_hosties_lr_beacon) == 1)
									ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));
							}
							else
							{
								PrintToChatAll(MESS, "S4S Double Shot Abort", LRprogressplayer1);
								if (GetConVarInt(sm_hosties_lr_beacon) == 1)
								{
									ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));
									ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));
								}
							}

							LRinprogress = false;
							S4Slastshot = 0;
							S4Sp1latestammo = 0;
							S4Sp2latestammo = 0;
						}
						else
						{
							S4Sp1latestammo = currentammo;
							S4Slastshot = LRprogressplayer1;
							if (GetConVarInt(sm_hosties_lr_s4s_shot_taken) == 1)
								PrintToChatAll(MESS, "S4S Shot Taken", LRprogressplayer1);
						}
					}
				}
			}

			if (GetClientButtons(LRprogressplayer2) & IN_ATTACK)
			{
				new String:weapon[32];
				GetClientWeapon(LRprogressplayer2, weapon, sizeof(weapon));
				if (StrEqual(weapon, "weapon_deagle"))
				{
					if (S4Sp2latestammo == 0)
					S4Sp2latestammo = 50;

					new iWeapon = GetEntDataEnt2(LRprogressplayer2, FindSendPropInfo("CCSPlayer", "m_hActiveWeapon"));
					new currentammo = GetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"));
					if (currentammo < S4Sp2latestammo)
					{
						if (S4Slastshot == LRprogressplayer2)
						{
							if (s4s_doubleshot_action == 2)
							{
								ForcePlayerSuicide(LRprogressplayer2);
								PrintToChatAll(MESS, "S4S Double Shot Slay", LRprogressplayer2);
								if (GetConVarInt(sm_hosties_lr_beacon) == 1)
									ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));
							}
							else
							{
								PrintToChatAll(MESS, "S4S Double Shot Abort", LRprogressplayer2);
								if (GetConVarInt(sm_hosties_lr_beacon) == 1)
								{
									ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));
									ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));
								}
							}

							LRinprogress = false;
							S4Slastshot = 0;
							S4Sp1latestammo = 0;
							S4Sp2latestammo = 0;
						}
						else
						{
							S4Sp2latestammo = currentammo;
							S4Slastshot = LRprogressplayer2;
							if (GetConVarInt(sm_hosties_lr_s4s_shot_taken) == 1)
								PrintToChatAll(MESS, "S4S Shot Taken", LRprogressplayer2);
						}
					}
				}
			}
		}
	}

/*	if ( (LRinprogress == true) && (LRtype == 1) && (s4s_doubleshot_action != 0) )
	{
		if (GetClientButtons(LRprogressplayer1) & IN_ATTACK)
			S4Sp1attack = true;
		else
			S4Sp1attack = false;

		if (GetClientButtons(LRprogressplayer2) & IN_ATTACK)
			S4Sp2attack = true;
		else
			S4Sp2attack = false;
	}*/
}

public Action:SetLoserColor(Handle:timer, any:client)
{
	if (IsPlayerAlive(client))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, GetConVarInt(sm_hosties_lr_cf_loser_color1), GetConVarInt(sm_hosties_lr_cf_loser_color2), GetConVarInt(sm_hosties_lr_cf_loser_color3), 255);
	}
	else
	{
		return Plugin_Stop;
		//CloseHandle(timer);
	}

	return Plugin_Continue;
}

public GetPlayerName(any:target_playerClient, String:name[], maxlength)
{
	new String:target_playerName[20];
	GetClientName(target_playerClient,target_playerName,sizeof(target_playerName));
	strcopy(name, maxlength, target_playerName);
}

public in_array(any:haystack[], needle)
{
	for(new i = 0; i < 64; i++)
	{
		if (haystack[i] == needle)
		{
			return true;
		}
	}
	return false;
}

public Action:Command_LastRequest(client, args)
{
	if (GetConVarInt(sm_hosties_lr) == 1)
	{
		if (!LRinprogress)
		{
			if (IsPlayerAlive(client) && (GetClientTeam(client) == 2))
			{
				if ( (in_array(rebels, client)) && (GetConVarInt(sm_hosties_lr_rebel_mode) == 0) )
				{
					PrintToChat(client, MESS, "LR Rebel Not Allowed");
				}
				else
				{
					// check the number of terrorists still alive
					new Ts = 0;
					new CTs = 0;		
					for(new i=1; i <= GetMaxClients(); i++)
					{
						if ( (IsClientConnected(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i)) )
						{
							if (GetClientTeam(i) == 2)
								Ts++;
							else if (GetClientTeam(i) == 3)
								CTs++;
						}
					}

					if (Ts <= GetConVarInt(sm_hosties_lr_ts_max))
					{
						if (CTs > 0)
						{
							new Handle:menu = CreateMenu(MainHandler);
							new String:lrchoose[32];
							Format(lrchoose, sizeof(lrchoose), "%T", "LR Choose", client);
							SetMenuTitle(menu, lrchoose);

							if (GetConVarInt(sm_hosties_lr_kf_enable) == 1)
							{
								new String:lr_kf[32];
								Format(lr_kf, sizeof(lr_kf), "%T", "Knife Fight", client);
								AddMenuItem(menu, "knife", lr_kf);
							}
							if (GetConVarInt(sm_hosties_lr_s4s_enable) == 1)
							{
								new String:lr_s4s[32];
								Format(lr_s4s, sizeof(lr_s4s), "%T", "Shot4Shot", client);
								AddMenuItem(menu, "s4s", lr_s4s);
							}
							if (GetConVarInt(sm_hosties_lr_gt_enable) == 1)
							{
								new String:lr_gt[32];
								Format(lr_gt, sizeof(lr_gt), "%T", "Gun Toss", client);
								AddMenuItem(menu, "guntoss", lr_gt);
							}
							if (GetConVarInt(sm_hosties_lr_cf_enable) == 1)
							{
								new String:lr_cf[32];
								Format(lr_cf, sizeof(lr_cf), "%T", "Chicken Fight", client);
								AddMenuItem(menu, "chickenfight", lr_cf);
							}

							SetMenuExitButton(menu, true);
							DisplayMenu(menu, client, 20);
						}
						else
						{
							PrintToChat(client, MESS, "No CTs Alive");
						}
					}
					else
					{
						PrintToChat(client, MESS, "Too Many Ts");
					}
				}
			}
			else
			{
				PrintToChat(client, MESS, "Not Alive Or In Wrong Team");
			}
		}
		else
		{
			PrintToChat(client, MESS, "Another LR In Progress");
		}
	}
	else
	{
		PrintToChat(client, MESS, "LR Disabled");
	}

	return Plugin_Handled;
}

public MainHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (!LRinprogress)
		{
			if (IsPlayerAlive(param1) && (GetClientTeam(param1) == 2))
			{
				if (param2 == 0 || param2 == 1 || param2 == 2 || param2 == 3)
				{
					new Handle:playermenu = CreateMenu(MainPlayerHandler);
					new String:chooseplayer[32];
					Format(chooseplayer, sizeof(chooseplayer), "%T", "Choose A Player", param1);
					SetMenuTitle(playermenu, chooseplayer);
					new playeri = 0;
					for(new i=1; i <= GetMaxClients(); i++)
					{
						if ( (IsClientConnected(i)) && (IsClientInGame(i)) )
						if ( (IsPlayerAlive(i)) && (GetClientTeam(i) == 3) ) // if player is alive and in CT
						{
							new String:clientname[32];
							GetPlayerName(i, clientname, 32);
							AddMenuItem(playermenu, "player", clientname); // add to the menu
							LRplayers[playeri] = i;
							playeri++;
						}
					}
					if (playeri == 0)
					{
						PrintToChat(param1, MESS, "No CTs Alive");
						CloseHandle(playermenu);
					}
					else
					{
						SetMenuExitButton(playermenu, true);
						DisplayMenu(playermenu, param1, 20);
						LRchoises[(param1-1)] = GetArrayCell(LRsenabled, param2);
					}
				}
				else
				{
					PrintToChat(param1, "\x04[SM_Hosties DEBUG] \x01param2 doesn't contain 0, 1, 2 or 3.");
				}
			}
			else
			{
				PrintToChat(param1, MESS, "Not Alive Or In Wrong Team");
			}
		}
		else
		{
			PrintToChat(param1, MESS, "Another LR In Progress");
		}
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.", param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MainPlayerHandler(Handle:playermenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (!LRinprogress)
		{
			if (IsPlayerAlive(param1) && (GetClientTeam(param1) == 2))
			{
				if (IsPlayerAlive(LRplayers[param2]) && (GetClientTeam(LRplayers[param2]) == 3))
				{

					// check the number of terrorists still alive
					new Ts = 0;
					new CTs = 0;		
					for(new i=1; i <= GetMaxClients(); i++)
					{
						if ( (IsClientConnected(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i)) )
						{
							if (GetClientTeam(i) == 2)
								Ts++;
							else if (GetClientTeam(i) == 3)
								CTs++;
						}
					}

					if (Ts <= GetConVarInt(sm_hosties_lr_ts_max))
					{
						if (CTs > 0)
						{
							if ( (!in_array(rebels, param1)) || (GetConVarInt(sm_hosties_lr_rebel_mode) == 2) )
							{
								LRinprogress = true;
								LRprogressplayer1 = param1;
								LRprogressplayer2 = LRplayers[param2];
								LRtype = LRchoises[(param1-1)];

								launchLR(LRtype);
							}
							else
							{
								// if rebel, send a menu to the CT asking for permission
								new Handle:askmenu = CreateMenu(MainAskHandler);
								new String:lrname[32];
								switch (LRchoises[(param1-1)])
								{
									case 0:
									{
										Format(lrname, sizeof(lrname), "%T", "Knife Fight", LRplayers[param2]);
									}
									case 1:
									{
										Format(lrname, sizeof(lrname), "%T", "Shot4Shot", LRplayers[param2]);
									}
									case 2:
									{
										Format(lrname, sizeof(lrname), "%T", "Gun Toss", LRplayers[param2]);
									}
									case 3:
									{
										Format(lrname, sizeof(lrname), "%T", "Chicken Fight", LRplayers[param2]);
									}
								}

								new String:asklr[128];
								Format(asklr, sizeof(asklr), "%T", "Rebel Ask CT For LR", LRplayers[param2], param1, lrname);
								SetMenuTitle(askmenu, asklr, param1, lrname);

								new String:yes[8];
								new String:no[8];
								Format(yes, sizeof(yes), "%T", "Yes", LRplayers[param2]);
								Format(no, sizeof(no), "%T", "No", LRplayers[param2]);
								AddMenuItem(askmenu, "yes", yes);
								AddMenuItem(askmenu, "no", no);

								LRaskcaller = param1;
								SetMenuExitButton(askmenu, true);
								DisplayMenu(askmenu, LRplayers[param2], 6);

								PrintToChat(param1, MESS, "Asking For Permission", LRplayers[param2]);
							}
						}
						else
						{
							PrintToChat(param1, MESS, "No CTs Alive");
						}
					}
					else
					{
						PrintToChat(param1, MESS, "Too Many Ts");
					}
				}
				else
				{
					PrintToChat(param1, MESS, "Target Is Not Alive Or In Wrong Team");
				}
			}
			else
			{
				PrintToChat(param1, MESS, "Not Alive Or In Wrong Team");
			}
		}
		else
		{
			PrintToChat(param1, MESS, "Another LR In Progress");
		}
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.", param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(playermenu);
	}
}

public MainAskHandler(Handle:askmenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (!LRinprogress)
		{
			if (IsPlayerAlive(LRaskcaller))
			{
				if (IsPlayerAlive(param1) && (GetClientTeam(param1) == 3))
				{
					if (param2 == 0)
					{
						LRinprogress = true;
						LRprogressplayer1 = LRaskcaller;
						LRprogressplayer2 = param1;
						LRtype = LRchoises[(LRaskcaller-1)];

						launchLR(LRtype);
					}
					else
					{
						PrintToChat(LRaskcaller, MESS, "Declined LR Request", param1);
					}
				}
				else
				{
					PrintToChat(param1, MESS, "Not Alive Or In Wrong Team");
				}
			}
			else
			{
				PrintToChat(param1, MESS, "LR Partner Died");
			}
		}
		else
		{
			PrintToChat(param1, MESS, "Too Slow Another LR In Progress");
		}
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToChat(LRaskcaller, MESS, "LR Request Decline Or Too Long", param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(askmenu);
	}
}

launchLR(type)
{
	switch (type)
	{
		case 0:		// knife fight
		{
			// strip weapons
			new wepIdx;
			for (new i = 0; i < 4; i++)
			{
				if ((wepIdx = GetPlayerWeaponSlot(LRprogressplayer1, i)) != -1)
				{
					RemovePlayerItem(LRprogressplayer1, wepIdx);
					RemoveEdict(wepIdx);
				}
				if ((wepIdx = GetPlayerWeaponSlot(LRprogressplayer2, i)) != -1)
				{
					RemovePlayerItem(LRprogressplayer2, wepIdx);
					RemoveEdict(wepIdx);
				}
			}

			// set HP
			SetEntData(LRprogressplayer1, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);
			SetEntData(LRprogressplayer2, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);

			// give knives
			GivePlayerItem(LRprogressplayer1, "weapon_knife");
			GivePlayerItem(LRprogressplayer2, "weapon_knife");

			// beacon players
			if (GetConVarInt(sm_hosties_lr_beacon) == 1)
			{
				ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));
				ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));
			}

			// announce LR
			new String:lrname[32];
			Format(lrname, sizeof(lrname), "%T", "Knife Fight", LRprogressplayer2);
			PrintToChatAll(MESS, "LR Chosen Start", LRprogressplayer1, lrname, LRprogressplayer2);
		}

		case 1:		// s4s
		{
			// strip weapons
			new wepIdx;
			for (new i = 0; i < 4; i++)
			{
				if ((wepIdx = GetPlayerWeaponSlot(LRprogressplayer1, i)) != -1)
				{
					RemovePlayerItem(LRprogressplayer1, wepIdx);
					RemoveEdict(wepIdx);
				}
				if ((wepIdx = GetPlayerWeaponSlot(LRprogressplayer2, i)) != -1)
				{
					RemovePlayerItem(LRprogressplayer2, wepIdx);
					RemoveEdict(wepIdx);
				}
			}

			S4Sp1latestammo = 0;
			S4Sp2latestammo = 0;
			S4Slastshot = 0;

			// give knives and deagles
			GivePlayerItem(LRprogressplayer1, "weapon_knife");
			GivePlayerItem(LRprogressplayer2, "weapon_knife");
			GivePlayerItem(LRprogressplayer1, "weapon_deagle");
			GivePlayerItem(LRprogressplayer2, "weapon_deagle");

			// set ammo
			new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
			SetEntData(LRprogressplayer1, ammoOffset+(1*4), 0);
			new iWeapon = GetEntDataEnt2(LRprogressplayer1, FindSendPropInfo("CCSPlayer", "m_hActiveWeapon"));
			SetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 50);

			SetEntData(LRprogressplayer2, ammoOffset+(1*4), 0);
			iWeapon = GetEntDataEnt2(LRprogressplayer2, FindSendPropInfo("CCSPlayer", "m_hActiveWeapon"));
			SetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 50);

			// set HP
			SetEntData(LRprogressplayer1, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);
			SetEntData(LRprogressplayer2, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);

			// beacon players
			if (GetConVarInt(sm_hosties_lr_beacon) == 1)
			{
				ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));
				ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));
			}

			// announce LR
			new String:lrname[32];
			Format(lrname, sizeof(lrname), "%T", "Shot4Shot", LRprogressplayer2);
			PrintToChatAll(MESS, "LR Chosen Start", LRprogressplayer1, lrname, LRprogressplayer2);
		}

		case 2:		// gun toss
		{

			GTp1dropped = false;
			GTp2dropped = false;
			GTcheckerstarted = false;
			GTp1done = false;
			GTp2done = false;
			GTp1cheat = false;
			GTp2cheat = false;

			new Float:resetTo[] = {0.00, 0.00, 0.00};
			GTdeagle1lastpos = resetTo;
			GTdeagle2lastpos = resetTo;

			// strip weapons
			new wepIdx;
			for (new i = 0; i < 4; i++)
			{
				if ((wepIdx = GetPlayerWeaponSlot(LRprogressplayer1, i)) != -1)
				{
					RemovePlayerItem(LRprogressplayer1, wepIdx);
					RemoveEdict(wepIdx);
				}
				if ((wepIdx = GetPlayerWeaponSlot(LRprogressplayer2, i)) != -1)
				{
					RemovePlayerItem(LRprogressplayer2, wepIdx);
					RemoveEdict(wepIdx);
				}
			}

			// give knives and deagles
			GivePlayerItem(LRprogressplayer1, "weapon_knife");
			GivePlayerItem(LRprogressplayer2, "weapon_knife");
			GTdeagle1 = GivePlayerItem(LRprogressplayer1, "weapon_deagle");
			GTdeagle2 = GivePlayerItem(LRprogressplayer2, "weapon_deagle");

			// set ammo (Clip2) 0
			new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
			SetEntData(LRprogressplayer1, ammoOffset+(1*4), 0);
			SetEntData(LRprogressplayer2, ammoOffset+(1*4), 0);

			if (lr_gt_mode != 0)
			{
				new iWeapon = GetEntDataEnt2(LRprogressplayer1, FindSendPropInfo("CCSPlayer", "m_hActiveWeapon"));
				SetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 0);
				iWeapon = GetEntDataEnt2(LRprogressplayer2, FindSendPropInfo("CCSPlayer", "m_hActiveWeapon"));
				SetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 0);
			}

			// beacon players
			if (GetConVarInt(sm_hosties_lr_beacon) == 1)
			{
				ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));
				ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));
			}

			if ( (LRtype == 2) && (lr_gt_mode != 0) )
			{
				SetEntityRenderMode(GTdeagle1, RENDER_TRANSCOLOR);
				SetEntityRenderColor(GTdeagle1, 255, 0, 0);
				SetEntityRenderMode(GTdeagle2, RENDER_TRANSCOLOR);
				SetEntityRenderColor(GTdeagle2, 0, 0, 255);
			}

			// announce LR
			new String:lrname[32];
			Format(lrname, sizeof(lrname), "%T", "Gun Toss", LRprogressplayer2);
			PrintToChatAll(MESS, "LR Chosen Start", LRprogressplayer1, lrname, LRprogressplayer2);

		}

		case 3:		// chicken fight
		{
			CFdone = false;

			// strip weapons
			new wepIdx;
			for (new i = 0; i < 4; i++)
			{
				if ((wepIdx = GetPlayerWeaponSlot(LRprogressplayer1, i)) != -1)
				{
					RemovePlayerItem(LRprogressplayer1, wepIdx);
					RemoveEdict(wepIdx);
				}
				if ((wepIdx = GetPlayerWeaponSlot(LRprogressplayer2, i)) != -1)
				{
					RemovePlayerItem(LRprogressplayer2, wepIdx);
					RemoveEdict(wepIdx);
				}
			}

			// beacon players
			if (GetConVarInt(sm_hosties_lr_beacon) == 1)
			{
				ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer1));
				ServerCommand("sm_beacon #%d", GetClientUserId(LRprogressplayer2));
			}

			// announce LR
			new String:lrname[32];
			Format(lrname, sizeof(lrname), "%T", "Chicken Fight", LRprogressplayer2);
			PrintToChatAll(MESS, "LR Chosen Start", LRprogressplayer1, lrname, LRprogressplayer2);

			CreateTimer(0.3, CFchecker, INVALID_HANDLE, TIMER_REPEAT);
		}

	}
}

public Action:Command_CheckPlayers(client, args)
{
	if (GetConVarInt(sm_hosties_checkplayers_enable) == 1)
	{
		if (IsPlayerAlive(client))
		{
			new listrebels[rebelscount];
			new realrebelscount = 0;
			for(new i = 0; i < rebelscount; i++)
			{
				if ( (IsClientConnected(rebels[i])) && (IsClientInGame(rebels[i])) && (IsPlayerAlive(rebels[i])) )
				{
					listrebels[realrebelscount] = rebels[i];
					realrebelscount++;
				}
			}

			if (realrebelscount < 1)
			{
				PrintToChat(client, MESS, "No Rebels ATM");
			}
			else
			{
				new Handle:checkplayersmenu = CreateMenu(Handler_DoNothing);
				new String:rebellingterrorists[32];
				Format(rebellingterrorists, sizeof(rebellingterrorists), "%T", "Rebelling Terrorists", client);
				SetMenuTitle(checkplayersmenu, rebellingterrorists);
				new String:item[64];
				for(new i = 0; i < realrebelscount; i++)
				{
					GetClientName(listrebels[i], item, sizeof(item));
					AddMenuItem(checkplayersmenu, "player", item);
				}
				SetMenuExitButton(checkplayersmenu, true);
				DisplayMenu(checkplayersmenu, client, MENU_TIME_FOREVER);
			}
		}
	}
	else
	{
		PrintToChatAll(MESS, "CheckPlayers CMD Disabled");
	}

	return Plugin_Handled;
}

public Action:Command_Rules(client, args)
{
	if (GetConVarInt(sm_hosties_rules_enable) == 1)
	{
		new String:file[256];
		BuildPath(Path_SM, file, 255, "configs/hosties_rules.ini");
		new Handle:fileh = OpenFile(file, "r");
		if (fileh != INVALID_HANDLE)
		{
			new Handle:rulesmenu = CreateMenu(Handler_DoNothing);
			SetMenuTitle(rulesmenu, "%t", "Server Rules");
			new String:buffer[256];

			while(ReadFileLine(fileh, buffer, sizeof(buffer)))
			{
				AddMenuItem(rulesmenu, "rule", buffer);
			}

			SetMenuExitButton(rulesmenu, true);
			DisplayMenu(rulesmenu, client, MENU_TIME_FOREVER);
		}
	}

	return Plugin_Handled;
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}