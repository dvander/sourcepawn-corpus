#pragma semicolon 1
#include <tf2_stocks>
#include <sdkhooks>
#define PLUGIN_VERSION  "1.2.2"

public Plugin:myinfo = {
	name = "Halloween Damage Tracker",
	author = "MasterOfTheXP",
	description = "Tracks damage done to HHH/Mono/Tank/Merasmus. Again!",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

#define BOSS_HHH (1 << 0) // 1
#define BOSS_MONO (1 << 1) // 2
#define BOSS_TANK (1 << 2) // 4
#define BOSS_MERASMUS (1 << 3) // 8

#define NOTICE_HHHAPPEARED (1 << 0) // 1
#define NOTICE_MONOCULUSAPPEARED (1 << 1) // 2
#define NOTICE_MERASMUSAPPEARED (1 << 2) // 4
#define NOTICE_HHHDEFEATED (1 << 3) // 8
#define NOTICE_MONOCULUSDEFEATED (1 << 4) // 16
#define NOTICE_MERASMUSDEFEATED (1 << 5) // 32
#define NOTICE_PLAYERDEFEATEDHHH (1 << 6) // 64 
#define NOTICE_PLAYERDEFEATEDMONOCULUS (1 << 7) // 128 
#define NOTICE_PLAYERDEFEATEDMERASMUS (1 << 8) // 256 
#define NOTICE_UNDERWORLDESCAPE (1 << 9) // 512 
#define NOTICE_LOOTISLANDARRIVAL (1 << 10) // 1024
#define NOTICE_SKULLISLANDESCAPE (1 << 11) // 2048

enum {
	Boss_NotABoss = 0,
	Boss_Horsemann,
	Boss_Monoculus,
	Boss_Tank,
	Boss_Merasmus,
	MerasmusProp
}

new bool:Enabled = true;
new Float:NextDamageTrackerTime;

new Damage[MAXPLAYERS + 1];
new HdmgSlots[MAXPLAYERS + 1] = {-1, ...};

new BossType[2049];

new Handle:cvarEnabled;
new Handle:cvarSpawnNotice;
new Handle:cvarTracker;
new Handle:cvarOutline;
new Handle:cvarWinScreen;

new Handle:cvarWinScreenDur;
new Handle:cvarOutlineProps;
new Handle:cvarHideNotices;

new Handle:cvarBossName[Boss_Merasmus+1];
new Handle:cvarSpawnNoticeColour[Boss_Merasmus+1];
new Handle:cvarDefaultSlots;
new Handle:cvarWinSlots;
new Handle:cvarHdmgMessage;
new Handle:cvarPointReward;

new Handle:hudTracker;
new Handle:hudWinScreen;

public OnPluginStart()
{
	CreateConVar("sm_hdmgtracker_version", PLUGIN_VERSION, "GAZE NOT UPON THE CVAR! And yes, that cvar.", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	cvarEnabled 						= CreateConVar("sm_hdmgtracker_enable", "1", "Enable Halloween Damage Tracker. If 0, the plugin will not do anything.");
	cvarSpawnNotice 					= CreateConVar("sm_hdmgtracker_spawnmessage", "15", "Print \"Boss spawned with # HP!\" messages to the chat when bosses spawn. Add up the numbers: 1=HHH, 2=Monoculus, 4=Tank, 8=Merasmus.");
	cvarTracker 						= CreateConVar("sm_hdmgtracker_tracker", "15", "Show damage meter heads-up-display for bosses. Add up the numbers: 1=HHH, 2=Monoculus, 4=Tank, 8=Merasmus.");
	cvarOutline						= CreateConVar("sm_hdmgtracker_outline", "15", "These bosses will have a \"glow\" outline around them, making them visible through walls. Add up the numbers: 1=HHH, 2=Monoculus, 4=Tank, 8=Merasmus.");
	cvarWinScreen 					= CreateConVar("sm_hdmgtracker_winscreen", "15", "Upon their defeat/departure, a screen showing how much damage everyone dealt will be displayed for these bosses. Add up the numbers: 1=HHH, 2=Monoculus, 4=Tank, 8=Merasmus.");
	
	cvarWinScreenDur 					= CreateConVar("sm_hdmgtracker_winscreen_duration", "10.0", "Time (in seconds) to display the win screen for.");
	cvarOutlineProps 					= CreateConVar("sm_hdmgtracker_outlinemerasmusprops", "1", "Props that Merasmus hides in will be visible through walls.");
	cvarHideNotices 					= CreateConVar("sm_hdmgtracker_hidenotices", "4032", "Hide certain messages about bosses that are usually shown by the game. Add up the numbers:\n1. HHH appeared! + sound\n2. MONOCULUS! appeared! + sound\n4. MERASMUS! appeared! + sound\n8. HHH defeated! + sound\n16. MONOCULUS! defeated!/left! + sound\n32. MERASMUS! defeated!/gone home! + sound\n64. PLAYER has defeated HHH!\n128. PLAYER has defeated MONOCULUS!\n256. PLAYER has defeated MERASMUS!\n512. PLAYER has escaped the underworld!\n1024. PLAYER has made it to Loot Island!\n2048. PLAYER has escaped Skull Island!");
	
	// Took a few minutes to figure out these tag mismatch warnings, then figured it out...then realized that Flamin fixed these same warnings in Model Manager already.
	cvarBossName[Boss_Horsemann] 	= _:CreateConVar("sm_hdmgtracker_name_horsemann", "The Horseless Headless Horsemann", "Custom name to give to the Horseless Headless Horsemann.");
	cvarBossName[Boss_Monoculus] 	= _:CreateConVar("sm_hdmgtracker_name_monoculus", "MONOCULUS!", "Custom name to give to Monoculus.");
	cvarBossName[Boss_Tank] 			= _:CreateConVar("sm_hdmgtracker_name_tank", "A Tank", "Custom name to give to the Tank.");
	cvarBossName[Boss_Merasmus] 		= _:CreateConVar("sm_hdmgtracker_name_merasmus", "MERASMUS!", "Custom name to give to Merasmus.");
	
	cvarSpawnNoticeColour[Boss_Horsemann] 	= _:CreateConVar("sm_hdmgtracker_msgclr_horsemann", "FF7632", "Hex colour (RRGGBB or RRGGBBAA) to use on the Horseless Headless Horsemann's spawn message.");
	cvarSpawnNoticeColour[Boss_Monoculus] 	= _:CreateConVar("sm_hdmgtracker_msgclr_monoculus", "FF7632", "Hex colour (RRGGBB or RRGGBBAA) to use on Monoculus's spawn message.");
	cvarSpawnNoticeColour[Boss_Tank] 		= _:CreateConVar("sm_hdmgtracker_msgclr_tank", "FF7632", "Hex colour (RRGGBB or RRGGBBAA) to use on the Tank's spawn message.");
	cvarSpawnNoticeColour[Boss_Merasmus] 	= _:CreateConVar("sm_hdmgtracker_msgclr_merasmus", "FF7632", "Hex colour (RRGGBB or RRGGBBAA) to use on Merasmus's spawn message.");
	
	cvarDefaultSlots 					= CreateConVar("sm_hdmgtracker_defaultslots", "3", "Default \"Top # damagers\" to show to players who damage the boss. Players can still modify it with /hdmg.");
	cvarWinSlots 						= CreateConVar("sm_hdmgtracker_winslots", "3", "\"Top # damagers\" to show on the win screen, shown when the boss is defeated.");
	cvarHdmgMessage 					= CreateConVar("sm_hdmgtracker_hdmgmessage", "1", "Show an informative message on how to use /hdmg when a player first harms a boss.");
	cvarPointReward					= CreateConVar("sm_hdmgtracker_pointreward", "600", "For each # damage done, 1 point will be awarded to players on the scoreboard. 0 to disable. May be buggy.");
	
	HookConVarChange(cvarEnabled, OnConVarChanged);
	AutoExecConfig(true, "halloweendamagetracker");
	
	RegAdminCmd("hdmg", Command_Hdmg, 0);
	
	HookEvent("npc_hurt",				Event_NPCHurt);
	HookEvent("pumpkin_lord_summoned",	Event_NoticeHooks);
	HookEvent("pumpkin_lord_killed",	Event_NoticeHooks);
	HookEvent("eyeball_boss_summoned",	Event_NoticeHooks);
	HookEvent("eyeball_boss_escaped",	Event_NoticeHooks);
	HookEvent("eyeball_boss_killer",	Event_NoticeHooks);
	HookEvent("eyeball_boss_killed",	Event_NoticeHooks);
	HookEvent("merasmus_summoned",		Event_NoticeHooks);
	HookEvent("merasmus_escaped",		Event_NoticeHooks);
	HookEvent("merasmus_killed",		Event_NoticeHooks);
	
	HookUserMessage(GetUserMessageId("SayText2"), UserMsg_SayText2, true);
	
	hudTracker							= CreateHudSynchronizer();
	hudWinScreen						= CreateHudSynchronizer();
	
	CreateTimer(1.0, Timer_Second, _, TIMER_REPEAT);
}

public OnClientDisconnect(client)
{
	Damage[client] = 0;
	HdmgSlots[client] = -1;
}

public Action:Command_Hdmg(client, args)
{
	if (!Enabled) return Plugin_Continue;
	if (!client) return Plugin_Continue;
	new String:str[10];
	GetCmdArgString(str, sizeof(str));
	new newSlots = StringToInt(str);
	if (newSlots < 0) newSlots *= -1;
	else if (newSlots > 64) newSlots = 64;
	if (!newSlots)
	{
		if (!StrContains(str, "0") || StrEqual(str, "off"))
		{
			HdmgSlots[client] = 0;
			ReplyToCommand(client, "\x01Halloween Damage Tracker \x07FF7632disabled\x01.");
		}
		else
		{
			new String:reply[192];
			Format(reply, sizeof(reply), "\x01Usage: \x07FF7632/hdmg <#>\x01 - Set the amount of slots shown by Halloween Damage Tracker.\n\x07FF7632/hdmg off\x01 to disable it.");
			if (HdmgSlots[client] > 0) Format(reply, sizeof(reply), "%s\nIt's currently set to \x07FF7632%i\x01 slots.", reply, HdmgSlots[client]);
			else if (!HdmgSlots[client]) Format(reply, sizeof(reply), "%s\nIt's currently \x07FF7632disabled\x01.", reply);
			ReplyToCommand(client, reply);
		}
		return Plugin_Handled;
	}
	HdmgSlots[client] = newSlots;
	ReplyToCommand(client, "\x01Halloween Damage Tracker will now show you \x07FF7632%i\x01 damage slots while you fight a boss.", newSlots);
	return Plugin_Handled;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (entity <= 0 || entity > 2048) return;
	if (classname[0] != 'h' &&
	classname[0] != 'e' &&
	classname[0] != 't' &&
	classname[0] != 'm') return;
	if (StrEqual(classname, "headless_hatman", false)) BossType[entity] = Boss_Horsemann;
	else if (StrEqual(classname, "eyeball_boss", false)) BossType[entity] = Boss_Monoculus;
	else if (StrEqual(classname, "tank_boss", false)) BossType[entity] = Boss_Tank;
	else if (StrEqual(classname, "merasmus", false)) BossType[entity] = Boss_Merasmus;
	else if (StrEqual(classname, "tf_merasmus_trick_or_treat_prop", false)) BossType[entity] = MerasmusProp;
	if (!Enabled) return;
	CreateTimer(0.0, Timer_BossSpawn, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_BossSpawn(Handle:timer, any:ref)
{
	if (!Enabled) return;
	new entity = EntRefToEntIndex(ref);
	if (!IsValidEdict(entity)) return;
	if (MerasmusProp == BossType[entity])
	{
		if (GetConVarBool(cvarOutlineProps))
		{
			new dispenser = CreateEntityByName("obj_dispenser");
			
			DispatchKeyValue(dispenser, "spawnflags", "2");
			DispatchKeyValue(dispenser, "solid", "0");
			DispatchKeyValue(dispenser, "teamnum", "1");
			SetEntProp(dispenser, Prop_Send, "m_usSolidFlags", (GetEntProp(dispenser, Prop_Send, "m_usSolidFlags") | (1 << 1)));
			new String:model[PLATFORM_MAX_PATH], Float:pos[3], Float:ang[3];
			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
			GetEntPropVector(entity, Prop_Send, "m_angRotation", ang);
			SetEntProp(dispenser, Prop_Send, "m_bGlowEnabled", 1);
			
			TeleportEntity(dispenser, pos, ang, NULL_VECTOR);
			DispatchSpawn(dispenser);
			SetEntityModel(dispenser, model);
			SetVariantString("!activator");
			AcceptEntityInput(dispenser, "SetParent", entity);
			
			SDKHook(dispenser, SDKHook_OnTakeDamage, OnTakeDamage_Dispenser);
			return;
		}
	}
	if (Boss_Monoculus == BossType[entity])
	{
		new team = GetEntProp(entity, Prop_Send, "m_iTeamNum");
		if (2 == team || 3 == team) return;
	}
	
	new HP 				= GetEntProp(entity, Prop_Data, "m_iMaxHealth");
	new	SpawnNotice 	= GetConVarInt(cvarSpawnNotice);
	new	Outline 		= GetConVarInt(cvarOutline);
	new boss_bit = GetBitOfBossType(BossType[entity]);
	
	if (SpawnNotice & boss_bit)
	{
		new String:bossName[96], String:prefix[32], String:colour[15];
		GetConVarString(cvarBossName[BossType[entity]], bossName, sizeof(bossName));
		SeperateBossNamePrefix(bossName, bossName, sizeof(bossName), prefix, sizeof(prefix));
		GetConVarString(cvarSpawnNoticeColour[BossType[entity]], colour, sizeof(colour));
		if (strlen(colour) >= 8) Format(colour, sizeof(colour), "\x08%s", colour);
		else if (strlen(colour) >= 6) Format(colour, sizeof(colour), "\x07%s", colour);
		else Format(colour, sizeof(colour), "\x07FF7632");
		PrintToChatAll("\x01%s%s%s\x01 spawned with %s%i\x01 HP!", prefix, colour, bossName, colour, HP);
	}
	
	if (Outline & boss_bit && Boss_Tank != BossType[entity])
		SetEntProp(entity, Prop_Send, "m_bGlowEnabled", 1);
	else if (!(Outline & boss_bit) && Boss_Tank == BossType[entity])
		SetEntProp(entity, Prop_Send, "m_bGlowEnabled", 0);
}

public Action:OnTakeDamage_Dispenser(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new parent = GetEntPropEnt(victim, Prop_Send, "moveparent");
	if (!IsValidEntity(parent)) return Plugin_Continue;
	SDKHooks_TakeDamage(parent, inflictor, attacker, damage, damagetype, weapon, damageForce, damagePosition);
	return Plugin_Stop;
}

public Action:Event_NPCHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker 	= GetClientOfUserId(GetEventInt(event, "attacker_player"));
	new damage 	= GetEventInt(event, "damageamount");
	new entity		= GetEventInt(event, "entindex");
	if (!attacker) return;
	if (!BossType[entity]) return;
	Damage[attacker] += damage;
	
	if (!Enabled) return;
	
	if (GetConVarInt(cvarTracker) & GetBitOfBossType(BossType[entity]))
	{
		if (HdmgSlots[attacker] == -1)
		{
			HdmgSlots[attacker] = GetConVarInt(cvarDefaultSlots);
			if (GetConVarBool(cvarHdmgMessage)) PrintToChat(attacker, "\x01Say \x07FF7632/hdmg <number>\x01 to change the amount of slots shown by Halloween Damage Tracker.\nSay \x07FF7632/hdmg 0\x01 to disable it.");
		}
		DrawDamageTracker();
	}
}

public Action:Timer_Second(Handle:timer)
	DrawDamageTracker();

stock DrawDamageTracker()
{
	if (NextDamageTrackerTime > GetTickedTime()) return;
	
	new maxSlots; // Was used to stop ranking clients at maxSlots, but then I realized unranked clients would not know their rank
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		if (IsFakeClient(client)) continue;
		if (!Damage[client]) continue;
		if (HdmgSlots[client] < maxSlots) continue;
		maxSlots = HdmgSlots[client];
	}
	if (!maxSlots) return;
	SetHudTextParams(0.0, 0.0, 1.1, 255, 255, 255, 255);
	
	new topDamagers[MAXPLAYERS + 1];
	new rank[MAXPLAYERS + 1];
	new filled;
	
	for (new slot; slot <= MAXPLAYERS; slot++)
	{
		new top;
		for (new client = 1; client <= MaxClients; client++)
		{
			if (rank[client]) continue;
			if (!Damage[client]) continue;
			if (Damage[client] < Damage[top]) continue;
			if (!IsClientInGame(client)) continue;
			top = client;
		}
		if (top)
		{
			topDamagers[slot] = top;
			rank[top] = slot+1;
			filled++;
		}
		else break;
	}
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!HdmgSlots[client]) continue;
		if (!Damage[client]) continue;
		if (!IsClientInGame(client)) continue;
		if (IsFakeClient(client)) continue;
		new String:msg[512];
		for (new slot; slot < HdmgSlots[client]; slot++)
		{
			if (!topDamagers[slot]) continue;
			new String:name[MAX_NAME_LENGTH + 1];
			GetClientName(topDamagers[slot], name, sizeof(name));
			new null = MAX_NAME_LENGTH - HdmgSlots[client];
			if (null < 5) null = 5;
			name[null] = '\0';
			Format(msg, sizeof(msg), "%s%s%i. %s : %i", msg, !slot ? "" : "\n", slot+1, name, Damage[topDamagers[slot]]);
		}
		if (rank[client] > HdmgSlots[client])
		{
			new String:name[MAX_NAME_LENGTH + 1];
			GetClientName(client, name, sizeof(name));
			new null = MAX_NAME_LENGTH - HdmgSlots[client];
			if (null < 5) null = 5;
			name[null] = '\0';
			Format(msg, sizeof(msg), "%s\n%i. %s : %i", msg, rank[client], name, Damage[client]);
		}
		ShowSyncHudText(client, hudTracker, msg);
	}
	
	NextDamageTrackerTime = GetTickedTime() + 0.1;
}

public OnEntityDestroyed(entity)
{
	if (entity <= 0 || entity > 2048) return;
	if (!BossType[entity]) return;
	if (!Enabled)
	{
		BossType[entity] = Boss_NotABoss;
		return;
	}
	if (!Enabled)
	{
		BossType[entity] = Boss_NotABoss;
		return;
	}
	// Filter out GetGameTime() < 2.0 here should problems arise
	
	new bool:otherBossesRemain, i;
	while ((i = FindEntityByClassname(i, "*")) != -1)
	{
		if (i == entity) continue;
		if (i <= 0 || i > 2048) continue;
		if (!BossType[i]) continue;
		otherBossesRemain = true;
		break;
	}
	
	new boss_bit 		= GetBitOfBossType(BossType[entity]);
	new HP 				= GetEntProp(entity, Prop_Data, "m_iHealth");
	new MaxHP 			= GetEntProp(entity, Prop_Data, "m_iMaxHealth");
	new WinScreen 		= GetConVarInt(cvarWinScreen);
	new PointReward	= GetConVarInt(cvarPointReward);
	
	if (WinScreen & boss_bit)
	{
		new WinSlots		= GetConVarInt(cvarWinSlots);
		
		SetHudTextParams(-1.0, 0.3, GetConVarFloat(cvarWinScreenDur), 255, 255, 255, 255);
		
		new String:bossName[96], String:prefix[32], String:header[192];
		GetConVarString(cvarBossName[BossType[entity]], bossName, sizeof(bossName));
		SeperateBossNamePrefix(bossName, bossName, sizeof(bossName), prefix, sizeof(prefix));
		if (StrEqual(prefix, "A ", false)) Format(prefix, sizeof(prefix), "The ");
		
		if (HP > 0) Format(header, sizeof(header), "%s%s had %i of %i HP left.", prefix, bossName, HP, MaxHP);
		else Format(header, sizeof(header), "%s%s %s", prefix, bossName, Boss_Tank != BossType[entity] ? "has been defeated!" : "has been destroyed!");
		
		if (!otherBossesRemain)
		{
			if (WinSlots)
			{
				new topDamagers[MAXPLAYERS + 1];
				new rank[MAXPLAYERS + 1];
				new topSlotsFilled;
				new players, totaldamage;
				for (new slot; slot < MAXPLAYERS; slot++)
				{
					new top;
					for (new client = 1; client <= MaxClients; client++)
					{
						if (rank[client]) continue;
						if (!Damage[client]) continue;
						players++;
						totaldamage += Damage[client];
						if (Damage[client] < Damage[top]) continue;
						if (!IsClientInGame(client)) continue;
						top = client;
					}
					if (top)
					{
						topDamagers[slot] = top;
						rank[top] = slot+1;
						if (WinSlots > topSlotsFilled) topSlotsFilled++;
					}
					else break;
				}
				
				new average;
				if (players) average = totaldamage / players;
				
				for (new client = 1; client <= MaxClients; client++)
				{
					if (!HdmgSlots[client]) continue;
					if (!Damage[client]) continue;
					if (!IsClientInGame(client)) continue;
					if (IsFakeClient(client)) continue;
					
					new String:msg[512];
					if (topSlotsFilled > 1) Format(msg, sizeof(msg), "%s\n \n= Top %i Damage Totals =", header, topSlotsFilled);
					else Format(msg, sizeof(msg), "%s\n \n= Most Damage =", header);
					
					for (new slot; slot < WinSlots; slot++)
					{
						if (!topDamagers[slot]) continue;
						new String:name[MAX_NAME_LENGTH + 1];
						GetClientName(topDamagers[slot], name, sizeof(name));
						name[MAX_NAME_LENGTH - WinSlots] = '\0';
						Format(msg, sizeof(msg), "%s\n%i. %s : %i", msg, slot+1, name, Damage[topDamagers[slot]]);
					}
					if (topSlotsFilled == 1 && 1 != WinSlots) Format(msg, sizeof(msg), "%s\n...And that's it.", msg);
					if (rank[client] > WinSlots)
					{
						new String:name[MAX_NAME_LENGTH + 1];
						GetClientName(client, name, sizeof(name));
						name[MAX_NAME_LENGTH - WinSlots] = '\0';
						Format(msg, sizeof(msg), "%s\n \n%i. %s : %i", msg, rank[client], name, Damage[client]);
					}
					else Format(msg, sizeof(msg), "%s\n ", msg);
					
					Format(msg, sizeof(msg), "%s\nAverage damage: %i", msg, average);
					if (PointReward && PointReward <= Damage[client]/2)
					{
						new points = (Damage[client] - (Damage[client] % PointReward)) / PointReward;
						if (points) Format(msg, sizeof(msg), "%s\nYou've earned %i point%s!", msg, points, points != 1 ? "s" : "");
					}
					ShowSyncHudText(client, hudWinScreen, msg);
				}
			}
			else // No win screen slots; let's just quickly calculate average damage and points, and show that
			{
				new players, totaldamage;
				for (new client = 1; client <= MaxClients; client++)
				{
					if (!Damage[client]) continue;
					players++;
					totaldamage += Damage[client];
				}
				
				new average;
				if (players) average = totaldamage / players;
				
				for (new client = 1; client <= MaxClients; client++)
				{
					if (!HdmgSlots[client]) continue;
					if (!Damage[client]) continue;
					if (!IsClientInGame(client)) continue;
					if (IsFakeClient(client)) continue;
					
					new String:msg[512];
					Format(msg, sizeof(msg), "%s\n \n \n \nAverage damage: %i", header, average);
					if (PointReward && PointReward <= Damage[client]/2)
					{
						new points = (Damage[client] - (Damage[client] % PointReward)) / PointReward;
						if (points) Format(msg, sizeof(msg), "%s\nYou've earned %i point%s!", msg, points, points != 1 ? "s" : "");
					}
					ShowSyncHudText(client, hudWinScreen, msg);
				}
			}
			if (PointReward)
			{
				for (new client = 1; client <= MaxClients; client++)
				{
					if (!Damage[client]) continue;
					if (PointReward > Damage[client]/2) continue;
					if (!IsClientInGame(client)) continue;
					new points = (Damage[client] - (Damage[client] % PointReward)) / PointReward;
					if (points)
					{
						new Handle:fEvent = CreateEvent("player_escort_score", true);
						SetEventInt(fEvent, "player", client);
						SetEventInt(fEvent, "points", points/2);
						FireEvent(fEvent);
					}
				}
			}
			for (new client = 1; client <= MaxClients; client++)
				Damage[client] = 0;
		}
		else // Other bosses are still active, so let's just show the header message.
		{
			for (new client = 1; client <= MaxClients; client++)
			{
				if (!HdmgSlots[client]) continue;
				if (!Damage[client]) continue;
				if (!IsClientInGame(client)) continue;
				if (IsFakeClient(client)) continue;
				
				ShowSyncHudText(client, hudWinScreen, header);
			}
		}
	}
	
	if (!otherBossesRemain)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client)) continue;
			Damage[client] = 0;
		}
	}
	
	BossType[entity] = Boss_NotABoss;
}

public Action:UserMsg_SayText2(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (!Enabled) return Plugin_Continue;
	new String:skip[2], String:msg[96], HideNotices = GetConVarInt(cvarHideNotices);
	BfReadString(bf, skip, sizeof(skip));
	BfReadString(bf, msg, sizeof(msg));
	if (HideNotices & NOTICE_PLAYERDEFEATEDHHH && StrEqual(msg, "#TF_Halloween_Boss_Killers"))
		return Plugin_Handled;
	else if (HideNotices & NOTICE_UNDERWORLDESCAPE && StrEqual(msg, "#TF_Halloween_Underworld"))
		return Plugin_Handled;
	else if (HideNotices & NOTICE_LOOTISLANDARRIVAL && StrEqual(msg, "#TF_Halloween_Loot_Island"))
		return Plugin_Handled;
	else if (HideNotices & NOTICE_SKULLISLANDESCAPE && StrEqual(msg, "#TF_Halloween_Skull_Island_Escape"))
		return Plugin_Handled;
	else if (HideNotices & NOTICE_PLAYERDEFEATEDMERASMUS && StrEqual(msg, "#TF_Halloween_Merasmus_Killers"))
		return Plugin_Handled;
	else return Plugin_Continue;
}

public Action:Event_NoticeHooks(Handle:event, const String:name[], bool:dontBroadcast)
{
	new HideNotices = GetConVarInt(cvarHideNotices);
	if (HideNotices & NOTICE_HHHAPPEARED && StrEqual(name, "pumpkin_lord_summoned", false))
		SetEventBroadcast(event, true);
	else if (HideNotices & NOTICE_HHHDEFEATED && StrEqual(name, "pumpkin_lord_killed", false))
		SetEventBroadcast(event, true);
	else if (HideNotices & NOTICE_MONOCULUSAPPEARED && StrEqual(name, "eyeball_boss_summoned", false))
		SetEventBroadcast(event, true);
	else if (HideNotices & NOTICE_MONOCULUSDEFEATED && StrEqual(name, "eyeball_boss_escaped", false))
		SetEventBroadcast(event, true);
	else if (HideNotices & NOTICE_PLAYERDEFEATEDMONOCULUS && StrEqual(name, "eyeball_boss_killer", false))
		SetEventBroadcast(event, true);
	else if (HideNotices & NOTICE_MONOCULUSDEFEATED && StrEqual(name, "eyeball_boss_killed", false))
		SetEventBroadcast(event, true);
	else if (HideNotices & NOTICE_MONOCULUSDEFEATED && StrEqual(name, "merasmus_summoned", false))
		SetEventBroadcast(event, true);
	else if (HideNotices & NOTICE_MERASMUSAPPEARED && StrEqual(name, "merasmus_summoned", false))
		SetEventBroadcast(event, true);
	else if (HideNotices & NOTICE_MERASMUSDEFEATED && StrEqual(name, "merasmus_escaped", false))
		SetEventBroadcast(event, true);
	else if (HideNotices & NOTICE_MERASMUSDEFEATED && StrEqual(name, "merasmus_killed", false))
		SetEventBroadcast(event, true);
}

public OnConVarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
	if (cvar == cvarEnabled) Enabled = bool:StringToInt(newValue);

stock GetBitOfBossType(type)
{
	switch (type)
	{
		case Boss_Horsemann: return BOSS_HHH;
		case Boss_Monoculus: return BOSS_MONO;
		case Boss_Tank: return BOSS_TANK;
		case Boss_Merasmus: return BOSS_MERASMUS;
	}
	return 0;
}

stock SeperateBossNamePrefix(String:input[], String:bossName[], namelen, String:prefix[], prefixlen)
{
	if (!StrContains(input, "The ", false))
	{
		Format(prefix, prefixlen, "The ");
		Format(bossName, namelen, input[4]);
	}
	if (!StrContains(input, "A ", false))
	{
		Format(prefix, prefixlen, "A ");
		Format(bossName, namelen, input[2]);
	}
}