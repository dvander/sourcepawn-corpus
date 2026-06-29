/*
 * Utilities
 */

/*
 * LookupWeaponNumber(name)
 * Lookup a weapon index by its name and return the index,
 * or -1 if not found.
 */
LookupWeaponNumber(const String:name[])
{
    new String:f_WeaponName[64];

    if (StrContains(name, "mp5")!=-1)
	strcopy(f_WeaponName, sizeof(f_WeaponName), "weapon_mp5navy");
    else if(name[0] == 'w' || name[0] == 'W')
        strcopy(f_WeaponName, sizeof(f_WeaponName), name);
    else
        Format(f_WeaponName, sizeof(f_WeaponName), "weapon_%s", name);

    for(new i = 0; i < _:Weapon_Max; i++)
    {
        if(!strncmp(f_WeaponName, g_WeaponNames[i], strlen(g_WeaponNames[i]), false))
            return i;
    }
    return -1;
}

/*
 * LookupTarget(String:team)
 * Returns the team index or -1 if invalid.
 */
LookupTeam(String:f_TeamString[])
{
    if(f_TeamString[0] == '\0' || f_TeamString[0] == 'a' || f_TeamString[0] == 'A')
        return TEAM_ALL;
    else if(f_TeamString[0] == 'c' || f_TeamString[0] == 'C')
        return TEAM_CT;
    else if(f_TeamString[0] == 't' || f_TeamString[0] == 'T')
        return TEAM_T;
    else
        return -1;
}

/*
 * RemoveWeaponFromClient(client, weapon, remove)
 * Finds a weapon on the client, removes if specified
 */
RemoveWeaponFromClient(client, f_Weapon, bool:f_Remove = false)
{
    new f_Entity;
    decl String:f_EntityName[64];

    if(g_WeaponSlot[f_Weapon] == Slot_Grenade)
        UTIL_FindGrenadeByName(client, g_WeaponNames[f_Weapon], true, true);
    else
        f_Entity = GetPlayerWeaponSlot(client, _:g_WeaponSlot[f_Weapon]);

    if(f_Entity != -1)
    {
        GetEdictClassname(f_Entity, f_EntityName, sizeof(f_EntityName));
    }

    if(f_Entity != -1 && f_Remove && !strcmp(f_EntityName, g_WeaponNames[f_Weapon], false))
    {
        HACK_CSWeaponDrop(client, f_Entity);
        HACK_Remove(f_Entity);
        RefundCash(client, f_Weapon);
        return -1;
    }
    return f_Entity;
}

/*
 * RefundCash(client, weapon)
 * Refunds the cash for the weapon to the player.
 */
RefundCash(client, f_Weapon)
{   
    if(g_iAccount != -1)
    {
        new f_CurrentCash = GetEntData(client, g_iAccount);

        f_CurrentCash += g_WeaponPrices[f_Weapon];
        PrintToChat(client, "You are refunded %d cash for %s.",
            g_WeaponPrices[f_Weapon], g_WeaponNames[f_Weapon]);
        SetEntData(client, g_iAccount, f_CurrentCash);
    }
}

/*
 * NotifyPlayers(client, weapon, amount, team, restrict)
 * Notifies the players what has been done. Massive, nasty function.
 */
NotifyPlayers(client, f_Weapon, f_Amount, f_Team, bool:f_Restrict)
{
    decl String:f_Name[MAX_NAME_LENGTH];

    if(client == 0)
        strcopy(f_Name, sizeof(f_Name), "CONSOLE");
    else
        GetClientName(client, f_Name, sizeof(f_Name));

    if(f_Restrict)
    {
        switch(f_Team)
        {
            case TEAM_ALL:
            {
                if(f_Amount == 0)
                {
                    PrintToChatAll("%s has restricted the %s.", f_Name, g_ShortWeaponNames[f_Weapon]);
                }
                else
                {
                    PrintToChatAll("%s has restricted the %s to %d.",
                    f_Name, g_ShortWeaponNames[f_Weapon], f_Amount);
                }
            }

            case TEAM_T:
            {
                for(new i = 1; i <= g_MaxClients; i++)
                {
                    if(IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == TEAM_T || client == i))
                    {

                        if(f_Amount == 0)
                        {
                            PrintToChat(i, "%s has restricted the %s.", 
                                f_Name, g_ShortWeaponNames[f_Weapon]);
                        }
                        else
                        {
                            PrintToChat(i, "%s has restricted the %s to %d.",
                                f_Name, g_ShortWeaponNames[f_Weapon], f_Amount);
                        }
                    }
                }
            }

            case TEAM_CT:
            {
                for(new i = 1; i <= g_MaxClients; i++)
                {
                    if(IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == TEAM_T || client == i))
                    {
                        if(f_Amount == 0)
                        {
                            PrintToChat(i, "%s has restricted the %s.", 
                                f_Name, g_ShortWeaponNames[f_Weapon]);
                        }
                        else
                        {
                            PrintToChat(i, "%s has restricted the %s to %d.",
                                f_Name, g_ShortWeaponNames[f_Weapon], f_Amount);
                        }
                    }
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
                if(f_Amount == 0)
                {
                    PrintToChatAll("%s has unrestricted the %s.", f_Name, g_ShortWeaponNames[f_Weapon]);
                }
                else
                {
                    PrintToChatAll("%s has unrestricted the %s to %d.",
                    f_Name, g_ShortWeaponNames[f_Weapon], f_Amount);
                }
            }

            case TEAM_T:
            {
                for(new i = 1; i <= g_MaxClients; i++)
                {
                    if(IsClientConnected(i) && IsClientInGame(i)  && (GetClientTeam(i) == TEAM_T || client == i))
                    {
                        if(f_Amount == 0)
                        {
                            PrintToChat(i, "%s has unrestricted the %s.", 
                                f_Name, g_ShortWeaponNames[f_Weapon]);
                        }
                        else
                        {
                            PrintToChat(i, "%s has unrestricted the %s to %d.",
                                f_Name, g_ShortWeaponNames[f_Weapon], f_Amount);
                        }
                    }
                }
            }

            case TEAM_CT:
            {
                for(new i = 1; i <= g_MaxClients; i++)
                {
                    if(IsClientConnected(i) && IsClientInGame(i)  && (GetClientTeam(i) == TEAM_T || client == i))
                    {
                        if(f_Amount == 0)
                        {
                            PrintToChatAll("%s has unrestricted the %s.", 
                                f_Name, g_ShortWeaponNames[f_Weapon]);
                        }
                        else
                        {
                            PrintToChatAll("%s has unrestricted the %s to %d.",
                                f_Name, g_ShortWeaponNames[f_Weapon], f_Amount);
                        }
                    }
                }
            }
        }
    }
}
    
