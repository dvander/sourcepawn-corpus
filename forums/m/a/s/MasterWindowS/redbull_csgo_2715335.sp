


#include <sdktools>

ConVar Cvar_Enabled;
ConVar Cvar_EffectTime;
ConVar Cvar_Health;
ConVar Cvar_Armor;
ConVar Cvar_Speed;
ConVar Cvar_Cost;

Handle TimerEffect[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Red Bull: Csgo",
	author = "tuty, Bacardi, MasterWindowS",
	description = "Say !redbull to buy a redbull.",
	version = "24.08.2020",
	url = "https://forums.alliedmods.net/showpost.php?p=2715166&postcount=29"
};

public void OnPluginStart()
{
	if(GetUserMessageId("Fade") == INVALID_MESSAGE_ID) SetFailState("Couldn't find UserMessage Fade");

	Cvar_Enabled = CreateConVar("redbull_enabled", "1.0", _, FCVAR_NONE, true, 0.0, true, 1.0);
	Cvar_EffectTime = CreateConVar("redbull_time", "0", _, FCVAR_NONE, true, 5.0, true, 60.0);
	Cvar_Health = CreateConVar("redbull_health", "50.0", _, FCVAR_NONE, true, 0.0);
	Cvar_Armor = CreateConVar("redbull_armor", "0", _, FCVAR_NONE, true, 0.0);
	Cvar_Speed = CreateConVar("redbull_speed", "0", _, FCVAR_NONE, true, 1.0, true, 6.0);
	Cvar_Cost = CreateConVar("redbull_cost", "16000", _, FCVAR_NONE, true, 0.0);

	RegConsoleCmd("sm_redbull", redbull, "Special Boost Effect, health, armor, speed");
}


public Action redbull(int client, int args)
{
	if(client == 0 || !IsClientInGame(client) || GetClientTeam(client) < 2)
		return Plugin_Handled;


	if(!Cvar_Enabled.BoolValue)
	{
		PrintToChat(client, "\x01[Red Bull: Esparta] \x03The plugin is disaled!");
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x01[Red Bull: Esparta] \x03Solamente jugadores vivos lo pueden usa!");
		return Plugin_Handled;
	}

	if(TimerEffect[client] != null)
	{
		PrintToChat(client, "\x01[Red Bull: Esparta] \x03Ya tienes los efectos del Redbull");
		return Plugin_Handled;
	}

	int cost = Cvar_Cost.IntValue;
	if(cost > 0)
	{
		int money = GetEntProp(client, Prop_Send, "m_iAccount");
		if(money < cost)
		{
			PrintToChat(client, "\x01[Red Bull: Esparta] \x03No tienes dinero para el redbull! necesitas %d$!", cost);
			return Plugin_Handled;
		}
		
		SetEntProp(client, Prop_Send, "m_iAccount", money - cost);
	}


	PrintToChat(client, "\x01[Red Bull: Esparta] \x03RedBull te da alas!" );
	PrintToChat(client, "\x01[Red Bull: Esparta] \x03RedBull Mejora el rendimiento especiamente en momentos de mayor tension!" );


	DataPack pack;
	TimerEffect[client] = CreateDataTimer(Cvar_EffectTime.FloatValue, reset, pack);
	pack.WriteCell(client);
	pack.WriteCell(GetClientUserId(client));
	pack.Reset();


	int health = Cvar_Health.IntValue;
	if(health > 0)	SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth") + health);

	int armor = Cvar_Armor.IntValue;
	if(armor > 0)	SetEntProp(client, Prop_Send, "m_ArmorValue", GetEntProp(client, Prop_Send, "m_ArmorValue") + armor);

	float speed = Cvar_Speed.FloatValue;
	if(speed > 1.0)	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);

	Fade(client);

	return Plugin_Handled;
}


public Action reset(Handle timer, DataPack pack)
{
	TimerEffect[pack.ReadCell()] = null;

	int client = GetClientOfUserId(pack.ReadCell());

	if(client != 0 && IsClientInGame(client))
	{
		PrintToChat(client, "\x01[Red Bull: Esparta] \x03RedBull los efectos solo son temporales");

		if(Cvar_Speed.FloatValue > 1.0)	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}

	return Plugin_Continue;
}




Fade(client)
{
	int duration = 500; //ms
	int holdtime = 6 * 1000; // s
	int flags = 0x0001; // Fade in
	int color[4] = {255, 0, 0, 100};

	Handle message = StartMessageOne("Fade", client);
	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
	}
	
	EndMessage();
}