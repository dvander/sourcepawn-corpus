#include <rpmlib>
#include <sdkhooks>

new hasNinja[MAXPLAYERS+1];
new bool:onninja[MAXPLAYERS+1];
new bool:canuse[MAXPLAYERS+1];

new Handle:cvar_quant = INVALID_HANDLE;
new Handle:cvar_cost = INVALID_HANDLE;
new Handle:cvar_shop = INVALID_HANDLE;

public OnPluginStart()
{
	RegConsoleCmd("ninja", ninja);
	RegConsoleCmd("ninja_buy", ninja_buy);
	RegAdminCmd("ninja_give", ninja_give, ADMFLAG_GENERIC);
	
	HookEvent("round_start", start);
	HookEvent("player_spawn", spawn);
	
	cvar_quant = CreateConVar("ninja_quant", "3", "Quantity of ninja a player will recieve during the round");
	cvar_shop = CreateConVar("ninja_shop", "0", "If this is set to 1 ninja_quant will be ignored, and players will have to buy your own ninjas");
	cvar_cost = CreateConVar("ninja_cost", "500", "This cvar only works if ninja_buy is 1, this will be the cost of ninjas");
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(rpm_Check(i))
		{	
			onninja[i] = false;
			canuse[i] = true;
			if(GetConVarInt(cvar_shop) == 0)
			{
				hasNinja[i] = GetConVarInt(cvar_quant);
			}
			else
			{
				hasNinja[i] = 0;
				rpm_PrintToChatTag(i, "Ninja", "Write !ninja_buy to acquire some ninja. Cost: %i", GetConVarInt(cvar_cost));
			}
		}
	}
	
	rpm_PrintToChatAllTag("Ninja", "Loaded!");
}

public Action:spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = rpm_GetClientOfEvent(event);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(rpm_Check(i))
		{	
			onninja[i] = false;
			canuse[i] = true;
			if(GetConVarInt(cvar_shop) == 0)
				hasNinja[i] = GetConVarInt(cvar_quant);
			else
			{
				rpm_PrintToChatTag(i, "Ninja", "Write !ninja_buy to acquire some ninja. Cost: %i", GetConVarInt(cvar_cost));
			}
		}
	}
}

public Action:ninja(client, args)
{
	if(hasNinja[client] > 0 && canuse[client] && IsPlayerAlive(client))
	{
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		
		new SmokeIndex = CreateEntityByName("env_particlesmokegrenade");
		if (SmokeIndex != -1)
		{
			SetEntProp(SmokeIndex, Prop_Send, "m_CurrentStage", 1);
			SetEntPropFloat(SmokeIndex, Prop_Send, "m_FadeStartTime", 2.0);
			SetEntPropFloat(SmokeIndex, Prop_Send, "m_FadeEndTime", 4.0);
			DispatchSpawn(SmokeIndex);
			ActivateEntity(SmokeIndex);
			TeleportEntity(SmokeIndex, vec, NULL_VECTOR, NULL_VECTOR);
		}
		rpm_SetClientInvisible(client, 0);
		CreateTimer(1.0, Invis, client);
		CreateTimer(6.0, NormalColor, client);
		hasNinja[client]--;
		rpm_PrintToChatAllTag("Ninja", "%N used ninja!", client);
		
		//Invis all weapons
		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
		//Prevent from droping invisible weapons
		SDKHook(client, SDKHook_WeaponDropPost, Drop);
		
		if(hasNinja[client] > 0)
			rpm_PrintToChatTag(client, "Ninja", "You have %i more ninjas", hasNinja[client]);
			
		else if(hasNinja[client] == 0 && GetConVarInt(cvar_shop) == 1)
			rpm_PrintToChatTag(client, "Ninja", "You have no more ninjas, type !ninja_buy");
		
		else if(hasNinja[client] == 0 && GetConVarInt(cvar_shop) == 0)
			rpm_PrintToChatTag(client, "Ninja", "You have no more ninjas");
	}
	else if(hasNinja[client] == 0 && GetConVarInt(cvar_shop) == 1)
		rpm_PrintToChatTag(client, "Ninja", "You have no more ninjas, type !ninja_buy");
		
	else if(hasNinja[client] == 0 && GetConVarInt(cvar_shop) == 0)
		rpm_PrintToChatTag(client, "Ninja", "You have no more ninjas");
		
	else if(!canuse[client])
		rpm_PrintToChatTag(client, "Ninja", "You can't use ninja right now");
}

public Action:ninja_buy(client, args)
{
	if(GetConVarInt(cvar_shop) == 1)
	{
		if(rpm_GetClientMoney(client) >= GetConVarInt(cvar_cost))
		{
			hasNinja[client]++;
			rpm_SetClientMoney(client, rpm_GetClientMoney(client) - GetConVarInt(cvar_cost));
			rpm_PrintToChatTag(client, "Ninja", "You have %i ninja", hasNinja[client]);
		}
		else
		{
			rpm_PrintToChatTag(client, "Ninja", "You have insufficient money!");
		}
	}
	else
	{
		rpm_PrintToChatTag(client, "Ninja", "Shop is disabled");
	}
}

public Action:ninja_give(client, args)
{
	decl String:arg1[50];
	decl String:arg2[50];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new target = FindTarget(client, arg1, false, false);
	new iArg2 = StringToInt(arg2);
	
	hasNinja[target] += iArg2;
	rpm_PrintToChatAllTag("Ninja", "%N recieved %i ninjas from admin", target, iArg2);
}

public Action:Invis(Handle:timer, any:client)
{
	onninja[client] = true;
	canuse[client] = false;
}

public Action:NormalColor(Handle:timer, any:client)
{
	rpm_SetClientInvisible(client, 255);
	onninja[client] = false;
	canuse[client] = true;
	
	//Invis all weapons
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	//Prevent from droping invisible weapons
	SDKUnhook(client, SDKHook_WeaponDropPost, Drop);
	rpm_PrintToChatTag(client, "Ninja", "You are visible again!");
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(attacker != 0 && onninja[victim])
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	else if(onninja[attacker])
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

//Invis all weapons
public OnPostThinkPost(client)
{
	if(client > 0)
	{
		rpm_SetClientInvisible(client, 0);
		SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
	}
}

//Prevent from droping invisible weapons
public Drop(client, weapon)
{
	SetEntityRenderMode(weapon, RENDER_GLOW);
	SetEntityRenderColor(weapon, 255, 255, 255, 255);
}