/* Plugin Version History
* 1.0 - Public release
* 1.1 - more configuration options
* 1.2 - delay fix
* 1.3 - advert disable fix
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"

#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"
#define MODEL_NICK "models/survivors/survivor_gambler.mdl"
#define MODEL_COACH "models/survivors/survivor_coach.mdl"
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl"
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl"

#define ADVERT "\x03This server runs \x04[\x038 Survivors\x04]\x03\nEvery player will have unique model!"

new Handle:cvarPluginVersion;
new Handle:cvarPluginMode;
new Handle:cvarPluginModelMode;
new Handle:cvarPluginDelay;
new Handle:cvarAdvertDelay;
new Handle:cvarPluginSafel4d1;
new String:currentmap[64];

public Plugin:myinfo = 
{
	name = "L4D2 8 Survivors",
	author = "kwski43 aka Jacklul",
	description = "Allows to set 8 survivors without cloned models. Currently only 7...",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1163224"
}

public OnPluginStart()
{
	decl String:s_Game[12];
	
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (!StrEqual(s_Game, "left4dead2"))
		SetFailState("Eight Survivors supports Left 4 Dead 2 only!");
	
	cvarPluginVersion = CreateConVar("l4d2_8survivors_version", PLUGIN_VERSION, "Eight Survivors Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarPluginMode = CreateConVar("l4d2_8survivors_mode", "1", "Eight Survivors Mode: 0-disable plugin, 1-new survivors first, 2-old survivors first", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvarPluginModelMode = CreateConVar("l4d2_8survivors_modelmode", "1", "Model change mode. 1-whole character, 2-only model", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 1.0, true, 2.0);
	cvarPluginDelay = CreateConVar("l4d2_8survivors_delay", "30", "Delay from round start when plugin start changing models.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 120.0);
	cvarAdvertDelay = CreateConVar("l4d2_8survivors_adsdelay", "10.0", "Advertisements after round start delay? 0-disable",FCVAR_PLUGIN, true, 0.0, true, 60.0);
	cvarPluginSafel4d1 = CreateConVar("l4d2_8survivors_safel4d1", "1", "Will not give l4d1's survivors on maps where bugs occur.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d2_8survivors");
	
	HookEvent("round_start", RoundStart, EventHookMode_Post);
	SetConVarString(cvarPluginVersion, PLUGIN_VERSION);
}

public OnMapStart()
{
	GetCurrentMap(currentmap, 64);
	//PrecacheModel(MODEL_BILL, true);
	PrecacheModel(MODEL_FRANCIS, true);
	PrecacheModel(MODEL_LOUIS, true);
	PrecacheModel(MODEL_ZOEY, true);
	PrecacheModel(MODEL_NICK, true);
	PrecacheModel(MODEL_COACH, true);
	PrecacheModel(MODEL_ROCHELLE, true);
	PrecacheModel(MODEL_ELLIS, true);
}

public Action:Advert(Handle:timer)
{
	PrintToChatAll(ADVERT);
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{ 	
	if(GetConVarInt(cvarPluginSafel4d1) && StrEqual(currentmap, "c6m1_riverbank") == true || StrEqual(currentmap, "c6m3_port") == true)
	{ 
	PrintToChatAll("\x04[\x038 Survivors\x04]\x03\n disabled due to bugs on this map");
	}
	else
	{
		if(GetConVarFloat(cvarAdvertDelay) > 0)
		{
			CreateTimer(GetConVarFloat(cvarAdvertDelay), Advert);
		}
		CreateTimer(GetConVarFloat(cvarPluginDelay), ChangeModels);
	}
	
}
public Action:ChangeModels(Handle:timer)
{
if(GetConVarInt(cvarPluginModelMode)==1)
{
	new model=0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
		if(GetConVarInt(cvarPluginMode)==1)
		{
			//code from http://forums.alliedmods.net/showthread.php?p=969651
			switch(model)
			{
				case 0: // Nick
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
					SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Nick \x05]");
				}
				case 1: // Rochelle
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1, 1, true);
					SetEntityModel(client, "models/survivors/survivor_producer.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Rochelle \x05]");
				}
				case 2: // Coach
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 2, 1, true);
					SetEntityModel(client, "models/survivors/survivor_coach.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Coach \x05]");
				}
				case 3: // Ellis
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
					SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Ellis \x05]");
				}
				case 4: // Zoey
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 5, 1, true);
					SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Zoey \x05]");
				}
				case 5: // Francis
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 6, 1, true);
					SetEntityModel(client, "models/survivors/survivor_biker.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Francis \x05]");
				}
				case 6: // Louis
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 7, 1, true);
					SetEntityModel(client, "models/survivors/survivor_manager.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Louis \x05]");
				}
				//case 7: // Bill
				//{
				//	SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
				//	SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
				//	PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Bill \x05]");
				//}
			}
			model=model+1;
		}
		else if(GetConVarInt(cvarPluginMode)==2)
		{
			//code from http://forums.alliedmods.net/showthread.php?p=969651
			switch(model)
			{
				case 0: // Zoey
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 5, 1, true);
					SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Zoey \x05]");
				}
				case 1: // Francis
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 6, 1, true);
					SetEntityModel(client, "models/survivors/survivor_biker.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Francis \x05]");
				}
				case 2: // Louis
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 7, 1, true);
					SetEntityModel(client, "models/survivors/survivor_manager.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Louis \x05]");
				}
				//case 3: // Bill
				//{
				//	SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
				//	SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
				//	PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Bill \x05]");
				//}
				case 4: // Nick
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
					SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Nick \x05]");
				}
				case 5: // Rochelle
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1, 1, true);
					SetEntityModel(client, "models/survivors/survivor_producer.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Rochelle \x05]");
				}
				case 6: // Coach
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 2, 1, true);
					SetEntityModel(client, "models/survivors/survivor_coach.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Coach \x05]");
				}
				case 7: // Ellis
				{
					SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
					SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Ellis \x05]");
				}
			}
			model=model+1;
		}
		}
	}
}
else if(GetConVarInt(cvarPluginModelMode)==2)
{
	new model=0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
		if(GetConVarInt(cvarPluginMode)==1)
		{
			//code from http://forums.alliedmods.net/showthread.php?p=969651
			switch(model)
			{
				case 0: // Nick
				{
					SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01Your model is now \x03Nick \x05]");
				}
				case 1: // Rochelle
				{
					SetEntityModel(client, "models/survivors/survivor_producer.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\\x05[ \x01Your model is now \x03Rochelle \x05]");
				}
				case 2: // Coach
				{
					SetEntityModel(client, "models/survivors/survivor_coach.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01Your model is now \x03Coach \x05]");
				}
				case 3: // Ellis
				{
					SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01Your model is now \x03Ellis \x05]");
				}
				case 4: // Zoey
				{
					SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01Your model is now \x03Zoey \x05]");
				}
				case 5: // Francis
				{
					SetEntityModel(client, "models/survivors/survivor_biker.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01Your model is now \x03Francis \x05]");
				}
				case 6: // Louis
				{
					SetEntityModel(client, "models/survivors/survivor_manager.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01Your model is now \x03Louis \x05]");
				}
				//case 7: // Bill
				//{
				//	SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
				//	PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01Your model is now \x03Bill \x05]");
				//}
			}
			model=model+1;
		}
		else if(GetConVarInt(cvarPluginMode)==2)
		{
			//code from http://forums.alliedmods.net/showthread.php?p=969651
			switch(model)
			{
				case 0: // Zoey
				{
					SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01Your model is now \x03Zoey \x05]");
				}
				case 1: // Francis
				{
					SetEntityModel(client, "models/survivors/survivor_biker.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01Your model is now \x03Francis \x05]");
				}
				case 2: // Louis
				{
					SetEntityModel(client, "models/survivors/survivor_manager.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01Your model is now \x03Louis \x05]");
				}
				//case 3: // Bill
				//{
				//	SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
				//	PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Bill \x05]");
				//}
				case 4: // Nick
				{
					SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Nick \x05]");
				}
				case 5: // Rochelle
				{
					SetEntityModel(client, "models/survivors/survivor_producer.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Rochelle \x05]");
				}
				case 6: // Coach
				{
					SetEntityModel(client, "models/survivors/survivor_coach.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Coach \x05]");
				}
				case 7: // Ellis
				{
					SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
					PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01You're now playing as \x03Ellis \x05]");
				}
			}
			model=model+1;
		}
		}
	}
}
else
{
	PrintToChatAll("\x04[\x038 Survivors\x04]\x03\n l4d2_8survivors_modelmode is set wrong, check the config! Plugin won't work.");
}
}