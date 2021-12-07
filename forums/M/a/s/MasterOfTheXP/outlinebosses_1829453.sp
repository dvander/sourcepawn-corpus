#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#define PLUGIN_VERSION  "1.1"

public Plugin:myinfo = {
	name = "Halloween Damage Tracker",
	author = "MasterOfTheXP",
	description = "Tracks damage done to HHH/Mono/Tank/Merasmus. Outlines 'em. An stuffs.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

#define BOSS_HHH (1 << 0) // 1
#define BOSS_MONO (1 << 1) // 2
#define BOSS_TANK (1 << 2) // 4
#define BOSS_MERASMUS (1 << 3) // 8

#define NOTICE_HHHDED (1 << 0) // 1
#define NOTICE_MONODED (1 << 1) // 2
#define NOTICE_UNDERWORLD (1 << 2) // 4
#define NOTICE_LOOTISLAND (1 << 3) // 32
#define NOTICE_SKULLISLAND (1 << 4) // 16
#define NOTICE_MERASMUSDED (1 << 5) // 32

enum {
	Boss_Invalid = 0,
	Boss_Horsemann,
	Boss_Monoculus,
	Boss_Tank,
	Boss_Merasmus,
	MerasmusProp
}

new MonsterEnt;
new Damage[MAXPLAYERS + 1][2049];
new ControllingHealthbar;
new BossType[2049];
new LastDamaged[MAXPLAYERS + 1];
new ActiveBosses;


new Handle:cvarDamageTracker;
new Handle:cvarSpawnNotice;
new Handle:cvarDisableDefeat;
new Handle:cvarOutline;
new Handle:cvarHealthbar;
new Handle:cvarPropFlicker;
new Handle:cvarPointsForDamage;

new Handle:DmgTimer;
new Handle:DmgText;

public OnPluginStart()
{
	new String:Game[10];
	GetGameFolderName(Game, 10);
	if (strncmp(Game, "tf", 2, false) != 0) SetFailState("Halloween Damage Tracker only works on Team Fortress 2!");
	CreateConVar("sm_hdmgtracker_version",PLUGIN_VERSION,"Plugin version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	cvarDamageTracker = CreateConVar("sm_halloween_damagetracker","15", "Damage to these bosses will be tracked, and displayed at the end of their life. Add up the numbers to track the bosses you want.\n1=Horsemann \n2=Monoculus \n4=Tank \n8=Merasmus", FCVAR_NONE);
	cvarSpawnNotice = CreateConVar("sm_halloween_spawnnotice","15", "When these bosses spawn, a notice will be printed to chat, including their health value. Add up the numbers to track the bosses you want.\n1=Horsemann \n2=Monoculus \n4=Tank \n8=Merasmus", FCVAR_NONE);
	cvarDisableDefeat = CreateConVar("sm_halloween_nodefeatnotice","63", "These notices will not be printed to the chat. Add up the numbers to block the notices you want.\n1=Horsemann defeated \n2=Monoculus defeated \n4=Underworld escape \n8=Loot Island arrival\n16=Skull Island escape \n32=Merasmus defeated", FCVAR_NONE);
	cvarOutline = CreateConVar("sm_halloween_outline","15", "These bosses will have an \"outline\" glow surrounding them, so they can be seen through walls. Add up the numbers to outline the bosses you want.\n1=Horsemann \n2=Monoculus \n4=Tank \n8=Merasmus", FCVAR_NONE);
	cvarHealthbar = CreateConVar("sm_halloween_healthbar","15", "While these bosses are active, players will be able to see their health via a bar at the top of their screens. Add up the numbers to show healthbars for the bosses you want.\n1=Horsemann \n2=Monoculus \n4=Tank \n8=Merasmus", FCVAR_NONE);
	cvarPropFlicker = CreateConVar("sm_halloween_propflicker","1", "Should Merasmus' props flicker?", FCVAR_NONE);
	cvarPointsForDamage = CreateConVar("sm_halloween_pointsfordamage","600", "Players get one point per this much damage done to a boss. The Damage Tracker (sm_halloween_damagetracker) must be on for that boss. Set to 0 to disable.", FCVAR_NONE);
	AutoExecConfig(true, "outlinebosses");
	HookConVarChange(cvarDamageTracker, CvarChange);
	HookEvent("npc_hurt", Event_NpcHurt, EventHookMode_Post);
	HookEvent("eyeball_boss_killer", Event_Defeated, EventHookMode_Pre);
	DmgText = CreateHudSynchronizer();
}

public OnMapStart()
{
	MonsterEnt = FindEntityByClassname(-1, "monster_resource");
	DmgTimer = CreateTimer(0.1, Timer_Damage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnEntityCreated(Ent, const String:cls[])
{
	if (StrEqual(cls, "headless_hatman", false)) BossType[Ent] = Boss_Horsemann;
	else if (StrEqual(cls, "eyeball_boss", false)) BossType[Ent] = Boss_Monoculus;
	else if (StrEqual(cls, "tank_boss", false)) BossType[Ent] = Boss_Tank;
	else if (StrEqual(cls, "merasmus", false)) BossType[Ent] = Boss_Merasmus;
	else if (StrEqual(cls, "tf_merasmus_trick_or_treat_prop", false)) BossType[Ent] = MerasmusProp;
	else
	{
		BossType[Ent] = Boss_Invalid;
		return;
	}
	CreateTimer(0.1, NPCSpawn, EntIndexToEntRef(Ent));
	ActiveBosses++;
}

public Action:NPCSpawn(Handle:timer, any:ref)
{
	new Ent = EntRefToEntIndex(ref);
	if (!IsValidEntity(Ent)) return Plugin_Handled;
	new HP = GetEntProp(Ent, Prop_Data, "m_iMaxHealth"), SpawnNotice = GetConVarInt(cvarSpawnNotice), Outline = GetConVarInt(cvarOutline), Healthbar = GetConVarInt(cvarHealthbar);
	switch (BossType[Ent])
	{
		case Boss_Horsemann:
		{
			if (SpawnNotice & BOSS_HHH) PrintToChatAll("\x01The \x07800080Horseless Headless Horsemann\x01 spawned with \x03%i\x01 HP!", HP);
			if (Outline & BOSS_HHH) SetEntProp(Ent, Prop_Send, "m_bGlowEnabled", 1);
			if (Healthbar & BOSS_HHH) SetHealthbar(Ent);
		}
		case Boss_Monoculus:
		{
			if (SpawnNotice & BOSS_MONO) PrintToChatAll("\x01\x07800080MONOCULUS!\x01 spawned with \x03%i\x01 HP!", HP);
			if (Outline & BOSS_MONO) SetEntProp(Ent, Prop_Send, "m_bGlowEnabled", 1);
			if (!(Healthbar & BOSS_MONO)) SetHealthbar(0);
		}
		case Boss_Tank:
		{
			if (SpawnNotice & BOSS_TANK) PrintToChatAll("\x01A \x07800080Tank\x01 spawned with \x03%i\x01 HP!", HP);
			if (!(Outline & BOSS_TANK)) SetEntProp(Ent, Prop_Send, "m_bGlowEnabled", 0);
			if (Healthbar & BOSS_TANK) SetHealthbar(Ent);
		}
		case Boss_Merasmus:
		{
			if (SpawnNotice & BOSS_MERASMUS) PrintToChatAll("\x01\x07800080Merasmus\x01 spawned with \x03%i\x01 HP!", HP);
			if (Outline & BOSS_MERASMUS) SetEntProp(Ent, Prop_Send, "m_bGlowEnabled", 1);
			if (!(Healthbar & BOSS_MERASMUS)) SetHealthbar(0);
		}
		case MerasmusProp:
		{
			if (GetConVarBool(cvarPropFlicker)) // Thanks xPaw
			{
				SetEntityRenderFx(Ent, RENDERFX_FLICKER_FAST);
				SetEntityRenderMode(Ent, RENDER_TRANSALPHA);
				SetEntityRenderColor(Ent, 255, 255, 0, 255);
			}
		}
	}
	return Plugin_Handled;
}

public OnEntityDestroyed(Ent)
{
	if (BossType[Ent] == 0) return;
	if (GetConVarInt(cvarDamageTracker) & BossTypeToBitwise(BossType[Ent]))
	{
		new top[3], String:str[256], pointsfordamage = GetConVarInt(cvarPointsForDamage); // VS Saxton Hale :3
		for (new i = 1; i <= MaxClients; i++)
		{
			if (Damage[i][Ent] >= Damage[top[0]][Ent])
			{
				top[2] = top[1];
				top[1] = top[0];
				top[0] = i;
			}
			else if (Damage[i][Ent] >= Damage[top[1]][Ent])
			{
				top[2] = top[1];
				top[1] = i;
			}
			else if (Damage[i][Ent] >= Damage[top[2]][Ent])
			{
				top[2] = i;
			}
		}
		switch (BossType[Ent])
		{
			case Boss_Horsemann: str = "The Horseless Headless Horsemann";
			case Boss_Monoculus: str = "MONOCULUS!";
			case Boss_Tank: str = "The Tank";
			case Boss_Merasmus: str = "Merasmus";
		}
		new HP = GetEntProp(Ent, Prop_Data, "m_iHealth");
		Format(str, sizeof(str), "%s had %i (of %i) HP left.\n\nMost damage dealt by:", str, HP >= 0 ? HP : 0, GetEntProp(Ent, Prop_Data, "m_iMaxHealth"));
		for (new z = 0; z <= 2; z++)
		{
			if (IsValidClient(top[z])) Format(str, sizeof(str), "%s\n[%i] %N - %i", str, z + 1, top[z], Damage[top[z]][Ent]);
			else Format(str, sizeof(str), "%s\n[%i] ---", str, z + 1);
		}
		SetHudTextParams(-1.0, 0.3, 10.0, 255, 255, 255, 255);
		for (new z = 1; z <= MaxClients; z++)
		{
			if (!IsValidClient(z)) continue;
			if (!IsFakeClient(z))
			{
				new String:str2[256];
				Format(str2, sizeof(str2), "%s\n\nDamage Dealt: %i", str, Damage[z][Ent]);
				if (pointsfordamage > 0) Format(str2, sizeof(str2), "%s\nScore for this round: %i", str2, RoundFloat(float(Damage[z][Ent]) / pointsfordamage));
				ShowHudText(z, -1, str2);
			}
			if (pointsfordamage > 0)
			{
				new Handle:aevent = CreateEvent("player_escort_score", true);
				SetEventInt(aevent, "player", z);
				new j;
				for (j = 0; Damage[z][Ent] - pointsfordamage > 0; Damage[z][Ent] -= pointsfordamage, j++) {}
				SetEventInt(aevent, "points", j);
				FireEvent(aevent);
			}
		}
	}
	BossType[Ent] = Boss_Invalid;
	ActiveBosses--;
	for (new z = 1; z <= MaxClients; z++)
	{
		Damage[z][Ent] = 0;
		if (LastDamaged[z] == Ent) LastDamaged[z] = 0;
	}
	if (Ent == ControllingHealthbar)
	{
		ControllingHealthbar = 0;
		SetHealthbar(0);
	}
}

stock SetHealthbar(Ent)
{
	if (ControllingHealthbar == 0 && Ent == 0)
	{
		SetEntProp(MonsterEnt, Prop_Send, "m_iBossHealthPercentageByte", 0);
		return;
	}
	if (ControllingHealthbar == 0) ControllingHealthbar = Ent;
	if (ControllingHealthbar != Ent) return;
	new Float:HP = float(GetEntProp(Ent, Prop_Data, "m_iHealth")), Float:MaxHP = float(GetEntProp(Ent, Prop_Data, "m_iMaxHealth"));
	if (MaxHP == 0.0) return;
	SetEntProp(MonsterEnt, Prop_Send, "m_iBossHealthPercentageByte", RoundFloat(255.0 * (HP / MaxHP)));
}

public OnGameFrame() // Ohhhh nooooooooo
{
	if (ActiveBosses > 0 && ControllingHealthbar == 0)
	{
		SetEntProp(MonsterEnt, Prop_Send, "m_iBossHealthPercentageByte", 0);
		return;
	}
}

public Action:Event_NpcHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker_player"));
	new damage = GetEventInt(event, "damageamount");
	new Ent		= GetEventInt(event, "entindex");
	new Bit		= BossTypeToBitwise(BossType[Ent]);
	if (Bit == 0) return Plugin_Continue;
	new Healthbar = GetConVarInt(cvarHealthbar);
	if (Bit == BOSS_HHH && Healthbar & Bit) SetHealthbar(Ent);
	if (Bit == BOSS_MONO && !(Healthbar & Bit)) SetHealthbar(0);
	if (Bit == BOSS_TANK && Healthbar & Bit) SetHealthbar(Ent);
	if (Bit == BOSS_MERASMUS && !(Healthbar & Bit)) SetHealthbar(0);
	Damage[client][Ent] += damage;
	LastDamaged[client] = Ent;
	return Plugin_Continue;
}

public Action:Event_Defeated(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarDisableDefeat) & NOTICE_MONODED) SetEventBroadcast(event, true);
}

public Action:Timer_Damage(Handle:timer)
{
	new cvarvalue = GetConVarInt(cvarDamageTracker);
	if (cvarvalue < 1)
	{
		DmgTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (ActiveBosses < 1) break;
		if (!IsValidClient(z)) continue;
		SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
		ShowSyncHudText(z, DmgText, "Damage: %i", Damage[z][LastDamaged[z]]);
	}
	return Plugin_Handled;
}

public Action:UserMessageHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new String:msg1[96], String:msg2[96], disabledefeat = GetConVarInt(cvarDisableDefeat);
	BfReadString(bf, msg1, sizeof(msg1));
	BfReadString(bf, msg2, sizeof(msg2));
	if (StrEqual(msg2, "#TF_Halloween_Boss_Killers") && disabledefeat & NOTICE_HHHDED)
		return Plugin_Handled;
	if (StrEqual(msg2, "#TF_Halloween_Underworld") && disabledefeat & NOTICE_UNDERWORLD)
		return Plugin_Handled;
	if (StrEqual(msg2, "#TF_Halloween_Loot_Island") && disabledefeat & NOTICE_LOOTISLAND)
		return Plugin_Handled;
	if (StrEqual(msg2, "#TF_Halloween_Skull_Island_Escape") && disabledefeat & NOTICE_SKULLISLAND)
		return Plugin_Handled;
	if (StrEqual(msg2, "#TF_Halloween_Merasmus_Killers") && disabledefeat & NOTICE_MERASMUSDED)
		return Plugin_Handled;
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	for (new z = MaxClients + 1; z <= 2048; z++)
		Damage[client][z] = 0;
	LastDamaged[client] = 0;
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) > 0)
	{
		if (DmgTimer != INVALID_HANDLE) KillTimer(DmgTimer);
		DmgTimer = CreateTimer(0.15, Timer_Damage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock BossTypeToBitwise(Type)
{
	if (Type == Boss_Horsemann) return BOSS_HHH;
	else if (Type == Boss_Monoculus) return BOSS_MONO;
	else if (Type == Boss_Tank) return BOSS_TANK;
	else if (Type == Boss_Merasmus) return BOSS_MERASMUS;
	return 0;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}