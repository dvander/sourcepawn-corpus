#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sourcemod>
	
public Plugin:myinfo = 
{
	name = "Crosshair With Noscope",
	author = "Mrs. Nesbitt And cjsrk",
	description = "An aiming reticle designed for Goldeneye: Source",
	url = ""
};

new Handle:cvarEnable6;
new Handle:cvarCrosshairType;
new Handle:cvarUnvisibleTime;
new Handle:cvarUnvisibleTime2;
bool isEnabled6 = true;    //启动或禁用插件变量
int CrosshairType = 1;    //狙击枪准心样式，1为红点，2为仿原版游戏绿色十字线
float UnvisibleTime = 0.0;    //暂时禁用准心时间（适用于击中反馈插件）
float UnvisibleTime2 = 0.0;    //暂时禁用准心时间（适用于击杀反馈插件）
new m_iFOV;
bool PlayersScopeFalgs[128] = {false};    //值为true则显示狙击枪准心
new String:DamageEventName[16] = "dmg_armor";


public OnPluginStart()
{
	//设置配置文件
	CreateConVar("sm_crosshair_with_noscope_version", "1.0.0", "plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable6 = CreateConVar("sm_crosshair_with_noscope_enable", "1", "Whether to enable the plugin (1: enabled; 0: disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarCrosshairType = CreateConVar("sm_crosshair_with_noscope_type", "1", "The crosshair style of the sniper rifle (1 is the red dot, and 2 is the green crosshair imitating CSS)", FCVAR_PLUGIN, true, 1.0, true, 2.0);
	cvarUnvisibleTime = CreateConVar("sm_crosshair_with_noscope_time", "0.0", "The time to temporarily disable the crosshair when injuring the enemy (it is consistent with the time displayed by the hit feedback plug-in, which is generally 0.15 or 0.1. If you do not install the hit feedback plugin, please fill in 0)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarUnvisibleTime2 = CreateConVar("sm_crosshair_with_noscope_time2", "0.0", "The time to temporarily disable the crosshair when killing an enemy (same as the display time of the kill feedback plug-in, and the display time of the kill feedback plugin is generally 1.0-3.0. If you do not install the kill feedback plugin, please fill in 0)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	AutoExecConfig(true, "plugin.crosshair_with_noscope");
	HookConVarChange(cvarEnable6, CvarChange);
	HookConVarChange(cvarCrosshairType, CvarChange);
	HookConVarChange(cvarUnvisibleTime, CvarChange);
	HookConVarChange(cvarUnvisibleTime2, CvarChange);
	
	m_iFOV = FindSendPropOffs("CBasePlayer","m_iFOV");
	RegConsoleCmd("crosshair_switch",Cmd_CreateAnaconda4);
	RegConsoleCmd("crosshair_type",Cmd_CreateAnaconda5);
	
	HookEvent("round_start", RoundStart_New, EventHookMode_Post);
	HookEvent("player_death", PlayerDeath2, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt2, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath2, EventHookMode_Post);
}


public OnMapStart()
{
	AddFileToDownloadsTable("materials/blutak/blutakk.vmt");
	AddFileToDownloadsTable("materials/blutak/blutakk.vtf");
	AddFileToDownloadsTable("materials/blutak/blutakk2.vmt");
	AddFileToDownloadsTable("materials/blutak/blutakk2.vtf");
	PrecacheDecal("blutak/blutakk", true);
	PrecacheDecal("blutak/blutakk2", true);
	
	UnlockConsoleCommandAndConvar("r_screenoverlay");
}


//读取配置文件的cvar的值
public OnConfigsExecuted()
{
	isEnabled6 = GetConVarBool(cvarEnable6);
	CrosshairType = GetConVarInt(cvarCrosshairType);
	UnvisibleTime = GetConVarFloat(cvarUnvisibleTime);
	UnvisibleTime2 = GetConVarFloat(cvarUnvisibleTime2);
}

//cvar值变化时的响应数组
public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(convar == cvarEnable6)
	{
		if(StringToInt(newValue) == 1)
		{
			isEnabled6 = true;
		}
		else
		{
			isEnabled6 = false;
		}
	}
	if(convar == cvarCrosshairType)
	{
		if(StringToInt(newValue) == 1)
		{
			CrosshairType = 1;
		}
		else
		{
			CrosshairType = 2;
		}
	}
	if(convar == cvarUnvisibleTime)
	{
		if(StringToFloat(newValue) >= 0 && StringToFloat(newValue) <= 1)
		{
			UnvisibleTime = StringToFloat(newValue);
		}
	}
	if(convar == cvarUnvisibleTime2)
	{
		if(StringToFloat(newValue) >= 0 && StringToFloat(newValue) <= 3)
		{
			UnvisibleTime2 = StringToFloat(newValue);
		}
	}
}


public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip5);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch3);
}


public Action:Cmd_CreateAnaconda4(Client,Args){
	if(!Client)Client=1;
	if(isEnabled6 == false)
	{
		isEnabled6 = true;
		PrintToChat(Client, "Sniper crosshairs are on！");
		if (IsClient(Client, true) && !IsFakeClient(Client))
		{
			new currentWeapon = GetEntPropEnt(Client, Prop_Send, "m_hActiveWeapon");
			if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
				return;
			decl String:sWeapon[32];
			GetEdictClassname(currentWeapon, sWeapon, sizeof(sWeapon));
			if(StrEqual("weapon_scout", sWeapon) || StrEqual("weapon_awp", sWeapon) || StrEqual("weapon_sg550", sWeapon) || StrEqual("weapon_g3sg1", sWeapon))
			{
				PlayersScopeFalgs[Client] = true;
			}
		}
	}
	else
	{
		isEnabled6 = false;
		ClientCommand(Client, "r_screenoverlay 0");
		PrintToChat(Client, "Sniper crosshairs are off！");
	}
}


public Action:Cmd_CreateAnaconda5(Client,Args){
	if(!Client)Client=1;
	if(CrosshairType == 1)
	{
		CrosshairType = 2;
		PrintToChat(Client, "The sniper rifle crosshair is set to imitate CSS green crosshair style！");
	}
	else
	{
		CrosshairType = 1;
		PrintToChat(Client, "Sniper rifle crosshairs set to red dot style！");
	}
}


bool:IsClient(Client, bool:Alive)
{
	return Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && (Alive && IsPlayerAlive(Client));
}


public Action:OnWeaponEquip5(client, weapon)
{
	if (isEnabled6 == true && IsClient(client, true) && !IsFakeClient(client)) 
	{
		decl String:sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
		if(StrEqual("weapon_scout", sWeapon) || StrEqual("weapon_awp", sWeapon) || StrEqual("weapon_sg550", sWeapon) || StrEqual("weapon_g3sg1", sWeapon))
		{
			PlayersScopeFalgs[client] = true;
		}
	}
}


//如果切换到其他武器，则清除准心
public Action:OnWeaponSwitch3(client, weapon)
{
	if (isEnabled6 == true && IsClient(client, true) && !IsFakeClient(client)) 
	{
		decl String:sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
		if(StrEqual("weapon_scout", sWeapon) || StrEqual("weapon_awp", sWeapon) || StrEqual("weapon_sg550", sWeapon) || StrEqual("weapon_g3sg1", sWeapon))
		{
			PlayersScopeFalgs[client] = true;
		}
		else
		{
			PlayersScopeFalgs[client] = false;
			ClientCommand(client, "r_screenoverlay 0");
		}
	}
}


public OnGameFrame()
{
	if(isEnabled6 == true)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			//new client = GetClientOfUserId(i);
			if(IsClientInGame(i) && IsClientConnected(i) && IsPlayerAlive(i) && !IsFakeClient(i))
			{
				new i_playerTeam = GetClientTeam(i);
				if(i_playerTeam > 1)
				{
					if(PlayersScopeFalgs[i] == true)
					{
						//如果该狙击步枪没有开镜，则显示准心CrosshairType
						new i_playerFOV;
						i_playerFOV = GetEntData(i, m_iFOV);
						if((i_playerFOV != 15) && (i_playerFOV != 40) && (i_playerFOV != 10))
						{
							if(CrosshairType == 1)
								ClientCommand(i, "r_screenoverlay blutak/blutakk");
							else
								ClientCommand(i, "r_screenoverlay blutak/blutakk2");
						}
						else
							ClientCommand(i, "r_screenoverlay 0");
					}
								
				}			
			}
		}
	}
}


//玩家死后消除准心
public PlayerDeath2(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid")
	new client = GetClientOfUserId(client_id);
	PlayersScopeFalgs[client] = false;
	if (isEnabled6 == true && IsClient(client, false) && !IsFakeClient(client))  
		ClientCommand(client, "r_screenoverlay 0");
}


//击中敌人后短暂禁用准心，避免和击中反馈插件冲突
public Action:Event_PlayerHurt2(Handle:event, const String:name[], bool:dontBroadcast)
{ 
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new hurtman = GetClientOfUserId(GetEventInt(event, "userid"));
	new health = GetEventInt(event, "health");
	
	if(attacker <1 || attacker == hurtman || IsFakeClient(attacker)) 
		return;
		
	if (IsClient(attacker, true) && health <= 0)
	{
		// PrintToChat(attacker, "打死了！");
		return;
	}
	
	if (isEnabled6 == true && IsClient(attacker, true) && PlayersScopeFalgs[attacker] == true)
	{
		PlayersScopeFalgs[attacker] = false;
		CreateTimer(UnvisibleTime, task_Clean2, attacker);
	}	
}

public Action:task_Clean2(Handle:Timer, any:client)
{
	PlayersScopeFalgs[client] = true;
}


//击杀敌人后短暂禁用准心，避免和击杀反馈插件冲突
public Event_PlayerDeath2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker <1 || attacker == victim || IsFakeClient(attacker)) 
		return;
	if (isEnabled6 == true && IsClient(attacker, true) && PlayersScopeFalgs[attacker] == true)
	{
		// PrintToChat(attacker, "击杀！");
		PlayersScopeFalgs[attacker] = false;
		CreateTimer(UnvisibleTime2, task_Clean3, attacker);
	}	
}

public Action:task_Clean3(Handle:Timer, any:client)
{
	PlayersScopeFalgs[client] = true;
}


public void RoundStart_New(Handle hEvent, char[] chEvent, bool bDontBroadcast)
{
	for (int i=1; i<=MaxClients; i++)
	{
		if (isEnabled6 == true && IsClient(i, true) && !IsFakeClient(i))
		{
			new currentWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
			{
				PlayersScopeFalgs[i] = false;
				continue;
			}	
			decl String:sWeapon[32];
			GetEdictClassname(currentWeapon, sWeapon, sizeof(sWeapon));
			if(StrEqual("weapon_scout", sWeapon) || StrEqual("weapon_awp", sWeapon) || StrEqual("weapon_sg550", sWeapon) || StrEqual("weapon_g3sg1", sWeapon))
			{
				// PrintToChat(i, "回合开始装备！");
				PlayersScopeFalgs[i] = true;
			}
			else
			    PlayersScopeFalgs[i] = false;
		}
		else
			PlayersScopeFalgs[i] = false;
	}
}


// 清除作弊标志函数
UnlockConsoleCommandAndConvar(const String:command[])
{
    new flags = GetCommandFlags(command);
    if (flags != INVALID_FCVAR_FLAGS)
    {
        SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    }
    
    new Handle:cvar = FindConVar(command);
    if (cvar != INVALID_HANDLE)
    {
        flags = GetConVarFlags(cvar);
        SetConVarFlags(cvar, flags & ~FCVAR_CHEAT);
    }
} 