#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION  "indev"
public Plugin:myinfo = {
	name = "Clocktown Mono Spawner",
	author = "MasterOfTheXP & Moge-ko",
	description = "Spawns Monoculus on top of the tower during the Final Hours.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

new Relays[6];
new DayCount, bool:Nighttime, SecondsCount;
new HourCount, HourSeconds;
new bool:WatchActive; // Only true if the time is validated.
new String:Map[PLATFORM_MAX_PATH];
new bool:Enabled;

new Handle:cvarHealth;
new Handle:cvarHealthPerPlayer;
new Handle:cvarHealthPerLevel;

public OnPluginStart()
{
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEntityOutput("logic_relay", "OnTrigger", OnTrigger);
	Enabled = (StrContains(Map, "trade_clocktown_", false) == 0 && !StrEqual(Map, "trade_clocktown_b1", false));
	if (!Enabled) return;
	// Late loading
	FindTimers();
}

public OnMapStart()
{
	GetCurrentMap(Map, sizeof(Map));
	Enabled = (StrContains(Map, "trade_clocktown_", false) == 0 && !StrEqual(Map, "trade_clocktown_b1", false));
	if (!Enabled) return;
	CreateTimer(1.0, Timer_Second, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnConfigsExecuted()
{
	cvarHealth = FindConVar("tf_eyeball_boss_health_base");
	cvarHealthPerPlayer = FindConVar("tf_eyeball_boss_health_per_player");
	cvarHealthPerLevel = FindConVar("tf_eyeball_boss_health_per_level");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return;
	FindTimers();
	DayCount = 1;
	SecondsCount = 0;
	HourCount = 6;
	HourSeconds = 0;
	Nighttime = false;
	WatchActive = true;
}

public OnTrigger(const String:output[], caller, activator, Float:delay)
{
	if (!Enabled) return;
	if (caller == Relays[0]) DayCount = 1;
	else if (caller == Relays[2]) DayCount = 2;
	else if (caller == Relays[4]) DayCount = 3;
	else if (caller == Relays[1]) DayCount = 11;
	else if (caller == Relays[3]) DayCount = 12;
	else if (caller == Relays[5]) DayCount = 13;
	else return;
	SecondsCount = 0;
	HourCount = 6;
	HourSeconds = 0;
	if (DayCount > 3)
	{
		DayCount -= 10;
		Nighttime = true;
	}
	else Nighttime = false;
	WatchActive = true;
}

public Action:Timer_Second(Handle:timer)
{
	if (!WatchActive) return;
	SecondsCount++;
	if (++HourSeconds >= 45)
	{
		if (++HourCount == 13) HourCount -= 12;
		HourSeconds = 0;
	}
	if (DayCount == 3 && HourCount == 12 && !HourSeconds && Nighttime)
	{
		new BaseHealth = GetConVarInt(cvarHealth), HealthPerPlayer = GetConVarInt(cvarHealthPerPlayer), HealthPerLevel = GetConVarInt(cvarHealthPerLevel);
		SetConVarInt(cvarHealth, 4200), SetConVarInt(cvarHealthPerPlayer, 300), SetConVarInt(cvarHealthPerLevel, 2000);
		new Ent = CreateEntityByName("eyeball_boss"); 
		TeleportEntity(Ent, Float:{-290.0, -327.0, -92.0}, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(Ent, "teamnum", "5")
		DispatchSpawn(Ent);
		SetEntProp(Ent, Prop_Send, "m_iTeamNum", 5)
		SetConVarInt(cvarHealth, BaseHealth), SetConVarInt(cvarHealthPerPlayer, HealthPerPlayer), SetConVarInt(cvarHealthPerLevel, HealthPerLevel);
	}
}

stock FindTimers() 
{
	new Ent = -1;
	while ((Ent = FindEntityByClassname(Ent, "logic_relay")) != -1)
	{ 
		new String:entName[35];
		GetEntPropString(Ent, Prop_Data, "m_iName", entName, sizeof(entName));
		if (StrEqual(entName, "day1relay")) Relays[0] = Ent;
		else if (StrEqual(entName, "night1relay")) Relays[1] = Ent;
		else if (StrEqual(entName, "day2relay")) Relays[2] = Ent;
		else if (StrEqual(entName, "night2relay")) Relays[3] = Ent;
		else if (StrEqual(entName, "day3relay")) Relays[4] = Ent;
		else if (StrEqual(entName, "night3relay")) Relays[5] = Ent;
	}
}