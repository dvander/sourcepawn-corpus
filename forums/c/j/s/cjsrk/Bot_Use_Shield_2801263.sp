#include <sourcemod>
#include <sdktools>
#include <sourcemod>
#include <cstrike>
	
new Handle:cvarEnable5;
new Handle:cvarEnableTBotUse;
new Handle:cvarEnableCTBotUse;
new Handle:cvarShieldWeapon2;
new bool:isEnabled5;    //启动或禁用插件变量
new bool:isEnableTBotUse;    //是否允许匪徒使用盾牌（盾牌替换的是双枪）
new bool:IsEnableCTBotUse;     //是否允许警察使用盾牌（如允许，则三分之一的usp会被替换为盾牌）
static char shieldWeapon2[30];    //应用盾牌功能的武器（必须和盾牌插件的值一致）

static int RoundNum5 = 0;    //回合序号

	
public Plugin:myinfo = 
{
	name = "Bot_Use_Shield",
	author = "srk",
	description = "Bot Use Shield For Shield Addon",
	url = ""
};

public OnPluginStart()
{
	//设置配置文件
	CreateConVar("sm_new_shield_version", "1.0.0", "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable5 = CreateConVar("sm_bot_use_shield_enable", "1", "Enable the plugin? (1: enabled; 0: disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarEnableTBotUse = CreateConVar("sm_bot_use_shield_enable_tbot", "0", "Allow terrorists to use shields? (1: allowed; 0: forbidden. If not allowed, then non-robot terrorist players cannot buy shields)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarEnableCTBotUse = CreateConVar("sm_bot_use_shield_enable_ctbot", "1", "Allow the police to use shields? (1: allowed; 0: forbidden. If allowed, one-third of usp will be replaced with shields+pistols)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarShieldWeapon2 = CreateConVar("sm_bot_use_shield_weapon", "weapon_elite", "The weapon witch can be used as the shield  (must be consistent with the value of the shield plugin)", FCVAR_PLUGIN);
	AutoExecConfig(true, "plugin.sm_bot_use_shield");
	HookConVarChange(cvarEnable5, CvarChange);
	HookConVarChange(cvarEnableTBotUse, CvarChange);
	HookConVarChange(cvarEnableCTBotUse, CvarChange);
	HookConVarChange(cvarShieldWeapon2, CvarChange);
	
	RegConsoleCmd("buy_shield",Cmd_CreateAnaconda6);
	HookEvent("round_start", RoundStart5, EventHookMode_Post);
}

public OnMapStart()
{	 
	RoundNum5 = 0; 
}

//读取配置文件的cvar的值
public OnConfigsExecuted()
{
	isEnabled5 = GetConVarBool(cvarEnable5);
	isEnableTBotUse = GetConVarBool(cvarEnableTBotUse);
	IsEnableCTBotUse = GetConVarBool(cvarEnableCTBotUse);
	GetConVarString(cvarShieldWeapon2, shieldWeapon2, sizeof(shieldWeapon2));
}


//cvar值变化时的响应数组
public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(convar == cvarEnable5)
	{
		if(StringToInt(newValue) == 1)
		{
			isEnabled5 = true;
		}
		else
		{
			isEnabled5 = false;
		}
	}
	if(convar == cvarEnableTBotUse)
	{
		if(StringToInt(newValue) == 1)
		{
			isEnableTBotUse = true;
		}
		else
		{
			isEnableTBotUse = false;
		}
	}
	if(convar == cvarEnableCTBotUse)
	{
		if(StringToInt(newValue) == 1)
		{
			IsEnableCTBotUse = true;
		}
		else
		{
			IsEnableCTBotUse = false;
		}
	}
	if(convar == cvarShieldWeapon2)
	{
		if(strlen(newValue) > 0 && !StrEqual("", newValue))
		{
			strcopy(shieldWeapon2, strlen(newValue) + 1, newValue);		
		}
	}
}


public Action:RoundStart5(Handle:event, const String:name[], bool:dontBroadcast) 
{
	RoundNum5++;
	// PrintToChatAll("提示：回合数：%d", RoundNum2);
	if(RoundNum5 >= 2)
	    CreateTimer(2.0, GetBotShield);
}

//指定替换原版武器
public Action:GetBotShield(Handle timer)
{
	if(isEnabled5 == true && !StrEqual("", shieldWeapon2) && (isEnableTBotUse == 0 || IsEnableCTBotUse > 0))
	{
		for(int i = 1; i <= MaxClients; i++) 
		{
			if(IsClient(i, true) && IsFakeClient(i))
			{
				// 如果不允许匪徒使用盾牌
				if(isEnableTBotUse == 0)
				{
					if(GetClientTeam(i) == CS_TEAM_T)
					{
						new pistol = GetPlayerWeaponSlot(i, 1);
						if(IsValidEdict(pistol) && pistol > -1)
						{
							char sWeapon[32];
							GetEdictClassname(pistol, sWeapon, sizeof(sWeapon));
							if(StrEqual(shieldWeapon2, sWeapon))    //glock替换所有匪徒盾牌
							{
								new weapon = CreateEntityByName("weapon_glock");
								DispatchSpawn(weapon);
								ActivateEntity(weapon);
								EquipPlayerWeapon(i,weapon);	
								new MyWeaponType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
								if (IsValidEdict(pistol) && (pistol > -1))
									AcceptEntityInput(pistol, "kill");
								if(GetEntProp(i, Prop_Data, "m_iAmmo", 4, MyWeaponType) <= 0)
								{
									SetEntProp(i, Prop_Data, "m_iAmmo", 100, 4, MyWeaponType); 
								}
								// PrintToChatAll("格洛克替换匪徒盾牌！");
							}
						}
					}
				}
				// 允许警察使用盾牌
				if(IsEnableCTBotUse > 0)
				{
					new pistol = GetPlayerWeaponSlot(i, 1);
					if(IsValidEdict(pistol) && pistol > -1)
					{
						char sWeapon[32];
						GetEdictClassname(pistol, sWeapon, sizeof(sWeapon));
						if(StrEqual("weapon_usp", sWeapon))    
						{
							int IsUseNewSecWeapon = GetRandomInt(1,3);
							if(IsUseNewSecWeapon == 1)    //盾牌替换警察三分之一usp
							{
								new weapon = CreateEntityByName(shieldWeapon2);
								DispatchSpawn(weapon);
								ActivateEntity(weapon);
								EquipPlayerWeapon(i,weapon);	
								new MyWeaponType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
								AcceptEntityInput(pistol, "kill");
								if(GetEntProp(i, Prop_Data, "m_iAmmo", 4, MyWeaponType) <= 0)
								{
									SetEntProp(i, Prop_Data, "m_iAmmo", 80, 4, MyWeaponType); 
								}
								// PrintToChatAll("盾牌替换警察usp！");
							}
						}
					}
				}
			}
		}
	}
}


bool:IsClient(Client, bool:Alive)
{
	return Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && (Alive && IsPlayerAlive(Client));
}


//警察获取盾牌指令
public Action:Cmd_CreateAnaconda6(Client,Args){
	if(!Client)Client=1;
	
	if(isEnabled5 == true && IsClient(Client, true) && GetClientTeam(Client) == CS_TEAM_CT && !StrEqual("", shieldWeapon2))
	{
		if(GetClientTeam(Client) == CS_TEAM_T)
		{
			PrintToChat(Client, "Only police can use the special buy shield command!");
			return;
		}
		
		decl String:sWeapon[30];
		strcopy(sWeapon, strlen(shieldWeapon2) + 1, shieldWeapon2);
		TrimString(sWeapon);
		ReplaceStringEx(sWeapon, strlen(sWeapon), "_", ";");
		decl String:data[2][30];
		ExplodeString(sWeapon, ";", data, 2, 30);					
		new GameWeaponID = CS_AliasToWeaponID(data[1]);
						
		new MyMoney = GetEntProp(Client, Prop_Send, "m_iAccount");
		new ShieldPrice = CS_GetWeaponPrice(Client, GameWeaponID, false);
		if(MyMoney < 0 || MyMoney < ShieldPrice)
		{
			PrintToChat(Client, "You don't have enough money to buy a shield!");
			return;
		}
		SetEntProp(Client, Prop_Send, "m_iAccount", MyMoney - ShieldPrice);
		
		new weapon = CreateEntityByName(shieldWeapon2);
		DispatchSpawn(weapon);
		ActivateEntity(weapon);
		EquipPlayerWeapon(Client,weapon);	
		new MyWeaponType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
		if(GetEntProp(Client, Prop_Data, "m_iAmmo", 4, MyWeaponType) <= 0)
		{
			SetEntProp(Client, Prop_Data, "m_iAmmo", 80, 4, MyWeaponType); 
		}	
	}
}


//  如果不允许匪徒使用盾牌，则匪徒真人玩家也不能购买
public Action CS_OnBuyCommand(int client, const char[] weapon)
{
	if(isEnabled5 == true && !StrEqual("", shieldWeapon2))
	{
		if(IsClient(client, true) && !IsFakeClient(client) && isEnableTBotUse == 0)
		{
			decl String:weapon2[32];
			Format(weapon2, sizeof(weapon2), "%s%s", "weapon_", weapon);
			TrimString(weapon2);
			if (StrEqual(weapon2, shieldWeapon2))
			{
				PrintToChat(client, "The server administrator has set that terrorists cannot buy shields!");
				return Plugin_Handled;
			}
		}
	}	
	return Plugin_Continue;
}