#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define     NICK     0 
#define     ROCHELLE    1 
#define     COACH     2 
#define     ELLIS     3 
#define     BILL     4 
#define     ZOEY     5 
#define     FRANCIS     6 
#define     LOUIS     7 

static const String:MODEL_NICK[] 		= "models/survivors/survivor_gambler.mdl";
static const String:MODEL_ROCHELLE[] 		= "models/survivors/survivor_producer.mdl";
static const String:MODEL_COACH[] 		= "models/survivors/survivor_coach.mdl";
static const String:MODEL_ELLIS[] 		= "models/survivors/survivor_mechanic.mdl";
static const String:MODEL_BILL[] 		= "models/survivors/survivor_namvet.mdl";
static const String:MODEL_ZOEY[] 		= "models/survivors/survivor_teenangst.mdl";
static const String:MODEL_FRANCIS[] 		= "models/survivors/survivor_biker.mdl";
static const String:MODEL_LOUIS[] 		= "models/survivors/survivor_manager.mdl";
static bool:g_bHasPlayerBeenRandomized[MAXPLAYERS+1] = false;
public Plugin:myinfo = 
{
	name = "L4D2 Randomize Survivor",
	author = "DeathChaos25",
	description = "Randomizes a Survivor's character whenever they spawn as a survivor for the first time",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=260321"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder)); 
	if (!StrEqual(s_GameFolder, "left4dead2", false))
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead 2 Only!"); 
		return APLRes_Failure;
	}
	return APLRes_Success; 
}

public OnPluginStart()
{
	RegAdminCmd("sm_randomizeall", AdminRandomizesPlayers, ADMFLAG_GENERIC, "Randomizes the character of all the survivors"); 
	HookEvent("player_spawn", PlayerJoined_Event);
}

public OnMapStart()
{
	CheckModelPreCache(MODEL_NICK);
	CheckModelPreCache(MODEL_ROCHELLE);
	CheckModelPreCache(MODEL_COACH);
	CheckModelPreCache(MODEL_ELLIS);
	CheckModelPreCache(MODEL_BILL);
	CheckModelPreCache(MODEL_ZOEY);
	CheckModelPreCache(MODEL_FRANCIS);
	CheckModelPreCache(MODEL_LOUIS);
}

stock CheckModelPreCache(const String:Modelfile[])
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile, true);
		PrintToServer("Precaching Model:%s",Modelfile);
	}
}

public OnClientDisconnect(client)
{
	g_bHasPlayerBeenRandomized[client] = false;
}

public Action:RandomizeDelayTimer(Handle:timer, Handle:pack) 
{
	ResetPack(pack);
	new client = GetClientOfUserId(ReadPackCell(pack));
	
	if (client <= 0 || client > MAXPLAYERS)
		return;
	if (GetClientTeam(client) != 2 || !IsClientInGame(client))
		return;
	
	ShowMenu(client);
	
	if (IsFakeClient(client))
	{
		RandomizeSurvivor(client); 
		return;
	}
}

public PlayerJoined_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0 || client > MAXPLAYERS) 
		return;
	
	if (IsClientInGame(client) && !g_bHasPlayerBeenRandomized[client])
	{
		new Handle:pack = CreateDataPack();
		WritePackCell(pack, GetClientUserId(client));
		CreateTimer(1.5, RandomizeDelayTimer, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
		
	}
	
}

public Action:AdminRandomizesPlayers(client, args)
{
	new maxplayers = GetMaxClients();
	for (new i = 1; i < maxplayers; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			g_bHasPlayerBeenRandomized[i] = true;
			RandomizeSurvivor(i);
			PrintToChat(i, "Your Survivor has been randomized by an Admin!");
		}
	}
}

public RandomizeSurvivor(client)
{
	new random = GetRandomInt(1,8);
	
	switch(random)
	{
		case 1: NickUse(client);
		case 2: RochelleUse(client);
		case 3: CoachUse(client);
		case 4: EllisUse(client);
		case 5: BillUse(client);
		case 6: ZoeyUse(client);
		case 7: LouisUse(client);
		case 8: BikerUse(client);
	}
	if (!g_bHasPlayerBeenRandomized[client])
	{
		PrintToChat(client,"Your survivor has been randomized!");
		g_bHasPlayerBeenRandomized[client] = true;
	}
}

public CharMenu(Handle:menu, MenuAction:action, param1, param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:item[2];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			switch(StringToInt(item)) 
			{
				case 1:        {    RandomizeSurvivor(param1);}
				case 2:		   { g_bHasPlayerBeenRandomized[param1] = true;}
			}
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public Action:ShowMenu(client) 
{
	decl String:sMenuEntry[2];
	
	new Handle:menu = CreateMenu(CharMenu);
	SetMenuTitle(menu, "Do you wish to randomize your Survivor Character?");
	
	
	IntToString(1, sMenuEntry, sizeof(sMenuEntry));
	AddMenuItem(menu, sMenuEntry, "Yes!");
	IntToString(2, sMenuEntry, sizeof(sMenuEntry));
	AddMenuItem(menu, sMenuEntry, "No");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Action:ZoeyUse(client)  
{  
	
	SetEntProp(client, Prop_Send, "m_survivorCharacter", ZOEY);  
	SetEntityModel(client, MODEL_ZOEY);  
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Zoey");
	}
}  

public Action:NickUse(client)  
{  
	
	SetEntProp(client, Prop_Send, "m_survivorCharacter", NICK);  
	SetEntityModel(client, MODEL_NICK);  
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Nick");
	}
}  

public Action:EllisUse(client)  
{  
	SetEntProp(client, Prop_Send, "m_survivorCharacter", ELLIS);  
	SetEntityModel(client, MODEL_ELLIS);  
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Ellis");
	}
}  

public Action:CoachUse(client)  
{  
	SetEntProp(client, Prop_Send, "m_survivorCharacter", COACH);  
	SetEntityModel(client, MODEL_COACH);  
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Coach");
	}
}  

public Action:RochelleUse(client)  
{  
	SetEntProp(client, Prop_Send, "m_survivorCharacter", ROCHELLE);  
	SetEntityModel(client, MODEL_ROCHELLE);  
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Rochelle");
	}
}  

public Action:BillUse(client)  
{  
	SetEntProp(client, Prop_Send, "m_survivorCharacter", BILL);  
	SetEntityModel(client, MODEL_BILL);  
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Bill");
	}
}  

public Action:BikerUse(client)  
{  
	SetEntProp(client, Prop_Send, "m_survivorCharacter", FRANCIS);  
	SetEntityModel(client, MODEL_FRANCIS);  
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Francis");
	}
}  

public Action:LouisUse(client)  
{  
	SetEntProp(client, Prop_Send, "m_survivorCharacter", LOUIS);  
	SetEntityModel(client, MODEL_LOUIS);  
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Louis");
	}
}  
