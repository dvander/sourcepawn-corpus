#include <sourcemod>
#define ZPSMAXPLAYERS 24
#define Version "1.9"
#define TopChannel 0
#define BottomChannel 5
#define CVarFlags FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
new MaxPlayers = -1;
new DamageThisLife[ZPSMAXPLAYERS+1][ZPSMAXPLAYERS+1] = {{0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}};
new Damage[ZPSMAXPLAYERS+1][ZPSMAXPLAYERS+1] = {{0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}};
new Float:LastDamageTime[ZPSMAXPLAYERS+1][ZPSMAXPLAYERS+1] = {{0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}, {0.0, ...}};
new ClientHP[ZPSMAXPLAYERS+1] = {0, ...};
new Ranking[ZPSMAXPLAYERS+1] = {1, ...};
new bool:DisplayingTop = false;
new String:DisplayingTopMessage[ZPSMAXPLAYERS+1][5][512];
new String:DisplayingTopMessageTitle[ZPSMAXPLAYERS+1][128];
new InfectionTimeOffset = -1;
new InfectedOffset = -1;
new SpectatingTargetOffset = -1;
new Handle:TopHudX = INVALID_HANDLE;
new Handle:TopHudY = INVALID_HANDLE;
new Handle:BottomHudX = INVALID_HANDLE;
new Handle:BottomHudY = INVALID_HANDLE;
new Handle:DisplayInfected = INVALID_HANDLE;
new Handle:DisplayDamage = INVALID_HANDLE;
new Handle:DisplayTop = INVALID_HANDLE;
new Handle:UpdateDelay = INVALID_HANDLE;
new Handle:TopDisplayHoldTime = INVALID_HANDLE;
new Handle:DmgDisplayHoldTime = INVALID_HANDLE;
new Handle:ColorR = INVALID_HANDLE;
new Handle:ColorG = INVALID_HANDLE;
new Handle:ColorB = INVALID_HANDLE;
new Handle:ColorA = INVALID_HANDLE;
new Handle:RankingInDmg = INVALID_HANDLE;
new Handle:VersionCVar = INVALID_HANDLE;
new Handle:DamageDisplayTimer[ZPSMAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:RetryUpdateDisplayTimer[ZPSMAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Float:NextDamageUpdateTime[ZPSMAXPLAYERS+1] = {0.0, ...};
new ClientHPAtDisplay[ZPSMAXPLAYERS+1][ZPSMAXPLAYERS+1] = {{0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}, {0, ...}};
new SpectatingTarget[ZPSMAXPLAYERS+1] = {-1, ...};
new ClientTeam[ZPSMAXPLAYERS+1] = {-1, ...};

public Plugin:myinfo = {
	name = "ZPS Displayer",
	author = "NBK - Sammy-ROCK!",
	description = "Display things about ZPS in the client's screen.",
	version = Version,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("zpsdisplayer.phrases");
	SpectatingTargetOffset = FindSendPropOffs("CHL2MP_Player", "m_hObserverTarget");
	TopHudX = CreateConVar("zpsdisplayer_topx", "-1.0", "X Pos of top display.", CVarFlags, true, -1.0, true, 1.0);
	TopHudY = CreateConVar("zpsdisplayer_topy", "0.1", "Y Pos of top display.", CVarFlags, true, -1.0, true, 1.0);
	BottomHudX = CreateConVar("zpsdisplayer_bottomx", "-1.0", "X Pos of bottom display.", CVarFlags, true, -1.0, true, 1.0);
	BottomHudY = CreateConVar("zpsdisplayer_bottomy", "0.9", "Y Pos of bottom display.", CVarFlags, true, -1.0, true, 1.0);
	DisplayInfected = CreateConVar("zpsdisplayer_infected", "1", "Display Infected Survivors's countdown to Zombies, Spectators and the infected person (Not survivors team).", CVarFlags, true, 0.0, true, 1.0);
	DisplayDamage = CreateConVar("zpsdisplayer_damage", "1", "Display damage to attacker when someone gets hurt by someone else.", CVarFlags, true, 0.0, true, 1.0);
	DisplayTop = CreateConVar("zpsdisplayer_top", "24", "Display round's top players based on damage when round ends. Value means the maximum players that are going to be displayed.", CVarFlags, true, 0.0, true, float(ZPSMAXPLAYERS));
	UpdateDelay = CreateConVar("zpsdisplayer_update_delay", "1.0", "Minimum delay before updating damage stats.", CVarFlags, true, 0.1);
	TopDisplayHoldTime = CreateConVar("zpsdisplayer_top_delay", "0.0", "Delay before removing top players display. 0 to remove on begin of next round.", CVarFlags, true, 0.0, true, 120.0);
	DmgDisplayHoldTime = CreateConVar("zpsdisplayer_damage_delay", "10.0", "Delay before removing old hits from damage display.", CVarFlags, true, 0.1);
	ColorR = CreateConVar("zpsdisplayer_colors_r", "218.0", "Red value in text displayed.", CVarFlags, true, 0.0, true, 255.0);
	ColorG = CreateConVar("zpsdisplayer_colors_g", "165.0", "Green value in text displayed.", CVarFlags, true, 0.0, true, 255.0);
	ColorB = CreateConVar("zpsdisplayer_colors_b", "32.0", "Blue value in text displayed.", CVarFlags, true, 0.0, true, 255.0);
	ColorA = CreateConVar("zpsdisplayer_colors_a", "255.0", "Alpha value in text displayed.", CVarFlags, true, 0.0, true, 255.0);
	RankingInDmg = CreateConVar("zpsdisplayer_rankingindmg", "1", "Displays the current rank and how much until next in the Damage Display.", CVarFlags, true, 0.0, true, 1.0);
	VersionCVar = CreateConVar("zpsdisplayer_version", Version, "Version of ZPS Displayer plugin.", CVarFlags);
	AutoExecConfig(true, "zpsdisplayer");
	HookEvent("ambient_play", AmbientPlayEvent);
	HookEvent("player_spawn", PlayerSpawnEvent);
	HookEvent("player_hurt"	, PlayerHurtEvent);
	HookEvent("player_team"	, PlayerTeamEvent);
	HookEvent("game_round_restart", RoundRestartEvent);
	new Handle:conf = LoadGameConfigFile("zpsinfectiontoolkit");
	InfectionTimeOffset = GameConfGetOffset(conf, "ZombieTurnTime");
	CloseHandle(conf);
	InfectedOffset = FindSendPropOffs("CHL2MP_Player", "m_IsInfected");
	decl String:DataVersion[16];
	GetConVarString(VersionCVar, DataVersion, sizeof(DataVersion));
	if(!StrEqual(DataVersion, Version))
	{
		DeleteFile("cfg\\sourcemod\\zpsdisplayer.cfg")
		AutoExecConfig(true, "zpsdisplayer");
		LogMessage("Newer Version Detected: cfg\\sourcemod\\zpsdisplayer.cfg was remade.");
	}
}

public OnGameFrame()
{
	new Float:CopyOfDmgDisplayHoldTime = GetConVarFloat(DmgDisplayHoldTime);
	new Float:GameTime = GetGameTime();
	decl NewHP, SpecTarget;
	decl bool:IsInGame[ZPSMAXPLAYERS+1] = {false, ...};
	for(new client = 1; client <= MaxPlayers; client++)
	{
		IsInGame[client] = IsClientInGame(client);
	}
	for(new client = 1; client <= MaxPlayers; client++)
	{
		if(IsInGame[client])
		{
			NewHP = GetClientHealth(client);
			if(NewHP != ClientHP[client])
			{
				ClientHP[client] = NewHP;
				for(new player = 1; player <= MaxPlayers; player++)
				{
					if(IsInGame[player] && GameTime - LastDamageTime[player][client] < CopyOfDmgDisplayHoldTime)
						UpdateDmgDisplayTimer(player);
				}
			}
			if(ClientTeam[client] == 1)
			{
				SpecTarget = GetEntDataEnt2(client, SpectatingTargetOffset);
				if(SpecTarget <= 0 || SpecTarget > MaxPlayers || !IsInGame[SpecTarget])
					SpecTarget = client;
				if(SpectatingTarget[client] != SpecTarget)
				{
					SpectatingTarget[client] = SpecTarget;
					UpdateDmgDisplayTimer(client);
				}
			}
		}
	}
}

public OnClientPutInServer(client)
{
	ResetStats(client);
	ClientTeam[client] = GetClientTeam(client);
}

public OnMapStart()
{
	MaxPlayers = GetMaxClients();
	CreateTimer(GetConVarFloat(UpdateDelay), TurnTimeUpdateTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(DisplayingTop)
		ShowRoundTopsToClient(client)
	else
		ReDisplayStats(client);
}

public Action:PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client)
		return;
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!attacker)
		attacker = client;
	new CurrentHP = GetClientHealth(client);
	if(CurrentHP < 0)
		CurrentHP = 0;
	new DamageDone = ClientHP[client] - CurrentHP;
	if(DamageDone <= 0)
		return;
	Damage[attacker][client] += DamageDone;
	DamageThisLife[attacker][client] += DamageDone;
	LastDamageTime[attacker][client] = GetGameTime();
}

public Action:PlayerTeamEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client)
		return;
	ClientTeam[client] = GetEventInt(event, "team");
}

public Action:RoundRestartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new client=1; client<=MaxPlayers; client++)
		ResetStats(client);
	if(GetConVarFloat(TopDisplayHoldTime) == 0.0)
	{
		DisplayingTop = false;
		RemoveHudDisplay(TopChannel);
	}
}

public Action:AmbientPlayEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:ASound[64];
	GetEventString(event, "sound", ASound, sizeof(ASound));
	if(StrContains(ASound, ".Win", true) > -1)
	{
		DisplayRoundTops();
	}
}

public ResetStats(client)
{
	for(new player=1; player<=MaxPlayers; player++)
	{
		Damage[client][player] = 0;
		DamageThisLife[client][player] = 0;
	}
}

public ReDisplayStats(client)
{
	if(DisplayingTop || !client || !IsClientInGame(client))
		return;
	for(new player=1; player<=MaxPlayers; player++)
	{
		if(IsClientInGame(player) && SpectatingTarget[player] == client)
		{
			UpdateDmgDisplayTimer(player);
		}
	}
	decl target;
	if(ClientTeam[client] == 1)
	{
		target = GetEntDataEnt2(client, SpectatingTargetOffset);
		if(target <= 0 || target > MaxPlayers)
			target = client;
	}
	else
		target = client;
	decl String:Message[1028], DamageDone, DamageDoneThisLife, TotalDamageDone, String:Victim[MAX_NAME_LENGTH], String:DamageStats[64], String:CurrentHP[16];
	SetGlobalTransTarget(client);
	if(target == client)
		Format(Message, sizeof(Message), "%t %t:", "Your", "Damages");
	else
		Format(Message, sizeof(Message), "%t:", "Refer Player", target, "Damages");
	if(GetConVarInt(RankingInDmg))
	{
		if((TotalDamageDone = GetTotalDamageDone(target)) > 0)
		{
			Format(Message, sizeof(Message), "%s %d", Message, TotalDamageDone);
			if((DamageDoneThisLife = GetTotalDamageDoneThisLife(target)) < TotalDamageDone)
				Format(Message, sizeof(Message), "%s (%d %t %t)", Message, DamageDoneThisLife, "this", "life");
			decl TargetTotalDamageDone, DamageDifference;
			new rank = 1, DamageUntilNext = 99999;
			for(new player = 1; player<= MaxPlayers; player++)
			{
				if(player != target)
				{
					if((TargetTotalDamageDone = GetTotalDamageDone(player)) > TotalDamageDone)
					{
						if((DamageDifference = TargetTotalDamageDone - TotalDamageDone) < DamageUntilNext)
							DamageUntilNext = DamageDifference;
						rank++;
					}
				}
			}
			Ranking[target] = rank;
			Format(Message, sizeof(Message), "%s\nRanking: %d", Message, rank);
			if(DamageUntilNext != 99999)
			{
				Format(Message, sizeof(Message), "%s (%d %t)", Message, DamageUntilNext, "left");
			}
			for(new player = 1; player<= MaxPlayers; player++)
			{
				if(player != target && Ranking[player] == Ranking[target])
				{
					UpdateDmgDisplayTimer(player);
					Ranking[player] += 1;
					break;
				}
			}
		}
		else
			return;
	}
	new bool:Empty = true;
	new Float:CopyOfDmgDisplayHoldTime = GetConVarFloat(DmgDisplayHoldTime);
	for(new player=1; player<=MaxPlayers; player++)
	{
		if(IsClientInGame(player) && (DamageDone = Damage[target][player]) > 0 && GetGameTime() - LastDamageTime[target][player] < CopyOfDmgDisplayHoldTime)
		{
			if(player == client)
				Format(Victim, sizeof(Victim), "%t", "Yourself");
			else if(player == target)
				Format(Victim, sizeof(Victim), "%t", "Himself");
			else
				Format(Victim, sizeof(Victim), "%N", player);

			Format(DamageStats, sizeof(DamageStats), "%d", DamageDone);
			if((DamageDoneThisLife = DamageThisLife[target][player]) > 0 && DamageDoneThisLife != DamageDone)
				Format(DamageStats, sizeof(DamageStats), "%s (%d %t %t)", DamageStats, DamageDoneThisLife, "this", "life");
			if((TotalDamageDone = GetTotalDamageReceived(player)) > DamageDone)
				Format(DamageStats, sizeof(DamageStats), "%s %t %d", DamageStats, "from", TotalDamageDone);

			if(IsPlayerAlive(player) && ClientHP[player] > 0 && ClientTeam[player] != 1)
				Format(CurrentHP, sizeof(CurrentHP), "%d %t", ClientHP[player], "left");
			else
				Format(CurrentHP, sizeof(CurrentHP), "%t", "DEAD");
			ClientHPAtDisplay[client][player] = ClientHP[player];
			Format(Message, sizeof(Message), "%s\n%s: %s (%s)", Message, Victim, DamageStats, CurrentHP);
			Empty = false;
		}
	}
	if(Empty)
	{
		ShowHudText(client, TopChannel, "");
		return;
	}
	SetHudTextParams(GetConVarFloat(TopHudX), GetConVarFloat(TopHudY), CopyOfDmgDisplayHoldTime, GetConVarInt(ColorR), GetConVarInt(ColorG), GetConVarInt(ColorB), GetConVarInt(ColorA));
	ShowHudText(client, TopChannel, Message);
}

stock GetTotalDamageReceived(client)
{
	new TotalDmg = 0;
	for(new player=1; player<=MaxPlayers; player++)
	{
		TotalDmg += Damage[player][client];
	}
	return TotalDmg;
}

stock GetTotalDamageDone(client)
{
	new TotalDmg = 0;
	for(new player=1; player<=MaxPlayers; player++)
	{
		if(player == client)
			TotalDmg -= Damage[client][player];
		else
			TotalDmg += Damage[client][player];
	}
	return TotalDmg;
}

stock GetTotalDamageDoneThisLife(client)
{
	new TotalDmg = 0;
	for(new player=1; player<=MaxPlayers; player++)
	{
		if(player == client)
			TotalDmg -= DamageThisLife[client][player];
		else
			TotalDmg += DamageThisLife[client][player];
	}
	return TotalDmg;
}

public ReDisplayTurnTime()
{
	decl Float:TurnTimeLeft, iTurnTimeLeft[ZPSMAXPLAYERS+1], Team[ZPSMAXPLAYERS+1];
	new Float:GameTime = GetGameTime();
	new bool:Empty = true;
	SetHudTextParams(GetConVarFloat(BottomHudX), GetConVarFloat(BottomHudY), 1.0, GetConVarInt(ColorR), GetConVarInt(ColorG), GetConVarInt(ColorB), GetConVarInt(ColorA));
	for(new client=1; client<=MaxPlayers; client++)
	{
		if(IsClientInGame(client) && (Team[client] = ClientTeam[client]) == 2 && GetEntData(client, InfectedOffset) && (TurnTimeLeft = GetEntDataFloat(client, InfectionTimeOffset) - GameTime) >= 1.0)
		{
			iTurnTimeLeft[client] = RoundToFloor(TurnTimeLeft);
			SetGlobalTransTarget(client);
			ShowHudText(client, BottomChannel, "%t %t %d secs", "Turning", "in", iTurnTimeLeft[client]);
			Empty = false;
		}
		else
			iTurnTimeLeft[client] = 0;
	}
	if(Empty)
		return;
	new String:InfectedTable[512];
	for(new player=1; player<=MaxPlayers; player++)
	{
		if(iTurnTimeLeft[player] >= 1)
			Format(InfectedTable, sizeof(InfectedTable), "%s\n%N: %d", InfectedTable, player, iTurnTimeLeft[player]);
	}
	for(new client=1; client<=MaxPlayers; client++)
	{
		if(IsClientInGame(client) && Team[client] != 2)
		{
			decl String:Message[512];
			SetGlobalTransTarget(client);
			Format(Message, sizeof(Message), "%t:%s", "Infecteds", InfectedTable);
			ShowHudText(client, BottomChannel, Message);
		}
	}
}

public Action:TurnTimeUpdateTimer(Handle:timer)
{
	CreateTimer(GetConVarFloat(UpdateDelay), TurnTimeUpdateTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	if(GetConVarInt(DisplayInfected))
		ReDisplayTurnTime();
	return Plugin_Stop;
}

public DisplayRoundTops()
{
	decl Top;
	if(!(Top = GetConVarInt(DisplayTop)))
		return;
	if(Top > MaxPlayers)
		Top = MaxPlayers;
	new TotalDmg[ZPSMAXPLAYERS+1] = {0, ...};
	for(new client=1; client<=MaxPlayers; client++)
	{
		for(new player=1; player<=MaxPlayers; player++)
		{
			TotalDmg[client] += Damage[client][player];
		}
	}
	new bool:Picked[ZPSMAXPLAYERS+1] = {false, ...};
	new TopDamage[Top], TopPlayer[Top];
	for(new i=0; i<Top; i++)
	{
		for(new client=1; client<=MaxPlayers; client++)
		{
			if(IsClientInGame(client) && !Picked[client] && TotalDmg[client] > TopDamage[i])
			{
				TopDamage[i] = TotalDmg[client];
				TopPlayer[i] = client;
			}
		}
		if(TopPlayer[i])
			Picked[TopPlayer[i]] = true;
		else
			break;
	}
	DisplayingTop = true;
	new Float:Holdtime = GetConVarFloat(TopDisplayHoldTime);
	if(Holdtime > 0.0)
		CreateTimer(Holdtime, TimerDisplayingTopEnd, _, TIMER_FLAG_NO_MAPCHANGE);
	for(new client=1; client<=MaxPlayers; client++)
	{
		if(IsClientInGame(client))
		{
			SetGlobalTransTarget(client);
			DisplayingTopMessageTitle[client] = "";
			DisplayingTopMessage[client][0] = "";
			DisplayingTopMessage[client][1] = "";
			DisplayingTopMessage[client][2] = "";
			DisplayingTopMessage[client][3] = "";
			Format(DisplayingTopMessageTitle[client], sizeof(DisplayingTopMessageTitle[]), "%t : %t", "Round's Top", "Damage");
			for(new i=0; i<Top; i++)
			{
				new index = RoundToFloor(float(i + 1) / 5);
				if(index > 0 && FloatModuloOperation(float(i + 1), 5.0) == 0.0)
					index -= 1;
				if(TopPlayer[i])
				{
					Format(DisplayingTopMessage[client][index], sizeof(DisplayingTopMessage[][]), "%s\n%d - %N : %d", DisplayingTopMessage[client][index], i+1, TopPlayer[i], TopDamage[i]);
					new TopDamageThisLife = GetTotalDamageDoneThisLife(TopPlayer[i]);
					if(TopDamageThisLife > 0 && TopDamageThisLife != TopDamage[i])
						Format(DisplayingTopMessage[client][index], sizeof(DisplayingTopMessage[][]), "%s (%d %t %t)", DisplayingTopMessage[client][index], TopDamageThisLife, "this", "life");
				}
				else
					break;
			}
			ShowRoundTopsToClient(client);
		}
	}
}

stock Float:FloatModuloOperation(Float:Val1, Float:Val2) //Same as "Val1 % Val2", "Val1 mod Val2". Operator not implemented for floats.
{
	new Float:Rest = Val1;
	while(Rest >= Val2)
		Rest -= Val2;
	return Rest;
}

public ShowRoundTopsToClient(client)
{
	SetHudTextParams(-1.0, 0.00, 120.0, GetConVarInt(ColorR), GetConVarInt(ColorG), GetConVarInt(ColorB), GetConVarInt(ColorA));
	ShowHudText(client, 0, DisplayingTopMessageTitle[client]);
	SetHudTextParams(-1.0, 0.01, 120.0, GetConVarInt(ColorR), GetConVarInt(ColorG), GetConVarInt(ColorB), GetConVarInt(ColorA));
	ShowHudText(client, 1, DisplayingTopMessage[client][0]);
	SetHudTextParams(-1.0, 0.20, 120.0, GetConVarInt(ColorR), GetConVarInt(ColorG), GetConVarInt(ColorB), GetConVarInt(ColorA));
	ShowHudText(client, 2, DisplayingTopMessage[client][1]);
	SetHudTextParams(-1.0, 0.40, 120.0, GetConVarInt(ColorR), GetConVarInt(ColorG), GetConVarInt(ColorB), GetConVarInt(ColorA));
	ShowHudText(client, 3, DisplayingTopMessage[client][2]);
	SetHudTextParams(-1.0, 0.60, 120.0, GetConVarInt(ColorR), GetConVarInt(ColorG), GetConVarInt(ColorB), GetConVarInt(ColorA));
	ShowHudText(client, 4, DisplayingTopMessage[client][3]);
	SetHudTextParams(-1.0, 0.80, 120.0, GetConVarInt(ColorR), GetConVarInt(ColorG), GetConVarInt(ColorB), GetConVarInt(ColorA));
	ShowHudText(client, 5, DisplayingTopMessage[client][4]);
}

public Action:TimerDisplayingTopEnd(Handle:timer)
{
	DisplayingTop = false;
	RemoveHudDisplay(TopChannel);
}

public RemoveHudDisplay(channel)
{
	for(new client=1; client<=MaxPlayers; client++)
	{
		if(IsClientInGame(client))
			ShowHudText(client, channel, "");
	}
}

public UpdateDmgDisplayTimer(client)
{
	if(!GetConVarInt(DisplayDamage) || !IsClientInGame(client))
		return;
	decl target;
	if(ClientTeam[client] == 1)
	{
		target = GetEntDataEnt2(client, SpectatingTargetOffset);
		if(target <= 0 || target > MaxPlayers || !IsClientInGame(target))
			target = client;
	}
	else
		target = client;
	decl Float:TempFloat;
	new Float:Delay = 120.0;
	new Float:CopyOfDmgDisplayHoldTime = GetConVarFloat(DmgDisplayHoldTime);
	new Float:GameTime = GetGameTime();
	new Float:CopyOfUpdateDelay = GetConVarFloat(UpdateDelay);
	for(new player=1; player<=MaxPlayers; player++)
	{
		if(Delay < 1.0)
			break;
		TempFloat = GameTime - LastDamageTime[target][player];
		if(TempFloat > CopyOfDmgDisplayHoldTime)
			continue;
		if(TempFloat >= 0.0 && TempFloat < Delay)
			Delay = TempFloat;
		TempFloat = GameTime - LastDamageTime[target][player] + CopyOfDmgDisplayHoldTime;
		if(TempFloat >= CopyOfDmgDisplayHoldTime)
			continue;
		if(TempFloat >= 0.0 && TempFloat < Delay)
			Delay = TempFloat;
		if(ClientHPAtDisplay[client][player] != ClientHP[player])
			Delay = 0.0;
	}
	if(Delay > CopyOfDmgDisplayHoldTime + CopyOfUpdateDelay)
		return;
	if(Delay < 1.0 && NextDamageUpdateTime[client] <= GameTime - CopyOfUpdateDelay)
	{
		DamageDisplayTimer[client] = INVALID_HANDLE;
		NextDamageUpdateTime[client] = GameTime;
		ReDisplayStats(client);
	}
	else if(NextDamageUpdateTime[client] >= GameTime + Delay + CopyOfUpdateDelay || NextDamageUpdateTime[client] <= GameTime - CopyOfUpdateDelay)
	{
		NextDamageUpdateTime[client] = GameTime + Delay;
		DamageDisplayTimer[client] = CreateTimer(Delay, ClientDisplayTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(RetryUpdateDisplayTimer[client] == INVALID_HANDLE)
	{
		Delay = NextDamageUpdateTime[client] - GameTime + CopyOfUpdateDelay + 0.1;
		if(Delay < 0.1)
			Delay = 0.1;
		RetryUpdateDisplayTimer[client] = CreateTimer(Delay, Retry_UpdateDmgDisplayTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Retry_UpdateDmgDisplayTimer(Handle:timer, any:client)
{
	UpdateDmgDisplayTimer(client);
	RetryUpdateDisplayTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:ClientDisplayTimer(Handle:timer, any:client)
{
	if(timer != DamageDisplayTimer[client])
		return Plugin_Stop;
	if(GetConVarInt(DisplayDamage))
		ReDisplayStats(client);
	DamageDisplayTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}