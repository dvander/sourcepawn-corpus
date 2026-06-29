/*
**  sort out : JOYIST
**  web: http://chdong.top/
**  date: 2018-04-18
Increase the English translation of .sp
*/

 PlVers __version = 5;
 float NULL_VECTOR[3];
 char NULL_STRING[1];
 Extension __ext_core = 68;
 int MaxClients;
 Extension __ext_sdktools = 2224;
 Handle hUsermnums;
 int usermnums;
 Handle hAwayCEnable;
 int AwayCEnable;
 bool RJoincheck;
 bool RCNcheck;
 Handle hRJoincheck;
 bool RAutoBotcheck;
 Handle hAutoBotcheck;
 bool Rmc_ChangeTeam[66];
public Plugin myinfo =
{
	name = "L4D2 Multiplayer RMC",
	description = "L4D2 Multiplayer Commands (!jg, !joingame, !away, !addbot, !sinfo, !sp, !zs, !bd, !rhelp, !kb, !sset)",
	author = "Ryanx，joyist",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?t=306873"
};
public void __ext_core_SetNTVOptional()
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
	return void 0;
}

public void PrintToChatAll(char format[])
{
	char buffer[256];
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 254, format, 2);
			PrintToChat(i, "%s", buffer);
			i++;
		}
		i++;
	}
	return void 0;
}

public void OnPluginStart()
{
	CreateConVar("L4D2_Multiplayer_RMC_version", "1.1", "L4D2 Multiplayer Game Settings", 8512, false, 0, false, 0);
	RegConsoleCmd("sm_jg", Jointhegame, "Join the game", 0);
	RegConsoleCmd("sm_joingame", Jointhegame, "Join the game", 0);
	RegConsoleCmd("sm_away", Gotoaway, "Join the observer", 0);
	RegConsoleCmd("sm_addbot", CreateOneBot, "Add a bot", 0);
	RegConsoleCmd("sm_sinfo", Vserverinfo, "Display server number information", 0);
	RegConsoleCmd("sm_bd", Bindkeyhots, "Bind keyboard L key automatically enter joingame", 0);
	RegConsoleCmd("sm_rhelp", Scdescription, "Plugin description", 0);
	RegAdminCmd("kb", Kbcheck, 2, "", "Kick all bots", 0);
	RegConsoleCmd("sm_sp", RListLoadplayer, "Displaying the list of players that are still loading", 0);
	RegConsoleCmd("sm_zs", Rzhisha, "Suicide command", 0);
	RegAdminCmd("sset", Numsetcheck, 2, "", "Set the number of servers", 0);
	HookEvent("round_start", EventHook 25, EventHookMode 2);
	HookEvent("player_team", EventHook 27, EventHookMode 1);
	hUsermnums = CreateConVar("L4D2_Rmc_total", "16", "Server support player number setting", 0, true, 1, true, 24);
	usermnums = GetConVarInt(hUsermnums);
	hRJoincheck = CreateConVar("l4d2_ADM_CHA", "0", "[0=OFF|1=ON] Whether to open 2 administrator reserved channels", 0, true, 0, true, 1);
	RJoincheck = GetConVarBool(hRJoincheck);
	hAwayCEnable = CreateConVar("L4D2_Away_Enable", "0", "[0=Off|1=On] Whether to allow the administrator to use only!Away to join the observer. 1=On, 0=Off", 0, true, 0, true, 1);
	AwayCEnable = GetConVarBool(hAwayCEnable);
	hAutoBotcheck = CreateConVar("l4d2_AUOT_ADDBOT", "1", "[0=OFF|1=ON] Whether to enable automatic increase of BOT", 0, true, 0, true, 1);
	RAutoBotcheck = GetConVarBool(hAutoBotcheck);
	RCNcheck = 0;
	AutoExecConfig(true, "l4d2_rmc", "sourcemod");
	return void 0;
}

public void OnMapStart()
{
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 999999, false, false);
	RJoincheck = GetConVarBool(hRJoincheck);
	AwayCEnable = GetConVarBool(hAwayCEnable);
	RAutoBotcheck = GetConVarBool(hAutoBotcheck);
	if (!RCNcheck)
	{
		usermnums = GetConVarInt(hUsermnums);
		if (usermnums < 1)
		{
			usermnums = 1;
		}
	}
	return void 0;
}

public Action Event_rmcRoundStart(Handle event, char name[], bool dontBroadcast)
{
	CreateTimer(1, rmcRepDelays, any 0, 0);
	return Action 0;
}

public Action JgHintplayers16(Handle timer, any client)
{
	if (0 < Botnums())
	{
		if (0 < Alivebotnums())
		{
			ClientCommand(client, "jointeam 2");
			ClientCommand(client, "go_away_from_keyboard");
			return Action 3;
		}
		PrintToChat(client, "\x05[Failed to join:]\x04Please wait for the BOT to be rescued and enter !jg to enter.");
		return Action 3;
	}
	PrintToChat(client, "\x05[Failed to join:]\x04Not enough BOT allows you to control, please enter !addbot to increase the computer. ");
	return Action 3;
}

public void OnClientDisconnect(int client)
{
	int var1;
	if (client)
	{
		Rmc_ChangeTeam[client] = 0;
		CreateTimer(1, DisKickClient, any 0, 0);
	}
	return void 0;
}

public Action DisKickClient(Handle timer)
{
	char asnus[4];
	char aynus[4];
	char abnus[4];
	int asnus1 = 0;
	int aynus1 = 0;
	int abnus1 = 0;
	Format(asnus, 3, "%i", Survivors());
	Format(aynus, 3, "%i", Gonaways());
	Format(abnus, 3, "%i", Botnums());
	asnus1 = StringToInt(asnus, 10);
	aynus1 = StringToInt(aynus, 10);
	abnus1 = StringToInt(abnus, 10);
	if (abnus1 > aynus1)
	{
		if (asnus1 > 4)
		{
			int i = 1;
			while (i <= MaxClients)
			{
				int var1;
				if (IsClientInGame(i))
				{
					KickClient(i, "");
				}
				i++;
			}
		}
	}
	return Action 0;
}

public Action rmcRepDelays(Handle timer)
{
	if (usermnums < 1)
	{
		usermnums = 1;
	}
	if (RJoincheck)
	{
		ServerCommand("sm_cvar sv_maxplayers %i", usermnums + 2);
		ServerCommand("sm_cvar sv_visiblemaxplayers %i", usermnums);
		PrintToChatAll("\x04[Tip] \x03Public location\x01[%i] \x03Administrator reserved\x01[2]", 2272);
	}
	else
	{
		ServerCommand("sm_cvar sv_maxplayers %i", usermnums);
		ServerCommand("sm_cvar sv_visiblemaxplayers %i", usermnums);
	}
	return Action 0;
}

public bool OnClientConnect(int client, char rejectmsg[], int maxlen)
{
	if (RJoincheck)
	{
		int Rnmax = GetConVarInt(FindConVar("sv_maxplayers"));
		int asnus1 = Allplayersn();
		if (Rnmax + -2 <= asnus1)
		{
			int var1;
			if (client)
			{
				KickClient(client, "The server is full, you are not an administrator can not enter the reserved channel!");
			}
			Rmc_ChangeTeam[client] = 0;
			return true;
		}
		Rmc_ChangeTeam[client] = 0;
		return true;
	}
	Rmc_ChangeTeam[client] = 0;
	return true;
}

public Action Kbcheck(int client, int args)
{
	if (GetUserFlagBits(client))
	{
		int ix = 1;
		while (ix <= MaxClients)
		{
			int var1;
			if (IsClientInGame(ix))
			{
				KickClient(ix, "");
				ix++;
			}
			ix++;
		}
		PrintToChatAll("\x05[Tip]\x03 Kick all bots.");
		return Action 0;
	}
	ReplyToCommand(client, "[Tip] This feature is for administrators only.");
	return Action 0;
}

public Action Numsetcheck(int client, int args)
{
	if (GetUserFlagBits(client))
	{
		rDisplaySnumMenu(client);
		return Action 0;
	}
	ReplyToCommand(client, "[Tip] This feature is for administrators only.");
	return Action 0;
}

public int rDisplaySnumMenu(int client)
{
	char namelist[64];
	char nameno[4];
	Handle menu = CreateMenu(MenuHandler 61, MenuAction 28);
	SetMenuTitle(menu, "Server number setting");
	int i = 1;
	while (i <= 24)
	{
		Format(nameno, 3, "%i", i);
		AddMenuItem(menu, nameno, namelist, 0);
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public int rNumMenuHandler(Handle menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction 4)
	{
		char clientinfos[12];
		int userids = 0;
		GetMenuItem(menu, itemNum, clientinfos, 10, 0, "", 0);
		userids = StringToInt(clientinfos, 10);
		usermnums = userids;
		RCNcheck = 1;
		PrintToChat(client, "\x05[remind:]\x04 The default number please modify l4d2_rmc.cfg");
		CreateTimer(0.1, rmcRepDelays, any 0, 0);
	}
	return 0;
}

public Action Scdescription(int client, int args)
{
	PrintToChatAll("\x05[Plugin description]\x03 !jg\x04 or \x03!joingame\x04 Join the game, \x03!away\x04 Spectator mode, \x03!addbot\x04 Add a BOT,");
	PrintToChatAll("\x05[Plugin description]\x03 !sinfo\x04 Display server number information, \x03!rhelp\x04 Display plug-in instructions, \x03!bd\x04 Bind keyboard L key automatically enter joingame");
	PrintToChatAll("\x05[Plugin description]\x03 !sp\x04 Displaying the list of players that are still loading, \x03!zs\x04 Commit suicide");
	PrintToChatAll("\x05[Plugin description]\x03 !kb\x04 Kick all bots, \x03!sset\x04 Set the number of servers \x03");
	return Action 3;
}

public Action Bindkeyhots(int client, int args)
{
	ClientCommand(client, "bind l \"say_team !joingame\"");
	PrintToChat(client, "\x05[reminder:]\x04Binding keyboard\x03 L \x04The key is automatically entered\x03!joingame\x04");
	return Action 3;
}

public Action Gotoaway(int client, int argCount)
{
	if (AwayCEnable)
	{
		if (GetUserFlagBits(client))
		{
			ChangeClientTeam(client, 1);
			return Action 3;
		}
		PrintToChat(client, "\x05[failure:]\x04Service is not turned on !away Can ask the administrator to modifyl4d2_rmc.cfg");
		return Action 3;
	}
	ChangeClientTeam(client, 1);
	return Action 3;
}

public Action Jointhegame(int client, int args)
{
	if (0 < Botnums())
	{
		if (0 < Alivebotnums())
		{
			ClientCommand(client, "jointeam 2");
			ClientCommand(client, "go_away_from_keyboard");
			return Action 3;
		}
		PrintToChat(client, "\x05[Failed to join:]\x04Please wait for the BOT to be rescued and enter !jg to enter.");
		return Action 3;
	}
	PrintToChat(client, "\x05[Failed to join:]\x04There isn't enough BOT to allow you to control, please enter !addbot to add the Bot.");
	return Action 3;
}

public int Survivors()
{
	int numSurvivors = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		int var1;
		if (IsClientInGame(i))
		{
			numSurvivors++;
			i++;
		}
		i++;
	}
	return numSurvivors;
}

public int AliveSurvivors()
{
	int numSurvivors = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		int var1;
		if (IsClientConnected(i))
		{
			numSurvivors++;
			i++;
		}
		i++;
	}
	return numSurvivors;
}

public int Allplayersn()
{
	int numplayers = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		int var1;
		if (IsClientConnected(i))
		{
			numplayers++;
			i++;
		}
		i++;
	}
	return numplayers;
}

public int Botnums()
{
	int numBots = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		int var1;
		if (IsClientInGame(i))
		{
			numBots++;
			i++;
		}
		i++;
	}
	return numBots;
}

public int Alivebotnums()
{
	int AnumBots = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		int var1;
		if (IsClientInGame(i))
		{
			AnumBots++;
			i++;
		}
		i++;
	}
	return AnumBots;
}

public int Gonaways()
{
	int numaways = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		int var1;
		if (IsClientInGame(i))
		{
			numaways++;
			i++;
		}
		i++;
	}
	return numaways;
}

public Action Vserverinfo(int client, int args)
{
	PrintToChat(client, "\x05[Tip]\x03 Number of survivors \x04[%i]\x03 Number of player survivors \x04[%i]\x03 Number of observers \x04[%i]\x03 bot Quantity \x04[%i]\x03 The number of bots that survive \x04[%i]", Survivors(), AliveSurvivors(), Gonaways(), Botnums(), Alivebotnums());
	return Action 3;
}

public Action Rzhisha(int client, int args)
{
	int var1;
	if (IsClientInGame(client))
	{
		ForcePlayerSuicide(client);
	}
	return Action 3;
}

public Action RListLoadplayer(int client, int args)
{
	char RLPlist[64];
	int Rlnameall = 0;
	bool RloadplayerN = 0;
	PrintToChatAll("\x05[Tip]\x03 Loaded player list...");
	int i = 1;
	while (i <= MaxClients)
	{
		int var1;
		if (IsClientConnected(i))
		{
			GetClientName(i, RLPlist, 64);
			Rlnameall++;
			PrintToChatAll("\x05[%i]\x04 %s \x01ID: %i", Rlnameall, RLPlist, i);
			RloadplayerN = 1;
			i++;
		}
		i++;
	}
	if (!RloadplayerN)
	{
		PrintToChatAll("\x05       ------ Empty ------");
	}
	else
	{
		PrintToChatAll("\x05------\x04 %i \x05People are still loading------", Rlnameall);
	}
	return Action 3;
}

public Action CreateOneBot(int client, int agrs)
{
	LCreateOneBot(client);
	return Action 0;
}

public int LCreateOneBot(int client)
{
	char asnus[4];
	char aynus[4];
	char abnus[4];
	int asnus1 = 0;
	int aynus1 = 0;
	int abnus1 = 0;
	Format(asnus, 3, "%i", Survivors());
	Format(aynus, 3, "%i", Gonaways());
	Format(abnus, 3, "%i", Botnums());
	asnus1 = StringToInt(asnus, 10);
	aynus1 = StringToInt(aynus, 10);
	abnus1 = StringToInt(abnus, 10);
	int var1;
	if (abnus1 < aynus1)
	{
		int survivorbot = CreateFakeClient("survivor bot");
		ChangeClientTeam(survivorbot, 2);
		DispatchKeyValue(survivorbot, "classname", "SurvivorBot");
		DispatchSpawn(survivorbot);
		CreateTimer(1, SurvivorKicker, survivorbot, 0);
		int i = 1;
		while (i <= MaxClients)
		{
			int var2;
			if (IsClientConnected(i))
			{
				float vAngles1[3];
				float vOrigin1[3];
				GetClientAbsOrigin(i, vOrigin1);
				GetClientAbsAngles(i, vAngles1);
				TeleportEntity(survivorbot, vOrigin1, vAngles1, NULL_VECTOR);
			}
			i++;
		}
	}
	else
	{
		PrintCenterText(client, "\x05[Tip]\x03 No need to add bot.");
		PrintToChat(client, "\x05[Tip]\x03 No need to add bot.");
	}
	return 0;
}

public Action SurvivorKicker(Handle timer, any survivorbot)
{
	KickClient(survivorbot, "CreateOneBot...");
	PrintToChatAll("\x05[Tip]\x01 BOT is created, click on the left mouse button.");
	return Action 3;
}

public Action Event_rmcteam(Handle event, char name[], bool dontBroadcast)
{
	if (RAutoBotcheck)
	{
		int Client = GetClientOfUserId(GetEventInt(event, "userid", 0));
		int var1;
		if (Client)
		{
			if (Rmc_ChangeTeam[Client][0][0])
			{
			}
			else
			{
				CreateTimer(0.5, JointeamRmc, Client, 0);
				Rmc_ChangeTeam[Client] = 1;
			}
		}
	}
	return Action 0;
}

public Action JointeamRmc(Handle timer, any client)
{
	int var1;
	if (IsClientConnected(client))
	{
		if (GetClientTeam(client) != 2)
		{
			LCreateOneBot(client);
			CreateTimer(1.5, JgHintplayers16, client, 0);
		}
	}
	return Action 0;
}

