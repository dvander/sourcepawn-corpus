/* Create By 游而戏之 2023/04/05 19:50 */
#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>

#define LOS 	0 			/* 失败团灭 */
#define WIN 	1 			/* 终章通关 */
#define	END 	10.0		/* 终章换图延时请勿设置过长 */
#define ACE		5.0			/* 团灭换图延时请尽可能设短 */

static char StartMap[][][64] =
{
	{"c1m1_hotel",				"c1-死亡中心"},
	{"c2m1_highway",			"c2-黑色狂欢节"},//1
	{"c3m1_plankcountry",		"c3-沼泽激战"},
	{"c4m1_milltown_a",			"c4-暴风骤雨"},
	{"c5m1_waterfront",			"c5-教区"},
	{"c6m1_riverbank",			"c6-短暂时刻"},
	{"c7m1_docks",				"c7-牺牲"},
	{"c8m1_apartment",			"c8-毫不留情"},
	{"c9m1_alleys",				"c9-坠机险途"},
	{"c10m1_caves",				"c10-死亡丧钟"},
	{"c11m1_greenhouse",		"c11-静寂时分"},
	{"c12m1_hilltop",			"c12-血腥收获"},
	{"c13m1_alpinecreek",		"c13-刺骨寒溪"},
	{"c14m1_junkyard",			"c14-临死一搏"}
};
static char FinaleMap[][64] =
{
	"c1m4_atrium",
	"c2m5_concert",
	"c3m4_plantation",
	"c4m5_milltown_escape",
	"c5m5_bridge",
	"c6m3_port",
	"c7m3_port",
	"c8m5_rooftop",
	"c9m2_lots",
	"c10m5_houseboat",
	"c11m5_runway",
	"c12m5_cornfield",
	"c13m4_cutthroatcreek",
	"c14m2_lighthouse"
};


int Limt	= 3;		/* 任意章节团灭多少次后换图 */
int Count;

public Plugin myinfo =
{
	name 		= "地图|自动换图",
	description = "让智障流行",
	author 		= "Ryanx, 24の节气",
	version 	= "2.B",
	url 		= "-"
};

public void OnPluginStart()
{
	HookEvent("finale_win",   	Event_FinaleWin);
	HookEvent("mission_lost", 	Event_MissonLos);
}
public void OnMapStart() {Count = 0;}

void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast) {CheckMap(WIN);}
void Event_MissonLos(Event event, const char[] name, bool dontBroadcast)
{
	Count ++;

	if(Count == Limt) CheckMap(LOS);
}

void CheckMap(int type)
{
	int e = -1;
	static int maxindex = sizeof FinaleMap - 1;

	char map[128];
	GetCurrentMap(map, sizeof map);

	/* 和官方最终章节地图名列表匹配 若是官图c14m2 换官图c1m1 */
	for(int i; i <= maxindex; i++)
	{
		if(strcmp(map, FinaleMap[i], false) == 0)
		{
			e = (i == maxindex ? 0 : i + 1);

			break;
		}
	}

	/* 团灭换图执行时间必须短，所以...... */
	float interval = (type ? END : ACE);
	int radnom = GetRandomInt(0, maxindex);
	int mapnum = (e == -1 ? radnom : e);

	if(type == LOS) PrintToChatAll("\x04团灭次数 | \x05%d次", Limt);
	PrintToChatAll("\x04自动换图 | \x05%d秒\n\x04下一章节 | \x05%s", RoundToNearest(interval), StartMap[mapnum][1]);

	CreateTimer(interval, Timer_ChangeMap, mapnum);
}

Action Timer_ChangeMap(Handle timer, int num) {ServerCommand("changelevel %s", StartMap[num][0]); return Plugin_Continue;}