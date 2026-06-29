#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

new g_bIsCutout[MAXPLAYERS+1];

public OnPluginStart() 
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	RegConsoleCmd("sm_meem", Command_Cutout, "Become a cut out model of your class.");
}

public OnClientConnected(client)
	g_bIsCutout[client] = false;

public Action:Command_Cutout(client, args)
{
	if(!g_bIsCutout[client])
	{
		PrintToChat(client, "You are now a cutout representation of your class!");
		CreateTimer(0.5, Changemodel, GetClientUserId(client));
		g_bIsCutout[client] = true;
	}
	else
	{
		PrintToChat(client, "You are no longer a cutout");
		g_bIsCutout[client] = false;
		
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
	
	return Plugin_Handled;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && client < MaxClients && g_bIsCutout[client])
	{
		CreateTimer(0.5, Changemodel, GetClientUserId(client));
	}
}

public Action:Changemodel(Handle:timer, any:userId)
{
	new client = GetClientOfUserId(userId);
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	switch(class)
	{
		case TFClass_DemoMan:		SetVariantString("models/props_training/target_demoman.mdl");
		case TFClass_Engineer:		SetVariantString("models/props_training/target_engineer.mdl");
		case TFClass_Heavy:			SetVariantString("models/props_training/target_heavy.mdl");
		case TFClass_Medic:			SetVariantString("models/props_training/target_medic.mdl");
		case TFClass_Pyro:			SetVariantString("models/props_training/target_pyro.mdl");
		case TFClass_Scout:			SetVariantString("models/props_training/target_scout.mdl");
		case TFClass_Sniper:		SetVariantString("models/props_training/target_sniper.mdl");
		case TFClass_Soldier:		SetVariantString("models/props_training/target_soldier.mdl");
		case TFClass_Spy:			SetVariantString("models/props_training/target_spy.mdl");
	}
	
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	
	TF2_RemoveAllWearables(client);
}

stock TF2_RemoveAllWearables(client)
{
	new wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
}