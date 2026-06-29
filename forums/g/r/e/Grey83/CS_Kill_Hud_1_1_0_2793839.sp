#pragma semicolon 1
#pragma newdecls required

#include <sdktools_engine>
#include <sdktools_trace>

#include l4d2_ems_hud

static const char
	PLUGIN_VERSION[] = "1.1.0 (rewritten by Grey83)",

	WEAPON[][] =
{
	"melee",

	"pistol",
	"pistol_magnum",
	"dual_pistols",

	"smg",
	"smg_silenced",
	"smg_mp5",

	"rifle",
	"rifle_ak47",
	"rifle_sg552",
	"rifle_desert",

	"pumpshotgun",
	"shotgun_chrome",
	"autoshotgun",
	"shotgun_spas",

	"hunting_rifle",
	"sniper_military",
	"sniper_scout",
	"sniper_awp",

	"pipe_bomb",

	"inferno",
	"entityflame",

	"rifle_m60",

	"grenade_launcher_projectile",

	"boomer",
	"player",

	"world",
	"worldspawn",
	"trigger_hurt"
},
	TYPE_IMG[][] =
{
	"■■‖═════>",	//0 melee
	"//^ˉˉˉ",		//1 pistol
	"Tˉˉ══",		//2 smg
	"■︻TT^ˉˉ^══",	//3 rifle
	"■︻/══^^",		//4 shotgun
	"■︻T^ˉ════",	//5 sniper
	"●ˉˉˉ",			//6 pipe bomb
	"__∫∫∫∫__",		//7 inferno, entityflame
	"■︻T^ˉ****",	//8 M60
	"︻T■■■■■",		//9 grenade_launcher_projectile

	"/*/*/",		//10 killed by push
	"*X*",			//11 killed by world
	"*=*彡",			//12 killed by special infected,
	"→‖→",			//13 kill behind wall
	"→⊙",			//14 headshot
},
	FRAME[][] =
{
	"===================",
	"★",
};

enum
{
	T_Melee,	// melee
	T_Pistol,	// pistol, pistol_magnum, dual_pistols
	T_Smg,		// smg, smg_silenced, smg_mp5
	T_Rifle,	// rifle, rifle_ak47, rifle_sg552, rifle_desert
	T_Shotgun,	// pumpshotgun, shotgun_chrome, autoshotgun, shotgun_spas
	T_Sniper,	// hunting_rifle, sniper_military, sniper_scout, sniper_awp
	T_Boomb,	// pipe boomb
	T_Fire,		// inferno, entityflame
	T_M60,		// rifle_m60
	T_Grenade,	// grenade_launcher_projectile
	T_Push,		// boomer, player killed by push
	T_World,

	T_Special,
	T_Through,
	T_HS
};

static const int TYPE[] =
{
	T_Melee,
	T_Pistol, T_Pistol, T_Pistol,
	T_Smg, T_Smg, T_Smg,
	T_Rifle, T_Rifle, T_Rifle, T_Rifle,
	T_Shotgun, T_Shotgun, T_Shotgun, T_Shotgun,
	T_Sniper, T_Sniper, T_Sniper, T_Sniper,
	T_Boomb,
	T_Fire, T_Fire,
	T_M60,
	T_Grenade,
	T_Push, T_Push,
	T_World, T_World, T_World	// 11
};

// follow the inc to set the pos.
static const float g_HUDpos[][] =
{
	// hostname
	{0.00, 0.00, 1.00, 0.04}, // HUD_LEFT_TOP
	// info
	{0.00, 0.00, 0.26, 0.06},
	// player list
	{0.00, 0.06, 0.23, 0.04},
	{0.00, 0.09, 0.23, 0.04},
	{0.00, 0.12, 0.23, 0.04},
	{0.00, 0.15, 0.23, 0.04},
	{0.00, 0.18, 0.23, 0.04},
	{0.00, 0.21, 0.23, 0.04},
	{0.00, 0.24, 0.23, 0.04},
	{0.00, 0.27, 0.23, 0.04},
	// kill list
	{0.00, 0.00, 1.00, 0.04},
	{0.00, 0.04, 1.00, 0.04},
	{0.00, 0.08, 1.00, 0.04},
	{0.00, 0.12, 1.00, 0.04},
	{0.00, 0.16, 1.00, 0.04},
};

StringMap
	g_weapon_name;
ArrayList
	g_hud_killinfo;
Handle
	g_timer_player_list;
int
	iListSize,
	iMaxPlayers = -1,
	g_player_num,
	g_player_killspecial[MAXPLAYERS],
	g_player_headshot[MAXPLAYERS];

public Plugin myinfo =
{
	name		= "HUD on L4D2",
	author		= "Miuwiki & special thanks \"sorall\" provide the inc.",
	description	= "HUD with player list & cs kill info list.",
	version		= PLUGIN_VERSION,
	url			= "http://www.miuwiki.site"
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeathInfo);
	HookEvent("round_start", Event_RoundStartInfo);
	HookEvent("round_end", Event_RoundEndinfo);

	g_weapon_name = new StringMap();
	for(int i; i < sizeof(WEAPON); i++) g_weapon_name.SetString(WEAPON[i], TYPE_IMG[TYPE[i]]);
	g_hud_killinfo = new ArrayList(128);

	ConVar cvar = CreateConVar("l4d2_max_player_list", "8", "Max count of the player list display", _,true, _, true,8.0);
	cvar.AddChangeHook(CVarChange_List);
	iListSize = cvar.IntValue;

	if(!(cvar = FindConVar("sv_maxplayers")))
		return;

	cvar.AddChangeHook(CVarChange_Max);
	iMaxPlayers = cvar.IntValue;
}

public void CVarChange_List(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iListSize = cvar.IntValue;
}

public void CVarChange_Max(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iMaxPlayers = cvar.IntValue;
}
//地图开始的时候重置人数，因为connected必定只会在mapstart的时候触发。round_start玩家已经在游戏了，不会触发人数加减。
public void OnMapStart()
{
	EnableHUD();
}

public void Event_RoundStartInfo(Event event,const char[] name,bool dontboradcast)
{
	g_timer_player_list = CreateTimer(1.0, Timer_DisplayHUDInfo, _, TIMER_REPEAT);
}
//回合结束跟地图结束，两者只会同时生效一个。因此为了保证计时器和右上角hud正确去除，需要写两次。
public void OnMapEnd()
{
	for(int i; i < MaxClients; i++) g_player_killspecial[i] = g_player_headshot[i] = 0;
	g_hud_killinfo.Clear();
	g_player_num = 0;
	delete g_timer_player_list;
}

public void Event_RoundEndinfo(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}
//玩家连接以及离开。
public void OnClientConnected(int client)
{
	if(!IsFakeClient(client))
	{
		g_player_num++;						//玩家数量
		g_player_killspecial[client] = 0;	//新进玩家属性：killspecial
		g_player_headshot[client] = 0;		//新进玩家属性，爆头
	}
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client))
	{
		g_player_num--;
		g_player_killspecial[client] = g_player_headshot[client] = 0;
	}
}
//通过playerdeath事件对击杀进行统计
public void Event_PlayerDeathInfo(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(victim < 1 || victim > MaxClients || !IsClientInGame(victim))
		return;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker < 0 || attacker > MaxClients || !IsClientInGame(victim))
		return;

	static char killinfo[128];
	if(attacker) // kill by world of fall 
	{
		FormatEx(killinfo,sizeof(killinfo),"	%s  %N", TYPE_IMG[T_World], victim);
		DisplayKillList(killinfo);
		return;
	}

	if(GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2) // kill by specials.
	{
		FormatEx(killinfo,sizeof(killinfo), "%N  %s  %N", attacker, TYPE_IMG[T_Special], victim);
		DisplayKillList(killinfo);
		return;
	}

	if(GetClientTeam(victim) == 3)
	{
		g_player_killspecial[attacker]++; // attacker kill +1
	}

	char weapon_type[28];
	event.GetString("weapon", weapon_type, sizeof(weapon_type));
	// add kill type
	if(!strcmp("world", weapon_type) || !strcmp(weapon_type, "worldspawn") || !strcmp(weapon_type, "trigger_hurt"))
	{
		FormatEx(killinfo, sizeof(killinfo), "	%s  %N", TYPE_IMG[T_World], victim);
		DisplayKillList(killinfo);
		return;
	}

	if(!g_weapon_name.GetString(weapon_type, weapon_type, sizeof(weapon_type)))
		return;

	if(event.GetBool("headshot"))
	{
		g_player_headshot[attacker]++;

		if(IsKilledBehindWall(attacker, victim))
			FormatEx(killinfo, sizeof(killinfo), "%N  %s %s %s  %N", attacker, TYPE_IMG[T_Through], TYPE_IMG[14], weapon_type, victim);
		else FormatEx(killinfo, sizeof(killinfo), "%N  %s %s  %N", attacker, TYPE_IMG[T_HS], weapon_type, victim);
	}
	else
	{
		if(IsKilledBehindWall(attacker, victim))
			FormatEx(killinfo, sizeof(killinfo), "%N  %s %s  %N", attacker, TYPE_IMG[T_Through], weapon_type, victim);
		else FormatEx(killinfo, sizeof(killinfo), "%N  %s  %N", attacker, weapon_type, victim);
	}

	DisplayKillList(killinfo);
}

public Action Timer_DisplayHUDInfo(Handle timer)
{
	// hostname
	static char HostName[128];
	GetConVarString(FindConVar("hostname"), HostName, sizeof(HostName));
	HUDPlaceByIndex(0, HUD_FLAG_ALIGN_CENTER, HostName);

	// info
	static char title[128];
	int maxplayers = iMaxPlayers != -1 ? MaxClients : iMaxPlayers;
	FormatEx(title, sizeof(title),"%s\n%s击杀/爆头  当前玩家: [%d/%d]%s\n%s", FRAME[0], FRAME[1], g_player_num, maxplayers, FRAME[1], FRAME[0]);
	HUDPlaceByIndex(1, HUD_FLAG_ALIGN_CENTER, title);

	// playerlist
	DisplayPlayerList();

	return Plugin_Continue;
}

stock void DisplayPlayerList()
{
	if(!iListSize)
		return;

	//循环出有效玩家，并写入编号。
	//survivor用于更好排序，不用在排序函数判断玩家合法性。
	int i = 1, total, survivor[MAXPLAYERS];
	for(; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2
		&&(!IsPlayerAlive(i) || !IsClientObserver(i)))	//排除旁观者.
				survivor[total++] = i;
	//survivor[players]数组,通过击杀数量函数killinfo进行排序
	SortCustom1D(survivor, sizeof(survivor), SortKillInfo);
	static char txt[128];
	for(i = 0; i < total && i <= iListSize; i++)
	{
		// 最多只能8个了，没插槽了。
		FormatEx(txt, sizeof(txt), "%s%d：%d/%d→%N",
				FRAME[1], i+1, g_player_killspecial[survivor[i]], g_player_headshot[survivor[i]], survivor[i]);
		HUDPlaceByIndex(i+2, IsPlayerAlive(survivor[i]) ? HUD_FLAG_ALIGN_LEFT : HUD_FLAG_ALIGN_LEFT|HUD_FLAG_BLINK, txt);
	}
}

stock void DisplayKillList(const char[] info)
{
	static char kill_list[128];
	FormatEx(kill_list, sizeof(kill_list), "%s", info);
	g_hud_killinfo.PushString(kill_list);

	switch(g_hud_killinfo.Length)
	{
		case 1:
			HUDPlaceByIndex(10, HUD_FLAG_ALIGN_RIGHT, kill_list);
		case 2:
			HUDPlaceByIndex(11, HUD_FLAG_ALIGN_RIGHT, kill_list);
		case 3:
			HUDPlaceByIndex(12, HUD_FLAG_ALIGN_RIGHT, kill_list);
		case 4:
			HUDPlaceByIndex(13, HUD_FLAG_ALIGN_RIGHT, kill_list);
		case 5:
			HUDPlaceByIndex(14, HUD_FLAG_ALIGN_RIGHT, kill_list);
		default:
		{
			g_hud_killinfo.Erase(0);
			for(int i = 10; i < 15; i++)
			{
				g_hud_killinfo.GetString(i-10, kill_list, sizeof(kill_list));
				HUDPlaceByIndex(i, HUD_FLAG_ALIGN_RIGHT, kill_list);
			}
		}
	}
}

stock bool IsKilledBehindWall(int attacker, int client)
{
	static float vPos_a[3], vPos_c[3];
	GetClientEyePosition(attacker, vPos_a);
	GetClientEyePosition(client, vPos_c);

	Handle hTrace = TR_TraceRayFilterEx(vPos_a, vPos_c, MASK_PLAYERSOLID, RayType_EndPoint, TraceRayNoPlayers, client);
	if(hTrace)
	{
		if(TR_DidHit(hTrace))
		{
			delete hTrace;
			return true;
		}

		delete hTrace;
	}
	return false;
}

public bool TraceRayNoPlayers(int entity, int mask, any data)
{
	return entity != data &&(entity < 1 || entity > MaxClients);
}
// sort the kill 
public int SortKillInfo(int elem1, int elem2, const int[] array, Handle hndl)
{
	if(g_player_killspecial[elem1] > g_player_killspecial[elem2])
		return -1;

	if(g_player_killspecial[elem2] > g_player_killspecial[elem1])
		return 1;

	if(elem1 > elem2)
		return -1;

	if(elem2 > elem1)
		return 1;

	return 0;
}

stock void HUDPlaceByIndex(int slot, int flags, const char[] dataval)
{
	HUDSetLayout(slot, HUD_FLAG_TEXT|HUD_FLAG_NOBG|flags, "%s", dataval);
	HUDPlace(slot, g_HUDpos[slot][0], g_HUDpos[slot][1], g_HUDpos[slot][2], g_HUDpos[slot][3]);
//	HUDPlace(MY_HUD::index,g_HUDpos[index][0],g_HUDpos[index][1],g_HUDpos[index][2],g_HUDpos[index][3]);
}