/**
 * ===============================================================
 * Counter Strike:Source Restrict Item Script, Copyright (C) 2007
 * All rights reserved.
 * ===============================================================
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * To view the latest information, see: http://forums.alliedmods.net/showpost.php?p=493376
 * 	Author(s):	Shane A. ^BuGs^ Froebel
 *
 *
 * File: restrict.recommand.sp
 *
**/

public Action:Command_Restrict(client, args)
{
	if (client > 0)
		new AdminId:aid = GetUserAdmin(client);
	else if (client == 0)
		strcopy(aid, sizeof(aid), "RCON ADMIN");
		
	if (!args)
	{
		//	Will bring up the Restrict Main Menu
		ReplyToCommand(client, "%c[RESTRICT]%c Please type 'sm_restrict help' for vaild commands and syntax.", GREEN, YELLOW);
		return Plugin_Handled;
	}
	if (args > 0)
	{
		
		decl String:arg[255];
		decl String:buffer[255][255];
		
		GetCmdArgString(arg, 255);
		
		new arraycount = ExplodeString(arg, " ", buffer, 500, strlen(arg)+1);
		
		//	sm_restrict status
		if (strcmp(buffer[0], "status", false) == 0)
		{
			new String:status[255];
			if (GetConVarBool(g_RestrictStatus))
			{
				status = "ON";	
			} else {
				status = "OFF";
			}
			PrintToChat(client, "%c[RESTRICT]%c Restriction is currently: %s", GREEN, YELLOW, status);
			return Plugin_Handled;
		}
		//	Commands all users can access... only when the script is on.
		if (GetConVarBool(g_RestrictStatus))
		{			
			//	sm_restrict show <global|map|team|player> [ <t|ct> | <playername|userid> ]
			if (strcmp(buffer[0], "show", false) == 0)
			{
				if (strcmp(buffer[1], "global", false) == 0)
				{
					// Show_CurrentRestrict(client, RestrictGroup_Global, -1);
					return Plugin_Handled;
				}
				if (strcmp(buffer[1], "map", false) == 0)
				{
					// Show_CurrentRestrict(client, RestrictGroup_Map, -1);
					return Plugin_Handled;
				}
				if (strcmp(buffer[1], "team", false) == 0)
				{
					/*
					new TeamIndex = -1;
					if (strcmp(buffer[2], "t", false) == 0)
					{
						TeamIndex = 0;
					} else {
						TeamIndex = 1;
					}
					*/
					// Show_CurrentRestrict(client, RestrictGroup_Team, TeamIndex);
					return Plugin_Handled;
				}
				if (strcmp(buffer[1], "player", false) == 0)
				{
					new clients[64];
					new count = Restrict_PlayerParse(buffer[2], clients);
					if (count > 1)
					{
						ReplyToCommand(client, "%c[RESTRICT]%c More than one client matches.", GREEN, YELLOW);
						return Plugin_Handled;
					}
					// Show_CurrentRestrict(client, RestrictGroup_Player, clients[0]);
					return Plugin_Handled;
				}
				ReplyToCommand(client, "%c[RESTRICT]%c Please type 'sm_restrict help' for vaild commands and syntax.", GREEN, YELLOW);
				return Plugin_Handled;
			}
			//	sm_restrict view <global|map|team|player> [ <map name> | <t|ct> | <playername|userid> ]
			if (strcmp(buffer[0], "view", false) == 0)
			{
				if (strcmp(buffer[1], "global", false) == 0)
				{
					// Show_CurrentDefaults(client, RestrictGroup_Global, -1);
					return Plugin_Handled;
				}
				if (strcmp(buffer[1], "map", false) == 0)
				{
					// Show_CurrentDefaults(client, RestrictGroup_Map, -1);
					return Plugin_Handled;
				}
				if (strcmp(buffer[1], "team", false) == 0)
				{
					/*
					new TeamIndex = -1;
					if (strcmp(buffer[2], "t", false) == 0)
					{
						TeamIndex = 0;
					} else {
						TeamIndex = 1;
					}
					*/
					// Show_CurrentDefaults(client, RestrictGroup_Team, TeamIndex);
					return Plugin_Handled;
				}
				if (strcmp(buffer[1], "player", false) == 0)
				{
					new clients[64];
					new count = Restrict_PlayerParse(buffer[2], clients);
					if (count > 1)
					{
						ReplyToCommand(client, "%c[RESTRICT]%c More than one client matches.", GREEN, YELLOW);
						return Plugin_Handled;	
					}
					// Show_CurrentDefaults(client, RestrictGroup_Player, clients[0]);
					return Plugin_Handled;
				}
				ReplyToCommand(client, "%c[RESTRICT]%c Please type 'sm_restrict help' for vaild commands and syntax.", GREEN, YELLOW);
				return Plugin_Handled;
			}
			//	Admin_Config ACCESS ONLY ... and the script is on
			//	                ..:: OR ::..
			//	Admin_RCON ACCESS ONLY ... and the script is on
			if ((GetAdminFlag(aid, Admin_Config, Access_Effective)) || (GetAdminFlag(aid, Admin_RCON, Access_Effective)))
			{
				//	sm_restrict all <global|map|team|player> [ <t|ct> | <playername|userid> ]
				//	sm_restrict weapon(s) <global|map|team|player> [ <t|ct> | <playername|userid> ]
				//	sm_restrict equipment <global|map|team|player> [ <t|ct> | <playername|userid> ]
				j = false;
				new RestrictQuick:g_Quick;
				if (strcmp(buffer[0], "all", false) == 0)
				{
					j = true;
					g_Quick = RestrictQuick_All;
				}
				if ((strcmp(buffer[0], "weapons", false) == 0) || (strcmp(buffer[0], "weapon", false) == 0))
				{
					j = true;
					g_Quick = RestrictQuick_Wep;
				}
				if ((strcmp(buffer[0], "equipment", false) == 0) || (strcmp(buffer[0], "equip", false) == 0))
				{
					j = true;
					g_Quick = RestrictQuick_Equipment;
				}
				if (j)
				{
					if (strcmp(buffer[1], "global", false) == 0)
					{
						QuickRestrict(g_Quick, RestrictGroup_Global, true, -1);
						ReplyToCommand(client, "%c[RESTRICT]%c This group was disabled globally.", GREEN, YELLOW);
						return Plugin_Handled;
					}
					if (strcmp(buffer[1], "map", false) == 0)
					{
						QuickRestrict(g_Quick, RestrictGroup_Map, true, -1);
						ReplyToCommand(client, "%c[RESTRICT]%c This group was disabled per map.", GREEN, YELLOW);
						return Plugin_Handled;
					}
					if (strcmp(buffer[1], "team", false) == 0)
					{
						new TeamIndex = -1;
						if (strcmp(buffer[2], "t", false) == 0)
						{
							TeamIndex = 0;
						} else if (strcmp(buffer[2], "ct", false) == 0) {
							TeamIndex = 1;
						} else {
							for (new i = 0; i < 2; i++)
							{
								QuickRestrict(g_Quick, RestrictGroup_Team, true, i);
							}
							ReplyToCommand(client, "%c[RESTRICT]%c This group was disabled both teams.", GREEN, YELLOW);
							return Plugin_Handled;
						}
						if (TeamIndex == -1)
						{
							ReplyToCommand(client, "%c[RESTRICT]%c Please type 'sm_restrict help' for vaild commands and syntax.", GREEN, YELLOW);
							return Plugin_Handled;
						}
						QuickRestrict(g_Quick, RestrictGroup_Team, true, TeamIndex);
						ReplyToCommand(client, "%c[RESTRICT]%c This group was disabled per teams.", GREEN, YELLOW);
						return Plugin_Handled;
					}
					if (strcmp(buffer[1], "player", false) == 0)
					{
						new clients[64];
						new count = Restrict_PlayerParse(buffer[2], clients);
						if (count > 1)
						{
							ReplyToCommand(client, "%c[RESTRICT]%c More than one client matches.", GREEN, YELLOW);
							return Plugin_Handled;	
						}
						QuickRestrict(g_Quick, RestrictGroup_Player, true, clients[0]);
						ReplyToCommand(client, "%c[RESTRICT]%c This group was disabled per the player.", GREEN, YELLOW);
						return Plugin_Handled;
					}
					ReplyToCommand(client, "%c[RESTRICT]%c Please type 'sm_restrict help' for vaild commands and syntax.", GREEN, YELLOW);
					return Plugin_Handled;
				}
				//	sm_restrict limit [ global | map | team <t|ct> ] <number> <item index|item alias>
				if (strcmp(buffer[0], "limit", false) == 0)
				{
					new value;
					if (strcmp(buffer[1], "global", false) == 0) 
					{
						if (IsStrNumber(buffer[2], false))
						{
							value = StringToInt(buffer[2]);			
							for (new a = 3; a < arraycount; a++)
							{
								//	Add if last array is "save/delete"
								new ItemIndex = GetItemIndexNumber(buffer[a]);
								if (ItemIndex != -1)
								{
									if (value > 0)
									{
										ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) was limited to %c %i %c total.", GREEN, YELLOW, buffer[a], GREEN, value, YELLOW);
									} else if (value < 0) {
										ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) limit check was removed.", GREEN, YELLOW, buffer[a]);
									}
									RestrictLimitByIndex(ItemIndex, RestrictGroup_Global, -1, true, value);
								} else {
									ReplyToCommand(client, "%c[RESTRICT]%c Item (%s) is not vaild.", GREEN, YELLOW, buffer[a]);
								}
							}
						} else {
							ReplyToCommand(client, "%c[RESTRICT]%c Please type 'sm_restrict help' for vaild commands and syntax.", GREEN, YELLOW);
						}
						return Plugin_Handled;
					}
					if (strcmp(buffer[1], "map", false) == 0)
					{
						if (IsStrNumber(buffer[2], false))
						{
							value = StringToInt(buffer[2]);					
							for (new a = 3; a < arraycount; a++)
							{
								//	Add if last array is "save/delete"
								new ItemIndex = GetItemIndexNumber(buffer[a]);
								if (ItemIndex != -1)
								{
									if (value > 0)
									{
										ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) was limited to %c %i %c total.", GREEN, YELLOW, buffer[1], GREEN, value, YELLOW);
									} else if (value < 0) {
										ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) limit check was removed.", GREEN, YELLOW, buffer[1]);
									}
									RestrictLimitByIndex(ItemIndex, RestrictGroup_Map, -1, true, value);
								} else {
									ReplyToCommand(client, "%c[RESTRICT]%c Item (%s) is not vaild.", GREEN, YELLOW, buffer[a]);
								}
							}
						} else {
							ReplyToCommand(client, "%c[RESTRICT]%c Please type 'sm_restrict help' for vaild commands and syntax.", GREEN, YELLOW);
						}
						return Plugin_Handled;
					}
					if (strcmp(buffer[1], "team", false) == 0)
					{
						new TeamIndex = -1;
						if (strcmp(buffer[2], "t", false) == 0)
						{
							TeamIndex = 0;
						} else if (strcmp(buffer[2], "ct", false) == 0) {
							TeamIndex = 1;
						}
						if (TeamIndex == -1)
						{
							if (IsStrNumber(buffer[2], false))
							{
								value = StringToInt(buffer[2]);
								for (new a = 3; a < arraycount; a++)
								{
									//	Add if last array is "save/delete"
									new ItemIndex = GetItemIndexNumber(buffer[a]);
									if (ItemIndex != -1)
									{
										if (value > 0)
										{
											ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) was limited to %c %i %c total for both teams.", GREEN, YELLOW, buffer[a], GREEN, value, YELLOW);
										} else if (value < 0) {
											ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) limit check was removed for both teams.", GREEN, YELLOW, buffer[a]);
										}
										for (new v = 0; v < 2; v++)
										{
											RestrictLimitByIndex(ItemIndex, RestrictGroup_Team, v, true, value);
										}
									} else {
										ReplyToCommand(client, "%c[RESTRICT]%c Item (%s) is not vaild.", GREEN, YELLOW, buffer[a]);
									}
								}
							} else {
								ReplyToCommand(client, "%c[RESTRICT]%c Please type 'sm_restrict help' for vaild commands and syntax.", GREEN, YELLOW);
							}
						} else {
							if (IsStrNumber(buffer[3], false))
							{
								value = StringToInt(buffer[3]);
								for (new a = 4; a < arraycount; a++)
								{
									//	Add if last array is "save/delete"
									new ItemIndex = GetItemIndexNumber(buffer[a]);
									if (ItemIndex != -1)
									{
										if (value > 0)
										{
											ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) was limited to %c %i %c total for the team.", GREEN, YELLOW, buffer[a], GREEN, value, YELLOW);
										} else if (value < 0) {
											ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) limit check was removed for the team.", GREEN, YELLOW, buffer[a]);
										}
										RestrictLimitByIndex(ItemIndex, RestrictGroup_Team, TeamIndex, true, value);
									}  else {
										ReplyToCommand(client, "%c[RESTRICT]%c Item (%s) is not vaild.", GREEN, YELLOW, buffer[a]);
									}								
								}
							} else {
								ReplyToCommand(client, "%c[RESTRICT]%c Please type 'sm_restrict help' for vaild commands and syntax.", GREEN, YELLOW);
							}
						}
						return Plugin_Handled;
					}
				}
				//	sm_restrict item [ global | map | team <t|ct> | player <playername|userid> ] <item index|item alias>
				//								map [ team <t|ct> | player <playername|userid> ]
				//
				if (strcmp(buffer[0], "item", false) == 0)
				{
					if (strcmp(buffer[1], "global", false) == 0)
					{
						for (new a = 2; a < arraycount; a++)
						{
							new ItemIndex = GetItemIndexNumber(buffer[a]);
							if (ItemIndex != -1)
							{
								ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) was disabled globally.", GREEN, YELLOW, buffer[a]);
								RestrictItemByIndex(ItemIndex, RestrictGroup_Global, -1, -1, true, false);
							}  else {
								ReplyToCommand(client, "%c[RESTRICT]%c Item (%s) is not vaild.", GREEN, YELLOW, buffer[a]);
							}
						}
						return Plugin_Handled;
					}
					if (strcmp(buffer[1], "map", false) == 0)
					{
						if (strcmp(buffer[2], "team", false) == 0)
						{
							new TeamIndex = -1;
							if (strcmp(buffer[3], "t", false) == 0)
							{
								TeamIndex = 0;
							} else if (strcmp(buffer[3], "ct", false) == 0) {
								TeamIndex = 1;
							}
							if (TeamIndex == -1)
							{
								//	MAP_TEAM (Both Teams)
								for (new a = 3; a < arraycount; a++)
								{
									new ItemIndex = GetItemIndexNumber(buffer[a]);
									if (ItemIndex != -1)
									{
										ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) was disabled for both teams on this map.", GREEN, YELLOW, buffer[a]);
										for (new i = 0; i < 2; i++)
										{
											RestrictItemByIndex(ItemIndex, RestrictGroup_MapTeam, -1, i, true, false);
										}
									}  else {
										ReplyToCommand(client, "%c[RESTRICT]%c Item (%s) is not vaild.", GREEN, YELLOW, buffer[a]);
									}
								}
							} else {
								//	MAP_TEAM (Signle Teams)
								for (new a = 4; a < arraycount; a++)
								{
									new ItemIndex = GetItemIndexNumber(buffer[a]);
									if (ItemIndex != -1)
									{
										ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) was disabled for this team on this map.", GREEN, YELLOW, buffer[a]);
										RestrictItemByIndex(ItemIndex, RestrictGroup_MapTeam, -1, TeamIndex, true, false);
									}  else {
										ReplyToCommand(client, "%c[RESTRICT]%c Item (%s) is not vaild.", GREEN, YELLOW, buffer[a]);
									}
								}
							}
							return Plugin_Handled;
						} else if (strcmp(buffer[2], "player", false) == 0) {
							new clients[64];
							new count = Restrict_PlayerParse(buffer[3], clients);
							if (count > 1)
							{
								ReplyToCommand(client, "%c[RESTRICT]%c More than one client matches.", GREEN, YELLOW);
								return Plugin_Handled;	
							}
							for (new a = 4; a < arraycount; a++)
							{
								new ItemIndex = GetItemIndexNumber(buffer[a]);
								if (ItemIndex != -1)
								{
									ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) was disabled for this player on this map.", GREEN, YELLOW, buffer[a]);
									RestrictItemByIndex(ItemIndex, RestrictGroup_MapPlayer, clients[0], -1, true, false);
								}  else {
									ReplyToCommand(client, "%c[RESTRICT]%c Item (%s) is not vaild.", GREEN, YELLOW, buffer[a]);
								}
							}
							return Plugin_Handled;	
						} else {
							for (new a = 2; a < arraycount; a++)
							{
								new ItemIndex = GetItemIndexNumber(buffer[a]);
								if (ItemIndex != -1)
								{
									ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) was disabled for this map.", GREEN, YELLOW, buffer[a]);
									RestrictItemByIndex(ItemIndex, RestrictGroup_Map, -1, -1, true, false);
								}  else {
									ReplyToCommand(client, "%c[RESTRICT]%c Item (%s) is not vaild.", GREEN, YELLOW, buffer[a]);
								}
							}
							return Plugin_Handled;
						}
					}
					if (strcmp(buffer[1], "team", false) == 0)
					{
						new TeamIndex = -1;
						if (strcmp(buffer[2], "t", false) == 0)
						{
							TeamIndex = 0;
						} else if (strcmp(buffer[2], "ct", false) == 0) {
							TeamIndex = 1;
						}
						if (TeamIndex == -1)
						{
							for (new a = 2; a < arraycount; a++)
							{
								new ItemIndex = GetItemIndexNumber(buffer[a]);
								if (ItemIndex != -1)
								{
									ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) was disabled for both teams.", GREEN, YELLOW, buffer[a]);
									for (new i = 0; i < 2; i++)
									{
										RestrictItemByIndex(ItemIndex, RestrictGroup_Team, -1, i, true, false);
									}
								}  else {
									ReplyToCommand(client, "%c[RESTRICT]%c Item (%s) is not vaild.", GREEN, YELLOW, buffer[a]);
								}
							}
						} else {
							for (new a = 3; a < arraycount; a++)
							{
								new ItemIndex = GetItemIndexNumber(buffer[a]);
								if (ItemIndex != -1)
								{
									ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) was disabled for this team.", GREEN, YELLOW, buffer[a]);
									RestrictItemByIndex(ItemIndex, RestrictGroup_Team, -1, TeamIndex, true, false);
								}  else {
									ReplyToCommand(client, "%c[RESTRICT]%c Item (%s) is not vaild.", GREEN, YELLOW, buffer[a]);
								}
							}
						}
						return Plugin_Handled;
					}
					if (strcmp(buffer[1], "player", false) == 0)
					{
						new clients[64];
						new count = Restrict_PlayerParse(buffer[2], clients);
						if (count > 1)
						{
							ReplyToCommand(client, "%c[RESTRICT]%c More than one client matches.", GREEN, YELLOW);
							return Plugin_Handled;	
						}
						for (new a = 3; a < arraycount; a++)
						{
							new ItemIndex = GetItemIndexNumber(buffer[a]);
							if (ItemIndex != -1)
							{
								ReplyToCommand(client, "%c[RESTRICT]%c This item (%s) was disabled for this player.", GREEN, YELLOW, buffer[a]);
								RestrictItemByIndex(ItemIndex, RestrictGroup_Player, clients[0], -1, true, false);
							} else {
								ReplyToCommand(client, "%c[RESTRICT]%c Item (%s) is not vaild.", GREEN, YELLOW, buffer[a]);
							}
						}
						return Plugin_Handled;
					}
				}
			}
			//	Admin_RCON ACCESS ONLY ... and the script is on
			if (GetAdminFlag(aid, Admin_RCON, Access_Effective))
			{
				if (UseDataSystem)
				{
					//	sm_restrict save <global|map|team|player> [ <t|ct> | <playername|userid> ]
					if (strcmp(buffer[0], "save", false) == 0)
					{
						if (strcmp(buffer[1], "global", false) == 0)
						{
							SaveRestrictSettings(RestrictGroup_Global, -1);
							return Plugin_Handled;
						}
						if (strcmp(buffer[1], "map", false) == 0)
						{
							SaveRestrictSettings(RestrictGroup_Map, -1);
							return Plugin_Handled;
						}
						if (strcmp(buffer[1], "team", false) == 0)
						{
							new TeamIndex = -1;
							if (strcmp(buffer[3], "t", false) == 0)
							{
								TeamIndex = 0;
							} else {
								TeamIndex = 1;
							}
							if (TeamIndex == -1)
							{
								for (new i = 0; i < 2; i++)
								{
									SaveRestrictSettings(RestrictGroup_Team, i);
								}
							} else {
								SaveRestrictSettings(RestrictGroup_Team, TeamIndex);
							}						
							return Plugin_Handled;
						}
						if (strcmp(buffer[1], "player", false) == 0)
						{
							new clients[64];
							new count = Restrict_PlayerParse(buffer[2], clients);
							if (count > 1)
							{
								ReplyToCommand(client, "%c[RESTRICT]%c More than one client matches.", GREEN, YELLOW);
								return Plugin_Handled;	
							}
							SaveRestrictSettings(RestrictGroup_Player, clients[0]);
							return Plugin_Handled;
						}
					}
					//	sm_restrict restore <global|map|team|player> [ <t|ct> | <playername|userid> ]
					if (strcmp(buffer[0], "restore", false) == 0)
					{
						if (strcmp(buffer[1], "global", false) == 0)
						{
							RestoreRestrictSettings(RestrictGroup_Global, -1);
							return Plugin_Handled;
						}
						if (strcmp(buffer[1], "map", false) == 0)
						{
							RestoreRestrictSettings(RestrictGroup_Map, -1);
							return Plugin_Handled;
						}
						if (strcmp(buffer[1], "team", false) == 0)
						{
							new TeamIndex = -1;
							if (strcmp(buffer[2], "t", false) == 0)
							{
								TeamIndex = 0;
							} else {
								TeamIndex = 1;
							}
							if (TeamIndex == -1)
							{
								for (new i = 0; i < 2; i++)
								{
									RestoreRestrictSettings(RestrictGroup_Team, i);
								}
							} else {
								RestoreRestrictSettings(RestrictGroup_Team, TeamIndex);
							}	
							return Plugin_Handled;
						}
						if (strcmp(buffer[1], "player", false) == 0)
						{
							new clients[64];
							new count = Restrict_PlayerParse(buffer[2], clients);
							if (count > 1)
							{
								ReplyToCommand(client, "%c[RESTRICT]%c More than one client matches.", GREEN, YELLOW);
								return Plugin_Handled;	
							}
							RestoreRestrictSettings(RestrictGroup_Player, clients[0]);
							return Plugin_Handled;
						}
					}
				}
			}
		}
		//	Admin_RCON ACCESS ONLY ... doesn't matter the script status
		if (GetAdminFlag(aid, Admin_RCON, Access_Effective))
		{
			//	sm_restrict on
			if (strcmp(buffer[0], "on", false) == 0)
			{
				ChangeRestrictStatus(1);
				return Plugin_Handled;
			}
			//	sm_restrict off
			if (strcmp(buffer[0], "off", false) == 0)
			{
				ChangeRestrictStatus(0);
				return Plugin_Handled;
			}
		}
		//	sm_restrict help
		if (strcmp(buffer[0], "help", false) == 0)
		{
			//	This will be all the help stuff.
			//	This section is also divided by "access".
			if (GetConVarBool(g_RestrictStatus))
			{
				//	Show Stuff here... that the user can see depending on their flags.
				return Plugin_Handled;
			} else {
				if (GetAdminFlag(aid, Admin_RCON, Access_Effective))
				{
					ReplyToCommand(client, "%c[RESTRICT]%c Please type 'sm_restrict on' to turn on restriction.", GREEN, YELLOW);
					return Plugin_Handled;
				} else {
					ReplyToCommand(client, "%c[RESTRICT]%c Please type 'sm_restrict status' to check on the status of restriction.", GREEN, YELLOW);
					return Plugin_Handled;
				}
			}
		}
		//	Nothing matched...
		ReplyToCommand(client, "%c[RESTRICT]%c Please type 'sm_restrict help' for vaild commands and syntax.", GREEN, YELLOW);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}