#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>
#include <tf2_stocks>
#include <sdktools>

public Plugin myinfo = {
	name		= "[TF2] Special Ragdolls",
	author		= "Nanochip",
	description = "When you kill someone, turn their ragdoll into something special.",
	version		= "1.0",
	url			= "http://steamcommunity.com/id/xNanochip"
};

int ragdollType[MAXPLAYERS+1] = {0, ...}; // 0 = No Special Ragdoll, 1 = Burning, 2 = Electrocuted, 3 = Gold, 4 = Ice, 5 = High Velocity, 6 = Cow Mangler Dissolve, 7 = Head Decapitation, 8 = Random
int randomRagdoll[MAXPLAYERS+1] =  { 0, ... };

Handle cRagdollType;

public void OnPluginStart()
{
	cRagdollType = RegClientCookie("specialragdolls_cookie", "", CookieAccess_Private);
	RegAdminCmd("sm_ragdoll", Cmd_Ragdoll, ADMFLAG_RESERVATION, "");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeathPost, EventHookMode_Post);
	
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
	switch (ragdollType[client])
	{
		case 0:
		{
			menu.AddItem("0", "No Special Ragdoll", ITEMDRAW_DISABLED);
			menu.AddItem("1", "Burning");
			menu.AddItem("2", "Electrocuted");
			menu.AddItem("3", "Gold");
			menu.AddItem("4", "Ice");
			menu.AddItem("5", "High Velocity");
			menu.AddItem("6", "Cow Mangler Dissolve");
			menu.AddItem("7", "Head Decapitation");
			menu.AddItem("8", "Random");
		}
		case 1:
		{
			menu.AddItem("0", "No Special Ragdoll");
			menu.AddItem("1", "Burning", ITEMDRAW_DISABLED);
			menu.AddItem("2", "Electrocuted");
			menu.AddItem("3", "Gold");
			menu.AddItem("4", "Ice");
			menu.AddItem("5", "High Velocity");
			menu.AddItem("6", "Cow Mangler Dissolve");
			menu.AddItem("7", "Head Decapitation");
			menu.AddItem("8", "Random");
		}
		case 2:
		{
			menu.AddItem("0", "No Special Ragdoll");
			menu.AddItem("1", "Burning");
			menu.AddItem("2", "Electrocuted", ITEMDRAW_DISABLED);
			menu.AddItem("3", "Gold");
			menu.AddItem("4", "Ice");
			menu.AddItem("5", "High Velocity");
			menu.AddItem("6", "Cow Mangler Dissolve");
			menu.AddItem("7", "Head Decapitation");
			menu.AddItem("8", "Random");
		}
		case 3:
		{
			menu.AddItem("0", "No Special Ragdoll");
			menu.AddItem("1", "Burning");
			menu.AddItem("2", "Electrocuted");
			menu.AddItem("3", "Gold", ITEMDRAW_DISABLED);
			menu.AddItem("4", "Ice");
			menu.AddItem("5", "High Velocity");
			menu.AddItem("6", "Cow Mangler Dissolve");
			menu.AddItem("7", "Head Decapitation");
			menu.AddItem("8", "Random");
		}
		case 4:
		{
			menu.AddItem("0", "No Special Ragdoll");
			menu.AddItem("1", "Burning");
			menu.AddItem("2", "Electrocuted");
			menu.AddItem("3", "Gold");
			menu.AddItem("4", "Ice", ITEMDRAW_DISABLED);
			menu.AddItem("5", "High Velocity");
			menu.AddItem("6", "Cow Mangler Dissolve");
			menu.AddItem("7", "Head Decapitation");
			menu.AddItem("8", "Random");
		}
		case 5:
		{
			menu.AddItem("0", "No Special Ragdoll");
			menu.AddItem("1", "Burning");
			menu.AddItem("2", "Electrocuted");
			menu.AddItem("3", "Gold");
			menu.AddItem("4", "Ice");
			menu.AddItem("5", "High Velocity", ITEMDRAW_DISABLED);
			menu.AddItem("6", "Cow Mangler Dissolve");
			menu.AddItem("7", "Head Decapitation");
			menu.AddItem("8", "Random");
		}
		case 6:
		{
			menu.AddItem("0", "No Special Ragdoll");
			menu.AddItem("1", "Burning");
			menu.AddItem("2", "Electrocuted");
			menu.AddItem("3", "Gold");
			menu.AddItem("4", "Ice");
			menu.AddItem("5", "High Velocity");
			menu.AddItem("6", "Cow Mangler Dissolve", ITEMDRAW_DISABLED);
			menu.AddItem("7", "Head Decapitation");
			menu.AddItem("8", "Random");
		}
		case 7:
		{
			menu.AddItem("0", "No Special Ragdoll");
			menu.AddItem("1", "Burning");
			menu.AddItem("2", "Electrocuted");
			menu.AddItem("3", "Gold");
			menu.AddItem("4", "Ice");
			menu.AddItem("5", "High Velocity");
			menu.AddItem("6", "Cow Mangler Dissolve");
			menu.AddItem("7", "Head Decapitation", ITEMDRAW_DISABLED);
			menu.AddItem("8", "Random");
		}
		case 8:
		{
			menu.AddItem("0", "No Special Ragdoll");
			menu.AddItem("1", "Burning");
			menu.AddItem("2", "Electrocuted");
			menu.AddItem("3", "Gold");
			menu.AddItem("4", "Ice");
			menu.AddItem("5", "High Velocity");
			menu.AddItem("6", "Cow Mangler Dissolve");
			menu.AddItem("7", "Head Decapitation");
			menu.AddItem("8", "Random", ITEMDRAW_DISABLED);
		}
	}
	
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
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	randomRagdoll[attacker] = ragdollType[attacker];
	if (ragdollType[attacker] == 8) randomRagdoll[attacker] = GetRandomInt(1, 7);
	if (randomRagdoll[attacker] == 0 || randomRagdoll[attacker] == 6) return;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(0.0, RemoveBody, client);
	
	int ragdoll = CreateEntityByName("tf_ragdoll");
	int team = GetClientTeam(client);
	int class = view_as<int>(TF2_GetPlayerClass(client));
	
	float clientOrigin[3];
	SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", clientOrigin); 
	SetEntProp(ragdoll, Prop_Send, "m_iPlayerIndex", client);
	
	// 0 = No Special Ragdoll, 1 = Burning, 2 = Electrocuted, 3 = Gold, 4 = Ice, 5 = High Velocity, 6 = Cow Mangler Dissolve
	if (randomRagdoll[attacker] == 1) SetEntProp(ragdoll, Prop_Send, "m_bBurning", 1);
	if (randomRagdoll[attacker] == 2) SetEntProp(ragdoll, Prop_Send, "m_bElectrocuted", 1);
	if (randomRagdoll[attacker] == 3) SetEntProp(ragdoll, Prop_Send, "m_bGoldRagdoll", 1);
	if (randomRagdoll[attacker] == 4) SetEntProp(ragdoll, Prop_Send, "m_bIceRagdoll", 1);
	if (randomRagdoll[attacker] == 5)
	{
		float vel[3];
		vel[0] = -180000.552734;
		vel[1] = -1800.552734;
		vel[2] = 800000.552734;
		
		SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", vel);
		SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", vel);
	}
	if (randomRagdoll[attacker] == 7) SetEntProp(ragdoll, Prop_Send, "m_iDamageCustom", 20);
	
	SetEntProp(ragdoll, Prop_Send, "m_iTeam", team);
	SetEntProp(ragdoll, Prop_Send, "m_iClass", class);
	SetEntProp(ragdoll, Prop_Send, "m_nForceBone", 1);
	
	DispatchSpawn(ragdoll);
	
	// Despawn
	char info[64];
	Format(info, sizeof(info), "OnUser1 !self:kill::20:1");
	SetVariantString(info);
	AcceptEntityInput(ragdoll, "AddOutput");
	AcceptEntityInput(ragdoll, "FireUser1");
	//CreateTimer(20.0, RemoveRagdoll, ragdoll);
}

public Action Event_PlayerDeathPost(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (randomRagdoll[attacker] != 6) return;
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidEntity(victim))
	{
		CreateTimer(0.1, Timer_DissolveRagdoll, victim);
	}
}


public Action Timer_DissolveRagdoll(Handle timer, any victim)
{
	int ragdoll = GetEntPropEnt(victim, Prop_Send, "m_hRagdoll");

	if (ragdoll != -1)
	{
		DissolveRagdoll(ragdoll);
	}
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

	return;
}  

public Action RemoveBody(Handle timer, any client)
{
	int BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(IsValidEdict(BodyRagdoll))
	{
		AcceptEntityInput(BodyRagdoll, "kill");
	}
}

/*public Action RemoveRagdoll(Handle timer, any ent)
{
	if(IsValidEntity(ent))
	{
		char classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if(StrEqual(classname, "tf_ragdoll", false))
		{
			AcceptEntityInput(ent, "kill");
		}
	}
}*/

stock bool IsValidClient(int client) 
{
	if (!( 1 <= client <= MaxClients) || !IsClientInGame(client)) 
		return false; 
	return true; 
}  