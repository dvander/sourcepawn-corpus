#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

new bool:ZedTimeGoing;

/* 感染者CLASS */
#define CLASS_SMOKER		1
#define CLASS_BOOMER		2
#define CLASS_HUNTER		3
#define CLASS_SPITTER	4
#define CLASS_JOCKEY		5
#define CLASS_CHARGER	6
#define CLASS_TANK		8
#define CLASS_WITCH		7
static const String:Sound1[] = "./ui/menu_countdown.wav";

// Plugin Info
public Plugin:myinfo =
{
    name = "L4D2/ZedTime",
    author = "EvansFix",
    description = "L4D2/ZedTime",
    version = "1.0",
    url = "http://www.l4dmap.net/"//my game maps URL
};

//自动公告信息定义
#define AutoMessage "\x04[系统]\x03感谢使用慢镜头辅助插件\n\x04插件版本:\x031.0\n\x04插件作者:\x03EvansFix\n\x04插件官方:\x03www.xygamers.net 群:33793205 浩方群:373130740"



public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("only l4d2!");
	}
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("hegrenade_detonate", Event_PipeExplode);
	ZedTimeGoing = false;
	new Handle:pack;
	CreateDataTimer(30.0, Timer_AutoMsg, pack, TIMER_REPEAT);
}

public Action:Timer_AutoMsg(Handle:Timer, Handle:pack)
{
	CPrintToChatAll(AutoMessage);
}

/* 死亡事件 */
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:headshot = GetEventBool(event, "headshot");
	if(IsValidPlayer(victim))
	{
		if(GetClientTeam(victim) == 3)
		{
			new tClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
			if(tClass == CLASS_CHARGER 
			|| tClass == CLASS_JOCKEY 
			|| tClass == CLASS_SPITTER 
			|| tClass == CLASS_HUNTER 
			|| tClass == CLASS_BOOMER 
			|| tClass == CLASS_SMOKER)
			{
				if(IsValidPlayer(attacker))
				{
					if(GetClientTeam(attacker) == 2 && !IsFakeClient(attacker))
					{
						ZedTime1();
					}
				}	
			}
			if(tClass == CLASS_WITCH || tClass == CLASS_TANK)
			{
				if(IsValidPlayer(attacker))
				{
					if(GetClientTeam(attacker) == 2 && !IsFakeClient(attacker))
					{
						ZedTime1();
					}
				}	
			}
		}
	}		
	if(!IsValidPlayer(victim))
	{
		if(IsValidPlayer(attacker))
		{
			if(GetClientTeam(attacker) == 2 && !IsFakeClient(attacker))
			{
				if(headshot)
				{
					ZedTime1();
				}
			}
		}
	}
}	

public ZedTime1()
{
	ZedTimeGoing = true;
	decl i_Ent, Handle:h_pack;
	i_Ent = CreateEntityByName("func_timescale");
	DispatchKeyValue(i_Ent, "desiredTimescale", "0.2");
	DispatchKeyValue(i_Ent, "acceleration", "2.0");
	DispatchKeyValue(i_Ent, "minBlendRate", "1.0");
	DispatchKeyValue(i_Ent, "blendDeltaMultiplier", "2.0");
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "Start");
	h_pack = CreateDataPack();
	WritePackCell(h_pack, i_Ent);
	CreateTimer(0.25, ZedBlendBack, h_pack);
}

public Action:ZedBlendBack(Handle:Timer, Handle:h_pack)
{
	decl i_Ent;
	ResetPack(h_pack, false);
	i_Ent = ReadPackCell(h_pack);
	CloseHandle(h_pack);
	if(IsValidEdict(i_Ent))
	{
		AcceptEntityInput(i_Ent, "Stop");
		ZedTimeGoing = false;
	}
	else
	{
		PrintToServer("[SM] i_Ent is not a valid edict!");
	}	
}	

public Action:Event_PipeExplode(Handle:event, const String:name[], bool:dontBroadcast)
{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetClientTeam(client) == 3) return;
		if(IsFakeClient(client)) return;
		if(ZedTimeGoing == true) return;
		ZedTime1();
		EmitSoundToAll(Sound1, client);
}	

stock bool:IsValidPlayer(Client, bool:AllowBot = true, bool:AllowDeath = true)
{
	if (Client < 1 || Client > MaxClients)
		return false;
	if (!IsClientConnected(Client) || !IsClientInGame(Client))
		return false;
	if (!AllowBot)
	{
		if (IsFakeClient(Client))
			return false;
	}

	if (!AllowDeath)
	{
		if (!IsPlayerAlive(Client))
			return false;
	}	
	
	return true;
}