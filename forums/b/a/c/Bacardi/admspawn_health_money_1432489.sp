
new Handle:mp_startmoney = INVALID_HANDLE;
new Handle:admspawn_health = INVALID_HANDLE;
new Handle:admspawn_armour = INVALID_HANDLE;
new Handle:admspawn_money = INVALID_HANDLE;
new Handle:admspawn_moneylimit = INVALID_HANDLE;
new Handle:admspawn_onlyfirstround = INVALID_HANDLE;
new startmoney;
new health;
new armour;
new money;
new moneylimit;
new bool:g_firstround = false;
new bool:g_enable = false;
new bool:notmoney = false;

public Plugin:myinfo =
{
	name = "[CSS] Admin Spawn (HP and Money)",
	author = "Bacardi",
	description = "Set health, armour and money to admins when spawn",
	version = "0.3",
	url = "https://forums.alliedmods.net/showthread.php?t=152613"
}

public OnPluginStart()
{
	HookEvent("round_end", RoundEnd, EventHookMode_Post);
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);

	mp_startmoney = FindConVar("mp_startmoney");
	startmoney = GetConVarInt(mp_startmoney);
	HookConVarChange(mp_startmoney, ConVarChanged);

	admspawn_health = CreateConVar("admspawn_health", "105", "Set player health when spawn. 0 = Disabled", FCVAR_NONE, true, 0.0);
	health = GetConVarInt(admspawn_health);
	HookConVarChange(admspawn_health, ConVarChanged);

	admspawn_armour = CreateConVar("admspawn_armour", "0", "Set player armour when spawn, helmet included. 0 = Disable", FCVAR_NONE, true, 0.0);
	armour = GetConVarInt(admspawn_armour);
	HookConVarChange(admspawn_armour, ConVarChanged);

	admspawn_onlyfirstround = CreateConVar("admspawn_onlyfirstround", "0", "Will give only in first round when game start", FCVAR_NONE, true, 0.0, true, 1.0);
	g_firstround = GetConVarBool(admspawn_onlyfirstround);
	if(!g_firstround)
	{
		g_enable = true;
	}
	HookConVarChange(admspawn_onlyfirstround, ConVarChanged);

	admspawn_money = CreateConVar("admspawn_money", "200", "Give +amount or reduce -amount money when player spawn. 0 = Disabled", FCVAR_NONE);
	money = GetConVarInt(admspawn_money);
	HookConVarChange(admspawn_money, ConVarChanged);

	admspawn_moneylimit = CreateConVar("admspawn_moneylimit", "16000", "Set limit when player not gain extra money, 0 = unlimited", FCVAR_NONE, true, 0.0);
	moneylimit = GetConVarInt(admspawn_moneylimit);
	HookConVarChange(admspawn_moneylimit, ConVarChanged);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == mp_startmoney)
	{
		startmoney = StringToInt(newValue);
	}

	if(convar == admspawn_health)
	{
		health = StringToInt(newValue);
	}

	if(convar == admspawn_armour)
	{
		armour = StringToInt(newValue);
	}

	if(convar == admspawn_onlyfirstround)
	{
		new temp = StringToInt(newValue);
		if(temp < 1)
		{
			g_firstround = false;
			g_enable = true;
		}
		else
		{
			g_firstround = true;
		}
	}

	if(convar == admspawn_money)
	{
		money = StringToInt(newValue);
	}

	if(convar == admspawn_moneylimit)
	{
		moneylimit = StringToInt(newValue);
	}
}

public RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(health == 0 && armour == 0 && money == 0)
	{
		return;
	}

	new reason = GetEventInt(event, "reason");
	if(g_firstround)
	{
		if(reason == 15) // #Game_Commencing (Game start, 1 player in both team)
		{
			g_enable = true;
		}
		else
		{
			g_enable = false;
		}
	}
	else
	{
		if(reason == 9)	// #Round_Draw
		{
			notmoney = true;
		}
		else
		{
			notmoney = false;
		}
	}
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(health == 0 && armour == 0 && money == 0)
	{
		return;
	}

	if(g_enable)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetClientTeam(client) >= 2 && CheckCommandAccess(client, "admspawn_advantage", ADMFLAG_CUSTOM1)) // Check player join team 2 (T) or 3 (CT) and have admin priviledge
		{
			if(health > 0)
			{
				SetEntityHealth(client, health);
			}

			if(armour > 0)
			{
				SetEntProp(client, Prop_Send, "m_ArmorValue", armour);
				SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
			}
		
			if(!notmoney && money != 0)
			{
				new current_money = GetEntProp(client, Prop_Send, "m_iAccount");
		
				if(g_firstround)
				{
					current_money = startmoney + money;
				}
				else if(moneylimit != 0 && current_money + money > moneylimit) // If moneylimit set and player will get over that
				{
					if(current_money >= moneylimit)
					{
						return;
					}
					else
					{
						current_money = moneylimit;
					}
				}
				else
				{
					current_money += money;
				}
			
				if(current_money < 0)
				{
					current_money = 0;
				}

				SetEntProp(client, Prop_Send, "m_iAccount", current_money); // Money
			}
		}
	}
}