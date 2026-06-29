#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <vsh2>

#undef REQUIRE_PLUGIN
#tryinclude <tf2attributes>
#define REQUIRE_PLUGIN


public Plugin myinfo = {
	name        = "[VSH2Boss] Piss Cakehole",
	author      = "Sajt",
	version     = "1.0",
};

enum struct PissCakehole {
	int          id;
	VSH2GameMode gm;
	ConfigMap    cfg;
	ConVar       scout_rage_gen;
	ConVar       airblast_rage;
	ConVar       jarate_rage;
	ConVar       pisscakehole_uber_time;
}
PissCakehole piss_cakehole;


public void OnLibraryAdded(const char[] name) {
	if( StrEqual(name, "VSH2") ) {
		piss_cakehole.cfg            = new ConfigMap("configs/saxton_hale/boss_cfgs/piss_cakehole.cfg");
		if( piss_cakehole.cfg==null ) {
			/// prevent template boss from registering if no config file was found.
			LogError("[VSH 2] ERROR :: **** couldn't find 'configs/saxton_hale/boss_cfgs/piss_cakehole.cfg'. Failed to register Piss Cakehole. ****");
			return;
		}
		piss_cakehole.scout_rage_gen = FindConVar("vsh2_scout_rage_gen");
		piss_cakehole.airblast_rage  = FindConVar("vsh2_airblast_rage");
		piss_cakehole.jarate_rage    = FindConVar("vsh2_jarate_rage");
		piss_cakehole.pisscakehole_uber_time    = CreateConVar("vsh2_pisscakehole_uber_time", "15.0", "Uber time for Piss Cakehole");
		
		char plugin_name_str[MAX_BOSS_NAME_SIZE];
		piss_cakehole.cfg.Get("boss.plugin name", plugin_name_str, sizeof(plugin_name_str));
		piss_cakehole.id = VSH2_RegisterBoss(plugin_name_str);
		LoadVSH2Hooks();
		AutoExecConfig(true, "VSH2-Piss Cakehole");
	}
}

public void LoadVSH2Hooks() {
	if( !VSH2_HookEx(OnCallDownloads, PissCakehole_OnCallDownloads) )
		LogError("Error loading OnCallDownloads forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnBossMenu, PissCakehole_OnBossMenu) )
		LogError("Error loading OnBossMenu forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnBossSelected, PissCakehole_OnBossSelected) )
		LogError("Error loading OnBossSelected forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnBossThink, PissCakehole_OnBossThink) )
		LogError("Error loading OnBossThink forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnBossModelTimer, PissCakehole_OnBossModelTimer) )
		LogError("Error loading OnBossModelTimer forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnBossEquipped, PissCakehole_OnBossEquipped) )
		LogError("Error loading OnBossEquipped forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnBossInitialized, PissCakehole_OnBossInitialized) )
		LogError("Error loading OnBossInitialized forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnBossPlayIntro, PissCakehole_OnBossPlayIntro) )
		LogError("Error loading OnBossPlayIntro forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnPlayerKilled, PissCakehole_OnPlayerKilled) )
		LogError("Error loading OnPlayerKilled forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnPlayerHurt, PissCakehole_OnPlayerHurt) )
		LogError("Error loading OnPlayerHurt forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnPlayerAirblasted, PissCakehole_OnPlayerAirblasted) )
		LogError("Error loading OnPlayerAirblasted forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnBossMedicCall, PissCakehole_OnBossMedicCall) )
		LogError("Error loading OnBossMedicCall forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnBossTaunt, PissCakehole_OnBossMedicCall) )
		LogError("Error loading OnBossTaunt forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnRoundEndInfo, PissCakehole_OnRoundEndInfo) )
		LogError("Error loading OnRoundEndInfo forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnMusic, PissCakehole_Music) )
		LogError("Error loading OnMusic forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnBossDeath, PissCakehole_OnBossDeath) )
		LogError("Error loading OnBossDeath forwards for Piss Cakehole plugin.");
		
	if( !VSH2_HookEx(OnBossJarated, PissCakehole_OnBossJarated) )
		LogError("Error loading OnBossJarated forwards for Spy plugin.");
	
	if( !VSH2_HookEx(OnBossTakeDamage_OnStabbed, PissCakehole_OnStabbed) )
		LogError("Error loading OnBossTakeDamage_OnStabbed forwards for Piss Cakehole plugin.");
	
	if( !VSH2_HookEx(OnLastPlayer, PissCakehole_OnLastPlayer) )
		LogError("Error loading OnLastPlayer forwards for Piss Cakehole plugin.");
		
	if( !VSH2_HookEx(OnSoundHook, PissCakehole_OnVoice) )
		LogError("Error loading OnSoundHook forwards for Piss Cakehole plugin.");
}


stock bool IsPissCakehole(const VSH2Player player) {
	return player.GetPropInt("iBossType") == piss_cakehole.id;
}

public void PissCakehole_OnCallDownloads() {
	{
		/// model.
		int boss_mdl_len = piss_cakehole.cfg.GetSize("boss.model");
		char[] boss_mdl_str = new char[boss_mdl_len];
		if( piss_cakehole.cfg.Get("boss.model", boss_mdl_str, boss_mdl_len) > 0 ) {
			PrepareModel(boss_mdl_str);
		}
		
		/// model skins.
		ConfigMap skins = piss_cakehole.cfg.GetSection("boss.skins");
		PrepareAssetsFromCfgMap(skins, ResourceMaterial);
	}
	{
		/// model.
		int zomb_mdl_len = piss_cakehole.cfg.GetSize("boss.ragemodel");
		char[] zomb_mdl_str = new char[zomb_mdl_len];
		if( piss_cakehole.cfg.Get("boss.ragemodel", zomb_mdl_str, zomb_mdl_len) > 0 ) {
			PrepareModel(zomb_mdl_str);
		}
		
		/// model skins.
		ConfigMap skins = piss_cakehole.cfg.GetSection("boss.rageskins");
		PrepareAssetsFromCfgMap(skins, ResourceMaterial);
	}
	
	ConfigMap vo_sect = piss_cakehole.cfg.GetSection("boss.sounds.phrase");
	if( vo_sect != null ) {
		int size = vo_sect.Size;
		ConfigMap[] vo_sects = new ConfigMap[size];
		int sect_count = vo_sect.GetSections(vo_sects);
		for( int n; n < sect_count; n++ ) {
			PrepareAssetsFromCfgMap(vo_sects[n], ResourceSound);
		}
	}
	
	ConfigMap sounds_sect = piss_cakehole.cfg.GetSection("boss.sounds");
	if( sounds_sect != null ) {
		int size = sounds_sect.Size;
		ConfigMap[] sound_sects = new ConfigMap[size];
		int sect_count = sounds_sect.GetSections(sound_sects);
		/// minus 1 so we don't access the music time section.
		for( int i; i < sect_count-1; i++ ) {
			PrepareAssetsFromCfgMap(sound_sects[i], ResourceSound);
		}
	}
}

public void PissCakehole_OnBossMenu(Menu& menu) {
	char tostr[10]; IntToString(piss_cakehole.id, tostr, sizeof(tostr));
	/// ConfigMap can be used to store the boss name.
	int menu_name_len = piss_cakehole.cfg.GetSize("boss.menu name");
	char[] menu_name_str = new char[menu_name_len];
	piss_cakehole.cfg.Get("boss.menu name", menu_name_str, menu_name_len);
	menu.AddItem(tostr, menu_name_str);
}

public void PissCakehole_OnBossSelected(const VSH2Player player) {
	if( !IsPissCakehole(player) )
		return;
	
	player.SetPropInt("iCustomProp", 0);
	player.SetPropFloat("flCustomProp", 0.0);
	player.SetPropAny("hCustomProp", player);
	
	/// ConfigMap is also useful for automating custom prop creation.
	ConfigMap custom_props = piss_cakehole.cfg.GetSection("boss.custom props");
	if( custom_props != null ) {
		for( int i; i<custom_props.Size; i++ ) {
			int prop_len = piss_cakehole.cfg.GetIntKeySize(i);
			char[] prop_name = new char[prop_len];
			piss_cakehole.cfg.GetIntKey(i, prop_name, prop_len);
			
			char prop[64]; strcopy(prop, sizeof prop, prop_name);
			player.SetPropInt(prop, 0);
		}
	}
	
	Panel panel = new Panel();
	int panel_len = piss_cakehole.cfg.GetSize("boss.help panel");
	char[] panel_info = new char[panel_len];
	piss_cakehole.cfg.Get("boss.help panel", panel_info, panel_len);
	panel.SetTitle(panel_info);
	panel.DrawItem("Piss");
	panel.Send(player.index, HintPanel, 999);
	delete panel;
}

public void PissCakehole_OnBossThink(const VSH2Player player) {
	int client = player.index;
	if( !IsPlayerAlive(client) || !IsPissCakehole(player) )
		return;
	
	player.SpeedThink(340.0);
	player.GlowThink(0.1);
	if( player.SuperJumpThink(2.5, 25.0) ) {
		player.PlayRandVoiceClipCfgMap(piss_cakehole.cfg.GetSection("boss.sounds.jump"), VSH2_VOICE_ABILITY);
		player.SuperJump(player.GetPropFloat("flCharge"), -100.0);
	}
	
	if( VSH2GameMode.AreScoutsLeft() ) {
		player.SetPropFloat("flRAGE", player.GetPropFloat("flRAGE") + piss_cakehole.scout_rage_gen.FloatValue);
	}
	player.WeighDownThink(0.2, 0.1);
	
	/// hud code
	SetHudTextParams(-1.0, 0.77, 0.35, 255, 255, 255, 255);
	Handle hud = piss_cakehole.gm.hHUD;
	float  jmp = player.GetPropFloat("flCharge");
	float  rage = player.GetPropFloat("flRAGE");
	if( rage >= 100.0 ) {
		ShowSyncHudText(client, hud, "Piss Jump: %i%% | Piss Cakehole Rage: FULL - Press E to activate", player.GetPropInt("bSuperCharge") ? 1000 : RoundFloat(jmp) * 4);
	} else {
		ShowSyncHudText(client, hud, "Piss Jump: %i%% | Piss Cakehole Rage: %0.1f", player.GetPropInt("bSuperCharge") ? 1000 : RoundFloat(jmp) * 4, rage);
	}
}

public void PissCakehole_OnBossModelTimer(const VSH2Player player) {
	if( !IsPissCakehole(player) )
		return;
	
	int client = player.index;
	int boss_mdl_len = piss_cakehole.cfg.GetSize("boss.model");
	char[] boss_mdl = new char[boss_mdl_len];
	piss_cakehole.cfg.Get("boss.model", boss_mdl, boss_mdl_len);
	SetVariantString(boss_mdl);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}

public void PissCakehole_OnBossEquipped(const VSH2Player player) {
	if( !IsPissCakehole(player) )
		return;
	
	char name[MAX_BOSS_NAME_SIZE];
	piss_cakehole.cfg.Get("boss.name", name, sizeof(name));
	player.SetName(name);
	
	player.RemoveAllItems();
	ConfigMap melee_wep = piss_cakehole.cfg.GetSection("boss.melee");
	if( melee_wep==null ) {
		return;
	}
	/// Normal Weapon
	int attribs_len = melee_wep.GetSize("attribs");
	char[] attribs_str = new char[attribs_len];
	melee_wep.Get("attribs", attribs_str, attribs_len);
	
	int classname_len = melee_wep.GetSize("classname");
	char[] classname_str = new char[classname_len];
	melee_wep.Get("classname", classname_str, classname_len);
	
	int index, level, quality;
	melee_wep.GetInt("index",   index);
	melee_wep.GetInt("level",   level);
	melee_wep.GetInt("quality", quality);
	
	int wep = player.SpawnWeapon(classname_str, index, level, quality, attribs_str);
	SetEntPropEnt(player.index, Prop_Send, "m_hActiveWeapon", wep);

}

public void PissCakehole_OnBossInitialized(const VSH2Player player) {
	if( !IsPissCakehole(player) )
		return;
	
	SetEntProp(player.index, Prop_Send, "m_iClass", view_as< int >(TFClass_Sniper));
}

public void PissCakehole_OnBossPlayIntro(const VSH2Player player) {
	if( !IsPissCakehole(player) )
		return;
	
	player.PlayRandVoiceClipCfgMap(piss_cakehole.cfg.GetSection("boss.sounds.intro"), VSH2_VOICE_INTRO);
}

public void PissCakehole_OnPlayerKilled(const VSH2Player attacker, const VSH2Player victim, Event event) {
	if( !IsPissCakehole(attacker) )
		return;
	
	float curtime = GetGameTime();
	if( curtime <= attacker.GetPropFloat("flKillSpree") ) {
		attacker.SetPropInt("iKills", attacker.GetPropInt("iKills") + 1);
	} else {
		attacker.SetPropInt("iKills", 0);
	}
	event.SetString("weapon", "bonesaw");
	
	attacker.PlayRandVoiceClipCfgMap(piss_cakehole.cfg.GetSection("boss.sounds.kill"), VSH2_VOICE_SPREE);
	if( attacker.GetPropInt("iKills") == 3 && piss_cakehole.gm.iLivingReds != 1 ) {
		attacker.PlayRandVoiceClipCfgMap(piss_cakehole.cfg.GetSection("boss.sounds.spree"), VSH2_VOICE_SPREE);
		attacker.SetPropInt("iKills", 0);
	} else {
		attacker.SetPropFloat("flKillSpree", curtime + 5.0);
	}
}

public void PissCakehole_OnPlayerHurt(const VSH2Player attacker, const VSH2Player victim, Event event) {
	int damage = event.GetInt("damageamount");
	if( victim.bIsBoss && IsPissCakehole(victim) ) {
		victim.GiveRage(damage);
	}
}

public void PissCakehole_OnPlayerAirblasted(const VSH2Player airblaster, const VSH2Player airblasted, Event event) {
	if( !IsPissCakehole(airblasted) )
		return;
	
	float rage = airblasted.GetPropFloat("flRAGE");
	airblasted.SetPropFloat("flRAGE", rage + piss_cakehole.airblast_rage.FloatValue);
}

public void PissCakehole_OnBossMedicCall(const VSH2Player rager) {
	if( !IsPissCakehole(rager) || rager.GetPropFloat("flRAGE") < 100.0 )
		return;
		
	char name[MAX_BOSS_NAME_SIZE];
	piss_cakehole.cfg.Get("boss.name", name, sizeof(name));
	rager.SetName(name);
	
	TF2_RemoveWeaponSlot(rager.index, TFWeaponSlot_Secondary);
	int wep = rager.SpawnWeapon("tf_weapon_jar", 58, 100, 14, "251; 5; 737; 5");
	SetEntPropEnt(rager.index, Prop_Send, "m_hActiveWeapon", wep);
	SetEntProp(wep, Prop_Send, "m_iClip1", 20);
	
	float rage_time = piss_cakehole.pisscakehole_uber_time.FloatValue;
	TF2_AddCondition(rager.index, TFCond_Ubercharged, rage_time);
	
	int zomb_mdl_len = piss_cakehole.cfg.GetSize("boss.ragemodel");
	char[] zomb_mdl = new char[zomb_mdl_len];
	piss_cakehole.cfg.Get("boss.ragemodel", zomb_mdl, zomb_mdl_len);
	SetVariantString(zomb_mdl);
	
	ConfigMap skins = piss_cakehole.cfg.GetSection("boss.rageskins");
	PrepareAssetsFromCfgMap(skins, ResourceMaterial);
	
	rager.DoGenericStun(800.0);
	VSH2Player[] players = new VSH2Player[MaxClients];
	int in_range = rager.GetPlayersInRange(players, 800.0);
	for( int i; i<in_range; i++ ) {
		if( players[i].bIsBoss || players[i].bIsMinion ) {
			continue;
		}
		/// do a distance based thing here.
	}
	rager.PlayRandVoiceClipCfgMap(piss_cakehole.cfg.GetSection("boss.sounds.rage"), VSH2_VOICE_RAGE);
	rager.SetPropFloat("flRAGE", 0.0);
}

public void PissCakehole_OnBossJarated(const VSH2Player victim, const VSH2Player thrower) {
	if( !IsPissCakehole(victim) )
		return;
	
	float rage = victim.GetPropFloat("flRAGE");
	victim.SetPropFloat("flRAGE", rage - piss_cakehole.jarate_rage.FloatValue);
}

public void PissCakehole_OnRoundEndInfo(const VSH2Player player, bool boss_won, char message[MAXMESSAGE]) {
	if( !IsPissCakehole(player) ) {
		return;
	} else if( boss_won ) {
		player.PlayRandVoiceClipCfgMap(piss_cakehole.cfg.GetSection("boss.sounds.win"), VSH2_VOICE_WIN);
	}
}


public void PissCakehole_Music(char song[PLATFORM_MAX_PATH], float &time, const VSH2Player player) {
	if( !IsPissCakehole(player) )
		return;
	
	ConfigMap music_sect = piss_cakehole.cfg.GetSection("boss.sounds.music");
	ConfigMap music_time_sect = piss_cakehole.cfg.GetSection("boss.sounds.music time");
	if( music_sect==null || music_time_sect==null ) {
		return;
	}
	
	int size = (music_sect.Size > music_time_sect.Size)? music_time_sect.Size : music_sect.Size;
	static int index;
	index = ShuffleIndex(size, index);
	music_sect.GetIntKey(index, song, sizeof(song));
	music_time_sect.GetIntKeyFloat(index, time);
}

public void PissCakehole_OnBossDeath(const VSH2Player player) {
	if( !IsPissCakehole(player) )
		return;
	
	player.PlayRandVoiceClipCfgMap(piss_cakehole.cfg.GetSection("boss.sounds.death"), VSH2_VOICE_LOSE);
}

public Action PissCakehole_OnStabbed(VSH2Player victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if( !IsPissCakehole(victim) )
		return Plugin_Continue;
	
	victim.PlayRandVoiceClipCfgMap(piss_cakehole.cfg.GetSection("boss.sounds.backstab"), VSH2_VOICE_STABBED);
	return Plugin_Continue;
}

public void PissCakehole_OnLastPlayer(const VSH2Player player) {
	if( !IsPissCakehole(player) )
		return;
	
	player.PlayRandVoiceClipCfgMap(piss_cakehole.cfg.GetSection("boss.sounds.lastplayer"), VSH2_VOICE_LASTGUY);
}

public Action PissCakehole_OnVoice(const VSH2Player player, char sample[PLATFORM_MAX_PATH], int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if (!IsPissCakehole(player)) return Plugin_Continue;

	if ( (channel == SNDCHAN_VOICE || channel == SNDCHAN_STATIC) && !StrContains(sample, "vo") )
	{
		ConfigMap phrase = piss_cakehole.cfg.GetSection("boss.sounds.phrase");
		int phrase_size = phrase ? phrase.Size : phrase_size;
		if (phrase_size)
		{
			phrase.GetIntKey(GetRandomInt(0, phrase_size - 1), sample, sizeof(sample));
			return Plugin_Changed;
		}
		else return Plugin_Stop;
	}

	return Plugin_Continue;
}

/// Stocks =============================================
stock bool IsValidClient(const int client, bool nobots=false) {
	if( client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)) )
		return false;
	return IsClientInGame(client);
}

stock void SetPawnTimerEx(Function func, float thinktime = 0.1, const any[] args, const int len) {
	DataPack thinkpack = new DataPack();
	thinkpack.WriteFunction(func);
	thinkpack.WriteCell(len);
	for( int i; i<len; i++ ) {
		thinkpack.WriteCell(args[i]);
	}
	CreateTimer(thinktime, DoPawnTimer, thinkpack, TIMER_DATA_HNDL_CLOSE);
}

public Action DoPawnTimer(Handle t, DataPack pack) {
	pack.Reset();
	Function fn = pack.ReadFunction();
	Call_StartFunction(null, fn);
	
	int len = pack.ReadCell();
	for( int i; i<len; i++ ) {
		any param = pack.ReadCell();
		Call_PushCell(param);
	}
	Call_Finish();
	return Plugin_Continue;
}

stock int GetSlotFromWeapon(const int iClient, const int iWeapon)
{
	for( int i; i<5; i++ )
		if( iWeapon == GetPlayerWeaponSlot(iClient, i) )
			return i;
	return -1;
}

stock void SetWeaponAmmo(const int weapon, const int ammo)
{
	int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if( owner <= 0 )
		return;
	else if( IsValidEntity(weapon) ) {
		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(owner, iAmmoTable+iOffset, ammo, 30, true);
	}
}

stock void SetWeaponClip(const int weapon, const int ammo) {
	if( !IsValidEntity(weapon) )
		return;
	
	int iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	SetEntData(weapon, iAmmoTable, ammo, 30, true);
}


public int HintPanel(Menu menu, MenuAction action, int param1, int param2) {
	return;
}
