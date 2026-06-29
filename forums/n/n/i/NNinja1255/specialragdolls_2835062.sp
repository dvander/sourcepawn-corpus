#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>
#include <tf2_stocks>
#include <sdktools>

#define killerdomination (1 << 0)
#define assisterdomination (1 << 1)
#define killerrevenge (1 << 2)
#define assisterrevenge (1 << 3)
#define firstblood (1 << 4)
#define feigndeath (1 << 5)

public Plugin myinfo = {
	name		= "[TF2] Special Ragdolls",
	author		= "Nanochip, NNinja1255",
	description = "When you kill someone, turn their ragdoll into something special.",
	version		= "1.0.2",
	url			= "http://steamcommunity.com/id/xNanochip"
};

int ragdollType[MAXPLAYERS+1] = {0, ...}; // 0 = No Special Ragdoll, 1 = Burning, 2 = Electrocuted, 3 = Gold, 4 = Ice, 5 = High Velocity, 6 = Cow Mangler Dissolve, 7 = Head Decapitation, 8 = Random
int randomRagdoll[MAXPLAYERS+1] =  { 0, ... };

Handle cRagdollType;

ConVar hAdminOnly;

public void OnPluginStart()
{
	hAdminOnly = CreateConVar("sm_specialragdolls_reserved", "1", "1 = Only reservations can use special ragdolls, 0 = All players can use special ragdolls.", 0, true, 0.0, true, 1.0);
	
	cRagdollType = RegClientCookie("specialragdolls_cookie", "", CookieAccess_Private);
	RegAdminCmd("sm_ragdoll", Cmd_Ragdoll, 0, "");
	RegAdminCmd("sm_ragdolls", Cmd_Ragdoll, 0, "");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	//HookEvent("player_death", Event_PlayerDeathPost, EventHookMode_Post);
	
	AutoExecConfig(true);
	
	//for late loads
	for (int i = 1; i <= MaxClients; i++)
	{
		ragdollType[i] = 0;
		if(IsClientInGame(i) && AreClientCookiesCached(i)) 
		{
			OnClientCookiesCached(i);
			OnClientPostAdminCheck(i);
		}
		
	}
}

public void OnEntityCreated(int iEntity, const char[] strClassname)
{
	// fix ragdoll bug
	if (StrEqual(strClassname,"tf_ragdoll"))
	{
		SetEntPropFloat(iEntity, Prop_Send, "m_flHeadScale", 1.0);
		SetEntPropFloat(iEntity, Prop_Send, "m_flTorsoScale", 1.0);
		SetEntPropFloat(iEntity, Prop_Send, "m_flHandScale", 1.0);
	}
}

public Action Cmd_Ragdoll(int client, int args)
{
	if (GetConVarBool(hAdminOnly) && !CheckCommandAccess(client, "sm_ragdoll", ADMFLAG_RESERVATION, true))
	{
		ReplyToCommand(client, "[SM] Sorry, this command is currently restricted to reservations.");
		return Plugin_Handled;
	}

	if (!IsValidClient(client)) return Plugin_Handled;
	RagdollMenu(client);
	
	if (args > 0)
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		ragdollType[client] = StringToInt(arg1);
		if (ragdollType[client] > 8) ragdollType[client] = 8;
		SetClientCookie(client, cRagdollType, arg1);
	}
	return Plugin_Handled;
}

public void RagdollMenu(int client)
{
	Menu menu = new Menu(RagdollMenuHandler);
	// 0 = No Special Ragdoll, 1 = Burning, 2 = Electrocuted, 
	//3 = Gold, 4 = Ice, 5 = High Velocity, 6 = Cow Mangler Dissolve, 7 = Head Decapitation
	menu.SetTitle("Select your enemies' ragdolls:");
	menu.AddItem("0", "No Special Ragdoll", (ragdollType[client] == 0) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("1", "Burning", (ragdollType[client] == 1) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("2", "Electrocuted", (ragdollType[client] == 2) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("3", "Gold", (ragdollType[client] == 3) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("4", "Ice", (ragdollType[client] == 4) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("5", "High Velocity", (ragdollType[client] == 5) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("6", "Cow Mangler Dissolve", (ragdollType[client] == 6) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("7", "Head Decapitation", (ragdollType[client] == 7) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("8", "Random", (ragdollType[client] == 8) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.Display(client, 20);
}

public int RagdollMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_End) delete menu;
	if (action == MenuAction_Select)
	{
		int style;
		char info[32], display[32];
		menu.GetItem(param2, info, sizeof(info), style, display, sizeof(display));
		
		ragdollType[client] = StringToInt(info);
		SetClientCookie(client, cRagdollType, info);
		if (ragdollType[client] > 8)ragdollType[client] = 8;
		
		PrintToChat(client, "[SM] Your enemies' ragdolls are set to: %s.", display);
		RagdollMenu(client);
	}
}

public void OnClientAuthorized(int client, const char[] auth)
{
	ragdollType[client] = 0;
}

public OnClientCookiesCached(int client)
{
	char value[32];
	GetClientCookie(client, cRagdollType, value, sizeof(value));
	ragdollType[client] = StringToInt(value);
}

public void OnClientPostAdminCheck(int client)
{
	if (!CheckCommandAccess(client, "sm_ragdoll", ADMFLAG_RESERVATION, false))
	{
		ragdollType[client] = 0;
	}
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if (GetEventInt(event, "death_flags") & feigndeath)
	{
		return Plugin_Continue;
	}

	DataPack pack;
    CreateDataTimer(0, Timer_ReplacePlayerRagdoll, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientOfUserId(GetEventInt(event, "attacker")));
	pack.WriteCell(GetClientOfUserId(GetEventInt(event, "userid")));
	
	return Plugin_Continue;
}

Action Timer_ReplacePlayerRagdoll(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int attacker = pack.ReadCell();
	if (!IsValidClient(attacker))
	{
		return Plugin_Handled;
	}
	randomRagdoll[attacker] = ragdollType[attacker];
	if (randomRagdoll[attacker] == 0) return Plugin_Handled;
	if (ragdollType[attacker] == 8) randomRagdoll[attacker] = GetRandomInt(1, 7);
	int client = pack.ReadCell();
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if (GetConVarBool(hAdminOnly) && !CheckCommandAccess(client, "sm_ragdoll", ADMFLAG_RESERVATION, true))
	{
		return Plugin_Handled;
	}

	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!IsValidEntity(ragdoll))
	{
		return Plugin_Handled;
	}
	
	int ent = CreateEntityByName("tf_ragdoll", -1);
	if (ent != -1)
	{
		float pos[3], ang[3], velocity[3], force[3];
		GetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", pos);
		GetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", velocity);
		GetEntPropVector(ragdoll, Prop_Send, "m_vecForce", force);
		GetEntPropVector(ragdoll, Prop_Data, "m_angAbsRotation", ang);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetEntPropVector(ent, Prop_Send, "m_vecRagdollOrigin", pos);
		SetEntPropVector(ent, Prop_Send, "m_vecRagdollVelocity", velocity);
		SetEntPropVector(ent, Prop_Send, "m_vecForce", force);
		SetEntPropFloat(ent, Prop_Send, "m_flHeadScale", 1.0);
		SetEntPropFloat(ent, Prop_Send, "m_flTorsoScale", 1.0);
		SetEntPropFloat(ent, Prop_Send, "m_flHandScale", 1.0);
		SetEntProp(ent, Prop_Send, "m_nForceBone", GetEntProp(ragdoll, Prop_Send, "m_nForceBone"));
		SetEntProp(ent, Prop_Send, "m_bOnGround", GetEntProp(ragdoll, Prop_Send, "m_bOnGround"));
		SetEntProp(ent, Prop_Send, "m_bCloaked", GetEntProp(ragdoll, Prop_Send, "m_bCloaked"));
		SetEntPropEnt(ent, Prop_Send, "m_hPlayer", GetEntPropEnt(ragdoll, Prop_Send, "m_hPlayer"));
		SetEntProp(ent, Prop_Send, "m_iTeam", GetEntProp(ragdoll, Prop_Send, "m_iTeam"));
		SetEntProp(ent, Prop_Send, "m_iClass", GetEntProp(ragdoll, Prop_Send, "m_iClass"));
		SetEntProp(ent, Prop_Send, "m_bWasDisguised", GetEntProp(ragdoll, Prop_Send, "m_bWasDisguised"));
		SetEntProp(ent, Prop_Send, "m_bFeignDeath", GetEntProp(ragdoll, Prop_Send, "m_bFeignDeath"));
		SetEntProp(ent, Prop_Send, "m_bGib", GetEntProp(ragdoll, Prop_Send, "m_bGib"));
		SetEntProp(ent, Prop_Send, "m_iDamageCustom", GetEntProp(ragdoll, Prop_Send, "m_iDamageCustom"));
		SetEntProp(ent, Prop_Send, "m_bBurning", GetEntProp(ragdoll, Prop_Send, "m_bBurning"));
		SetEntProp(ent, Prop_Send, "m_bBecomeAsh", GetEntProp(ragdoll, Prop_Send, "m_bBecomeAsh"));
		SetEntProp(ent, Prop_Send, "m_bGoldRagdoll", GetEntProp(ragdoll, Prop_Send, "m_bGoldRagdoll"));
		SetEntProp(ent, Prop_Send, "m_bIceRagdoll", GetEntProp(ragdoll, Prop_Send, "m_bIceRagdoll"));
		SetEntProp(ent, Prop_Send, "m_bElectrocuted", GetEntProp(ragdoll, Prop_Send, "m_bElectrocuted"));
		int deathType = randomRagdoll[attacker];
		switch (deathType)
		{
			case 1:
			{
				SetEntProp(ent, Prop_Send, "m_bBurning", true);
			}
			case 2:
			{
				SetEntProp(ent, Prop_Send, "m_bElectrocuted", true);
			}
			case 3:
			{
				SetEntProp(ent, Prop_Send, "m_bGoldRagdoll", true);
			}
			case 4:
			{
				SetEntProp(ent, Prop_Send, "m_bIceRagdoll", true);
			}
			case 5:
			{
				velocity[0] = -180000.552734;
				velocity[1] = -1800.552734;
				velocity[2] = 800000.552734;

				force[0] = -180000.552734;
				force[1] = -1800.552734;
				force[2] = 800000.552734;
				
				SetEntPropVector(ent, Prop_Send, "m_vecRagdollVelocity", velocity);
				SetEntPropVector(ent, Prop_Send, "m_vecForce", force);
			}
			case 6:
			{
				CreateTimer(0, Timer_DissolveRagdoll, ent, TIMER_FLAG_NO_MAPCHANGE);
				//DissolveRagdoll(ent);
			}
			case 7:
			{
				SetEntProp(ent, Prop_Send, "m_iDamageCustom", 20);
			}
		}
		DispatchSpawn(ent);
		ActivateEntity(ent);
		SetEntPropEnt(client, Prop_Send, "m_hRagdoll", ent, 0);
	}
	//RemoveEntity(ragdoll);
	AcceptEntityInput(ragdoll, "Kill", -1, -1, 0);
	return Plugin_Handled;
}

/*
public Action Event_PlayerDeathPost(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (randomRagdoll[attacker] != 6) return Plugin_Continue;
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidEntity(victim))
	{
		CreateTimer(0, Timer_DissolveRagdoll, victim, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}
*/

public Action Timer_DissolveRagdoll(Handle timer, any ent)
{
	int ragdoll = ent;

	if (ragdoll != -1)
	{
		DissolveRagdoll(ragdoll);
	}
	
	return Plugin_Handled;
}


stock void DissolveRagdoll(ragdoll)
{
	int dissolver = CreateEntityByName("env_entity_dissolver");

	if (dissolver == -1)
	{
		return;
	}

	DispatchKeyValue(dissolver, "dissolvetype", "0");
	DispatchKeyValue(dissolver, "magnitude", "1");
	DispatchKeyValue(dissolver, "target", "!activator");

	AcceptEntityInput(dissolver, "Dissolve", ragdoll);
	AcceptEntityInput(dissolver, "Kill");
}

public Action RemoveBody(Handle timer, any client)
{
	int BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(IsValidEdict(BodyRagdoll))
	{
		AcceptEntityInput(BodyRagdoll, "kill");
	}
	
	return Plugin_Handled;
}

stock bool IsValidClient(int client) 
{
	if (!( 1 <= client <= MaxClients) || !IsClientInGame(client)) 
		return false; 
	return true; 
}  