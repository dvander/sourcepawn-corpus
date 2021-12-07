/* Plugin Version History
* 1.0 - Public release
* 1.1 - more configuration options
* 1.2 - delay fix
* 1.3 - advert disable fix
* 1.4 - more configuration options
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

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
new Handle:cvarPluginSafeScoring;
new Handle:cvarAdvertSafeScoringDelay;
new String:currentmap[64];
new check;

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
	cvarPluginDelay = CreateConVar("l4d2_8survivors_delay", "10", "Delay from round start when plugin start changing models.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 120.0);
	cvarAdvertDelay = CreateConVar("l4d2_8survivors_adsdelay", "5.0", "Advertisements after round start delay? 0-disable",FCVAR_PLUGIN, true, 0.0, true, 60.0);
	cvarPluginSafel4d1 = CreateConVar("l4d2_8survivors_safel4d1", "1", "Will not give l4d1's whole character survivors on maps where bugs occur. This only affects if l4d2_8survivors_modelmode is set to 1.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarPluginSafeScoring = CreateConVar("l4d2_8survivors_safescoring", "0", "When the survivors reaches the saferoom they will get the default models. This should fix scoring bugs", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarAdvertSafeScoringDelay = CreateConVar("l4d2_8survivors_safescoringdelay", "180.0", "This is just a time how long the safescoring function will be blocked as it works on any saferoomdoors\nand the starting doors would switch to default models too! recommended: 120-300",FCVAR_PLUGIN, true, 60.0, true, 300.0);
	
	
	AutoExecConfig(true, "l4d2_8survivors");
	
	HookEvent("round_start", RoundStart, EventHookMode_Post);
	HookEvent("player_use", RoundEnd, EventHookMode_Post);
	
	SetConVarString(cvarPluginVersion, PLUGIN_VERSION);
}

public OnMapStart()
{
	GetCurrentMap(currentmap, 64);
	PrecacheModel(MODEL_BILL, true);
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
	if(GetConVarFloat(cvarAdvertDelay) > 0)
	{
		CreateTimer(GetConVarFloat(cvarAdvertDelay), Advert);
	}
	if(GetConVarInt(cvarPluginModelMode) == 1)
	{
		CreateTimer(GetConVarFloat(cvarPluginDelay), ChangeModelsMode1);
	}
	if(GetConVarInt(cvarPluginModelMode) == 2)
	{
		CreateTimer(GetConVarFloat(cvarPluginDelay), ChangeModelsMode2);
	}
	if(GetConVarInt(cvarPluginSafeScoring) == 1)
	{
	CreateTimer(GetConVarFloat(cvarAdvertSafeScoringDelay), CheckT);
	}
}

public Action:CheckT(Handle:timer)
{
	check=1;
}

public Action:ChangeModelsMode1(Handle:timer)
{
	if(GetConVarInt(cvarPluginSafel4d1) && StrEqual(currentmap, "c6m1_riverbank") == true || StrEqual(currentmap, "c6m3_port") == true)
	{ 
		PrintToChatAll("\x04[\x038 Survivors\x04]\x01 Changing characters disabled due to bugs on this map\x04!");
	}
	else
	{
		new model=0;
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && GetClientTeam(client)==2)
			{
				if(GetConVarInt(cvarPluginMode)==1)
				{
					//code from http://forums.alliedmods.net/showthread.php?p=969651, now modified to cool'd it
					switch(model)
					{
						case 0: // Nick
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
							SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Nick\x04!");
						}
						case 1: // Rochelle
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1, 1, true);
							SetEntityModel(client, "models/survivors/survivor_producer.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Rochelle\x04!");
						}
						case 2: // Coach
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 2, 1, true);
							SetEntityModel(client, "models/survivors/survivor_coach.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Coach\x04!");
						}
						case 3: // Ellis
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
							SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Ellis\x04!");
						}
						case 4: // Zoey
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 5, 1, true);
							SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Zoey\x04!");
						}
						case 5: // Francis
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 6, 1, true);
							SetEntityModel(client, "models/survivors/survivor_biker.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Francis\x04!");
						}
						case 6: // Louis
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 7, 1, true);
							SetEntityModel(client, "models/survivors/survivor_manager.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Louis\x04!");
						}
						case 7: // Bill
						{
						SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Bill\x04!");
						}
					}
					model=model+1;
				}
				else if(GetConVarInt(cvarPluginMode)==2)
				{
					//code from http://forums.alliedmods.net/showthread.php?p=969651, now modified to cool'd it
					switch(model)
					{
						case 0: // Zoey
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 5, 1, true);
							SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Zoey\x04!");
						}
						case 1: // Francis
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 6, 1, true);
							SetEntityModel(client, "models/survivors/survivor_biker.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Francis\x04!");
						}
						case 2: // Louis
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 7, 1, true);
							SetEntityModel(client, "models/survivors/survivor_manager.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Louis\x04!");
						}
						case 3: // Bill
						{
						SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Bill\x04!");
						}
						case 4: // Nick
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
							SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Nick\x04!");
						}
						case 5: // Rochelle
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1, 1, true);
							SetEntityModel(client, "models/survivors/survivor_producer.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Rochelle\x04!");
						}
						case 6: // Coach
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 2, 1, true);
							SetEntityModel(client, "models/survivors/survivor_coach.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Coach\x04!");
						}
						case 7: // Ellis
						{
							SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
							SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
							PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Ellis\x04!");
						}
					}
					model=model+1;
				}
			}
		}
	}
}

public Action:ChangeModelsMode2(Handle:timer)
{
	new model=0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			if(GetConVarInt(cvarPluginMode)==1)
			{
				//code from http://forums.alliedmods.net/showthread.php?p=969651, now modified to cool'd it
				switch(model)
				{
					case 0: // Nick
					{
						SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Nick\x04!");
					}
					case 1: // Rochelle
					{
						SetEntityModel(client, "models/survivors/survivor_producer.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03\n\\x05[ \x01Your model is now \x03Rochelle\x04!");
					}
					case 2: // Coach
					{
						SetEntityModel(client, "models/survivors/survivor_coach.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Coach\x04!");
					}
					case 3: // Ellis
					{
						SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Ellis\x04!");
					}
					case 4: // Zoey
					{
						SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Zoey\x04!");
					}
					case 5: // Francis
					{
						SetEntityModel(client, "models/survivors/survivor_biker.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Francis\x04!");
					}
					case 6: // Louis
					{
						SetEntityModel(client, "models/survivors/survivor_manager.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Louis\x04!");
					}
					case 7: // Bill
					{
						SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Bill\x04!");
					}
				}
				model=model+1;
			}
			else if(GetConVarInt(cvarPluginMode)==2)
			{
				//code from http://forums.alliedmods.net/showthread.php?p=969651, now modified to cool'd it
				switch(model)
				{
					case 0: // Zoey
					{
						SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Zoey\x04!");
					}
					case 1: // Francis
					{
						SetEntityModel(client, "models/survivors/survivor_biker.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Francis\x04!");
					}
					case 2: // Louis
					{
						SetEntityModel(client, "models/survivors/survivor_manager.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Louis\x04!");
					}
					case 3: // Bill
					{
						SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01Your model is now \x03Bill\x04!");
					}
					case 4: // Nick
					{
						SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Nick\x04!");
					}
					case 5: // Rochelle
					{
						SetEntityModel(client, "models/survivors/survivor_producer.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Rochelle\x04!");
					}
					case 6: // Coach
					{
						SetEntityModel(client, "models/survivors/survivor_coach.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Coach\x04!");
					}
					case 7: // Ellis
					{
						SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
						PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Ellis\x04!");
					}
				}
				model=model+1;
			}
		}
	}
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(check==1)
	{
		new Entity = GetEventInt(event, "targetid");
		if(IsValidEntity(Entity))
		{
			new String:entname[128];
			if(GetEdictClassname(Entity, entname, sizeof(entname)))
			{
				/* Saferoom door */
				if(StrEqual(entname, "prop_door_rotating_checkpoint"))
				{
					if(GetConVarInt(cvarPluginSafeScoring) == 1)
					{
						PrintToChatAll("\x04[\x038 Survivors\x04]\x01 Changing characters to default due to scores bug\x04!");
						new model=0;
						for (new client = 1; client <= MaxClients; client++)
						{
							if (IsClientInGame(client) && GetClientTeam(client)==2)
							{
								if(GetConVarInt(cvarPluginModelMode) == 1)
								{
									if(model >= 4)
									{
										model=0;
									}
									switch(model)
									{
										case 0: // Nick
										{
											SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
											SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
											PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Nick\x04!");
										}
										case 1: // Rochelle
										{
											SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1, 1, true);
											SetEntityModel(client, "models/survivors/survivor_producer.mdl");
											PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Rochelle\x04!");
										}
										case 2: // Coach
										{
											SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 2, 1, true);
											SetEntityModel(client, "models/survivors/survivor_coach.mdl");
											PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Coach\x04!");
										}
										case 3: // Ellis
										{
											SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
											SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
											PrintToChat(client, "\x04[\x038 Survivors\x04]\x03 \x01You're now playing as \x03Ellis\x04!");
										}
									}
									model=model+1;
								}
							}
						}
					}
				}
			}
		}
		check=0;
	}
}
