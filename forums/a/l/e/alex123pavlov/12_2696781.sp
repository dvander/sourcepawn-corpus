public OnPluginStart()
{
	HookEvent("round_start", round_start, EventHookMode_PostNoCopy);
	HookEvent("item_pickup", item_pickup);
}

public item_pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new index = GetPlayerWeaponSlot(client, 0);
	if (index > 0)
	{
		decl String:class[20];
		GetEntityClassname(index, class, 20);
		if (StrEqual(class, "weapon_awp", false))
		{
			if (GetClientTeam(client) == 2) 
			{
				if (playerT > Awp)
				{	
					CS_DropWeapon(client, index, true, true);
					PrintToChat(client, "AWP STOP %d", playerT);
					playerT = Awp;
					playerT++;
				}
			}
			if (GetClientTeam(client) == 3)
			{
				if (playerCT > Awp) 
				{
					CS_DropWeapon(client, index, true, true);
					PrintToChat(client, "AWP STOP %d", playerCT);
					playerCT = Awp;
					playerCT++;
				}
			}
		}
	}
}

public round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	playerT = 0, playerCT = 0, Player = 0, Awp = 0;
	for(new x = 1; x <= MaxClients; x++)
	{
		if (IsClientInGame(x) && IsPlayerAlive(x)) Player++;
	}
	if (Player <= 4) Awp = 0;
	else if (Player <= 10) Awp = 0;
	else if (Player <= 24) Awp = 2;
 	else if (Player <= 32) Awp = 4;
	else if (Player <= MaxClients) Awp = 5;
}

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if (StrEqual(weapon, "awp", false))
	{
		if (GetClientTeam(client) == 2) 
		{
			playerT++;
			if (playerT > Awp)
			{
				PrintToChat(client, "AWP STOP");
				playerT = Awp;
				return Plugin_Handled;
			}
		}
		if (GetClientTeam(client) == 3)
		{
			playerCT++;
			if (playerCT > Awp) 
			{
				PrintToChat(client, "AWP STOP");
				playerCT = Awp;
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}