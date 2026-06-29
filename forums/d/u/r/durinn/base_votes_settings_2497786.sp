public Plugin:myinfo =
{
	name = "Base votes settings",
	author = "Pheonix (˙·٠●Феникс●٠·˙)",
	version = "1.0",
	url = "http://zizt.ru/ http://hlmod.ru/"
}

new bool:bl;
new bool:q_,
	bool:w_,
	bool:e_,
	bool:r_,
	bool:t_,
	bool:y_;
	
new	q_f,
	w_f,
	e_f,
	r_f,
	t_f,
	y_f;
	
new Handle:q_h,
	Handle:w_h,
	Handle:e_h,
	Handle:r_h,
	Handle:t_h,
	Handle:y_h;

public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("VoteStart"), VoteStart, true);
	HookUserMessage(GetUserMessageId("VoteFailed"), VoteFailed, true);
	bl = false;
	q_h = CreateConVar("sm_standart_vote_kick", "1", "Кик игрокаn\n0 отключить\n1 включить без ограничения по флагу\nz флаг по котором доступно голосование");
	w_h = CreateConVar("sm_standart_vote_map", "1", "Сменить карту\n0 отключить\n1 включить без ограничения по флагу\nz флаг по котором доступно голосование");
	e_h = CreateConVar("sm_standart_vote_nextmap", "1", "Следующая карта\n0 отключить\n1 включить без ограничения по флагу\nz флаг по котором доступно голосование");
	r_h = CreateConVar("sm_standart_vote_change_places", "1", "Сменить команды местами\n0 отключить\n1 включить без ограничения по флагу\nz флаг по котором доступно голосование");
	t_h = CreateConVar("sm_standart_vote_mix_team", "1", "Перемешать команды\n0 отключить\n1 включить без ограничения по флагу\nz флаг по котором доступно голосование");
	y_h = CreateConVar("sm_standart_vote_restart_game", "1", "Рестарт игры\n0 отключить\n1 включить без ограничения по флагу\nz флаг по котором доступно голосование");
	HookConVarChange(q_h, ConVarChanges);
	HookConVarChange(w_h, ConVarChanges);
	HookConVarChange(e_h, ConVarChanges);
	HookConVarChange(r_h, ConVarChanges);
	HookConVarChange(t_h, ConVarChanges);
	HookConVarChange(y_h, ConVarChanges);
	AutoExecConfig(true, "sm_base_votes_settings");
}

public ConVarChanges(Handle:convar, const String:oldVal[], const String:newVal[]) 
{
	decl String:u[1];
	if(convar == q_h)
	{
		if(IsCharNumeric(newVal[0]))
		{
			q_ = StringToInt(newVal) ? true:false;
			q_f = 0;
		}
		else
		{
			q_ = true;
			u[0] = CharToLower(newVal[0]);
			q_f = ReadFlagString(u);
		}
	}
	else if(convar == w_h)
	{
		if(IsCharNumeric(newVal[0]))
		{
			w_ = StringToInt(newVal) ? true:false;
			w_f = 0;
		}
		else
		{
			w_ = true;
			u[0] = CharToLower(newVal[0]);
			w_f = ReadFlagString(u);
		}
	}
	else if(convar == e_h)
	{
		if(IsCharNumeric(newVal[0]))
		{
			e_ = StringToInt(newVal) ? true:false;
			e_f = 0;
		}
		else
		{
			e_ = true;
			u[0] = CharToLower(newVal[0]);
			e_f = ReadFlagString(u);
		}
	}
	else if(convar == r_h)
	{
		if(IsCharNumeric(newVal[0]))
		{
			r_ = StringToInt(newVal) ? true:false;
			r_f = 0;
		}
		else
		{
			r_ = true;
			u[0] = CharToLower(newVal[0]);
			r_f = ReadFlagString(u);
		}
	}
	else if(convar == t_h)
	{
		if(IsCharNumeric(newVal[0]))
		{
			t_ = StringToInt(newVal) ? true:false;
			t_f = 0;
		}
		else
		{
			t_ = true;
			u[0] = CharToLower(newVal[0]);
			t_f = ReadFlagString(u);
		}
	}
	else if(convar == y_h)
	{
		if(IsCharNumeric(newVal[0]))
		{
			y_ = StringToInt(newVal) ? true:false;
			y_f = 0;
		}
		else
		{
			y_ = true;
			u[0] = CharToLower(newVal[0]);
			y_f = ReadFlagString(u);
		}
	}
}

public Action:VoteStart(UserMsg:msg_id, Handle:Pb, const clients[], numClients, bool:reliable, bool:init)
{
	new iClient = PbReadInt(Pb, "ent_idx");
	if(0 < iClient <= MaxClients)
	{
		switch(PbReadInt(Pb, "vote_type"))
		{
			case 0:
			{
				if(q_)
				{
					if(q_f && !(GetUserFlagBits(iClient) & q_f))
					{
						CreateTimer(0.1, Failed, iClient);
						bl = true;
						return Plugin_Handled;
					}
					else
					{
						decl String:str[128], String:name[128];
						PbReadString(Pb, "details_str", str, 128);
						for (new u = 1; u <= MaxClients; u++)
						{
							if(iClient != u && IsClientInGame(u) && !IsFakeClient(u))
							{
								GetClientName(u, name, 128);
								if(StrEqual(name, str)) 
								{
									if(GetAdminImmunityLevel(GetUserAdmin(iClient)) < GetAdminImmunityLevel(GetUserAdmin(u)))
									{
										CreateTimer(0.1, Failed, iClient);
										bl = true;
										return Plugin_Handled;
									}
								}
							}
						}	
					}
				}
				else 
				{
					CreateTimer(0.1, Failed, iClient);
					bl = true;
					return Plugin_Handled;
				}
				return Plugin_Continue;
			}
			case 1:
			{
				if(w_)
				{
					if(w_f && !(GetUserFlagBits(iClient) & w_f))
					{
						CreateTimer(0.1, Failed, iClient);
						bl = true;
						return Plugin_Handled;
					}
					return Plugin_Continue;
				}
				else 
				{
					CreateTimer(0.1, Failed, iClient);
					bl = true;
					return Plugin_Handled;
				}
			}
			case 2:
			{
				if(e_)
				{
					if(e_f && !(GetUserFlagBits(iClient) & e_f))
					{
						CreateTimer(0.1, Failed, iClient);
						bl = true;
						return Plugin_Handled;
					}
					return Plugin_Continue;
				}
				else 
				{
					CreateTimer(0.1, Failed, iClient);
					bl = true;
					return Plugin_Handled;
				}
			}
			case 3:
			{
				if(r_)
				{
					if(r_f && !(GetUserFlagBits(iClient) & r_f))
					{
						CreateTimer(0.1, Failed, iClient);
						bl = true;
						return Plugin_Handled;
					}
					return Plugin_Continue;
				}
				else 
				{
					CreateTimer(0.1, Failed, iClient);
					bl = true;
					return Plugin_Handled;
				}
			}
			case 4:
			{
				if(t_)
				{
					if(t_f && !(GetUserFlagBits(iClient) & t_f))
					{
						CreateTimer(0.1, Failed, iClient);
						bl = true;
						return Plugin_Handled;
					}
					return Plugin_Continue;
				}
				else 
				{
					CreateTimer(0.1, Failed, iClient);
					bl = true;
					return Plugin_Handled;
				}
			}
			case 5:
			{
				if(y_)
				{
					if(y_f && !(GetUserFlagBits(iClient) & y_f))
					{
						CreateTimer(0.1, Failed, iClient);
						bl = true;
						return Plugin_Handled;
					}
					return Plugin_Continue;
				}
				else 
				{
					CreateTimer(0.1, Failed, iClient);
					bl = true;
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:VoteFailed(UserMsg:msg_id, Handle:Pb, const clients[], numClients, bool:reliable, bool:init)
{
	if(bl && PbReadInt(Pb, "reason") == 4) 
	{
		bl = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Failed(Handle:Timer, any:iClient)
{
	new Handle:F = StartMessageOne("CallVoteFailed", iClient, USERMSG_RELIABLE);
	PbSetInt(F, "reason", 0);
	EndMessage();
}