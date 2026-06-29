#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#define PLUGIN_VERSION "1.2.3.0"
#undef REQUIRE_EXTENSIONS
#pragma semicolon 1 
new Handle:RegenTimer;
new Handle:CV_MEDMICMODEL = INVALID_HANDLE;
new Handle:CV_MEDICNUMBER = INVALID_HANDLE;
new Handle:CV_INFECTIONCURE = INVALID_HANDLE;
new Handle:CV_MAXTEACH = INVALID_HANDLE;
new Handle:CV_HEARTBEATENABLE = INVALID_HANDLE;
new Handle:handledtimer[33],bool:CheckHeadMedic[33];
new RegenScore[33],TeachLeval[33];
new bool:IsMedic[33] = false;
new IsInfected = -1;
new CarrierOffset = -1;
new MedicsNum = 0;
public Plugin:myinfo = {
	name = "ZP:S Hey Medic Plugin",
	author = "Master(D)",
	description = "Adds A Medic to ZPS who can heal players, + Heartbeat addon.",
	version = PLUGIN_VERSION,
	url = "http://"
}
public OnPluginStart() {
	RegAdminCmd("sm_givemedic", Command_GiveMedicPlayer, ADMFLAG_SLAY);
	RegConsoleCmd("sm_teach",Command_Teach);
	RegConsoleCmd("sm_ismedic",cheakmedicMe);
	HookEvent("game_round_restart", GameStart);
	HookEvent("round_end", GameEnd);
	HookEvent("player_death", EventDeath);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	RegenTimer = CreateConVar("sm_regentime", "3.0");
	CV_MEDMICMODEL = CreateConVar("sm_medicmodel","models/Humans/Group03m/male_06.mdl","Defalt Medic Model",FCVAR_NOTIFY);
	CV_MEDICNUMBER = CreateConVar("sm_medicnumber","1","Disable = 0, Enable = 1, 2 Medics = 2, 3 medics = 3",FCVAR_NOTIFY);
	CV_INFECTIONCURE = CreateConVar("sm_mediccureinfection","1", "enable = 1, disable = 0",FCVAR_NOTIFY);
	CV_MAXTEACH = CreateConVar("sm_maxteach","1", "enable >= 1, disable = 0",FCVAR_NOTIFY);
	CV_HEARTBEATENABLE = CreateConVar("sm_heartbeat","1", "enable = 1, disable = 0",FCVAR_NOTIFY);
	IsInfected = FindSendPropOffs("CHL2MP_Player", "m_IsInfected");
	new Handle:conf = LoadGameConfigFile("zpsinfectiontoolkit");
	CarrierOffset = GameConfGetOffset(conf, "IsCarrier");
	CloseHandle(conf);
}
public OnAllPluginsLoaded() {

	if (GetExtensionFileStatus("sdkhooks.ext") != 1) {

		SetFailState("SDK Hooks v1.3 or higher is required for ZPS Medic");

	}
	for (new X = 1; X <= MaxClients; X++)
 {

		if (IsClientInGame(X)) {

			SDKHook(X, SDKHook_OnTakeDamage, OnTakeDamage);
		}

	}

}


public OnMapStart() {
	new String:MedicModel[255];
	GetConVarString(CV_MEDMICMODEL,MedicModel, 255);
	PrecacheModel(MedicModel);
}
public OnClientPutInServer(Client) {
	SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
	if(GetConVarInt(CV_HEARTBEATENABLE) == 1) {
		SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage2);
	} CreateTimer(1.5, CheckClientOrg, Client, TIMER_REPEAT);
}
public Action:GameStart(Handle:Event, const String:Name[], bool:Broadcast) {
	CreateTimer(7.0, ChooseMedic);
	CloseHandle(Event);
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new UserId = GetEventInt(event, "userid");
	new UserIndex = GetClientOfUserId(UserId);
	new ClientRagdoll = GetEntPropEnt(UserIndex, Prop_Send, "m_hRagdoll");
	new Float:XMultiplier = 10.0;
	new Float:YMultiplier = 10.0;
	new Float:ZMultiplier = 10.0;
	new Float:Force[3];
	GetEntPropVector(ClientRagdoll, Prop_Send, "m_vecForce", Force);
	Force[0] *= XMultiplier;
	Force[1] *= YMultiplier;
	Force[2] *= ZMultiplier;
	SetEntPropVector(ClientRagdoll, Prop_Send, "m_vecForce", Force);
	new Float:Velocity[3];
	GetEntPropVector(ClientRagdoll, Prop_Send, "m_vecRagdollVelocity", Velocity);
	Velocity[0] *= XMultiplier;
	Velocity[1] *= YMultiplier;
	Velocity[2] *= ZMultiplier;
	SetEntPropVector(ClientRagdoll, Prop_Send, "m_vecRagdollVelocity", Velocity);
	return Plugin_Continue;
}  
public Action:GameEnd(Handle:Event, const String:Name[], bool:Broadcast) {
	for (new X = 1; X <= MaxClients; X++)
 {

		if(IsClientInGame(X) && IsClientConnected(X)) {
			IsMedic[X] = false;
			CheckHeadMedic[X] = false;
			MedicsNum = 0;
			TeachLeval[X] = 0;
		}
	} CloseHandle(Event);
}
public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast) {
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	if(IsClientInGame(Client) && IsClientConnected(Client)) {
		if(GetClientTeam(Client) == 2) {
			if(IsMedic[Client] == true) {
				IsMedic[Client] = false;
				CheckHeadMedic[Client] = false;
				if(MedicsNum > 0) {
					MedicsNum -= 1;
				} SetCarrier(Client, true);
			} TeachLeval[Client] = 0;
			IsMedic[Client] = false;
		} IsMedic[Client] = false;
	} CloseHandle(Event);
}
public Action:OnTakeDamage(Client, &attacker, &inflictor, &Float:damage, &damageType) {
	if(GetClientTeam(Client) == 2) {
		if(GetConVarInt(CV_HEARTBEATENABLE) == 1) {
			CreateTimer(1.0, HeartBeat, Client);
		} else if(IsMedic[Client] == true) {
			if(handledtimer[Client] == INVALID_HANDLE) {
				handledtimer[Client] = CreateTimer(GetConVarFloat(RegenTimer), HandleMedicRegenTimer, Client, TIMER_REPEAT);
			}
		}
	}
}
public Action:OnTakeDamage2(Client, &attacker, &inflictor, &Float:damage, &damageType) {
	if(GetClientTeam(Client) == 3 && GetClientTeam(attacker) == 2) {
		new String:WeaponName[32];
		GetClientWeapon(attacker, WeaponName, 32);
		if(StrEqual(WeaponName, "weapon_frag", false)) {
			if(damage > 30) {
				if(damage >= 71) {
					IgniteEntity(Client,12.0);
				} else if(damage >= 51) {
					IgniteEntity(Client,9.0);
				} else if(damage >= 31) {
					IgniteEntity(Client,6.0);
				}
			} else { IgniteEntity(Client,3.0); }
		}
	}
}
public Action:ChooseMedic(Handle:timer) {
	decl String:MedicModel[255];
	GetConVarString(CV_MEDMICMODEL, MedicModel, 255);
	if(GetConVarInt(CV_MEDICNUMBER) == 1) {
		new player1 = GetRandomPlayer(2);
		if (player1 != -1) {
			if(GetClientTeam(player1) == 2) {
				SetEntityModel(player1, MedicModel);
				IsMedic[player1] = true;
				CheckHeadMedic[player1] = true;
				return;
			}
		}
	} if(GetConVarInt(CV_MEDICNUMBER) == 2) {
		if(GetClientCount() >=12) {
			new player2 = GetRandomPlayer(2);
			if (player2 != -1) {
				if(GetClientTeam(player2) == 2) {
					SetEntityModel(player2, MedicModel);
					IsMedic[player2] = true;
					CheckHeadMedic[player2] = true;
					return;
				}
			}
		}
	} if(GetConVarInt(CV_MEDICNUMBER) == 3) {
		if(GetClientCount() >=22) {
			new player3 = GetRandomPlayer(2);
			if (player3 != -1) {
				if(GetClientTeam(player3) == 2) {
					SetEntityModel(player3, MedicModel);
					IsMedic[player3] = true;
					CheckHeadMedic[player3] = true;
					return;
				}
			}
		}
	} else {
		CreateTimer(0.1, ChooseMedic);
	} return;
}

public Action:HandleRegenTimer(Handle:timer, any:Client) {
	new ClientHealth = GetClientHealth(Client);
	new Switch = GetRandomInt(1, 4);
	if(Switch == 1) RegenScore[Client] = 1;
	if(Switch == 2) RegenScore[Client] = 2;
	if(Switch == 3) RegenScore[Client] = 3;
	if(Switch == 4) RegenScore[Client] = 4;
	if(ClientHealth == 100) { KillTimer(timer); }
	if((ClientHealth + RegenScore[Client]) >= 100) {
		if(GetConVarInt(CV_INFECTIONCURE) == 1) {
			SetEntData(Client, IsInfected, 0);
		}
		SetEntityHealth(Client, 100);
		handledtimer[Client] = INVALID_HANDLE;
		KillTimer(timer);
	} else {
		if(GetConVarInt(CV_INFECTIONCURE) == 1) {
			SetEntData(Client, IsInfected, 0);
		} SetEntityHealth(Client, (ClientHealth + RegenScore[Client]));
	} return Plugin_Handled;
}
public Action:HandleMedicRegenTimer(Handle:timer, any:Client) {
	new ClientHealth = GetClientHealth(Client);
	new Switch = GetRandomInt(1, 5);
	if(Switch == 1) RegenScore[Client] = 4;
	if(Switch == 2) RegenScore[Client] = 5;
	if(Switch == 3) RegenScore[Client] = 6;
	if(Switch == 4) RegenScore[Client] = 7;
	if(Switch == 5) RegenScore[Client] = 8;
	if(IsMedic[Client] == true) {
		if(ClientHealth == 100) { KillTimer(timer); }
		if((ClientHealth + RegenScore[Client]) >= 100) {
			if(GetConVarInt(CV_INFECTIONCURE) == 1) {
				SetEntData(Client, IsInfected, 0);
			}
			SetEntityHealth(Client, 100);
			handledtimer[Client] = INVALID_HANDLE;
			KillTimer(timer);
		} else {
			SetEntityHealth(Client, (ClientHealth + RegenScore[Client]));
			CreateTimer(2.0, HandleMedicRegenTimer, Client);
			if(GetConVarInt(CV_INFECTIONCURE) == 1) {
				SetEntData(Client, IsInfected, 0);
			}
		}
	} return Plugin_Handled;
}
public Action:HeartBeat(Handle:timer, any:Client) {
	if(IsClientConnected(Client) && IsClientInGame(Client)) {
		if(GetClientTeam(Client) == 2) {
			new String:Sound[256] = "heart_normal.wav";
			if(IsPlayerAlive(Client)) {
				if(GetClientHealth(Client) <= 10) {
					//new Switch = GetRandomInt(1, 4);
					//new String:Sound[256];
					//if(Switch == 1) Sound = "infection/jolt-01.wav";
					//if(Switch == 2) Sound = "infection/jolt-02.wav";
					//if(Switch == 3) Sound = "infection/jolt-03.wav";
					//if(Switch == 4) Sound = "infection/jolt-04.wav";
					ClientCommand(Client, "play \"%s\"", Sound);
					CreateTimer(1.0, HeartBeat, Client);
					//CreateTimer(3.0, HeartBeat, Client);
				} else if(GetClientHealth(Client) <= 20) {
					ClientCommand(Client, "play \"%s\"", Sound);
					CreateTimer(1.4, HeartBeat, Client);
				} else if(GetClientHealth(Client) <= 30) {
					ClientCommand(Client, "play \"%s\"", Sound);
					CreateTimer(1.7, HeartBeat, Client);
				} else if(GetClientHealth(Client) <= 40) {
					ClientCommand(Client, "play \"%s\"", Sound);
					CreateTimer(2.0, HeartBeat, Client);
				} else {
					KillTimer(timer);
				}
			} else {
				KillTimer(timer);
			}
		} else {
			KillTimer(timer);
		}
	} else {
		KillTimer(timer);
	}
}
public Action:CheckClientOrg(Handle:Timer, any:Client) {
	if(handledtimer[Client] == INVALID_HANDLE) {
		if(IsClientConnected(Client) && IsClientInGame(Client)) {
			if(IsMedic[Client] || CheckHeadMedic[Client] == true) {
				decl Float:MedicOrigin[3],Float:TargetOrigin[3], Float:Distance;
				GetClientAbsOrigin(Client, MedicOrigin);
				for (new X = 1; X <= MaxClients; X++) {
					if(X != Client && IsClientConnected(X) && IsClientInGame(X)) {
						if(IsPlayerAlive(X) && IsPlayerAlive(Client)) {
							FaceModel(Client);
							GetClientAbsOrigin(X, TargetOrigin);
							Distance = GetVectorDistance(TargetOrigin,MedicOrigin);
							if(GetClientTeam(X) == 2 && GetClientTeam(Client) == 2) {
								if(Distance <= 75.0 && GetClientHealth(X) <=99) {
									handledtimer[Client] = CreateTimer(GetConVarFloat(RegenTimer), HandleMedicRegenTimer, X, TIMER_REPEAT);
								}
							}
						}
					}
				}
			}
		}
	} return Plugin_Handled;
}
public Action:TeachTimer(Handle:Timer, any:Client) {
	for (new X = 1; X <= MaxClients; X++)
 {

		if(IsClientConnected(X) && IsClientInGame(X)) {
			decl Float:ClientOrigin[3],Float:PlayerOrigin[3],Float:Distance;
			decl String:MedicModel[255],String:MedicName[32], String:ClientName[32];
			GetClientAbsOrigin(X, PlayerOrigin);
			GetClientAbsOrigin(Client, ClientOrigin);
			if(Distance <= 75.0) {
				if(IsMedic[X] == true) {
					if(CheckHeadMedic[X] == true) {
						GetClientName(X, MedicName, 32);
						GetClientName(Client, ClientName, 32);
						if(IsPlayerAlive(Client)) {
							if(TeachLeval[Client] < 100) {
								decl String:buffer[3];
								new Float:TeachNum = GetRandomFloat(0.0, 1000.0) / 10.0;
								FloatToString(TeachNum, buffer, 3);
								ReplyToCommand(Client, "\x01[SM] - \x04%s has teached you \x05%2.2f\x01 Percent how to be a medic", MedicName, TeachNum);
								ReplyToCommand(X, "\x01[SM] - You have teached \x04%s\x05 %2.2f\x01 percent how to be a medic ", ClientName, TeachNum);
								TeachLeval[Client] == TeachLeval[Client] + TeachNum;
								CreateTimer(1.0, TeachTimer, X);
 							} else {
								IsMedic[Client] = true;
								CheckHeadMedic[Client] = false;
								MedicsNum ++;
								GetConVarString(CV_MEDMICMODEL, MedicModel, 255);
								SetEntityModel(Client, MedicModel);
								ReplyToCommand(Client, "\x01[SM] - \x04%s\x01 has teached you how to be a medic", MedicName);
								ReplyToCommand(X, "\x01[SM] - You have teached \x04%s\x01 how to be a medic ", ClientName);
								KillTimer(Timer);
							}
						} else {
							ReplyToCommand(Client, "\x01[SM] - The \x04%s\x01 has died and you carnt be teached anymore", MedicName);
							KillTimer(Timer);
						}
					} else {
						ReplyToCommand(Client, "\x01[SM] - You have moved to far away from the head medic");
						KillTimer(Timer);
					}
				} else {
					KillTimer(Timer);
				}
			} else {
				ReplyToCommand(Client, "\x01[SM] - You have moved to far away from the head medic");
				KillTimer(Timer);
			}
		} else {
			ReplyToCommand(Client, "\x01[SM] - This player isnt connected or not ingame");
			KillTimer(Timer);
		}
	}
}
public Action:Command_Teach(Client, args) {
	new Player = GetClientAimTarget(Client,false);
	if(Player > 0) {
		decl Float:ClientOrigin[3],Float:PlayerOrigin[3],Float:Distance,String:PlayerName[32],String:ClientName[32];
		GetClientAbsOrigin(Player, PlayerOrigin);
		GetClientAbsOrigin(Client, ClientOrigin);
		GetClientName(Player, PlayerName, 32);
		GetClientName(Client, ClientName, 32);
		Distance = GetVectorDistance(ClientOrigin, PlayerOrigin);
		if(Distance <= 75.0) {
			if(IsClientConnected(Player) && IsClientInGame(Player)) {
				if(GetClientTeam(Player) == 2) {
					if(IsMedic[Client] == true) {
						if(!IsMedic[Player] == true) {
							if(CheckHeadMedic[Client] == true) {
								if(MedicsNum <= GetConVarFloat(CV_MAXTEACH)) {
									ReplyToCommand(Client, "\x01[SM] - You Teaching \x04%s\x01 to be a medic", PlayerName);
									ReplyToCommand(Player, "\x01[SM] - %s is teaching you how to be a medic", ClientName);
									CreateTimer(0.5, TeachTimer, Player);
									return Plugin_Handled;
								} else { 
									ReplyToCommand(Client, "\x01[SM] - You have reached your max teach limit");
									return Plugin_Handled;
								}
							} else {
								ReplyToCommand(Client, "\x01[SM] - your not the head medic you carn't teach this player");
								return Plugin_Handled;
							}
						} else {
							ReplyToCommand(Client, "\x01[SM] - This player is already a medic you carn't teach them");
							return Plugin_Handled;
						}
					} else {
						ReplyToCommand(Client, "\x01[SM] - Your not a medic you carn't teach this player");
						return Plugin_Handled;
					}
				} else {
					ReplyToCommand(Client, "\x01[SM] - This player is a zombie they carnt be teached");
					return Plugin_Handled;
				}
			} else {
				ReplyToCommand(Client, "\x01[SM] - This player isnt connected or not ingame");
				return Plugin_Handled;
			}			
		} else {
			ReplyToCommand(Client, "\x01[SM] - this player is to far away you carnt teach him");
			return Plugin_Handled;
		}
	} else {
		ReplyToCommand(Client, "\x01[SM] - Invalid Player");
		return Plugin_Handled;
	}
}
public Action:cheakmedicMe(Client, args) {
	if(IsMedic[Client] == true) {
		ReplyToCommand(Client, "\x01[SM] - Yes you are a medic");
	} else if(IsMedic[Client] == false) {
		ReplyToCommand(Client, "\x01[SM] - No you are not a medic");
	} return Plugin_Handled;
}
public Action:Command_GiveMedicPlayer(Client, Args) {
	decl String:target_name[255],Player,String:PlayerName[32];
	decl target_list[33],target_count,bool:tn_is_ml,String:MedicModel[255];
	GetCmdArg(1, PlayerName, sizeof(PlayerName));
	if(!IsClientAuthorized(Client)) {
		ReplyToCommand(Client, "\x01[SM] - SteamID Error");
		return Plugin_Handled;
	}
    	if(Args != 1) {
        	ReplyToCommand(Client, "\x01[SM] - Wrong Parameter. Usage: sm_givemedic <NAME>");
        	return Plugin_Handled;
    	}
	if ((target_count = ProcessTargetString(PlayerName,0,target_list,MaxClients,0,target_name,sizeof(target_name),tn_is_ml)) <= 0) {
		ReplyToCommand(Client, "\x01[SM] - Could not find Client %s", PlayerName);
		return Plugin_Handled;
	}
	if(target_count > 1) {
		ReplyToCommand(Client, "\x01[SM] - Token \x04%s\x05 not unique", PlayerName);
		return Plugin_Handled;
	}
	Player = target_list[0];
	if(IsClientInGame(Player) && IsClientConnected(Player) && IsPlayerAlive(Player)) {
		GetClientName(Player, PlayerName, 32);
		if(IsMedic[Player] == true) {
			ReplyToCommand(Client, "\x01[SM] - Player \x04%s\x05 is already medic", PlayerName);
			return Plugin_Handled;
		}
		if(!IsMedic[Player] == true) {
			PrintToChatAll("\x01[SM] - Player %s is now medic", PlayerName);
			GetConVarString(CV_MEDMICMODEL, MedicModel, 255);
			SetEntityModel(Player, MedicModel);
			IsMedic[Player] = true;
			CheckHeadMedic[Player] = true;
			return Plugin_Handled;
		}
	} return Plugin_Handled;
}
public FaceModel(Client) {
	new String:Buffer[64], String:MedicModel[255];
	GetConVarString(CV_MEDMICMODEL,MedicModel, 255);
	GetClientModel(Client, Buffer, 64);
	if(GetClientTeam(Client) == 2) {
		if(FileExists(MedicModel, true)) {
			if(IsModelPrecached(MedicModel)) {
				if(!StrEqual(Buffer, MedicModel, false)) {
					SetEntityModel(Client, MedicModel);
				} else { return; }
			} else { PrecacheModel(MedicModel); }
		} else { return; }
	} else { return; }
}
stock GetRandomPlayer(team) {
	new clients[MaxClients+1], clientCount;
	for (new X = 1; X <= MaxClients; X++) {
		if (IsClientInGame(X) && (GetClientTeam(X) == team)) {
			clients[clientCount++] = X;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}
public SetCarrier(client, bool:set) {
	SetEntData(client, CarrierOffset, set);
}