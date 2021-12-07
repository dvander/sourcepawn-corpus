/*
 so here 4 the "common zombies",
 ..cuz i hate the specials zombies.."director_no_specials 1"
v1.4
-added xls to the web http://spreadsheets.google.com/ccc?key=0AvePZRl3b_qmdDFTZHRSSFliRkFYRUVEY1RTbVdYR2c&hl=en
-fixed min/max intervals
v1.3
- added difficulty vote for survival mode trigger !czv
- added survival mode (with and without/director_no_specials 1)
v1.2
- fixed for singleplayer mode, the triggers
- factor +0.x (didnt know how its worx correct)
- fixed compiling bugs (float)
v1.1
- added specials zombies (hunter,tank,...) hp calculations/support
v1.0
- pimp up 2 v1.0, no bugs founded
v0.9
-add "l4d_cZadifnfo" prints infos to player chat
v0.8
-add based common zombie setting 4 changing
v0.7
-mass join/left/spawning/- timer at the recalc 
v0.6 
-ingame difficult vote (passed hook) recalcing
-join/left player/bots
-change all cvars "l4d_cZa*"
-remove z_pounce_damage no working with commons (static? at easy,hard,..,game mode ?)
-add info trigger !cZadif same info as !cz
 v0.5 
 -puplic
*/
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.4"


public Plugin:myinfo =
{
	name = "[L4D2] Common Autodifficulty",
	author = "dYZER",
	description = "Automatic controls common Zombies difficulty via players + (cvar)faktors",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=116684"
}

new String:l4d_cZadi_Mode[64];
new String:l4d_cZadi_cdify[64];
new String:l4d_cZadi_game[64];
new Handle:SpawnTimer = INVALID_HANDLE;
new Handle:l4d_cZadif;
new Handle:l4d_cZadifnfo;
new Handle:l4d_cZadifbot;
new Handle:l4d_cZadifak1;
new Handle:l4d_cZadifak2;
new Handle:l4d_cZadifak3;
new Handle:l4d_cZadifak4;
new Handle:l4d_cZadinonhead;
new Handle:l4d_cZadifak0;
new Handle:l4d_cZadi_z_hp;
new Handle:l4d_cZadi_z_co_li;
new Handle:l4d_cZadi_z_bg_li;
new Handle:l4d_cZadi_z_nhd_ea;
new Handle:l4d_cZadi_z_nhd_ex;
new Handle:l4d_cZadi_z_nhd_ha;
new Handle:l4d_cZadi_z_nhd_no;
new Handle:l4d_cZadi_z_ainc_d;
new Handle:l4d_cZadi_z_mob_maxi_ea;
new Handle:l4d_cZadi_z_mob_mini_ea;
new Handle:l4d_cZadi_z_mob_maxi_no;
new Handle:l4d_cZadi_z_mob_mini_no;
new Handle:l4d_cZadi_z_mob_maxi_ha;
new Handle:l4d_cZadi_z_mob_mini_ha;
new Handle:l4d_cZadi_z_mob_maxi_ex;
new Handle:l4d_cZadi_z_mob_mini_ex;
new Handle:l4d_cZadi_z_mob_maxi_sk;
new Handle:l4d_cZadi_z_mob_mini_sk;
new Handle:l4d_cZadi_z_smob_maxs;
new Handle:l4d_cZadi_z_smob_mins;
new Handle:l4d_cZadi_z_mob_maxs;
new Handle:l4d_cZadi_z_mmob_max_int
new Handle:l4d_cZadi_z_mmob_min_int
new Handle:l4d_cZadi_z_mob_mins;
new Handle:l4d_cZadi_z_mob_f_s;
new Handle:l4d_cZadi_z_mob_m_s;
new Handle:l4d_cZadi_z_hunter_hp;
new Handle:l4d_cZadi_z_smoker_hp;
new Handle:l4d_cZadi_z_boomer_hp;
new Handle:l4d_cZadi_z_charger_hp;
new Handle:l4d_cZadi_z_splitter_hp;
new Handle:l4d_cZadi_z_jockey_hp;
new Handle:l4d_cZadi_z_witch_hp;
new Handle:l4d_cZadi_z_tank_hp;


public OnPluginStart()
{
	CreateConVar("l4d_cZadif_version", PLUGIN_VERSION, "[L4D/2] Common Zombies Autodifficulty", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	GetGameFolderName(l4d_cZadi_game, sizeof(l4d_cZadi_game));
	l4d_cZadifnfo = CreateConVar("l4d_cZadifnfo", "1", "infos to users anounce", FCVAR_PLUGIN|FCVAR_NOTIFY);
	l4d_cZadifbot = CreateConVar("l4d_cZadifbot", "1", "bots counting", FCVAR_PLUGIN);
	l4d_cZadif = CreateConVar("l4d_cZadif", "1", "Is the plugin enabled.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	l4d_cZadifak0 = CreateConVar("l4d_cZadifak0", "5.3", "current calc fak");
	l4d_cZadifak1 = CreateConVar("l4d_cZadifak1", "2.2", "easy faktor.", FCVAR_PLUGIN);
	l4d_cZadifak2 = CreateConVar("l4d_cZadifak2", "4.5", "normal faktor.", FCVAR_PLUGIN);
	l4d_cZadifak3 = CreateConVar("l4d_cZadifak3", "6.5", "hard faktor.", FCVAR_PLUGIN);
	l4d_cZadifak4 = CreateConVar("l4d_cZadifak4", "8.0", "expert faktor.", FCVAR_PLUGIN);
	l4d_cZadinonhead = CreateConVar("l4d_cZadinonhead", "1.0", "nonhead.");
	l4d_cZadi_z_hp = CreateConVar("l4d_cZadi_z_hp", "50", "z_health");
	l4d_cZadi_z_co_li = CreateConVar("l4d_cZadi_z_co_li", "30", "z_common_limit");
	l4d_cZadi_z_bg_li = CreateConVar("l4d_cZadi_z_bg_li", "20", "z_background_limit");
	l4d_cZadi_z_nhd_ea = CreateConVar("l4d_cZadi_z_nhd_ea", "2.0", "z_non_head_damage_factor_easy");
	l4d_cZadi_z_nhd_ex = CreateConVar("l4d_cZadi_z_nhd_ex", "0.5", "z_non_head_damage_factor_expert");
	l4d_cZadi_z_nhd_ha = CreateConVar("l4d_cZadi_z_nhd_ha", "0.75", "z_non_head_damage_factor_hard");
	l4d_cZadi_z_nhd_no = CreateConVar("l4d_cZadi_z_nhd_no", "1.0", "z_non_head_damage_factor_normal");
	l4d_cZadi_z_ainc_d = CreateConVar("l4d_cZadi_z_ainc_d", "10", "z_attack_incapacitated_damage");
	l4d_cZadi_z_mob_maxi_ea = CreateConVar("l4d_cZadi_z_mob_maxi_ea", "240", "z_mob_spawn_max_interval_easy");
	l4d_cZadi_z_mob_mini_ea = CreateConVar("l4d_cZadi_z_mob_mini_ea", "120", "z_mob_spawn_min_interval_easy");
	l4d_cZadi_z_mob_maxi_no = CreateConVar("l4d_cZadi_z_mob_maxi_no", "180", "z_mob_spawn_max_interval_normal");
	l4d_cZadi_z_mob_mini_no = CreateConVar("l4d_cZadi_z_mob_mini_no", "90", "z_mob_spawn_min_interval_normal");
	l4d_cZadi_z_mob_maxi_ha = CreateConVar("l4d_cZadi_z_mob_maxi_ha", "180", "z_mob_spawn_max_interval_hard");
	l4d_cZadi_z_mob_mini_ha = CreateConVar("l4d_cZadi_z_mob_mini_ha", "90", "z_mob_spawn_min_interval_hard");
	l4d_cZadi_z_mob_maxi_ex = CreateConVar("l4d_cZadi_z_mob_maxi_ex", "180", "z_mob_spawn_max_interval_expert");
	l4d_cZadi_z_mob_mini_ex = CreateConVar("l4d_cZadi_z_mob_mini_ex", "90", "z_mob_spawn_min_interval_expert");
	l4d_cZadi_z_mob_maxi_sk = CreateConVar("l4d_cZadi_z_mob_maxi_sk", "90", "z_skirmish_spawn_max_interval");
	l4d_cZadi_z_mob_mini_sk = CreateConVar("l4d_cZadi_z_mob_mini_sk", "45", "z_skirmish_spawn_min_interval");
	l4d_cZadi_z_smob_maxs = CreateConVar("l4d_cZadi_z_smob_maxs", "6", "z_skirmish_spawn_max_size");
	l4d_cZadi_z_smob_mins = CreateConVar("l4d_cZadi_z_smob_mins", "2", "z_skirmish_spawn_min_size");
	l4d_cZadi_z_mob_maxs = CreateConVar("l4d_cZadi_z_mob_maxs", "30", "z_mob_spawn_max_size");
	l4d_cZadi_z_mob_mins = CreateConVar("l4d_cZadi_z_mob_mins", "10", "z_mob_spawn_min_size");
	l4d_cZadi_z_mob_f_s = CreateConVar("l4d_cZadi_z_mob_f_s", "20", "z_mob_spawn_finale_size");
	l4d_cZadi_z_mob_m_s = CreateConVar("l4d_cZadi_z_mob_m_s", "50", "z_mega_mob_size");
	l4d_cZadi_z_mmob_max_int = CreateConVar("l4d_cZadi_z_mmob_max_int", "360", "z_mega_mob_max_interval");
	l4d_cZadi_z_mmob_min_int = CreateConVar("l4d_cZadi_z_mmob_min_int", "180", "z_mega_mob_min_interval");
	l4d_cZadi_z_hunter_hp = CreateConVar("l4d_cZadi_z_hunter_hp", "250", "z_hunter_health");
	l4d_cZadi_z_smoker_hp = CreateConVar("l4d_cZadi_z_smoker_hp", "250", "z_gas_health");
	l4d_cZadi_z_boomer_hp = CreateConVar("l4d_cZadi_z_boomer_hp", "50", "z_exploding_health");
	l4d_cZadi_z_charger_hp = CreateConVar("l4d_cZadi_z_charger_hp", "600", "z_charger_health");
	l4d_cZadi_z_splitter_hp = CreateConVar("l4d_cZadi_z_splitter_hp", "100", "z_spitter_health");
	l4d_cZadi_z_jockey_hp = CreateConVar("l4d_cZadi_z_jockey_hp", "325", "z_jockey_health");
	l4d_cZadi_z_witch_hp = CreateConVar("l4d_cZadi_z_witch_hp", "1000", "z_witch_health");
	l4d_cZadi_z_tank_hp = CreateConVar("l4d_cZadi_z_tank_hp", "4000", "z_tank_health");

	HookEvent("player_spawn", evtPlayerSpawn);
	HookEvent("vote_passed", EventVoteEnd);
	
	HookConVarChange(l4d_cZadif, czautodif_EnableDisable);
	HookConVarChange(l4d_cZadifbot, czbotcount_EnableDisable);
	
	RegConsoleCmd("sm_cz", czadac, "Get current cz info");
	RegConsoleCmd("sm_czv",czvmenu, "votemenu for Game difficulty supported 4 survival mode");
  	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	AutoExecConfig(true,"l4d_czadif");
}

l4d_faktr()
{
	if ((StrEqual(l4d_cZadi_cdify, "Easy")) || (StrEqual(l4d_cZadi_cdify, "1")) || (StrEqual(l4d_cZadi_cdify, "easy"))) SetConVarFloat(l4d_cZadifak0, GetConVarFloat(l4d_cZadifak1));
	if ((StrEqual(l4d_cZadi_cdify, "Normal")) || (StrEqual(l4d_cZadi_cdify, "2")) || (StrEqual(l4d_cZadi_cdify, "normal"))) SetConVarFloat(l4d_cZadifak0, GetConVarFloat(l4d_cZadifak2));
	if ((StrEqual(l4d_cZadi_cdify, "Hard")) || (StrEqual(l4d_cZadi_cdify, "3")) || (StrEqual(l4d_cZadi_cdify, "hard"))) SetConVarFloat(l4d_cZadifak0, GetConVarFloat(l4d_cZadifak3));
	if ((StrEqual(l4d_cZadi_cdify, "Impossible")) || (StrEqual(l4d_cZadi_cdify, "4")) || (StrEqual(l4d_cZadi_cdify, "impossible"))) SetConVarFloat(l4d_cZadifak0, GetConVarFloat(l4d_cZadifak4));
}
czdisplay()
{
	czautodif();

	if ((StrEqual(l4d_cZadi_cdify, "Easy")) || (StrEqual(l4d_cZadi_cdify, "1")) || (StrEqual(l4d_cZadi_cdify, "easy")))
	{
		l4d_cZadi_cdify = "Easy";
		SetConVarFloat(l4d_cZadinonhead, GetConVarFloat(FindConVar("z_non_head_damage_factor_easy")));
	}
	if ((StrEqual(l4d_cZadi_cdify, "Normal")) || (StrEqual(l4d_cZadi_cdify, "2")) || (StrEqual(l4d_cZadi_cdify, "normal")))
	{
		l4d_cZadi_cdify = "Normal";
		SetConVarFloat(l4d_cZadinonhead, GetConVarFloat(FindConVar("z_non_head_damage_factor_normal")));			
	}
	if ((StrEqual(l4d_cZadi_cdify, "Hard")) || (StrEqual(l4d_cZadi_cdify, "3")) || (StrEqual(l4d_cZadi_cdify, "hard")))
	{
		l4d_cZadi_cdify = "Hard";
		SetConVarFloat(l4d_cZadinonhead, GetConVarFloat(FindConVar("z_non_head_damage_factor_hard")));
	}
	if ((StrEqual(l4d_cZadi_cdify, "Impossible")) || (StrEqual(l4d_cZadi_cdify, "4")) || (StrEqual(l4d_cZadi_cdify, "impossible")))
	{
		l4d_cZadi_cdify = "Expert";
		SetConVarFloat(l4d_cZadinonhead, GetConVarFloat(FindConVar("z_non_head_damage_factor_expert")));
	}
	if (GetConVarFloat(FindConVar("l4d_cZadinonhead")) < 0.00)
	{
		SetConVarFloat(l4d_cZadinonhead, 0.00);
	}
	if (GetConVarInt(l4d_cZadifnfo) == 1) 
	{
		PrintToChatAll("\x04[cZadif] \x05Difficulty: \x04%s\x05 at Factor \x04%f\x05 | Mode: \x04%s\x05 | Counting players: \x04%i\x03", l4d_cZadi_cdify, GetConVarFloat(l4d_cZadifak0), l4d_cZadi_Mode, GetSUVInGamePlayerCount());
		PrintToChatAll("\x04[cZadif] \x05Zombie HP: \x04%i\x05 limit \x04%i | \x05nonhead Faktor \x04%f\x05 ", GetConVarInt(FindConVar("z_health")), GetConVarInt(FindConVar("z_common_limit")), GetConVarFloat(FindConVar("l4d_cZadinonhead")));
	}
}
public Action:czvmenu(client, args)
{
	czv();
	return Plugin_Handled;
}
czv()
{
	new Handle:czvv = CreateMenu(Handle_czv);
	SetMenuTitle(czvv, "Change Difficulty");
	AddMenuItem(czvv, "0", "Easy");
	AddMenuItem(czvv, "1", "Normal");
	AddMenuItem(czvv, "2", "Hard");
	AddMenuItem(czvv, "3", "Expert");
	SetMenuExitButton(czvv, false);
	VoteMenuToAll(czvv, 20);
}

public Handle_czv(Handle:czvv, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(czvv);
	} 
	else if (action == MenuAction_VoteEnd) {

			if (param1 == 0)
			{
			ServerCommand("z_difficulty 1");
			SpawnTimer = CreateTimer(5.0, czadtimer);
			}
			if (param1 == 1)
			{
			ServerCommand("z_difficulty 2");
			SpawnTimer = CreateTimer(5.0, czadtimer);
			}
			if (param1 == 2)
			{
			ServerCommand("z_difficulty 3");
			SpawnTimer = CreateTimer(5.0, czadtimer);
			}
			if (param1 == 3)
			{
			ServerCommand("z_difficulty 4");
			SpawnTimer = CreateTimer(5.0, czadtimer);
			}
	} else if (action == MenuAction_Cancel) {
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
}

public Action:Command_Say(client, args)
{
	if (!client) return Plugin_Continue;
	
	decl String:text[192];
	
	if (!GetCmdArgString(text, sizeof(text))) return Plugin_Continue;
	
	new startidx = 0;
	
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	if ((strcmp(text[startidx], "!cz", false) == 0) || (strcmp(text[startidx], "!cZadif", false) == 0))
	{
		czdisplay();
	}
	if ((strcmp(text[startidx], "!czv", false) == 0) || (strcmp(text[startidx], "!cZadifvote", false) == 0)) 
	{ 
		czv();
	}
	SetCmdReplySource(old);
	
	return Plugin_Continue;
}

public Action:czadac(client, args)
{
	czdisplay();
	return Plugin_Continue;
}
public czautodif_EnableDisable(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
	if (GetConVarInt(l4d_cZadif) == 1)
	{
		czautodif();
		if (GetConVarInt(l4d_cZadifnfo) == 1) PrintToChatAll("\x04[cZadif] \x03ON");
	}
	if (GetConVarInt(l4d_cZadif) == 0)
	{
		reset2standart();
		if (GetConVarInt(l4d_cZadifnfo) == 1) PrintToChatAll("\x04[cZadif]\x03OFF");
	}
}
public czbotcount_EnableDisable(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
	if (GetConVarInt(l4d_cZadifbot) == 1)
	{
		czautodif();
		if (GetConVarInt(l4d_cZadifnfo) == 1) PrintToChatAll("\x04[cZadif]\x05 Surv Bots counting \x04ON");
	}
	if (GetConVarInt(l4d_cZadifbot) == 0)
	{
		czautodif();
		if (GetConVarInt(l4d_cZadifnfo) == 1) PrintToChatAll("\x04[cZadif]\x05 Surv Bots counting \x04OFF");
	}
}

public Action:czadtimer(Handle:timer)
{
	czdisplay();
	SpawnTimer = INVALID_HANDLE;
}

public OnClientPutInServer(client)
{
	if (GetClientTeam(client) == 2)
	{
		if ((GetConVarInt(l4d_cZadifbot) == 1) && (SpawnTimer == INVALID_HANDLE)) SpawnTimer = CreateTimer(5.0, czadtimer);
		if (!IsFakeClient(client))
		{
			if (SpawnTimer == INVALID_HANDLE) SpawnTimer = CreateTimer(5.0, czadtimer);
			if (GetConVarInt(l4d_cZadifnfo) == 1) PrintToChatAll("\x04[cZadif] \x05Player \x04%N\x05 has entered the game. Zombies grow stronger!\x03", client);
	}
}
}
public OnClientDisconnect(client)
{
	if (GetClientTeam(client) == 2)
	{
		if (SpawnTimer == INVALID_HANDLE) SpawnTimer = CreateTimer(5.0, czadtimer);
		if ((!IsFakeClient(client)) && (GetConVarInt(l4d_cZadifnfo) == 1)) PrintToChatAll("\x04[cZadif] \x05Player \x04%N\x05 has left the game. Zombies weaken! \x03", client);
	}
}

public Action:evtPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ((GetConVarInt(l4d_cZadifbot) == 1) && (GetClientTeam(client) == 2) && (SpawnTimer == INVALID_HANDLE)) SpawnTimer = CreateTimer(7.0, czadtimer);
	if ((GetConVarInt(l4d_cZadifbot) == 0) && (GetClientTeam(client) == 2) && (SpawnTimer == INVALID_HANDLE) && (!IsFakeClient(client))) SpawnTimer = CreateTimer(7.0, czadtimer);
}
public EventVoteEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	SpawnTimer = CreateTimer(3.0, czadtimer);
}

GetSUVInGamePlayerCount()
{
	new count = 0;
	new countb = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if ((IsClientConnected(i)) && (GetClientTeam(i) == 2))
		{
			if (GetConVarInt(l4d_cZadifbot) == 1) count++;
			if ((GetConVarInt(l4d_cZadifbot) == 0) && (!IsFakeClient(i))) countb++;
		}
	}

	new countall = count + countb;
	return countall;
}
public czautodif()
{
	if (GetConVarInt(l4d_cZadif) == 1)
	{
		GetConVarString(FindConVar("z_difficulty"), l4d_cZadi_cdify, sizeof(l4d_cZadi_cdify));
		GetConVarString(FindConVar("mp_gamemode"), l4d_cZadi_Mode, sizeof(l4d_cZadi_Mode));	

		l4d_faktr();
		
		new plya = GetSUVInGamePlayerCount();
		new Float:fakt2 = GetConVarFloat(l4d_cZadifak0);

		new Float:z_health2 = GetConVarInt(l4d_cZadi_z_hp) + ((plya * fakt2) * fakt2);
		new Float:z_background_limit2 = GetConVarInt(l4d_cZadi_z_bg_li) + plya * fakt2;
		new Float:z_common_limit2 = GetConVarInt(l4d_cZadi_z_co_li) + plya * fakt2;
		
		new Float:z_attack_inc_damage2 = GetConVarInt(l4d_cZadi_z_ainc_d) + plya + fakt2;
		
		new Float:z_mob_spawn_max_int_ea2 = GetConVarInt(l4d_cZadi_z_mob_maxi_ea) - (plya * fakt2);
		new Float:z_mob_spawn_min_int_ea2 = GetConVarInt(l4d_cZadi_z_mob_mini_ea) - (plya * fakt2);
		new Float:z_mob_spawn_max_int_no2 = GetConVarInt(l4d_cZadi_z_mob_maxi_no) - (plya * fakt2);
		new Float:z_mob_spawn_min_int_no2 = GetConVarInt(l4d_cZadi_z_mob_mini_no) - (plya * fakt2);
		new Float:z_mob_spawn_max_int_ha2 = GetConVarInt(l4d_cZadi_z_mob_maxi_ha) - (plya * fakt2);
		new Float:z_mob_spawn_min_int_ha2 = GetConVarInt(l4d_cZadi_z_mob_mini_ha) - (plya * fakt2);
		new Float:z_mob_spawn_max_int_ex2 = GetConVarInt(l4d_cZadi_z_mob_maxi_ex) - (plya * fakt2);
		new Float:z_mob_spawn_min_int_ex2 = GetConVarInt(l4d_cZadi_z_mob_mini_ex) - (plya * fakt2);
		new Float:z_mob_spawn_max_size2 = GetConVarInt(l4d_cZadi_z_mob_maxs) + (plya * fakt2) - plya - fakt2;
		new Float:z_mob_spawn_min_size2 = GetConVarInt(l4d_cZadi_z_mob_mins) + (plya * fakt2) - plya - fakt2;

		new Float:z_mob_spawn_finale_size2 = GetConVarInt(l4d_cZadi_z_mob_f_s) + (plya * fakt2) - plya - fakt2;
		
		new Float:z_mob_spawn_max_int_ski = GetConVarInt(l4d_cZadi_z_mob_maxi_sk) - (plya * fakt2);
		new Float:z_mob_spawn_min_int_ski = GetConVarInt(l4d_cZadi_z_mob_mini_sk) - (plya * fakt2);
		new Float:z_skirmish_spawn_max_size2 = GetConVarInt(l4d_cZadi_z_smob_maxs) + (plya * fakt2) - plya - fakt2;
		new Float:z_skirmish_spawn_min_size2 = GetConVarInt(l4d_cZadi_z_smob_mins) + (plya * fakt2) - plya - fakt2;

		new Float:z_mega_mob_size2 = GetConVarInt(l4d_cZadi_z_mob_m_s) + (plya * fakt2) + plya;
		new Float:z_mega_mob_max_int2 = GetConVarInt(l4d_cZadi_z_mmob_max_int) - (plya * fakt2);
		new Float:z_mega_mob_min_int2 = GetConVarInt(l4d_cZadi_z_mmob_min_int) - (plya * fakt2);
		
		new Float:z_non_head_easy2 = GetConVarFloat(l4d_cZadi_z_nhd_ea) - ( (plya * fakt2) / 48 );
		new Float:z_non_head_expert2 = GetConVarFloat(l4d_cZadi_z_nhd_ex) - ( (plya * fakt2) / 90);
		new Float:z_non_head_hard2 = GetConVarFloat(l4d_cZadi_z_nhd_ha) - ( (plya * fakt2) / 85);
		new Float:z_non_head_normal2 = GetConVarFloat(l4d_cZadi_z_nhd_no) - ( (plya * fakt2) / 58);
		
		new Float:z_hunter_health2 = GetConVarInt(l4d_cZadi_z_hunter_hp) + ((plya * fakt2) * fakt2);
		new Float:z_smoker_health2 = GetConVarInt(l4d_cZadi_z_smoker_hp) + ((plya * fakt2) * fakt2);
		new Float:z_boomer_health2 = GetConVarInt(l4d_cZadi_z_boomer_hp) + ((plya * fakt2) * fakt2);
		new Float:z_charger_health2 = GetConVarInt(l4d_cZadi_z_charger_hp) + ((plya * fakt2) * fakt2);
		new Float:z_spitter_health2 = GetConVarInt(l4d_cZadi_z_splitter_hp) + ((plya * fakt2) * fakt2);
		new Float:z_jockey_health2 = GetConVarInt(l4d_cZadi_z_jockey_hp) + ((plya * fakt2) * fakt2);
		new Float:z_witch_health2 = ((GetConVarInt(l4d_cZadi_z_witch_hp) + (plya * fakt2)) * (plya + fakt2)) / 4;
		new Float:z_tank_health2 = ((GetConVarInt(l4d_cZadi_z_tank_hp) + (plya * fakt2)) * (plya + fakt2)) / 6;

		SetConVarFloat(FindConVar("z_health"), z_health2);	
		SetConVarFloat(FindConVar("z_hunter_health"), z_hunter_health2);
		SetConVarFloat(FindConVar("z_gas_health"), z_smoker_health2);
		SetConVarFloat(FindConVar("z_exploding_health"), z_boomer_health2);


		if(strcmp(l4d_cZadi_game, "left4dead2", false) == 0)
		{
			SetConVarFloat(FindConVar("z_charger_health"), z_charger_health2);
			SetConVarFloat(FindConVar("z_spitter_health"), z_spitter_health2);
			SetConVarFloat(FindConVar("z_jockey_health"), z_jockey_health2);
		}
		SetConVarFloat(FindConVar("z_witch_health"), z_witch_health2);
		SetConVarFloat(FindConVar("z_tank_health"), z_tank_health2);

		SetConVarFloat(FindConVar("z_background_limit"), z_background_limit2);
		SetConVarFloat(FindConVar("z_common_limit"), z_common_limit2);

		SetConVarFloat(FindConVar("z_attack_incapacitated_damage"), z_attack_inc_damage2);

		SetConVarFloat(FindConVar("z_non_head_damage_factor_easy"), z_non_head_easy2);
		SetConVarFloat(FindConVar("z_non_head_damage_factor_expert"), z_non_head_expert2);
		SetConVarFloat(FindConVar("z_non_head_damage_factor_hard"), z_non_head_hard2);
		SetConVarFloat(FindConVar("z_non_head_damage_factor_normal"), z_non_head_normal2);

		SetConVarFloat(FindConVar("z_mob_spawn_max_interval_easy"), z_mob_spawn_max_int_ea2);
		SetConVarFloat(FindConVar("z_mob_spawn_min_interval_easy"), z_mob_spawn_min_int_ea2);
		SetConVarFloat(FindConVar("z_mob_spawn_max_interval_normal"), z_mob_spawn_max_int_no2);
		SetConVarFloat(FindConVar("z_mob_spawn_min_interval_normal"), z_mob_spawn_min_int_no2);
		SetConVarFloat(FindConVar("z_mob_spawn_max_interval_hard"), z_mob_spawn_max_int_ha2);
		SetConVarFloat(FindConVar("z_mob_spawn_min_interval_hard"), z_mob_spawn_min_int_ha2);
		SetConVarFloat(FindConVar("z_mob_spawn_max_interval_expert"), z_mob_spawn_max_int_ex2);
		SetConVarFloat(FindConVar("z_mob_spawn_min_interval_expert"), z_mob_spawn_min_int_ex2);
		SetConVarFloat(FindConVar("z_mob_spawn_max_size"), z_mob_spawn_max_size2);
		SetConVarFloat(FindConVar("z_mob_spawn_min_size"), z_mob_spawn_min_size2);

		SetConVarFloat(FindConVar("z_mob_spawn_finale_size"), z_mob_spawn_finale_size2);

		SetConVarFloat(FindConVar("z_mega_mob_size"), z_mega_mob_size2);
		SetConVarFloat(FindConVar("z_mega_mob_spawn_max_interval"), z_mega_mob_max_int2);
		SetConVarFloat(FindConVar("z_mega_mob_spawn_min_interval"), z_mega_mob_min_int2);

		SetConVarFloat(FindConVar("z_skirmish_spawn_max_interval"), z_mob_spawn_max_int_ski);
		SetConVarFloat(FindConVar("z_skirmish_spawn_min_interval"), z_mob_spawn_min_int_ski);
		SetConVarFloat(FindConVar("z_skirmish_spawn_max_size"), z_skirmish_spawn_max_size2);
		SetConVarFloat(FindConVar("z_skirmish_spawn_min_size"), z_skirmish_spawn_min_size2);


		GetConVarString(FindConVar("mp_gamemode"), l4d_cZadi_Mode, sizeof(l4d_cZadi_Mode));	
		
		if((GetConVarInt(FindConVar("director_no_specials")) == 1) || (GetConVarInt(FindConVar("director_no_bosses")) == 1)) //|| (GetConVarInt(FindConVar("director_ai_tanks")) == 0))
		{
			if(strcmp(l4d_cZadi_Mode, "survival", false) == 0) 
			{
				new Float:z_mob_spawn_max_size0 = z_mob_spawn_max_size2  + ((plya * fakt2) + fakt2);
				new Float:z_mob_spawn_min_size0 = z_mob_spawn_min_size2  + ((plya * fakt2) + fakt2);
				new Float:z_skirmish_spawn_max_size0 = z_skirmish_spawn_max_size2 + ((plya * fakt2) + fakt2);
				new Float:z_skirmish_spawn_min_size0 = z_skirmish_spawn_min_size2 + ((plya * fakt2) + fakt2);
				new Float:z_mob_spawn_max_int_ski0 = z_mob_spawn_max_int_ski / plya;
				new Float:z_mob_spawn_min_int_ski0 = z_mob_spawn_min_int_ski / plya;
				
				new Float:z_mob_spawn_finale_size0 = z_mob_spawn_finale_size2 + ((plya * fakt2) + fakt2);

				new Float:z_mega_mob_size0 = z_mega_mob_size2 * 1.5; //useless?
				new Float:z_mega_mob_max_int0 = z_mega_mob_max_int2 / 1.5; //useless?
				new Float:z_mega_mob_min_int0 = z_mega_mob_min_int2 / 1.5; //useless?

				new Float:z_background_limit0 = GetConVarFloat(FindConVar("z_background_limit")) + (plya * fakt2) + plya; //useless?
				new Float:z_common_limit0 = GetConVarFloat(FindConVar("z_common_limit")) + (plya * fakt2) + plya; //useless?
				SetConVarFloat(FindConVar("z_skirmish_spawn_max_interval"), z_mob_spawn_max_int_ski0);
				SetConVarFloat(FindConVar("z_skirmish_spawn_min_interval"), z_mob_spawn_min_int_ski0);
				SetConVarFloat(FindConVar("z_skirmish_spawn_max_size"), z_skirmish_spawn_max_size0);
				SetConVarFloat(FindConVar("z_skirmish_spawn_min_size"), z_skirmish_spawn_min_size0);
				
				SetConVarFloat(FindConVar("z_background_limit"), z_background_limit0);
				SetConVarFloat(FindConVar("z_common_limit"), z_common_limit0);
				
				SetConVarInt(FindConVar("director_finale_panic_waves"), plya);
				

				SetConVarFloat(FindConVar("z_mob_spawn_max_size"), z_mob_spawn_max_size0);
				SetConVarFloat(FindConVar("z_mob_spawn_min_size"), z_mob_spawn_min_size0);
				SetConVarFloat(FindConVar("z_mob_spawn_finale_size"), z_mob_spawn_finale_size0);
				SetConVarFloat(FindConVar("z_mega_mob_size"), z_mega_mob_size0);
				SetConVarFloat(FindConVar("z_mega_mob_spawn_max_interval"), z_mega_mob_max_int0);
				SetConVarFloat(FindConVar("z_mega_mob_spawn_min_interval"), z_mega_mob_min_int0);
			}
		}
	}
	else
	{
		reset2standart();
	}
}

reset2standart()
{
	ResetConVar(FindConVar("z_hunter_health"), true, true);
	ResetConVar(FindConVar("z_gas_health"), true, true);
	ResetConVar(FindConVar("z_exploding_health"), true, true);
	ResetConVar(FindConVar("z_charger_health"), true, true);
	ResetConVar(FindConVar("z_spitter_health"), true, true);
	ResetConVar(FindConVar("z_jockey_health"), true, true);
	ResetConVar(FindConVar("z_witch_health"), true, true);
	ResetConVar(FindConVar("z_tank_health"), true, true);
	ResetConVar(FindConVar("z_health"), true, true);
	ResetConVar(FindConVar("z_common_limit"), true, true);
	ResetConVar(FindConVar("z_background_limit"), true, true);
	ResetConVar(FindConVar("z_pounce_damage"), true, true);
	ResetConVar(FindConVar("z_non_head_damage_factor_easy"), true, true);
	ResetConVar(FindConVar("z_non_head_damage_factor_expert"), true, true);
	ResetConVar(FindConVar("z_non_head_damage_factor_hard"), true, true);
	ResetConVar(FindConVar("z_non_head_damage_factor_normal"), true, true);
	ResetConVar(FindConVar("z_attack_incapacitated_damage"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_max_interval_easy"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_min_interval_easy"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_max_interval_normal"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_min_interval_normal"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_max_interval_hard"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_min_interval_hard"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_max_interval_expert"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_min_interval_expert"), true, true);
	ResetConVar(FindConVar("z_skirmish_spawn_max_interval"), true, true);
	ResetConVar(FindConVar("z_skirmish_spawn_min_interval"), true, true);
	ResetConVar(FindConVar("z_skirmish_spawn_max_size"), true, true);
	ResetConVar(FindConVar("z_skirmish_spawn_min_size"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_max_size"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_min_size"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_finale_size"), true, true);
	ResetConVar(FindConVar("z_mega_mob_size"), true, true);
	ResetConVar(FindConVar("z_mega_mob_spawn_max_interval"), true, true);
	ResetConVar(FindConVar("z_mega_mob_spawn_min_interval"), true, true);
	ResetConVar(FindConVar("z_mega_mob_size"), true, true);
	ResetConVar(FindConVar("z_mega_mob_size"), true, true);
}