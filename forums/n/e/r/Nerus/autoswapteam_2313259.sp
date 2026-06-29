#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors>



#define PLUGIN_VERSION "2.2.2"
#define MAX_FILE_LEN 128


	
public Plugin:myinfo = 
{
    name = "Auto Swap Team",
    author = "Experto",
    description = "Auto Swap Team",
    version = PLUGIN_VERSION,
    url = "http://fortal.forumeiros.com"
};



new Handle:astEnable = INVALID_HANDLE;
new Handle:astType = INVALID_HANDLE;
new Handle:astScoreType = INVALID_HANDLE;
new Handle:astResetCash = INVALID_HANDLE;
new Handle:astResetFrag = INVALID_HANDLE;
new Handle:astResetDead = INVALID_HANDLE;
new Handle:astResetWeapon = INVALID_HANDLE;

new Handle:astAdvertRound = INVALID_HANDLE;
new Handle:astAdvertAlert = INVALID_HANDLE;
new Handle:astAdvertSwap = INVALID_HANDLE;

new Handle:astPlaySound = INVALID_HANDLE;

new Handle:astSoundRound = INVALID_HANDLE;
new Handle:astSoundFileRound = INVALID_HANDLE;

new Handle:astSoundAlert = INVALID_HANDLE;
new Handle:astSoundFileAlert = INVALID_HANDLE;

new Handle:astSoundSwap = INVALID_HANDLE;
new Handle:astSoundFileSwap = INVALID_HANDLE;

new Handle:astImmuneSwap = INVALID_HANDLE;
new Handle:astImmuneCash = INVALID_HANDLE;
new Handle:astImmuneFrag = INVALID_HANDLE;
new Handle:astImmuneDead = INVALID_HANDLE;
new Handle:astImmuneWeapon = INVALID_HANDLE;

new Handle:astMaxRound = INVALID_HANDLE;

new String:modelCT[4][128];
new String:modelT[4][128];

new bool:swapNow = false;
new bool:isSwap = false;

new scoreSwapCT;
new scoreSwapT;

new nRound;

new String: soundFileRound[MAX_FILE_LEN];
new String: soundFileAlert[MAX_FILE_LEN];
new String: soundFileSwap[MAX_FILE_LEN];

new startMoney;
new cashOffset;

new Handle:DB_AST = INVALID_HANDLE;



RegisterCvars()
{
	AutoExecConfig(true, "autoswapteam");

	CreateConVar("sm_autoswapteam_version", PLUGIN_VERSION, "Auto Swap Team", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	astEnable = CreateConVar("sm_autoswapteam_enable", "1", "Liga/Desliga o Auto Swap Team. [0 = Desligado, 1 = Ligado]", _, true, 0.0, true, 1.0);
	astType = CreateConVar("sm_autoswapteam_type", "1", "Define o tipo do Auto Swap. [1 = TEMPO, 2 = NR DE RODADAS, 3 = NR DE VITORIAS, 4 = PONTUACAO, 5 = SEM LIMITES DEFINIDOS...]", _, true, 1.0, true, 5.0);
	astScoreType = CreateConVar("sm_autoswapteam_scoretype", "2", "Define acao para o score. [0 = MANTER, 1 = ZERAR, 2 = TROCAR]", _, true, 0.0, true, 2.0);
	astResetCash = CreateConVar("sm_autoswapteam_resetcash", "0", "Resetar Dinheiro após a troca? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astResetFrag = CreateConVar("sm_autoswapteam_resetfrag", "0", "Resetar Pontuacao após a troca? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astResetDead = CreateConVar("sm_autoswapteam_resetdead", "0", "Resetar Mortes após a troca? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astResetWeapon = CreateConVar("sm_autoswapteam_resetweapon", "0", "Resetar Armas após a troca? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);

	astAdvertRound = CreateConVar("sm_autoswapteam_advert_round", "1", "Mensagem de aviso a cada round? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astAdvertAlert = CreateConVar("sm_autoswapteam_advert_alert", "1", "Mensagem de aviso antes do swap? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astAdvertSwap = CreateConVar("sm_autoswapteam_advert_swap", "1", "Mensagem de aviso apos swap? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);

	astPlaySound = CreateConVar("sm_autoswapteam_playsound", "1", "Tocar som? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);

	astSoundRound = CreateConVar("sm_autoswapteam_sround", "1", "Tocar som de round? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astSoundFileRound = CreateConVar("sm_autoswapteam_sfile_round", "hostage/huse/okletsgo.wav", "Endereco do arquivo de som de Round");

	astSoundAlert = CreateConVar("sm_autoswapteam_salert", "1", "Tocar som de Alerta antes do swap? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astSoundFileAlert = CreateConVar("sm_autoswapteam_sfile_alert", "buttons/bell1.wav", "Endereco do arquivo de som de Alerta");

	astSoundSwap = CreateConVar("sm_autoswapteam_sswap", "1", "Tocar som apos swap? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astSoundFileSwap = CreateConVar("sm_autoswapteam_sfile_swap", "ambient/misc/brass_bell_C.wav", "Endereco do arquivo de som de Swap");

	astImmuneSwap = CreateConVar("sm_autoswapteam_immune_swap", "0", "Admins sao imunes ao Auto Swap? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astImmuneCash = CreateConVar("sm_autoswapteam_immune_cash", "0", "Resetar Dinheiro dos Admins após a troca? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astImmuneFrag = CreateConVar("sm_autoswapteam_immune_frag", "0", "Resetar Pontuação dos Admins após a troca? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astImmuneDead = CreateConVar("sm_autoswapteam_immune_dead", "0", "Resetar Mortes dos Admins após a troca? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astImmuneWeapon = CreateConVar("sm_autoswapteam_immune_weapon", "0", "Resetar Armas dos Admins após a troca? [0 = NAO, 1 = SIM]", _, true, 0.0, true, 1.0);
	astMaxRound = CreateConVar("sm_autoswapteam_maxround", "10", "Quando sm_autoswapteam_type = 5.\nQuantidade máxima de rodadas antes da troca?", _, true, 1.0);
}



public OnPluginStart()
{
	RegisterCvars();

	AutoExecConfig(true, "autoswapteam");

	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);

	RegAdminCmd("sm_autoswapteam_immunity_add", ImmunityAdd, ADMFLAG_BAN, "Adiciona um jogador a lista de imunidade do Auto Swap Team");
	RegAdminCmd("sm_autoswapteam_immunity_del", ImmunityRemove, ADMFLAG_BAN, "Remove um jogador da lista de imunidade do Auto Swap Team");

	RegAdminCmd("sm_autoswapteam_immunity_list", ImmunityList, ADMFLAG_BAN, "Exibe a lista de imunidade do Auto Swap Team");

	cashOffset = FindSendPropInfo("CCSPlayer","m_iAccount");

	LoadTranslations("autoswapteam.phrases");

	ConnectDB();

	CPrintToChatAll("Auto Swap Team ON");
}



public OnConfigsExecuted()
{
	CacheSounds();
}



public OnMapStart()
{
	CacheSounds();

	swapNow = false;
	isSwap = false;

	scoreSwapCT = 0;
	scoreSwapT = 0;

	nRound = 0;

	PrecacheModel("models/player/ct_gign.mdl",true);
	PrecacheModel("models/player/ct_gsg9.mdl",true);
	PrecacheModel("models/player/ct_sas.mdl",true);
	PrecacheModel("models/player/ct_urban.mdl",true);

	PrecacheModel("models/player/t_arctic.mdl",true);
	PrecacheModel("models/player/t_guerilla.mdl",true);
	PrecacheModel("models/player/t_leet.mdl",true);
	PrecacheModel("models/player/t_phoenix.mdl",true);

	modelCT[0] = "models/player/ct_gign.mdl";
	modelCT[1] = "models/player/ct_gsg9.mdl";
	modelCT[2] = "models/player/ct_sas.mdl";
	modelCT[3] = "models/player/ct_urban.mdl";

	modelT[0] = "models/player/t_arctic.mdl";
	modelT[1] = "models/player/t_guerilla.mdl";
	modelT[2] = "models/player/t_leet.mdl";
	modelT[3] = "models/player/t_phoenix.mdl";
}



public OnRoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (GetConVarBool(astEnable))
	{
		//5 = SEM LIMITE DEFINIDO
		if (GetConVarInt(astType) == 5)
		{
			nRound++;

			if (swapNow)
			{
				for(new client = 1; client <= MaxClients; client++)
				{
					if(IsValidClient(client) || IsBot(client))
					{
						if (!IsAdmin(client))
						{
							new immunity[5];

							immunity = GetImmunityById(client);

							// 1 WEAPON
							// 2 DEAD
							// 3 FRAG
							// 4 CASH

							if (GetConVarBool(astResetWeapon) && (immunity[1] == 0))
							{
								ResetWeapon(client);
							}

							if (GetConVarBool(astResetDead) && (immunity[2] == 0))
							{
								ResetDead(client);
							}

							if (GetConVarBool(astResetFrag) && (immunity[3] == 0))
							{
								ResetFrag(client);
							}

							if (GetConVarBool(astResetCash) && (immunity[4] == 0))
							{
								ResetCash(client);
							}

						}
						else
						{
							if (GetConVarBool(astResetWeapon) && !GetConVarBool(astImmuneWeapon))
							{
								ResetWeapon(client);
							}

							if (GetConVarBool(astResetDead) && !GetConVarBool(astImmuneDead))
							{
								ResetDead(client);
							}

							if (GetConVarBool(astResetFrag) && !GetConVarBool(astImmuneFrag))
							{
								ResetFrag(client);
							}

							if (GetConVarBool(astResetCash) && !GetConVarBool(astImmuneCash))
							{
								ResetCash(client);
							}
						}

					}

				}

				swapNow = false;
			}

			new maxRound = GetConVarInt(astMaxRound);

			if (nRound == maxRound)
			{
				swapNow = true;

				if (GetConVarBool(astAdvertAlert))
				{
					CPrintToChatAll("\x01[AST]\x04 %t","advert_will_swap");
				}

				if (GetConVarBool(astPlaySound))
				{
					PlaySound(2);
				}
			}
			else
			{
				if (GetConVarBool(astAdvertRound))
				{
					new difference = maxRound - nRound;
					CPrintToChatAll("\x01[AST]\x04 %t","advert_rounds",difference+1);
				}

				if (GetConVarBool(astPlaySound))
				{
					PlaySound(1);
				}
			}
		}
		else
		{

			// Se ainda não houve o swap
			if (!isSwap)
			{
				//1 = TEMPO
				if (GetConVarInt(astType) == 1)
				{
					new timeLimit;

					if (GetMapTimeLimit(timeLimit) && timeLimit > 0)
					{
						new timeLeft;

						if (GetMapTimeLeft(timeLeft) && timeLeft > 0)
						{
							new minLeft;
							minLeft = timeLeft / 60;

							new minSwap = (timeLimit / 2);

							if (minLeft <= minSwap)
							{
								swapNow = true;
							}
							else if (GetConVarBool(astAdvertRound))
							{
								new difference = minLeft - minSwap;

								CPrintToChatAll("\x01[AST]\x04 %t","advert_time",difference);

								if (GetConVarBool(astPlaySound))
								{
									PlaySound(1);
								}
							}
						}
					}
				}

				//2 = NR DE RODADAS
				else if (GetConVarInt(astType) == 2)
				{
					new maxRounds = GetConVarInt(FindConVar("mp_maxrounds"));

					if (maxRounds > 0)
					{
						new roundSwap;

						roundSwap = maxRounds / 2;

						new scoreCT = GetTeamScore(CS_TEAM_CT);
						new scoreT = GetTeamScore(CS_TEAM_T);

						new sumRound = scoreCT + scoreT + 1;

						if(sumRound == roundSwap)
						{
							swapNow = true;
						}
						else if (GetConVarBool(astAdvertRound))
						{
							new difference = roundSwap - sumRound;

							CPrintToChatAll("\x01[AST]\x04 %t","advert_rounds",difference+1);

							if (GetConVarBool(astPlaySound))
							{
								PlaySound(1);
							}
						}
					}
				}

				//3 = NR DE VITORIAS
				else if (GetConVarInt(astType) == 3)
				{
					new winLimit = GetConVarInt(FindConVar("mp_winlimit"));

					if (winLimit > 0)
					{
						new winSwap;

						winSwap = winLimit / 2;

						if (GetConVarBool(astAdvertRound))
						{
							CPrintToChatAll("\x01[AST]\x04 %t","advert_wins",winSwap);
						}

						if (GetConVarBool(astPlaySound))
						{
							PlaySound(1);
						}
					}
				}

				//4 = PONTUACAO
				else if (GetConVarInt(astType) == 4)
				{
					new fragLimit = GetConVarInt(FindConVar("mp_fraglimit"));

					if (fragLimit > 0)
					{
						new fragSwap = fragLimit / 2;

						if (GetConVarBool(astAdvertRound))
						{
							CPrintToChatAll("\x01[AST]\x04 %t","advert_frags",fragSwap);
						}

						if (GetConVarBool(astPlaySound))
						{
							PlaySound(1);
						}
					}
				}

				// Encontrou situação indicativa de swap; swap deve ser realizado ao final do round
				if (swapNow)
				{
					if (GetConVarBool(astAdvertAlert))
					{
						CPrintToChatAll("\x01[AST]\x04 %t","advert_will_swap");
					}

					if (GetConVarBool(astPlaySound))
					{
						PlaySound(2);
					}
				}

			}
			else
			{
				if (swapNow)
				{
					for(new client = 1; client <= MaxClients; client++)
					{
						if(IsValidClient(client) || IsBot(client))
						{
							if (!IsAdmin(client))
							{
								new immunity[5];

								immunity = GetImmunityById(client);

								// 1 WEAPON
								// 2 DEAD
								// 3 FRAG
								// 4 CASH

								if (GetConVarBool(astResetWeapon) && (immunity[1] == 0))
								{
									ResetWeapon(client);
								}

								if (GetConVarBool(astResetDead) && (immunity[2] == 0))
								{
									ResetDead(client);
								}

								if (GetConVarBool(astResetFrag) && (immunity[3] == 0))
								{
									ResetFrag(client);
								}

								if (GetConVarBool(astResetCash) && (immunity[4] == 0))
								{
									ResetCash(client);
								}

							}
							else
							{
								if (GetConVarBool(astResetWeapon) && !GetConVarBool(astImmuneWeapon))
								{
									ResetWeapon(client);
								}

								if (GetConVarBool(astResetDead) && !GetConVarBool(astImmuneDead))
								{
									ResetDead(client);
								}

								if (GetConVarBool(astResetFrag) && !GetConVarBool(astImmuneFrag))
								{
									ResetFrag(client);
								}

								if (GetConVarBool(astResetCash) && !GetConVarBool(astImmuneCash))
								{
									ResetCash(client);
								}
							}

						}

					}

					swapNow = false;
				}

			}


		}

	}

}



public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(astEnable))
	{
		new reason;
		reason = GetEventInt(event, "reason");

		if ((reason == 15) || (reason == 16))
		{
			swapNow = false;
			isSwap = false;

			scoreSwapCT = 0;
			scoreSwapT = 0;

			nRound = 0;
		}
		else
		{
			//5 = SEM LIMITE DEFINIDO
			if (GetConVarInt(astType) == 5)
			{
				if (swapNow)
				{
					nRound = 0;

					CreateTimer(0.3,AutoSwap);
				}
				else
				{
					if (GetConVarInt(astScoreType) != 0)
					{
						new winner;
						winner = GetEventInt(event, "winner");

						if(winner == CS_TEAM_CT)
						{
							++scoreSwapCT;
						}
						else if(winner == CS_TEAM_T)
						{
							++scoreSwapT;
						}

						SetScoreTeam(CS_TEAM_CT, scoreSwapCT);
						SetScoreTeam(CS_TEAM_T, scoreSwapT);
					}

				}
			}
			else
			{
				if (!isSwap)
				{


					//3 = NR DE VITORIAS
					if (GetConVarInt(astType) == 3)
					{
						new winLimit = GetConVarInt(FindConVar("mp_winlimit"));

						if (winLimit > 0)
						{
							new winSwap;

							winSwap = winLimit / 2;

							new scoreCT = GetTeamScore(CS_TEAM_CT);
							new scoreT = GetTeamScore(CS_TEAM_T);

							if ((scoreCT == winSwap) || (scoreT == winSwap))
							{
								swapNow = true;
							}
						}
					}

					//4 = PONTUACAO
					else if (GetConVarInt(astType) == 4)
					{
						new fragLimit = GetConVarInt(FindConVar("mp_fraglimit"));

						if (fragLimit > 0)
						{
							new fragSwap = RoundFloat(fragLimit / 2.0);

							for(new client = 1; client <= MaxClients; client++)
							{
								if(IsValidClient(client) || IsBot(client))
								{
									if (GetFrag(client) >= fragSwap)
									{
										swapNow = true;
										break;
									}
								}
							}
						}
					}

					if (swapNow)
					{
						CreateTimer(0.3,AutoSwap);

						isSwap = true;
					}
				}
				else
				{
					if (GetConVarInt(astScoreType) != 0)
					{
						new winner;
						winner = GetEventInt(event, "winner");

						if(winner == CS_TEAM_CT)
						{
							++scoreSwapCT;
						}
						else if(winner == CS_TEAM_T)
						{
							++scoreSwapT;
						}

						SetScoreTeam(CS_TEAM_CT, scoreSwapCT);
						SetScoreTeam(CS_TEAM_T, scoreSwapT);
					}
				}
			}
		}
	}
}



public Action:AutoSwap(Handle:timer)
{
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client) || IsBot(client))
		{
			if (!IsAdmin(client))
			{
				new immunity[5];

				immunity = GetImmunityById(client);

				// 0 SWAP
				if (immunity[0] == 0)
				{
					SwapClient(client);
				}
			}
			else if (!GetConVarBool(astImmuneSwap))
			{
				SwapClient(client);
			}
		}
	}

	if (GetConVarInt(astScoreType) != 0)
	{
		SetScore();
	}

	if (GetConVarBool(astAdvertSwap))
	{
		CPrintToChatAll("\x01[AST]\x04 %t","advert_were_swap");
	}

	if (GetConVarBool(astPlaySound))
	{
		PlaySound(3);
	}
}



public CacheSounds()
{
	GetConVarString(astSoundFileRound, soundFileRound, sizeof(soundFileRound));
	if (GetConVarBool(astSoundRound) && !StrEqual(soundFileRound, ""))
	{
		PrepareSound(soundFileRound);
	}

	GetConVarString(astSoundFileAlert, soundFileAlert, sizeof(soundFileAlert));
	if (GetConVarBool(astSoundAlert) && !StrEqual(soundFileAlert, ""))
	{
		PrepareSound(soundFileAlert);
	}

	GetConVarString(astSoundFileSwap, soundFileSwap, sizeof(soundFileSwap));
	if (GetConVarBool(astSoundSwap) && !StrEqual(soundFileSwap, ""))
	{
		PrepareSound(soundFileSwap);
	}
}



public PrepareSound(String: sound[MAX_FILE_LEN])
{
	decl String:fileSound[MAX_FILE_LEN];

	Format(fileSound, MAX_FILE_LEN, "sound/%s", sound);

	if (FileExists(fileSound))
	{
		PrecacheSound(sound, true);
		AddFileToDownloadsTable(fileSound);
	}
	else
	{
		PrintToServer("[AST] ERROR: File sound '%s' doesn't exist!",fileSound);
	}
}




PlaySound(typeSound)
{
	// round
	if ((typeSound == 1) && GetConVarBool(astSoundRound))
	{
		if (!StrEqual(soundFileRound, ""))
		{
			EmitSoundToAll(soundFileRound);
		}
	}

	// alert
	if ((typeSound == 2) && GetConVarBool(astSoundAlert))
	{
		if (!StrEqual(soundFileAlert, ""))
		{
			EmitSoundToAll(soundFileAlert);
		}
	}

	// swap
	if ((typeSound == 3) && GetConVarBool(astSoundSwap))
	{
		if (!StrEqual(soundFileSwap, ""))
		{
			EmitSoundToAll(soundFileSwap);
		}
	}
}



SwapClient(client)
{
	new team = GetClientTeam(client);

	if(team == CS_TEAM_CT)
	{
		CS_SwitchTeam(client,CS_TEAM_T);
		SetEntityModel(client,modelT[GetRandomInt(0,3)]);
	}
	else if(team == CS_TEAM_T)
	{
		CS_SwitchTeam(client,CS_TEAM_CT);
		SetEntityModel(client,modelCT[GetRandomInt(0,3)]);
	}
}



ResetWeapon(client)
{
	new team = GetClientTeam(client);

	new weaponentity;
	new grenade;

	// SLOTS
	// 0 - PRIMARY ARMOR
	// 1 - SECUNDARY ARMOR
	// 2 - KNIFE
	// 3 - GRENADES - flashbang, hegrenade, smokegrenade 
	// 4 - C4

	for(new slotweapon = 0; slotweapon <= 3; slotweapon++)
	{
		weaponentity = GetPlayerWeaponSlot(client,slotweapon);

		if(IsValidEntity(weaponentity))
		{
			if (slotweapon != 2) 
			{
				RemovePlayerItem(client,weaponentity);

				if(slotweapon == 3)
				{
					grenade = GetPlayerWeaponSlot(client,slotweapon);

					while(IsValidEntity(grenade))
					{
						RemovePlayerItem(client,grenade);
						grenade = GetPlayerWeaponSlot(client,slotweapon);
					}
				}
			}
		}
	}


	if(team == CS_TEAM_CT)
	{
		GivePlayerItem(client,"weapon_usp");
	}
	else if(team == CS_TEAM_T)
	{
		GivePlayerItem(client,"weapon_glock");
	}
}



ResetDead(client)
{
	SetEntProp(client,Prop_Data,"m_iDeaths",0);
}



GetFrag(client)
{
    return GetEntProp(client, Prop_Data, "m_iFrags");
}



ResetFrag(client)
{
	SetEntProp(client,Prop_Data,"m_iFrags",0);
}



ResetCash(client)
{
	startMoney = GetConVarInt(FindConVar("mp_startmoney"));

	SetEntData(client,cashOffset,startMoney,4,true);
}



bool:IsAdmin(client)
{
	return CheckCommandAccess(client, "sm_ban", ADMFLAG_BAN);
}



bool:IsValidClient(client)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}



bool:IsBot(client)
{
	if (IsClientInGame(client) && IsFakeClient(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}



bool:SetScoreTeam(index, score)
{
	new edict = GetEdictTeam(index);

	if (edict == -1)
	{
		return false;
	}

	SetEntProp(edict, Prop_Send, "m_iScore", score);
	ChangeEdictState(edict, GetEntSendPropOffs(edict, "m_iScore"));

	return true;
}



EdictGetNumTeam(edict)
{
	return GetEntProp(edict, Prop_Send, "m_iTeamNum");
}



GetEdictTeam(index)
{
	new team_manager = -1;

	while ((team_manager = FindEntityByClassname(team_manager, "cs_team_manager")) != -1)
	{
		if (EdictGetNumTeam(team_manager) == index)
		{
			return team_manager;
		}
	}

	return -1;
}



SetScore()
{
	if (GetConVarInt(astScoreType) == 1)
	{
		SetScoreTeam(CS_TEAM_CT, 0);
		SetScoreTeam(CS_TEAM_T, 0);

		scoreSwapCT = 0;
		scoreSwapT = 0;
	}
	else if(GetConVarInt(astScoreType) == 2)
	{
		new scoreCT = GetTeamScore(CS_TEAM_CT);
		new scoreT = GetTeamScore(CS_TEAM_T);

		SetScoreTeam(CS_TEAM_CT, scoreT);
		SetScoreTeam(CS_TEAM_T, scoreCT);

		scoreSwapCT = scoreT;
		scoreSwapT = scoreCT;
	}
}






//---------------------------------------------------

ConnectDB()
{
	new String:error[255];

	DB_AST = SQLite_UseDatabase("auto_swap_team", error, sizeof(error));

	if (DB_AST == INVALID_HANDLE)
	{
		SetFailState("SQL error: %s", error);
	}

	SQL_LockDatabase(DB_AST);

	SQL_FastQuery(DB_AST, "CREATE TABLE IF NOT EXISTS players_immune (steamId TEXT, swap NUMERIC, weapon NUMERIC, dead NUMERIC, frag NUMERIC, cash NUMERIC)");
	SQL_FastQuery(DB_AST, "CREATE UNIQUE INDEX IF NOT EXISTS pk_steamId ON players_immune(steamId ASC)");

	SQL_UnlockDatabase(DB_AST);
}



public Action:ImmunityAdd(client, args) 
{
	if (args < 2)
	{
		ReplyToCommand(client, "[AST] Usage: sm_autoswapteam_immunity_add <steamId> <immunity>");
		return Plugin_Handled;
	}

	decl String:params[54];
	GetCmdArgString(params, sizeof(params));

	decl String:steamId[50];
	decl String:argImmunity[3];

	new len = BreakString(params, steamId, sizeof(steamId));
	BreakString(params[len], argImmunity, sizeof(argImmunity));

	if (strncmp(steamId, "STEAM_", 6) != 0 || steamId[7] != ':')
	{
		ReplyToCommand(client, "[AST] %t", "invalid_steamid");
		return Plugin_Handled;
	}

	new immunity;
	immunity = StringToInt(argImmunity);

	if (immunity == 0)
	{
		ReplyToCommand(client, "[AST] %t", "invalid_immunity");
		return Plugin_Handled;
	}

	new swap = 0;
	new weapon = 0;
	new dead = 0;
	new frag = 0;
	new cash = 0;

	new codImmunity;

	// SWAP
	codImmunity = 16;
	if ((immunity - codImmunity) >= 0)
	{
		immunity = immunity - codImmunity;
		swap = 1;
	}

	// WEAPON
	codImmunity = 8;
	if ((immunity - codImmunity) >= 0)
	{
		immunity = immunity - codImmunity;
		weapon = 1;
	}

	// DEAD
	codImmunity = 4;
	if ((immunity - codImmunity) >= 0)
	{
		immunity = immunity - codImmunity;
		dead = 1;
	}

	// FRAG
	codImmunity = 2;
	if ((immunity - codImmunity) >= 0)
	{
		immunity = immunity - codImmunity;
		frag = 1;
	}

	// CASH
	codImmunity = 1;
	if ((immunity - codImmunity) >= 0)
	{
		immunity = immunity - codImmunity;
		cash = 1;
	}

	decl String:query[200];

	Format(query, sizeof(query), "INSERT INTO players_immune(steamId, swap, weapon, dead, frag, cash) VALUES ('%s', %d, %d, %d, %d, %d);", steamId, swap, weapon, dead, frag, cash);

	if (SQL_FastQuery(DB_AST, query))
	{
		ReplyToCommand(client, "[AST] %t", "immunity_add_success");
	}
	else
	{
		ReplyToCommand(client, "[AST] %t", "immunity_add_error");
	}

	return Plugin_Handled;
} 



public Action:ImmunityRemove(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[AST] Usage: sm_autoswapteam_immunity_del <steamId>");
		return Plugin_Handled;
	}

	decl String:params[54];
	GetCmdArgString(params, sizeof(params));

	decl String:steamId[50];
	BreakString(params, steamId, sizeof(steamId));

	decl String:query[200];
	Format(query, sizeof(query), "DELETE FROM players_immune WHERE steamId = '%s';", steamId);

	if (SQL_FastQuery(DB_AST, query))
	{
		ReplyToCommand(client, "[AST] %t", "immunity_del_success");
	}
	else
	{
		ReplyToCommand(client, "[AST] %t", "immunity_del_error");
	}

	return Plugin_Handled;
}



GetImmunityById(client)
{
	new immunity[5];

	immunity[0] = 0; // SWAP
	immunity[1] = 0; // WEAPON
	immunity[2] = 0; // DEAD
	immunity[3] = 0; // FRAG
	immunity[4] = 0; // CASH

	if(IsValidClient(client))
	{
		decl String:steamId[50];
		GetClientAuthId(client, AuthId_Steam2 ,steamId, sizeof(steamId));

		new String:query[200];
		Format(query, sizeof(query), "SELECT swap,weapon,dead,frag,cash FROM players_immune WHERE steamId = '%s'", steamId);
	 
		new Handle:hQuery = SQL_Query(DB_AST, query);

		if ((hQuery != INVALID_HANDLE) && SQL_FetchRow(hQuery))
		{
			immunity[0] = SQL_FetchInt(hQuery,0);
			immunity[1] = SQL_FetchInt(hQuery,1);
			immunity[2] = SQL_FetchInt(hQuery,2);
			immunity[3] = SQL_FetchInt(hQuery,3);
			immunity[4] = SQL_FetchInt(hQuery,4);
		}

		CloseHandle(hQuery);
	}

	return immunity;
}



public Action:ImmunityList(client, args)
{
	new String:query[200];

	if (args < 1)
	{
		Format(query, sizeof(query), "SELECT steamId, swap, weapon, dead, frag, cash FROM players_immune");
	}
	else
	{
		decl String:params[54];
		GetCmdArgString(params, sizeof(params));

		decl String:steamId[50];
		BreakString(params, steamId, sizeof(steamId));

		Format(query, sizeof(query), "SELECT steamId, swap, weapon, dead, frag, cash FROM players_immune WHERE steamId = '%s'", steamId);
	}

	new Handle:hQuery = SQL_Query(DB_AST, query);

	if (hQuery != INVALID_HANDLE)
	{

		ReplyToCommand(client, "[AST] STEAM_ID / SWAP / WEAPON / DEAD / FRAG / CASH");
		ReplyToCommand(client, "-----------------------------------------------------");

		while (SQL_FetchRow(hQuery))
		{
			decl String:steam[50];
			SQL_FetchString(hQuery, 0, steam, sizeof(steam));

			new immunity[5];

			immunity[0] = SQL_FetchInt(hQuery,1); // SWAP
			immunity[1] = SQL_FetchInt(hQuery,2); // WEAPON
			immunity[2] = SQL_FetchInt(hQuery,3); // DEAD
			immunity[3] = SQL_FetchInt(hQuery,4); // FRAG
			immunity[4] = SQL_FetchInt(hQuery,5); // CASH

			ReplyToCommand(client, "[AST] %s / %d / %d / %d / %d / %d", steam, immunity[0], immunity[1], immunity[2], immunity[3], immunity[4]);
		}

		ReplyToCommand(client, "-----------------------------------------------------");
	}

	CloseHandle(hQuery);

	return Plugin_Handled;
}