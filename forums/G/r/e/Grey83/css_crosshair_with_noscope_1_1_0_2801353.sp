#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools_stringtables>

static const char
	PL_NAME[]	= "Crosshair With Noscope",
	PL_VER[]	= "1.1.0 (rewritten by Grey83)",

	OVERLAY[][]	= {"blutak/blutakk", "blutak/blutakk2"};

Handle
	hTimer[MAXPLAYERS+1];
bool
	bEnable[MAXPLAYERS+1],	//启动或禁用插件变量
	bScope[MAXPLAYERS+1],	//值为true则显示狙击枪准心
	bDot[MAXPLAYERS+1];		//狙击枪准心样式，1为红点，2为仿原版游戏绿色十字线
int
	m_iFOV;
float
	fTime1,	//暂时禁用准心时间（适用于击中反馈插件）
	fTime2;	//暂时禁用准心时间（适用于击杀反馈插件）

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if((m_iFOV = FindSendPropInfo("CBasePlayer","m_iFOV")) < 1)
	{
		FormatEx(error, err_max, "Can't find offset 'CBasePlayer::m_iFOV'!");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Display the crosshair when the sniper rifle is not on the scope",
	author		= "Mrs. Nesbitt And cjsrk",
	url			= "https://forums.alliedmods.net/showthread.php?t=342204"
}

public void OnPluginStart()
{
	//设置配置文件
	CreateConVar("sm_crosshair_with_noscope_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_NOTIFY);

	ConVar cvar;
	cvar = CreateConVar("sm_crosshair_with_noscope_enable", "1", "Whether to enable the plugin (1: enabled; 0: disabled)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Enable);
	bEnable[0] = cvar.BoolValue;

	cvar = CreateConVar("sm_crosshair_with_noscope_type", "1", "The crosshair style of the sniper rifle (1 is the red dot, and 2 is the green crosshair imitating CSS)", _, true, 1.0, true, 2.0);
	cvar.AddChangeHook(CVarChange_Dot);
	bDot[0] = cvar.IntValue == 1;

	cvar = CreateConVar("sm_crosshair_with_noscope_time", "0.0", "The time to temporarily disable the crosshair when injuring the enemy (it is consistent with the time displayed by the hit feedback plug-in, which is generally 0.15 or 0.1. If you do not install the hit feedback plugin, please fill in 0)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Time1);
	fTime1 = cvar.FloatValue;

	cvar = CreateConVar("sm_crosshair_with_noscope_time2", "0.0", "The time to temporarily disable the crosshair when killing an enemy (same as the display time of the kill feedback plug-in, and the display time of the kill feedback plugin is generally 1.0-3.0. If you do not install the kill feedback plugin, please fill in 0)", _, true, _, true, 3.0);
	cvar.AddChangeHook(CVarChange_Time2);
	fTime2 = cvar.FloatValue;

	AutoExecConfig(true, "crosshair_with_noscope");

	RegConsoleCmd("crosshair_switch", Cmd_ToggleScope);
	RegConsoleCmd("crosshair_type", Cmd_SwichType);
}

public void CVarChange_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	static bool hooked;
	if((bEnable[0] = cvar.BoolValue) == hooked) return;

	if((hooked ^= true))
	{
		HookEvent("round_freeze_end", Event_Start, EventHookMode_PostNoCopy);
		HookEvent("player_death", Event_Death);
		HookEvent("player_hurt", Event_Hurt);
		Event_Start(null, "", false);
		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
			SDKHook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	}
	else
	{
		UnhookEvent("round_freeze_end", Event_Start, EventHookMode_PostNoCopy);
		UnhookEvent("player_death", Event_Death);
		UnhookEvent("player_hurt", Event_Hurt);

		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SDKUnhook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
			if(bScope[i]) ClientCommand(i, "r_screenoverlay 0");
			if(hTimer[i]) delete hTimer[i];
		}
	}
}

public void CVarChange_Dot(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bDot[0] = cvar.IntValue == 1;
}

public void CVarChange_Time1(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fTime1 = cvar.FloatValue;
}

public void CVarChange_Time2(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fTime2 = cvar.FloatValue;
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	PrecacheDecal(OVERLAY[0], true);
	FormatEx(buffer, sizeof(buffer), "materials/%s.vmt", OVERLAY[0]);
	AddFileToDownloadsTable(buffer);
	FormatEx(buffer, sizeof(buffer), "materials/%s.vtf", OVERLAY[0]);
	AddFileToDownloadsTable(buffer);

	PrecacheDecal(OVERLAY[1], true);
	FormatEx(buffer, sizeof(buffer), "materials/%s.vmt", OVERLAY[1]);
	AddFileToDownloadsTable(buffer);
	FormatEx(buffer, sizeof(buffer), "materials/%s.vtf", OVERLAY[1]);
	AddFileToDownloadsTable(buffer);

	// 清除作弊标志函数
	int flags = GetCommandFlags("r_screenoverlay");
	if(flags != INVALID_FCVAR_FLAGS) SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);

	ConVar cvar = FindConVar("r_screenoverlay");
	if(cvar) SetConVarFlags(cvar, (GetConVarFlags(cvar) & ~FCVAR_CHEAT));
}

public void OnClientPutInServer(int client)
{
	if(bEnable[0] && !IsFakeClient(client)) SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

public void OnClientDisconnect(int client)
{
	bDot[client] = bDot[0];
	bEnable[client] = true;
	if(hTimer[client]) delete hTimer[client];
}

//如果切换到其他武器，则清除准心
public void OnWeaponSwitch(int client, int weapon)
{
	if(hTimer[client]) delete hTimer[client];
	if(bEnable[client] && !(bScope[client] = WithScope(weapon))) ClientCommand(client, "r_screenoverlay 0");
}

public void OnGameFrame()
{
	if(!bEnable[0])
		return;

	for(int i = 1, fov; i <= MaxClients; i++)
		if(bEnable[i] && bScope[i] && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1 && IsPlayerAlive(i))
			//如果该狙击步枪没有开镜，则显示准心bDot
			ClientCommand(i, "r_screenoverlay %s", (fov = GetEntData(i, m_iFOV)) != 15 && fov != 40 && fov != 10 ? "0" : bDot ? OVERLAY[0] : OVERLAY[1]);
}

public void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1 && IsPlayerAlive(i)) bScope[i] = WithScope(i);
}

public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	// 玩家死后消除准心
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(!victim)
		return;

	if(bScope[victim])
	{
		bScope[victim] = false;
		ClientCommand(victim, "r_screenoverlay 0");
	}

	// 击杀敌人后短暂禁用准心，避免和击杀反馈插件冲突
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(!attacker || attacker == victim || !bScope[attacker]
	|| IsFakeClient(attacker) || IsPlayerAlive(attacker))
		return;

//	PrintToChat(attacker, "击杀！");
	if(hTimer[attacker]) delete hTimer[attacker];
	bScope[attacker] = false;
	hTimer[attacker] = CreateTimer(fTime2, Timer_Clean, attacker);
}

//击中敌人后短暂禁用准心，避免和击中反馈插件冲突
public void Event_Hurt(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("health") < 1)
		return;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(!attacker || attacker == GetClientOfUserId(event.GetInt("userid")) || IsFakeClient(attacker)
	|| GetClientTeam(attacker) < 2 || !IsPlayerAlive(attacker))
		return;

	if(hTimer[attacker]) delete hTimer[attacker];
	bScope[attacker] = false;
	hTimer[attacker] = CreateTimer(fTime1, Timer_Clean, attacker);
}

public Action Timer_Clean(Handle timer, int client)
{
	bScope[client] = true;
	hTimer[client] = null;
	return Plugin_Stop;
}

public Action Cmd_ToggleScope(int client, int args)
{
	if(!bEnable[0] || !client || IsFakeClient(client))
		return Plugin_Handled;

	if((bEnable[client] ^= true))
	{
		PrintToChat(client, "Crosshair is enabled");	// "狙击枪十字准心已开启！"
		bScope[client] = WithScope(client);
	}
	else
	{
		if(hTimer[client]) delete hTimer[client];
		if(bScope[client]) ClientCommand(client, "r_screenoverlay 0");
		PrintToChat(client, "Crosshair is disabled");	// "狙击枪十字准心已关闭！"
	}

	return Plugin_Handled;
}

public Action Cmd_SwichType(int client, int args)
{
	if(client) PrintToChat(client, (bDot[client] ^= true) ? "Switched to crosshair!" : "Switched to dot!");	// "狙击枪十字准心设置为仿原版游戏样式！" : "狙击枪十字准心设置为红点样式！"

	return Plugin_Handled;
}

bool WithScope(int entity)
{
	static char wpn[16];
	if(0 < entity && entity <= MaxClients)
		GetClientWeapon(entity, wpn, sizeof(wpn));
	else if(MaxClients < entity)
		GetEdictClassname(entity, wpn, sizeof(wpn));
	else return false;

	return !strcmp("awp", wpn) || !strcmp("g3sg1", wpn) || !strcmp("scout", wpn) || !strcmp("sg550", wpn);
}