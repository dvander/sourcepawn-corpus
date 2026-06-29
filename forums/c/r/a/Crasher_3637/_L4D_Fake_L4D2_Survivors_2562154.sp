#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.1"
#define CVAR_FLAGS FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD
#define CVAR_FLAGS2 FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"
#define MODEL_NICK "models/survivors/survivor_gambler.mdl"
#define MODEL_COACH "models/survivors/survivor_coach.mdl"
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl"
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl"

Handle cvarPluginVersion;
Handle cvarPluginMode;

public Plugin myinfo = 
{
	name = "[L4D] Fake L4D2 Survivors",
	author = "kwski43 aka Jacklul - Edited Code by Black David",
	description = "Change the other models and become L4D2 characters",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=302678"
}

public void OnPluginStart()
{
	char s_Game[12];
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (!StrEqual(s_Game, "left4dead"))
		SetFailState("Fake L4D2 Survivors supports Left 4 Dead only!");
	cvarPluginVersion = CreateConVar("l4d_fakel4d2sur_version", PLUGIN_VERSION, "Eight Survivors Version", CVAR_FLAGS);
	cvarPluginMode = CreateConVar("l4d_fakel4d2sur_mode", "1", "Eight Survivors Mode: 0: disable plugin, 1: new survivors first, 2: old survivors first", CVAR_FLAGS2, true, 0.0, true, 2.0);
	AutoExecConfig(true, "l4d_fakel4d2sur");
	HookEvent("round_start", RoundStart, EventHookMode_Post);
	SetConVarString(cvarPluginVersion, PLUGIN_VERSION);
}

public void OnMapStart()
{
	PrecacheModel(MODEL_BILL, true);
	PrecacheModel(MODEL_FRANCIS, true);
	PrecacheModel(MODEL_LOUIS, true);
	PrecacheModel(MODEL_ZOEY, true);
	PrecacheModel(MODEL_NICK, true);
	PrecacheModel(MODEL_COACH, true);
	PrecacheModel(MODEL_ROCHELLE, true);
	PrecacheModel(MODEL_ELLIS, true);
}

public void RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(15.0, ChangeModels); 
}

public Action ChangeModels(Handle timer)
{
	int model=0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (GetClientTeam(client)==2)
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
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Nick \x05]");
					}

					case 1: // Rochelle
					{
						SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1, 1, true);
						SetEntityModel(client, "models/survivors/survivor_producer.mdl");
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Rochelle \x05]");
					}

					case 2: // Coach
					{
						SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 2, 1, true);
						SetEntityModel(client, "models/survivors/survivor_coach.mdl");
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Coach \x05]");
					}

					case 3: // Ellis
					{
						SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
						SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Ellis \x05]");
					}

					case 4: // Zoey
					{
						SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 5, 1, true);
						SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Zoey \x05]");
					}

					case 5: // Francis
					{
						SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 6, 1, true);
						SetEntityModel(client, "models/survivors/survivor_biker.mdl");
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Francis \x05]");
					}

					case 6: // Louis
					{
						SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 7, 1, true);
						SetEntityModel(client, "models/survivors/survivor_manager.mdl");
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Louis \x05]");
					}

					//case 7: // Bill
					//{
					//	SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
					//	SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
					//	PrintToChat(client, "\x05[ \x01You're now playing as \x03Bill \x05]");
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
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Zoey \x05]");
					}

					case 1: // Francis
					{
						SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 6, 1, true);
						SetEntityModel(client, "models/survivors/survivor_biker.mdl");
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Francis \x05]");
					}

					case 2: // Louis
					{
						SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 7, 1, true);
						SetEntityModel(client, "models/survivors/survivor_manager.mdl");
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Louis \x05]");
					}

					//case 3: // Bill
					//{
					//	SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
					//	SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
					//	PrintToChat(client, "\x05[ \x01You're now playing as \x03Bill \x05]");
					//}

					case 4: // Nick
					{
						SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
						SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Nick \x05]");
					}

					case 5: // Rochelle
					{
						SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1, 1, true);
						SetEntityModel(client, "models/survivors/survivor_producer.mdl");
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Rochelle \x05]");
					}

					case 6: // Coach
					{
						SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 2, 1, true);
						SetEntityModel(client, "models/survivors/survivor_coach.mdl");
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Coach \x05]");
					}

					case 7: // Ellis
					{
						SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
						SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
						PrintToChat(client, "\x05[ \x01You're now playing as \x03Ellis \x05]");
					}
				}

				model=model+1;
			}
		}
	}
}