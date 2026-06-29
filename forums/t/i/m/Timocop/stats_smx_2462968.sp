public PlVers:__version =
{
	version = 5,
	filevers = "1.7.0",
	date = "03/19/2015",
	time = "20:37:18"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_cprefs =
{
	name = "Client Preferences",
	file = "clientprefs.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
new String:CTag[6][0];
new String:CTagCode[6][16] =
{
	"\x01",
	"\x04",
	"\x03",
	"\x03",
	"\x03",
	"\x05"
};
new bool:CTagReqSayText2[6] =
{
	0, 0, 1, 1, 1, 0
};
new bool:CEventIsHooked;
new bool:CSkipList[66];
new bool:CProfile_Colors[6] =
{
	1, 1, 0, 0, 0, 0
};
new CProfile_TeamIndex[6] =
{
	-1, ...
};
new bool:CProfile_SayText2;
public Extension:__ext_sdkhooks =
{
	name = "SDKHooks",
	file = "sdkhooks.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_geoip =
{
	name = "GeoIP",
	file = "geoip.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_smsock =
{
	name = "Socket",
	file = "socket.ext",
	autoload = 1,
	required = 1,
};
new Float:RDifficultyMultiplier = 1065353216;
new playerscount = 4;
new bool:l4d2_plugin_loot = 1;
new bool:l4d2_plugin_monsterbots = 1;
new bool:extra_charger;
new bool:autodifficulty_calculated;
new Handle:hm_autodifficulty;
new Handle:hm_autodifficulty_forcehp;
new Handle:z_difficulty;
new Handle:z_special_spawn_interval;
new Handle:director_special_respawn_interval;
new Handle:z_max_player_zombies;
new Handle:hm_auto_tongue_range_min;
new Handle:hm_auto_tongue_range_max;
new Handle:hm_auto_tongue_miss_delay_min;
new Handle:hm_auto_tongue_miss_delay_max;
new Handle:hm_auto_tongue_hit_delay_min;
new Handle:hm_auto_tongue_hit_delay_max;
new Handle:hm_auto_tongue_choke_dmg_min;
new Handle:hm_auto_tongue_choke_dmg_max;
new Handle:hm_auto_tongue_drag_dmg_min;
new Handle:hm_auto_tongue_drag_dmg_max;
new Handle:hm_auto_smoker_pz_claw_dmg_min;
new Handle:hm_auto_smoker_pz_claw_dmg_max;
new Handle:hm_auto_jockey_pz_claw_dmg_min;
new Handle:hm_auto_jockey_pz_claw_dmg_max;
new Handle:hm_auto_grenade_lr_dmg_min;
new Handle:hm_auto_grenade_lr_dmg_max;
new Handle:damage_type;
new Handle:hm_damage_ak47_min;
new Handle:hm_damage_ak47_max;
new Handle:hm_damage_awp_min;
new Handle:hm_damage_awp_max;
new Handle:hm_damage_m60_min;
new Handle:hm_damage_m60_max;
new Handle:hm_damage_scout_min;
new Handle:hm_damage_scout_max;
new Handle:hm_damage_sg552_min;
new Handle:hm_damage_sg552_max;
new Handle:hm_damage_spas_min;
new Handle:hm_damage_spas_max;
new Handle:hm_damage_sniper_military_min;
new Handle:hm_damage_sniper_military_max;
new Handle:hm_damage2_ak47_min;
new Handle:hm_damage2_ak47_max;
new Handle:hm_damage2_awp_min;
new Handle:hm_damage2_awp_max;
new Handle:hm_damage2_m60_min;
new Handle:hm_damage2_m60_max;
new Handle:hm_damage2_scout_min;
new Handle:hm_damage2_scout_max;
new Handle:hm_damage2_sg552_min;
new Handle:hm_damage2_sg552_max;
new Handle:hm_damage2_spas_min;
new Handle:hm_damage2_spas_max;
new Handle:hm_damage2_sniper_military_min;
new Handle:hm_damage2_sniper_military_max;
new Handle:hm_meleefix_min;
new Handle:hm_meleefix_max;
new Handle:hm_meleefix_headshot_min;
new Handle:hm_meleefix_headshot_max;
new Handle:hm_meleefix_tank_min;
new Handle:hm_meleefix_tank_max;
new Handle:hm_meleefix_tank_headshot_min;
new Handle:hm_meleefix_tank_headshot_max;
new Handle:hm_meleefix_witch_min;
new Handle:hm_meleefix_witch_max;
new Handle:hm_loot_mod;
new Handle:hm_tank_hp_mod;
new Handle:hm_infected_hp_mod;
new Handle:hm_spawn_time_mod;
new Handle:hm_spawn_count_mod;
new Handle:hm_special_infected_min;
new Handle:hm_special_infected_max;
new Handle:hm_spawn_interval_min;
new Handle:hm_spawn_interval_max;
new Handle:hm_tank_burn_duration_min;
new Handle:hm_tank_burn_duration_max;
new Handle:hm_autohp_automod;
new Handle:hm_autohp_supercharger_auto;
new Handle:hm_autohp_zombie_min;
new Handle:hm_autohp_zombie_max;
new Handle:hm_autohp_hunter_min;
new Handle:hm_autohp_hunter_max;
new Handle:hm_autohp_smoker_min;
new Handle:hm_autohp_smoker_max;
new Handle:hm_autohp_boomer_min;
new Handle:hm_autohp_boomer_max;
new Handle:hm_autohp_jockey_min;
new Handle:hm_autohp_jockey_max;
new Handle:hm_autohp_charger_min;
new Handle:hm_autohp_charger_max;
new Handle:hm_autohp_spitter_min;
new Handle:hm_autohp_spitter_max;
new Handle:hm_autohp_witch_min;
new Handle:hm_autohp_witch_max;
new Handle:hm_autohp_tank_min;
new Handle:hm_autohp_tank_max;
new Handle:hm_items_automod;
new Handle:hm_items_supercharger_auto;
new Handle:hm_items_hunter_min;
new Handle:hm_items_hunter_max;
new Handle:hm_items_smoker_min;
new Handle:hm_items_smoker_max;
new Handle:hm_items_boomer_min;
new Handle:hm_items_boomer_max;
new Handle:hm_items_jockey_min;
new Handle:hm_items_jockey_max;
new Handle:hm_items_charger_min;
new Handle:hm_items_charger_max;
new Handle:hm_items_spitter_min;
new Handle:hm_items_spitter_max;
new Handle:hm_items_tank_min;
new Handle:hm_items_tank_max;
new Handle:hm_spawn_automod;
new Handle:hm_spawn_zombie_min;
new Handle:hm_spawn_zombie_max;
new Handle:hm_spawn_hunter_min;
new Handle:hm_spawn_hunter_max;
new Handle:hm_spawn_smoker_min;
new Handle:hm_spawn_smoker_max;
new Handle:hm_spawn_boomer_min;
new Handle:hm_spawn_boomer_max;
new Handle:hm_spawn_jockey_min;
new Handle:hm_spawn_jockey_max;
new Handle:hm_spawn_charger_min;
new Handle:hm_spawn_charger_max;
new Handle:hm_spawn_spitter_min;
new Handle:hm_spawn_spitter_max;
new Handle:hm_speed_automod;
new Handle:hm_speed_hunter_min;
new Handle:hm_speed_hunter_max;
new Handle:hm_speed_smoker_min;
new Handle:hm_speed_smoker_max;
new Handle:hm_speed_boomer_min;
new Handle:hm_speed_boomer_max;
new Handle:hm_speed_jockey_min;
new Handle:hm_speed_jockey_max;
new Handle:hm_speed_charger_min;
new Handle:hm_speed_charger_max;
new Handle:hm_speed_spitter_min;
new Handle:hm_speed_spitter_max;
new Handle:hm_speed_tank_min;
new Handle:hm_speed_tank_max;
new String:sGameDifficulty[16];
new String:Server_UpTime[20];
new UpTime;
new cvar_difficulty = 1;
new cvar_maxplayers;
new AutodifficultyHP[66][9];
new AutodifficultyGrenadeLRDmg[66];
new AutodifficultyItems[66][9];
new AutodifficultySpawnLimit[66][9];
new AutodifficultySpeed[66][9];
new AutodifficultySpawnInterval[66];
new AutodifficultySpawnCount[66];
new AutodifficultyTongueMissDelay[66];
new AutodifficultyTongueHitDelay[66];
new AutodifficultyTongueRange[66];
new AutodifficultyTongueChokeDmg[66];
new AutodifficultyTongueDragDmg[66];
new AutodifficultySmokerClawDmg[66];
new AutodifficultyJockeyClawDmg[66];
new AutodifficultyTankBurnTime[66];
new Autodifficulty_ak47_Dmg[66];
new Autodifficulty_awp_Dmg[66];
new Autodifficulty_m60_Dmg[66];
new Autodifficulty_scout_Dmg[66];
new Autodifficulty_sg552_Dmg[66];
new Autodifficulty_spas_Dmg[66];
new Autodifficulty_sniper_military_Dmg[66];
new Autodifficulty_meleefix_Dmg[66];
new Autodifficulty_meleefix_headshot_Dmg[66];
new Autodifficulty_meleefix_tank_Dmg[66];
new Autodifficulty_meleefix_tank_headshot_Dmg[66];
new Autodifficulty_meleefix_witch_Dmg[66];
new bool:g_IsTimeAutodifficulty;
new Handle:MeleeDmg[10];
new Handle:MeleeHeadshotDmg[9];
new Float:DamageBody[10];
new Float:DamageHeadshot[9];
new Handle:hm_damage;
new Handle:hm_damage_friendly;
new Handle:hm_damage_showvalue;
new Handle:hm_damage_hunter;
new Handle:hm_damage_smoker;
new Handle:hm_damage_boomer;
new Handle:hm_damage_spitter1;
new Handle:hm_damage_spitter2;
new Handle:hm_damage_jockey;
new Handle:hm_damage_charger;
new Handle:hm_damage_tank;
new Handle:hm_damage_tankrock;
new Handle:hm_damage_common;
new Handle:hm_damage_type;
new Handle:hm_damage_ak47;
new Handle:hm_damage2_ak47;
new Handle:hm_damage_awp;
new Handle:hm_damage2_awp;
new Handle:hm_damage_scout;
new Handle:hm_damage2_scout;
new Handle:hm_damage_m60;
new Handle:hm_damage2_m60;
new Handle:hm_damage_pipebomb;
new Handle:hm_damage_spas;
new Handle:hm_damage2_spas;
new Handle:hm_damage_sg552;
new Handle:hm_damage2_sg552;
new Handle:hm_damage_smg;
new Handle:hm_damage_smg_silenced;
new Handle:hm_damage_m16;
new Handle:hm_damage_pumpshotgun;
new Handle:hm_damage_autoshotgun;
new Handle:hm_damage_hunting_rifle;
new Handle:hm_damage_rifle_desert;
new Handle:hm_damage_shotgun_chrome;
new Handle:hm_damage_smg_mp5;
new Handle:hm_damage_sniper_military;
new Handle:hm_damage2_sniper_military;
new Handle:hm_damage_pistol;
new Handle:hm_damage_pistol_magnum;
new tystatsbalans;
new bonus;
new Handle:db;
new RankTotal;
new round_end_repeats;
new ClientRank[66];
new ClientPoints[66];
new ClientKills[66];
new ProtectedFriendlyCounter[66];
new ClientPlaytime[66];
new Playtime[66];
new KillsInfected[66];
new NewPoints[66];
new TKblockDamage[66];
new TKblockPunishment[66];
new TKblockmin = 120;
new TKblockmax = 360;
new bool:IsTimeAutodifficulty;
new bool:IsMapFinished;
new bool:IsPrint;
new bool:IsRoundStarted;
new Handle:Join_Timer[66];
new Pills[4096];
new Adrenaline[4096];
new g_votekick[66];
new LastVotebanTIME[66];
new Handle:hm_count_fails;
new Handle:hm_stats_colors;
new Handle:hm_stats_bot_colors;
new Handle:l4d2_rankmod_mode;
new Handle:l4d2_rankmod_min;
new Handle:l4d2_rankmod_max;
new Handle:l4d2_rankmod_logarithm;
new Handle:l4d2_players_join_message_timer;
new Handle:hm_blockvote_kick;
new Handle:hm_blockvote_map;
new Handle:hm_allowvote_map_players;
new Handle:hm_blockvote_lobby;
new Handle:hm_blockvote_restart;
new Handle:hm_blockvote_difficulty;
new Handle:hm_blockvote_difference;
new Handle:hm_allowvote_mission;
new String:CV_FileName[256];
new Handle:cvar_Hunter;
new Handle:cvar_Smoker;
new Handle:cvar_Boomer;
new Handle:cvar_Spitter;
new Handle:cvar_Jockey;
new Handle:cvar_Charger;
new Handle:cvar_Witch;
new Handle:cvar_Tank;
new Handle:cvar_Bonus;
new Handle:cvar_SiteURL;
new Float:rank_sum;
new Handle:SDifficultyMultiplier;
new bool:g_Socket[66];
new bool:g_HaveSteam[66];
new String:g_SteamID[66][32];
new String:g_ProfileID[66][20];
new Handle:g_HaveSteam_Trie;
new String:MOTD_TITLE[32] = "Message Of The Day";
new String:MessageOfTheDay[1024];
new Float:MapTimingStartTime = -1082130432;
new String:datafilepath[256];
public Plugin:myinfo =
{
	name = "l4d2 stats with autodifficulty",
	description = "",
	author = "TY (edited by SupermenCJ)",
	version = "3.0",
	url = "http://www.zambiland.ru/"
};
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	MarkNativeAsOptional("BfWriteBool");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteChar");
	MarkNativeAsOptional("BfWriteShort");
	MarkNativeAsOptional("BfWriteWord");
	MarkNativeAsOptional("BfWriteNum");
	MarkNativeAsOptional("BfWriteFloat");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("BfWriteEntity");
	MarkNativeAsOptional("BfWriteAngle");
	MarkNativeAsOptional("BfWriteCoord");
	MarkNativeAsOptional("BfWriteVecCoord");
	MarkNativeAsOptional("BfWriteVecNormal");
	MarkNativeAsOptional("BfWriteAngles");
	MarkNativeAsOptional("BfReadBool");
	MarkNativeAsOptional("BfReadByte");
	MarkNativeAsOptional("BfReadChar");
	MarkNativeAsOptional("BfReadShort");
	MarkNativeAsOptional("BfReadWord");
	MarkNativeAsOptional("BfReadNum");
	MarkNativeAsOptional("BfReadFloat");
	MarkNativeAsOptional("BfReadString");
	MarkNativeAsOptional("BfReadEntity");
	MarkNativeAsOptional("BfReadAngle");
	MarkNativeAsOptional("BfReadCoord");
	MarkNativeAsOptional("BfReadVecCoord");
	MarkNativeAsOptional("BfReadVecNormal");
	MarkNativeAsOptional("BfReadAngles");
	MarkNativeAsOptional("BfGetNumBytesLeft");
	MarkNativeAsOptional("BfWrite.WriteBool");
	MarkNativeAsOptional("BfWrite.WriteByte");
	MarkNativeAsOptional("BfWrite.WriteChar");
	MarkNativeAsOptional("BfWrite.WriteShort");
	MarkNativeAsOptional("BfWrite.WriteWord");
	MarkNativeAsOptional("BfWrite.WriteNum");
	MarkNativeAsOptional("BfWrite.WriteFloat");
	MarkNativeAsOptional("BfWrite.WriteString");
	MarkNativeAsOptional("BfWrite.WriteEntity");
	MarkNativeAsOptional("BfWrite.WriteAngle");
	MarkNativeAsOptional("BfWrite.WriteCoord");
	MarkNativeAsOptional("BfWrite.WriteVecCoord");
	MarkNativeAsOptional("BfWrite.WriteVecNormal");
	MarkNativeAsOptional("BfWrite.WriteAngles");
	MarkNativeAsOptional("BfRead.ReadBool");
	MarkNativeAsOptional("BfRead.ReadByte");
	MarkNativeAsOptional("BfRead.ReadChar");
	MarkNativeAsOptional("BfRead.ReadShort");
	MarkNativeAsOptional("BfRead.ReadWord");
	MarkNativeAsOptional("BfRead.ReadNum");
	MarkNativeAsOptional("BfRead.ReadFloat");
	MarkNativeAsOptional("BfRead.ReadString");
	MarkNativeAsOptional("BfRead.ReadEntity");
	MarkNativeAsOptional("BfRead.ReadAngle");
	MarkNativeAsOptional("BfRead.ReadCoord");
	MarkNativeAsOptional("BfRead.ReadVecCoord");
	MarkNativeAsOptional("BfRead.ReadVecNormal");
	MarkNativeAsOptional("BfRead.ReadAngles");
	MarkNativeAsOptional("BfRead.GetNumBytesLeft");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetFloat");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbSetColor");
	MarkNativeAsOptional("PbSetAngle");
	MarkNativeAsOptional("PbSetVector");
	MarkNativeAsOptional("PbSetVector2D");
	MarkNativeAsOptional("PbAddInt");
	MarkNativeAsOptional("PbAddFloat");
	MarkNativeAsOptional("PbAddBool");
	MarkNativeAsOptional("PbAddString");
	MarkNativeAsOptional("PbAddColor");
	MarkNativeAsOptional("PbAddAngle");
	MarkNativeAsOptional("PbAddVector");
	MarkNativeAsOptional("PbAddVector2D");
	MarkNativeAsOptional("PbRemoveRepeatedFieldValue");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	MarkNativeAsOptional("Protobuf.ReadInt");
	MarkNativeAsOptional("Protobuf.ReadFloat");
	MarkNativeAsOptional("Protobuf.ReadBool");
	MarkNativeAsOptional("Protobuf.ReadString");
	MarkNativeAsOptional("Protobuf.ReadColor");
	MarkNativeAsOptional("Protobuf.ReadAngle");
	MarkNativeAsOptional("Protobuf.ReadVector");
	MarkNativeAsOptional("Protobuf.ReadVector2D");
	MarkNativeAsOptional("Protobuf.GetRepeatedFieldCount");
	MarkNativeAsOptional("Protobuf.SetInt");
	MarkNativeAsOptional("Protobuf.SetFloat");
	MarkNativeAsOptional("Protobuf.SetBool");
	MarkNativeAsOptional("Protobuf.SetString");
	MarkNativeAsOptional("Protobuf.SetColor");
	MarkNativeAsOptional("Protobuf.SetAngle");
	MarkNativeAsOptional("Protobuf.SetVector");
	MarkNativeAsOptional("Protobuf.SetVector2D");
	MarkNativeAsOptional("Protobuf.AddInt");
	MarkNativeAsOptional("Protobuf.AddFloat");
	MarkNativeAsOptional("Protobuf.AddBool");
	MarkNativeAsOptional("Protobuf.AddString");
	MarkNativeAsOptional("Protobuf.AddColor");
	MarkNativeAsOptional("Protobuf.AddAngle");
	MarkNativeAsOptional("Protobuf.AddVector");
	MarkNativeAsOptional("Protobuf.AddVector2D");
	MarkNativeAsOptional("Protobuf.RemoveRepeatedFieldValue");
	MarkNativeAsOptional("Protobuf.ReadMessage");
	MarkNativeAsOptional("Protobuf.ReadRepeatedMessage");
	MarkNativeAsOptional("Protobuf.AddMessage");
	VerifyCoreVersion();
	return 0;
}

Float:operator++(Float:)(Float:oper)
{
	return oper + 1.0;
}

Float:operator*(Float:,_:)(Float:oper1, oper2)
{
	return oper1 * float(oper2);
}

Float:operator/(Float:,_:)(Float:oper1, oper2)
{
	return oper1 / float(oper2);
}

Float:operator/(_:,Float:)(oper1, Float:oper2)
{
	return float(oper1) / oper2;
}

Float:operator+(Float:,_:)(Float:oper1, oper2)
{
	return oper1 + float(oper2);
}

Float:operator-(Float:,_:)(Float:oper1, oper2)
{
	return oper1 - float(oper2);
}

bool:operator>(Float:,_:)(Float:oper1, oper2)
{
	return oper1 > float(oper2);
}

bool:operator<(Float:,_:)(Float:oper1, oper2)
{
	return oper1 < float(oper2);
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

StrCat(String:buffer[], maxlength, String:source[])
{
	new len = strlen(buffer);
	if (len >= maxlength)
	{
		return 0;
	}
	return Format(buffer[len], maxlength - len, "%s", source);
}

ExplodeString(String:text[], String:split[], String:buffers[][], maxStrings, maxStringLength, bool:copyRemainder)
{
	new reloc_idx;
	new idx;
	new total;
	new var1;
	if (maxStrings < 1 || !split[0])
	{
		return 0;
	}
	while ((idx = SplitString(text[reloc_idx], split, buffers[total], maxStringLength)) != -1)
	{
		reloc_idx = idx + reloc_idx;
		total++;
		if (maxStrings == total)
		{
			if (copyRemainder)
			{
				strcopy(buffers[total + -1], maxStringLength, text[reloc_idx - idx]);
			}
			return total;
		}
	}
	total++;
	strcopy(buffers[total], maxStringLength, text[reloc_idx]);
	return total;
}

Handle:StartMessageOne(String:msgname[], client, flags)
{
	new players[1];
	players[0] = client;
	return StartMessage(msgname, players, 1, flags);
}

PrintToChatAll(String:format[])
{
	decl String:buffer[192];
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 192, format, 2);
			PrintToChat(i, "%s", buffer);
		}
		i++;
	}
	return 0;
}

ShowMOTDPanel(client, String:title[], String:msg[], type)
{
	new String:num[4];
	IntToString(type, num, 3);
	new KeyValues:kv = KeyValues.KeyValues("data", "", "");
	KeyValues.SetString(kv, "title", title);
	KeyValues.SetString(kv, "type", num);
	KeyValues.SetString(kv, "msg", msg);
	ShowVGUIPanel(client, "info", kv, true);
	CloseHandle(kv);
	kv = MissingTAG:0;
	return 0;
}

ReplyToTargetError(client, reason)
{
	switch (reason)
	{
		case -7:
		{
			ReplyToCommand(client, "[SM] %t", "More than one client matched");
		}
		case -6:
		{
			ReplyToCommand(client, "[SM] %t", "Cannot target bot");
		}
		case -5:
		{
			ReplyToCommand(client, "[SM] %t", "No matching clients");
		}
		case -4:
		{
			ReplyToCommand(client, "[SM] %t", "Unable to target");
		}
		case -3:
		{
			ReplyToCommand(client, "[SM] %t", "Target is not in game");
		}
		case -2:
		{
			ReplyToCommand(client, "[SM] %t", "Target must be dead");
		}
		case -1:
		{
			ReplyToCommand(client, "[SM] %t", "Target must be alive");
		}
		case 0:
		{
			ReplyToCommand(client, "[SM] %t", "No matching client");
		}
		default:
		{
		}
	}
	return 0;
}

GetEntSendPropOffs(ent, String:prop[], bool:actual)
{
	decl String:cls[64];
	if (!GetEntityNetClass(ent, cls, 64))
	{
		return -1;
	}
	if (actual)
	{
		return FindSendPropInfo(cls, prop, 0, 0, 0);
	}
	return FindSendPropOffs(cls, prop);
}

SetEntityRenderColor(entity, r, g, b, a)
{
	static bool:gotconfig;
	static String:prop[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_clrRender", prop, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(prop, 32, "m_clrRender");
		}
		gotconfig = true;
	}
	new offset = GetEntSendPropOffs(entity, prop, false);
	if (0 >= offset)
	{
		ThrowError("SetEntityRenderColor not supported by this mod");
	}
	SetEntData(entity, offset, r, 1, true);
	SetEntData(entity, offset + 1, g, 1, true);
	SetEntData(entity, offset + 2, b, 1, true);
	SetEntData(entity, offset + 3, a, 1, true);
	return 0;
}

SetEntityHealth(entity, amount)
{
	static bool:gotconfig;
	static String:prop[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_iHealth", prop, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(prop, 32, "m_iHealth");
		}
		gotconfig = true;
	}
	decl String:cls[64];
	new PropFieldType:type;
	new offset;
	if (!GetEntityNetClass(entity, cls, 64))
	{
		ThrowError("SetEntityHealth not supported by this mod: Could not get serverclass name");
		return 0;
	}
	offset = FindSendPropInfo(cls, prop, type, 0, 0);
	if (0 >= offset)
	{
		ThrowError("SetEntityHealth not supported by this mod");
		return 0;
	}
	if (type == PropFieldType:2)
	{
		SetEntDataFloat(entity, offset, float(amount), false);
	}
	else
	{
		SetEntProp(entity, PropType:0, prop, amount, 4, 0);
	}
	return 0;
}

EmitSoundToClient(client, String:sample[], entity, channel, level, flags, Float:volume, pitch, speakerentity, Float:origin[3], Float:dir[3], bool:updatePos, Float:soundtime)
{
	new clients[1];
	clients[0] = client;
	new var1;
	if (entity == -2)
	{
		var1 = client;
	}
	else
	{
		var1 = entity;
	}
	entity = var1;
	EmitSound(clients, 1, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	return 0;
}

EmitSoundToAll(String:sample[], entity, channel, level, flags, Float:volume, pitch, speakerentity, Float:origin[3], Float:dir[3], bool:updatePos, Float:soundtime)
{
	new clients[MaxClients];
	new total;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			total++;
			clients[total] = i;
		}
		i++;
	}
	if (!total)
	{
		return 0;
	}
	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	return 0;
}

CPrintToChat(client, String:szMessage[])
{
	new var1;
	if (client <= 0 || client > MaxClients)
	{
		ThrowError("Invalid client index %d", client);
	}
	if (!IsClientInGame(client))
	{
		ThrowError("Client %d is not in game", client);
	}
	decl String:szBuffer[252];
	decl String:szCMessage[252];
	SetGlobalTransTarget(client);
	Format(szBuffer, 250, "\x01%s", szMessage);
	VFormat(szCMessage, 250, szBuffer, 3);
	new index = CFormat(szCMessage, 250, -1);
	if (index == -1)
	{
		PrintToChat(client, szCMessage);
	}
	else
	{
		CSayText2(client, index, szCMessage);
	}
	return 0;
}

CPrintToChatAll(String:szMessage[])
{
	decl String:szBuffer[252];
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientInGame(i) && !IsFakeClient(i) && !CSkipList[i])
		{
			SetGlobalTransTarget(i);
			VFormat(szBuffer, 250, szMessage, 2);
			CPrintToChat(i, szBuffer);
		}
		CSkipList[i] = 0;
		i++;
	}
	return 0;
}

CFormat(String:szMessage[], maxlength, author)
{
	if (!CEventIsHooked)
	{
		CSetupProfile();
		HookEvent("server_spawn", CEvent_MapStart, EventHookMode:2);
		CEventIsHooked = true;
	}
	new iRandomPlayer = -1;
	if (author != -1)
	{
		if (CProfile_SayText2)
		{
			ReplaceString(szMessage, maxlength, "{teamcolor}", "\x03", true);
			iRandomPlayer = author;
		}
		else
		{
			ReplaceString(szMessage, maxlength, "{teamcolor}", CTagCode[1], true);
		}
	}
	else
	{
		ReplaceString(szMessage, maxlength, "{teamcolor}", "", true);
	}
	new i;
	while (i < 6)
	{
		if (!(StrContains(szMessage, CTag[i], true) == -1))
		{
			if (!CProfile_Colors[i])
			{
				ReplaceString(szMessage, maxlength, CTag[i], CTagCode[1], true);
			}
			else
			{
				if (!CTagReqSayText2[i])
				{
					ReplaceString(szMessage, maxlength, CTag[i], CTagCode[i], true);
				}
				if (!CProfile_SayText2)
				{
					ReplaceString(szMessage, maxlength, CTag[i], CTagCode[1], true);
				}
				if (iRandomPlayer == -1)
				{
					iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i]);
					if (iRandomPlayer == -2)
					{
						ReplaceString(szMessage, maxlength, CTag[i], CTagCode[1], true);
					}
					else
					{
						ReplaceString(szMessage, maxlength, CTag[i], CTagCode[i], true);
					}
				}
				ThrowError("Using two team colors in one message is not allowed");
			}
		}
		i++;
	}
	return iRandomPlayer;
}

CFindRandomPlayerByTeam(color_team)
{
	if (color_team)
	{
		new i = 1;
		while (i <= MaxClients)
		{
			new var1;
			if (IsClientInGame(i) && color_team == GetClientTeam(i))
			{
				return i;
			}
			i++;
		}
		return -2;
	}
	return 0;
}

CSayText2(client, author, String:szMessage[])
{
	new Handle:hBuffer = StartMessageOne("SayText2", client, 0);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, 1);
	BfWriteString(hBuffer, szMessage);
	EndMessage();
	return 0;
}

CSetupProfile()
{
	decl String:szGameName[32];
	GetGameFolderName(szGameName, 30);
	if (StrEqual(szGameName, "cstrike", false))
	{
		CProfile_Colors[2] = 1;
		CProfile_Colors[3] = 1;
		CProfile_Colors[4] = 1;
		CProfile_Colors[5] = 1;
		CProfile_TeamIndex[2] = 0;
		CProfile_TeamIndex[3] = 2;
		CProfile_TeamIndex[4] = 3;
		CProfile_SayText2 = true;
	}
	else
	{
		if (StrEqual(szGameName, "tf", false))
		{
			CProfile_Colors[2] = 1;
			CProfile_Colors[3] = 1;
			CProfile_Colors[4] = 1;
			CProfile_Colors[5] = 1;
			CProfile_TeamIndex[2] = 0;
			CProfile_TeamIndex[3] = 2;
			CProfile_TeamIndex[4] = 3;
			CProfile_SayText2 = true;
		}
		new var1;
		if (StrEqual(szGameName, "left4dead", false) || StrEqual(szGameName, "left4dead2", false))
		{
			CProfile_Colors[2] = 1;
			CProfile_Colors[3] = 1;
			CProfile_Colors[4] = 1;
			CProfile_Colors[5] = 1;
			CProfile_TeamIndex[2] = 0;
			CProfile_TeamIndex[3] = 3;
			CProfile_TeamIndex[4] = 2;
			CProfile_SayText2 = true;
		}
		if (StrEqual(szGameName, "hl2mp", false))
		{
			if (GetConVarBool(FindConVar("mp_teamplay")))
			{
				CProfile_Colors[3] = 1;
				CProfile_Colors[4] = 1;
				CProfile_Colors[5] = 1;
				CProfile_TeamIndex[3] = 3;
				CProfile_TeamIndex[4] = 2;
				CProfile_SayText2 = true;
			}
			else
			{
				CProfile_SayText2 = false;
				CProfile_Colors[5] = 1;
			}
		}
		if (StrEqual(szGameName, "dod", false))
		{
			CProfile_Colors[5] = 1;
			CProfile_SayText2 = false;
		}
		if (GetUserMessageId("SayText2") == -1)
		{
			CProfile_SayText2 = false;
		}
		CProfile_Colors[3] = 1;
		CProfile_Colors[4] = 1;
		CProfile_TeamIndex[3] = 2;
		CProfile_TeamIndex[4] = 3;
		CProfile_SayText2 = true;
	}
	return 0;
}

public Action:CEvent_MapStart(Handle:event, String:name[], bool:dontBroadcast)
{
	CSetupProfile();
	new i = 1;
	while (i <= MaxClients)
	{
		CSkipList[i] = 0;
		i++;
	}
	return Action:0;
}

public CoopAutoDiffOnPluginStart()
{
	UpTime = GetTime({0,0});
	hm_autodifficulty = CreateConVar("hm_autodifficulty", "1", "Is the plugin enabled.", 262144, false, 0.0, false, 0.0);
	hm_autodifficulty_forcehp = CreateConVar("hm_autodifficulty_forcehp", "0", "", 262144, false, 0.0, false, 0.0);
	hm_loot_mod = CreateConVar("hm_loot_mod", "1.0", "", 262144, false, 0.0, false, 0.0);
	hm_tank_hp_mod = CreateConVar("hm_tank_hp_mod", "1.0", "", 262144, false, 0.0, false, 0.0);
	hm_infected_hp_mod = CreateConVar("hm_infected_hp_mod", "1.0", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_time_mod = CreateConVar("hm_spawn_time_mod", "1.0", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_count_mod = CreateConVar("hm_spawn_count_mod", "1.0", "", 262144, false, 0.0, false, 0.0);
	z_difficulty = FindConVar("z_difficulty");
	HookConVarChange(z_difficulty, z_difficulty_changed);
	z_special_spawn_interval = FindConVar("z_special_spawn_interval");
	director_special_respawn_interval = FindConVar("director_special_respawn_interval");
	z_max_player_zombies = FindConVar("z_max_player_zombies");
	hm_auto_tongue_range_min = CreateConVar("hm_auto_tongue_range_min", "750", "", 262144, false, 0.0, false, 0.0);
	hm_auto_tongue_range_max = CreateConVar("hm_auto_tongue_range_max", "1500", "", 262144, false, 0.0, false, 0.0);
	hm_auto_tongue_miss_delay_min = CreateConVar("hm_auto_tongue_miss_delay_min", "5", "Минимальное время перезарядки языка при промахе.", 262144, false, 0.0, false, 0.0);
	hm_auto_tongue_miss_delay_max = CreateConVar("hm_auto_tongue_miss_delay_max", "15", "Максимальное время перезарядки языка при промахе.", 262144, false, 0.0, false, 0.0);
	hm_auto_tongue_hit_delay_min = CreateConVar("hm_auto_tongue_hit_delay_min", "5", "Минимальное время перезарядки языка, после отпускания (не важно по какой причине) предыдущей жертвы.", 262144, false, 0.0, false, 0.0);
	hm_auto_tongue_hit_delay_max = CreateConVar("hm_auto_tongue_hit_delay_max", "20", "Максимальное время перезарядки языка, после отпускания (не важно по какой причине) предыдущей жертвы.", 262144, false, 0.0, false, 0.0);
	hm_auto_tongue_choke_dmg_min = CreateConVar("hm_auto_tongue_choke_dmg_min", "24", "", 262144, false, 0.0, false, 0.0);
	hm_auto_tongue_choke_dmg_max = CreateConVar("hm_auto_tongue_choke_dmg_max", "67", "", 262144, false, 0.0, false, 0.0);
	hm_auto_tongue_drag_dmg_min = CreateConVar("hm_auto_tongue_drag_dmg_min", "9", "", 262144, false, 0.0, false, 0.0);
	hm_auto_tongue_drag_dmg_max = CreateConVar("hm_auto_tongue_drag_dmg_max", "35", "", 262144, false, 0.0, false, 0.0);
	hm_auto_smoker_pz_claw_dmg_min = CreateConVar("hm_auto_smoker_pz_claw_dmg_min", "5", "", 262144, false, 0.0, false, 0.0);
	hm_auto_smoker_pz_claw_dmg_max = CreateConVar("hm_auto_smoker_pz_claw_dmg_max", "18", "", 262144, false, 0.0, false, 0.0);
	hm_auto_jockey_pz_claw_dmg_min = CreateConVar("hm_auto_jockey_pz_claw_dmg_min", "5", "", 262144, false, 0.0, false, 0.0);
	hm_auto_jockey_pz_claw_dmg_max = CreateConVar("hm_auto_jockey_pz_claw_dmg_max", "18", "", 262144, false, 0.0, false, 0.0);
	hm_auto_grenade_lr_dmg_min = CreateConVar("hm_auto_grenade_lr_dmg_min", "400", "", 262144, false, 0.0, false, 0.0);
	hm_auto_grenade_lr_dmg_max = CreateConVar("hm_auto_grenade_lr_dmg_max", "4000", "", 262144, false, 0.0, false, 0.0);
	hm_damage_ak47_min = CreateConVar("hm_damage_ak47_min", "2523", "", 262144, false, 0.0, false, 0.0);
	hm_damage_ak47_max = CreateConVar("hm_damage_ak47_max", "11160", "", 262144, false, 0.0, false, 0.0);
	hm_damage_awp_min = CreateConVar("hm_damage_awp_min", "9486", "", 262144, false, 0.0, false, 0.0);
	hm_damage_awp_max = CreateConVar("hm_damage_awp_max", "39272", "", 262144, false, 0.0, false, 0.0);
	hm_damage_m60_min = CreateConVar("hm_damage_m60_min", "1652", "", 262144, false, 0.0, false, 0.0);
	hm_damage_m60_max = CreateConVar("hm_damage_m60_max", "9812", "", 262144, false, 0.0, false, 0.0);
	hm_damage_scout_min = CreateConVar("hm_damage_scout_min", "4667", "", 262144, false, 0.0, false, 0.0);
	hm_damage_scout_max = CreateConVar("hm_damage_scout_max", "20286", "", 262144, false, 0.0, false, 0.0);
	hm_damage_sg552_min = CreateConVar("hm_damage_sg552_min", "1111", "", 262144, false, 0.0, false, 0.0);
	hm_damage_sg552_max = CreateConVar("hm_damage_sg552_max", "4500", "", 262144, false, 0.0, false, 0.0);
	hm_damage_spas_min = CreateConVar("hm_damage_spas_min", "3000", "", 262144, false, 0.0, false, 0.0);
	hm_damage_spas_max = CreateConVar("hm_damage_spas_max", "12430", "", 262144, false, 0.0, false, 0.0);
	hm_damage_sniper_military_min = CreateConVar("hm_damage_sniper_military_min", "1055", "", 262144, false, 0.0, false, 0.0);
	hm_damage_sniper_military_max = CreateConVar("hm_damage_sniper_military_max", "2000", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_ak47_min = CreateConVar("hm_damage2_ak47_min", "140", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_ak47_max = CreateConVar("hm_damage2_ak47_max", "600", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_awp_min = CreateConVar("hm_damage2_awp_min", "700", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_awp_max = CreateConVar("hm_damage2_awp_max", "4000", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_m60_min = CreateConVar("hm_damage2_m60_min", "85", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_m60_max = CreateConVar("hm_damage2_m60_max", "490", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_scout_min = CreateConVar("hm_damage2_scout_min", "420", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_scout_max = CreateConVar("hm_damage2_scout_max", "1820", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_sg552_min = CreateConVar("hm_damage2_sg552_min", "70", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_sg552_max = CreateConVar("hm_damage2_sg552_max", "250", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_spas_min = CreateConVar("hm_damage2_spas_min", "60", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_spas_max = CreateConVar("hm_damage2_spas_max", "250", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_sniper_military_min = CreateConVar("hm_damage2_sniper_military_min", "50", "", 262144, false, 0.0, false, 0.0);
	hm_damage2_sniper_military_max = CreateConVar("hm_damage2_sniper_military_max", "150", "", 262144, false, 0.0, false, 0.0);
	hm_meleefix_min = CreateConVar("hm_meleefix_min", "650", "", 262144, false, 0.0, false, 0.0);
	hm_meleefix_max = CreateConVar("hm_meleefix_max", "3200", "", 262144, false, 0.0, false, 0.0);
	hm_meleefix_headshot_min = CreateConVar("hm_meleefix_headshot_min", "900", "", 262144, false, 0.0, false, 0.0);
	hm_meleefix_headshot_max = CreateConVar("hm_meleefix_headshot_max", "3800", "", 262144, false, 0.0, false, 0.0);
	hm_meleefix_tank_min = CreateConVar("hm_meleefix_tank_min", "700", "", 262144, false, 0.0, false, 0.0);
	hm_meleefix_tank_max = CreateConVar("hm_meleefix_tank_max", "4000", "", 262144, false, 0.0, false, 0.0);
	hm_meleefix_tank_headshot_min = CreateConVar("hm_meleefix_tank_headshot_min", "1400", "", 262144, false, 0.0, false, 0.0);
	hm_meleefix_tank_headshot_max = CreateConVar("hm_meleefix_tank_headshot_max", "5000", "", 262144, false, 0.0, false, 0.0);
	hm_meleefix_witch_min = CreateConVar("hm_meleefix_witch_min", "200", "", 262144, false, 0.0, false, 0.0);
	hm_meleefix_witch_max = CreateConVar("hm_meleefix_witch_max", "360", "", 262144, false, 0.0, false, 0.0);
	hm_special_infected_min = CreateConVar("hm_special_infected_min", "4", "", 262144, false, 0.0, false, 0.0);
	hm_special_infected_max = CreateConVar("hm_special_infected_max", "6", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_interval_min = CreateConVar("hm_spawn_interval_min", "8", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_interval_max = CreateConVar("hm_spawn_interval_max", "16", "", 262144, false, 0.0, false, 0.0);
	hm_tank_burn_duration_min = CreateConVar("hm_tank_burn_duration_min", "75", "", 262144, false, 0.0, false, 0.0);
	hm_tank_burn_duration_max = CreateConVar("hm_tank_burn_duration_max", "250", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_automod = CreateConVar("hm_autohp_automod", "1", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_supercharger_auto = CreateConVar("hm_autohp_supercharger_auto", "0", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_zombie_min = CreateConVar("hm_autohp_zombie_min", "50", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_zombie_max = CreateConVar("hm_autohp_zombie_max", "120", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_hunter_min = CreateConVar("hm_autohp_hunter_min", "250", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_hunter_max = CreateConVar("hm_autohp_hunter_max", "2500", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_smoker_min = CreateConVar("hm_autohp_smoker_min", "250", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_smoker_max = CreateConVar("hm_autohp_smoker_max", "2800", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_boomer_min = CreateConVar("hm_autohp_boomer_min", "100", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_boomer_max = CreateConVar("hm_autohp_boomer_max", "1000", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_jockey_min = CreateConVar("hm_autohp_jockey_min", "325", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_jockey_max = CreateConVar("hm_autohp_jockey_max", "3200", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_spitter_min = CreateConVar("hm_autohp_spitter_min", "100", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_spitter_max = CreateConVar("hm_autohp_spitter_max", "1700", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_charger_min = CreateConVar("hm_autohp_charger_min", "600", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_charger_max = CreateConVar("hm_autohp_charger_max", "3400", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_witch_min = CreateConVar("hm_autohp_witch_min", "1000", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_witch_max = CreateConVar("hm_autohp_witch_max", "1800", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_tank_min = CreateConVar("hm_autohp_tank_min", "16000", "", 262144, false, 0.0, false, 0.0);
	hm_autohp_tank_max = CreateConVar("hm_autohp_tank_max", "150000", "", 262144, false, 0.0, false, 0.0);
	hm_items_automod = CreateConVar("hm_items_automod", "1", "", 262144, false, 0.0, false, 0.0);
	hm_items_supercharger_auto = CreateConVar("hm_items_supercharger_auto", "2", "", 262144, false, 0.0, false, 0.0);
	hm_items_hunter_min = CreateConVar("hm_items_hunter_min", "1", "", 262144, false, 0.0, false, 0.0);
	hm_items_hunter_max = CreateConVar("hm_items_hunter_max", "3", "", 262144, false, 0.0, false, 0.0);
	hm_items_smoker_min = CreateConVar("hm_items_smoker_min", "1", "", 262144, false, 0.0, false, 0.0);
	hm_items_smoker_max = CreateConVar("hm_items_smoker_max", "3", "", 262144, false, 0.0, false, 0.0);
	hm_items_boomer_min = CreateConVar("hm_items_boomer_min", "1", "", 262144, false, 0.0, false, 0.0);
	hm_items_boomer_max = CreateConVar("hm_items_boomer_max", "3", "", 262144, false, 0.0, false, 0.0);
	hm_items_jockey_min = CreateConVar("hm_items_jockey_min", "1", "", 262144, false, 0.0, false, 0.0);
	hm_items_jockey_max = CreateConVar("hm_items_jockey_max", "3", "", 262144, false, 0.0, false, 0.0);
	hm_items_charger_min = CreateConVar("hm_items_charger_min", "2", "", 262144, false, 0.0, false, 0.0);
	hm_items_charger_max = CreateConVar("hm_items_charger_max", "4", "", 262144, false, 0.0, false, 0.0);
	hm_items_spitter_min = CreateConVar("hm_items_spitter_min", "1", "", 262144, false, 0.0, false, 0.0);
	hm_items_spitter_max = CreateConVar("hm_items_spitter_max", "3", "", 262144, false, 0.0, false, 0.0);
	hm_items_tank_min = CreateConVar("hm_items_tank_min", "7", "", 262144, false, 0.0, false, 0.0);
	hm_items_tank_max = CreateConVar("hm_items_tank_max", "24", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_automod = CreateConVar("hm_spawn_automod", "1", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_zombie_min = CreateConVar("hm_spawn_zombie_min", "15", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_zombie_max = CreateConVar("hm_spawn_zombie_max", "10", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_hunter_min = CreateConVar("hm_spawn_hunter_min", "1", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_hunter_max = CreateConVar("hm_spawn_hunter_max", "3", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_smoker_min = CreateConVar("hm_spawn_smoker_min", "1", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_smoker_max = CreateConVar("hm_spawn_smoker_max", "3", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_boomer_min = CreateConVar("hm_spawn_boomer_min", "1", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_boomer_max = CreateConVar("hm_spawn_boomer_max", "4", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_jockey_min = CreateConVar("hm_spawn_jockey_min", "1", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_jockey_max = CreateConVar("hm_spawn_jockey_max", "3", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_spitter_min = CreateConVar("hm_spawn_spitter_min", "1", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_spitter_max = CreateConVar("hm_spawn_spitter_max", "3", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_charger_min = CreateConVar("hm_spawn_charger_min", "1", "", 262144, false, 0.0, false, 0.0);
	hm_spawn_charger_max = CreateConVar("hm_spawn_charger_max", "3", "", 262144, false, 0.0, false, 0.0);
	hm_speed_automod = CreateConVar("hm_speed_automod", "1", "", 262144, false, 0.0, false, 0.0);
	hm_speed_hunter_min = CreateConVar("hm_speed_hunter_min", "300", "", 262144, false, 0.0, false, 0.0);
	hm_speed_hunter_max = CreateConVar("hm_speed_hunter_max", "350", "", 262144, false, 0.0, false, 0.0);
	hm_speed_smoker_min = CreateConVar("hm_speed_smoker_min", "210", "", 262144, false, 0.0, false, 0.0);
	hm_speed_smoker_max = CreateConVar("hm_speed_smoker_max", "315", "", 262144, false, 0.0, false, 0.0);
	hm_speed_boomer_min = CreateConVar("hm_speed_boomer_min", "175", "", 262144, false, 0.0, false, 0.0);
	hm_speed_boomer_max = CreateConVar("hm_speed_boomer_max", "280", "", 262144, false, 0.0, false, 0.0);
	hm_speed_jockey_min = CreateConVar("hm_speed_jockey_min", "250", "", 262144, false, 0.0, false, 0.0);
	hm_speed_jockey_max = CreateConVar("hm_speed_jockey_max", "300", "", 262144, false, 0.0, false, 0.0);
	hm_speed_charger_min = CreateConVar("hm_speed_charger_min", "250", "", 262144, false, 0.0, false, 0.0);
	hm_speed_charger_max = CreateConVar("hm_speed_charger_max", "300", "", 262144, false, 0.0, false, 0.0);
	hm_speed_spitter_min = CreateConVar("hm_speed_spitter_min", "210", "", 262144, false, 0.0, false, 0.0);
	hm_speed_spitter_max = CreateConVar("hm_speed_spitter_max", "315", "", 262144, false, 0.0, false, 0.0);
	hm_speed_tank_min = CreateConVar("hm_speed_tank_min", "210", "", 262144, false, 0.0, false, 0.0);
	hm_speed_tank_max = CreateConVar("hm_speed_tank_max", "315", "", 262144, false, 0.0, false, 0.0);
	RegAdminCmd("sm_autodifficulty_init", Command_AutoDifficultyInit, 256, "", "", 0);
	RegAdminCmd("sm_autodifficulty_refresh", Command_AutoDifficultyRefresh, 256, "", "", 0);
	RegAdminCmd("sm_check", Command_Check, 256, "", "", 0);
	RegAdminCmd("sm_spawn_limits", Command_SpawnLimits, 256, "", "", 0);
	RegConsoleCmd("sm_rankmod", Command_RankMod, "", 0);
	RegConsoleCmd("sm_ddfull", Command_ddfull, "", 0);
	RegConsoleCmd("sm_damage", Command_damage, "", 0);
	RegConsoleCmd("sm_chance", Command_ammo, "", 0);
	RegConsoleCmd("sm_melee", Command_melee, "", 0);
	RegConsoleCmd("sm_info1", Command_info2, "", 0);
	RegConsoleCmd("sm_pinfo", Command_pinfo, "", 0);
	RegAdminCmd("sm_swd", Command_swd, 2, "sm_swd", "", 0);
	RegAdminCmd("sm_swdoff", Command_swdoff, 2, "sm_swdoff", "", 0);
	HookConVarChange(FindConVar("sv_maxplayers"), cvar_maxplayers_changed);
	RegConsoleCmd("say", cmd_Say, "", 0);
	RegConsoleCmd("say_team", cmd_Say, "", 0);
	return 0;
}

ADOnMapStart()
{
	g_IsTimeAutodifficulty = false;
	return 0;
}

ADRoundStart()
{
	if (FindConVar("monsterbots_interval"))
	{
		l4d2_plugin_monsterbots = true;
	}
	else
	{
		l4d2_plugin_monsterbots = false;
	}
	if (!l4d2_plugin_monsterbots)
	{
		new flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
		SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBounds:0, false, 0.0);
		SetConVarFlags(FindConVar("z_max_player_zombies"), flags & -257);
	}
	cvar_maxplayers = GetConVarInt(FindConVar("sv_maxplayers")) + -5;
	CreateTimer(25.0, g_TimedAutoDifficultyInit, any:0, 0);
	return 0;
}

public Action:g_TimedAutoDifficultyInit(Handle:timer, any:client)
{
	g_IsTimeAutodifficulty = true;
	return Action:0;
}

public Action:Command_AutoDifficultyInit(client, args)
{
	AutoDifficultyInit();
	return Action:0;
}

public Action:Command_AutoDifficultyRefresh(client, args)
{
	new var1;
	if (GetRealtyClientCount(true) > 0 && g_IsTimeAutodifficulty)
	{
		Autodifficulty();
	}
	return Action:0;
}

public Action:Command_Check(client, args)
{
	PrintToServer("hm_autohp_charger_min = %d, hm_autohp_charger_max = %d, sv_maxplayers = %d", GetConVarInt(hm_autohp_charger_min), GetConVarInt(hm_autohp_charger_max), cvar_maxplayers);
	new i = 4;
	while (i <= MaxClients)
	{
		PrintToServer("AutodifficultyItems[%d][ZC_SMOKER] = %d | AutodifficultyHP[%d][ZC_CHARGER] = %d", i, AutodifficultyItems[i][1], i, AutodifficultyHP[i][6]);
		i++;
	}
	return Action:0;
}

public Action:Command_SpawnLimits(client, args)
{
	if (client)
	{
		PrintToChat(client, "z_common_limit = %d", GetConVarInt(FindConVar("z_common_limit")));
		PrintToChat(client, "z_hunter_limit = %d", GetConVarInt(FindConVar("z_hunter_limit")));
		PrintToChat(client, "z_smoker_limit = %d", GetConVarInt(FindConVar("z_smoker_limit")));
		PrintToChat(client, "z_boomer_limit = %d", GetConVarInt(FindConVar("z_boomer_limit")));
		PrintToChat(client, "z_spitter_limit = %d", GetConVarInt(FindConVar("z_spitter_limit")));
		PrintToChat(client, "z_jockey_limit = %d", GetConVarInt(FindConVar("z_jockey_limit")));
		PrintToChat(client, "z_charger_limit = %d", GetConVarInt(FindConVar("z_charger_limit")));
	}
	else
	{
		PrintToServer("z_common_limit = %d", GetConVarInt(FindConVar("z_common_limit")));
		PrintToServer("z_hunter_limit = %d (spawned %d)", GetConVarInt(FindConVar("z_hunter_limit")), CountMonsters(3));
		PrintToServer("z_smoker_limit = %d (spawned %d)", GetConVarInt(FindConVar("z_smoker_limit")), CountMonsters(1));
		PrintToServer("z_boomer_limit = %d (spawned %d)", GetConVarInt(FindConVar("z_boomer_limit")), CountMonsters(2));
		PrintToServer("z_spitter_limit = %d (spawned %d)", GetConVarInt(FindConVar("z_spitter_limit")), CountMonsters(4));
		PrintToServer("z_jockey_limit = %d (spawned %d)", GetConVarInt(FindConVar("z_jockey_limit")), CountMonsters(5));
		PrintToServer("z_charger_limit = %d (spawned %d)", GetConVarInt(FindConVar("z_charger_limit")), CountMonsters(6));
	}
	return Action:0;
}

CountMonsters(ZOMBIE_CLASS)
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		if (ZOMBIE_CLASS == GetClientZC(i))
		{
			count++;
		}
		i++;
	}
	return count;
}

public z_difficulty_changed(Handle:hVariable, String:strOldValue[], String:strNewValue[])
{
	UpdateDifficultyName();
	return 0;
}

public hm_ad_options_changed(Handle:hVariable, String:strOldValue[], String:strNewValue[])
{
	AutoDifficultyInit();
	return 0;
}

UpdateDifficultyName()
{
	GetConVarString(z_difficulty, sGameDifficulty, 16);
	if (ReplaceString(sGameDifficulty, 16, "Impossible", "Expert", false))
	{
		cvar_difficulty = 4;
	}
	else
	{
		if (ReplaceString(sGameDifficulty, 16, "Hard", "Master", false))
		{
			cvar_difficulty = 3;
		}
	}
	return 0;
}

AutoDifficultyInit()
{
	UpdateDifficultyName();
	if (!cvar_maxplayers)
	{
		cvar_maxplayers = GetConVarInt(FindConVar("sv_maxplayers")) + -5;
	}
	if (cvar_maxplayers < 1)
	{
		return 0;
	}
	damage_type = FindConVar("hm_damage_type");
	if (FindConVar("l4d2_loot_h_drop_items"))
	{
		l4d2_plugin_loot = true;
	}
	else
	{
		l4d2_plugin_loot = false;
	}
	if (FindConVar("monsterbots_interval"))
	{
		l4d2_plugin_monsterbots = true;
	}
	else
	{
		l4d2_plugin_monsterbots = false;
	}
	new var1;
	if (FindConVar("l4d2_charger_steering_allow") && GetConVarInt(FindConVar("l4d2_charger_steering_allow")) > 0 && GetConVarFloat(hm_autohp_supercharger_auto) > 0)
	{
		extra_charger = true;
	}
	else
	{
		extra_charger = false;
	}
	new i = 4;
	while (i <= MaxClients)
	{
		AutodifficultyHP[i][0] = GetLineFunction(GetConVarInt(hm_autohp_zombie_min), GetConVarInt(hm_autohp_zombie_max), i);
		AutodifficultyHP[i][1] = GetLineFunction(GetConVarInt(hm_autohp_smoker_min), GetConVarInt(hm_autohp_smoker_max), i);
		AutodifficultyHP[i][2] = GetLineFunction(GetConVarInt(hm_autohp_boomer_min), GetConVarInt(hm_autohp_boomer_max), i);
		AutodifficultyHP[i][3] = GetLineFunction(GetConVarInt(hm_autohp_hunter_min), GetConVarInt(hm_autohp_hunter_max), i);
		AutodifficultyHP[i][4] = GetLineFunction(GetConVarInt(hm_autohp_spitter_min), GetConVarInt(hm_autohp_spitter_max), i);
		AutodifficultyHP[i][5] = GetLineFunction(GetConVarInt(hm_autohp_jockey_min), GetConVarInt(hm_autohp_jockey_max), i);
		AutodifficultyHP[i][6] = GetLineFunction(GetConVarInt(hm_autohp_charger_min), GetConVarInt(hm_autohp_charger_max), i);
		AutodifficultyHP[i][7] = GetLineFunction(GetConVarInt(hm_autohp_witch_min), GetConVarInt(hm_autohp_witch_max), i);
		AutodifficultyHP[i][8] = RoundToNearest(GetLineFunction(GetConVarInt(hm_autohp_tank_min), GetConVarInt(hm_autohp_tank_max), i) / 1073741824);
		if (l4d2_plugin_loot)
		{
			AutodifficultyItems[i][1] = GetLineFunction(GetConVarInt(hm_items_smoker_min), GetConVarInt(hm_items_smoker_max), i);
			AutodifficultyItems[i][2] = GetLineFunction(GetConVarInt(hm_items_boomer_min), GetConVarInt(hm_items_boomer_max), i);
			AutodifficultyItems[i][3] = GetLineFunction(GetConVarInt(hm_items_hunter_min), GetConVarInt(hm_items_hunter_max), i);
			AutodifficultyItems[i][4] = GetLineFunction(GetConVarInt(hm_items_spitter_min), GetConVarInt(hm_items_spitter_max), i);
			AutodifficultyItems[i][5] = GetLineFunction(GetConVarInt(hm_items_jockey_min), GetConVarInt(hm_items_jockey_max), i);
			AutodifficultyItems[i][6] = GetLineFunction(GetConVarInt(hm_items_charger_min), GetConVarInt(hm_items_charger_max), i);
			AutodifficultyItems[i][8] = GetLineFunction(GetConVarInt(hm_items_tank_min), GetConVarInt(hm_items_tank_max), i);
		}
		AutodifficultySpawnLimit[i][0] = GetLineFunction(GetConVarInt(hm_spawn_zombie_min), GetConVarInt(hm_spawn_zombie_max), i);
		AutodifficultySpawnLimit[i][1] = GetLineFunction(GetConVarInt(hm_spawn_smoker_min), GetConVarInt(hm_spawn_smoker_max), i);
		AutodifficultySpawnLimit[i][2] = GetLineFunction(GetConVarInt(hm_spawn_boomer_min), GetConVarInt(hm_spawn_boomer_max), i);
		AutodifficultySpawnLimit[i][3] = GetLineFunction(GetConVarInt(hm_spawn_hunter_min), GetConVarInt(hm_spawn_hunter_max), i);
		AutodifficultySpawnLimit[i][4] = GetLineFunction(GetConVarInt(hm_spawn_spitter_min), GetConVarInt(hm_spawn_spitter_max), i);
		AutodifficultySpawnLimit[i][5] = GetLineFunction(GetConVarInt(hm_spawn_jockey_min), GetConVarInt(hm_spawn_jockey_max), i);
		AutodifficultySpawnLimit[i][6] = GetLineFunction(GetConVarInt(hm_spawn_charger_min), GetConVarInt(hm_spawn_charger_max), i);
		AutodifficultySpeed[i][1] = GetLineFunction(GetConVarInt(hm_speed_smoker_min), GetConVarInt(hm_speed_smoker_max), i);
		AutodifficultySpeed[i][2] = GetLineFunction(GetConVarInt(hm_speed_boomer_min), GetConVarInt(hm_speed_boomer_max), i);
		AutodifficultySpeed[i][3] = GetLineFunction(GetConVarInt(hm_speed_hunter_min), GetConVarInt(hm_speed_hunter_max), i);
		AutodifficultySpeed[i][4] = GetLineFunction(GetConVarInt(hm_speed_spitter_min), GetConVarInt(hm_speed_spitter_max), i);
		AutodifficultySpeed[i][5] = GetLineFunction(GetConVarInt(hm_speed_jockey_min), GetConVarInt(hm_speed_jockey_max), i);
		AutodifficultySpeed[i][6] = GetLineFunction(GetConVarInt(hm_speed_charger_min), GetConVarInt(hm_speed_charger_max), i);
		AutodifficultySpeed[i][8] = GetLineFunction(GetConVarInt(hm_speed_tank_min), GetConVarInt(hm_speed_tank_max), i);
		AutodifficultySpawnInterval[i] = GetLineFunction(GetConVarInt(hm_spawn_interval_max), GetConVarInt(hm_spawn_interval_min), i);
		AutodifficultySpawnCount[i] = GetLineFunction(GetConVarInt(hm_special_infected_min), GetConVarInt(hm_special_infected_max), i);
		AutodifficultyTongueRange[i] = GetLineFunction(GetConVarInt(hm_auto_tongue_range_min), GetConVarInt(hm_auto_tongue_range_max), i);
		AutodifficultyTongueMissDelay[i] = GetLineFunction(GetConVarInt(hm_auto_tongue_miss_delay_max), GetConVarInt(hm_auto_tongue_miss_delay_min), i);
		AutodifficultyTongueHitDelay[i] = GetLineFunction(GetConVarInt(hm_auto_tongue_hit_delay_max), GetConVarInt(hm_auto_tongue_hit_delay_min), i);
		AutodifficultyTongueChokeDmg[i] = GetLineFunction(GetConVarInt(hm_auto_tongue_choke_dmg_min), GetConVarInt(hm_auto_tongue_choke_dmg_max), i);
		AutodifficultyTongueDragDmg[i] = GetLineFunction(GetConVarInt(hm_auto_tongue_drag_dmg_min), GetConVarInt(hm_auto_tongue_drag_dmg_max), i);
		AutodifficultySmokerClawDmg[i] = GetLineFunction(GetConVarInt(hm_auto_smoker_pz_claw_dmg_min), GetConVarInt(hm_auto_smoker_pz_claw_dmg_max), i);
		AutodifficultyJockeyClawDmg[i] = GetLineFunction(GetConVarInt(hm_auto_jockey_pz_claw_dmg_min), GetConVarInt(hm_auto_jockey_pz_claw_dmg_max), i);
		AutodifficultyGrenadeLRDmg[i] = GetLineFunction(GetConVarInt(hm_auto_grenade_lr_dmg_min), GetConVarInt(hm_auto_grenade_lr_dmg_max), i);
		AutodifficultyTankBurnTime[i] = GetLineFunction(GetConVarInt(hm_tank_burn_duration_min), GetConVarInt(hm_tank_burn_duration_max), i);
		if (GetConVarInt(damage_type) == 1)
		{
			Autodifficulty_ak47_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage_ak47_min), GetConVarInt(hm_damage_ak47_max), i);
			Autodifficulty_awp_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage_awp_min), GetConVarInt(hm_damage_awp_max), i);
			Autodifficulty_m60_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage_m60_min), GetConVarInt(hm_damage_m60_max), i);
			Autodifficulty_scout_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage_scout_min), GetConVarInt(hm_damage_scout_max), i);
			Autodifficulty_sg552_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage_sg552_min), GetConVarInt(hm_damage_sg552_max), i);
			Autodifficulty_spas_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage_spas_min), GetConVarInt(hm_damage_spas_max), i);
			Autodifficulty_sniper_military_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage_sniper_military_min), GetConVarInt(hm_damage_sniper_military_max), i);
		}
		else
		{
			if (GetConVarInt(damage_type) == 2)
			{
				Autodifficulty_ak47_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage2_ak47_min), GetConVarInt(hm_damage2_ak47_max), i);
				Autodifficulty_awp_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage2_awp_min), GetConVarInt(hm_damage2_awp_max), i);
				Autodifficulty_m60_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage2_m60_min), GetConVarInt(hm_damage2_m60_max), i);
				Autodifficulty_scout_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage2_scout_min), GetConVarInt(hm_damage2_scout_max), i);
				Autodifficulty_sg552_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage2_sg552_min), GetConVarInt(hm_damage2_sg552_max), i);
				Autodifficulty_spas_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage2_spas_min), GetConVarInt(hm_damage2_spas_max), i);
				Autodifficulty_sniper_military_Dmg[i] = GetLineFunction(GetConVarInt(hm_damage2_sniper_military_min), GetConVarInt(hm_damage2_sniper_military_max), i);
			}
		}
		Autodifficulty_meleefix_Dmg[i] = GetLineFunction(GetConVarInt(hm_meleefix_min), GetConVarInt(hm_meleefix_max), i);
		Autodifficulty_meleefix_headshot_Dmg[i] = GetLineFunction(GetConVarInt(hm_meleefix_headshot_min), GetConVarInt(hm_meleefix_headshot_max), i);
		Autodifficulty_meleefix_tank_Dmg[i] = GetLineFunction(GetConVarInt(hm_meleefix_tank_min), GetConVarInt(hm_meleefix_tank_max), i);
		Autodifficulty_meleefix_tank_headshot_Dmg[i] = GetLineFunction(GetConVarInt(hm_meleefix_tank_headshot_min), GetConVarInt(hm_meleefix_tank_headshot_max), i);
		Autodifficulty_meleefix_witch_Dmg[i] = GetLineFunction(GetConVarInt(hm_meleefix_witch_min), GetConVarInt(hm_meleefix_witch_max), i);
		i++;
	}
	autodifficulty_calculated = true;
	return 0;
}

GetLineFunction(GLF_Min, GLF_Max, i)
{
	new result = GetLineFunctionEx(GLF_Min, GLF_Max, i, cvar_maxplayers);
	if (0 > result)
	{
		return GLF_Min;
	}
	return result;
}

GetLineFunctionEx(GLF_Min, GLF_Max, i, GLF_maxplayers)
{
	new Float:k = 1065353216 * GLF_Max - GLF_Min / GLF_maxplayers + -4 * 1.0;
	new Float:b = 1065353216 * GLF_Max - k * GLF_maxplayers;
	return RoundToNearest(k * i + b);
}

GetTankHP()
{
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsValidEntity(i) && IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			if (GetEntProp(i, PropType:0, "m_zombieClass", 4, 0) == 8)
			{
				if (GetEntProp(i, PropType:0, "m_isIncapacitated", 4, 0))
				{
					return 0;
				}
				return GetClientHealth(i);
			}
		}
		i++;
	}
	return GetConVarInt(FindConVar("z_tank_health")) * 2;
}

public Action:Command_info2(client, args)
{
	if (client)
	{
		new String:sFormattedTime[24];
		FormatTime(sFormattedTime, 22, "%m/%d/%Y - %H:%M:%S", GetTime({0,0}));
		decl String:Mapname[128];
		GetCurrentMap(Mapname, 128);
		UpdateServerUpTime();
		PrintToChat(client, "%t", "L4D2°•Rus Coop-25°•(Hardmod v0.4.34) | UpTime: %s", Server_UpTime);
		if (RDifficultyMultiplier >= 1000.0)
		{
			decl String:MapDifficultyMultiplier[8];
			FloatToString(RDifficultyMultiplier, MapDifficultyMultiplier, 8);
			PrintToChat(client, "%t", "Difficulty: %s x %s | Players: %i", sGameDifficulty, MapDifficultyMultiplier, GetRealClientCount(true));
		}
		else
		{
			if (RDifficultyMultiplier >= 100.0)
			{
				decl String:MapDifficultyMultiplier[8];
				FloatToString(RDifficultyMultiplier, MapDifficultyMultiplier, 7);
				PrintToChat(client, "%t", "Difficulty: %s x %s | Players: %i", sGameDifficulty, MapDifficultyMultiplier, GetRealClientCount(true));
			}
			if (RDifficultyMultiplier >= 10.0)
			{
				decl String:MapDifficultyMultiplier[8];
				FloatToString(RDifficultyMultiplier, MapDifficultyMultiplier, 6);
				PrintToChat(client, "%t", "Difficulty: %s x %s | Players: %i", sGameDifficulty, MapDifficultyMultiplier, GetRealClientCount(true));
			}
			decl String:MapDifficultyMultiplier[8];
			FloatToString(RDifficultyMultiplier, MapDifficultyMultiplier, 5);
			CPrintToChat(client, "%t", "Difficulty: %s x %s | Players: %i | Live Survivors: %i", sGameDifficulty, MapDifficultyMultiplier, GetRealClientCount(true), GetLiveSurvivorsCount(true));
		}
		if (IsTankAlive())
		{
			new String:Message[256];
			new String:TempMessage[64];
			new bool:more_than_one;
			Format(TempMessage, 64, "%t", "Tank HP: ");
			StrCat(Message, 256, TempMessage);
			new i = 1;
			while (GetMaxClients() >= i)
			{
				if (IsClientInGame(i))
				{
					new var1;
					if (GetClientTeam(i) == 3 && !IsIncapacitated(i) && IsPlayerAlive(i) && GetClientZC(i) == 8 && GetClientHealth(i) > 0)
					{
						if (more_than_one)
						{
							Format(TempMessage, 64, "\x04& \x03%d ", GetClientHealth(i));
							StrCat(Message, 256, TempMessage);
						}
						else
						{
							Format(TempMessage, 64, "\x03%d ", GetClientHealth(i));
							StrCat(Message, 256, TempMessage);
						}
						more_than_one = true;
					}
				}
				i++;
			}
			Format(TempMessage, 64, "%t", "| Witch HP: %i | Zombie HP: %i", GetConVarInt(FindConVar("z_witch_health")), GetConVarInt(FindConVar("z_health")));
			StrCat(Message, 256, TempMessage);
			PrintToChat(client, Message);
		}
		else
		{
			PrintToChat(client, "%t", "Tank HP: %i | Witch HP: %i | Zombie HP: %i", GetTankHP(), GetConVarInt(FindConVar("z_witch_health")), GetConVarInt(FindConVar("z_health")));
		}
		PrintToChat(client, "%t", "Hunter HP: %i | Smoker HP: %i | Boomer HP: %i \nCharger HP: %i | Spitter HP: %i | Jockey HP: %i", GetConVarInt(FindConVar("z_hunter_health")), GetConVarInt(FindConVar("z_gas_health")), GetConVarInt(FindConVar("z_exploding_health")), GetConVarInt(FindConVar("z_charger_health")), GetConVarInt(FindConVar("z_spitter_health")), GetConVarInt(FindConVar("z_jockey_health")));
		PrintToChat(client, "%t", "Grenade Launcher Damage: %d. Server time: %s", GetConVarInt(FindConVar("grenadelauncher_damage")), sFormattedTime);
		PrintToChat(client, "%t", "CurrentMap: %s", Mapname);
		return Action:0;
	}
	return Action:3;
}

public Autodifficulty()
{
	if (GetConVarInt(hm_autodifficulty) < 1)
	{
		return 0;
	}
	if (!autodifficulty_calculated)
	{
		AutoDifficultyInit();
		return 0;
	}
	if (playerscount < 4)
	{
		playerscount = 4;
	}
	if (playerscount > cvar_maxplayers)
	{
		playerscount = cvar_maxplayers;
	}
	if (l4d2_plugin_monsterbots)
	{
		SetConVarInt(FindConVar("monsterbots_maxbots"), RoundToNearest(GetConVarFloat(hm_spawn_count_mod) * AutodifficultySpawnCount[playerscount]), false, false);
		SetConVarInt(FindConVar("monsterbots_interval"), RoundToNearest(GetConVarFloat(hm_spawn_time_mod) * AutodifficultySpawnInterval[playerscount]), false, false);
	}
	else
	{
		SetConVarInt(z_special_spawn_interval, RoundToNearest(GetConVarFloat(hm_spawn_time_mod) * AutodifficultySpawnInterval[playerscount]), false, false);
		SetConVarInt(director_special_respawn_interval, RoundToNearest(GetConVarFloat(hm_spawn_time_mod) * AutodifficultySpawnInterval[playerscount]), false, false);
		SetConVarInt(z_max_player_zombies, RoundToNearest(GetConVarFloat(hm_spawn_count_mod) * AutodifficultySpawnCount[playerscount]), false, false);
	}
	RDifficultyMultiplier = Calculate_Rank_Mod();
	if (0 < GetConVarInt(hm_speed_automod))
	{
		SetConVarInt(FindConVar("z_hunter_speed"), AutodifficultySpeed[playerscount][3], false, false);
		SetConVarInt(FindConVar("z_gas_speed"), AutodifficultySpeed[playerscount][1], false, false);
		SetConVarInt(FindConVar("z_exploding_speed"), AutodifficultySpeed[playerscount][2], false, false);
		SetConVarInt(FindConVar("z_spitter_speed"), AutodifficultySpeed[playerscount][4], false, false);
		SetConVarInt(FindConVar("z_jockey_speed"), AutodifficultySpeed[playerscount][5], false, false);
		SetConVarInt(FindConVar("z_charge_start_speed"), AutodifficultySpeed[playerscount][6], false, false);
		SetConVarInt(FindConVar("z_tank_speed"), AutodifficultySpeed[playerscount][8], false, false);
	}
	new Handle:tank_burn_duration;
	switch (cvar_difficulty)
	{
		case 1:
		{
			tank_burn_duration = FindConVar("tank_burn_duration");
		}
		case 3:
		{
			tank_burn_duration = FindConVar("tank_burn_duration_hard");
		}
		case 4:
		{
			tank_burn_duration = FindConVar("tank_burn_duration_expert");
		}
		default:
		{
		}
	}
	SetConVarInt(tank_burn_duration, AutodifficultyTankBurnTime[playerscount], false, false);
	SetConVarInt(FindConVar("grenadelauncher_damage"), AutodifficultyGrenadeLRDmg[playerscount], false, false);
	if (0 < GetConVarInt(hm_spawn_automod))
	{
		SetConVarInt(FindConVar("z_common_limit"), AutodifficultySpawnLimit[playerscount][0], false, false);
		SetConVarInt(FindConVar("z_hunter_limit"), AutodifficultySpawnLimit[playerscount][3], false, false);
		SetConVarInt(FindConVar("z_smoker_limit"), AutodifficultySpawnLimit[playerscount][1], false, false);
		SetConVarInt(FindConVar("z_boomer_limit"), AutodifficultySpawnLimit[playerscount][2], false, false);
		SetConVarInt(FindConVar("z_spitter_limit"), AutodifficultySpawnLimit[playerscount][4], false, false);
		SetConVarInt(FindConVar("z_jockey_limit"), AutodifficultySpawnLimit[playerscount][5], false, false);
		SetConVarInt(FindConVar("z_charger_limit"), AutodifficultySpawnLimit[playerscount][6], false, false);
	}
	new Float:HealthMod = GetConVarFloat(hm_infected_hp_mod);
	if (0 < GetConVarInt(hm_autohp_automod))
	{
		HealthMod *= RDifficultyMultiplier;
	}
	SetConVarInt(FindConVar("z_charger_health"), RoundToNearest(HealthMod * AutodifficultyHP[playerscount][6]), false, false);
	SetConVarInt(FindConVar("z_hunter_health"), RoundToNearest(HealthMod * AutodifficultyHP[playerscount][3]), false, false);
	SetConVarInt(FindConVar("z_gas_health"), RoundToNearest(HealthMod * AutodifficultyHP[playerscount][1]), false, false);
	SetConVarInt(FindConVar("z_exploding_health"), RoundToNearest(HealthMod * AutodifficultyHP[playerscount][2]), false, false);
	SetConVarInt(FindConVar("z_spitter_health"), RoundToNearest(HealthMod * AutodifficultyHP[playerscount][4]), false, false);
	SetConVarInt(FindConVar("z_jockey_health"), RoundToNearest(HealthMod * AutodifficultyHP[playerscount][5]), false, false);
	SetConVarInt(FindConVar("z_witch_health"), RoundToNearest(HealthMod * AutodifficultyHP[playerscount][7]), false, false);
	SetConVarInt(FindConVar("z_tank_health"), RoundToNearest(HealthMod * AutodifficultyHP[playerscount][8] * GetConVarFloat(hm_tank_hp_mod)), false, false);
	SetConVarInt(FindConVar("z_health"), RoundToNearest(1065353216 * AutodifficultyHP[playerscount][0]), false, false);
	SetConVarInt(FindConVar("l4d2_ammo_witches"), RoundToNearest(1040187392 * playerscount + 0.5 * 4 * RDifficultyMultiplier), false, false);
	new var1;
	if (l4d2_plugin_loot && GetConVarInt(hm_items_automod) > 0)
	{
		new Float:LootMod = GetConVarFloat(hm_loot_mod);
		SetConVarInt(FindConVar("l4d2_loot_h_drop_items"), RoundToNearest(LootMod * AutodifficultyItems[playerscount][3]), false, false);
		SetConVarInt(FindConVar("l4d2_loot_b_drop_items"), RoundToNearest(LootMod * AutodifficultyItems[playerscount][2]), false, false);
		SetConVarInt(FindConVar("l4d2_loot_s_drop_items"), RoundToNearest(LootMod * AutodifficultyItems[playerscount][1]), false, false);
		SetConVarInt(FindConVar("l4d2_loot_sp_drop_items"), RoundToNearest(LootMod * AutodifficultyItems[playerscount][4]), false, false);
		SetConVarInt(FindConVar("l4d2_loot_j_drop_items"), RoundToNearest(LootMod * AutodifficultyItems[playerscount][5]), false, false);
		SetConVarInt(FindConVar("l4d2_loot_t_drop_items"), RoundToNearest(LootMod * AutodifficultyItems[playerscount][8]), false, false);
		if (extra_charger)
		{
			SetConVarInt(FindConVar("l4d2_loot_c_drop_items"), RoundToNearest(AutodifficultyItems[playerscount][6][LootMod * GetConVarInt(hm_items_supercharger_auto)]), false, false);
		}
		else
		{
			SetConVarInt(FindConVar("l4d2_loot_c_drop_items"), RoundToNearest(LootMod * AutodifficultyItems[playerscount][6]), false, false);
		}
	}
	SetConVarInt(FindConVar("tongue_miss_delay"), AutodifficultyTongueMissDelay[playerscount], false, false);
	SetConVarInt(FindConVar("tongue_hit_delay"), AutodifficultyTongueHitDelay[playerscount], false, false);
	SetConVarInt(FindConVar("tongue_range"), AutodifficultyTongueRange[playerscount], false, false);
	SetConVarInt(FindConVar("smoker_pz_claw_dmg"), AutodifficultySmokerClawDmg[playerscount], false, false);
	SetConVarInt(FindConVar("jockey_pz_claw_dmg"), AutodifficultyJockeyClawDmg[playerscount], false, false);
	SetConVarInt(FindConVar("tongue_choke_damage_amount"), AutodifficultyTongueChokeDmg[playerscount], false, false);
	SetConVarInt(FindConVar("tongue_drag_damage_amount"), AutodifficultyTongueDragDmg[playerscount], false, false);
	new Float:WeaponMod = GetConVarFloat(hm_infected_hp_mod);
	if (0 < GetConVarInt(hm_autohp_automod))
	{
		WeaponMod *= RDifficultyMultiplier;
	}
	if (GetConVarInt(damage_type) == 1)
	{
		SetConVarInt(FindConVar("hm_damage_ak47"), RoundToNearest(WeaponMod * Autodifficulty_ak47_Dmg[playerscount]), false, false);
		SetConVarInt(FindConVar("hm_damage_awp"), RoundToNearest(WeaponMod * Autodifficulty_awp_Dmg[playerscount]), false, false);
		SetConVarInt(FindConVar("hm_damage_m60"), RoundToNearest(WeaponMod * Autodifficulty_m60_Dmg[playerscount]), false, false);
		SetConVarInt(FindConVar("hm_damage_scout"), RoundToNearest(WeaponMod * Autodifficulty_scout_Dmg[playerscount]), false, false);
		SetConVarInt(FindConVar("hm_damage_sg552"), RoundToNearest(WeaponMod * Autodifficulty_sg552_Dmg[playerscount]), false, false);
		SetConVarInt(FindConVar("hm_damage_spas"), RoundToNearest(WeaponMod * Autodifficulty_spas_Dmg[playerscount]), false, false);
		SetConVarInt(FindConVar("hm_damage_sniper_military"), RoundToNearest(WeaponMod * Autodifficulty_sniper_military_Dmg[playerscount]), false, false);
	}
	else
	{
		if (GetConVarInt(damage_type) == 2)
		{
			SetConVarInt(FindConVar("hm_damage2_ak47"), RoundToNearest(WeaponMod * Autodifficulty_ak47_Dmg[playerscount]), false, false);
			SetConVarInt(FindConVar("hm_damage2_awp"), RoundToNearest(WeaponMod * Autodifficulty_awp_Dmg[playerscount]), false, false);
			SetConVarInt(FindConVar("hm_damage2_m60"), RoundToNearest(WeaponMod * Autodifficulty_m60_Dmg[playerscount]), false, false);
			SetConVarInt(FindConVar("hm_damage2_scout"), RoundToNearest(WeaponMod * Autodifficulty_scout_Dmg[playerscount]), false, false);
			SetConVarInt(FindConVar("hm_damage2_sg552"), RoundToNearest(WeaponMod * Autodifficulty_sg552_Dmg[playerscount]), false, false);
			SetConVarInt(FindConVar("hm_damage2_spas"), RoundToNearest(WeaponMod * Autodifficulty_spas_Dmg[playerscount]), false, false);
			SetConVarInt(FindConVar("hm_damage2_sniper_military"), RoundToNearest(WeaponMod * Autodifficulty_sniper_military_Dmg[playerscount]), false, false);
		}
	}
	SetConVarInt(FindConVar("hm_meleefix_smoker"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_smoker_headshot"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_headshot_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_boomer"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_boomer_headshot"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_headshot_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_hunter"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_hunter_headshot"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_headshot_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_jockey"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_jockey_headshot"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_headshot_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_spitter"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_spitter_headshot"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_headshot_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_charger"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_charger_headshot"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_headshot_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_tank"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_tank_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_tank_headshot"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_tank_headshot_Dmg[playerscount]), false, false);
	SetConVarInt(FindConVar("hm_meleefix_witch"), RoundToNearest(WeaponMod * Autodifficulty_meleefix_witch_Dmg[playerscount]), false, false);
	if (playerscount > 4)
	{
		SetConVarInt(FindConVar("z_spitter_max_wait_time"), 34 - playerscount, false, false);
		SetConVarInt(FindConVar("z_vomit_interval"), 34 - playerscount, false, false);
	}
	else
	{
		SetConVarInt(FindConVar("z_spitter_max_wait_time"), 30, false, false);
		SetConVarInt(FindConVar("z_vomit_interval"), 30, false, false);
	}
	return 0;
}

public cvar_maxplayers_changed(Handle:hVariable, String:strOldValue[], String:strNewValue[])
{
	cvar_maxplayers = GetConVarInt(FindConVar("sv_maxplayers")) + -5;
	return 0;
}

public Action:Command_RankMod(client, args)
{
	new Float:RankMod = Calculate_Rank_Mod();
	if (client)
	{
		PrintToChat(client, "\x05loc_result: \x04%f", RankMod);
	}
	else
	{
		PrintToServer("local_result: %f", RankMod);
	}
	return Action:0;
}

ADPlayerSpawn(Handle:event)
{
	if (GetConVarInt(hm_autodifficulty_forcehp) < 1)
	{
		return 0;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	new var1;
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		switch (GetClientZC(client))
		{
			case 1:
			{
				SetEntityHealth(client, GetConVarInt(FindConVar("z_gas_health")));
			}
			case 2:
			{
				SetEntityHealth(client, GetConVarInt(FindConVar("z_exploding_health")));
			}
			case 3:
			{
				SetEntityHealth(client, GetConVarInt(FindConVar("z_hunter_health")));
			}
			case 4:
			{
				SetEntityHealth(client, GetConVarInt(FindConVar("z_spitter_health")));
			}
			case 5:
			{
				SetEntityHealth(client, GetConVarInt(FindConVar("z_jockey_health")));
			}
			case 6:
			{
				SetEntityHealth(client, GetConVarInt(FindConVar("z_charger_health")));
			}
			case 8:
			{
				SetEntityHealth(client, GetConVarInt(FindConVar("z_tank_health")) * 2);
			}
			default:
			{
			}
		}
	}
	return 0;
}

public Action:Command_melee(client, args)
{
	if (IsClientInGame(client))
	{
		PrintToChat(client, "\x05melee damage for bosses: \x04%d \x05| melee damage for bosses (HEADSHOT): \x04%d", GetConVarInt(FindConVar("hm_meleefix_boomer")), GetConVarInt(FindConVar("hm_meleefix_boomer_headshot")));
		PrintToChat(client, "\x05melee damage for tank: \x04%d \x05| tank headshot: \x04%d \x05| witch: \x04%d", GetConVarInt(FindConVar("hm_meleefix_tank")), GetConVarInt(FindConVar("hm_meleefix_tank_headshot")), GetConVarInt(FindConVar("hm_meleefix_witch")));
	}
	return Action:0;
}

public Action:Command_ammo(client, args)
{
	if (IsClientInGame(client))
	{
		PrintToChat(client, "\x05witches: \x04%d \x05| ammochance medbox: \x04%d \x05| ammochance healbox: \x04%d", GetConVarInt(FindConVar("l4d2_ammo_witches")), GetConVarInt(FindConVar("l4d2_ammochance_medbox")), GetConVarInt(FindConVar("l4d2_ammochance_healbox")));
	}
	return Action:0;
}

public Action:Command_damage(client, args)
{
	if (IsClientInGame(client))
	{
		if (GetConVarInt(damage_type) == 1)
		{
			PrintToChat(client, "\x05awp damage: \x04%d \x05| ak47 damage: \x04%d", GetConVarInt(FindConVar("hm_damage_awp")) / 1000 * 143, GetConVarInt(FindConVar("hm_damage_ak47")) / 1000 * 72);
			PrintToChat(client, "\x05scout damage: \x04%d \x05| m60 damage: \x04%d", GetConVarInt(FindConVar("hm_damage_scout")) / 1000 * 112, GetConVarInt(FindConVar("hm_damage_m60")) / 1000 * 62);
			PrintToChat(client, "\x05spas damage: \x04%d \x05| sg552 damage: \x04%d", GetConVarInt(FindConVar("hm_damage_spas")) / 1000 * 22, GetConVarInt(FindConVar("hm_damage_sg552")) / 1000 * 36);
		}
		if (GetConVarInt(damage_type) == 2)
		{
			PrintToChat(client, "\x05awp damage: \x04%d \x05| ak47 damage: \x04%d", GetConVarInt(FindConVar("hm_damage2_awp")), GetConVarInt(FindConVar("hm_damage2_ak47")));
			PrintToChat(client, "\x05scout damage: \x04%d \x05| m60 damage: \x04%d", GetConVarInt(FindConVar("hm_damage2_scout")), GetConVarInt(FindConVar("hm_damage2_m60")));
			PrintToChat(client, "\x05spas damage: \x04%d \x05| sg552 damage: \x04%d", GetConVarInt(FindConVar("hm_damage2_spas")), GetConVarInt(FindConVar("hm_damage2_sg552")));
		}
	}
	return Action:0;
}

public Action:Command_swd(client, args)
{
	SetConVarInt(FindConVar("hm_damage_showvalue"), 1, false, false);
	PrintToChat(client, "\x05Показ урона \x04включен");
	return Action:0;
}

public Action:Command_swdoff(client, args)
{
	SetConVarInt(FindConVar("hm_damage_showvalue"), 0, false, false);
	PrintToChat(client, "\x05Показ урона \x04выключен");
	return Action:0;
}

public Action:Command_ddfull(client, args)
{
	Command_melee(client, args);
	Command_ammo(client, args);
	Command_damage(client, args);
	return Action:0;
}

IsTankAlive()
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (IsPlayerAlive(i))
			{
				new var1;
				if (GetClientZC(i) == 8 && !IsIncapacitated(i))
				{
					return 1;
				}
			}
		}
		i++;
	}
	return 0;
}

public bool:IsIncapacitated(client)
{
	new isIncap = GetEntProp(client, PropType:0, "m_isIncapacitated", 4, 0);
	if (isIncap)
	{
		return true;
	}
	return false;
}

GetRealClientCount(bool:inGameOnly)
{
	new clients;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				clients++;
			}
		}
		i++;
	}
	return clients;
}

UpdateServerUpTime()
{
	decl String:str_uptime_temp[8];
	new Current_UpTime = GetTime({0,0}) - UpTime;
	new Days = RoundToFloor(Current_UpTime / 1202241536);
	Current_UpTime -= Days * 86400;
	if (0 < Days)
	{
		if (Days > 1)
		{
			Format(Server_UpTime, 20, "%d days ", Days);
		}
		else
		{
			Format(Server_UpTime, 20, "1 day ");
		}
	}
	new Hours = RoundToFloor(Current_UpTime / 1163984896);
	if (Hours < 10)
	{
		Format(str_uptime_temp, 8, "0%d:", Hours);
	}
	else
	{
		Format(str_uptime_temp, 8, "%d:", Hours);
	}
	StrCat(Server_UpTime, 20, str_uptime_temp);
	Current_UpTime -= Hours * 3600;
	FormatTime(str_uptime_temp, 8, "%M:%S", Current_UpTime);
	StrCat(Server_UpTime, 20, str_uptime_temp);
	return 0;
}

public Action:Command_pinfo(client, args)
{
	new var1;
	if (client > 0 && args < 1)
	{
		ShowMyPanel(client);
	}
	return Action:3;
}

ShowMyPanel(client)
{
	new Handle:panel = CreatePanel(Handle:0);
	new String:text[1024];
	new String:sFormattedTime[24];
	FormatTime(sFormattedTime, 22, "%m/%d/%Y - %H:%M:%S", GetTime({0,0}));
	decl String:Mapname[128];
	GetCurrentMap(Mapname, 128);
	UpdateServerUpTime();
	Format(text, 1024, "%t", "L4D2°•Rus Coop-25°•(Hardmod v0.4.34) | UpTime: %s (panel)", Server_UpTime);
	SetPanelTitle(panel, text, false);
	if (RDifficultyMultiplier >= 1000.0)
	{
		decl String:MapDifficultyMultiplier[8];
		FloatToString(RDifficultyMultiplier, MapDifficultyMultiplier, 8);
		Format(text, 1024, "%t", "Difficulty: %s x %s | Players: %i (panel)", sGameDifficulty, MapDifficultyMultiplier, GetRealClientCount(true));
		DrawPanelText(panel, text);
	}
	else
	{
		if (RDifficultyMultiplier >= 100.0)
		{
			decl String:MapDifficultyMultiplier[8];
			FloatToString(RDifficultyMultiplier, MapDifficultyMultiplier, 7);
			Format(text, 1024, "%t", "Difficulty: %s x %s | Players: %i (panel)", sGameDifficulty, MapDifficultyMultiplier, GetRealClientCount(true));
			DrawPanelText(panel, text);
		}
		if (RDifficultyMultiplier >= 10.0)
		{
			decl String:MapDifficultyMultiplier[8];
			FloatToString(RDifficultyMultiplier, MapDifficultyMultiplier, 6);
			Format(text, 1024, "%t", "Difficulty: %s x %s | Players: %i (panel)", sGameDifficulty, MapDifficultyMultiplier, GetRealClientCount(true));
			DrawPanelText(panel, text);
		}
		decl String:MapDifficultyMultiplier[8];
		FloatToString(RDifficultyMultiplier, MapDifficultyMultiplier, 5);
		Format(text, 1024, "%t", "Difficulty: %s x %s | Players: %i | Live Survivors: %i (panel)", sGameDifficulty, MapDifficultyMultiplier, GetRealClientCount(true), GetLiveSurvivorsCount(true));
		DrawPanelText(panel, text);
	}
	if (IsTankAlive())
	{
		new String:Message[256];
		new String:TempMessage[64];
		Format(TempMessage, 64, "%t", "Tank HP: (panel)");
		StrCat(Message, 256, TempMessage);
		new i = 1;
		while (GetMaxClients() >= i)
		{
			if (IsClientInGame(i))
			{
				new var1;
				if (GetClientTeam(i) == 3 && !IsIncapacitated(i) && IsPlayerAlive(i) && GetClientZC(i) == 8 && GetClientHealth(i) > 0)
				{
					Format(TempMessage, 64, "%d ", GetClientHealth(i));
					StrCat(Message, 256, TempMessage);
				}
			}
			i++;
		}
		Format(TempMessage, 64, "%t", "| Witch HP: %i | Zombie HP: %i (panel)", GetConVarInt(FindConVar("z_witch_health")), GetConVarInt(FindConVar("z_health")));
		StrCat(Message, 256, TempMessage);
		DrawPanelText(panel, Message);
	}
	else
	{
		Format(text, 1024, "%t", "Tank HP: %i | Witch HP: %i | Zombie HP: %i (panel)", GetTankHP(), GetConVarInt(FindConVar("z_witch_health")), GetConVarInt(FindConVar("z_health")));
		DrawPanelText(panel, text);
	}
	Format(text, 1024, "%t", "Hunter HP: %i | Smoker HP: %i | Boomer HP: %i (panel)", GetConVarInt(FindConVar("z_hunter_health")), GetConVarInt(FindConVar("z_gas_health")), GetConVarInt(FindConVar("z_exploding_health")));
	DrawPanelText(panel, text);
	Format(text, 1024, "%t", "Charger HP: %i | Spitter HP: %i | Jockey HP: %i (panel)", GetConVarInt(FindConVar("z_charger_health")), GetConVarInt(FindConVar("z_spitter_health")), GetConVarInt(FindConVar("z_jockey_health")));
	DrawPanelText(panel, text);
	Format(text, 1024, "%t", "Grenade Launcher Damage: %d. Server time: %s (panel)", GetConVarInt(FindConVar("grenadelauncher_damage")), sFormattedTime);
	DrawPanelText(panel, text);
	Format(text, 1024, "%t", "CurrentMap: %s (panel)", Mapname);
	DrawPanelText(panel, text);
	DrawPanelItem(panel, "Close", 0);
	SendPanelToClient(panel, client, PanelHandler, 30);
	CloseHandle(panel);
	return 0;
}

public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	return 0;
}

public Action:cmd_Say(client, args)
{
	decl String:Text[192];
	new Start;
	GetCmdArgString(Text, 192);
	new TextLen = strlen(Text);
	if (0 >= TextLen)
	{
		return Action:0;
	}
	if (Text[TextLen + -1] == '"')
	{
		Text[TextLen + -1] = MissingTAG:0;
		Start = 1;
	}
	return HandleCommands(client, Text[Start]);
}

public Action:HandleCommands(client, String:Text[])
{
	if (strcmp(Text, "!info2", false))
	{
		if (!(strcmp(Text, "/info2", false)))
		{
			Command_info2(client, 0);
			return Action:3;
		}
	}
	else
	{
		Command_info2(client, 0);
	}
	return Action:0;
}

public DamageOnPluginStart()
{
	hm_damage = CreateConVar("hm_damage", "1", "Enable/Disable damage", 262144, false, 0.0, false, 0.0);
	hm_damage_friendly = CreateConVar("hm_damage_friendly", "0.3", "Enable/Disable ff damage", 262144, false, 0.0, false, 0.0);
	hm_damage_showvalue = CreateConVar("hm_damage_showvalue", "0", "Enable/Disable show damage", 262144, false, 0.0, false, 0.0);
	hm_damage_hunter = CreateConVar("hm_damage_hunter", "1.0", "Hunter additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_smoker = CreateConVar("hm_damage_smoker", "1.2", "Smoker additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_boomer = CreateConVar("hm_damage_boomer", "1.2", "Boomer additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_spitter1 = CreateConVar("hm_damage_spitter1", "1.2", "Spitter additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_spitter2 = CreateConVar("hm_damage_spitter2", "4", "Spitter additional damage (spit)", 262144, false, 0.0, false, 0.0);
	hm_damage_jockey = CreateConVar("hm_damage_jockey", "1.2", "Jockey additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_charger = CreateConVar("hm_damage_charger", "1.2", "Charger additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_tank = CreateConVar("hm_damage_tank", "1.0", "Tank additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_tankrock = CreateConVar("hm_damage_tankrock", "1.0", "Tank additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_common = CreateConVar("hm_damage_common", "0", "Common additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_type = CreateConVar("hm_damage_type", "2", "damage type", 262144, false, 0.0, false, 0.0);
	hm_damage_ak47 = CreateConVar("hm_damage_ak47", "2523", "AK47 additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage2_ak47 = CreateConVar("hm_damage2_ak47", "140", "AK47 damage", 262144, false, 0.0, false, 0.0);
	hm_damage_awp = CreateConVar("hm_damage_awp", "9486", "AWP additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage2_awp = CreateConVar("hm_damage2_awp", "700", "AWP damage", 262144, false, 0.0, false, 0.0);
	hm_damage_scout = CreateConVar("hm_damage_scout", "4667", "Scout additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage2_scout = CreateConVar("hm_damage2_scout", "420", "Scout damage", 262144, false, 0.0, false, 0.0);
	hm_damage_m60 = CreateConVar("hm_damage_m60", "1652", "M60 additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage2_m60 = CreateConVar("hm_damage2_m60", "85", "M60 damage", 262144, false, 0.0, false, 0.0);
	hm_damage_spas = CreateConVar("hm_damage_spas", "3000", "SPAS additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage2_spas = CreateConVar("hm_damage2_spas", "60", "SPAS damage", 262144, false, 0.0, false, 0.0);
	hm_damage_sg552 = CreateConVar("hm_damage_sg552", "1111", "SG552 additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage2_sg552 = CreateConVar("hm_damage2_sg552", "70", "SG552 damage", 262144, false, 0.0, false, 0.0);
	hm_damage_smg = CreateConVar("hm_damage_smg", "0.6", "SMG additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_smg_silenced = CreateConVar("hm_damage_smg_silenced", "0.6", "SMG_SILENCED additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_m16 = CreateConVar("hm_damage_m16", "0.6", "M16 additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_pumpshotgun = CreateConVar("hm_damage_pumpshotgun", "0.6", "PUMPSHOTGUN additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_autoshotgun = CreateConVar("hm_damage_autoshotgun", "0.6", "AUTOSHOTGUN additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_hunting_rifle = CreateConVar("hm_damage_hunting_rifle", "0.6", "HUNTING_RIFLE additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_rifle_desert = CreateConVar("hm_damage_rifle_desert", "0.6", "RIFLE_DESERT additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_shotgun_chrome = CreateConVar("hm_damage_shotgun_chrome", "0.6", "SHOTGUN_CHROME additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_smg_mp5 = CreateConVar("hm_damage_smg_mp5", "0.6", "MP5 additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_sniper_military = CreateConVar("hm_damage_sniper_military", "1055", "sniper military additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage2_sniper_military = CreateConVar("hm_damage2_sniper_military", "50", "sniper military damage", 262144, false, 0.0, false, 0.0);
	hm_damage_pistol = CreateConVar("hm_damage_pistol", "0.6", "pistol additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_pistol_magnum = CreateConVar("hm_damage_pistol_magnum", "1.0", "pistol magnum additional damage", 262144, false, 0.0, false, 0.0);
	hm_damage_pipebomb = CreateConVar("hm_damage_pipebomb", "90", "Pipe bomb additional damage", 262144, false, 0.0, false, 0.0);
	MeleeDmg[1] = CreateConVar("hm_meleefix_smoker", "1000.0", "Melee damage Smoker", 262144, false, 0.0, false, 0.0);
	MeleeDmg[2] = CreateConVar("hm_meleefix_boomer", "1000.0", "Melee damage Boomer", 262144, false, 0.0, false, 0.0);
	MeleeDmg[3] = CreateConVar("hm_meleefix_hunter", "1000.0", "Melee damage Hunter", 262144, false, 0.0, false, 0.0);
	MeleeDmg[5] = CreateConVar("hm_meleefix_jockey", "1000.0", "Melee damage Jockey", 262144, false, 0.0, false, 0.0);
	MeleeDmg[4] = CreateConVar("hm_meleefix_spitter", "1000.0", "Melee damage Spitter", 262144, false, 0.0, false, 0.0);
	MeleeDmg[6] = CreateConVar("hm_meleefix_charger", "1000.0", "Melee damage Charger", 262144, false, 0.0, false, 0.0);
	MeleeDmg[0] = CreateConVar("hm_meleefix_witch", "400.0", "Melee damage Witch", 262144, false, 0.0, false, 0.0);
	MeleeDmg[8] = CreateConVar("hm_meleefix_tank", "1000.0", "Melee damage Tank", 262144, false, 0.0, false, 0.0);
	MeleeHeadshotDmg[1] = CreateConVar("hm_meleefix_smoker_headshot", "2000.0", "Headshot Melee damage Smoker", 262144, false, 0.0, false, 0.0);
	MeleeHeadshotDmg[2] = CreateConVar("hm_meleefix_boomer_headshot", "2000.0", "Headshot Melee damage Boomer", 262144, false, 0.0, false, 0.0);
	MeleeHeadshotDmg[3] = CreateConVar("hm_meleefix_hunter_headshot", "2000.0", "Headshot Melee damage Hunter", 262144, false, 0.0, false, 0.0);
	MeleeHeadshotDmg[5] = CreateConVar("hm_meleefix_jockey_headshot", "2000.0", "Headshot Melee damage Jockey", 262144, false, 0.0, false, 0.0);
	MeleeHeadshotDmg[4] = CreateConVar("hm_meleefix_spitter_headshot", "2000.0", "Headshot Melee damage Spitter", 262144, false, 0.0, false, 0.0);
	MeleeHeadshotDmg[6] = CreateConVar("hm_meleefix_charger_headshot", "2000.0", "Headshot Melee damage Charger", 262144, false, 0.0, false, 0.0);
	MeleeHeadshotDmg[8] = CreateConVar("hm_meleefix_tank_headshot", "1000.0", "Headshot Melee damage Tank", 262144, false, 0.0, false, 0.0);
	HookConVarChange(MeleeDmg[1], ConVarChanged);
	HookConVarChange(MeleeDmg[2], ConVarChanged);
	HookConVarChange(MeleeDmg[3], ConVarChanged);
	HookConVarChange(MeleeDmg[5], ConVarChanged);
	HookConVarChange(MeleeDmg[4], ConVarChanged);
	HookConVarChange(MeleeDmg[6], ConVarChanged);
	HookConVarChange(MeleeDmg[0], ConVarChanged);
	HookConVarChange(MeleeDmg[8], ConVarChanged);
	HookConVarChange(MeleeHeadshotDmg[1], ConVarChanged);
	HookConVarChange(MeleeHeadshotDmg[2], ConVarChanged);
	HookConVarChange(MeleeHeadshotDmg[3], ConVarChanged);
	HookConVarChange(MeleeHeadshotDmg[5], ConVarChanged);
	HookConVarChange(MeleeHeadshotDmg[4], ConVarChanged);
	HookConVarChange(MeleeHeadshotDmg[6], ConVarChanged);
	HookConVarChange(MeleeHeadshotDmg[8], ConVarChanged);
	HookEvent("player_hurt", Event_DPlayerHurt, EventHookMode:0);
	HookEvent("witch_spawn", OnWitchSpawn_Event, EventHookMode:1);
	HookEvent("witch_killed", OnWitchKilled_Event, EventHookMode:1);
	ConVarsInit();
	new x = 1;
	while (x <= MaxClients)
	{
		if (ValidClient(x))
		{
			SDKHook(x, SDKHookType:2, OnTakeDamage);
		}
		x++;
	}
	return 0;
}

public void:OnPluginEnd()
{
	new x = 1;
	while (x <= MaxClients)
	{
		if (ValidClient(x))
		{
			SDKUnhook(x, SDKHookType:2, OnTakeDamage);
		}
		x++;
	}
	return void:0;
}

ValidClient(ok)
{
	new var1;
	if (0 < ok <= MaxClients && IsClientConnected(ok) && IsClientInGame(ok))
	{
		return 1;
	}
	return 0;
}

public ConVarChanged(Handle:hVariable, String:strOldValue[], String:strNewValue[])
{
	ConVarsInit();
	return 0;
}

public ConVarsInit()
{
	DamageBody[1] = GetConVarFloat(MeleeDmg[1]);
	DamageBody[2] = GetConVarFloat(MeleeDmg[2]);
	DamageBody[3] = GetConVarFloat(MeleeDmg[3]);
	DamageBody[5] = GetConVarFloat(MeleeDmg[5]);
	DamageBody[4] = GetConVarFloat(MeleeDmg[4]);
	DamageBody[6] = GetConVarFloat(MeleeDmg[6]);
	DamageBody[0] = GetConVarFloat(MeleeDmg[0]);
	DamageBody[8] = GetConVarFloat(MeleeDmg[8]);
	DamageHeadshot[1] = GetConVarFloat(MeleeHeadshotDmg[1]);
	DamageHeadshot[2] = GetConVarFloat(MeleeHeadshotDmg[2]);
	DamageHeadshot[3] = GetConVarFloat(MeleeHeadshotDmg[3]);
	DamageHeadshot[5] = GetConVarFloat(MeleeHeadshotDmg[5]);
	DamageHeadshot[4] = GetConVarFloat(MeleeHeadshotDmg[4]);
	DamageHeadshot[6] = GetConVarFloat(MeleeHeadshotDmg[6]);
	DamageHeadshot[8] = GetConVarFloat(MeleeHeadshotDmg[8]);
	return 0;
}

public void:OnAllPluginsLoaded()
{
	new i = 1;
	while (i <= MaxClients)
	{
		SDKHook(i, SDKHookType:11, OnTraceAttack);
		i++;
	}
	return void:0;
}

public void:OnClientPutInServer(client)
{
	SDKHook(client, SDKHookType:11, OnTraceAttack);
	SDKHook(client, SDKHookType:2, OnTakeDamage);
	return void:0;
}

DMOnClientDisconnect(client)
{
	SDKUnhook(client, SDKHookType:11, OnTraceAttack);
	SDKUnhook(client, SDKHookType:2, OnTakeDamage);
	return 0;
}

public OnWitchSpawn_Event(Handle:event, String:name[], bool:dontBroadcast)
{
	if (0.0 == DamageBody[0])
	{
		return 0;
	}
	new witch = GetEventInt(event, "witchid", 0);
	new var1;
	if (witch < 1 || !IsValidEntity(witch))
	{
		return 0;
	}
	SDKHook(witch, SDKHookType:2, OnWitchTakeDamage);
	return 0;
}

public OnWitchKilled_Event(Handle:event, String:name[], bool:dontBroadcast)
{
	if (0.0 == DamageBody[0])
	{
		return 0;
	}
	new witch = GetEventInt(event, "witchid", 0);
	new var1;
	if (witch < 1 || !IsValidEntity(witch))
	{
		return 0;
	}
	SDKUnhook(witch, SDKHookType:2, OnWitchTakeDamage);
	return 0;
}

public Action:OnWitchTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new var1;
	if (!damage > 0.0 || attacker < 1 || attacker > MaxClients || !IsClientInGame(attacker) || GetClientTeam(attacker) == 2)
	{
		return Action:0;
	}
	decl String:clsname[64];
	GetEdictClassname(inflictor, clsname, 64);
	if (!StrEqual(clsname, "weapon_melee", true))
	{
		return Action:0;
	}
	damage = DamageBody[0];
	return Action:1;
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	new var1;
	if (0.0 == damage || victim < 1 || victim > MaxClients || !IsClientInGame(victim) || GetClientTeam(victim) == 3 || attacker < 1 || attacker > MaxClients || !IsClientInGame(attacker) || GetClientTeam(attacker) == 2)
	{
		return Action:0;
	}
	decl String:clsname[64];
	GetEdictClassname(inflictor, clsname, 64);
	if (!StrEqual(clsname, "weapon_melee", true))
	{
		return Action:0;
	}
	new zClass = GetEntProp(victim, PropType:0, "m_zombieClass", 4, 0);
	new var2;
	if ((zClass > 0 && zClass < 7) || zClass == 8)
	{
		if (0.0 == DamageBody[zClass])
		{
			return Action:0;
		}
		if (hitgroup == 1)
		{
			if (0.0 == DamageHeadshot[zClass])
			{
				return Action:0;
			}
			damage = DamageHeadshot[zClass];
			return Action:1;
		}
		damage = DamageBody[zClass];
		return Action:1;
	}
	return Action:0;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new var1;
	if (GetConVarInt(hm_damage) == 1 && !victim)
	{
		return Action:0;
	}
	new var2;
	if (inflictor > MaxClients || attacker > MaxClients || !attacker || 0.0 == damage)
	{
		return Action:0;
	}
	decl String:Weapon[32];
	GetClientWeapon(attacker, Weapon, 32);
	new Float:original_damage = damage;
	if (damagetype == 128)
	{
		if (StrEqual(Weapon, "weapon_boomer_claw", true))
		{
			damage = damage * GetConVarFloat(hm_damage_boomer);
		}
		else
		{
			if (StrEqual(Weapon, "weapon_charger_claw", true))
			{
				damage = damage * GetConVarFloat(hm_damage_charger);
			}
			if (StrEqual(Weapon, "weapon_hunter_claw", true))
			{
				damage = damage * GetConVarFloat(hm_damage_hunter);
			}
			if (StrEqual(Weapon, "weapon_smoker_claw", true))
			{
				damage = damage * GetConVarFloat(hm_damage_smoker);
			}
			if (StrEqual(Weapon, "weapon_spitter_claw", true))
			{
				damage = damage * GetConVarFloat(hm_damage_spitter1);
			}
			if (StrEqual(Weapon, "weapon_jockey_claw", true))
			{
				damage = damage * GetConVarFloat(hm_damage_jockey);
			}
			if (StrEqual(Weapon, "weapon_tank_claw", true))
			{
				damage = damage * GetConVarFloat(hm_damage_tank);
			}
			if (StrEqual(Weapon, "weapon_tank_rock", true))
			{
				damage = damage * GetConVarFloat(hm_damage_tankrock);
			}
		}
	}
	else
	{
		if (GetConVarInt(hm_damage_type) == 1)
		{
			if (StrEqual(Weapon, "weapon_rifle_ak47", true))
			{
				damage = damage * GetConVarFloat(hm_damage_ak47) / 1000;
			}
			else
			{
				if (StrEqual(Weapon, "weapon_sniper_awp", true))
				{
					damage = damage * GetConVarFloat(hm_damage_awp) / 1000;
				}
				if (StrEqual(Weapon, "weapon_sniper_scout", true))
				{
					damage = damage * GetConVarFloat(hm_damage_scout) / 1000;
				}
				if (StrEqual(Weapon, "weapon_rifle_m60", true))
				{
					damage = damage * GetConVarFloat(hm_damage_m60) / 1000;
				}
				if (StrEqual(Weapon, "weapon_shotgun_spas", true))
				{
					damage = damage * GetConVarFloat(hm_damage_spas) / 1000;
				}
				if (StrEqual(Weapon, "weapon_rifle_sg552", true))
				{
					damage = damage * GetConVarFloat(hm_damage_sg552) / 1000;
				}
				if (StrEqual(Weapon, "weapon_smg", true))
				{
					damage = damage * GetConVarFloat(hm_damage_smg);
				}
				if (StrEqual(Weapon, "weapon_smg_silenced", true))
				{
					damage = damage * GetConVarFloat(hm_damage_smg_silenced);
				}
				if (StrEqual(Weapon, "weapon_rifle", true))
				{
					damage = damage * GetConVarFloat(hm_damage_m16);
				}
				if (StrEqual(Weapon, "weapon_pumpshotgun", true))
				{
					damage = damage * GetConVarFloat(hm_damage_pumpshotgun);
				}
				if (StrEqual(Weapon, "weapon_autoshotgun", true))
				{
					damage = damage * GetConVarFloat(hm_damage_autoshotgun);
				}
				if (StrEqual(Weapon, "weapon_hunting_rifle", true))
				{
					damage = damage * GetConVarFloat(hm_damage_hunting_rifle);
				}
				if (StrEqual(Weapon, "weapon_rifle_desert", true))
				{
					damage = damage * GetConVarFloat(hm_damage_rifle_desert);
				}
				if (StrEqual(Weapon, "weapon_shotgun_chrome", true))
				{
					damage = damage * GetConVarFloat(hm_damage_shotgun_chrome);
				}
				if (StrEqual(Weapon, "weapon_smg_mp5", true))
				{
					damage = damage * GetConVarFloat(hm_damage_smg_mp5);
				}
				if (StrEqual(Weapon, "weapon_sniper_military", true))
				{
					damage = damage * GetConVarFloat(hm_damage_sniper_military) / 1000;
				}
				if (StrEqual(Weapon, "weapon_pistol", true))
				{
					damage = damage * GetConVarFloat(hm_damage_pistol);
				}
				if (StrEqual(Weapon, "weapon_pistol_magnum", true))
				{
					damage = damage * GetConVarFloat(hm_damage_pistol_magnum);
				}
			}
		}
		if (GetConVarInt(hm_damage_type) == 2)
		{
			if (StrEqual(Weapon, "weapon_rifle_ak47", true))
			{
				damage = GetConVarFloat(hm_damage2_ak47);
			}
			if (StrEqual(Weapon, "weapon_sniper_awp", true))
			{
				damage = GetConVarFloat(hm_damage2_awp);
			}
			if (StrEqual(Weapon, "weapon_sniper_scout", true))
			{
				damage = GetConVarFloat(hm_damage2_scout);
			}
			if (StrEqual(Weapon, "weapon_rifle_m60", true))
			{
				damage = GetConVarFloat(hm_damage2_m60);
			}
			if (StrEqual(Weapon, "weapon_shotgun_spas", true))
			{
				damage = GetConVarFloat(hm_damage2_spas);
			}
			if (StrEqual(Weapon, "weapon_rifle_sg552", true))
			{
				damage = GetConVarFloat(hm_damage2_sg552);
			}
			if (StrEqual(Weapon, "weapon_smg", true))
			{
				damage = damage * GetConVarFloat(hm_damage_smg);
			}
			if (StrEqual(Weapon, "weapon_smg_silenced", true))
			{
				damage = damage * GetConVarFloat(hm_damage_smg_silenced);
			}
			if (StrEqual(Weapon, "weapon_rifle", true))
			{
				damage = damage * GetConVarFloat(hm_damage_m16);
			}
			if (StrEqual(Weapon, "weapon_pumpshotgun", true))
			{
				damage = damage * GetConVarFloat(hm_damage_pumpshotgun);
			}
			if (StrEqual(Weapon, "weapon_autoshotgun", true))
			{
				damage = damage * GetConVarFloat(hm_damage_autoshotgun);
			}
			if (StrEqual(Weapon, "weapon_hunting_rifle", true))
			{
				damage = damage * GetConVarFloat(hm_damage_hunting_rifle);
			}
			if (StrEqual(Weapon, "weapon_rifle_desert", true))
			{
				damage = damage * GetConVarFloat(hm_damage_rifle_desert);
			}
			if (StrEqual(Weapon, "weapon_shotgun_chrome", true))
			{
				damage = damage * GetConVarFloat(hm_damage_shotgun_chrome);
			}
			if (StrEqual(Weapon, "weapon_smg_mp5", true))
			{
				damage = damage * GetConVarFloat(hm_damage_smg_mp5);
			}
			if (StrEqual(Weapon, "weapon_sniper_military", true))
			{
				damage = GetConVarFloat(hm_damage2_sniper_military);
			}
			if (StrEqual(Weapon, "weapon_pistol", true))
			{
				damage = damage * GetConVarFloat(hm_damage_pistol);
			}
			if (StrEqual(Weapon, "weapon_pistol_magnum", true))
			{
				damage = damage * GetConVarFloat(hm_damage_pistol_magnum);
			}
		}
	}
	if (original_damage != damage)
	{
		new var3;
		if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 2)
		{
			if (!IsPlayerIncapped(victim))
			{
				damage = damage * GetConVarFloat(hm_damage_friendly);
				if (damage >= 1065353216 * GetHealth(victim))
				{
					damage = 1065353216 * GetHealth(victim) - 1;
				}
			}
			damage = damage * GetConVarFloat(hm_damage_friendly) * 0.5;
		}
		return Action:1;
	}
	return Action:0;
}

public IncapTarget(target)
{
	if (IsValidEntity(target))
	{
		new iDmgEntity = CreateEntityByName("point_hurt", -1);
		SetEntityHealth(target, 1);
		DispatchKeyValue(target, "targetname", "bm_target");
		DispatchKeyValue(iDmgEntity, "DamageTarget", "bm_target");
		DispatchKeyValue(iDmgEntity, "Damage", "100");
		DispatchKeyValue(iDmgEntity, "DamageType", "0");
		DispatchSpawn(iDmgEntity);
		AcceptEntityInput(iDmgEntity, "Hurt", target, -1, 0);
		DispatchKeyValue(target, "targetname", "bm_targetoff");
		RemoveEdict(iDmgEntity);
	}
	return 0;
}

public Action:Event_DPlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(hm_damage) < 1)
	{
		return Action:0;
	}
	new enemy = GetClientOfUserId(GetEventInt(event, "attacker", 0));
	new target = GetClientOfUserId(GetEventInt(event, "userid", 0));
	new dmg_health = GetEventInt(event, "dmg_health", 0);
	new damagetype = GetEventInt(event, "type", 0);
	new var1;
	if ((GetConVarInt(hm_damage) < 2 && damagetype == 128) || (target && !dmg_health))
	{
		return Action:0;
	}
	decl String:weapon[16];
	GetEventString(event, "weapon", weapon, 16, "");
	new hardmod_damage;
	if (StrEqual(weapon, "insect_swarm", false))
	{
		hardmod_damage = GetConVarInt(hm_damage_spitter2);
	}
	else
	{
		if (StrEqual(weapon, "pipe_bomb", false))
		{
			hardmod_damage = GetConVarInt(hm_damage_pipebomb);
		}
		if (StrEqual(weapon, "", false))
		{
			hardmod_damage = GetConVarInt(hm_damage_common);
		}
		new var3;
		if (GetConVarInt(hm_damage) > 1 && enemy)
		{
			if (damagetype == 128)
			{
				if (StrEqual(weapon, "boomer_claw", true))
				{
					hardmod_damage = GetConVarInt(hm_damage_boomer);
				}
				else
				{
					if (StrEqual(weapon, "charger_claw", true))
					{
						hardmod_damage = GetConVarInt(hm_damage_charger);
					}
					if (StrEqual(weapon, "hunter_claw", true))
					{
						hardmod_damage = GetConVarInt(hm_damage_hunter);
					}
					if (StrEqual(weapon, "smoker_claw", true))
					{
						hardmod_damage = GetConVarInt(hm_damage_smoker);
					}
					if (StrEqual(weapon, "spitter_claw", true))
					{
						hardmod_damage = GetConVarInt(hm_damage_spitter1);
					}
					if (StrEqual(weapon, "jockey_claw", true))
					{
						hardmod_damage = GetConVarInt(hm_damage_jockey);
					}
					if (StrEqual(weapon, "tank_claw", true))
					{
						hardmod_damage = GetConVarInt(hm_damage_tank);
					}
					if (StrEqual(weapon, "tank_rock", true))
					{
						hardmod_damage = GetConVarInt(hm_damage_tankrock);
					}
				}
			}
			if (StrEqual(weapon, "rifle_ak47", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_ak47);
			}
			if (StrEqual(weapon, "sniper_awp", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_awp);
			}
			if (StrEqual(weapon, "sniper_scout", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_scout);
			}
			if (StrEqual(weapon, "rifle_m60", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_m60);
			}
			if (StrEqual(weapon, "shotgun_spas", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_spas);
			}
			if (StrEqual(weapon, "rifle_sg552", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_sg552);
			}
			if (StrEqual(weapon, "smg", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_smg);
			}
			if (StrEqual(weapon, "smg_silenced", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_smg_silenced);
			}
			if (StrEqual(weapon, "rifle", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_m16);
			}
			if (StrEqual(weapon, "pumpshotgun", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_pumpshotgun);
			}
			if (StrEqual(weapon, "autoshotgun", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_autoshotgun);
			}
			if (StrEqual(weapon, "hunting_rifle", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_hunting_rifle);
			}
			if (StrEqual(weapon, "rifle_desert", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_rifle_desert);
			}
			if (StrEqual(weapon, "shotgun_chrome", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_shotgun_chrome);
			}
			if (StrEqual(weapon, "smg_mp5", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_smg_mp5);
			}
			if (StrEqual(weapon, "sniper_military", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_sniper_military);
			}
			if (StrEqual(weapon, "pistol", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_pistol);
			}
			if (StrEqual(weapon, "pistol_magnum", true))
			{
				hardmod_damage = GetConVarInt(hm_damage_pistol_magnum);
			}
		}
	}
	if (0 < hardmod_damage)
	{
		new var4;
		if (enemy && GetClientTeam(target) == 2 && GetClientTeam(enemy) == 2)
		{
			hardmod_damage = RoundToNearest(GetConVarFloat(hm_damage_friendly) * hardmod_damage);
		}
		dmg_health = hardmod_damage + dmg_health;
		SetEventInt(event, "dmg_health", dmg_health);
		DamageTarget(target, hardmod_damage);
	}
	if (0 < GetConVarInt(hm_damage_showvalue))
	{
		new var5;
		if (IsValidClient(enemy) && !IsFakeClient(enemy))
		{
			PrintHintText(enemy, "%d", dmg_health);
			PrintToChat(enemy, "\x05(урон) \x04%d", dmg_health);
		}
		new var6;
		if (IsValidClient(target) && !IsFakeClient(target))
		{
			PrintHintText(target, "-%d", dmg_health);
		}
	}
	return Action:0;
}

public DamageTarget(any:client, damage)
{
	if (GetHealth(client) < 1)
	{
		return 0;
	}
	new HP = GetHealth(client);
	if (HP > damage)
	{
		SetEntityHealth(client, HP - damage);
	}
	else
	{
		if (HP > 1)
		{
			damage -= HP + -1;
			SetEntityHealth(client, 1);
		}
		new TempHP = GetClientTempHealth(client);
		if (TempHP >= damage)
		{
			SetTempHealth(client, TempHP - damage);
		}
		else
		{
			new var1;
			if (GetClientTeam(client) == 2 && !IsGoingToDie(client))
			{
				IncapTarget(client);
			}
			if (GetConVarInt(hm_damage) > 2)
			{
				DamageEffect(client, 5.0);
			}
			SetTempHealth(client, 0);
		}
	}
	return 0;
}

DamageEffect(target, Float:damage)
{
	decl String:tName[20];
	Format(tName, 20, "target%d", target);
	new pointHurt = CreateEntityByName("point_hurt", -1);
	DispatchKeyValue(target, "targetname", tName);
	DispatchKeyValueFloat(pointHurt, "Damage", damage);
	DispatchKeyValue(pointHurt, "DamageTarget", tName);
	DispatchKeyValue(pointHurt, "DamageType", "65536");
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt", -1, -1, 0);
	AcceptEntityInput(pointHurt, "Kill", -1, -1, 0);
	return 0;
}

public GetHealth(client)
{
	return GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
}

GetClientTempHealth(client)
{
	new var1;
	if (!client || !IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientObserver(client) || GetClientTeam(client) == 2)
	{
		return -1;
	}
	new Float:buffer = GetEntPropFloat(client, PropType:0, "m_healthBuffer", 0);
	new Float:TempHealth = 0.0;
	if (buffer <= 0.0)
	{
		TempHealth = 0.0;
	}
	else
	{
		new Float:difference = GetGameTime() - GetEntPropFloat(client, PropType:0, "m_healthBufferTime", 0);
		new Float:decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
		new Float:constant = 1.0 / decay;
		TempHealth = buffer - difference / constant;
	}
	if (TempHealth < 0.0)
	{
		TempHealth = 0.0;
	}
	return RoundToFloor(TempHealth);
}

public SetTempHealth(client, hp)
{
	SetEntPropFloat(client, PropType:0, "m_healthBufferTime", GetGameTime(), 0);
	new Float:newOverheal = 1.0 * hp;
	SetEntPropFloat(client, PropType:0, "m_healthBuffer", newOverheal, 0);
	return 0;
}

public bool:IsGoingToDie(client)
{
	new var1;
	if (!IsValidEntity(client) || !IsValidEdict(client))
	{
		return false;
	}
	new m_isGoingToDie = GetEntProp(client, PropType:0, "m_isGoingToDie", 4, 0);
	if (m_isGoingToDie > 1)
	{
		return true;
	}
	return false;
}

GetLiveSurvivorsCount(bool:inGameOnly)
{
	new clients;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				if (IsPlayerAlive(i))
				{
					clients++;
				}
			}
		}
		i++;
	}
	return clients;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("TYSTATS_GetPoints", Native_TYSTATS_GetPoints);
	CreateNative("TYSTATS_GetRank", Native_TYSTATS_GetRank);
	return APLRes:0;
}

public Native_TYSTATS_GetPoints(Handle:plugin, numParams)
{
	return ClientPoints[GetNativeCell(1)];
}

public Native_TYSTATS_GetRank(Handle:plugin, numParams)
{
	return ClientRank[GetNativeCell(1)];
}

public void:OnPluginStart()
{
	LoadTranslations("tystats.phrases");
	BuildPath(PathType:0, datafilepath, 256, "configs/tystats.txt");
	ConnectDB();
	CoopAutoDiffOnPluginStart();
	DamageOnPluginStart();
	RegConsoleCmd("callvote", Callvote_Handler, "", 0);
	hm_blockvote_kick = CreateConVar("hm_blockvote_kick", "1", "", 262144, false, 0.0, false, 0.0);
	hm_blockvote_map = CreateConVar("hm_blockvote_map", "1", "", 262144, false, 0.0, false, 0.0);
	hm_allowvote_map_players = CreateConVar("hm_allowvote_map_players", "6", "", 262144, false, 0.0, false, 0.0);
	hm_blockvote_lobby = CreateConVar("hm_blockvote_lobby", "1", "", 262144, false, 0.0, false, 0.0);
	hm_blockvote_restart = CreateConVar("hm_blockvote_restart", "1", "", 262144, false, 0.0, false, 0.0);
	hm_blockvote_difficulty = CreateConVar("hm_blockvote_difficulty", "0", "", 262144, false, 0.0, false, 0.0);
	hm_blockvote_difference = CreateConVar("hm_blockvote_difference", "0", "", 262144, false, 0.0, false, 0.0);
	hm_allowvote_mission = CreateConVar("hm_allowvote_mission", "21", "", 262144, false, 0.0, false, 0.0);
	BuildPath(PathType:0, CV_FileName, 256, "hardmod/forbiddenmaps.txt");
	cvar_Hunter = CreateConVar("l4d2_tystats_hunter", "4", "Base score for killing a Hunter", 262144, true, 1.0, false, 0.0);
	cvar_Smoker = CreateConVar("l4d2_tystats_smoker", "4", "Base score for killing a Smoker", 262144, true, 1.0, false, 0.0);
	cvar_Boomer = CreateConVar("l4d2_tystats_boomer", "3", "Base score for killing a Boomer", 262144, true, 1.0, false, 0.0);
	cvar_Spitter = CreateConVar("l4d2_tystats_spitter", "5", "Base score for killing a Spitter", 262144, true, 1.0, false, 0.0);
	cvar_Jockey = CreateConVar("l4d2_tystats_jockey", "4", "Base score for killing a Jockey", 262144, true, 1.0, false, 0.0);
	cvar_Charger = CreateConVar("l4d2_tystats_charger", "6", "Base score for killing a Charger", 262144, true, 1.0, false, 0.0);
	cvar_Witch = CreateConVar("l4d2_tystats_witch", "7", "Base score for killing a Witch", 262144, true, 1.0, false, 0.0);
	cvar_Tank = CreateConVar("l4d2_tystats_tank", "10", "Base score for killing a Tank", 262144, true, 1.0, false, 0.0);
	cvar_Bonus = CreateConVar("l4d2_tystats_bonus", "2", "Bonus score for killing bosses", 262144, true, 1.0, false, 0.0);
	cvar_SiteURL = CreateConVar("l4d_stats_siteurl", "ruscoop25.myarena.ru/l4dstats/", "Community site URL, for rank panel display", 262144, false, 0.0, false, 0.0);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode:1);
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode:1);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode:1);
	HookEvent("player_incapacitated", Event_PlayerIncap, EventHookMode:1);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode:1);
	HookEvent("round_start", Event_RoundStart, EventHookMode:1);
	HookEvent("heal_success", Event_HealPlayer, EventHookMode:1);
	HookEvent("defibrillator_used", Event_DefibPlayer, EventHookMode:1);
	HookEvent("revive_success", Event_ReviveSuccess, EventHookMode:1);
	HookEvent("player_now_it", Event_PlayerNowIt, EventHookMode:1);
	HookEvent("survivor_rescued", Event_SurvivorRescued, EventHookMode:1);
	HookEvent("award_earned", Event_Award_L4D2, EventHookMode:1);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode:1);
	HookEvent("map_transition", Event_MapTransition, EventHookMode:1);
	HookEvent("finale_win", Event_FinalWin, EventHookMode:1);
	HookEvent("player_disconnect", Event_Disconnect, EventHookMode:0);
	HookEvent("player_left_start_area", Event_StartArea, EventHookMode:1);
	HookEvent("player_left_checkpoint", Event_StartArea, EventHookMode:1);
	HookEvent("round_end", Event_RoundEnd, EventHookMode:1);
	RegConsoleCmd("sm_myrank", cmd_ShowRank, "", 0);
	RegConsoleCmd("sm_rank", Command_RankPlayer, "sm_rank <target>", 0);
	RegConsoleCmd("sm_top10", cmd_ShowTop10, "", 0);
	RegConsoleCmd("sm_top15", cmd_ShowTop15, "", 0);
	RegConsoleCmd("sm_top20", cmd_ShowTop20, "", 0);
	RegConsoleCmd("sm_nextrank", cmd_NextRank, "", 0);
	RegConsoleCmd("sm_ranktarget", cmd_ShowRankTarget, "", 0);
	RegConsoleCmd("sm_showpoints", Command_totalPoints_to_all, "", 0);
	RegConsoleCmd("sm_points", Command_Points, "", 0);
	RegConsoleCmd("sm_playtime", Command_Playtime, "", 0);
	RegConsoleCmd("sm_maptop", Command_MapTop, "", 0);
	RegConsoleCmd("sm_ranksum", Command_RankSum, "", 0);
	RegConsoleCmd("sm_city17", Command_city17l4d2, "", 0);
	RegConsoleCmd("sm_warcelona", Command_warcelona, "", 0);
	RegConsoleCmd("sm_ravenholm", Command_ravenholm, "", 0);
	RegConsoleCmd("sm_lastsummer", Command_lastsummer, "", 0);
	RegConsoleCmd("sm_yama", Command_yama, "", 0);
	RegConsoleCmd("sm_one4nine", Command_one4nine, "", 0);
	RegAdminCmd("sm_rankpluginrefresh", Command_Refresh, 256, "", "", 0);
	RegAdminCmd("sm_mapfinished", Command_MapFinished, 256, "", "", 0);
	RegAdminCmd("sm_mapnotfinished", Command_MapNotFinished, 256, "", "", 0);
	RegAdminCmd("sm_tystatsbonus", Command_Bonus, 256, "", "", 0);
	RegAdminCmd("sm_givepoints", Command_GivePoints, 16384, "sm_givepoints <target> [Score]", "", 0);
	RegAdminCmd("sm_rank_motd", Command_SetMotd, 2, "Set Message Of The Day", "", 0);
	hm_count_fails = CreateConVar("hm_count_fails", "1", "", 262144, false, 0.0, false, 0.0);
	hm_stats_colors = CreateConVar("hm_stats_colors", "2", "", 262144, false, 0.0, false, 0.0);
	hm_stats_bot_colors = CreateConVar("hm_stats_bot_colors", "1", "", 262144, false, 0.0, false, 0.0);
	l4d2_players_join_message_timer = CreateConVar("l4d2_players_join_message_timer", "10", "", 262144, false, 0.0, false, 0.0);
	l4d2_rankmod_mode = CreateConVar("l4d2_rankmod_mode", "0", "", 262144, false, 0.0, false, 0.0);
	l4d2_rankmod_min = CreateConVar("l4d2_rankmod_min", "0.5", "", 262144, false, 0.0, false, 0.0);
	l4d2_rankmod_max = CreateConVar("l4d2_rankmod_max", "1.0", "", 262144, false, 0.0, false, 0.0);
	l4d2_rankmod_logarithm = CreateConVar("l4d2_rankmod_logarithm", "0.008", "", 262144, false, 0.0, false, 0.0);
	SDifficultyMultiplier = CreateConVar("l4d2_difficulty_stats", "1.0", "", 262144, false, 0.0, false, 0.0);
	g_HaveSteam_Trie = CreateTrie();
	RegConsoleCmd("steam", steam_command, "", 0);
	CreateTimer(60.0, timer_UpdatePlayersPlaytime, any:0, 1);
	return void:0;
}

public void:OnClientConnected(client)
{
	g_Socket[client] = 0;
	g_HaveSteam[client] = 0;
	g_SteamID[client][0] = MissingTAG:0;
	g_ProfileID[client][0] = MissingTAG:0;
	return void:0;
}

public Action:timer_UpdatePlayersPlaytime(Handle:timer, Handle:hndl)
{
	if (StatsDisabled())
	{
		return Action:0;
	}
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			Playtime[i] += 1;
			CheckPlayerDB(i);
		}
		i++;
	}
	return Action:0;
}

public KnowRankPoints(client)
{
	if (StatsDisabled())
	{
		return 0;
	}
	if (!client)
	{
		return 0;
	}
	if (!IsClientInGame(client))
	{
		return 0;
	}
	if (IsFakeClient(client))
	{
		return 0;
	}
	decl String:steamId[64];
	GetClientAuthId(client, AuthIdType:1, steamId, 64, true);
	decl String:query[256];
	Format(query, 256, "SELECT COUNT(*) FROM players");
	SQL_TQuery(db, GetRankTotal, query, client, DBPriority:1);
	Format(query, 256, "SELECT points FROM players WHERE steamid = '%s'", steamId);
	SQL_TQuery(db, GetClientPoints, query, client, DBPriority:1);
	CreateTimer(0.6, TimertyGetClientRank, client, 0);
	return 0;
}

public KnowRankKills(client)
{
	if (StatsDisabled())
	{
		return 0;
	}
	if (!client)
	{
		return 0;
	}
	if (!IsClientInGame(client))
	{
		return 0;
	}
	if (IsFakeClient(client))
	{
		return 0;
	}
	decl String:SteamID[64];
	GetClientAuthId(client, AuthIdType:1, SteamID, 64, true);
	decl String:query[1024];
	Format(query, 1024, "SELECT kill_hunter,kill_smoker,kill_boomer,kill_spitter,kill_jockey,kill_charger,award_tankkill FROM players WHERE steamid = '%s'", SteamID);
	SQL_TQuery(db, GetClientKills, query, client, DBPriority:1);
	return 0;
}

public KnowRankPlaytime(client)
{
	if (StatsDisabled())
	{
		return 0;
	}
	if (!client)
	{
		return 0;
	}
	if (!IsClientInGame(client))
	{
		return 0;
	}
	if (IsFakeClient(client))
	{
		return 0;
	}
	decl String:SteamID[64];
	GetClientAuthId(client, AuthIdType:1, SteamID, 64, true);
	decl String:query[512];
	Format(query, 512, "SELECT playtime FROM players WHERE steamid = '%s'", SteamID);
	SQL_TQuery(db, GetClientPlaytime, query, client, DBPriority:1);
	return 0;
}

public void:OnClientDisconnect(client)
{
	DMOnClientDisconnect(client);
	g_votekick[client] = 0;
	if (Join_Timer[client])
	{
		KillTimer(Join_Timer[client], false);
		Join_Timer[client] = 0;
	}
	if (StatsDisabled())
	{
		return void:0;
	}
	if (!client)
	{
		return void:0;
	}
	if (IsFakeClient(client))
	{
		return void:0;
	}
	InterstitialPlayerUpdate(client);
	UpdatePlaytimePlayers(client);
	return void:0;
}

public void:OnClientDisconnect_Post(client)
{
	OnClientConnected(client);
	return void:0;
}

public void:OnClientAuthorized(client, String:steamid[])
{
	if (!(StrContains(steamid, "STEAM_", false)))
	{
		strcopy(g_SteamID[client], 30, steamid);
		decl bool:steam_client;
		if (GetTrieValue(g_HaveSteam_Trie, steamid, steam_client))
		{
			g_HaveSteam[client] = steam_client;
		}
		else
		{
			wS_GetProfileId(client, steamid);
		}
	}
	return void:0;
}

public InterstitialPlayerUpdate(client)
{
	decl String:SteamID[64];
	GetClientAuthId(client, AuthIdType:1, SteamID, 64, true);
	decl String:query[1024];
	Format(query, 1024, "UPDATE players SET points = points + %i, kills = kills + %i, kill_infected = kill_infected + %i, award_protect = award_protect + %i WHERE steamid = '%s'", CalculatePoints(NewPoints[client]), KillsInfected[client], KillsInfected[client], ProtectedFriendlyCounter[client], SteamID);
	SendSQLUpdate(query);
	ProtectedFriendlyCounter[client] = 0;
	NewPoints[client] = 0;
	KillsInfected[client] = 0;
	return 0;
}

UpdatePlaytimePlayers(client)
{
	if (StatsDisabled())
	{
		return 0;
	}
	if (!client)
	{
		return 0;
	}
	if (!IsClientInGame(client))
	{
		return 0;
	}
	if (IsFakeClient(client))
	{
		return 0;
	}
	if (Playtime[client])
	{
		new PlaytimeDB = Playtime[client] * 60;
		decl String:SteamID[64];
		GetClientAuthId(client, AuthIdType:1, SteamID, 64, true);
		decl String:query[512];
		Format(query, 512, "UPDATE players SET playtime = playtime + %i WHERE steamid = '%s'", PlaytimeDB, SteamID);
		SendSQLUpdate(query);
		PlaytimeDB = 0;
		Playtime[client] = 0;
		return 0;
	}
	return 0;
}

public Action:Event_Disconnect(Handle:event, String:name[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (!client)
	{
		return Action:0;
	}
	if (IsFakeClient(client))
	{
		return Action:0;
	}
	decl String:ip[16];
	decl String:country[48];
	if (IsClientInGame(client))
	{
		if (IsRealClient(client))
		{
			GetClientIP(client, ip, 16, true);
			new flags = GetUserFlagBits(client);
			if (GeoipCountry(ip, country, 45))
			{
				if (g_HaveSteam[client])
				{
					if (flags & 16384)
					{
						CPrintToChatAll("%t {red}%N \x05(%s)", "- Owner", client, country);
					}
					else
					{
						if (flags & 8192)
						{
							CPrintToChatAll("%t {red}%N \x05(%s)", "- Admin", client, country);
						}
						if (flags & 2)
						{
							CPrintToChatAll("%t {red}%N \x05(%s)", "- Moderator", client, country);
						}
						if (flags & 1)
						{
							CPrintToChatAll("%t {red}%N \x05(%s)", "- VIP", client, country);
						}
						CPrintToChatAll("%t {blue}%N \x05(%s)", "- Player", client, country);
					}
				}
				else
				{
					if (flags & 16384)
					{
						CPrintToChatAll("%t {red}%N \x05(%s) \x04[\x03no-steam\x04]", "- Owner", client, country);
					}
					if (flags & 8192)
					{
						CPrintToChatAll("%t {red}%N \x05(%s) \x04[\x03no-steam\x04]", "- Admin", client, country);
					}
					if (flags & 2)
					{
						CPrintToChatAll("%t {red}%N \x05(%s) \x04[\x03no-steam\x04]", "- Moderator", client, country);
					}
					if (flags & 1)
					{
						CPrintToChatAll("%t {red}%N \x05(%s) \x04[\x03no-steam\x04]", "- VIP", client, country);
					}
					CPrintToChatAll("%t {blue}%N \x05(%s) \x04[\x03no-steam\x04]", "- Player", client, country);
				}
			}
			else
			{
				if (g_HaveSteam[client])
				{
					if (flags & 16384)
					{
						CPrintToChatAll("%t {red}%N", "- Owner", client);
					}
					else
					{
						if (flags & 8192)
						{
							CPrintToChatAll("%t {red}%N", "- Admin", client);
						}
						if (flags & 2)
						{
							CPrintToChatAll("%t {red}%N", "- Moderator", client);
						}
						if (flags & 1)
						{
							CPrintToChatAll("%t {red}%N", "- VIP", client);
						}
						CPrintToChatAll("%t {blue}%N", "- Player", client);
					}
				}
				if (flags & 16384)
				{
					CPrintToChatAll("%t {red}%N \x04[\x03no-steam\x04]", "- Owner", client);
				}
				if (flags & 8192)
				{
					CPrintToChatAll("%t {red}%N \x04[\x03no-steam\x04]", "- Admin", client);
				}
				if (flags & 2)
				{
					CPrintToChatAll("%t {red}%N \x04[\x03no-steam\x04]", "- Moderator", client);
				}
				if (flags & 1)
				{
					CPrintToChatAll("%t {red}%N \x04[\x03no-steam\x04]", "- VIP", client);
				}
				CPrintToChatAll("%t {blue}%N \x04[\x03no-steam\x04]", "- Player", client);
			}
		}
	}
	if (!IsTimeAutodifficulty)
	{
		return Action:0;
	}
	ADPlayerTeam();
	return Action:0;
}

public Action:TimertyGetClientRank(Handle:timer, any:client)
{
	if (StatsDisabled())
	{
		return Action:4;
	}
	if (!client)
	{
		return Action:4;
	}
	if (!IsClientInGame(client))
	{
		return Action:4;
	}
	if (IsFakeClient(client))
	{
		return Action:4;
	}
	decl String:query[256];
	Format(query, 256, "SELECT COUNT(*) FROM players WHERE points >=%i", ClientPoints[client]);
	SQL_TQuery(db, GetClientRank, query, client, DBPriority:1);
	return Action:4;
}

public GetClientPoints(Handle:owner, Handle:hndl, String:error[], any:client)
{
	new var1;
	if (!client || hndl)
	{
		return 0;
	}
	while (SQL_FetchRow(hndl))
	{
		ClientPoints[client] = SQL_FetchInt(hndl, 0, 0);
	}
	return 0;
}

public GetClientKills(Handle:owner, Handle:hndl, String:error[], any:client)
{
	new var1;
	if (!client || hndl)
	{
		return 0;
	}
	while (SQL_FetchRow(hndl))
	{
		ClientKills[client] = SQL_FetchInt(hndl, 6, 0) + SQL_FetchInt(hndl, 5, 0) + SQL_FetchInt(hndl, 4, 0) + SQL_FetchInt(hndl, 3, 0) + SQL_FetchInt(hndl, 2, 0) + SQL_FetchInt(hndl, 1, 0) + SQL_FetchInt(hndl, 0, 0);
	}
	return 0;
}

public GetClientPlaytime(Handle:owner, Handle:hndl, String:error[], any:client)
{
	new var1;
	if (!client || hndl)
	{
		return 0;
	}
	while (SQL_FetchRow(hndl))
	{
		ClientPlaytime[client] = SQL_FetchInt(hndl, 0, 0);
	}
	return 0;
}

public GetClientRank(Handle:owner, Handle:hndl, String:error[], any:client)
{
	new var1;
	if (!client || hndl)
	{
		return 0;
	}
	while (SQL_FetchRow(hndl))
	{
		ClientRank[client] = SQL_FetchInt(hndl, 0, 0);
	}
	return 0;
}

public GetRankTotal(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if (!hndl)
	{
		return 0;
	}
	while (SQL_FetchRow(hndl))
	{
		RankTotal = SQL_FetchInt(hndl, 0, 0);
	}
	return 0;
}

public updateptystatslayers()
{
	new round_fails = round_end_repeats;
	if (round_end_repeats > 3)
	{
		round_fails = 3;
	}
	if (GetRealtyClientCount(true) > 15)
	{
		tystatsbalans = 3 - round_fails;
	}
	else
	{
		if (GetRealtyClientCount(true) > 8)
		{
			tystatsbalans = 2 - round_fails;
		}
		if (GetRealtyClientCount(true) > 4)
		{
			tystatsbalans = 1 - round_fails;
		}
		tystatsbalans = 0;
	}
	return 0;
}

public void:OnMapStart()
{
	ADOnMapStart();
	IsTimeAutodifficulty = false;
	round_end_repeats = 0;
	PrecacheSound("buttons/blip1.wav", true);
	PrecacheSound("level/countdown.wav", true);
	PrecacheSound("level/bell_normal.wav", true);
	new i = 1;
	while (i <= MaxClients)
	{
		g_votekick[i] = 0;
		i++;
	}
	return void:0;
}

public Action:Event_RoundStart(Handle:hEvent, String:strName[], bool:DontBroadcast)
{
	ADRoundStart();
	IsMapFinished = false;
	IsRoundStarted = true;
	tystatsbalans = 0;
	bonus = 0;
	MapTimingStartTime = 0.0;
	CreateTimer(6.0, TimedColortystats, any:0, 0);
	CreateTimer(25.0, TimedAutoDifficultyInit, any:0, 0);
	return Action:0;
}

public Event_RoundEnd(Handle:event, String:name[], bool:dontBroadcast)
{
	if (!IsRoundStarted)
	{
		return 0;
	}
	round_end_repeats += 1;
	return 0;
}

public Action:TimedColortystats(Handle:timer, any:client)
{
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsValidEntity(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			RanktyConnect(i);
		}
		i++;
	}
	return Action:0;
}

public Action:TimedAutoDifficultyInit(Handle:timer, any:client)
{
	IsTimeAutodifficulty = true;
	AutoDifficultyInit();
	Autodifficulty();
	return Action:0;
}

public void:OnClientPostAdminCheck(client)
{
	if (!IsValidEntity(client))
	{
		return void:0;
	}
	if (IsFakeClient(client))
	{
		return void:0;
	}
	Join_Timer[client] = CreateTimer(1065353216 * GetConVarInt(l4d2_players_join_message_timer), PlayerJoinMessage, client, 0);
	if (StatsDisabled())
	{
		return void:0;
	}
	TKblockPunishment[client] = 0;
	TKblockDamage[client] = 0;
	ClientPoints[client] = 0;
	ClientRank[client] = 0;
	ClientKills[client] = 0;
	ProtectedFriendlyCounter[client] = 0;
	ClientPlaytime[client] = 0;
	Playtime[client] = 0;
	KillsInfected[client] = 0;
	NewPoints[client] = 0;
	g_votekick[client] = 0;
	CreateTimer(7.0, Timedtyclient, client, 0);
	return void:0;
}

public Action:Timedtyclient(Handle:timer, any:client)
{
	if (!client)
	{
		return Action:4;
	}
	if (!IsClientInGame(client))
	{
		return Action:4;
	}
	if (IsFakeClient(client))
	{
		return Action:4;
	}
	if (StatsDisabled())
	{
		return Action:4;
	}
	CheckPlayerDB(client);
	KnowRankPoints(client);
	CreateTimer(GetRandomFloat(5.5, 8.5) * 1.0, RankConnect, client, 0);
	return Action:4;
}

public Action:RankConnect(Handle:timer, any:client)
{
	if (!client)
	{
		return Action:4;
	}
	if (!IsClientInGame(client))
	{
		return Action:4;
	}
	if (IsFakeClient(client))
	{
		return Action:4;
	}
	PrintToChat(client, "%t", "Rank: %i of %i. Points: %i", ClientRank[client], RankTotal, ClientPoints[client]);
	RanktyConnect(client);
	return Action:4;
}

public Action:PlayerJoinMessage(Handle:timer, any:client)
{
	decl String:ip[16];
	decl String:country[48];
	if (IsClientInGame(client))
	{
		if (IsRealClient(client))
		{
			GetClientIP(client, ip, 16, true);
			new flags = GetUserFlagBits(client);
			if (GeoipCountry(ip, country, 45))
			{
				if (g_HaveSteam[client])
				{
					if (flags & 16384)
					{
					}
					else
					{
						if (flags & 8192)
						{
							CPrintToChatAll("%t {blue}%N \x05(%s)", "+ Admin", client, country);
						}
						if (flags & 2)
						{
							CPrintToChatAll("%t {blue}%N \x05(%s)", "+ Moderator", client, country);
						}
						if (flags & 1)
						{
							CPrintToChatAll("%t {blue}%N \x05(%s)", "+ VIP", client, country);
						}
						CPrintToChatAll("%t {blue}%N \x05(%s)", "+ Player", client, country);
					}
				}
				else
				{
					if (!(flags & 16384))
					{
						if (flags & 8192)
						{
							CPrintToChatAll("%t {blue}%N \x05(%s) \x04[\x03no-steam\x04]", "+ Admin", client, country);
						}
						if (flags & 2)
						{
							CPrintToChatAll("%t {blue}%N \x05(%s) \x04[\x03no-steam\x04]", "+ Moderator", client, country);
						}
						if (flags & 1)
						{
							CPrintToChatAll("%t {blue}%N \x05(%s) \x04[\x03no-steam\x04]", "+ VIP", client, country);
						}
						CPrintToChatAll("%t {blue}%N \x05(%s) \x04[\x03no-steam\x04]", "+ Player", client, country);
					}
				}
			}
			else
			{
				if (g_HaveSteam[client])
				{
					if (flags & 16384)
					{
					}
					else
					{
						if (flags & 8192)
						{
							CPrintToChatAll("%t {blue}%N", "+ Admin", client);
						}
						if (flags & 2)
						{
							CPrintToChatAll("%t {blue}%N", "+ Moderator", client);
						}
						if (flags & 1)
						{
							CPrintToChatAll("%t {blue}%N", "+ VIP", client);
						}
						CPrintToChatAll("%t {blue}%N", "+ Player", client);
					}
				}
				if (!(flags & 16384))
				{
					if (flags & 8192)
					{
						CPrintToChatAll("%t {blue}%N \x04[\x03no-steam\x04]", "+ Admin", client);
					}
					if (flags & 2)
					{
						CPrintToChatAll("%t {blue}%N \x04[\x03no-steam\x04]", "+ Moderator", client);
					}
					if (flags & 1)
					{
						CPrintToChatAll("%t {blue}%N \x04[\x03no-steam\x04]", "+ VIP", client);
					}
					CPrintToChatAll("%t {blue}%N \x04[\x03no-steam\x04]", "+ Player", client);
				}
			}
			EmitSoundToAll("buttons/blip1.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	Join_Timer[client] = 0;
	return Action:0;
}

public RanktyConnect(client)
{
	new var1;
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetClientTeam(client) == 2)
		{
			if (IsPlayerAlive(client))
			{
				if (ClientPoints[client] >= 640000)
				{
					SetEntityRenderColor(client, 255, 97, 3, 255);
				}
				if (ClientPoints[client] >= 320000)
				{
					SetEntityRenderColor(client, 255, 0, 0, 255);
				}
				if (ClientPoints[client] >= 160000)
				{
					SetEntityRenderColor(client, 255, 104, 240, 255);
				}
				if (ClientPoints[client] >= 80000)
				{
					SetEntityRenderColor(client, 102, 25, 140, 255);
				}
				if (ClientPoints[client] >= 40000)
				{
					SetEntityRenderColor(client, 0, 139, 0, 255);
				}
				if (ClientPoints[client] >= 20000)
				{
					SetEntityRenderColor(client, 0, 0, 255, 255);
				}
				if (ClientPoints[client] >= 10000)
				{
					SetEntityRenderColor(client, 255, 255, 0, 255);
				}
				if (ClientPoints[client] >= 5000)
				{
					SetEntityRenderColor(client, 173, 255, 47, 255);
				}
			}
		}
	}
	return 0;
}

public ConnectDB()
{
	if (SQL_CheckConfig("l4dstats"))
	{
		new String:Error[256];
		db = SQL_Connect("l4dstats", true, Error, 256);
		if (db)
		{
			SendSQLUpdate("SET NAMES 'utf8'");
		}
		else
		{
			LogError("Failed to connect to database: %s", Error);
		}
	}
	else
	{
		LogError("database.cfg missing 'l4dstats' entry!");
	}
	return 0;
}

CheckPlayerDB(client)
{
	if (StatsDisabled())
	{
		return 0;
	}
	if (!client)
	{
		return 0;
	}
	if (!IsClientInGame(client))
	{
		return 0;
	}
	if (IsFakeClient(client))
	{
		return 0;
	}
	decl String:SteamID[64];
	GetClientAuthId(client, AuthIdType:1, SteamID, 64, true);
	decl String:query[512];
	Format(query, 512, "SELECT steamid FROM players WHERE steamid = '%s'", SteamID);
	SQL_TQuery(db, InsertPlayerDB, query, client, DBPriority:1);
	return 0;
}

public InsertPlayerDB(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if (StatsDisabled())
	{
		return 0;
	}
	new client = data;
	new var1;
	if (!client || hndl)
	{
		return 0;
	}
	if (StatsDisabled())
	{
		return 0;
	}
	if (!IsClientInGame(client))
	{
		return 0;
	}
	if (!SQL_GetRowCount(hndl))
	{
		new String:SteamID[64];
		GetClientAuthId(client, AuthIdType:1, SteamID, 64, true);
		new String:query[512];
		Format(query, 512, "INSERT IGNORE INTO players SET steamid = '%s'", SteamID);
		SQL_TQuery(db, SQLErrorCheckCallback, query, any:0, DBPriority:1);
	}
	UpdatePlayer(client);
	return 0;
}

public SendSQLUpdate(String:query[])
{
	if (db)
	{
		SQL_TQuery(db, SQLErrorCheckCallback, query, any:0, DBPriority:1);
		return 0;
	}
	return 0;
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if (db)
	{
		if (!StrEqual("", error, true))
		{
			LogError("SQL Error: %s", error);
		}
		return 0;
	}
	return 0;
}

public UpdatePlayer(client)
{
	if (!IsClientConnected(client))
	{
		return 0;
	}
	decl String:SteamID[64];
	GetClientAuthId(client, AuthIdType:1, SteamID, 64, true);
	decl String:Name[64];
	GetClientName(client, Name, 64);
	ReplaceString(Name, 64, "<?php", "", true);
	ReplaceString(Name, 64, "<?PHP", "", true);
	ReplaceString(Name, 64, "?>", "", true);
	ReplaceString(Name, 64, "\", "", true);
	ReplaceString(Name, 64, "\"", "", true);
	ReplaceString(Name, 64, "'", "", true);
	ReplaceString(Name, 64, ";", "", true);
	ReplaceString(Name, 64, "ґ", "", true);
	ReplaceString(Name, 64, "`", "", true);
	decl String:IP[16];
	GetClientIP(client, IP, 16, true);
	decl String:query[512];
	Format(query, 512, "UPDATE players SET lastontime = UNIX_TIMESTAMP(), ip = '%s', points = points + 0, name = '%s' WHERE steamid = '%s'", IP, Name, SteamID);
	SendSQLUpdate(query);
	return 0;
}

public Action:Event_WitchKilled(Handle:hEvent, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid", 0));
	if (!IsValidEntity(client))
	{
		return Action:0;
	}
	if (!client)
	{
		return Action:0;
	}
	if (IsFakeClient(client))
	{
		return Action:0;
	}
	decl String:SteamID[64];
	GetClientAuthId(client, AuthIdType:1, SteamID, 64, true);
	new Score;
	decl String:query2[512];
	Score = GetConVarInt(cvar_Witch) + tystatsbalans + bonus;
	Format(query2, 512, "UPDATE players SET kill_witch = kill_witch + 1 WHERE steamid = '%s'", SteamID);
	if (IsMapFinished)
	{
		Score = 0;
	}
	SendSQLUpdate(query2);
	AddScore(client, Score);
	return Action:0;
}

public Action:Event_PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker", 0));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (!IsValidEntity(Attacker))
	{
		return Action:0;
	}
	if (!Attacker)
	{
		return Action:0;
	}
	if (IsFakeClient(Attacker))
	{
		return Action:0;
	}
	if (Victim == Attacker)
	{
		return Action:0;
	}
	if (StatsDisabled())
	{
		return Action:0;
	}
	decl String:AttackerID[64];
	GetClientAuthId(Attacker, AuthIdType:1, AttackerID, 64, true);
	decl String:VictimName[64];
	GetEventString(event, "victimname", VictimName, 64, "");
	new Score;
	decl String:query2[512];
	new var1;
	if (Victim > 0 && !IsFakeClient(Victim) && GetClientTeam(Victim) == 2 && GetClientTeam(Attacker) == 2)
	{
		Score = -50;
		TKblockDamage[Attacker] = TKblockDamage[Attacker] + 30;
		CPrintToChat(Victim, "%t", "%N attacked %N (%i TK)", Attacker, Victim, TKblockDamage[Attacker]);
		CPrintToChat(Attacker, "%t", "%N attacked %N (%i TK)", Attacker, Victim, TKblockDamage[Attacker]);
		PunishTeamkiller(Attacker);
		Format(query2, 512, "UPDATE players SET award_teamkill = award_teamkill + 1 WHERE steamid = '%s'", AttackerID);
	}
	if (StrEqual(VictimName, "Infected", false))
	{
		KillsInfected[Attacker]++;
		return Action:0;
	}
	if (!Victim)
	{
		return Action:0;
	}
	if (GetClientTeam(Victim) != 3)
	{
		return Action:0;
	}
	new iClass = GetEntProp(Victim, PropType:0, "m_zombieClass", 4, 0);
	if (iClass == 3)
	{
		Score = GetConVarInt(cvar_Hunter) + tystatsbalans + bonus;
		Format(query2, 512, "UPDATE players SET kill_hunter = kill_hunter + 1, kills = kills + 1 WHERE steamid = '%s'", AttackerID);
	}
	else
	{
		if (iClass == 1)
		{
			Score = GetConVarInt(cvar_Smoker) + tystatsbalans + bonus;
			Format(query2, 512, "UPDATE players SET kill_smoker = kill_smoker + 1, kills = kills + 1 WHERE steamid = '%s'", AttackerID);
		}
		if (iClass == 2)
		{
			Score = GetConVarInt(cvar_Boomer) + tystatsbalans + bonus;
			Format(query2, 512, "UPDATE players SET kill_boomer = kill_boomer + 1, kills = kills + 1 WHERE steamid = '%s'", AttackerID);
		}
		if (iClass == 5)
		{
			Score = GetConVarInt(cvar_Jockey) + tystatsbalans + bonus;
			Format(query2, 512, "UPDATE players SET kill_jockey = kill_jockey + 1, kills = kills + 1 WHERE steamid = '%s'", AttackerID);
		}
		if (iClass == 6)
		{
			Score = GetConVarInt(cvar_Charger) + tystatsbalans + bonus;
			Format(query2, 512, "UPDATE players SET kill_charger = kill_charger + 1, kills = kills + 1 WHERE steamid = '%s'", AttackerID);
		}
		if (iClass == 4)
		{
			Score = GetConVarInt(cvar_Spitter) + tystatsbalans + bonus;
			Format(query2, 512, "UPDATE players SET kill_spitter = kill_spitter + 1, kills = kills + 1 WHERE steamid = '%s'", AttackerID);
		}
		if (iClass == 8)
		{
			Score = GetConVarInt(cvar_Tank) + tystatsbalans + bonus;
			Format(query2, 512, "UPDATE players SET award_tankkill = award_tankkill + 1 WHERE steamid = '%s'", AttackerID);
		}
		return Action:0;
	}
	if (IsMapFinished)
	{
		if (0 < Score)
		{
			Score = 0;
		}
	}
	SendSQLUpdate(query2);
	AddScore(Attacker, Score);
	return Action:0;
}

public Action:Event_PlayerIncap(Handle:event, String:name[], bool:dontBroadcast)
{
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker", 0));
	new userid = GetClientOfUserId(GetEventInt(event, "userid", 0));
	PlayerIncap(Attacker, userid);
	if (!Attacker)
	{
		return Action:0;
	}
	new var1;
	if (IsFakeClient(Attacker) || IsFakeClient(userid))
	{
		return Action:0;
	}
	if (userid == Attacker)
	{
		return Action:0;
	}
	new var2;
	if (GetClientTeam(Attacker) == 2 && GetClientTeam(userid) == 2)
	{
		return Action:0;
	}
	TKblockDamage[Attacker] = TKblockDamage[Attacker] + 10;
	CPrintToChat(userid, "%t", "%N attacked %N (%i TK)", Attacker, userid, TKblockDamage[Attacker]);
	CPrintToChat(Attacker, "%t", "%N attacked %N (%i TK)", Attacker, userid, TKblockDamage[Attacker]);
	PunishTeamkiller(Attacker);
	if (StatsDisabled())
	{
		return Action:0;
	}
	decl String:AttackerID[64];
	GetClientAuthId(Attacker, AuthIdType:1, AttackerID, 64, true);
	decl String:query2[512];
	Format(query2, 512, "UPDATE players SET award_fincap = award_fincap + 1 WHERE steamid = '%s'", AttackerID);
	SendSQLUpdate(query2);
	new Score = 10 * -1;
	AddScore(Attacker, Score);
	return Action:0;
}

public Action:Event_PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker", 0));
	new target = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (!Attacker)
	{
		return Action:0;
	}
	if (GetEventInt(event, "dmg_health", 0) < 1)
	{
		return Action:0;
	}
	if (target == Attacker)
	{
		return Action:0;
	}
	new var1;
	if (IsFakeClient(Attacker) || IsFakeClient(target))
	{
		return Action:0;
	}
	new var2;
	if (GetClientTeam(Attacker) == 2 && GetClientTeam(target) == 2)
	{
		return Action:0;
	}
	new Score = -GetEventInt(event, "dmg_health", 0) * Score / 3;
	if (!Score)
	{
		Score = -1;
	}
	TKblockDamage[Attacker] = TKblockDamage[Attacker][Score * -1];
	CPrintToChat(target, "%t", "%N attacked %N (%i TK)", Attacker, target, TKblockDamage[Attacker]);
	CPrintToChat(Attacker, "%t", "%N attacked %N (%i TK)", Attacker, target, TKblockDamage[Attacker]);
	PunishTeamkiller(Attacker);
	if (StatsDisabled())
	{
		return Action:0;
	}
	AddScore(Attacker, Score);
	return Action:0;
}

public Action:Event_HealPlayer(Handle:event, String:name[], bool:dontBroadcast)
{
	new Recepient = GetClientOfUserId(GetEventInt(event, "subject", 0));
	new Giver = GetClientOfUserId(GetEventInt(event, "userid", 0));
	new restored = GetEventInt(event, "health_restored", 0);
	new var1;
	if (IsFakeClient(Recepient) || IsFakeClient(Giver))
	{
		return Action:0;
	}
	decl String:query2[512];
	decl String:GiverID[64];
	GetClientAuthId(Giver, AuthIdType:1, GiverID, 64, true);
	if (Giver == Recepient)
	{
		Format(query2, 512, "UPDATE players SET heal = heal + 1 WHERE steamid = '%s'", GiverID);
	}
	else
	{
		TKblockDamage[Giver] = TKblockDamage[Giver] + -16;
		if (0 >= TKblockDamage[Giver])
		{
			TKblockDamage[Giver] = 0;
		}
		if (StatsDisabled())
		{
			return Action:0;
		}
		new Score = 4;
		if (restored > 39)
		{
			Format(query2, 512, "UPDATE players SET award_medkit = award_medkit + 1 WHERE steamid = '%s'", GiverID);
		}
		AddScore(Giver, Score);
	}
	SendSQLUpdate(query2);
	return Action:0;
}

public Action:Event_DefibPlayer(Handle:event, String:name[], bool:dontBroadcast)
{
	new Recipient = GetClientOfUserId(GetEventInt(event, "subject", 0));
	new Giver = GetClientOfUserId(GetEventInt(event, "userid", 0));
	new var1;
	if (IsFakeClient(Recipient) || IsFakeClient(Giver))
	{
		return Action:0;
	}
	if (Giver == Recipient)
	{
		return Action:0;
	}
	if (StatsDisabled())
	{
		return Action:0;
	}
	new Score = 4;
	decl String:GiverID[64];
	GetClientAuthId(Giver, AuthIdType:1, GiverID, 64, true);
	decl String:query2[1024];
	Format(query2, 1024, "UPDATE players SET award_defib = award_defib + 1 WHERE steamid = '%s'", GiverID);
	SendSQLUpdate(query2);
	AddScore(Giver, Score);
	return Action:0;
}

public OnDefibPlayerByMedkit(client, target)
{
	if (IsFakeClient(target))
	{
		return 0;
	}
	if (StatsDisabled())
	{
		return 0;
	}
	new Score = 4;
	decl String:clientID[64];
	GetClientAuthId(client, AuthIdType:1, clientID, 64, true);
	decl String:query2[1024];
	Format(query2, 1024, "UPDATE players SET award_defib = award_defib + 1 WHERE steamid = '%s'", clientID);
	SendSQLUpdate(query2);
	AddScore(client, Score);
	return 0;
}

public Action:Event_ReviveSuccess(Handle:event, String:name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "subject", 0));
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	new var1;
	if (IsFakeClient(target) || IsFakeClient(client))
	{
		return Action:0;
	}
	if (client == target)
	{
		return Action:0;
	}
	TKblockDamage[client] = TKblockDamage[client] + -8;
	if (0 >= TKblockDamage[client])
	{
		TKblockDamage[client] = 0;
	}
	if (StatsDisabled())
	{
		return Action:0;
	}
	new Score = 2;
	decl String:GiverID[64];
	GetClientAuthId(client, AuthIdType:1, GiverID, 64, true);
	decl String:query2[1024];
	Format(query2, 1024, "UPDATE players SET award_revive = award_revive + 1 WHERE steamid = '%s'", GiverID);
	SendSQLUpdate(query2);
	AddScore(client, Score);
	GrantPlayerColor(target);
	return Action:0;
}

public Action:Event_PlayerNowIt(Handle:event, String:name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (!IsValidClient(target))
	{
		return Action:0;
	}
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker", 0));
	if (StatsDisabled())
	{
		return Action:0;
	}
	new Score;
	if (attacker)
	{
		new var1;
		if (!IsClientConnected(attacker) || !IsClientInGame(attacker))
		{
			return Action:0;
		}
		if (IsFakeClient(attacker))
		{
			return Action:0;
		}
		if (GetClientTeam(attacker) != 2)
		{
			return Action:0;
		}
		if (attacker == target)
		{
			Score = 3;
		}
		else
		{
			if (GetClientTeam(target) == 3)
			{
				if (GetClientZC(target) == 8)
				{
					Score = 8;
					CPrintToChatAll("\x04Player {blue}%N \x01vomit \x05Tank", attacker);
				}
			}
		}
		AddScore(attacker, Score);
		return Action:0;
	}
	return Action:0;
}

public Action:Event_SurvivorRescued(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "rescuer", 0));
	new target = GetClientOfUserId(GetEventInt(event, "victim", 0));
	if (!IsValidClient(client))
	{
		return Action:0;
	}
	if (IsFakeClient(client))
	{
		return Action:0;
	}
	if (IsFakeClient(target))
	{
		return Action:0;
	}
	if (StatsDisabled())
	{
		return Action:0;
	}
	new Score = 1;
	decl String:clientID[64];
	GetClientAuthId(client, AuthIdType:1, clientID, 64, true);
	decl String:query2[1024];
	Format(query2, 1024, "UPDATE players SET award_rescue = award_rescue + 1 WHERE steamid = '%s'", clientID);
	SendSQLUpdate(query2);
	AddScore(client, Score);
	return Action:0;
}

public Action:Event_Award_L4D2(Handle:event, String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
	{
		return Action:0;
	}
	new PlayerID = GetEventInt(event, "userid", 0);
	if (!PlayerID)
	{
		return Action:0;
	}
	new client = GetClientOfUserId(PlayerID);
	if (IsFakeClient(client))
	{
		return Action:0;
	}
	new target = GetEventInt(event, "subjectentid", 0);
	new Recipient;
	new String:AwardSQL[128];
	new AwardID = GetEventInt(event, "award", 0);
	decl String:UserID[64];
	GetClientAuthId(client, AuthIdType:1, UserID, 64, true);
	if (AwardID == 67)
	{
		if (!target)
		{
			return Action:0;
		}
		ProtectedFriendlyCounter[client]++;
		return Action:0;
	}
	if (AwardID == 68)
	{
		if (!target)
		{
			return Action:0;
		}
		Recipient = GetClientOfUserId(GetClientUserId(target));
		GivePills(client, Recipient, -1);
		return Action:0;
	}
	if (AwardID == 69)
	{
		if (!target)
		{
			return Action:0;
		}
		Recipient = GetClientOfUserId(GetClientUserId(target));
		GiveAdrenaline(client, Recipient, -1);
		return Action:0;
	}
	if (AwardID == 85)
	{
		if (!target)
		{
			return Action:0;
		}
		Recipient = GetClientOfUserId(GetClientUserId(target));
		PlayerIncap(client, Recipient);
		return Action:0;
	}
	if (AwardID == 81)
	{
		Format(AwardSQL, 128, "award_tankkillnodeaths = award_tankkillnodeaths + 1");
	}
	else
	{
		if (AwardID == 86)
		{
			Format(AwardSQL, 128, "award_left4dead = award_left4dead + 1");
		}
		if (AwardID == 95)
		{
			Format(AwardSQL, 128, "award_letinsafehouse = award_letinsafehouse + 1");
		}
		return Action:0;
	}
	decl String:query[1024];
	Format(query, 1024, "UPDATE players SET %s WHERE steamid = '%s'", AwardSQL, UserID);
	SendSQLUpdate(query);
	return Action:0;
}

GivePills(Giver, Recipient, PillsID)
{
	if (0 > PillsID)
	{
		PillsID = GetPlayerWeaponSlot(Recipient, 4);
	}
	new var1;
	if (PillsID < 0 || Pills[PillsID] == 1)
	{
		return 0;
	}
	Pills[PillsID] = 1;
	if (IsFakeClient(Giver))
	{
		return 0;
	}
	decl String:GiverID[64];
	GetClientAuthId(Giver, AuthIdType:1, GiverID, 64, true);
	decl String:query2[1024];
	Format(query2, 1024, "UPDATE players SET award_pills = award_pills + 1 WHERE steamid = '%s'", GiverID);
	SendSQLUpdate(query2);
	return 0;
}

GiveAdrenaline(Giver, Recipient, AdrenalineID)
{
	if (0 > AdrenalineID)
	{
		AdrenalineID = GetPlayerWeaponSlot(Recipient, 4);
	}
	new var1;
	if (AdrenalineID < 0 || Adrenaline[AdrenalineID] == 1)
	{
		return 0;
	}
	Adrenaline[AdrenalineID] = 1;
	if (IsFakeClient(Giver))
	{
		return 0;
	}
	decl String:GiverID[64];
	GetClientAuthId(Giver, AuthIdType:1, GiverID, 64, true);
	decl String:query2[1024];
	Format(query2, 1024, "UPDATE players SET award_adrenaline = award_adrenaline + 1 WHERE steamid = '%s'", GiverID);
	SendSQLUpdate(query2);
	return 0;
}

PlayerIncap(Attacker, Victim)
{
	if (0 >= Victim)
	{
		return 0;
	}
	if (Attacker == Victim)
	{
		return 0;
	}
	new var1;
	if (!Attacker || IsFakeClient(Attacker))
	{
		return 0;
	}
	new AttackerTeam = GetClientTeam(Attacker);
	new VictimTeam = GetClientTeam(Victim);
	new var2;
	if (AttackerTeam == 2 && VictimTeam == 2)
	{
		decl String:AttackerID[64];
		GetClientAuthId(Attacker, AuthIdType:1, AttackerID, 64, true);
		decl String:query2[1024];
		Format(query2, 1024, "UPDATE players SET award_fincap = award_fincap + 1 WHERE steamid = '%s'", AttackerID);
		SendSQLUpdate(query2);
	}
	return 0;
}

public PunishTeamkiller(client)
{
	if (GetUserFlagBits(client))
	{
		return 0;
	}
	new BonusTK;
	new var1;
	if (ClientRank[client] > 1000 || ClientRank[client])
	{
		BonusTK = -45;
	}
	else
	{
		new var2;
		if (ClientRank[client] > 100 && ClientRank[client] < 1001)
		{
			BonusTK = 0;
		}
		new var3;
		if (ClientRank[client] > 0 && ClientRank[client] < 101)
		{
			BonusTK = 30;
		}
	}
	if (BonusTK + TKblockmin < TKblockDamage[client])
	{
		if (BonusTK + TKblockmax < TKblockDamage[client])
		{
			if (BonusTK + TKblockmax > TKblockPunishment[client])
			{
				new var4;
				if (IsValidEntity(client) && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
				{
					decl String:steamId[64];
					GetClientAuthId(client, AuthIdType:1, steamId, 64, true);
					PrintToChatAll("%t", "%N (%s) has been banned [%i TK]", client, steamId, TKblockDamage[client]);
					TKblockPunishment[client] = TKblockDamage[client];
					if (ClientPoints[client] <= -1000)
					{
						if (GetTime({0,0}) <= LastVotebanTIME[client][1])
						{
							ServerCommand("sm_ban \"#%d\" \"%i\" \"%s\"", GetClientUserId(client), 40320, "Team Killer");
						}
						else
						{
							ServerCommand("sm_ban \"#%d\" \"%i\" \"%s\"", GetClientUserId(client), 20160, "Team Killer");
						}
					}
					else
					{
						new var5;
						if (ClientPoints[client] > -1000 && ClientPoints[client] <= -300)
						{
							if (GetTime({0,0}) <= LastVotebanTIME[client][1])
							{
								ServerCommand("sm_ban \"#%d\" \"%i\" \"%s\"", GetClientUserId(client), 40320, "Team Killer");
							}
							else
							{
								ServerCommand("sm_ban \"#%d\" \"%i\" \"%s\"", GetClientUserId(client), 10080, "Team Killer");
							}
						}
						new var6;
						if (ClientPoints[client] > -300 && ClientPoints[client] <= 0)
						{
							ServerCommand("sm_ban \"#%d\" \"%i\" \"%s\"", GetClientUserId(client), 4320, "Team Killer");
						}
						if (0 < ClientPoints[client])
						{
							ServerCommand("sm_ban \"#%d\" \"%i\" \"%s\"", GetClientUserId(client), 720, "Team Killer");
						}
					}
					ServerCommand("sm_cancelvote");
				}
			}
		}
		if (BonusTK + TKblockmin < TKblockDamage[client] - TKblockPunishment[client])
		{
			new var7;
			if (IsValidEntity(client) && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
			{
				TKblockPunishment[client] = TKblockDamage[client];
				CPrintToChatAll("%t {blue}%N %t", "Auto Voteban", client, "%i TK. (Rank: %d Points: %d)", TKblockDamage[client], ClientRank[client], ClientPoints[client]);
				ServerCommand("sm_voteban #%d TeamKiller", GetClientUserId(client));
				LastVotebanTIME[client] = GetTime({0,0});
			}
		}
	}
	return 0;
}

public Action:cmd_ShowRank(client, args)
{
	if (!client)
	{
		return Action:3;
	}
	if (!IsClientInGame(client))
	{
		return Action:3;
	}
	if (StatsDisabled())
	{
		PrintToChat(client, "%t", "Failed to connect to database");
		return Action:3;
	}
	if (IsFakeClient(client))
	{
		return Action:3;
	}
	KnowRankPoints(client);
	KnowRankKills(client);
	KnowRankPlaytime(client);
	CreateTimer(1.2, TimerDisplayRank, client, 0);
	return Action:3;
}

public Action:TimerDisplayRank(Handle:timer, any:client)
{
	if (!client)
	{
		return Action:4;
	}
	if (!IsClientInGame(client))
	{
		return Action:4;
	}
	if (IsFakeClient(client))
	{
		return Action:4;
	}
	new Handle:RankPanel = CreatePanel(Handle:0);
	new String:Value[64];
	new String:URL[64];
	GetConVarString(cvar_SiteURL, URL, 64);
	new theTime = ClientPlaytime[client];
	new days = theTime / 60 / 60 / 24;
	new hours = theTime / 60 / 60 % 24;
	new minutes = theTime / 60 % 60;
	new String:playtime[128];
	new var1;
	if (hours && days)
	{
		Format(playtime, 128, "%d min", minutes);
	}
	else
	{
		if (days)
		{
			Format(playtime, 128, "%d day %d hour %d min", days, hours, minutes);
		}
		Format(playtime, 128, "%d hour %d min", hours, minutes);
	}
	new BonusTK;
	new var2;
	if (ClientRank[client] > 1000 || ClientRank[client])
	{
		BonusTK = -45;
	}
	else
	{
		new var3;
		if (ClientRank[client] > 100 && ClientRank[client] < 1001)
		{
			BonusTK = 0;
		}
		new var4;
		if (ClientRank[client] > 0 && ClientRank[client] < 101)
		{
			BonusTK = 30;
		}
	}
	new TKblockminReal = BonusTK + TKblockmin;
	new TKblockmaxReal = BonusTK + TKblockmax;
	Format(Value, 64, "Ranking of %N", client);
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "========================");
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "Rank: %i of %i", ClientRank[client], RankTotal);
	DrawPanelText(RankPanel, Value);
	if (NewPoints[client])
	{
		if (0 < NewPoints[client])
		{
			if (0 < GetConVarInt(hm_count_fails))
			{
				Format(Value, 64, "Points: %i + %i(%i)", ClientPoints[client], NewPoints[client], CalculatePoints(NewPoints[client]));
			}
			else
			{
				Format(Value, 64, "Points: %i + %i", ClientPoints[client], NewPoints[client]);
			}
		}
		else
		{
			Format(Value, 64, "Points: %i %i", ClientPoints[client], NewPoints[client]);
		}
	}
	else
	{
		Format(Value, 64, "Points: %i", ClientPoints[client]);
	}
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "Killed Bosses: %i", ClientKills[client]);
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "Playtime: %s", playtime);
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "TK: %i", TKblockDamage[client]);
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "Voteban TK: %i", TKblockminReal);
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "Ban TK: %i", TKblockmaxReal);
	DrawPanelText(RankPanel, Value);
	if (!StrEqual(URL, "", false))
	{
		Format(Value, 64, "For full stats visit:\nhttp://%s", URL);
		DrawPanelText(RankPanel, Value);
		Format(Value, 64, "========================");
		DrawPanelText(RankPanel, Value);
		DrawPanelItem(RankPanel, "Show full stats", 0);
	}
	DrawPanelItem(RankPanel, "Next Rank", 0);
	DrawPanelItem(RankPanel, "Top 20 Players", 0);
	DrawPanelItem(RankPanel, "Show Player Ranks", 0);
	DrawPanelItem(RankPanel, "Close", 0);
	SendPanelToClient(RankPanel, client, RankPanelHandlerOption, 30);
	CloseHandle(RankPanel);
	CreateTimer(1.0, TimedGrantPlayerColor, client, 0);
	return Action:4;
}

public RankPanelHandlerOption(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		new String:URL[64];
		GetConVarString(cvar_SiteURL, URL, 64);
		if (!StrEqual(URL, "", false))
		{
			if (param2 == 1)
			{
				FakeClientCommand(param1, "sm_browse %s", URL);
			}
			else
			{
				if (param2 == 2)
				{
					cmd_NextRank(param1, 0);
				}
				if (param2 == 3)
				{
					cmd_ShowTop20(param1, 0);
				}
				if (param2 == 4)
				{
					DisplayRankTargetMenu(param1);
				}
			}
		}
		else
		{
			if (param2 == 1)
			{
				cmd_NextRank(param1, 0);
			}
			if (param2 == 2)
			{
				cmd_ShowTop20(param1, 0);
			}
			if (param2 == 3)
			{
				DisplayRankTargetMenu(param1);
			}
		}
	}
	return 0;
}

DisplayRankTargetMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Rank, MenuAction:28);
	decl String:title[100];
	new String:playername[128];
	new String:identifier[64];
	decl String:DisplayName[64];
	Format(title, 100, "%s", "Player Ranks:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	new i = 1;
	while (GetMaxClients() > i)
	{
		new var1;
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientName(i, playername, 128);
			Format(DisplayName, 64, "%s (%i points)", playername, ClientPoints[i]);
			Format(identifier, 64, "%i", i);
			AddMenuItem(menu, identifier, DisplayName, 0);
		}
		i++;
	}
	DisplayMenu(menu, client, 0);
	return 0;
}

public MenuHandler_Rank(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction:16)
	{
		CloseHandle(menu);
	}
	else
	{
		if (action == MenuAction:4)
		{
			decl String:info[32];
			decl String:name[32];
			new target;
			GetMenuItem(menu, param2, info, 32, 0, name, 32);
			target = StringToInt(info, 10);
			if (target)
			{
				KnowRankKills(target);
				KnowRankPlaytime(target);
				DisplayRank(target, param1);
			}
			else
			{
				PrintToChat(param1, "[SM] %s", "Player no longer available");
			}
		}
	}
	return 0;
}

DisplayRank(target, sender)
{
	new Handle:RankPanel = CreatePanel(Handle:0);
	new String:Value[64];
	new String:URL[64];
	GetConVarString(cvar_SiteURL, URL, 64);
	new theTime = ClientPlaytime[target];
	new days = theTime / 60 / 60 / 24;
	new hours = theTime / 60 / 60 % 24;
	new minutes = theTime / 60 % 60;
	new String:playtime[128];
	new var1;
	if (hours && days)
	{
		Format(playtime, 128, "%d min", minutes);
	}
	else
	{
		if (days)
		{
			Format(playtime, 128, "%d day %d hour %d min", days, hours, minutes);
		}
		Format(playtime, 128, "%d hour %d min", hours, minutes);
	}
	new BonusTK;
	new var2;
	if (ClientRank[target] > 1000 || ClientRank[target])
	{
		BonusTK = -45;
	}
	else
	{
		new var3;
		if (ClientRank[target] > 100 && ClientRank[target] < 1001)
		{
			BonusTK = 0;
		}
		new var4;
		if (ClientRank[target] > 0 && ClientRank[target] < 101)
		{
			BonusTK = 30;
		}
	}
	new TKblockminReal = BonusTK + TKblockmin;
	new TKblockmaxReal = BonusTK + TKblockmax;
	Format(Value, 64, "Ranking of %N", target);
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "========================");
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "Rank: %i of %i", ClientRank[target], RankTotal);
	DrawPanelText(RankPanel, Value);
	if (NewPoints[target])
	{
		if (0 < NewPoints[target])
		{
			if (0 < GetConVarInt(hm_count_fails))
			{
				Format(Value, 64, "Points: %i + %i(%i)", ClientPoints[target], NewPoints[target], CalculatePoints(NewPoints[target]));
			}
			else
			{
				Format(Value, 64, "Points: %i + %i", ClientPoints[target], NewPoints[target]);
			}
		}
		else
		{
			Format(Value, 64, "Points: %i %i", ClientPoints[target], NewPoints[target]);
		}
	}
	else
	{
		Format(Value, 64, "Points: %i", ClientPoints[target]);
	}
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "Killed Bosses: %i", ClientKills[target]);
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "Playtime: %s", playtime);
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "TK: %i", TKblockDamage[target]);
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "Voteban TK: %i", TKblockminReal);
	DrawPanelText(RankPanel, Value);
	Format(Value, 64, "Ban TK: %i", TKblockmaxReal);
	DrawPanelText(RankPanel, Value);
	if (!StrEqual(URL, "", false))
	{
		Format(Value, 64, "For full stats visit:\nhttp://%s", URL);
		DrawPanelText(RankPanel, Value);
		Format(Value, 64, "========================");
		DrawPanelText(RankPanel, Value);
		DrawPanelItem(RankPanel, "Show full stats", 0);
	}
	DrawPanelItem(RankPanel, "Next Rank", 0);
	DrawPanelItem(RankPanel, "Top 20 Players", 0);
	DrawPanelItem(RankPanel, "Show Player Ranks", 0);
	DrawPanelItem(RankPanel, "Close", 0);
	SendPanelToClient(RankPanel, sender, RankPanelHandlerOption, 30);
	CloseHandle(RankPanel);
	return 0;
}

public Action:cmd_ShowTop10(client, args)
{
	if (!client)
	{
		return Action:3;
	}
	if (!IsClientInGame(client))
	{
		return Action:3;
	}
	if (StatsDisabled())
	{
		PrintToChat(client, "%t", "Failed to connect to database");
		return Action:3;
	}
	if (IsFakeClient(client))
	{
		return Action:3;
	}
	decl String:query[256];
	Format(query, 256, "SELECT name, points FROM players ORDER BY points DESC LIMIT 10");
	SQL_TQuery(db, DisplayTop10, query, client, DBPriority:1);
	return Action:3;
}

public Action:cmd_ShowTop15(client, args)
{
	if (!client)
	{
		return Action:3;
	}
	if (!IsClientInGame(client))
	{
		return Action:3;
	}
	if (StatsDisabled())
	{
		PrintToChat(client, "%t", "Failed to connect to database");
		return Action:3;
	}
	if (IsFakeClient(client))
	{
		return Action:3;
	}
	decl String:query[256];
	Format(query, 256, "SELECT name, points FROM players ORDER BY points DESC LIMIT 15");
	SQL_TQuery(db, DisplayTop15, query, client, DBPriority:1);
	return Action:3;
}

public Action:cmd_ShowTop20(client, args)
{
	if (!client)
	{
		return Action:3;
	}
	if (!IsClientInGame(client))
	{
		return Action:3;
	}
	if (StatsDisabled())
	{
		PrintToChat(client, "%t", "Failed to connect to database");
		return Action:3;
	}
	if (IsFakeClient(client))
	{
		return Action:3;
	}
	decl String:query[256];
	Format(query, 256, "SELECT name, points FROM players ORDER BY points DESC LIMIT 20");
	SQL_TQuery(db, DisplayTop20, query, client, DBPriority:1);
	return Action:3;
}

public DisplayTop10(Handle:owner, Handle:hndl, String:error[], any:client)
{
	new var1;
	if (!client || hndl)
	{
		return 0;
	}
	new String:Name[32];
	new Handle:Top10Panel = CreatePanel(Handle:0);
	new String:Value[64];
	new points;
	new number;
	SetPanelTitle(Top10Panel, "Top 10 Players", false);
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, 32, 0);
		points = SQL_FetchInt(hndl, 1, 0);
		ReplaceString(Name, 32, "&lt;", "<", true);
		ReplaceString(Name, 32, "&gt;", ">", true);
		ReplaceString(Name, 32, "&#37;", "%", true);
		ReplaceString(Name, 32, "&#61;", "=", true);
		ReplaceString(Name, 32, "&#42;", "*", true);
		number++;
		Format(Value, 64, "%i_ %s  %i Points", number, Name, points);
		DrawPanelText(Top10Panel, Value);
	}
	DrawPanelItem(Top10Panel, "Close", 0);
	SendPanelToClient(Top10Panel, client, RankPanelHandler, 30);
	CloseHandle(Top10Panel);
	return 0;
}

public DisplayTop15(Handle:owner, Handle:hndl, String:error[], any:client)
{
	new var1;
	if (!client || hndl)
	{
		return 0;
	}
	new String:Name[32];
	new Handle:Top15Panel = CreatePanel(Handle:0);
	new String:Value[64];
	new points;
	new number;
	SetPanelTitle(Top15Panel, "Top 15 Players", false);
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, 32, 0);
		points = SQL_FetchInt(hndl, 1, 0);
		ReplaceString(Name, 32, "&lt;", "<", true);
		ReplaceString(Name, 32, "&gt;", ">", true);
		ReplaceString(Name, 32, "&#37;", "%", true);
		ReplaceString(Name, 32, "&#61;", "=", true);
		ReplaceString(Name, 32, "&#42;", "*", true);
		number++;
		Format(Value, 64, "%i_ %s  %i Points", number, Name, points);
		DrawPanelText(Top15Panel, Value);
	}
	DrawPanelItem(Top15Panel, "Close", 0);
	SendPanelToClient(Top15Panel, client, RankPanelHandler, 30);
	CloseHandle(Top15Panel);
	return 0;
}

public DisplayTop20(Handle:owner, Handle:hndl, String:error[], any:client)
{
	new var1;
	if (!client || hndl)
	{
		return 0;
	}
	new String:Name[32];
	new Handle:Top20Panel = CreatePanel(Handle:0);
	new String:Value[64];
	new points;
	new number;
	SetPanelTitle(Top20Panel, "Top 20 Players", false);
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, 32, 0);
		points = SQL_FetchInt(hndl, 1, 0);
		ReplaceString(Name, 32, "&lt;", "<", true);
		ReplaceString(Name, 32, "&gt;", ">", true);
		ReplaceString(Name, 32, "&#37;", "%", true);
		ReplaceString(Name, 32, "&#61;", "=", true);
		ReplaceString(Name, 32, "&#42;", "*", true);
		number++;
		Format(Value, 64, "%i_ %s %i", number, Name, points);
		DrawPanelText(Top20Panel, Value);
	}
	DrawPanelItem(Top20Panel, "Close", 0);
	SendPanelToClient(Top20Panel, client, RankPanelHandler, 30);
	CloseHandle(Top20Panel);
	return 0;
}

public Action:cmd_NextRank(client, args)
{
	if (!client)
	{
		return Action:3;
	}
	if (!IsClientInGame(client))
	{
		return Action:3;
	}
	if (StatsDisabled())
	{
		PrintToChat(client, "%t", "Failed to connect to database");
		return Action:3;
	}
	if (IsFakeClient(client))
	{
		return Action:3;
	}
	KnowRankPoints(client);
	CreateTimer(1.2, TimerDisplayNextRank, client, 0);
	return Action:3;
}

public Action:TimerDisplayNextRank(Handle:timer, any:client)
{
	if (!client)
	{
		return Action:4;
	}
	if (!IsClientInGame(client))
	{
		return Action:4;
	}
	if (IsFakeClient(client))
	{
		return Action:4;
	}
	if (StatsDisabled())
	{
		return Action:4;
	}
	decl String:steamId[64];
	GetClientAuthId(client, AuthIdType:1, steamId, 64, true);
	decl String:query[1024];
	Format(query, 1024, "SELECT points FROM players WHERE points > %i AND steamid <> '%s' ORDER BY points LIMIT 1", ClientPoints[client], steamId);
	SQL_TQuery(db, DisplayNextRank, query, client, DBPriority:1);
	return Action:4;
}

public Action:TimerDisplayFullNextRank(Handle:timer, any:client)
{
	if (!client)
	{
		return Action:4;
	}
	if (!IsClientInGame(client))
	{
		return Action:4;
	}
	if (IsFakeClient(client))
	{
		return Action:4;
	}
	if (StatsDisabled())
	{
		return Action:4;
	}
	decl String:steamId[64];
	GetClientAuthId(client, AuthIdType:1, steamId, 64, true);
	decl String:query[2048];
	decl String:query1[1024];
	decl String:query2[256];
	decl String:query3[1024];
	Format(query1, 1024, "SELECT name,points FROM players WHERE points > %i AND steamid <> '%s' ORDER BY points ASC LIMIT 3", ClientPoints[client], steamId);
	Format(query2, 256, "SELECT name,points FROM players WHERE steamid = '%s'", steamId);
	Format(query3, 1024, "SELECT name,points FROM players WHERE points < %i AND steamid <> '%s' ORDER BY points DESC LIMIT 3", ClientPoints[client], steamId);
	Format(query, 2048, "(%s) UNION (%s) UNION (%s) ORDER BY points DESC", query1, query2, query3);
	SQL_TQuery(db, DisplayFullNextRank, query, client, DBPriority:1);
	return Action:4;
}

public DisplayNextRank(Handle:owner, Handle:hndl, String:error[], any:client)
{
	new var1;
	if (!client || hndl)
	{
		return 0;
	}
	new Points;
	while (SQL_FetchRow(hndl))
	{
		Points = SQL_FetchInt(hndl, 0, 0);
	}
	new Handle:NextRankPanel = CreatePanel(Handle:0);
	new String:Value[64];
	SetPanelTitle(NextRankPanel, "Next Rank:", false);
	if (ClientRank[client] == 1)
	{
		Format(Value, 64, "You are 1st");
		DrawPanelText(NextRankPanel, Value);
	}
	else
	{
		Format(Value, 64, "Points required: %i", Points - ClientPoints[client]);
		DrawPanelText(NextRankPanel, Value);
	}
	DrawPanelItem(NextRankPanel, "More...", 0);
	DrawPanelItem(NextRankPanel, "Close", 0);
	SendPanelToClient(NextRankPanel, client, NextRankPanelHandler, 30);
	CloseHandle(NextRankPanel);
	return 0;
}

public DisplayFullNextRank(Handle:owner, Handle:hndl, String:error[], any:client)
{
	new var1;
	if (!client || hndl)
	{
		return 0;
	}
	new String:Name[32];
	new Points;
	new Handle:FullNextRankPanel = CreatePanel(Handle:0);
	new String:Value[64];
	SetPanelTitle(FullNextRankPanel, "Next Rank List:", false);
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, 32, 0);
		Points = SQL_FetchInt(hndl, 1, 0);
		ReplaceString(Name, 32, "&lt;", "<", true);
		ReplaceString(Name, 32, "&gt;", ">", true);
		ReplaceString(Name, 32, "&#37;", "%", true);
		ReplaceString(Name, 32, "&#61;", "=", true);
		ReplaceString(Name, 32, "&#42;", "*", true);
		Format(Value, 64, "%i points: %s", Points, Name);
		DrawPanelText(FullNextRankPanel, Value);
	}
	DrawPanelItem(FullNextRankPanel, "Close", 0);
	SendPanelToClient(FullNextRankPanel, client, RankPanelHandler, 30);
	CloseHandle(FullNextRankPanel);
	return 0;
}

public RankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	return 0;
}

public NextRankPanelHandler(Handle:panel, MenuAction:action, client, option)
{
	if (action != MenuAction:4)
	{
		return 0;
	}
	if (option == 1)
	{
		CreateTimer(1.2, TimerDisplayFullNextRank, client, 0);
		return 0;
	}
	return 0;
}

GetRealtyClientCount(bool:inGameOnly)
{
	new clients;
	new i = 1;
	while (GetMaxClients() >= i)
	{
		new var1;
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			clients++;
		}
		i++;
	}
	return clients;
}

StatsDisabled()
{
	if (db)
	{
		return 0;
	}
	return 1;
}

public Action:cmd_ShowRankTarget(client, args)
{
	new Target = GetClientAimTarget(client, false);
	if (!IsRealClient(Target))
	{
		return Action:0;
	}
	new var1;
	if (IsClientConnected(Target) && IsClientInGame(Target) && GetClientTeam(Target) == 2)
	{
		CPrintToChat(client, "%t {blue}%N %t", "Player", Target, "Rank: %d Points: %d Map points: %d", ClientRank[Target], ClientPoints[Target], NewPoints[Target]);
	}
	return Action:0;
}

public Action:Command_totalPoints_to_all(client, args)
{
	PrintTotalPointsToAll(client);
	return Action:0;
}

PrintTotalPointsToAll(client)
{
	CPrintToChatAll("%t {blue}%N %t", "Player", client, "Rank: %d Points: %d", ClientRank[client], ClientPoints[client]);
	return 0;
}

public Action:Command_Points(client, args)
{
	PrintPoints(client);
	return Action:0;
}

PrintPoints(client)
{
	PrintToChat(client, "%t", "Your points: %d , Your map points: %d", ClientPoints[client], NewPoints[client]);
	return 0;
}

public Action:Command_Playtime(client, args)
{
	PrintPlaytime(client);
	return Action:0;
}

PrintPlaytime(client)
{
	PrintToChat(client, "%t", "Your playtime on this map: %d", Playtime[client]);
	return 0;
}

public Action:Command_MapTop(client, args)
{
	PrintMapTop(client);
	return Action:0;
}

PrintMapTop(client)
{
	new var1 = 0;
	new var2 = 0;
	new String:NameBuffer[32] = "";
	new String:WorseNameBuffer[32] = "";
	new count;
	new totalpoints;
	new j;
	new worse;
	j = -100000;
	worse = 100000;
	count = 0;
	totalpoints = 0;
	new topplayerrank;
	new worseplayerrank;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsRealClient(i))
		{
			new String:clientname[32];
			GetClientName(i, clientname, 32);
			var1[i] = i;
			var1[i][1] = NewPoints[i];
			if (NewPoints[i] > j)
			{
				j = NewPoints[i];
				topplayerrank = ClientRank[i];
			}
			if (NewPoints[i] < worse)
			{
				worse = NewPoints[i];
				worseplayerrank = ClientRank[i];
			}
			count++;
			totalpoints = NewPoints[i][totalpoints];
		}
		i++;
	}
	if (0 < GetConVarInt(hm_count_fails))
	{
		PrintToChat(client, "%t", "Map total points: %d (%d)", totalpoints, CalculatePoints(totalpoints));
		CPrintToChat(client, "%t {blue}%s %t", "Map best player:", NameBuffer, "(rank: %d; points: %d (%d))", topplayerrank, j, CalculatePoints(j));
	}
	else
	{
		PrintToChat(client, "%t", "Map total points: %d", totalpoints);
		CPrintToChat(client, "%t {blue}%s %t", "Map best player:", NameBuffer, "(rank: %d; points: %d)", topplayerrank, j);
	}
	if (0 > worse)
	{
		CPrintToChat(client, "%t {blue}%s %t", "Map worst player:", WorseNameBuffer, "(rank: %d; points: %d)", worseplayerrank, worse);
	}
	if (0 < GetConVarInt(hm_count_fails))
	{
		if (round_end_repeats)
		{
			if (!IsPrint)
			{
				IsPrint = true;
				new prct = 100 - round_end_repeats * 10;
				PrintToChatAll("%t", "It took %d attempts to finish this map!", round_end_repeats);
				PrintToChatAll("%t", "All players will receive %d%%%% of their points earned for this map.", prct);
			}
		}
		else
		{
			if (!IsPrint)
			{
				IsPrint = true;
				PrintToChatAll("%t", "The map was passed on the first try!");
				PrintToChatAll("%t", "All players will receive 100%%%% of their points earned for this map.");
			}
		}
		PrintToChat(client, "%t", "Your map points: %d (%d)", NewPoints[client], CalculatePoints(NewPoints[client]));
	}
	else
	{
		PrintToChat(client, "%t", "Your map points: %d", NewPoints[client]);
	}
	return 0;
}

CalculatePoints(points)
{
	if (0 < GetConVarInt(hm_count_fails))
	{
		points = RoundToZero(1065353216 * points * 100 - round_end_repeats * 10 / 100);
	}
	return points;
}

GrantPlayerColor(client)
{
	if (GetConVarInt(hm_stats_colors) < 1)
	{
		return 0;
	}
	if (!IsValidClient(client))
	{
		return 0;
	}
	new var1;
	if (!IsClientConnected(client) || !IsClientInGame(client) || GetClientTeam(client) == 2)
	{
		return 0;
	}
	if (!IsPlayerAlive(client))
	{
		return 0;
	}
	if (IsFakeClient(client))
	{
		if (GetConVarInt(hm_stats_bot_colors) < 1)
		{
			SetEntityRenderColor(client, 255, 255, 255, 255);
		}
		else
		{
			SetEntityRenderColor(client, 175, 175, 175, 255);
		}
		return 0;
	}
	if (GetConVarInt(hm_stats_colors) == 1)
	{
		new var2;
		if (ClientRank[client] > 0 && ClientRank[client] < 51)
		{
			if (ClientRank[client] < 4)
			{
				SetEntityRenderColor(client, 160, 32, 240, 255);
			}
			else
			{
				if (ClientRank[client] < 11)
				{
					SetEntityRenderColor(client, 255, 0, 0, 255);
				}
				if (ClientRank[client] < 21)
				{
					SetEntityRenderColor(client, 0, 0, 255, 255);
				}
				if (ClientRank[client] < 31)
				{
					SetEntityRenderColor(client, 255, 255, 0, 255);
				}
				if (ClientRank[client] < 41)
				{
					SetEntityRenderColor(client, 0, 255, 0, 255);
				}
				SetEntityRenderColor(client, 173, 255, 47, 255);
			}
		}
		else
		{
			SetEntityRenderColor(client, 255, 255, 255, 255);
		}
		return 0;
	}
	if (GetConVarInt(hm_stats_colors) == 2)
	{
		if (ClientPoints[client] > 5000)
		{
			new var3;
			if (ClientPoints[client] > 5000 && ClientPoints[client] < 10001)
			{
				SetEntityRenderColor(client, 173, 255, 47, 255);
			}
			else
			{
				new var4;
				if (ClientPoints[client] > 10000 && ClientPoints[client] < 20001)
				{
					SetEntityRenderColor(client, 255, 255, 0, 255);
				}
				new var5;
				if (ClientPoints[client] > 20000 && ClientPoints[client] < 40001)
				{
					SetEntityRenderColor(client, 0, 0, 255, 255);
				}
				new var6;
				if (ClientPoints[client] > 40000 && ClientPoints[client] < 80001)
				{
					SetEntityRenderColor(client, 0, 139, 0, 255);
				}
				new var7;
				if (ClientPoints[client] > 80000 && ClientPoints[client] < 160001)
				{
					SetEntityRenderColor(client, 102, 25, 140, 255);
				}
				new var8;
				if (ClientPoints[client] > 160000 && ClientPoints[client] < 320001)
				{
					SetEntityRenderColor(client, 255, 104, 240, 255);
				}
				new var9;
				if (ClientPoints[client] > 320000 && ClientPoints[client] < 640001)
				{
					SetEntityRenderColor(client, 255, 0, 0, 255);
				}
				if (ClientPoints[client] > 640000)
				{
					SetEntityRenderColor(client, 255, 97, 3, 255);
				}
			}
		}
		else
		{
			SetEntityRenderColor(client, 255, 255, 255, 255);
		}
		return 0;
	}
	SetEntityRenderColor(client, 255, 255, 255, 255);
	return 0;
}

public Action:Event_PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	ADPlayerSpawn(event);
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	CreateTimer(6.0, TimedGrantPlayerColor, client, 0);
	return Action:0;
}

public L4D2_Supercoop_PlayerOnUnfreezed(client)
{
	GrantPlayerColor(client);
	return 0;
}

public Action:TimedGrantPlayerColor(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		return Action:0;
	}
	if (GetClientHealth(client) < 1)
	{
		return Action:0;
	}
	GrantPlayerColor(client);
	return Action:0;
}

IsRealClient(client)
{
	if (!IsValidClient(client))
	{
		return 0;
	}
	new var1;
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (IsClientInGame(client))
		{
			if (!IsFakeClient(client))
			{
				return 1;
			}
		}
	}
	return 0;
}

IsValidClient(client)
{
	if (!IsValidEntity(client))
	{
		return 0;
	}
	new var1;
	if (client < 1 || client > MaxClients)
	{
		return 0;
	}
	return 1;
}

public GetClientZC(client)
{
	new var1;
	if (!IsValidEntity(client) || !IsValidEdict(client))
	{
		return 0;
	}
	return GetEntProp(client, PropType:0, "m_zombieClass", 4, 0);
}

ADPlayerTeam()
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			count++;
		}
		i++;
	}
	if (count != playerscount)
	{
		playerscount = count;
		if (IsTimeAutodifficulty)
		{
			Autodifficulty();
		}
	}
	updateptystatslayers();
	return 0;
}

public Action:Event_PlayerTeam(Handle:event, String:name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "disconnect", false))
	{
		return Action:0;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	new var1;
	if (!client || !IsClientInGame(client))
	{
		return Action:0;
	}
	ADPlayerTeam();
	return Action:0;
}

Float:Calculate_Rank_Mod()
{
	new Float:local_result = 1.0;
	switch (GetConVarInt(l4d2_rankmod_mode))
	{
		case 0, 1, 2:
		{
			if (RankTotal < cvar_maxplayers)
			{
				return GetConVarFloat(SDifficultyMultiplier);
			}
			new Float:sum_low = 0.0;
			new Float:sum_high = 0.0;
			new i = 1;
			while (i <= cvar_maxplayers)
			{
				sum_low += Sum_Function(1065353216 * i);
				sum_high += Sum_Function(1065353216 * RankTotal + 1.0 - 1065353216 * i);
				i++;
			}
			sum_low *= 1065353216 / cvar_maxplayers * 1.0;
			sum_high *= 1065353216 / cvar_maxplayers * 1.0;
			new Float:sum_current = 0.0;
			new Float:current_player_rank = 0.0;
			new Float:current_players_count = 0.0;
			new i = 1;
			while (i <= MaxClients)
			{
				if (IsClientInGame(i))
				{
					if (!IsFakeClient(i))
					{
						if (GetClientTeam(i) == 2)
						{
							current_players_count += 1.0;
							current_player_rank = 1.0 * ClientRank[i];
							if (current_player_rank < 1.0)
							{
								current_player_rank = 0.5 * RankTotal;
							}
							sum_current += Sum_Function(1065353216 + RankTotal - current_player_rank);
						}
					}
				}
				i++;
			}
			if (current_players_count < 1.4E-45)
			{
				return local_result;
			}
			sum_current *= 1.0 / current_players_count * 1.0;
			new Float:k = GetConVarFloat(l4d2_rankmod_max) - GetConVarFloat(l4d2_rankmod_min) / sum_high - sum_low;
			new Float:p = GetConVarFloat(l4d2_rankmod_max) - k * sum_high;
			local_result = k * sum_current + p;
			if (local_result < GetConVarFloat(l4d2_rankmod_min))
			{
				local_result = GetConVarFloat(l4d2_rankmod_min);
			}
			else
			{
				if (local_result > GetConVarFloat(l4d2_rankmod_max))
				{
					local_result = GetConVarFloat(l4d2_rankmod_max);
				}
			}
			if (GetConVarInt(l4d2_rankmod_mode) == 1)
			{
				local_result += GetConVarFloat(SDifficultyMultiplier);
			}
			if (GetConVarInt(l4d2_rankmod_mode) == 2)
			{
				local_result *= GetConVarFloat(SDifficultyMultiplier);
			}
			return local_result;
		}
		case 3, 4, 5:
		{
			if (RankTotal < 3600)
			{
				return GetConVarFloat(SDifficultyMultiplier);
			}
			rank_sum = 0.0;
			new players_count;
			new i = 1;
			while (i <= MaxClients)
			{
				if (IsClientInGame(i))
				{
					if (!IsFakeClient(i))
					{
						if (GetClientTeam(i) == 2)
						{
							if (ClientRank[i])
							{
								if (ClientRank[i] <= 10)
								{
									rank_sum = rank_sum + 5.0;
								}
								if (ClientRank[i] <= 25)
								{
									rank_sum = rank_sum + 4.4;
								}
								if (ClientRank[i] <= 50)
								{
									rank_sum = rank_sum + 3.8;
								}
								if (ClientRank[i] <= 100)
								{
									rank_sum = rank_sum + 3.2;
								}
								if (ClientRank[i] <= 200)
								{
									rank_sum = rank_sum + 2.6;
								}
								if (ClientRank[i] <= 400)
								{
									rank_sum = rank_sum + 2.0;
								}
								if (ClientRank[i] <= 800)
								{
									rank_sum = rank_sum + 1.4;
								}
								if (ClientRank[i] <= 1600)
								{
									rank_sum = rank_sum + 0.8;
								}
								if (ClientRank[i] <= 3200)
								{
									rank_sum = rank_sum + 0.2;
								}
							}
							else
							{
								rank_sum = rank_sum + 0.0;
							}
							players_count++;
						}
					}
				}
				i++;
			}
			if (players_count < 1)
			{
				players_count = 1;
			}
			local_result = rank_sum * 1.0 - 1069547520 * players_count / 1065353216 * players_count / 6.0 + 0.75;
			if (local_result < GetConVarFloat(l4d2_rankmod_min))
			{
				local_result = GetConVarFloat(l4d2_rankmod_min);
			}
			else
			{
				if (local_result > GetConVarFloat(l4d2_rankmod_max))
				{
					local_result = GetConVarFloat(l4d2_rankmod_max);
				}
			}
			if (GetConVarInt(l4d2_rankmod_mode) == 4)
			{
				local_result += GetConVarFloat(SDifficultyMultiplier);
			}
			if (GetConVarInt(l4d2_rankmod_mode) == 5)
			{
				local_result *= GetConVarFloat(SDifficultyMultiplier);
			}
			return local_result;
		}
		default:
		{
			return GetConVarFloat(SDifficultyMultiplier);
		}
	}
}

Float:Sum_Function(Float:input_value)
{
	if (0.0 == input_value)
	{
		return 0.0;
	}
	new Float:cvar_rankmod_logarithm = GetConVarFloat(l4d2_rankmod_logarithm);
	if (cvar_rankmod_logarithm >= 1.0)
	{
		return Logarithm(input_value, cvar_rankmod_logarithm);
	}
	new var1;
	if (cvar_rankmod_logarithm >= 0.0 && cvar_rankmod_logarithm < 1.0)
	{
		return input_value * cvar_rankmod_logarithm;
	}
	if (0.0 == cvar_rankmod_logarithm)
	{
		return input_value;
	}
	if (-1.0 == cvar_rankmod_logarithm)
	{
		new Float:x = Logarithm(input_value, 10.0);
		return x * x;
	}
	if (-2.0 == cvar_rankmod_logarithm)
	{
		return input_value * input_value / input_value + RankTotal * 4 / 1103626240 * RankTotal / 10.0;
	}
	if (-3.0 == cvar_rankmod_logarithm)
	{
		new Float:x = Logarithm(input_value, 10.0);
		return x * x / x * 0.001 + 1.11;
	}
	return input_value;
}

public Action:Command_RankSum(client, args)
{
	if (client)
	{
		PrintToChat(client, "\x05Rank Sum: \x04%f", rank_sum);
	}
	else
	{
		PrintToServer("Rank Sum: %f", rank_sum);
	}
	return Action:0;
}

public Action:Command_MapFinished(client, args)
{
	if (!IsMapFinished)
	{
		IsMapFinished = true;
	}
	return Action:0;
}

public Action:Command_MapNotFinished(client, args)
{
	if (IsMapFinished)
	{
		IsMapFinished = false;
	}
	return Action:0;
}

public Action:Command_Bonus(client, args)
{
	bonus = GetConVarInt(cvar_Bonus);
	return Action:0;
}

public Action:Event_MapTransition(Handle:event, String:name[], bool:dontBroadcast)
{
	ADOnMapStart();
	IsTimeAutodifficulty = false;
	PrintMapPoints();
	StopMapTiming();
	return Action:0;
}

public Action:Event_FinalWin(Handle:event, String:name[], bool:dontBroadcast)
{
	PrintMapPoints();
	StopMapTiming();
	return Action:0;
}

PrintMapPoints()
{
	IsPrint = false;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsRealClient(i))
		{
			PrintMapTop(i);
		}
		i++;
	}
	return 0;
}

public Action:Command_GivePoints(client, args)
{
	if (IsMapFinished)
	{
		return Action:3;
	}
	if (args == 2)
	{
		decl String:arg[68];
		decl String:arg2[32];
		GetCmdArg(1, arg, 65);
		GetCmdArg(2, arg2, 32);
		decl String:target_name[64];
		decl target_list[65];
		decl target_count;
		decl bool:tn_is_ml;
		new targetclient;
		new Score = StringToInt(arg2, 10);
		if (0 >= (target_count = ProcessTargetString(arg, client, target_list, 65, 0, target_name, 64, tn_is_ml)))
		{
			ReplyToTargetError(client, target_count);
			return Action:3;
		}
		ReplyToCommand(client, "Point for player: %s set to: %d", target_name, Score);
		new i;
		while (i < target_count)
		{
			targetclient = target_list[i];
			AddScore(targetclient, Score);
			i++;
		}
		return Action:3;
	}
	ReplyToCommand(client, "sm_givepoints <#userid|name> [Score]");
	return Action:3;
}

public AddScore(client, Score)
{
	if (0 < Score)
	{
		PrintToChat(client, "\x04+%i", Score);
		new var1 = NewPoints[client];
		var1 = var1[Score];
	}
	else
	{
		if (0 > Score)
		{
			PrintToChat(client, "\x05%i", Score);
			new var2 = NewPoints[client];
			var2 = var2[Score];
		}
	}
	return Score;
}

public Action:Command_RankPlayer(client, args)
{
	if (args)
	{
		if (args == 1)
		{
			decl String:arg[68];
			GetCmdArg(1, arg, 65);
			decl String:target_name[64];
			decl target_list[65];
			decl target_count;
			decl bool:tn_is_ml;
			new targetclient;
			if (0 >= (target_count = ProcessTargetString(arg, client, target_list, 65, 0, target_name, 64, tn_is_ml)))
			{
				ReplyToTargetError(client, target_count);
				return Action:3;
			}
			ReplyToCommand(client, "Вы просматриваете статистику игрока %s", target_name);
			new i;
			while (i < target_count)
			{
				targetclient = target_list[i];
				KnowRankKills(targetclient);
				KnowRankPlaytime(targetclient);
				DisplayRank(targetclient, client);
				i++;
			}
			return Action:3;
		}
		ReplyToCommand(client, "sm_rankplayer <#userid|name>");
		return Action:3;
	}
	cmd_ShowRank(client, 0);
	return Action:3;
}

public Action:Command_Refresh(client, args)
{
	ConnectDB();
	return Action:0;
}

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, PropType:0, "m_isIncapacitated", 1, 0))
	{
		return true;
	}
	return false;
}

IsMissionAllowed(String:map_name[128])
{
	new result = 1;
	new Handle:file = OpenFile(CV_FileName, "r", false, "GAME");
	if (file)
	{
		FileSeek(file, 0, 0);
		new String:CV_StoredMap[128];
		while (!IsEndOfFile(file))
		{
			if (ReadFileLine(file, CV_StoredMap, 128))
			{
				TrimString(CV_StoredMap);
				if (StrEqual(map_name, CV_StoredMap, false))
				{
					result = 0;
					CloseHandle(file);
					return result;
				}
			}
			CloseHandle(file);
			return result;
		}
		CloseHandle(file);
		return result;
	}
	return result;
}

public Action:Callvote_Handler(client, args)
{
	if (client)
	{
		decl String:voteName[32];
		decl String:initiatorName[32];
		GetClientName(client, initiatorName, 32);
		GetCmdArg(1, voteName, 32);
		if (strcmp(voteName, "Kick", false))
		{
			if (strcmp(voteName, "ReturnToLobby", false))
			{
				new var1;
				if (strcmp(voteName, "ChangeMission", false) && strcmp(voteName, "ChangeChapter", false))
				{
					decl String:map_name[128];
					GetCmdArg(2, map_name, 128);
					if (!IsMissionAllowed(map_name))
					{
						new AdminId:ClientAdminId = GetUserAdmin(client);
						new flags = GetAdminFlags(ClientAdminId, AdmAccessMode:1);
						new var2;
						if (flags & 1024 || flags & 64)
						{
							CPrintToChat(client, "%t", "Warning! This campaign is forbidden!\n\"Vote\" access granted");
							return Action:0;
						}
						PrintToChat(client, "%t", "Vote access denied [this campaign is forbidden]");
						return Action:3;
					}
					new var3;
					if (GetConVarInt(hm_blockvote_map) && GetConVarInt(hm_allowvote_map_players) >= GetRealClientCount(true))
					{
						PrintToChat(client, "%t", "Vote access granted");
						PrintToChatAll("%t", "%N started the voting", client);
						return Action:0;
					}
					if (GetConVarInt(hm_blockvote_map) == 1)
					{
						new AdminId:ClientAdminId = GetUserAdmin(client);
						new flags = GetAdminFlags(ClientAdminId, AdmAccessMode:1);
						new var4;
						if ((ClientRank[client] < GetConVarInt(hm_allowvote_mission) && ClientRank[client]) || (flags & 1 || flags & 1024 || flags & 64))
						{
							PrintToChat(client, "%t", "Vote access granted");
							PrintToChatAll("%t", "%N started the voting", client);
							return Action:0;
						}
						PrintToChat(client, "%t", "Vote access denied [%d > %d]", ClientRank[client], GetConVarInt(hm_allowvote_mission));
						return Action:3;
					}
				}
				if (strcmp(voteName, "RestartGame", false))
				{
					if (strcmp(voteName, "ChangeDifficulty", false))
					{
						return Action:0;
					}
					if (0 < GetConVarInt(hm_blockvote_difficulty))
					{
						new AdminId:ClientAdminId = GetUserAdmin(client);
						new flags = GetAdminFlags(ClientAdminId, AdmAccessMode:1);
						new var8;
						if (flags & 1024 & 128 || flags & 16384)
						{
							PrintToChat(client, "%t", "Vote access granted");
							PrintToChatAll("%t", "%N started the voting", client);
							return Action:0;
						}
						PrintToChat(client, "%t", "Vote access denied");
						return Action:3;
					}
					PrintToChat(client, "%t", "Vote access granted");
					PrintToChatAll("%t", "%N started the voting", client);
					return Action:0;
				}
				if (GetConVarInt(hm_blockvote_restart))
				{
					if (GetConVarInt(hm_blockvote_restart) == 1)
					{
						new AdminId:ClientAdminId = GetUserAdmin(client);
						new flags = GetAdminFlags(ClientAdminId, AdmAccessMode:1);
						new var7;
						if (flags & 8192 || flags & 16384 || (ClientRank[client] < 21 && ClientRank[client]))
						{
							PrintToChat(client, "%t", "Vote access granted");
							PrintToChatAll("%t", "%N started the voting", client);
							return Action:0;
						}
						PrintToChat(client, "%t", "Vote access denied");
						return Action:3;
					}
					PrintToChat(client, "%t", "Vote access denied");
					return Action:3;
				}
				PrintToChat(client, "%t", "Vote access granted");
				return Action:0;
			}
			if (0 < GetConVarInt(hm_blockvote_lobby))
			{
				PrintToChat(client, "%t", "Vote access denied");
				return Action:3;
			}
			PrintToChat(client, "%t", "Vote access granted");
			PrintToChatAll("%t", "%N started the voting", client);
			return Action:0;
		}
		return Kick_Vote_Logic(client, args);
	}
	return Action:0;
}

public Action:Kick_Vote_Logic(client, args)
{
	decl String:initiatorName[32];
	GetClientName(client, initiatorName, 32);
	decl String:arg2[12];
	GetCmdArg(2, arg2, 12);
	new target = GetClientOfUserId(StringToInt(arg2, 10));
	if (!target)
	{
		return Action:3;
	}
	if (g_votekick[client] > 3)
	{
		PrintToChat(client, "\x05Вы уже голосовали 3 раза за карту!");
		PrintToChat(client, "%t", "Vote access denied");
		return Action:3;
	}
	new AdminId:ClientAdminId = GetUserAdmin(client);
	new AdminId:TargetAdminId = GetUserAdmin(target);
	new flags = GetAdminFlags(ClientAdminId, AdmAccessMode:1);
	if (GetConVarInt(hm_blockvote_kick))
	{
		if (GetConVarInt(hm_blockvote_kick) == 1)
		{
			new var1;
			if (flags & 1024 || flags & 1 || flags & 16384 || ClientRank[client] < 51)
			{
				if (ClientRank[target] > ClientRank[client][GetConVarInt(hm_blockvote_difference)])
				{
					new flags2 = GetAdminFlags(TargetAdminId, AdmAccessMode:1);
					new var2;
					if (flags2 & 2 || flags2 & 16384)
					{
						PrintToChat(client, "%t", "Vote access denied. Target is Admin");
						return Action:3;
					}
					PrintToChat(client, "%t", "Vote access granted");
					g_votekick[client] = g_votekick[client] + 1;
				}
				PrintToChat(client, "%t", "Vote access denied");
				PrintToChat(client, "%t \x04[\x03%d \x05>=\x03 %d\x04]", "Vote access denied", ClientRank[client], ClientRank[target]);
				return Action:3;
			}
			PrintToChat(client, "%t \x04[\x03%d \x05>\x03 50\x04]", "Vote access denied", ClientRank[client]);
			return Action:3;
		}
		PrintToChatAll("%t", "%N started the voting", client);
		return Action:0;
	}
	PrintToChat(client, "%t", "Vote access granted");
	g_votekick[client] = g_votekick[client] + 1;
	return Action:0;
}

public Action:Command_city17l4d2(client, args)
{
	if (client < 1)
	{
		return Action:3;
	}
	new var1;
	if (GetConVarInt(hm_blockvote_map) && GetConVarInt(hm_allowvote_map_players) <= GetRealClientCount(true))
	{
		PrintToChat(client, "%t", "Vote access granted");
		PrintToChatAll("%t", "%N started the voting", client);
		ServerCommand("sm_votemap l4d2_city17_01");
		if (bStandartMap())
		{
			SaveMap();
		}
		return Action:0;
	}
	if (GetConVarInt(hm_blockvote_map) == 1)
	{
		new AdminId:ClientAdminId = GetUserAdmin(client);
		new flags = GetAdminFlags(ClientAdminId, AdmAccessMode:1);
		new var2;
		if ((ClientRank[client] < GetConVarInt(hm_allowvote_mission) && ClientRank[client]) || (flags & 1024 || flags & 64))
		{
			PrintToChat(client, "%t", "Vote access granted");
			PrintToChatAll("%t", "%N started the voting", client);
			ServerCommand("sm_votemap l4d2_city17_01");
			if (bStandartMap())
			{
				SaveMap();
			}
			return Action:0;
		}
		PrintToChat(client, "%t", "Vote access denied [%d > %d]", ClientRank[client], GetConVarInt(hm_allowvote_mission));
		return Action:3;
	}
	return Action:0;
}

public Action:Command_warcelona(client, args)
{
	if (client < 1)
	{
		return Action:3;
	}
	new var1;
	if (GetConVarInt(hm_blockvote_map) && GetConVarInt(hm_allowvote_map_players) >= GetRealClientCount(true))
	{
		PrintToChat(client, "%t", "Vote access granted");
		PrintToChatAll("%t", "%N started the voting", client);
		ServerCommand("sm_votemap srocchurch");
		if (bStandartMap())
		{
			SaveMap();
		}
		return Action:0;
	}
	if (GetConVarInt(hm_blockvote_map) == 1)
	{
		new AdminId:ClientAdminId = GetUserAdmin(client);
		new flags = GetAdminFlags(ClientAdminId, AdmAccessMode:1);
		new var2;
		if ((ClientRank[client] < GetConVarInt(hm_allowvote_mission) && ClientRank[client]) || (flags & 1024 || flags & 64))
		{
			PrintToChat(client, "%t", "Vote access granted");
			PrintToChatAll("%t", "%N started the voting", client);
			ServerCommand("sm_votemap srocchurch");
			if (bStandartMap())
			{
				SaveMap();
			}
			return Action:0;
		}
		PrintToChat(client, "%t", "Vote access denied [%d > %d]", ClientRank[client], GetConVarInt(hm_allowvote_mission));
		return Action:3;
	}
	return Action:0;
}

public Action:Command_ravenholm(client, args)
{
	if (client < 1)
	{
		return Action:3;
	}
	new var1;
	if (GetConVarInt(hm_blockvote_map) && GetConVarInt(hm_allowvote_map_players) >= GetRealClientCount(true))
	{
		PrintToChat(client, "%t", "Vote access granted");
		PrintToChatAll("%t", "%N started the voting", client);
		ServerCommand("sm_votemap l4d2_ravenholmwar_1");
		if (bStandartMap())
		{
			SaveMap();
		}
		return Action:0;
	}
	if (GetConVarInt(hm_blockvote_map) == 1)
	{
		new AdminId:ClientAdminId = GetUserAdmin(client);
		new flags = GetAdminFlags(ClientAdminId, AdmAccessMode:1);
		new var2;
		if ((ClientRank[client] < GetConVarInt(hm_allowvote_mission) && ClientRank[client]) || (flags & 1024 || flags & 64))
		{
			PrintToChat(client, "%t", "Vote access granted");
			PrintToChatAll("%t", "%N started the voting", client);
			ServerCommand("sm_votemap l4d2_ravenholmwar_1");
			if (bStandartMap())
			{
				SaveMap();
			}
			return Action:0;
		}
		PrintToChat(client, "%t", "Vote access denied [%d > %d]", ClientRank[client], GetConVarInt(hm_allowvote_mission));
		return Action:3;
	}
	return Action:0;
}

public Action:Command_lastsummer(client, args)
{
	if (client < 1)
	{
		return Action:3;
	}
	new var1;
	if (GetConVarInt(hm_blockvote_map) && GetConVarInt(hm_allowvote_map_players) >= GetRealClientCount(true))
	{
		PrintToChat(client, "%t", "Vote access granted");
		PrintToChatAll("%t", "%N started the voting", client);
		ServerCommand("sm_votemap campanar_coop_vs");
		if (bStandartMap())
		{
			SaveMap();
		}
		return Action:0;
	}
	if (GetConVarInt(hm_blockvote_map) == 1)
	{
		new AdminId:ClientAdminId = GetUserAdmin(client);
		new flags = GetAdminFlags(ClientAdminId, AdmAccessMode:1);
		new var2;
		if ((ClientRank[client] < GetConVarInt(hm_allowvote_mission) && ClientRank[client]) || (flags & 1024 || flags & 64))
		{
			PrintToChat(client, "%t", "Vote access granted");
			PrintToChatAll("%t", "%N started the voting", client);
			ServerCommand("sm_votemap campanar_coop_vs");
			if (bStandartMap())
			{
				SaveMap();
			}
			return Action:0;
		}
		PrintToChat(client, "%t", "Vote access denied [%d > %d]", ClientRank[client], GetConVarInt(hm_allowvote_mission));
		return Action:3;
	}
	return Action:0;
}

public Action:Command_yama(client, args)
{
	if (client < 1)
	{
		return Action:3;
	}
	new var1;
	if (GetConVarInt(hm_blockvote_map) && GetConVarInt(hm_allowvote_map_players) >= GetRealClientCount(true))
	{
		PrintToChat(client, "%t", "Vote access granted");
		PrintToChatAll("%t", "%N started the voting", client);
		ServerCommand("sm_votemap l4d_yama_1");
		if (bStandartMap())
		{
			SaveMap();
		}
		return Action:0;
	}
	if (GetConVarInt(hm_blockvote_map) == 1)
	{
		new AdminId:ClientAdminId = GetUserAdmin(client);
		new flags = GetAdminFlags(ClientAdminId, AdmAccessMode:1);
		new var2;
		if ((ClientRank[client] < GetConVarInt(hm_allowvote_mission) && ClientRank[client]) || (flags & 1024 || flags & 64))
		{
			PrintToChat(client, "%t", "Vote access granted");
			PrintToChatAll("%t", "%N started the voting", client);
			ServerCommand("sm_votemap l4d_yama_1");
			if (bStandartMap())
			{
				SaveMap();
			}
			return Action:0;
		}
		PrintToChat(client, "%t", "Vote access denied [%d > %d]", ClientRank[client], GetConVarInt(hm_allowvote_mission));
		return Action:3;
	}
	return Action:0;
}

public Action:Command_one4nine(client, args)
{
	if (client < 1)
	{
		return Action:3;
	}
	new var1;
	if (GetConVarInt(hm_blockvote_map) && GetConVarInt(hm_allowvote_map_players) >= GetRealClientCount(true))
	{
		PrintToChat(client, "%t", "Vote access granted");
		PrintToChatAll("%t", "%N started the voting", client);
		ServerCommand("sm_votemap l4d_149_1");
		if (bStandartMap())
		{
			SaveMap();
		}
		return Action:0;
	}
	if (GetConVarInt(hm_blockvote_map) == 1)
	{
		new AdminId:ClientAdminId = GetUserAdmin(client);
		new flags = GetAdminFlags(ClientAdminId, AdmAccessMode:1);
		new var2;
		if ((ClientRank[client] < GetConVarInt(hm_allowvote_mission) && ClientRank[client]) || (flags & 1024 || flags & 64))
		{
			PrintToChat(client, "%t", "Vote access granted");
			PrintToChatAll("%t", "%N started the voting", client);
			ServerCommand("sm_votemap l4d_149_1");
			if (bStandartMap())
			{
				SaveMap();
			}
			return Action:0;
		}
		PrintToChat(client, "%t", "Vote access denied [%d > %d]", ClientRank[client], GetConVarInt(hm_allowvote_mission));
		return Action:3;
	}
	return Action:0;
}

SaveMap()
{
	if (!FileExists("mapfinalnext_recover.txt", false, "GAME"))
	{
		new Handle:dataFileHandle = OpenFile("mapfinalnext_recover.txt", "a", false, "GAME");
		WriteFileLine(dataFileHandle, "c1m1_hotel");
		CloseHandle(dataFileHandle);
	}
	else
	{
		if (FileExists("mapfinalnext_recover.txt", false, "GAME"))
		{
			if (!DeleteFile("mapfinalnext_recover.txt", false, "DEFAULT_WRITE_PATH"))
			{
				LogError("[Mapfinalnext Map Recovery] Warning: Failed to delete \"%s\" possibly due to lacking permissions.", "mapfinalnext_recover.txt");
			}
		}
	}
	new Handle:inf = OpenFile("mapfinalnext_recover.txt", "w+", false, "GAME");
	if (inf)
	{
		decl String:CurrentMap[256];
		GetCurrentMap(CurrentMap, 256);
		if (bStandartMapOfCampaign())
		{
			WriteFileLine(inf, CurrentMap);
		}
		CloseHandle(inf);
		return 0;
	}
	LogError("[Mapfinalnext Map Recovery] Failed to open/create file '%s'", "mapfinalnext_recover.txt");
	return 0;
}

public bool:bStandartMapOfCampaign()
{
	decl String:MapName[128];
	GetCurrentMap(MapName, 128);
	new var1;
	if (StrContains(MapName, "c1m1", true) > -1 || StrContains(MapName, "c1m2", true) > -1 || StrContains(MapName, "c1m3", true) > -1 || StrContains(MapName, "c1m4", true) > -1 || StrContains(MapName, "c2m1", true) > -1 || StrContains(MapName, "c2m2", true) > -1 || StrContains(MapName, "c2m3", true) > -1 || StrContains(MapName, "c2m4", true) > -1 || StrContains(MapName, "c2m5", true) > -1 || StrContains(MapName, "c3m1", true) > -1 || StrContains(MapName, "c3m2", true) > -1 || StrContains(MapName, "c3m3", true) > -1 || StrContains(MapName, "c3m4", true) > -1 || StrContains(MapName, "c4m1", true) > -1 || StrContains(MapName, "c4m2", true) > -1 || StrContains(MapName, "c4m3", true) > -1 || StrContains(MapName, "c4m4", true) > -1 || StrContains(MapName, "c4m5", true) > -1 || StrContains(MapName, "c5m1", true) > -1 || StrContains(MapName, "c5m2", true) > -1 || StrContains(MapName, "c5m3", true) > -1 || StrContains(MapName, "c5m4", true) > -1 || StrContains(MapName, "c5m5", true) > -1 || StrContains(MapName, "c6m1", true) > -1 || StrContains(MapName, "c6m2", true) > -1 || StrContains(MapName, "c6m3", true) > -1 || StrContains(MapName, "c7m1", true) > -1 || StrContains(MapName, "c7m2", true) > -1 || StrContains(MapName, "c7m3", true) > -1 || StrContains(MapName, "c8m1", true) > -1 || StrContains(MapName, "c8m2", true) > -1 || StrContains(MapName, "c8m3", true) > -1 || StrContains(MapName, "c8m4", true) > -1 || StrContains(MapName, "c8m5", true) > -1 || StrContains(MapName, "c9m1", true) > -1 || StrContains(MapName, "c9m2", true) > -1 || StrContains(MapName, "c10m1", true) > -1 || StrContains(MapName, "c10m2", true) > -1 || StrContains(MapName, "c10m3", true) > -1 || StrContains(MapName, "c10m4", true) > -1 || StrContains(MapName, "c10m5", true) > -1 || StrContains(MapName, "c11m1", true) > -1 || StrContains(MapName, "c11m2", true) > -1 || StrContains(MapName, "c11m3", true) > -1 || StrContains(MapName, "c11m4", true) > -1 || StrContains(MapName, "c11m5", true) > -1 || StrContains(MapName, "c12m1", true) > -1 || StrContains(MapName, "c12m2", true) > -1 || StrContains(MapName, "c12m3", true) > -1 || StrContains(MapName, "c12m4", true) > -1 || StrContains(MapName, "c12m5", true) > -1 || StrContains(MapName, "c13m1", true) > -1 || StrContains(MapName, "c13m2", true) > -1 || StrContains(MapName, "c13m3", true) > -1 || StrContains(MapName, "c13m4", true) > -1)
	{
		return true;
	}
	return false;
}

public Action:steam_command(client, args)
{
	if (0 < client <= MaxClients)
	{
		wS_ShowMenu(client, 0);
	}
	return Action:3;
}

wS_ShowMenu(client, item)
{
	new Handle:menu = CreateMenu(Menu_CallBack, MenuAction:28);
	SetMenuTitle(menu, "Detect SteaM\n \n");
	decl String:Text[68];
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			new var2;
			if (g_HaveSteam[i])
			{
				var2[0] = 92368;
			}
			else
			{
				if (g_Socket[i])
				{
					var2[0] = 92376;
				}
				var2[0] = 92384;
			}
			Format(Text, 65, "%N (%s)", i, var2);
			if (g_HaveSteam[i])
			{
				AddMenuItem(menu, g_ProfileID[i], Text, 0);
			}
			AddMenuItem(menu, "", Text, 1);
		}
		i++;
	}
	DisplayMenuAtItem(menu, client, item, 0);
	return 0;
}

public Menu_CallBack(Handle:menu, MenuAction:action, client, item)
{
	if (action != MenuAction:4)
	{
		return 0;
	}
	decl String:info[100];
	if (!GetMenuItem(menu, item, info, 100, 0, "", 0))
	{
		return 0;
	}
	Format(info, 100, "http://steamcommunity.com/profiles/%s", info);
	ShowMOTDPanel(client, "SteaM ProfiLe", info, 2);
	PrintToChat(client, "\x04%s", info);
	wS_ShowMenu(client, GetMenuSelectionPosition());
	return 0;
}

wS_GetProfileId(client, String:steamid[])
{
	new var3;
	if (ExplodeString(steamid, ":", var3, 3, 11, false) != 3)
	{
		return 0;
	}
	new String:Identifier[20] = "76561197960265728";
	new Current;
	decl CarryOver;
	new var4 = var3 + 4;
	CarryOver = var4 + var4/* ERROR unknown load Binary */ == 49;
	new i = 16;
	decl j;
	new var5 = var3 + 8;
	j = strlen(var5 + var5) + -1;
	new k = strlen(Identifier) + -1;
	while (0 <= i)
	{
		new var1;
		if (j >= 0)
		{
			new var6 = var3 + 8;
			var1 = var6 + var6[j][-12] * 2;
		}
		else
		{
			var1 = 0;
		}
		new var2;
		if (k >= 0)
		{
			var2 = Identifier[k] + -48 * 1;
		}
		else
		{
			var2 = 0;
		}
		Current = var2 + var1 + CarryOver;
		CarryOver = Current / 10;
		g_ProfileID[client][i] = Current % 10 + 48;
		i--;
		j--;
		k--;
	}
	g_ProfileID[client][4] = MissingTAG:0;
	new Handle:socket = SocketCreate(SocketType:1, OnSocketError);
	SocketSetArg(socket, GetClientUserId(client));
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "steamcommunity.com", 80);
	return 0;
}

public OnSocketError(Handle:socket, errorType, errorNum, any:id)
{
	CloseHandle(socket);
	LogError("SocketError -> errorType: %d, errorNum: %d", errorType, errorNum);
	return 0;
}

public OnSocketConnected(Handle:socket, any:id)
{
	new client = GetClientOfUserId(id);
	if (client < 1)
	{
		CloseHandle(socket);
		return 0;
	}
	decl String:info[200];
	Format(info, 200, "GET /profiles/%s HTTP/1.0\r\nHost: steamcommunity.com\r\nConnection: close\r\n\r\n", g_ProfileID[client]);
	SocketSend(socket, info, -1);
	return 0;
}

public OnSocketReceive(Handle:socket, String:receiveData[], dataSize, any:id)
{
	new var1;
	if (dataSize > 0 && StrContains(receiveData, "user has not yet set", false) != -1)
	{
		wS_ClientAuthorized(socket, id, false);
	}
	return 0;
}

public OnSocketDisconnected(Handle:socket, any:id)
{
	wS_ClientAuthorized(socket, id, true);
	return 0;
}

wS_ClientAuthorized(Handle:socket, id, bool:steam_client)
{
	CloseHandle(socket);
	new client = GetClientOfUserId(id);
	if (client < 1)
	{
		return 0;
	}
	g_HaveSteam[client] = steam_client;
	g_Socket[client] = 1;
	SetTrieValue(g_HaveSteam_Trie, g_SteamID[client], steam_client, true);
	return 0;
}

public void:OnConfigsExecuted()
{
	ReadDb();
	return void:0;
}

ReadDb()
{
	ReadDbMotd();
	return 0;
}

ReadDbMotd()
{
	decl String:query[512];
	Format(query, 512, "SELECT svalue FROM server_settings WHERE sname = 'motdmessage' LIMIT 1");
	SQL_TQuery(db, ReadDbMotdCallback, query, any:0, DBPriority:1);
	return 0;
}

public ReadDbMotdCallback(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if (hndl)
	{
		if (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, MessageOfTheDay, 1024, 0);
		}
		return 0;
	}
	LogError("ReadDbMotdCallback Query failed: %s", error);
	return 0;
}

public Action:Command_SetMotd(client, args)
{
	decl String:arg[1024];
	GetCmdArgString(arg, 1024);
	UpdateServerSettings(client, "motdmessage", arg, MOTD_TITLE);
	return Action:3;
}

bool:UpdateServerSettings(Client, String:Key[], String:Value[], String:Desc[])
{
	new Handle:statement;
	decl String:error[1024];
	decl String:query[2048];
	if (!DoFastQuery(Client, "INSERT IGNORE INTO server_settings SET sname = '%s', svalue = ''", Key))
	{
		PrintToConsole(Client, "[RANK] %s: Setting a new MOTD value failure!", Desc);
		return false;
	}
	Format(query, 2048, "UPDATE server_settings SET svalue = ? WHERE sname = '%s'", Key);
	statement = SQL_PrepareQuery(db, query, error, 1024);
	if (statement)
	{
		new bool:retval = 1;
		SQL_BindParamString(statement, 0, Value, false);
		if (!SQL_Execute(statement))
		{
			if (SQL_GetError(db, error, 1024))
			{
				PrintToConsole(Client, "[RANK] %s: Update failed! (Error = \"%s\")", Desc, error);
				LogError("%s: Update failed! (Error = \"%s\")", Desc, error);
			}
			else
			{
				PrintToConsole(Client, "[RANK] %s: Update failed!", Desc);
				LogError("%s: Update failed!", Desc);
			}
			retval = false;
		}
		else
		{
			PrintToConsole(Client, "[RANK] %s: Update successful!", Desc);
			if (StrEqual(Key, "motdmessage", false))
			{
				strcopy(MessageOfTheDay, 1024, Value);
			}
		}
		CloseHandle(statement);
		return retval;
	}
	PrintToConsole(Client, "[RANK] %s: Update failed! (Reason: Cannot create SQL statement)");
	return false;
}

bool:DoFastQuery(Client, String:Query[])
{
	new String:FormattedQuery[4096];
	VFormat(FormattedQuery, 4096, Query, 3);
	new String:Error[1024];
	if (!SQL_FastQuery(db, FormattedQuery, -1))
	{
		if (SQL_GetError(db, Error, 1024))
		{
			PrintToConsole(Client, "[RANK] Fast query failed! (Error = \"%s\") Query = \"%s\"", Error, FormattedQuery);
			LogError("Fast query failed! (Error = \"%s\") Query = \"%s\"", Error, FormattedQuery);
		}
		else
		{
			PrintToConsole(Client, "[RANK] Fast query failed! Query = \"%s\"", FormattedQuery);
			LogError("Fast query failed! Query = \"%s\"", FormattedQuery);
		}
		return false;
	}
	return true;
}

public Action:Event_StartArea(Handle:event, String:name[], bool:dontBroadcast)
{
	if (bFirstMapOfCampaign())
	{
		StartMapTiming();
		return Action:0;
	}
	return Action:0;
}

public OnEntityCreated(entity, String:classname[])
{
	if (StrEqual(classname, "prop_door_rotating_checkpoint", true))
	{
		if (!(GetEntProp(entity, PropType:0, "m_eDoorState", 4, 0)))
		{
			HookSingleEntityOutput(entity, "OnFullyOpen", OnStartSFDoorFullyOpened, true);
		}
	}
	return 0;
}

public OnStartSFDoorFullyOpened(String:output[], caller, activator, Float:delay)
{
	StartMapTiming();
	return 0;
}

public StartMapTiming()
{
	if (0.0 != MapTimingStartTime)
	{
		return 0;
	}
	MapTimingStartTime = GetEngineTime();
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			EmitSoundToClient(i, "level/countdown.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		i++;
	}
	return 0;
}

public StopMapTiming()
{
	if (MapTimingStartTime <= 0.0)
	{
		return 0;
	}
	new Float:TotalTime = GetEngineTime() - MapTimingStartTime;
	MapTimingStartTime = -1.0;
	decl String:TimeLabel[32];
	SetTimeLabel(TotalTime, TimeLabel, 32);
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			EmitSoundToClient(i, "level/bell_normal.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			PrintToChat(i, "%t", "It took %s to finish this map!", TimeLabel);
		}
		i++;
	}
	return 0;
}

public SetTimeLabel(Float:TheSeconds, String:TimeLabel[], maxsize)
{
	new FlooredSeconds = RoundToFloor(TheSeconds);
	new FlooredSecondsMod = FlooredSeconds % 60;
	new Float:Seconds = TheSeconds - float(FlooredSeconds) + float(FlooredSecondsMod);
	decl Minutes;
	new var1;
	if (TheSeconds < 60.0)
	{
		var1 = 0;
	}
	else
	{
		var1 = RoundToNearest(float(FlooredSeconds - FlooredSecondsMod) / 60);
	}
	Minutes = var1;
	new MinutesMod = Minutes % 60;
	decl Hours;
	new var2;
	if (Minutes < 60)
	{
		var2 = 0;
	}
	else
	{
		var2 = RoundToNearest(float(Minutes - MinutesMod) / 60);
	}
	Hours = var2;
	Minutes = MinutesMod;
	if (0 < Hours)
	{
		Format(TimeLabel, maxsize, "%t", "%ih %im %.1fs", Hours, Minutes, Seconds);
	}
	else
	{
		if (0 < Minutes)
		{
			Format(TimeLabel, maxsize, "%t", "%i min %.1f sec", Minutes, Seconds);
		}
		Format(TimeLabel, maxsize, "%t", "%.1f seconds", Seconds);
	}
	return 0;
}

public bool:bFirstMapOfCampaign()
{
	decl String:MapName[128];
	GetCurrentMap(MapName, 128);
	new var1;
	if (StrContains(MapName, "c1m1", true) > -1 || StrContains(MapName, "c2m1", true) > -1 || StrContains(MapName, "c3m1", true) > -1 || StrContains(MapName, "c4m1", true) > -1 || StrContains(MapName, "c5m1", true) > -1 || StrContains(MapName, "c6m1", true) > -1 || StrContains(MapName, "c7m1", true) > -1 || StrContains(MapName, "c8m1", true) > -1 || StrContains(MapName, "c9m1", true) > -1 || StrContains(MapName, "c10m1", true) > -1 || StrContains(MapName, "c11m1", true) > -1 || StrContains(MapName, "c12m1", true) > -1 || StrContains(MapName, "c13m1", true) > -1 || StrContains(MapName, "l4d_zero01_base", true) > -1 || StrContains(MapName, "l4d_viennacalling2_1", true) > -1 || StrContains(MapName, "eu01_residential_b16", true) > -1 || StrContains(MapName, "bloodtracks_01", true) > -1 || StrContains(MapName, "l4d2_darkblood01_tanker", true) > -1 || StrContains(MapName, "l4d_dbd2dc_anna_is_gone", true) > -1 || StrContains(MapName, "cdta_01detour", true) > -1 || StrContains(MapName, "l4d_ihm01_forest", true) > -1 || StrContains(MapName, "l4d2_diescraper1_apartment_31", true) > -1 || StrContains(MapName, "l4d_149_1", true) > -1 || StrContains(MapName, "gr-mapone-7", true) > -1 || StrContains(MapName, "qe_1_cliche", true) > -1 || StrContains(MapName, "l4d2_stadium1_apartment", true) > -1 || StrContains(MapName, "eu01_residential_b09", true) > -1 || StrContains(MapName, "wth_1", true) > -1 || StrContains(MapName, "2ee_01", true) > -1 || StrContains(MapName, "l4d2_city17_01", true) > -1 || StrContains(MapName, "l4d_deathaboard01_prison", true) > -1 || StrContains(MapName, "cwm1_intro", true) > -1 || StrContains(MapName, "2ee_01_deadlybeggining", true) > -1 || StrContains(MapName, "l4d_orange01_first", true) > -1 || StrContains(MapName, "hf01_theforest", true) > -1 || StrContains(MapName, "l4d2_deadcity01_riverside", true) > -1 || StrContains(MapName, "tutorial01", true) > -1 || StrContains(MapName, "tutorial_standards", true) > -1 || StrContains(MapName, "srocchurch", true) > -1 || StrContains(MapName, "l4d2_ravenholmwar_1", true) > -1)
	{
		return true;
	}
	return false;
}

public bool:bStandartMap()
{
	decl String:MapName[128];
	GetCurrentMap(MapName, 128);
	new var1;
	if (StrContains(MapName, "c1m", true) > -1 || StrContains(MapName, "c2m", true) > -1 || StrContains(MapName, "c3m", true) > -1 || StrContains(MapName, "c4m", true) > -1 || StrContains(MapName, "c5m", true) > -1 || StrContains(MapName, "c6m", true) > -1 || StrContains(MapName, "c7m", true) > -1 || StrContains(MapName, "c8m", true) > -1 || StrContains(MapName, "c9m", true) > -1 || StrContains(MapName, "c10m", true) > -1 || StrContains(MapName, "c11m", true) > -1 || StrContains(MapName, "c12m", true) > -1 || StrContains(MapName, "c13m", true) > -1)
	{
		return true;
	}
	return false;
}

