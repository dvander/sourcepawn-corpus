/*
 * All code included in this file was written by Liam.
 *
 * This file includes the helper functions used in
 * the weapon restrictions plugin.
 */

#include "restrict_hacks.sp"
#include "restrict_utils.sp"

/*
 * RestrictWeapon(client, weapon, amount, team)
 * This function handles the parsing of all inputted variables.
 * It also contains all error codes to be returned to the client
 * in the case of something being invalid.
 */
RestrictWeapon(client, f_Weapon, f_Amount, f_Team, bool:f_Broadcast=true)
{
    if(f_Weapon == -1 || f_Amount == -1 || f_Team == -1)
    {
        ReplyToCommand(client, "Usage: sm_restrict <weapon> <amt|0=default> <all=default|t|ct>");
        return;
    }

    switch(f_Team)
    {
        case TEAM_ALL:
        {
            g_T_RestrictList[f_Weapon] = f_Amount;
            g_CT_RestrictList[f_Weapon] = f_Amount;
        }

        case TEAM_T:
        {
            g_T_RestrictList[f_Weapon] = f_Amount;
        }

        case TEAM_CT:
        {
            g_CT_RestrictList[f_Weapon] = f_Amount;
        }
    }
    if(f_Broadcast)
        NotifyPlayers(client, f_Weapon, f_Amount, f_Team, true);
}

/*
 * bool:IsRestricted(client, weapon, checkType)
 * Checks to see if a weapon is restricted.
 * If it is, it returns true, if not, returns false.
 */
bool:IsRestricted(f_Weapon, f_Team, f_CheckType = TYPE_BUY)
{
    new f_Count, f_AllowedAmount;

    if(GetConVarInt(g_Cvar_Admins_Can_Buy) == 1)
        return false;

    switch(f_Team)
    {
        case TEAM_ALL:
        {
            if(g_T_RestrictList[f_Weapon] >= 0 || g_CT_RestrictList[f_Weapon] >= 0)
                return true;
            else
                return false;
        }

        case TEAM_T:
        {
            if(g_T_RestrictList[f_Weapon] == -1)
                return false;
            else
            {
                if(f_CheckType == TYPE_RESTRICT || g_T_RestrictList[f_Weapon] == 0)
                    return true; 
                f_Count = CountWeaponsInGame(f_Team, f_Weapon);
                f_AllowedAmount = g_T_RestrictList[f_Weapon];
            }
        }

        case TEAM_CT:
        {
            if(g_CT_RestrictList[f_Weapon] == -1)
                return false;
            else
            {
                if(f_CheckType == TYPE_RESTRICT || g_CT_RestrictList[f_Weapon] == 0)
                    return true;
                
                f_Count = CountWeaponsInGame(f_Team, f_Weapon);
                f_AllowedAmount = g_CT_RestrictList[f_Weapon];
            }
        }
    }

    switch(f_CheckType)
    {
        case TYPE_REMOVE:
        {
            if(f_Count > f_AllowedAmount)
                return true;
            else
                return false;
        }

        case TYPE_BUY:
        {
            if(f_Count >= f_AllowedAmount)
                return true;
            else
                return false;
        }
    }
    return false;
}

/*
 * UnRestrictWeapon(client, weapon)
 * This function handles the parsing of all inputted variables.
 * It also contains all error codes to be returned to the client
 * in the case of something being invalid.
 */
UnrestrictWeapon(client, f_Team, f_Weapon, bool:f_Broadcast=true)
{
    if(f_Weapon == -1 || f_Team == -1)
    {
        ReplyToCommand(client, "Usage: sm_unrestrict <weapon> <all=default|t|ct>");
        return;
    }

    if(f_Weapon != 999 && !IsRestricted(f_Weapon, f_Team, TYPE_RESTRICT))
    {
        ReplyToCommand(client, "The %s is not restricted.", g_ShortWeaponNames[f_Weapon]);
        return;
    }

    if(f_Weapon == 999)
    {
        for(new i = 0; i < _:Weapon_Max; i++)
        {
            switch(f_Team)
            {
                case TEAM_ALL:
                {
                    g_T_RestrictList[i] = -1;
                    g_CT_RestrictList[i] = -1;
                }

                case TEAM_T:
                {
                    g_T_RestrictList[i] = -1;
                }

                case TEAM_CT:
                {
                    g_CT_RestrictList[i] = -1;
                }
            }
        }

        if(f_Team == TEAM_ALL)
            PrintToChatAll("All weapons have been unrestricted.");
        else
        {
            for(new i = 1; i <= g_MaxClients; i++)
            {
                if(IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == TEAM_T || client == i))
                {
                    PrintToChat(i, "All weapons have been unrestricted for your team.");
                }
            }
        }
    }
    else
    {
        switch(f_Team)
        {
            case TEAM_ALL:
            {
                g_T_RestrictList[f_Weapon] = -1;
                g_CT_RestrictList[f_Weapon] = -1;
            }

            case TEAM_T:
            {
                g_T_RestrictList[f_Weapon] = -1;
            }

            case TEAM_CT:
            {
                g_CT_RestrictList[f_Weapon] = -1;
            }
        }

        if(f_Broadcast)
            NotifyPlayers(client, f_Weapon, 0, f_Team, false);
    }
}

/*
 * CountWeaponsInGame(weapon, team)
 * Counts all weapons in game either all or by team
 * and returns that amount.
 */
CountWeaponsInGame(f_Team, f_Weapon)
{
    new f_Count = 0;
    new f_MaxEntities = GetMaxEntities( );

    if(f_Team == TEAM_ALL)
    {
        for(new i = 0; i < f_MaxEntities; i++)
        {
            decl String:f_Name[64];

            if(!IsValidEntity(i))
                continue;

            if(GetEdictClassname(i, f_Name, sizeof(f_Name))
                && !strcmp(f_Name, g_WeaponNames[f_Weapon], false))
            {
                f_Count++;
            }
        }
    }
    else
    {
        decl String:f_WeaponName[64];

        for(new i = 1; i <= g_MaxClients; i++)
        {
            if(!IsClientConnected(i) || !IsClientInGame(i))
                continue;

            new f_ClientTeam = GetClientTeam(i);

            if(f_Team != TEAM_ALL)
            {
                if(f_Team != f_ClientTeam)
                    continue;
            }

            for(new Slots:slot = Slot_Primary; slot < Slot_None; slot++)
            {
                new f_Entity;

                if(slot == Slot_Grenade)
                    f_Entity = UTIL_FindGrenadeByName(i, g_WeaponNames[f_Weapon]);
                else
                    f_Entity = GetPlayerWeaponSlot(i, _:slot);
                
                if(f_Entity == -1)
                    continue;

                GetEdictClassname(f_Entity, f_WeaponName, sizeof(f_WeaponName));

                if(!strcmp(f_WeaponName, g_WeaponNames[f_Weapon], false))
                    f_Count++;
            }
        }
    }
    return f_Count;
}

/* Count Grenades on a client. */
CountGrenades(client)
{
	frag[client] = 0;
	smoke[client] = 0;
	flash[client] = 0;
	decl String:Class[64];
	for(new i = 0, ent; i < 128; i += 4)
	{
		ent = GetEntDataEnt(client, m_hMyWeapons + i);

		if(IsValidEdict(ent) && ent > g_MaxClients && HACK_GetSlot(ent) == _:Slot_Grenade)
		{
			GetEdictClassname(ent, Class, sizeof(Class));

			if(strcmp(Class, "weapon_hegrenade", false) == 0)
				frag[client]++;
			if(strcmp(Class, "weapon_smokegrenade", false) == 0)
				smoke[client]++;
			if(strcmp(Class, "weapon_flashbang", false) == 0)
				flash[client]++;
		}
	}
}

/*
 * CheckRestrictedWeapons(client)
 * Checks a client for all restricted weapons, if found, weapon is removed.
 */
CheckClientForRestrictedWeapons(client)
{
    new f_Team = GetClientTeam(client);

    if(g_KnivesOnly > 1)
    {
        for(new f_Weapon = 0; f_Weapon < _:Weapon_Max; f_Weapon++)
        {
	    if ( f_Weapon != _:Weapon_Knife && f_Weapon != _:Weapon_C4 )
                RemoveWeaponFromClient(client, f_Weapon, true);
        }
	return;
    }

    if(g_SingleWeaponRound > 1)
    {
        for(new f_Weapon = 0; f_Weapon < _:Weapon_Max; f_Weapon++)
        {
            if(g_SingleWeapon != f_Weapon && f_Weapon != _:Weapon_C4 && f_Weapon != _:Weapon_Knife)
                RemoveWeaponFromClient(client, f_Weapon, true);
        }
	return;
    }

    if(g_PistolsOnly > 1)
    {
        for(new f_Weapon = 0; f_Weapon < _:Weapon_Max; f_Weapon++)
        {
            if(g_WeaponSlot[f_Weapon] != Slot_Secondary && f_Weapon != _:Weapon_C4 && f_Weapon != _:Weapon_Knife)
                RemoveWeaponFromClient(client, f_Weapon, true);
        }
    }

    
    for(new f_Weapon = 0; f_Weapon < _:Weapon_Max; f_Weapon++)
    {
        if(IsRestricted(f_Weapon, f_Team, TYPE_REMOVE))
            RemoveWeaponFromClient(client, f_Weapon, true);
    }
    return;
}