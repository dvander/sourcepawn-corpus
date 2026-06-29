#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

new Handle:cvarEnable3;
new Handle:cvarEnableSpark;
new Handle:cvarIsMediumShield;
new Handle:cvarIsChangeAddon;
new Handle:cvarIsExposeRightHand;
new Handle:cvarIsExposeReload;
new Handle:cvarShieldWeapon;
new bool:isEnabled3;    //启动或禁用插件变量
new bool:isEnabledSpark;    //启用火花变量
new bool:IsMediumShield;    //盾牌是否是半身盾
new int:IsChangeAddon;    //是否让盾牌在空闲状态时在背部显示
new bool:IsExposeRightHand;    //右手是否暴露在盾牌外
new bool:IsExposeReload;    //换弹时是否暴露头部和右半身
static char shieldWeapon[30];    //应用盾牌功能的武器
int ClientHitGroup[128] = 0;    //客户端HitGroup
int ClientHitGroup2[128] = 0;    //客户端HitGroup2，目前用于储存前一次的爆头信息
int ShieldIsReload[128] = {0};    //判断盾牌手是否在换弹的数组

new bool:g_TRIgnore[MAXPLAYERS + 1]; // Tells traceray to ignore collisions with certain players
new g_Ignore[MAXPLAYERS + 1]; // Tell plugin to ignore penetrative bullets for a certain player
	
public Plugin:myinfo = 
{
	name = "New Shield",
	author = "cjsrk",
	description = "Give A Shield For CS Source",
	url = ""
};

public OnPluginStart()
{
	//设置配置文件
	CreateConVar("sm_new_shield_version", "1.0.0", "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable3 = CreateConVar("sm_new_shield_enable", "1", "Enable the plugin? (1: enabled; 0: disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarEnableSpark = CreateConVar("sm_new_shield_enable_spark", "1", "Enables the spark effect when a bullet hits the shield? (1: enabled; 0: disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarIsMediumShield = CreateConVar("sm_new_shield_is_medium", "0", "Enable the half shield effect? (1: Enabled; 0: Disabled. If enabled, the shield does not provide full protection for your feet, such as the shield model that comes with the plugin can use it)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarIsChangeAddon = CreateConVar("sm_new_shield_is_change_addon", "0", "Make the shield show on the back when switching to primary weapon? (1: The shield is hidden when switching to the primary weapon; 2: The shield is displayed on the back when switching to the primary weapon (only for specific models,such as the shield model that comes with the plugin); 0: Disabled. This function can be used when setting a knife or a pistol as a shield.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvarIsExposeRightHand = CreateConVar("sm_new_shield_is_expose_righthand", "0", "Don't protect your right hand? (1: Doesn't protect; 0: Protect. It can be used when the model make your right hand to be exposed outside the shield, such as the shield model that comes with the plugin can use it)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarIsExposeReload = CreateConVar("sm_new_shield_is_expose_reload", "0", "Doesn't protect the head and right side of the body when reloading? (1: Doesn't protect; 0: Protect. This feature can works when the model make the user's head and right side of the body to be exposed from the shield when reloading, such as the shield model that comes with the plugin can use it)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarShieldWeapon = CreateConVar("sm_shield_weapon", "weapon_elite", "the weapon witch can be used as the shield", FCVAR_PLUGIN);
	AutoExecConfig(true, "plugin.new_shield");
	HookConVarChange(cvarEnable3, CvarChange);
	HookConVarChange(cvarEnableSpark, CvarChange);
	HookConVarChange(cvarIsMediumShield, CvarChange);
	HookConVarChange(cvarIsChangeAddon, CvarChange);
	HookConVarChange(cvarIsExposeRightHand, CvarChange);
	HookConVarChange(cvarIsExposeReload, CvarChange);
	HookConVarChange(cvarShieldWeapon, CvarChange);
	
	HookEvent("round_start", RoundStart3, EventHookMode_Post);
	AddTempEntHook("EffectDispatch", TE_OnEffectDispatch);
	AddTempEntHook("World Decal", TE_OnWorldDecal);
	UpdateAllConvars();
}

public OnMapStart()
{	
    PrecacheSound("physics/metal/metal_box_impact_bullet1.wav", true);
	PrecacheSound("physics/metal/metal_solid_impact_bullet2.wav", true);
	PrecacheSound("physics/metal/metal_solid_impact_bullet3.wav", true);
	PrecacheSound("physics/metal/metal_solid_impact_bullet4.wav", true);	
}


//读取配置文件的cvar的值
public OnConfigsExecuted()
{
	isEnabled3 = GetConVarBool(cvarEnable3);
	isEnabledSpark = GetConVarBool(cvarEnableSpark);
	IsMediumShield = GetConVarBool(cvarIsMediumShield);
	IsChangeAddon = GetConVarInt(cvarIsChangeAddon);
	IsExposeRightHand = GetConVarBool(cvarIsExposeRightHand);
	IsExposeReload = GetConVarBool(cvarIsExposeReload);
	GetConVarString(cvarShieldWeapon, shieldWeapon, sizeof(shieldWeapon));
}

//cvar值变化时的响应数组
public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(convar == cvarEnable3)
	{
		if(StringToInt(newValue) == 1)
		{
			isEnabled3 = true;
		}
		else
		{
			isEnabled3 = false;
		}
	}
	if(convar == cvarEnableSpark)
	{
		if(StringToInt(newValue) == 1)
		{
			isEnabledSpark = true;
		}
		else
		{
			isEnabledSpark = false;
		}
	}
	if(convar == cvarIsMediumShield)
	{
		if(StringToInt(newValue) == 1)
		{
			IsMediumShield = true;
		}
		else
		{
			IsMediumShield = false;
		}
	}
	if(convar == cvarIsChangeAddon)
	{
		if(StringToInt(newValue) == 1)
		{
			IsChangeAddon = 1;
		}
		else if(StringToInt(newValue) == 2)
		{
			IsChangeAddon = 2;
		}
		else
		{
			IsChangeAddon = 0;
		}
	}
	if(convar == cvarIsExposeRightHand)
	{
		if(StringToInt(newValue) == 1)
		{
			IsExposeRightHand = true;
		}
		else
		{
			IsExposeRightHand = false;
		}
	}
	if(convar == cvarIsExposeReload)
	{
		if(StringToInt(newValue) == 1)
		{
			IsExposeReload = true;
		}
		else
		{
			IsExposeReload = false;
		}
	}
	if(convar == cvarShieldWeapon)
	{
		if(strlen(newValue) > 0 && !StrEqual("", newValue))
		{
			strcopy(shieldWeapon, strlen(newValue) + 1, newValue);		
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage2);  
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip3);
}

bool:IsClient(Client, bool:Alive)
{
	return Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && (Alive && IsPlayerAlive(Client));
}


public Action TE_OnEffectDispatch(const char[] te_name, const Players[], int numClients, float delay)
{
	if(isEnabled3 == false)
		return Plugin_Continue;
	int iEffectIndex = TE_ReadNum("m_iEffectName");
	int nHitBox = TE_ReadNum("m_nHitBox");
	char sEffectName[64];
	GetEffectName(iEffectIndex, sEffectName, sizeof(sEffectName));
	if(StrEqual(sEffectName, "csblood"))
	{
		decl Float:tempent[3];
		new client = TE_ReadNum("entindex");
		// PrintToChatAll("流血是 %d 。", client);
		tempent[0] = TE_ReadFloat("m_vOrigin[0]");
		tempent[1] = TE_ReadFloat("m_vOrigin[1]");
		tempent[2] = TE_ReadFloat("m_vOrigin[2]");
		new Float: victimOrigin[3], Float:victimAngles[3], Float:vecPoints[3], Float:vecAngles[3];
		// GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", victimOrigin);    //获取受害者坐标
		// 检测受害者的坐标
		GetClientEyePosition(client, victimOrigin);
		
		// 检测受害者的角度方向
		GetClientEyeAngles(client, victimAngles);
		// GetVectorAngles(victimOrigin, victimAngles);
		// 建立从受害者到攻击者的方向向量
		MakeVectorFromPoints(victimOrigin, tempent, vecPoints);
		GetVectorAngles(vecPoints, vecAngles);
		
		// Differenz
		new diff = RoundFloat(victimAngles[1]) - RoundFloat(vecAngles[1]);
		// Correct it
		if (diff < -180)
		{
			diff = 360 + diff;
		}

		if (diff > 180)
		{
			diff = 360 - diff;
		}
		// PrintToChatAll("diff转换后的值：%d 。", diff);
		
		// 检测攻击的方向
		bool ShieldSign = false;    //正面攻击
		bool ShieldSign2 = false;    //背后攻击
		bool IsRightBody = false;    //攻击来自右前方
		
		// 打中前方
		if (diff >= -22.5 && diff < 22.5)
		{
			ShieldSign = true;
		}

		// 打中右前方
		else if (diff >= 22.5 && diff < 67.5)
		{
			ShieldSign = true;
			IsRightBody = true;
		}

		// 打中右方
		else if (diff >= 67.5 && diff < 112.5)
		{
			ShieldSign = false;
			ShieldSign2 = false;
		}

		// 打中右后方
		else if (diff >= 112.5 && diff < 157.5)
		{
			ShieldSign2 = true;
		}

		// 打中后方
		else if (diff >= 157.5 || diff < -157.5)
		{
			ShieldSign2 = true;
		}

		// 打中左后方
		else if (diff >= -157.5 && diff < -112.5)
		{
			ShieldSign2 = true;
		}

		// 打中左方
		else if (diff >= -112.5 && diff < -67.5)
		{
			ShieldSign = false;
			ShieldSign2 = false;
		}

		// 打中左前方
		else if (diff >= -67.5 && diff < -22.5)
		{
			ShieldSign = true;
		}
		
		// 检测受害者使用的武器
		if(HasEntProp(client, Prop_Send, "m_hActiveWeapon") == false)
			return Plugin_Continue;
		new currentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
			return Plugin_Continue;
		decl String:sWeapon[32];
		GetEdictClassname(currentWeapon, sWeapon, sizeof(sWeapon));

		// 如果受害者正在使用盾牌
		if(StrEqual(shieldWeapon, sWeapon))
		{
			if(ShieldSign == true)    // 被正面攻击
			{
				// 开启换弹时不保护头部和右半身，且当盾牌手换弹时被击中右半身，不能减伤，正常掉血
				if(IsRightBody == true && IsExposeReload == true && ShieldIsReload[client] == 1)
				{
					return Plugin_Continue;
				}
				// PrintToChatAll("正面攻击持盾者，不掉血！");
				return Plugin_Stop;
			}
			else
			{
				if(tempent[2] >= victimOrigin[2])
				{
					// PrintToChatAll("正面打头，不掉血！");
					return Plugin_Stop;
				}
			}
		}
		// 如果受害者没有使用盾牌	
		else
		{
			bool ShieldOnBack = false;    //检测盾牌有没有在背上
			new main = GetPlayerWeaponSlot(client, 0);
			new pistol = GetPlayerWeaponSlot(client, 1);
			new knife = GetPlayerWeaponSlot(client, 2);
			if(main > -1)
			{
				decl String:sWeapon2[32];
				GetEdictClassname(main, sWeapon2, sizeof(sWeapon2));
				if(StrEqual(shieldWeapon, sWeapon2))
					ShieldOnBack = true;
			}
			if(pistol > -1)
			{
				decl String:sWeapon2[32];
				GetEdictClassname(pistol, sWeapon2, sizeof(sWeapon2));
				if(StrEqual(shieldWeapon, sWeapon2))
					ShieldOnBack = true;
			}
			if(knife > -1)
			{
				decl String:sWeapon2[32];
				GetEdictClassname(knife, sWeapon2, sizeof(sWeapon2));
				if(StrEqual(shieldWeapon, sWeapon2))    
					ShieldOnBack = true;
			}
			
			// 如果受害者的盾牌在背上（未使用）
			if(ShieldOnBack == true)
			{
				if(ShieldSign2 == true)  //背面攻击
				{
					// PrintToChatAll("背面攻击背盾者，不掉血！");
					return Plugin_Stop;
				}
			}
		}					
	}
}

stock int GetParticleEffectName(int index, char[] sEffectName, int maxlen)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("ParticleEffectNames");
	
	return ReadStringTable(table, index, sEffectName, maxlen);
}

stock int GetEffectName(int index, char[] sEffectName, int maxlen)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("EffectDispatch");
	
	return ReadStringTable(table, index, sEffectName, maxlen);
}


public Action TE_OnWorldDecal(const char[] te_name, const Players[], int numClients, float delay)
{
	if(isEnabled3 == false)
		return Plugin_Continue;
	float vecOrigin[3];
	int nIndex = TE_ReadNum("m_nIndex");
	char sDecalName[64];
	TE_ReadVector("m_vecOrigin", vecOrigin);
	GetDecalName(nIndex, sDecalName, sizeof(sDecalName));
	
	if(StrContains(sDecalName, "decals/blood") == 0 && StrContains(sDecalName, "_subrect") != -1)
	{
		char sBuffer[64];
		Format(sBuffer, sizeof(sBuffer), "Decal Name: %s", sDecalName);
		// PrintToChatAll(sBuffer);
		// PrintToChatAll("地上的血！");
		// PrintToChatAll("地上血坐标的x：%f 。", vecOrigin[0]);
		// PrintToChatAll("地上血坐标的y：%f 。", vecOrigin[1]);
		// PrintToChatAll("地上血坐标的z：%f 。", vecOrigin[2]);
		
		// Variables to store
		new Float:victimAngles[3];
		new Float:searchOrigin[3];
		new Float:near;
		new Float:distance;

		new Float:dist;
		new Float:vecPoints[3];
		new Float:vecAngles[3];
		new Float:searchAngles[3];

		decl String:directionString[64];
		decl String:unitString[32];

		new String:textToPrint[64];

		// nearest client
		new nearest;
		
		// Reset variables
		nearest = 0;
		near = 0.0;
		
		//搜索离血迹最近的玩家
		// Next client loop
		for (new search = 1; search <= MaxClients; search++)
		{
			if (IsClient(search, true))
			{
				// Get distance to first client
				GetClientAbsOrigin(search, searchOrigin);
				distance = GetVectorDistance(vecOrigin, searchOrigin);

				// Is he more near to the player as the player before?
				if (near == 0.0)
				{
					near = distance;
					nearest = search;
				}

				if (distance < near)
				{
					// Set new distance and new nearest player
					near = distance;
					nearest = search;
				}
			}
		}
		
		// Found a player?
		if (nearest != 0)
		{		
			GetClientAbsOrigin(nearest, searchOrigin);
			GetClientEyeAngles(nearest, searchAngles);
			// 建立受害者和攻击者的方向向量
			MakeVectorFromPoints(vecOrigin, searchOrigin, vecPoints);
			GetVectorAngles(vecPoints, vecAngles);

			// Differenz
			new diff = RoundFloat(searchAngles[1]) - RoundFloat(vecAngles[1]);


			// Correct it
			if (diff < -180)
			{
				diff = 360 + diff;
			}

			if (diff > 180)
			{
				diff = 360 - diff;
			}
			
			// 检测攻击的方向
			bool ShieldSign = false;    //正面攻击
			bool ShieldSign2 = false;    //背后攻击

			// Now geht the direction
			// 前方
			if (diff >= -22.5 && diff < 22.5)
			{
				ShieldSign = true;
			}

			// 右前方
			else if (diff >= 22.5 && diff < 67.5)
			{
				ShieldSign = true;
			}

			// 右方
			else if (diff >= 67.5 && diff < 112.5)
			{
				ShieldSign = false;
				ShieldSign2 = false;
			}

			// 右后方
			else if (diff >= 112.5 && diff < 157.5)
			{
				ShieldSign2 = true;
			}

			// 后方
			else if (diff >= 157.5 || diff < -157.5)
			{
				ShieldSign2 = true;
			}

			// 左后方
			else if (diff >= -157.5 && diff < -112.5)
			{
				ShieldSign2 = true;
			}

			// 左方
			else if (diff >= -112.5 && diff < -67.5)
			{
				ShieldSign = false;
				ShieldSign2 = false;
			}

			// 左前方
			else if (diff >= -67.5 && diff < -22.5)
			{
				ShieldSign = true;
			}

			// Distance to meters
			dist = near * 0.01905;
			
			// decl String:TempName[64];
			// GetClientName(nearest, TempName, sizeof(TempName));
			// PrintToChatAll("流血的的受害者名字是 %s 。", TempName);
			
			// 检测受害者使用的武器
			if(HasEntProp(nearest, Prop_Send, "m_hActiveWeapon") == false)
				return Plugin_Continue;
			new currentWeapon = GetEntPropEnt(nearest, Prop_Send, "m_hActiveWeapon");
			if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
				return Plugin_Continue;
			decl String:sWeapon[32];
			GetEdictClassname(currentWeapon, sWeapon, sizeof(sWeapon));

			// 如果受害者正在使用盾牌
			if(StrEqual(shieldWeapon, sWeapon))
			{
				if(ShieldSign == true)    // 被正面攻击
				{
					// PrintToChatAll("正面攻击持盾者，清除地上的血！");
					return Plugin_Stop;
				}
			}
			// 如果受害者没有使用盾牌	
			else
			{
				bool ShieldOnBack = false;    //检测盾牌有没有在背上
				new main = GetPlayerWeaponSlot(nearest, 0);
				new pistol = GetPlayerWeaponSlot(nearest, 1);
				new knife = GetPlayerWeaponSlot(nearest, 2);
				if(main > -1)
				{
					decl String:sWeapon2[32];
					GetEdictClassname(main, sWeapon2, sizeof(sWeapon2));
					if(StrEqual(shieldWeapon, sWeapon2))
						ShieldOnBack = true;
				}
				if(pistol > -1)
				{
					decl String:sWeapon2[32];
					GetEdictClassname(pistol, sWeapon2, sizeof(sWeapon2));
					if(StrEqual(shieldWeapon, sWeapon2))
						ShieldOnBack = true;
				}
				if(knife > -1)
				{
					decl String:sWeapon2[32];
					GetEdictClassname(knife, sWeapon2, sizeof(sWeapon2));
					if(StrEqual(shieldWeapon, sWeapon2))    
						ShieldOnBack = true;
				}
				
				// 如果受害者的盾牌在背上（未使用）
				if(ShieldOnBack == true)
				{
					if(ShieldSign2 == true)  //背面攻击
					{
						// PrintToChatAll("背面攻击背盾者，清除地上的血！");
						return Plugin_Stop;
					}
				}
				// 如果受害者没有盾牌，再次搜索第二个离血迹最近的玩家
				else
				{
					new OldNearest = nearest;
					// Reset variables
					nearest = 0;
					near = 0.0;
					
					// Next client loop
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClient(search, true))
						{
							// Get distance to first client
							GetClientAbsOrigin(search, searchOrigin);
							distance = GetVectorDistance(vecOrigin, searchOrigin);

							// Is he more near to the player as the player before?
							if (near == 0.0)
							{
								near = distance;
								nearest = search;
							}

							if (distance < near && search != OldNearest)
							{
								// Set new distance and new nearest player
								near = distance;
								nearest = search;
							}
						}
					}
					
					// 如果找到离血迹最近的第二个玩家
					if (nearest != 0)
					{
						// decl String:TempName2[64];
						// GetClientName(nearest, TempName2, sizeof(TempName2));
						// PrintToChatAll("流血第二人名字是 %s 。", TempName2);
						
						GetClientAbsOrigin(nearest, searchOrigin);
						GetClientEyeAngles(nearest, searchAngles);
						// 建立受害者和攻击者的方向向量
						MakeVectorFromPoints(vecOrigin, searchOrigin, vecPoints);
						GetVectorAngles(vecPoints, vecAngles);

						// Differenz
						diff = RoundFloat(searchAngles[1]) - RoundFloat(vecAngles[1]);


						// Correct it
						if (diff < -180)
						{
							diff = 360 + diff;
						}

						if (diff > 180)
						{
							diff = 360 - diff;
						}
						
						// 检测攻击的方向
						ShieldSign = false;    //正面攻击
						ShieldSign2 = false;    //背后攻击

						// Now geht the direction
						// 前方
						if (diff >= -22.5 && diff < 22.5)
						{
							ShieldSign = true;
						}

						// 右前方
						else if (diff >= 22.5 && diff < 67.5)
						{
							ShieldSign = true;
						}

						// 右方
						else if (diff >= 67.5 && diff < 112.5)
						{
							ShieldSign = false;
							ShieldSign2 = false;
						}

						// 右后方
						else if (diff >= 112.5 && diff < 157.5)
						{
							ShieldSign2 = true;
						}

						// 后方
						else if (diff >= 157.5 || diff < -157.5)
						{
							ShieldSign2 = true;
						}

						// 左后方
						else if (diff >= -157.5 && diff < -112.5)
						{
							ShieldSign2 = true;
						}

						// 左方
						else if (diff >= -112.5 && diff < -67.5)
						{
							ShieldSign = false;
							ShieldSign2 = false;
						}

						// 左前方
						else if (diff >= -67.5 && diff < -22.5)
						{
							ShieldSign = true;
						}

						// Distance to meters
						dist = near * 0.01905;
						
						// PrintToChatAll("流血第二人距离是 %f 米。", dist);
						if(dist > 8.0)
							return Plugin_Continue;
						
						// 检测受害者使用的武器
						if(HasEntProp(nearest, Prop_Send, "m_hActiveWeapon") == false)
							return Plugin_Continue;
						currentWeapon = -1;
						currentWeapon = GetEntPropEnt(nearest, Prop_Send, "m_hActiveWeapon");
						if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
							return Plugin_Continue;
						sWeapon = "";
						GetEdictClassname(currentWeapon, sWeapon, sizeof(sWeapon));
						
						// 如果受害者正在使用盾牌
						if(StrEqual(shieldWeapon, sWeapon))
						{
							if(ShieldSign == true)    // 被正面攻击
							{
								// PrintToChatAll("2正面攻击持盾者，清除地上的血！");
								return Plugin_Stop;
							}
						}
						// 如果受害者没有使用盾牌	
						else
						{
							ShieldOnBack = false;    //检测盾牌有没有在背上
							main = -1, pistol = -1, knife = -1;
							main = GetPlayerWeaponSlot(nearest, 0);
							pistol = GetPlayerWeaponSlot(nearest, 1);
							knife = GetPlayerWeaponSlot(nearest, 2);
							if(main > -1)
							{
								decl String:sWeapon2[32];
								GetEdictClassname(main, sWeapon2, sizeof(sWeapon2));
								if(StrEqual(shieldWeapon, sWeapon2))
									ShieldOnBack = true;
							}
							if(pistol > -1)
							{
								decl String:sWeapon2[32];
								GetEdictClassname(pistol, sWeapon2, sizeof(sWeapon2));
								if(StrEqual(shieldWeapon, sWeapon2))
									ShieldOnBack = true;
							}
							if(knife > -1)
							{
								decl String:sWeapon2[32];
								GetEdictClassname(knife, sWeapon2, sizeof(sWeapon2));
								if(StrEqual(shieldWeapon, sWeapon2))    
									ShieldOnBack = true;
							}
							
							// 如果受害者的盾牌在背上（未使用）
							if(ShieldOnBack == true)
							{
								if(ShieldSign2 == true)  //背面攻击
								{
									// PrintToChatAll("2背面攻击背盾者，清除地上的血！");
									return Plugin_Stop;
								}
							}
						}
					}
					
									
				}
			}			
			// PrintToChatAll("流血者索引是 %d 。", nearest);
			// PrintToChatAll("宿主与血液距离：%f ！", dist);			
		}
	}	
}


stock int GetDecalName(int index, char[] sDecalName, int maxlen)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("decalprecache");
	
	return ReadStringTable(table, index, sDecalName, maxlen);
}


public void:OnWeaponEquip3(client, weapon)
{   
    if (IsClient(client, true)) 
	{
		decl String:sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
		if(StrEqual(shieldWeapon, sWeapon))    //如果当前武器是盾牌，则挂钩其换弹动作
		{
			SDKHook(weapon, SDKHook_ReloadPost, OnWeaponReload3);
		}
	}
}

public Action:OnWeaponReload3(weapon)
{
	new client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
    if (IsClient(client, true))
	{
		float ReloadTime = GetEntPropFloat(client, Prop_Send, "m_flNextAttack") - GetGameTime();    //获取换弹时间
		ShieldIsReload[client] = 1;
		CreateTimer(ReloadTime, Timer_ReloadTime, client);    //换弹结束后修改ShieldIsReload[client]的值
		// PrintToChat(client, "盾牌手开始换弹！");
	}
}

//换弹结束修改ShieldIsReload数组函数
public Action:Timer_ReloadTime(Handle timer, int client)
{
	if(!IsValidEntity(client))
		return Plugin_Continue;
	if (IsClient(client, true))
	{
		ShieldIsReload[client] = 0;
		// PrintToChat(client, "盾牌手结束换弹！");
	}
}



// 让盾牌在切换到主武器时隐藏（当设置副武器或刀子为盾牌时可使用）
public OnPostThinkPost(client)
{
	if(IsClient(client, true) == true)
	{
		if(isEnabled3 == true && IsChangeAddon > 0)
		{
			if(HasEntProp(client, Prop_Send, "m_hActiveWeapon") == false)
				return;
			new currentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
				return;
			decl String:sWeapon[64];
			GetEntityClassname(currentWeapon, sWeapon, sizeof(sWeapon));
			if(!StrEqual(shieldWeapon, sWeapon))    //当前武器不是盾牌
			{
				new pistol = GetPlayerWeaponSlot(client, 1);
				new knife = GetPlayerWeaponSlot(client, 2);
				if(pistol > -1)    //设置的盾牌是副武器
				{
					decl String:sWeapon2[64];
					GetEdictClassname(pistol, sWeapon2, sizeof(sWeapon2));
					if(StrEqual(shieldWeapon, sWeapon2))
					{
						ReplaceStringEx(sWeapon2, strlen(sWeapon2), "_", ";");
						decl String:data[2][64];
						ExplodeString(sWeapon2, ";", data, 2, 30);			
						
						new GameWeaponID = CS_AliasToWeaponID(data[1]);
						// PrintToChat(client, "武器ID：%d 。", GameWeaponID);
						int WeaponIdFlag = GameWeaponID;
						if(WeaponIdFlag == 0)    //加枪插件产生的武器
						{
							// 隐藏腰部的盾牌模型
							SetEntProp(client, Prop_Send, "m_iSecondaryAddon", 0);
						}
						else    //普通武器
						{
							// 隐藏腰部的盾牌模型并将盾牌模型添加在使用者背上
							SetEntProp(client, Prop_Send, "m_iSecondaryAddon", 0);
							if(IsChangeAddon == 2)
							{
								SetEntProp(client, Prop_Send, "m_iAddonBits", 64);
								SetEntProp(client, Prop_Send, "m_iPrimaryAddon", GameWeaponID);
							}
						}
					}
					return;
				}
				if(knife > -1)    //设置的盾牌是刀子
				{
					decl String:sWeapon2[64];
					GetEdictClassname(knife, sWeapon2, sizeof(sWeapon2));
					if(StrEqual(shieldWeapon, sWeapon2))
					{
						ReplaceStringEx(sWeapon2, strlen(sWeapon2), "_", ";");
						decl String:data[2][64];
						ExplodeString(sWeapon2, ";", data, 2, 30);			
						
						new GameWeaponID = CS_AliasToWeaponID(data[1]);
						// PrintToChat(client, "武器ID：%d 。", GameWeaponID);
						int WeaponIdFlag = GameWeaponID;
						if(WeaponIdFlag == 0)    //加枪插件产生的武器
						{
							// 隐藏腰部的盾牌模型
						}
						else    //普通武器
						{
							if(IsChangeAddon == 2)
							{
								// 将盾牌模型添加在使用者背上
								SetEntProp(client, Prop_Send, "m_iAddonBits", 64);
								SetEntProp(client, Prop_Send, "m_iPrimaryAddon", GameWeaponID);
							}							
						}
					}
				}
			}
			else    //当前正在使用盾牌
			{
				if(IsChangeAddon == 2)
				{
					new main = GetPlayerWeaponSlot(client, 0);
					if(main > -1)    //如果装备了主武器
					{
						decl String:sWeapon2[64];
						GetEdictClassname(main, sWeapon2, sizeof(sWeapon2));
						ReplaceStringEx(sWeapon2, strlen(sWeapon2), "_", ";");
						decl String:data[2][64];
						ExplodeString(sWeapon2, ";", data, 2, 30);			
						
						new GameWeaponID = CS_AliasToWeaponID(data[1]);
						// PrintToChat(client, "主武器ID：%d 。", GameWeaponID);
						int WeaponIdFlag = GameWeaponID;
						if(WeaponIdFlag == 0)
						{
							// 清除人物背部的盾牌模型
							// PrintToChat(client, "额外主武器ID：%d 。", GameWeaponID);
							SetEntProp(client, Prop_Send, "m_iAddonBits", 0);						
							SetEntProp(client, Prop_Send, "m_iPrimaryAddon", 0);
							SetEntProp(client, Prop_Send, "m_iPrimaryAddon", 0);
							
							// CreateTimer(0.05, Timer_PrintMessageOneTimes, client);
						}
						else
						{
							// 清除人物背部的盾牌模型
							// PrintToChat(client, "普通主武器ID：%d 。", GameWeaponID);
							SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
							SetEntProp(client, Prop_Send, "m_iSecondaryAddon", 0);
							SetEntProp(client, Prop_Send, "m_iPrimaryAddon", 0);
							
							// DataPack pack = new DataPack();
							// pack.WriteCell(client);
							// pack.WriteCell(WeaponIdFlag);
							// CreateTimer(0.05, Timer_PrintMessageOneTimes2, pack);
						}
					}
					else    //如果没有装备主武器
					{
						// 清除人物背部的盾牌模型
						SetEntProp(client, Prop_Send, "m_iPrimaryAddon", 0);
					}
					return;
				}
			}
		}		
	}
}


// public Action:Timer_PrintMessageOneTimes(Handle timer, int client)
// {
	// if(!IsValidEntity(client))
		// return Plugin_Continue;
	// if(IsClient(client, true) == true)
	// {
		// // SetEntProp(client, Prop_Send, "m_iSecondaryAddon", 0);
		// SetEntProp(client, Prop_Send, "m_iAddonBits", 128);
		// SetEntProp(client, Prop_Send, "m_iPrimaryAddon", 18);
	// }	
// }

// public Action:Timer_PrintMessageOneTimes2(Handle:timer, DataPack pack)
// {
	// pack.Reset(); 
	// int client = pack.ReadCell();
	// int WeaponIdFlag = pack.ReadCell();
	// CloseHandle(pack);
	
	// if(!IsValidEntity(client))
		// return Plugin_Continue;
	// if(IsClient(client, true) == true)
	// {
		// // SetEntProp(client, Prop_Send, "m_iSecondaryAddon", 0);
		// SetEntProp(client, Prop_Send, "m_iAddonBits", 64);
		// SetEntProp(client, Prop_Send, "m_iPrimaryAddon", WeaponIdFlag);
	// }
// }


//启用半身盾效果时，当盾牌手被击中时，检测其HitGroup
public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, 
        int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if( isEnabled3 == false || // 插件被禁用
		StrEqual("", shieldWeapon) || // 不存在应用插件的武器
		(damagetype & DMG_BULLET == 0 && damagetype & DMG_NEVERGIB == 0 && damagetype & DMG_BLAST == 0) || // 伤害不是来自子弹或刀子或手雷
		attacker < 1 ||
		attacker > MaxClients || // 攻击者不是玩家
		victim < 0 ||
		victim > MaxClients || // 受害者不是玩家
		attacker != inflictor ||
		inflictor > MaxClients || 
		!IsClientInGame(attacker) ||
		!IsClientInGame(victim) )
		{
			return Plugin_Continue; 
		}
    
	int DuckFalg = GetEntProp(victim, Prop_Send, "m_bDucked");
	if(DuckFalg == 0)    //受害者不是蹲下状态
	{
		if((hitgroup == 6 || hitgroup == 7) && IsMediumShield == 1)    //如果子弹击中脚部（且开启半身盾）
		{
			ClientHitGroup[victim] = 1;
			ClientHitGroup2[victim] = 0;
		}
		if(hitgroup == 1 && IsExposeReload == 1)    //如果子弹击中头部（且关闭换弹时的头部和右半身保护）
		{
			ClientHitGroup[victim] = 3;
			ClientHitGroup2[victim] = 1;
		}
		else
			ClientHitGroup2[victim] = 0;
	}
	if(hitgroup == 5 && IsExposeRightHand == 1)    //如果子弹击中右手（关闭右手保护）
	{
		ClientHitGroup[victim] = 2;
		ClientHitGroup2[victim] = 0;
	}			
	else
		ClientHitGroup2[victim] = 0;	
    return Plugin_Continue;
}


//调整伤害函数
public Action:OnTakeDamage2(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if( isEnabled3 == false || // 插件被禁用
		StrEqual("", shieldWeapon) || // 不存在应用插件的武器
		(damagetype & DMG_BULLET == 0 && damagetype & DMG_NEVERGIB == 0 && damagetype & DMG_BLAST == 0) || // 伤害不是来自子弹或刀子或手雷
		attacker < 1 ||
		attacker > MaxClients || // 攻击者不是玩家
		victim < 0 ||
		victim > MaxClients || // 受害者不是玩家
		(attacker != inflictor && damagetype & DMG_BLAST == 0) ||
		(inflictor > MaxClients && damagetype & DMG_BLAST == 0) || 
		!IsClientInGame(attacker) ||
		!IsClientInGame(victim) )
		{
			// PrintToChatAll("提示：不符合基本条件。");
			return Plugin_Continue; // Allow damage to go through
		}	
		
	decl Float:attackerOrigin[3], Float:victimAngles[3], Float:victimOrigin[3], vecPoints[3], vecAngles[3];
	// 检测攻击者的坐标
	GetClientEyePosition(attacker, attackerOrigin);
	// 检测受害者的角度方向
	GetClientEyeAngles(victim, victimAngles);
	// 检测受害者的坐标
	GetClientEyePosition(victim, victimOrigin);
	// 建立从受害者到攻击者的方向向量
	MakeVectorFromPoints(victimOrigin, attackerOrigin, vecPoints);
	GetVectorAngles(vecPoints, vecAngles);
		
	// PrintToChatAll("受害者索引：%d 。", victim);
	// PrintToChatAll("攻击者坐标的x：%f 。", attackerOrigin[0]);
	// PrintToChatAll("攻击者坐标的y：%f 。", attackerOrigin[1]);
	// PrintToChatAll("攻击者坐标的z：%f 。", attackerOrigin[2]);
	
	// Differenz
	new diff = RoundFloat(victimAngles[1]) - RoundFloat(vecAngles[1]);
	
	// Correct it
	if (diff < -180)
	{
		diff = 360 + diff;
	}

	if (diff > 180)
	{
		diff = 360 - diff;
	}
	// PrintToChatAll("diff转换后的值：%d 。", diff);
	
	// 检测攻击的方向
	bool ShieldSign = false;    //正面攻击
	bool ShieldSign2 = false;    //背后攻击
	bool IsRightBody = false;    //攻击来自右前方
	
	// 打中前方
	if (diff >= -22.5 && diff < 22.5)
	{
		ShieldSign = true;
	}

	// 打中右前方
	else if (diff >= 22.5 && diff < 67.5)
	{
		ShieldSign = true;
		IsRightBody = true;
	}

	// 打中右方
	else if (diff >= 67.5 && diff < 112.5)
	{
		ShieldSign = false;
		ShieldSign2 = false;
	}

	// 打中右后方
	else if (diff >= 112.5 && diff < 157.5)
	{
		ShieldSign2 = true;
	}

	// 打中后方
	else if (diff >= 157.5 || diff < -157.5)
	{
		ShieldSign2 = true;
	}

	// 打中左后方
	else if (diff >= -157.5 && diff < -112.5)
	{
		ShieldSign2 = true;
	}

	// 打中左方
	else if (diff >= -112.5 && diff < -67.5)
	{
		ShieldSign = false;
		ShieldSign2 = false;
	}

	// 打中左前方
	else if (diff >= -67.5 && diff < -22.5)
	{
		ShieldSign = true;
	}
	
	// 检测受害者使用的武器
	if(HasEntProp(victim, Prop_Send, "m_hActiveWeapon") == false)
		return Plugin_Continue;
	new currentWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
		return Plugin_Continue;
	decl String:sWeapon[32];
	GetEdictClassname(currentWeapon, sWeapon, sizeof(sWeapon));

    // 如果受害者正在使用盾牌
	if(StrEqual(shieldWeapon, sWeapon))
	{
		if(ShieldSign == true)    // 被正面攻击
		{	
		    // 开启换弹时不保护头部和右半身，且当盾牌手换弹时被击中头部或右半身，不能减伤
			if((ClientHitGroup[victim] == 3 || IsRightBody == true) && IsExposeReload == true && ShieldIsReload[victim] == 1)
			{
				// PrintToChat(victim, "提示：盾牌手换弹时被右前方的子弹击中或者被爆头，不能减伤！");
				// PrintToChat(attacker, "提示：盾牌手换弹时被右前方的子弹击中或者被爆头，不能减伤！");
				ClientHitGroup[victim] = 0;
				return Plugin_Continue;
			}
	
			new Float: Pos[3], Float: OutputDir[3], Float: OutputPos[3], Float: OutputDir2[3];
			GetEntPropVector(currentWeapon, Prop_Data, "m_vecAbsOrigin", Pos);    //获取盾牌坐标
			//产生金属火花
			if(isEnabledSpark == true)    
			{				
				float Distance = 0;
				Distance = GetVectorDistance(victimOrigin, damagePosition);
				MoveForward(damagePosition, victimAngles, OutputPos, Distance - 7.0);
				// PrintToChatAll("着弹点高度差：%d。", MyLength);
				
				// MakeVectorFromPoints(damagePosition, OutputPos, OutputDir); 
				OutputDir2[0] = victimAngles[0];
				OutputDir2[1] = victimAngles[1];
				OutputDir2[2] = victimAngles[2] + 30.0;
				TE_SetupSparks(OutputPos, OutputDir2, 1, 1); 
				// TE_SetupSparks(OutputPos, OutputDir, 1, 1); 
				TE_SendToAll();	
			}
			
			Shake(victim, damage * 0.15, 0.3);    //被击中产生震动
			switch(GetRandomInt(1,4))    //播放金属响声
			{
				case 1: EmitAmbientSound("physics/metal/metal_box_impact_bullet1.wav", Pos, currentWeapon, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
				case 2: EmitAmbientSound("physics/metal/metal_solid_impact_bullet2.wav", Pos, currentWeapon, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
				case 3: EmitAmbientSound("physics/metal/metal_solid_impact_bullet3.wav", Pos, currentWeapon, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
				case 4: EmitAmbientSound("physics/metal/metal_solid_impact_bullet4.wav", Pos, currentWeapon, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
			}
			
			if(damagetype & DMG_BLAST != 0)
			{
				// PrintToChatAll("提示：爆炸攻击！伤害减免30%。");
				damage = damage * 0.7;    //爆炸伤害只能减免30%
				return Plugin_Changed;
			}			
            if(IsMediumShield == 1 && ClientHitGroup[victim] == 1)	
			{
				// PrintToChatAll("提示：装备半身盾且不蹲下时子弹打中脚部！伤害减免50%。");
				damage = damage * 0.5;     //装备半身盾且不蹲下时子弹打中脚部伤害只能减免50%
				ClientHitGroup[victim] = 0;
				return Plugin_Changed;
			}
			if(IsExposeRightHand == 1 && ClientHitGroup[victim] == 2)	
			{
				// PrintToChatAll("提示：设置右手露出盾牌时且子弹打中右手！伤害减免30%。");
				damage = damage * 0.7;     //右手露出盾牌时且子弹打中右手伤害只能减免30%
				ClientHitGroup[victim] = 0;
				return Plugin_Changed;
			}
			else
			{
				damage = 0.0;   
				return Plugin_Changed;    // 受害者正在使用盾牌，伤害无效
			}
		}
		else
		    return Plugin_Continue;    //受害者正在使用盾牌，但是子弹是从背后射来，伤害有效 
	}
	
    // 如果受害者没有使用盾牌	
	else
	{
		bool ShieldOnBack = false;    //检测盾牌有没有在背上
		new main = GetPlayerWeaponSlot(victim, 0);
		new pistol = GetPlayerWeaponSlot(victim, 1);
		new knife = GetPlayerWeaponSlot(victim, 2);
		new MyShield = 0;
		if(main > -1)
		{
			decl String:sWeapon2[32];
			GetEdictClassname(main, sWeapon2, sizeof(sWeapon2));
			if(StrEqual(shieldWeapon, sWeapon2))
			{
				ShieldOnBack = true;
				MyShield = main;
			}				
		}
		if(pistol > -1)
		{
			decl String:sWeapon2[32];
			GetEdictClassname(pistol, sWeapon2, sizeof(sWeapon2));
			if(StrEqual(shieldWeapon, sWeapon2))
			{
				ShieldOnBack = true;
				MyShield = pistol;
			}
		}
		if(knife > -1)
		{
			decl String:sWeapon2[32];
			GetEdictClassname(knife, sWeapon2, sizeof(sWeapon2));
			if(StrEqual(shieldWeapon, sWeapon2))    
			{
				ShieldOnBack = true;
				MyShield = knife;
			}
		}
		
		// 如果受害者的盾牌在背上（未使用）
		if(ShieldOnBack == true)
		{
			if(ShieldSign2 == true)  //背面攻击
			{			
				new Float: Pos[3], Float: OutputDir[3], Float: OutputPos[3];
				GetEntPropVector(MyShield, Prop_Data, "m_vecAbsOrigin", Pos);    //获取盾牌坐标
				//产生金属火花
				if(isEnabledSpark == true)    
				{
					float Distance = 0;
					Distance = GetVectorDistance(victimOrigin, damagePosition);
					MoveForward(damagePosition, victimAngles, OutputPos, -1.0 * (Distance + 5.0));
					// PrintToChatAll("着弹点高度差：%d。", MyLength);

					MakeVectorFromPoints(victimOrigin, attackerOrigin, OutputDir);  
					
					OutputDir[2] = OutputDir[2] + 60.0;
					
					TE_SetupSparks(OutputPos, OutputDir, 1, 1);    
					TE_SendToAll();	
				}
				
				Shake(victim, damage * 0.1, 0.3);    //被击中产生震动
				switch(GetRandomInt(1,4))    //播放金属响声
				{
					case 1: EmitAmbientSound("physics/metal/metal_box_impact_bullet1.wav", Pos, MyShield, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
					case 2: EmitAmbientSound("physics/metal/metal_solid_impact_bullet2.wav", Pos, MyShield, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
					case 3: EmitAmbientSound("physics/metal/metal_solid_impact_bullet3.wav", Pos, MyShield, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
					case 4: EmitAmbientSound("physics/metal/metal_solid_impact_bullet4.wav", Pos, MyShield, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
				}
				
				if(damagetype & DMG_BLAST != 0)
				{
					// PrintToChatAll("提示：爆炸攻击！伤害减免30%。");
					damage = damage * 0.7;    //爆炸伤害只能减免30%
					return Plugin_Changed;
				}	
                if(IsMediumShield == 1 && ClientHitGroup[victim] == 1)	
				{
					// PrintToChatAll("提示：装备半身盾且不蹲下时子弹打中脚部！伤害减免50%。");
					damage = damage * 0.5;     //装备半身盾且不蹲下时子弹打中脚部伤害只能减免50%
					ClientHitGroup[victim] = 0;
					return Plugin_Changed;
				}
				if(IsExposeRightHand == 1 && ClientHitGroup[victim] == 2)	
				{
					// PrintToChatAll("提示：设置右手露出盾牌时且子弹打中右手！伤害减免30%。");
					damage = damage * 0.7;     //右手露出盾牌时且子弹打中右手伤害只能减免30%
					ClientHitGroup[victim] = 0;
					return Plugin_Changed;
				}				
				else
				{
					damage = 0.0;   
					return Plugin_Changed;    //受攻击者正在背着盾牌！伤害无效
				}
			}
			else
				return Plugin_Continue;     // 受害者正在背着盾牌，但是子弹是从正面射来，伤害正常
		}
		// 受害者没有使用或装备盾牌
		else
		{
			// 初始化变量
			decl Float:attackerloc[3], Float:bulletvec[3], Float:bulletang[3];
			// GetClientEyePosition(attacker, attackerloc);
			GetEntPropVector(attacker, Prop_Data, "m_vecAbsOrigin", attackerloc);
			MakeVectorFromPoints(attackerloc, damagePosition, bulletvec);
			GetVectorAngles(bulletvec, bulletang);
			
			// 追踪子弹击中的第一个受害者
			g_TRIgnore[attacker] = true; // Tell traceray to ignore collisions with the attacker
			TR_TraceRayFilter(attackerloc, bulletang, MASK_ALL, RayType_Infinite, TraceRayHitPlayer); // Try to hit a player
			new obstruction = TR_GetEntityIndex(); // Find first entity in traceray path
			g_TRIgnore[attacker] = false;
			
			// 如果子弹击中的第一个受害者不是当前受害者
			if(obstruction != victim)
			{		
				// 子弹击中的第一个受害者是人类
				if( obstruction > 0 &&
					obstruction <= MaxClients &&
					IsClientInGame(obstruction) )
				{
					// decl String:TempName[64];
					// GetClientName(victim, TempName, sizeof(TempName));
					// PrintToChatAll("被已击穿一人的子弹击中的受害者名字是 %s 。", TempName);
					
					bool HasShield = false;    //检测第一个受害者有没有装备盾牌
					new main2 = GetPlayerWeaponSlot(obstruction, 0);
					new pistol2 = GetPlayerWeaponSlot(obstruction, 1);
					new knife2 = GetPlayerWeaponSlot(obstruction, 2);
					if(main2 > -1)
					{
						decl String:sWeapon3[32];
						GetEdictClassname(main2, sWeapon3, sizeof(sWeapon3));
						if(StrEqual(shieldWeapon, sWeapon3))
							HasShield = true;
					}
					if(pistol2 > -1)
					{
						decl String:sWeapon3[32];
						GetEdictClassname(pistol2, sWeapon3, sizeof(sWeapon3));
						if(StrEqual(shieldWeapon, sWeapon3))
							HasShield = true;
					}
					if(knife2 > -1)
					{
						decl String:sWeapon3[32];
						GetEdictClassname(knife2, sWeapon3, sizeof(sWeapon3));
						if(StrEqual(shieldWeapon, sWeapon3))
							HasShield = true;
					}
					
					// 如果第一个受害者装备了盾牌（使用中或者背着均可）
					if(HasShield == true)    
					{
						decl Float:victimAngles2[3], Float:victimOrigin2[3], vecPoints2[3], vecAngles2[3];
						// 检测第一个受害者方向角度
						GetClientEyeAngles(obstruction, victimAngles2);
						// 检测第一个受害者的的坐标
						GetClientEyePosition(obstruction, victimOrigin2);
						// 建立从第一个受害者到攻击者的方向向量
						MakeVectorFromPoints(victimOrigin2, attackerOrigin, vecPoints2);
						GetVectorAngles(vecPoints2, vecAngles2);
						
						// Differenz
						new diff2 = RoundFloat(victimAngles2[1]) - RoundFloat(vecAngles2[1]);
						
						// Correct it
						if (diff2 < -180)
						{
							diff2 = 360 + diff;
						}

						if (diff2 > 180)
						{
							diff2 = 360 - diff;
						}
						bool ShieldSign3 = true;     //
						// 打中右方						
						if (diff >= 67.5 && diff < 112.5)
						{
							ShieldSign3 = false;
						}
						// 打中左方
						if (diff >= -112.5 && diff < -67.5)
						{
							ShieldSign3 = false;
						}
						
						if(ShieldSign3 == true)    //攻击方向不是正左或正右
						{
							// 开启换弹时不保护头部和右半身，且当盾牌手换弹时被击中头部或右半身，背后的人也不能减伤
							if((ClientHitGroup2[obstruction] == 1 || IsRightBody == true) && IsExposeReload == true && ShieldIsReload[obstruction] == 1)
							{
								// PrintToChat(victim, "提示：盾牌手换弹时被右前方的子弹击中或者被爆头，背后的人不能减伤！");
								// PrintToChat(obstruction, "提示：盾牌手换弹时被右前方的子弹击中或者被爆头，背后的人不能减伤！");
								// PrintToChat(attacker, "提示：盾牌手换弹时被右前方的子弹击中或者被爆头，背后的人不能减伤！");
								ClientHitGroup2[obstruction] = 0;
								return Plugin_Continue;
							}
							
							if(damagetype & DMG_BLAST != 0)
							{
								// PrintToChatAll("提示：爆炸攻击！伤害减免30%。");
								damage = damage * 0.7;    //爆炸伤害只能减免30%
								return Plugin_Changed;
							}				
							else
							{
								damage = 0.0;   
								// PrintToChatAll("提示：受攻击者在盾牌手后面！伤害无效。");
								return Plugin_Changed;
							}								
						}
						else    //攻击方向是正左或正右
						{
							// PrintToChatAll("提示：受攻击者在盾牌手正侧面，伤害正常。");
							return Plugin_Continue;
						}
					}
					// 如果受害者没有装备盾牌，则伤害正常
					else
					    return Plugin_Continue; 	
				}
				
				// 如果子弹击中的第一个受害者不是人类，则伤害正常
				else
				{
					return Plugin_Continue;    
				}
			}
		}
	}

}


//屏幕晃动函数
Shake(client, Float:flAmplitude, Float:flDuration)
{
	if (IsFakeClient(client))
	{
		return 0;
	}
	new Handle:hBf = StartMessageOne("Shake", client, 0);
	BfWriteByte(hBf, 0);
	BfWriteFloat(hBf, flAmplitude);
	BfWriteFloat(hBf, 1.0);
	BfWriteFloat(hBf, flDuration);
	EndMessage();
	return 0;
}


public bool:TraceRayHitPlayer(entity, mask)
{
	// Check if the ray hits an entity, and stop if it does
	if(entity > 0 && entity <= MaxClients && !g_TRIgnore[entity])
		return true;
	return false;
}


UpdateAllConvars()
{
	for(new i = 0; i < MAXPLAYERS; i++)
	{
		g_TRIgnore[i] = false;
		g_Ignore[i] = 0;	
	}
}

public Action:RoundStart3(Handle:event, const String:name[], bool:dontBroadcast) 
{
	for(new i = 0; i < MAXPLAYERS; i++)
	{
		ClientHitGroup[i] = 0;
		ClientHitGroup2[i] = 0;		
		ShieldIsReload[i] = 0;
	}
}


// 求距坐标的正前方指定距离的坐标
stock MoveForward(const Float:vPos[3], const Float:vAng[3], Float:vReturn[3], Float:fDistance)
{
    decl Float:vDir[3];
    GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
    vReturn = vPos;
    vReturn[0] += vDir[0] * fDistance;
    vReturn[1] += vDir[1] * fDistance;
} 