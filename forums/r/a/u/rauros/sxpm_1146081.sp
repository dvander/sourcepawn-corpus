#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define print PrintToServer

#define SXPM_XP_GAIN_PER_KILL 10
#define SXPM_XP_NEEDED_FIRST_LEVEL 50.0
#define SXPM_XP_NEEDED_MULTIPLIER 1.2
#define SXPM_EXPENDPOINTS_FIRST_LEVEL 1.0
#define SXPM_EXPENDPOINTS_MULTIPLIER 1.0
#define SXPM_MAX_LEVEL 1800

#define SXPM_C_xp 0x1
#define SXPM_C_lv 0x2
#define SXPM_C_ExpP 0x4
#define SXPM_C_Str 0x8
#define SXPM_C_Arm 0x10
#define SXPM_C_Reg 0x20
#define SXPM_C_NArm 0x40
#define SXPM_C_AmnR 0x80
#define SXPM_C_AntiGr 0x100
#define SXPM_C_SpeedI 0x200
#define SXPM_C_TeamPow 0x400
#define SXPM_C_BlckAtt 0x800

public Plugin:myinfo = 
{
	name = "SXPM",
	author = "lilEzek",
	description = "Synergy experience mod",
	version = "0.1",
	url = "http://forums.alliedmods.net/showthread.php?p=1141375#post1141375"
}

public GetAmmo(ammo_index,client)
{
	if (ammo_index > 31 || ammo_index < 0)
	{
		LogError("Invalid ammo index(%i). It must be between 0 and 31 inclusive.",ammo_index);
		return -1;
	}	
	return GetEntData(client,ammo_index * 4);	
}

public SetAmmo(ammo_index,client,amount)
{
	if (ammo_index > 31 || ammo_index < 0)
	{
		LogError("Invalid ammo index(%i). It must be between 0 and 31 inclusive.",ammo_index);
		return;
	}
	
}

// Client list system:

new ClientList[64];

public bool:IsClientInList(client)
{
	for (new x = 0; x < 64;x++)
	{
		if (ClientList[x] == client)
			return true;
	}
	return false;
}

public GetIndexFromClient(client)
{
	FixList();
	for (new x = 0; x < 64;x++)
	{
		if (ClientList[x] == client)
			return x;
	}
	if (AddPlayer(client))
		return GetIndexFromClient(client);
	return -1;
}

public GetClientFromIndex(index)
{
	FixList();
	return ClientList[index];
}

public FixList()
{
	for (new x = 0; x < 64;x++)
	{
		if (ClientList[x] != 0)
			if (!IsClientConnected(ClientList[x]))
			{
				ClientList[x] = 0;
				PlayerInit(x);
			}
	}
}

public FindEmptyIndex()
{
	for (new x = 0; x < 64;x++)
	{
		if (ClientList[x] < 1)
			return x;
	}
	return -1;
}

public bool:AddPlayer(client)
{
	FixList();
	if (client < 1)
		return false;
	new index = FindEmptyIndex();
	if (index == -1)
		return false;
	if (!IsClientConnected(client))
		return false;
	ClientList[index] = client;
	PlayerInit(index);
	return true;
}

// Client list system finished.

// Experience mod and some other shit system:

new String:SteamID[32][64];
new xp[64];
new lv[64];
new ExpendPoints[64];
new Strength[64];
new Armor[64];
new Regeneration[64];
new Float:NReg[64];
new NanoArmor[64];
new Float:NNano[64];
new AmunRein[64];
//new Float:NAmun[64];
new AntiGrav[64];
new SpeedI[64];
new TeamPower[64];
new BlockAttack[64];

new hChanged[64]; // Used to store in sqlite.

new Float:LastStored;

new Handle:Handle_Database;

public OnPluginStart()
{
	print("SXPM initialized");
	HookEvent("entity_killed",Event_EntityKilled,EventHookMode_Post);
	HookEvent("player_spawn",OnPlayerSpawn,EventHookMode_Post);
	RegConsoleCmd("sxpm_player_info", SXPM_PrintInfo);
	RegConsoleCmd("sxpm_expend_point",SXPM_Exp_Point);
	RegConsoleCmd("sxpm_restart_player",SXPM_Restart_Expend_Points);
	RegServerCmd("sxpm_add_expend_points",SXPM_CmdAddExpPoints);
	RegServerCmd("sxpm_networkprop",DEBUG_NTWPROP);
	new String:Err[100];
	Handle_Database = SQLite_UseDatabase("sourcemod-local",Err,100-1);
	if (Handle_Database == INVALID_HANDLE)
		LogError("SQLite error: %s",Err);
}

new Float:LastCheck;

public OnGameFrame()
{
	new Float:Time = GetTickedTime();
	new Float:Delta = Time - LastCheck;
	if (Delta < 0.5)
		return;
	LastCheck = Time;
	new client;
	for (new i = 0;i<64;i++)
	{
		client = GetClientFromIndex(i);
		if (client < 0 || client > MaxClients)
			continue;
		if (Regeneration[i])
		{
			new CurHealth = GetClientHealth(client);
			if ((NReg[i] <= Time) && (CurHealth < 100 + Strength[i]))
			{
				new AddHealth = RoundToFloor(GetRandomFloat(0.0,Regeneration[i]/60.0)) + 1;
				if (CurHealth + AddHealth > 100 + Strength[i])
					AddHealth = (100 + Strength[i]) - CurHealth;
				SetEntityHealth(client, CurHealth + AddHealth);
				NReg[i] = Time + (300.0-Regeneration[i]);
			}
		}
		if (NanoArmor[i])
		{
			new CurArmor = GetEntProp(client,Prop_Data,"m_ArmorValue");
			if ((NNano[i] <= Time) && (CurArmor < 100 + Armor[i]))
			{
				new AddArmor = RoundToFloor(GetRandomFloat(0.0,NanoArmor[i]/60.0)) + 1;
				if (CurArmor + AddArmor > 100 + Armor[i])
					AddArmor = (100 + Armor[i]) - CurArmor;
				SetEntProp(client, Prop_Data, "m_ArmorValue", CurArmor + AddArmor);
				NNano[i] = Time + (300.0-NanoArmor[i]);
			}
		}
		if(AntiGrav[i] && GetClientButtons(client)&IN_JUMP)
		{
			SetEntityGravity(client,1.0 - (0.8 * float(AntiGrav[i])/40.0));
		}		
		if(SpeedI[i])
		{
			if (GetClientButtons(client)&IN_RUN)
				SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",SpeedI[i] * 50.0 + 500.0);
			else
				SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",SpeedI[i] * 50.0 + 320.0);
		}
		if (BlockAttack[i])
		{
			if (GetRandomInt(0,300) <= BlockAttack[i])
			{
				new flags = GetEntProp(client,Prop_Send,"m_fFlags");
				if (!(flags&0x4000))
					flags |= 0x4000;
				SetEntProp(client,Prop_Send,"m_fFlags",flags);
			}
			else
			{
				new flags = GetEntProp(client,Prop_Send,"m_fFlags");
				if ((flags&0x4000))
					flags -= 0x4000;
				SetEntProp(client,Prop_Send,"m_fFlags",flags);
			}
		}
		if (LastStored - Time <= 3.0)
		{
			if (hChanged[i])
				SXPM_StoreInTable(client);
			LastStored = Time;
		}
	}
}

public OnClientAuthorized(client, const String:szAuth[])
{
	new index = GetIndexFromClient(client);
	if (index > -1)
	{
		GetClientAuthString(client, SteamID[index], 32-1);
		SXPM_LoadClient(client);
	}
}

public OnClientDisconnect(client)
{
	new index = GetIndexFromClient(client);
	if (index > -1)
	{
		ClientList[index] = 0;
		PlayerInit(index);
	}
}

public PlayerInit(index)
{
	xp[index] = 0;
	lv[index] = 1;
	ExpendPoints[index] = 0;
	Strength[index] = 0;
	Armor[index] = 0;
	Regeneration[index] = 0;
	NanoArmor[index] = 0;
	AmunRein[index] = 0;
	AntiGrav[index] = 0;
	SpeedI[index] = 0;
	TeamPower[index] = 0;
	BlockAttack[index] = 0;
	SteamID[index] = "";
}

public Action:SXPM_CmdAddExpPoints(args)
{
	if (args < 1)
	{
		PrintToServer("Useage: sxpm_add_expend_points <client>");
		return Plugin_Handled;
	}
	new String:h[4];
	GetCmdArg(1,h,4);
	new index = GetIndexFromClient(StringToInt(h));
	if (index > -1)
	{
		if (args > 1)
		{
			GetCmdArg(2,h,4);
			ExpendPoints[index] += StringToInt(h);
		}
		else
			ExpendPoints[index]++;
	}
	return Plugin_Handled;
}

public Action:DEBUG_NTWPROP(args)
{
	new String:h[30];
	if (args == 2)
	{
		GetCmdArg(2,h,30);
		if (!strcmp(h,"vector",false))
		{
			new Float:Val[3];
			GetCmdArg(1,h,30);
			GetEntPropVector(1,Prop_Send,h,Val);
			PrintToServer("%s property contains: %f,%f,%f",h,Val[0],Val[1],Val[2]);
		}
		else if (!strcmp(h,"float",false))
		{
			new Float:Val;
			GetCmdArg(1,h,30);
			Val = GetEntPropFloat(1,Prop_Send,h);
			PrintToServer("%s property contains: %f",h,Val);
		}
		else
		{
			new Val;
			GetCmdArg(1,h,30);
			Val = GetEntProp(1,Prop_Send,h);
			PrintToServer("%s property contains: %i",h,Val);
		}
		return Plugin_Handled;
	}
	if (args < 3)
	{
		PrintToServer("Useage: sxpm_networkprop <name> <type> <value> [if vector <value2> <value3>]");
		return Plugin_Handled;
	}
	GetCmdArg(2,h,30);
	if (args < 5 && !strcmp(h,"vector",false))
	{
		PrintToServer("Useage: sxpm_networkprop <name> <type> <value> [if vector <value2> <value3>]");
		return Plugin_Handled;
	}
	if (!strcmp(h,"vector"))
	{
		new Float:val[3];
		GetCmdArg(3,h,30);
		val[0] = StringToFloat(h);
		GetCmdArg(4,h,30);
		val[1] = StringToFloat(h);
		GetCmdArg(5,h,30);
		val[2] = StringToFloat(h);
		GetCmdArg(1,h,30);
		SetEntPropVector(1,Prop_Send,h,val);
	}
	else if(!strcmp(h,"float"))
	{
		new Float:val;
		GetCmdArg(3,h,30);
		val = StringToFloat(h);
		GetCmdArg(1,h,30);
		SetEntPropFloat(1,Prop_Send,h,val);
	}
	else
	{
		new val;
		GetCmdArg(3,h,30);
		val = StringToInt(h);
		GetCmdArg(1,h,30);
		SetEntProp(1,Prop_Send,h,val);
	}
	return Plugin_Handled;
}

public Action:SXPM_PrintInfo(client, args)
{
	if (client == 0)
		client++;
	new index = GetIndexFromClient(client);
	if (index > -1)
	{
		PrintToConsole(client,"Experience: %i/%i\nLevel: %i/1800\nExpend Points: %i\n",xp[index],SXPM_XpNeeded(client),lv[index],ExpendPoints[index]);
		PrintToConsole(client,"(1)Strengh points: %i/400\n(2)Armor points: %i/450\n(3)Regeneration: %i/300\n(4)Nano Armor: %i/300\n(5)Ammo Reincarnation: %i/30\n(6)Anti Gravity: %i/40\n(7)Speed: %i/80\n(8)Team power: %i/60\n(9)Block points: %i/140",Strength[index],Armor[index],Regeneration[index],NanoArmor[index],AmunRein[index],AntiGrav[index],SpeedI[index],TeamPower[index],BlockAttack[index]);
	}
}

public Action:SXPM_Exp_Point(client, args)
{
	if (args < 1)
	{
		PrintToConsole(client, "Usage: sxpm_expend_point <skill>");
		return Plugin_Handled;
	}		
	new String:Info[5];
	GetCmdArg(1,Info,5);
	new info = StringToInt(Info);
	new amount = 1;
	if (args > 1)
	{
		GetCmdArg(2,Info,5);
		amount = StringToInt(Info);
	}
	if (info > 9 || info < 1)
	{
		PrintToConsole(client, "Invalid skill.");
		return Plugin_Handled;
	}
	if (client == 0) // Localplayer compatibilities
		client++;
	new index = GetIndexFromClient(client);
	if (index > -1)
	{
		if (!(ExpendPoints[index] >= amount))
		{
			PrintToConsole(client, "You have no enought points to expend");
			return Plugin_Handled;
		}
		switch(info)
		{
			case 1:
			{
				if (Strength[index] < 400)
				{
					if ((amount + Strength[index]) > 400)
						amount = 400 - Strength[index] ;
					ExpendPoints[index] -= amount;
					Strength[index]+=amount;
					SetEntityHealth(client, GetClientHealth(client)+amount);
					SetEntProp(client,Prop_Send,"m_iMaxHealth",100 + Strength[index]);
					hChanged[index] |= SXPM_C_Str;
				}
			}
			case 2:
			{
				if (Armor[index] < 450)
				{
					if ((amount + Armor[index]) > 450)
						amount = 450 - Armor[index];
					ExpendPoints[index] -= amount;
					Armor[index]+=amount;
					SetEntProp(client, Prop_Data, "m_ArmorValue", GetEntProp(client, Prop_Data,"m_ArmorValue",1) + amount, 1 );
					hChanged[index] |= SXPM_C_Arm;
				}
			}
			case 3:
			{
				if (Regeneration[index] < 300)
				{
					if ((amount + Regeneration[index]) > 300)
						amount = 300 - Regeneration[index];
					ExpendPoints[index] -= amount;
					Regeneration[index]+=amount;
					hChanged[index] |= SXPM_C_Reg;
				}
			}
			case 4:
			{
				if (NanoArmor[index] < 300)
				{
					if ((amount + NanoArmor[index]) > 300)
						amount = 300 - NanoArmor[index];
					ExpendPoints[index] -= amount;
					NanoArmor[index]+=amount;
					hChanged[index] |=SXPM_C_NArm;
				}
			}
			case 5:
			{
				if (AmunRein[index] < 30)
				{
					if ((amount + AmunRein[index]) > 30)
						amount = 30 - AmunRein[index];
					ExpendPoints[index] -= amount;
					AmunRein[index]+=amount;
					hChanged[index] |= SXPM_C_AmnR;
				}
			}
			case 6:
			{
				if (AntiGrav[index] < 40)
				{
					if ((amount + AntiGrav[index]) > 40)
						amount = 40 - AntiGrav[index];
					ExpendPoints[index] -= amount;
					AntiGrav[index]+=amount;
					hChanged[index] |= SXPM_C_AntiGr;
				}
			}
			case 7:
			{
				if (SpeedI[index] < 80)
				{
					if ((amount + SpeedI[index]) > 80)
						amount = 80 - SpeedI[index];
					ExpendPoints[index] -= amount;
					SpeedI[index]+=amount;
					SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",1.0 + SpeedI[index] * 0.0125);
					hChanged[index] |= SXPM_C_SpeedI;
				}
			}
			case 8:
			{
				if (TeamPower[index] < 60)
				{
					if ((amount + TeamPower[index]) > 60)
						amount = 60 - TeamPower[index];
					ExpendPoints[index] -= amount;
					TeamPower[index]+=amount;
					hChanged[index] |= SXPM_C_TeamPow;
				}
			}
			case 9:
			{
				if (BlockAttack[index] < 140)
				{
					if ((amount + BlockAttack[index]) > 140)
						amount = 140 - BlockAttack[index];
					ExpendPoints[index] -= amount;
					BlockAttack[index]+=amount;
					hChanged[index] |= SXPM_C_BlckAtt;
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action:Event_EntityKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Killer = GetEventInt(event,"entindex_attacker");
	if (Killer > MaxClients || Killer < 1)
		return Plugin_Handled;
	SXPM_AddXp(Killer,SXPM_XP_GAIN_PER_KILL);
	return Plugin_Handled;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new index = GetIndexFromClient(client);
	if (Strength[index])
	{
		SetEntityHealth(client, 100 + Strength[index]);
		SetEntProp(client,Prop_Send,"m_iMaxHealth",100 + Strength[index]); 
	}
	if (Armor[index])
		SetEntProp(client, Prop_Data, "m_ArmorValue", Armor[index], 1 );
	if (AntiGrav[index])
	{
		SetEntityGravity(client,1.0 - (0.8 * float(AntiGrav[index])/40.0));
	}
	if (SpeedI[index])
	{
		SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",1.0 + SpeedI[index] * 0.0125);
	}
	return Plugin_Handled;
}

public SXPM_AddXp(client, XP)
{
	new index = GetIndexFromClient(client);
	if (index > -1)
		if (lv[index] >= SXPM_MAX_LEVEL)
			return;
		else
			xp[index] += XP;
	SXPM_CheckXp(client);
	hChanged[index] |= SXPM_C_xp;
}

public SXPM_AddLv(client)
{
	new index = GetIndexFromClient(client);
	if (index > -1)
	{
		lv[index]++;
		SXPM_AddExpPoints(client);
		hChanged[index] |= SXPM_C_lv;
		PrintToChat(client,"You have reached %i level",lv[index]);
	}
}

public SXPM_XpNeeded(client)
{
	new index = GetIndexFromClient(client);
	if (index < 0)
		return -1;
	new Float:result = SXPM_XP_NEEDED_FIRST_LEVEL;
	for (new x = 1;x < lv[index];x++)
	{
		result *= SXPM_XP_NEEDED_MULTIPLIER;
	}
	return RoundFloat(result);
}

public SXPM_CheckXp(client)
{
	new index = GetIndexFromClient(client);
	new XPN;
	if (index > -1)
		while ((XPN = SXPM_XpNeeded(client)) <= xp[index])
		{
			xp[index] -= XPN;
			SXPM_AddLv(client);
		}
	
}

public SXPM_AddExpPoints(client)
{
	new index = GetIndexFromClient(client);
	if (index > -1)
	{
		new Float:xpp = SXPM_EXPENDPOINTS_FIRST_LEVEL;
		for (new x = 1;x < lv[index];x++)
		{
			xpp *= SXPM_EXPENDPOINTS_MULTIPLIER;
		}
		ExpendPoints[index] += RoundFloat(xpp);
		hChanged[index] |= SXPM_C_ExpP;
	}
}

public Action:SXPM_Restart_Expend_Points(client, args)
{
	if (client == 0) // Localplayer compatibilities
		client++;
	new index = GetIndexFromClient(client);
	if (index > -1)
	{
		ExpendPoints[index] += Strength[index] + Armor[index] + Regeneration[index] + NanoArmor[index] + AmunRein[index] + AntiGrav[index] + SpeedI[index] + TeamPower[index] + BlockAttack[index];
		Strength[index] = Armor[index] = Regeneration[index] = NanoArmor[index] = AmunRein[index] = AntiGrav[index] = SpeedI[index] = TeamPower[index] = BlockAttack[index] = 0;
	}
}

public bool:SXPM_IsStored(client)
{
	new index = GetIndexFromClient(client);
	new String:Query[100];
	Format(Query,100,"SELECT H1 FROM sxpm_playerinfo WHERE SteamID = '%s'",SteamID[index]);
	new Handle:hQuery = SQL_Query(Handle_Database,Query);
	if (hQuery == INVALID_HANDLE)
	{
		new String:Err[100];
		SQL_GetError(Handle_Database,Err,100);
		LogError("SQLite error: %s",Err);
		return false;
	}
	while (SQL_FetchRow(hQuery))
	{
		CloseHandle(hQuery);
		return true;
	}
	CloseHandle(hQuery);
	return false;
}

public SXPM_StoreInTable(client)
{
	new index = GetIndexFromClient(client);
	if (!hChanged[index])
		return;
	if (!SQL_FastQuery(Handle_Database,"CREATE TABLE IF NOT EXISTS sxpm_playerinfo('SteamID' VARCHAR(32) NOT NULL PRIMARY KEY,'H1' INT NOT NULL,'H2' INT NOT NULL,'H3' INT NOT NULL,'H4' INT NOT NULL,'H5' INT NOT NULL,'H6' INT NOT NULL,'H7' INT NOT NULL,'H8' INT NOT NULL,'H9' INT NOT NULL,'Lv' INT NOT NULL,'Xp' INT NOT NULL,'Points' INT NOT NULL);"))
	{
		new String:Err[100];
		SQL_GetError(Handle_Database,Err,100);
		LogError("SQLite error: %s",Err);
		return;
	}
	new String:Query[500];
	new String:Temp[100];
	if (SXPM_IsStored(client))
	{
		StrCat(Query,500,"UPDATE sxpm_playerinfo SET ");
		if (hChanged[index] & SXPM_C_Str)
		{
			Format(Temp,100,"H1 = %i, ",Strength[index]);
			StrCat(Query,500,Temp);
		}
		if (hChanged[index] & SXPM_C_Arm)
		{
			Format(Temp,100,"H2 = %i, ",Armor[index]);
			StrCat(Query,500,Temp);
		}
		if (hChanged[index] & SXPM_C_Reg)
		{
			Format(Temp,100,"H3 = %i, ",Regeneration[index]);
			StrCat(Query,500,Temp);
		}
		if (hChanged[index] & SXPM_C_NArm)
		{
			Format(Temp,100,"H4 = %i, ",NanoArmor[index]);
			StrCat(Query,500,Temp);
		}
		if (hChanged[index] & SXPM_C_AmnR)
		{
			Format(Temp,100,"H5 = %i, ",AmunRein[index]);
			StrCat(Query,500,Temp);
		}
		if (hChanged[index] & SXPM_C_AntiGr)
		{
			Format(Temp,100,"H6 = %i, ",AntiGrav[index]);
			StrCat(Query,500,Temp);
		}
		if (hChanged[index] & SXPM_C_SpeedI)
		{
			Format(Temp,100,"H7 = %i, ",SpeedI[index]);
			StrCat(Query,500,Temp);
		}
		if (hChanged[index] & SXPM_C_TeamPow)
		{
			Format(Temp,100,"H8 = %i, ",TeamPower[index]);
			StrCat(Query,500,Temp);
		}
		if (hChanged[index] & SXPM_C_BlckAtt)
		{
			Format(Temp,100,"H9 = %i, ",BlockAttack[index]);
			StrCat(Query,500,Temp);
		}
		if (hChanged[index] & SXPM_C_lv)
		{
			Format(Temp,100,"Lv = %i, ",lv[index]);
			StrCat(Query,500,Temp);
		}
		if (hChanged[index] & SXPM_C_xp)
		{
			Format(Temp,100,"Xp = %i, ",xp[index]);
			StrCat(Query,500,Temp);
		}
		if (hChanged[index] & SXPM_C_ExpP)
		{
			Format(Temp,100,"Points = %i, ",ExpendPoints[index]);
			StrCat(Query,500,Temp);
		}
		Query[strlen(Query)-2] = '\0';
		Format(Temp,100," WHERE SteamID = '%s';",SteamID[index]);
		StrCat(Query,500,Temp);
	}
	else
	{
		StrCat(Query,500,"INSERT INTO sxpm_playerinfo VALUES( '");
		StrCat(Query,500,SteamID[index]);
		StrCat(Query,500,"' ,");
		IntToString(Strength[index],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(Armor[index],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(Regeneration[index],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(NanoArmor[index],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(AmunRein[index],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(AntiGrav[index],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(SpeedI[index],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(TeamPower[index],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(BlockAttack[index],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(lv[index],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(xp[index],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(ExpendPoints[index],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,");");
	}
	if (!SQL_FastQuery(Handle_Database,Query))
	{
		new String:Err[100];
		SQL_GetError(Handle_Database,Err,100);
		LogError("SQLite error: %s with query %s",Err,Query);
		return;
	}
	hChanged[index] = 0;
}

public SXPM_LoadClient(client)
{
	new index = GetIndexFromClient(client);
	if (index < 0)
		return;
	if (!SXPM_IsStored(client))
	{
		SXPM_StoreInTable(client);
		return;
	}
	new String:Query[100];
	Format(Query,100,"SELECT * FROM sxpm_playerinfo WHERE SteamID = '%s';",SteamID[index]);
	new Handle:hQuery = SQL_Query(Handle_Database,Query);
	if (hQuery == INVALID_HANDLE)
	{
		new String:Err[100];
		SQL_GetError(Handle_Database,Err,100);
		LogError("SQLite error: %s with query %s",Err,Query);
		return;
	}
	while(SQL_FetchRow(hQuery))
	{
		Strength[index] = SQL_FetchInt(hQuery,1);
		Armor[index] = SQL_FetchInt(hQuery,2);
		Regeneration[index] = SQL_FetchInt(hQuery,3);
		NanoArmor[index] = SQL_FetchInt(hQuery,4);
		AmunRein[index] = SQL_FetchInt(hQuery,5);
		AntiGrav[index] = SQL_FetchInt(hQuery,6);
		SpeedI[index] = SQL_FetchInt(hQuery,7);
		TeamPower[index] = SQL_FetchInt(hQuery,8);
		BlockAttack[index] = SQL_FetchInt(hQuery,9);
		lv[index] = SQL_FetchInt(hQuery,10);
		xp[index] = SQL_FetchInt(hQuery,11);
		ExpendPoints[index] = SQL_FetchInt(hQuery,12);
	}
}