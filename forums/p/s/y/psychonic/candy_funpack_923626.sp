#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.4.4"

public Plugin:myinfo = 
{
	name = "Fun package for Candy",
	author = "GachL",
	description = "This plugin is a pack of functions that work well with Candy for TF2.",
	version = PLUGIN_VERSION,
	url = "http://bloodisgood.org"
}

new Handle:cvNoiseLevel;
//new Handle:sdkRegenerate;
new bool:bPlayerHasCrit[MAXPLAYERS]

public OnPluginStart()
{
	RegAdminCmd("sm_candy_buy_crit", cBuyCrit, ADMFLAG_BAN, "Get crit 100%");
	RegAdminCmd("sm_candy_buy_invincible", cBuyInvincible, ADMFLAG_BAN, "Get invincibility");
	RegAdminCmd("sm_candy_buy_uber", cBuyUber, ADMFLAG_BAN, "Get instant uber (medic)");
	//RegAdminCmd("sm_candy_buy_regen", cBuyRegen, ADMFLAG_BAN, "Fill health and ammo");
	//RegAdminCmd("sm_candy_buy_repair", cBuyRepair, ADMFLAG_BAN, "Instant repair all buildings (engineer)");
	//RegAdminCmd("sm_candy_buy_invisible", cBuyInvisibility, ADMFLAG_BAN, "Be invisible");
	//RegAdminCmd("sm_candy_buy_noreload", cBuyReload, ADMFLAG_BAN, "No reloading needed");
	RegAdminCmd("sm_candy_buy_slay", cBuySlay, ADMFLAG_BAN, "Slay a player!");
	
	/*StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "Regenerate");
	sdkRegenerate = EndPrepSDKCall();
	*/
	cvNoiseLevel = CreateConVar("sm_candy_buy_noiselevel", "2", "1 = silent, 2 = buyer only, 3 = everyone", FCVAR_PLUGIN, true, 1.0, true, 3.0);
}

public Action:cBuyCrit(cclient, args)
{
	new String:sErrStr[] = "[candypack] Usage: sm_candy_buy_crit <userid> <onoff>";
	if (args < 2)
	{
		PrintToServer(sErrStr);
		return Plugin_Handled;
	}
	new String:sclient[32];
	GetCmdArg(1, sclient, sizeof(sclient));
	new client = GetClientOfUserId(StringToInt(sclient));
	if (!FullCheckClient(client))
	{
		PrintToServer(sErrStr);
		return Plugin_Handled;
	}
	new String:sonoff[32];
	GetCmdArg(2, sonoff, sizeof(sonoff));
	new onoff = StringToInt(sonoff);
	new noise = GetConVarInt(cvNoiseLevel);
	
	if (onoff == 1)
	{
		SetPlayerCrit(client, true);
		if (noise == 2)
		{
			PrintToChat(client, "Enabled criticals on you!");
		}
		else if (noise == 3)
		{
			new String:name[128];
			GetClientName(client, name, sizeof(name));
			PrintToChatAll("Enabled criticals on %s!", name);
		}
	}
	else
	{
		SetPlayerCrit(client, false);
		if (noise == 2)
		{
			PrintToChat(client, "Disabled criticals on you!");
		}
		else if (noise == 3)
		{
			new String:name[128];
			GetClientName(client, name, sizeof(name));
			PrintToChatAll("Disabled criticals on %s!", name);
		}
	}
	
	return Plugin_Handled;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (PlayerHasCrit(client))
	{
		result = true;
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}

public bool:PlayerHasCrit(client)
{
	return bPlayerHasCrit[client-1];
}

public SetPlayerCrit(client, bool:onoff)
{
	bPlayerHasCrit[client-1] = onoff;
}

public Action:cBuyInvincible(cclient, args)
{
	new String:sErrStr[] = "[candypack] Usage: sm_candy_buy_invincible <userid> <onoff>";
	if (args < 2)
	{
		PrintToServer(sErrStr);
		return Plugin_Handled;
	}
	new String:sclient[32];
	GetCmdArg(1, sclient, sizeof(sclient));
	new client = GetClientOfUserId(StringToInt(sclient));
	if (!FullCheckClient(client))
	{
		PrintToServer(sErrStr);
		return Plugin_Handled;
	}
	new String:sonoff[32];
	GetCmdArg(2, sonoff, sizeof(sonoff));
	new onoff = StringToInt(sonoff);
	new noise = GetConVarInt(cvNoiseLevel);
	
	if (onoff == 1)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		if (noise == 2)
		{
			PrintToChat(client, "Enabled invincibility on you!");
		}
		else if (noise == 3)
		{
			new String:name[128];
			GetClientName(client, name, sizeof(name));
			PrintToChatAll("Enabled invincibility on %s!", name);
		}
	}
	else
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		if (noise == 2)
		{
			PrintToChat(client, "Disabled invincibility on you!");
		}
		else if (noise == 3)
		{
			new String:name[128];
			GetClientName(client, name, sizeof(name));
			PrintToChatAll("Disabled invincibility on %s!", name);
		}
	}
	return Plugin_Handled;
}

public Action:cBuyUber(cclient, args)
{
	new String:sErrStr[] = "[candypack] Usage: sm_candy_buy_uber <userid> <percent>";
	if (args < 2)
	{
		PrintToServer(sErrStr);
		return Plugin_Handled;
	}
	new String:sclient[32];
	GetCmdArg(1, sclient, sizeof(sclient));
	new client = GetClientOfUserId(StringToInt(sclient));
	if (!FullCheckClient(client))
	{
		PrintToServer(sErrStr);
		return Plugin_Handled;
	}
	new String:sonoff[32];
	GetCmdArg(2, sonoff, sizeof(sonoff));
	new onoff = StringToInt(sonoff);
	new noise = GetConVarInt(cvNoiseLevel);
	
	if (TF2_GetPlayerClass(client) == TF2_GetClass("medic"))
	{
		new iSlot = GetPlayerWeaponSlot(client, 1);
		if (iSlot > 0)
			SetEntPropFloat(iSlot, Prop_Send, "m_flChargeLevel", onoff*0.01);
		if (noise == 2)
		{
			PrintToChat(client, "Gave you %i\% ubercharge!", onoff);
		}
		else if (noise == 3)
		{
			new String:name[128];
			GetClientName(client, name, sizeof(name));
			PrintToChatAll("Gave %s %i\% ubercharge!", name, onoff);
		}
	}
	return Plugin_Handled;
}

public Action:cBuyRegen(cclient, args)
{
	new String:sErrStr[] = "[candypack] Usage: sm_candy_buy_regen <userid>";
	if (args < 1)
	{
		PrintToServer(sErrStr);
		return Plugin_Handled;
	}
	new String:sclient[32];
	GetCmdArg(1, sclient, sizeof(sclient));
	new client = GetClientOfUserId(StringToInt(sclient));
	if (!FullCheckClient(client))
	{
		PrintToServer(sErrStr);
		return Plugin_Handled;
	}
	new noise = GetConVarInt(cvNoiseLevel);
	
	new iClassHealth[] = {-1, 125, 125, 200, 175, 150, 300, 175, 125, 125};
	SetEntityHealth(client, iClassHealth[GetEntProp(client, Prop_Send, "m_iClass")]);
	if (noise == 2)
	{
		PrintToChat(client, "Gave you full health and ammo!");
	}
	else if (noise == 3)
	{
		new String:name[128];
		GetClientName(client, name, sizeof(name));
		PrintToChatAll("Gave %s full health and ammo!", name);
	}
	return Plugin_Handled;
}

public Action:cBuyRepair(cclient, args)
{
	return Plugin_Handled;
}

public Action:cBuyInvisibility(cclient, args)
{
	return Plugin_Handled;
}

public Action:cBuyReload(cclient, args)
{
	return Plugin_Handled;
}

public Action:cBuySlay(cclient, args)
{
	new String:sErrStr[] = "[candypack] Usage: sm_candy_buy_slay <userid>";
	if (args < 1)
	{
		PrintToServer(sErrStr);
		return Plugin_Handled;
	}
	new String:sclient[32];
	GetCmdArg(1, sclient, sizeof(sclient));
	new client = GetClientOfUserId(StringToInt(sclient));
	if (!FullCheckClient(client))
	{
		PrintToServer(sErrStr);
		return Plugin_Handled;
	}
	
	new Handle:hMenu = CreateMenu(cSlayPlayer);
	SetMenuTitle(hMenu, "Slay who?");
	for (new i = 1; i <= GetClientCount(); i++)
	{
		new String:sName[255], String:sInfo[4];
		GetClientName(i, sName, sizeof(sName));
		IntToString(i, sInfo, sizeof(sInfo));
		AddMenuItem(hMenu, sInfo, sName);
	}
	DisplayMenu(hMenu, client, 20);
	
	return Plugin_Handled;
}

public cSlayPlayer(Handle:menu, MenuAction:action, client, result)
{
	if (action == MenuAction_Select)
	{
		new String:info[32], String:sAName[255], String:sVName[255];
		GetMenuItem(menu, result, info, sizeof(info))
		new hTarget = StringToInt(info);
		GetClientName(client, sAName, sizeof(sAName));
		GetClientName(hTarget, sVName, sizeof(sVName));
		
		SlapPlayer(hTarget, GetClientHealth(hTarget) + 10, false); // +10 just to be sure
		new noise = GetConVarInt(cvNoiseLevel);
		if (noise > 1)
		{
			PrintToChat(client, "You slayed %s", sVName);
			PrintToChat(hTarget, "%s slayed you", sAName);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

public bool:FullCheckClient(client)
{
	if (client < 1)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	return true;
}

