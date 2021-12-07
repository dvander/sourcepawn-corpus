
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

ConVar cvarPluginVersion, cvarPluginMode, cvarPluginModelMode, cvarPluginDelay, cvarAdvertDelay,
    cvarPluginSafel4d1, cvarPluginSafeScoring, cvarAdvertSafeScoringDelay;
char currentmap[64];
int check;

public Plugin myinfo =
{
	name = "L4D2 8 Survivors",
	description = "Allows to set 8 survivors without cloned models.",
	author = "kwski43 aka Jacklul",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1163224"
};

public void OnPluginStart()
{
	char s_Game[12];
	
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (!StrEqual(s_Game, "left4dead2"))
		SetFailState("Eight Survivors supports Left 4 Dead 2 only!");
		
	cvarPluginVersion = CreateConVar("l4d2_8survivors_version", PLUGIN_VERSION, "Eight Survivors Version", FCVAR_NOTIFY);
	cvarPluginMode = CreateConVar("l4d2_8survivors_mode", "1", "Eight Survivors Mode: 0-disable plugin, 1-new survivors first, 2-old survivors first", FCVAR_NONE, true, 0.0, true, 2.0);
	cvarPluginModelMode = CreateConVar("l4d2_8survivors_modelmode", "1", "Model change mode. 1-whole character, 2-only model", FCVAR_NONE, true, 1.0, true, 2.0);
	cvarPluginDelay = CreateConVar("l4d2_8survivors_delay", "8", "Delay from round start when plugin start changing models.", FCVAR_NONE, true, 0.0, true, 120.0);
	cvarAdvertDelay = CreateConVar("l4d2_8survivors_adsdelay", "5.0", "Advertisements after round start delay? 0-disable", FCVAR_NONE, true, 0.0, true, 60.0);
	cvarPluginSafel4d1 = CreateConVar("l4d2_8survivors_safel4d1", "1", "Will not give l4d1's whole character survivors on maps where bugs occur. This only affects if l4d2_8survivors_modelmode is set to 1.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarPluginSafeScoring = CreateConVar("l4d2_8survivors_safescoring", "0", "When the survivors reaches the saferoom they will get the default models. This should fix scoring bugs", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarAdvertSafeScoringDelay = CreateConVar("l4d2_8survivors_safescoringdelay", "180.0", "This is just a time how long the safescoring function will be blocked as it works on any saferoomdoors\nand the starting doors would switch to default models too! recommended: 120-300", FCVAR_NONE, true, 60.0, true, 300.0);

	AutoExecConfig(true, "l4d2_8survivors", "sourcemod");

	HookEvent("round_start", RoundStart, EventHookMode_Post);
	HookEvent("player_use", RoundEnd, EventHookMode_Post);
	SetConVarString(cvarPluginVersion, PLUGIN_VERSION);
}

public void OnMapStart()
{
	GetCurrentMap(currentmap, 64);
	PrecacheModel("models/survivors/survivor_namvet.mdl", true);
	PrecacheModel("models/survivors/survivor_biker.mdl", true);
	PrecacheModel("models/survivors/survivor_manager.mdl", true);
	PrecacheModel("models/survivors/survivor_teenangst.mdl", true);
	PrecacheModel("models/survivors/survivor_gambler.mdl", true);
	PrecacheModel("models/survivors/survivor_coach.mdl", true);
	PrecacheModel("models/survivors/survivor_producer.mdl", true);
	PrecacheModel("models/survivors/survivor_mechanic.mdl", true);
}

public Action Advert(Handle timer)
{
	PrintToChatAll("\x03Mod \x04[\x038 Survivors\x04]");
}

public void RoundStart(Event event, char[] name, bool dontbroadcast)
{
	if (cvarAdvertDelay.FloatValue > 0)
	{
		CreateTimer((cvarAdvertDelay.FloatValue), Advert);
	}
	if (cvarPluginModelMode.IntValue == 1)
	{
		CreateTimer((cvarPluginDelay.FloatValue), ChangeModelsMode1);
	}
	if (cvarPluginModelMode.IntValue == 2)
	{
		CreateTimer((cvarPluginDelay.FloatValue), ChangeModelsMode2);
	}
	if (cvarPluginSafeScoring.IntValue == 1)
	{
		CreateTimer((cvarAdvertSafeScoringDelay.FloatValue), CheckT);
	}
}

public Action CheckT(Handle timer)
{
	check = 1;
}

public Action ChangeModelsMode1(Handle timer)
{
	if(cvarPluginSafel4d1.IntValue && StrEqual(currentmap, "c6m1_riverbank") == true || StrEqual(currentmap, "c6m3_port") == true)
	{
		PrintToChatAll("\x04[\x038 Survivors\x04]\x01 �Plugin 8 survivors deactivated due to an internal problem \x04!");
	}
	else
	{
		int model = 0;
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				if (cvarPluginMode.IntValue == 1)
				{
					switch (model)
					{
						case 0:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
							SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Nick\x04!");
						}
						case 1:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1, 1, true);
							SetEntityModel(client, "models/survivors/survivor_producer.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Rochelle\x04!");
						}
						case 2:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 2, 1, true);
							SetEntityModel(client, "models/survivors/survivor_coach.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Coach\x04!");
						}
						case 3:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
							SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Ellis\x04!");
						}
						case 4:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 5, 1, true);
							SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Zoey\x04!");
						}
						case 5:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 6, 1, true);
							SetEntityModel(client, "models/survivors/survivor_biker.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Francis\x04!");
						}
						case 6:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 7, 1, true);
							SetEntityModel(client, "models/survivors/survivor_manager.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Louis\x04!");
						}
						case 7:
						{
							SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Bill\x04!");
						}
					}
					model = model + 1;
				}
				else if (cvarPluginMode.IntValue == 2)
				{
					switch (model)
					{
						case 0:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 5, 1, true);
							SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Zoey\x04!");
						}
						case 1:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 6, 1, true);
							SetEntityModel(client, "models/survivors/survivor_biker.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Francis\x04!");
						}
						case 2:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 7, 1, true);
							SetEntityModel(client, "models/survivors/survivor_manager.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Louis\x04!");
						}
						case 3:
						{
							SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Bill\x04!");
						}
						case 4:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
							SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Nick\x04!");
						}
						case 5:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1, 1, true);
							SetEntityModel(client, "models/survivors/survivor_producer.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Rochelle\x04!");
						}
						case 6:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 2, 1, true);
							SetEntityModel(client, "models/survivors/survivor_coach.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Coach\x04!");
						}
						case 7:
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
							SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Ellis\x04!");
						}
					}
					model = model + 1;
				}
			}
		}
	}
}

public Action ChangeModelsMode2(Handle timer)
{
	int model = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			if (cvarPluginMode.IntValue == 1)
			{
				switch (model)
				{
					case 0:
					{
						SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Nick\x04!");
					}
					case 1:
					{
						SetEntityModel(client, "models/survivors/survivor_producer.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\x05[ \x01Your model is now \x03Rochelle\x04!");
					}
					case 2:
					{
						SetEntityModel(client, "models/survivors/survivor_coach.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Coach\x04!");
					}
					case 3:
					{
						SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Ellis\x04!");
					}
					case 4:
					{
						SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Zoey\x04!");
					}
					case 5:
					{
						SetEntityModel(client, "models/survivors/survivor_biker.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Tu Skin es el de \x03Francis\x04!");
					}
					case 6:
					{
						SetEntityModel(client, "models/survivors/survivor_manager.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Louis\x04!");
					}
					case 7:
					{
						SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Bill\x04!");
					}
				}
				model = model + 1;
			}
			else if (cvarPluginMode.IntValue == 2)
			{
				switch (model)
				{
					case 0:
					{
						SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Zoey\x04!");
					}
					case 1:
					{
						SetEntityModel(client, "models/survivors/survivor_biker.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Francis\x04!");
					}
					case 2:
					{
						SetEntityModel(client, "models/survivors/survivor_manager.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Tu Skin es el de \x03Louis\x04!");
					}
					case 3:
					{
						SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Tu Skin es el de \x03Bill\x04!");
					}
					case 4:
					{
						SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Nick\x04!");
					}
					case 5:
					{
						SetEntityModel(client, "models/survivors/survivor_producer.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Rochelle\x04!");
					}
					case 6:
					{
						SetEntityModel(client, "models/survivors/survivor_coach.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Coach\x04!");
					}
					case 7:
					{
						SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Ellis\x04!");
					}
				}
				model = model + 1;
			}
		}
	}
}

public void RoundEnd(Event event, char[] name, bool dontbroadcast)
{
	if (check == 1)
	{
		int Entity = GetEventInt(event, "targetid");
		if (IsValidEntity(Entity))
		{
			char entname[128];
			if (GetEdictClassname(Entity, entname, 128))
			{
				if (StrEqual(entname, "prop_door_rotating_checkpoint", true))
				{
					if (cvarPluginSafeScoring.IntValue == 1)
					{
						PrintToChatAll("\x04[\x038 Survivors\x04]\x01 Character restored due to a score problem \x04!");
						int model = 0;
						for (int client = 1; client <= MaxClients; client++)
						{
							if (IsClientInGame(client) && GetClientTeam(client) == 2)
							{
								if (cvarPluginModelMode.IntValue == 1)
								{
									if (model >= 4) model = 0;
									switch (model)
									{
										case 0:
										{
											SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
											SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
											PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Nick\x04!");
										}
										case 1:
										{
											SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1, 1, true);
											SetEntityModel(client, "models/survivors/survivor_producer.mdl");
											PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Rochelle\x04!");
										}
										case 2:
										{
											SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 2, 1, true);
											SetEntityModel(client, "models/survivors/survivor_coach.mdl");
											PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Coach\x04!");
										}
										case 3:
										{
											SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
											SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
											PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your character is now \x03Ellis\x04!");
										}
									}
									model = model + 1;
								}
							}
						}
					}
				}
			}
		}
		check = 0;
	}
}
