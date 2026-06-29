#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS FCVAR_NOTIFY
#define DEBUG 0

ConVar	Coin_Drop_Switch, Coin_Drop_Num, Coin_Drop_Model_Case, Coin_Drop_Model_Alpha, Coin_Drop_Clear_Time, Coin_Glow_Switch, Coin_Glow_Color, Coin_Glow_Range; 
ConVar	Weapon_Drop_Glow_Switch, Weapon_Drop_Glow_Color, Weapon_Drop_Glow_Range;
int		g_Coin_Drop_Num, g_Coin_Drop_Model_Case, g_Coin_Drop_Model_Alpha, g_Coin_Drop_Clear_Time, g_Coin_Glow_Range, g_Weapon_Drop_Glow_Range;
char	g_Coin_Glow_Color[64], g_Weapon_Drop_Glow_Color[64];
bool	g_Coin_Drop_Switch, g_Coin_Glow_Switch, g_Weapon_Drop_Glow_Switch;

char c_models[][] = 
{
	"models/props_collectables/coin.mdl",		//0 Coin
	"models/props_collectables/gold_bar.mdl",	//1 GoldBar
	"models/props_collectables/money_wad.mdl"	//2 Money
};

public Plugin myinfo = 
{
	name 		= "drop coins and glowing dropped weapons when players dead",
	author 		= "CD意识STEAM_1:0:211123334 (Alliedmods:kazya3)",
	description = "drop coins and glowing dropped weapons when players dead",
	version 	= "1.2",
	url 		= "https://steamcommunity.com/profiles/76561198382512396/"
}

public void OnPluginStart()
{
	Coin_Drop_Switch		= CreateConVar("L4D2_Coin_Drop_Switch", 		"1", 			"Enable drop coins when player dead",				CVAR_FLAGS, true, 0.0, true, 1.0);
	Coin_Drop_Num			= CreateConVar("L4D2_Coin_Drop_Num", 			"10", 			"Number of dropped coins",							CVAR_FLAGS, true, 0.0, true, 999.0);
	Coin_Drop_Model_Case	= CreateConVar("L4D2_Coin_Drop_Model_Case", 	"3", 			"Coin model, 0:coin 1:goldBar 2:money 3:random",	CVAR_FLAGS, true, 0.0, true, 3.0);
	Coin_Drop_Model_Alpha	= CreateConVar("L4D2_Coin_Drop_Model_Alpha", 	"255", 			"Coin model Alpha",									CVAR_FLAGS, true, 0.0, true, 255.0);
	Coin_Drop_Clear_Time	= CreateConVar("L4D2_Coin_Drop_Clear_Time", 	"10", 			"Clear coin time (Seconds)",						CVAR_FLAGS, true, 0.0, true, 999.0);
	Coin_Glow_Switch		= CreateConVar("L4D2_Coin_Glow_Switch", 		"0", 			"Enable coin glowing",								CVAR_FLAGS, true, 0.0, true, 1.0);
	Coin_Glow_Color			= CreateConVar("L4D2_Coin_Glow_Color", 			"255 170 0", 	"Coin glowing colors (RGB)",					 	CVAR_FLAGS);
	Coin_Glow_Range			= CreateConVar("L4D2_Coin_Glow_Range", 			"2000", 		"Coin glowing range",								CVAR_FLAGS, true, 0.0, true, 9999.0);
	Weapon_Drop_Glow_Switch	= CreateConVar("L4D2_Weapon_Drop_Glow_Switch", 	"1", 			"Enable dropped weapons glowing when player dead",	CVAR_FLAGS, true, 0.0, true, 1.0);
	Weapon_Drop_Glow_Color	= CreateConVar("L4D2_Weapon_Drop_Glow_Color", 	"255 170 0", 	"Weapons glowing colors (RGB)",					 	CVAR_FLAGS);
	Weapon_Drop_Glow_Range	= CreateConVar("L4D2_Weapon_Drop_Glow_Range", 	"2000", 		"Weapons glowing range",						 	CVAR_FLAGS, true, 0.0, true, 9999.0);
	// SDKHOOK
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_WeaponDropPost , OnWeaponDropped);
	}

	GetCvars();
	Coin_Drop_Switch.AddChangeHook(ConVarChanges); 
	Coin_Drop_Num.AddChangeHook(ConVarChanges); 
	Coin_Drop_Model_Case.AddChangeHook(ConVarChanges); 
	Coin_Drop_Model_Alpha.AddChangeHook(ConVarChanges); 
	Coin_Drop_Clear_Time.AddChangeHook(ConVarChanges); 
	Coin_Glow_Switch.AddChangeHook(ConVarChanges); 
	Coin_Glow_Color.AddChangeHook(ConVarChanges); 
	Coin_Glow_Range.AddChangeHook(ConVarChanges);
	Weapon_Drop_Glow_Switch.AddChangeHook(ConVarChanges);
	Weapon_Drop_Glow_Color.AddChangeHook(ConVarChanges);
	Weapon_Drop_Glow_Range.AddChangeHook(ConVarChanges);
	HookEvent("player_death", Event_PlayerDeath);

	AutoExecConfig(true, "l4d2_drop_coins_v1.2");
}

//////////////////////////////////////////初始化相关//////////////////////////////////////////
void ConVarChanges(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_Coin_Drop_Switch 			= Coin_Drop_Switch.BoolValue;
	g_Coin_Drop_Num 			= Coin_Drop_Num.IntValue;
	g_Coin_Drop_Model_Case 		= Coin_Drop_Model_Case.IntValue; 
	g_Coin_Drop_Model_Alpha		= Coin_Drop_Model_Alpha.IntValue; 
	g_Coin_Drop_Clear_Time 		= Coin_Drop_Clear_Time.IntValue;
	g_Coin_Glow_Switch			= Coin_Glow_Switch.BoolValue;
	if(g_Coin_Glow_Switch)
	{
		g_Coin_Glow_Range 		= Coin_Glow_Range.IntValue; 
		Coin_Glow_Color.GetString(g_Coin_Glow_Color, sizeof(g_Coin_Glow_Color));
	}
	g_Weapon_Drop_Glow_Switch = Weapon_Drop_Glow_Switch.BoolValue;
	if(g_Weapon_Drop_Glow_Switch)
	{
		g_Weapon_Drop_Glow_Range = Weapon_Drop_Glow_Range.IntValue; 
		Weapon_Drop_Glow_Color.GetString(g_Weapon_Drop_Glow_Color, sizeof(g_Weapon_Drop_Glow_Color));
	}
}

// 缓存
public void OnMapStart()
{
	for (int i = 0; i < sizeof(c_models); i++)
	{
		PrecacheModel(c_models[i]);
	}
}

//////////////////////////////////////////死亡//////////////////////////////////////////
void Event_PlayerDeath(Event event, const char[] name, bool dontbroadcast)
{
	if(!g_Coin_Drop_Switch)	return;
	if(entityCount() > (1900 - g_Coin_Drop_Num)) return; //防止太多实体炸服 一张图最多允许2048,我还额外给地图预留了148个槽位
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(!isSurvivor(victim))	return;
	for(int i; i < g_Coin_Drop_Num; i ++)
	{
		int coin = CreateEntityByName("prop_physics_override");
		if(IsValidEnt(coin))
		{
			int index = g_Coin_Drop_Model_Case == 3 ? GetRandomInt(0,sizeof(c_models)-1) : g_Coin_Drop_Model_Case;
			DispatchKeyValue(coin, "model", c_models[index]);
			float CoinPos[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", CoinPos);
			// DispatchKeyValueVector(coin, "origin", CoinPos);
			DispatchKeyValue(coin, "solid", "0");
			DispatchKeyValue(coin, "spawnflags", "8454"); // "Don`t take physics damage" + "Generate output on +USE" + "Force Server Side" + "ignore player"
			DispatchSpawn(coin);
			char io[64];
			FormatEx(io, sizeof(io), "OnUser1 !self:kill::%d.0:-1", g_Coin_Drop_Clear_Time);
			SetVariantString(io);
			AcceptEntityInput(coin, "AddOutput");
			SetEntityRenderMode(coin, RENDER_TRANSCOLOR);
			if(g_Coin_Drop_Clear_Time >= 3)
			{
				char io2[64];
				// FormatEx(io2, sizeof(io2), "OnUser1 !self:AddOutput:renderfx 6:%d.0:-1", g_Coin_Drop_Clear_Time - 3);
				FormatEx(io2, sizeof(io2), "OnUser1 !self:FireUser2::%d.0:-1", g_Coin_Drop_Clear_Time - 3);
				SetVariantString(io2);
				AcceptEntityInput(coin, "AddOutput");
				HookSingleEntityOutput(coin, "OnUser2", FadeOut_OnUser2);
			}
			AcceptEntityInput(coin, "FireUser1");

			if(g_Coin_Drop_Model_Alpha < 255)
			{
				// SetEntityRenderMode(coin, RenderMode:3);
				SetEntityRenderColor(coin, 255, 255, 255, g_Coin_Drop_Model_Alpha);
			}

			if(g_Coin_Glow_Switch) createWeaponGlow(coin, g_Coin_Glow_Color, 2, g_Coin_Glow_Range);
			float force[3];
			force[0] = GetRandomFloat(-200.0, 200.0);
			force[1] = GetRandomFloat(-200.0, 200.0);
			force[2] = 800.0;
			float CoinAngle[3];
			CoinAngle[0] = GetRandomFloat(-180.0, 180.0);
			CoinAngle[1] = GetRandomFloat(-180.0, 180.0);
			CoinAngle[2] = GetRandomFloat(-180.0, 180.0);			
			TeleportEntity(coin, CoinPos, CoinAngle, force);
		}
	}
	PrintToChatAll("\x03%N \x04Dead.", victim);
}

void FadeOut_OnUser2(const char[] name, int caller, int activator, float delay)
{
	if(IsValidEnt(caller))
	{
		SetEntityRenderFx(caller, RENDERFX_FADE_FAST);
		// 我不确定需不需要在实体被删除前unhook，不知道删除时候会不会自动脱钩
		// i dont know is this necessary or will automatic unhook when entity be killed？
		UnhookSingleEntityOutput(caller, "OnUser2", FadeOut_OnUser2);
	}
}

////////////////////////////////  sdkhook相关   ////////////////////////////////
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponDropPost , OnWeaponDropped);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponDropPost, OnWeaponDropped);
}

void OnWeaponDropped(int client, int weapon)
{
	if (IsValidEnt(weapon) && isSurvivor(client) && g_Weapon_Drop_Glow_Switch)
	{
		if (GetClientHealth(client) > 0) createWeaponGlow(weapon, "0 0 0", 2, g_Weapon_Drop_Glow_Range);
		else createWeaponGlow(weapon, g_Weapon_Drop_Glow_Color, 2, g_Weapon_Drop_Glow_Range);
	}
}

//////////////////////////////// 创建武器轮廓   ////////////////////////////////
void createWeaponGlow(int weapon, char[] colors, int type, int range)
{
	SetEntProp(weapon, Prop_Send, "m_iGlowType", type);
	SetEntProp(weapon, Prop_Send, "m_glowColorOverride", GetColor(colors));
	SetEntProp(weapon, Prop_Send, "m_nGlowRange", range);
}

//////////////////////////////// func ////////////////////////////////
int entityCount()
{
	int count = 0, ent = -1;
	while ((ent = FindEntityByClassname(ent, "*")) != -1) count++;
	#if DEBUG
	PrintToChatAll("[debug] entity count: %d", count);
	#endif
	return count;
}

int GetColor(char[] sTemp)
{
	if (strcmp(sTemp, "") == 0) return 0;
	char sColors[3][4];
	int	 iColor = ExplodeString(sTemp, " ", sColors, 3, 4);
	if (iColor != 3) return 0;
	iColor = StringToInt(sColors[0]);
	iColor += 256 * StringToInt(sColors[1]);
	iColor += 65536 * StringToInt(sColors[2]);
	return iColor;
}

bool isSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2;
}

bool IsValidEnt(int entity)
{
	return (entity > 0 && entity > MaxClients && IsValidEntity(entity) && entity != INVALID_ENT_REFERENCE);
}
