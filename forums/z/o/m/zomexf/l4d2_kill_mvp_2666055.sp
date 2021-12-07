public PlVers:__version =
{
	version = 5,
	filevers = "1.8.0.6016",
	date = "08/03/2017",
	time = "13:18:05"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
new killif[66];
new killifs[66];
new damageff[66];
new pdamageff[66];
new Handle:hCountMvpDelay;
new Float:CountMvpDelay;
new IF;
public Plugin:myinfo =
{
	name = "特感击杀排名",
	description = "特感击杀排名-by望夜",
	author = "fenghf",
	version = "1.0.0",
	url = ""
};
public void:__ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	MarkNativeAsOptional("BfWriteBool");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteChar");
	MarkNativeAsOptional("BfWriteShort");
	MarkNativeAsOptional("BfWriteWord");
	MarkNativeAsOptional("BfWriteNum");
	MarkNativeAsOptional("BfWriteFloat");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("BfWriteEntity");
	MarkNativeAsOptional("BfWriteAngle");
	MarkNativeAsOptional("BfWriteCoord");
	MarkNativeAsOptional("BfWriteVecCoord");
	MarkNativeAsOptional("BfWriteVecNormal");
	MarkNativeAsOptional("BfWriteAngles");
	MarkNativeAsOptional("BfReadBool");
	MarkNativeAsOptional("BfReadByte");
	MarkNativeAsOptional("BfReadChar");
	MarkNativeAsOptional("BfReadShort");
	MarkNativeAsOptional("BfReadWord");
	MarkNativeAsOptional("BfReadNum");
	MarkNativeAsOptional("BfReadFloat");
	MarkNativeAsOptional("BfReadString");
	MarkNativeAsOptional("BfReadEntity");
	MarkNativeAsOptional("BfReadAngle");
	MarkNativeAsOptional("BfReadCoord");
	MarkNativeAsOptional("BfReadVecCoord");
	MarkNativeAsOptional("BfReadVecNormal");
	MarkNativeAsOptional("BfReadAngles");
	MarkNativeAsOptional("BfGetNumBytesLeft");
	MarkNativeAsOptional("BfWrite.WriteBool");
	MarkNativeAsOptional("BfWrite.WriteByte");
	MarkNativeAsOptional("BfWrite.WriteChar");
	MarkNativeAsOptional("BfWrite.WriteShort");
	MarkNativeAsOptional("BfWrite.WriteWord");
	MarkNativeAsOptional("BfWrite.WriteNum");
	MarkNativeAsOptional("BfWrite.WriteFloat");
	MarkNativeAsOptional("BfWrite.WriteString");
	MarkNativeAsOptional("BfWrite.WriteEntity");
	MarkNativeAsOptional("BfWrite.WriteAngle");
	MarkNativeAsOptional("BfWrite.WriteCoord");
	MarkNativeAsOptional("BfWrite.WriteVecCoord");
	MarkNativeAsOptional("BfWrite.WriteVecNormal");
	MarkNativeAsOptional("BfWrite.WriteAngles");
	MarkNativeAsOptional("BfRead.ReadBool");
	MarkNativeAsOptional("BfRead.ReadByte");
	MarkNativeAsOptional("BfRead.ReadChar");
	MarkNativeAsOptional("BfRead.ReadShort");
	MarkNativeAsOptional("BfRead.ReadWord");
	MarkNativeAsOptional("BfRead.ReadNum");
	MarkNativeAsOptional("BfRead.ReadFloat");
	MarkNativeAsOptional("BfRead.ReadString");
	MarkNativeAsOptional("BfRead.ReadEntity");
	MarkNativeAsOptional("BfRead.ReadAngle");
	MarkNativeAsOptional("BfRead.ReadCoord");
	MarkNativeAsOptional("BfRead.ReadVecCoord");
	MarkNativeAsOptional("BfRead.ReadVecNormal");
	MarkNativeAsOptional("BfRead.ReadAngles");
	MarkNativeAsOptional("BfRead.GetNumBytesLeft");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetFloat");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbSetColor");
	MarkNativeAsOptional("PbSetAngle");
	MarkNativeAsOptional("PbSetVector");
	MarkNativeAsOptional("PbSetVector2D");
	MarkNativeAsOptional("PbAddInt");
	MarkNativeAsOptional("PbAddFloat");
	MarkNativeAsOptional("PbAddBool");
	MarkNativeAsOptional("PbAddString");
	MarkNativeAsOptional("PbAddColor");
	MarkNativeAsOptional("PbAddAngle");
	MarkNativeAsOptional("PbAddVector");
	MarkNativeAsOptional("PbAddVector2D");
	MarkNativeAsOptional("PbRemoveRepeatedFieldValue");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	MarkNativeAsOptional("Protobuf.ReadInt");
	MarkNativeAsOptional("Protobuf.ReadFloat");
	MarkNativeAsOptional("Protobuf.ReadBool");
	MarkNativeAsOptional("Protobuf.ReadString");
	MarkNativeAsOptional("Protobuf.ReadColor");
	MarkNativeAsOptional("Protobuf.ReadAngle");
	MarkNativeAsOptional("Protobuf.ReadVector");
	MarkNativeAsOptional("Protobuf.ReadVector2D");
	MarkNativeAsOptional("Protobuf.GetRepeatedFieldCount");
	MarkNativeAsOptional("Protobuf.SetInt");
	MarkNativeAsOptional("Protobuf.SetFloat");
	MarkNativeAsOptional("Protobuf.SetBool");
	MarkNativeAsOptional("Protobuf.SetString");
	MarkNativeAsOptional("Protobuf.SetColor");
	MarkNativeAsOptional("Protobuf.SetAngle");
	MarkNativeAsOptional("Protobuf.SetVector");
	MarkNativeAsOptional("Protobuf.SetVector2D");
	MarkNativeAsOptional("Protobuf.AddInt");
	MarkNativeAsOptional("Protobuf.AddFloat");
	MarkNativeAsOptional("Protobuf.AddBool");
	MarkNativeAsOptional("Protobuf.AddString");
	MarkNativeAsOptional("Protobuf.AddColor");
	MarkNativeAsOptional("Protobuf.AddAngle");
	MarkNativeAsOptional("Protobuf.AddVector");
	MarkNativeAsOptional("Protobuf.AddVector2D");
	MarkNativeAsOptional("Protobuf.RemoveRepeatedFieldValue");
	MarkNativeAsOptional("Protobuf.ReadMessage");
	MarkNativeAsOptional("Protobuf.ReadRepeatedMessage");
	MarkNativeAsOptional("Protobuf.AddMessage");
	VerifyCoreVersion();
	return void:0;
}

void:PrintToChatAll(String:format[])
{
	new String:buffer[256];
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 254, format, 2);
			PrintToChat(i, "%s", buffer);
		}
		i++;
	}
	return void:0;
}

public void:OnPluginStart()
{
	RegConsoleCmd("sm_mvp", Command_kill, "", 0);
	HookEvent("player_death", MVPEvent_kill_infected, EventHookMode:1);
	HookEvent("player_hurt", MVPEvent_PlayerHurt, EventHookMode:1);
	HookEvent("infected_death", MVPEvent_kill_SS, EventHookMode:1);
	HookEvent("map_transition", MVPEvent_MapTransition, EventHookMode:2);
	HookEvent("round_end", MVPEvent_MapTransition, EventHookMode:2);
	HookEvent("round_start", MVPEvent_RoundStart, EventHookMode:2);
	CreateConVar("L4D2_kill_mvp_Version", "L4D2特感击杀排名v1.1-by望夜", "L4D2特感击杀排名v1.1-by望夜", 8512, false, 0.0, false, 0.0);
	hCountMvpDelay = CreateConVar("kill_mvp_display_delay", "120", "击杀排名多久显示一次(秒).", 0, true, 10.0, true, 9999.0);
	CountMvpDelay = GetConVarFloat(hCountMvpDelay);
	HookConVarChange(hCountMvpDelay, ConVarMvpDelays);
	AutoExecConfig(true, "l4d2_kill_mvp", "sourcemod");
	IF = FindSendPropInfo("CTerrorPlayer", "m_zombieClass", 0, 0, 0);
	return void:0;
}

public ConVarMvpDelays(Handle:convar, String:oldValue[], String:newValue[])
{
	CountMvpDelay = GetConVarFloat(hCountMvpDelay);
	return 0;
}

public void:OnMapStart()
{
	CountMvpDelay = GetConVarFloat(hCountMvpDelay);
	kill_infected();
	CreateTimer(CountMvpDelay, killinfected_dis, any:0, 3);
	return void:0;
}

public MVPEvent_PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid", 0);
	new victim = GetClientOfUserId(victimId);
	new attackerId = GetEventInt(event, "attacker", 0);
	new attackersid = GetClientOfUserId(attackerId);
	new damageDone = GetEventInt(event, "dmg_health", 0);
	new var1;
	if (IsClientAndInGame(attackersid) && IsClientAndInGame(victim) && GetClientTeam(attackersid) == 2 && GetClientTeam(victim) == 2)
	{
		new var2 = damageff[attackersid];
		var2 = var2[damageDone];
		new var3 = pdamageff[victim];
		var3 = var3[damageDone];
	}
	return 0;
}

bool:IsClientAndInGame(index)
{
	new var1;
	return index > 0 && index <= MaxClients && IsClientInGame(index);
}

public Action:MVPEvent_kill_SS(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker", 0));
	if (!killer)
	{
		return Action:0;
	}
	if (GetClientTeam(killer) == 2)
	{
		killifs[killer] += 1;
	}
	return Action:0;
}

public Action:MVPEvent_kill_infected(Handle:event, String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker", 0));
	new deadbody = GetClientOfUserId(GetEventInt(event, "userid", 0));
	new var1;
	if (0 < killer <= MaxClients && deadbody)
	{
		new ZClass = GetEntData(deadbody, IF, 4);
		if (GetClientTeam(killer) == 2)
		{
			new var2;
			if (ZClass == 1 || ZClass == 2 || ZClass == 3 || ZClass == 4 || ZClass == 5 || ZClass == 6)
			{
				killif[killer] += 1;
			}
			if (IsPlayerTank(deadbody))
			{
				killif[killer] += 1;
			}
		}
	}
	return Action:0;
}

bool:IsPlayerTank(client)
{
	if (GetEntProp(client, PropType:0, "m_zombieClass", 4, 0) == 8)
	{
		return true;
	}
	return false;
}

public MVPEvent_MapTransition(Handle:event, String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, killinfected_dis, any:0, 0);
	return 0;
}

public Action:killinfected_dis(Handle:timer)
{
	displaykillinfected();
	return Action:0;
}

public MVPEvent_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	kill_infected();
	return 0;
}

public Action:Command_kill(client, args)
{
	displaykillinfected();
	return Action:0;
}

displaykillinfected()
{
	new client;
	new players = -1;
	new players_clients[24];
	decl killss;
	decl killsss;
	decl damageffss;
	decl pdamageffss;
	client = 1;
	while (client <= MaxClients)
	{
		new var1;
		if (!IsClientInGame(client) || GetClientTeam(client) == 2)
		{
		}
		else
		{
			players++;
			players_clients[players] = client;
			killss = killif[client];
			killsss = killifs[client];
			damageffss = damageff[client];
			pdamageffss = pdamageff[client];
		}
		client++;
	}
	PrintToChatAll("\x04[MVP]\x03 击杀排名-by望夜");
	SortCustom1D(players_clients, 24, SortByDamageDesc, Handle:0);
	new i;
	while (i <= 3)
	{
		client = players_clients[i];
		killss = killif[client];
		killsss = killifs[client];
		damageffss = damageff[client];
		PrintToChatAll("\x01%d: \x04%3d  \x03特感,\x04%4d  \x03丧尸,\x04%5d  \x03友伤; \x05%N", i + 1, killss, killsss, damageffss, client);
		i++;
	}
	SortCustom1D(players_clients, 24, SortByPffDamageDesc, Handle:0);
	pdamageffss = pdamageff[players_clients[0]];
	PrintToChatAll("\x01<囧-被黑王-囧> \x03被黑 \x04%d  \x05%N", pdamageffss, players_clients);
	SortCustom1D(players_clients, 24, SortByffDamageDesc, Handle:0);
	damageffss = damageff[players_clients[0]];
	PrintToChatAll("\x01<凸-黑枪王-凸> \x03友伤 \x04%d  \x05%N", damageffss, players_clients);
	return 0;
}

public SortByDamageDesc(elem1, elem2, array[], Handle:hndl)
{
	if (killif[elem2] < killif[elem1])
	{
		return -1;
	}
	if (killif[elem1] < killif[elem2])
	{
		return 1;
	}
	if (elem1 > elem2)
	{
		return -1;
	}
	if (elem2 > elem1)
	{
		return 1;
	}
	return 0;
}

public SortByffDamageDesc(elem1, elem2, array[], Handle:hndl)
{
	if (damageff[elem2] < damageff[elem1])
	{
		return -1;
	}
	if (damageff[elem1] < damageff[elem2])
	{
		return 1;
	}
	if (elem1 > elem2)
	{
		return -1;
	}
	if (elem2 > elem1)
	{
		return 1;
	}
	return 0;
}

public SortByPffDamageDesc(elem1, elem2, array[], Handle:hndl)
{
	if (pdamageff[elem2] < pdamageff[elem1])
	{
		return -1;
	}
	if (pdamageff[elem1] < pdamageff[elem2])
	{
		return 1;
	}
	if (elem1 > elem2)
	{
		return -1;
	}
	if (elem2 > elem1)
	{
		return 1;
	}
	return 0;
}

kill_infected()
{
	new i = 1;
	while (i <= MaxClients)
	{
		killif[i] = 0;
		killifs[i] = 0;
		damageff[i] = 0;
		pdamageff[i] = 0;
		i++;
	}
	return 0;
}